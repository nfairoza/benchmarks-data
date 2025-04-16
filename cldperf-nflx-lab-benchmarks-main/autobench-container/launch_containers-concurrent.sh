#!/usr/bin/env bash
set -euo pipefail
#
# Check if the 'benchmark-container' image exists locally
if ! docker image inspect benchmark-container >/dev/null 2>&1; then
    echo "⚠️ 'benchmark-container' image not found locally."
    if [[ -f Dockerfile ]]; then
        echo "🛠️ Building Docker image 'benchmark-container' from Dockerfile..."
        docker build -t benchmark-container .
        echo "✅ Docker image 'benchmark-container' built successfully."
    else
        echo "❌ Dockerfile not found in the current directory. Cannot build 'benchmark-container'."
        exit 1
    fi
fi

# 🔒 Safety check: refuse to run if benchmark containers are already running
existing=$(docker ps --filter "name=benchmark-" -q)

if [[ -n "$existing" ]]; then
    echo "❌ ERROR: One or more benchmark containers are still running:"
    docker ps --filter "name=benchmark-"
    echo "💡 Tip: Wait for them to finish or stop them with: docker stop \$(docker ps -q --filter name=benchmark-)"
    exit 1
fi

###############################################################################
# 1. Define instance shapes and resources
###############################################################################

declare -A aws_shapes=(
  ["xlarge"]="4 16"
  ["2xlarge"]="8 32"
  ["4xlarge"]="16 64"
  ["8xlarge"]="32 128"
  ["12xlarge"]="48 192"
  ["16xlarge"]="64 256"
  ["24xlarge"]="96 384"
  ["32xlarge"]="128 512"
  ["metal-48xl"]="192 768"
)

###############################################################################
# 2. Parse command-line arguments (shapes) into (count, shape)
###############################################################################
ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then
    echo "❌ ERROR: No instance shapes provided. Usage:"
    echo "   $0 xlarge 2xlarge 5.xlarge 2.8xlarge"
    exit 1
fi

# We'll keep track of all requests in an array of "count shape" pairs
declare -a requested_pairs=()
TOTAL_CONTAINERS=0

# Function to parse each argument into "count" and "shape"
parse_arg() {
    local arg="$1"
    # If argument matches "<number>.<shape>", capture both
    if [[ "$arg" =~ ^([0-9]+)\.(.+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        # No numeric prefix, so default count = 1, shape = entire arg
        echo "1 $arg"
    fi
}

# Parse all CLI arguments into pairs of (count, shape)
for arg in "${ARGS[@]}"; do
    read -r count shape <<< "$(parse_arg "$arg")"
    # Validate the shape
    if [[ -z "${aws_shapes[$shape]:-}" ]]; then
        echo "❌ ERROR: Unknown shape '$shape'. Available: ${!aws_shapes[@]}"
        exit 1
    fi
    requested_pairs+=("$count $shape")
    TOTAL_CONTAINERS=$((TOTAL_CONTAINERS + count))
done

# Only set GROUP if more than 1 container
if (( TOTAL_CONTAINERS > 1 )); then
    shapes_label=()
    for pair in "${requested_pairs[@]}"; do
        read -r c s <<< "$pair"
        if [[ "$c" -eq 1 ]]; then
            shapes_label+=( "$s" )
        else
            shapes_label+=( "${c}.${s}" )
        fi
    done
    joined_label="$(IFS=_; echo "${shapes_label[*]}")"
    GROUP="GROUP-${joined_label}-$(date '+%Y-%m-%d_%H-%M-%S')"
    export GROUP
fi

###############################################################################
# 3. Detect system topology with lscpu
###############################################################################
TOPO_LINES=()
while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  TOPO_LINES+=( "$line" )
done < <(lscpu -p=CPU,CORE,SOCKET,NODE 2>/dev/null || lscpu -p=CPU,CORE,SOCKET 2>/dev/null)

declare -A CORE_MAP=()  # e.g. CORE_MAP["0-2"] = "0 96"
declare -A SOCKET_SEEN=()
MAX_SOCKET_ID=0

for line in "${TOPO_LINES[@]}"; do
  IFS=',' read -r cpu core socket node <<< "$line"
  if [[ -z "${node:-}" ]]; then
    node="$socket"
  fi

  SOCKET_SEEN["$socket"]=1
  (( socket > MAX_SOCKET_ID )) && MAX_SOCKET_ID="$socket"

  key="${socket}-${core}"
  if [[ -n "${CORE_MAP[$key]:-}" ]]; then
    CORE_MAP[$key]="${CORE_MAP[$key]} $cpu"
  else
    CORE_MAP[$key]="$cpu"
  fi
done

# Build arrays: CORES_PER_SOCKET[socket] = "coreID1 coreID2 ..."
declare -A CORES_PER_SOCKET=()
for key in "${!CORE_MAP[@]}"; do
  IFS='-' read -r s c <<< "$key"
  if [[ -n "${CORES_PER_SOCKET[$s]:-}" ]]; then
    CORES_PER_SOCKET[$s]="${CORES_PER_SOCKET[$s]} $c"
  else
    CORES_PER_SOCKET[$s]="$c"
  fi
done

# Sort core IDs
for s in "${!CORES_PER_SOCKET[@]}"; do
  tmp=( ${CORES_PER_SOCKET[$s]} )  # array
  IFS=$'\n' tmp_sorted=($(sort -n <<< "${tmp[*]}"))
  unset IFS
  CORES_PER_SOCKET[$s]="${tmp_sorted[*]}"
done

# Detect threads_per_core by sampling one core
THREADS_PER_CORE=1
min_socket_id=$(echo "${!CORES_PER_SOCKET[@]}" | tr ' ' '\n' | sort -n | head -1)
first_core=$(echo "${CORES_PER_SOCKET[$min_socket_id]}" | awk '{print $1}')
first_map_key="${min_socket_id}-${first_core}"
if [[ -n "${CORE_MAP[$first_map_key]:-}" ]]; then
  tmp=( ${CORE_MAP[$first_map_key]} )
  THREADS_PER_CORE=${#tmp[@]}
fi

###############################################################################
# 4. Calculate total resources
###############################################################################
TOTAL_MEMORY_GB=$(free -g | awk '/^Mem:/ {print $2}')
# total physical cores = sum of # cores in each socket
total_physical_cores=0
for s in "${!CORES_PER_SOCKET[@]}"; do
  tmp=( ${CORES_PER_SOCKET[$s]} )
  total_physical_cores=$(( total_physical_cores + ${#tmp[@]} ))
done

REQUIRED_CORES=0
REQUIRED_MEMORY_GB=0
declare -a container_plans=()

ceil_div() {
  local numerator="$1"
  local denominator="$2"
  echo $(( (numerator + denominator - 1) / denominator ))
}

for pair in "${requested_pairs[@]}"; do
    read -r c shape <<< "$pair"
    read -r vcpus mem_gb <<< "${aws_shapes[$shape]}"

    needed_cores_one="$(ceil_div "$vcpus" "$THREADS_PER_CORE")"
    (( needed_cores_one < 1 )) && needed_cores_one=1

    local_total_cores=$(( c * needed_cores_one ))
    REQUIRED_CORES=$(( REQUIRED_CORES + local_total_cores ))

    local_total_mem=$(( c * mem_gb ))
    REQUIRED_MEMORY_GB=$(( REQUIRED_MEMORY_GB + local_total_mem ))

    # Store c times
    for (( i=1; i<=c; i++ )); do
      container_plans+=( "$shape $vcpus $mem_gb $needed_cores_one" )
    done
done

# Check if we exceed system resources
if (( REQUIRED_CORES > total_physical_cores )); then
  echo "❌ ERROR: Requested $REQUIRED_CORES cores, but system has $total_physical_cores."
  exit 1
fi
if (( REQUIRED_MEMORY_GB > TOTAL_MEMORY_GB )); then
  echo "❌ ERROR: Requested $REQUIRED_MEMORY_GB GB mem, but system has $TOTAL_MEMORY_GB GB."
  exit 1
fi

echo "Detected: $((MAX_SOCKET_ID+1)) sockets, $total_physical_cores total physical cores,"
echo "          $THREADS_PER_CORE threads/core, $TOTAL_MEMORY_GB GB total memory."
echo "Request:  $REQUIRED_CORES physical cores, $REQUIRED_MEMORY_GB GB memory."
echo "✅ Sufficient resources. Proceeding..."

###############################################################################
# 5. Prepare FREE_CORES
###############################################################################
declare -A FREE_CORES=()
for s in "${!CORES_PER_SOCKET[@]}"; do
  FREE_CORES[$s]="${CORES_PER_SOCKET[$s]}"
done

# Debug: show initial free cores
# for s in "${!FREE_CORES[@]}"; do
#   echo "DEBUG start: Socket $s -> free cores: ${FREE_CORES[$s]}"
# done

###############################################################################
# 6. Allocation function (NO SUB-SHELL)
###############################################################################
# We'll store results in these two global variables each time we allocate.
ALLOC_SOCKET=""
ALLOC_CPUSET=""

allocate_physical_cores() {
  local needed="$1"

  # get sorted socket IDs
  local all_sockets
  IFS=$'\n' read -r -d '' -a all_sockets < <(printf "%s\n" "${!FREE_CORES[@]}" | sort -n && printf '\0')

  for s in "${all_sockets[@]}"; do
    # parse the free core IDs into an array
    local core_list
    IFS=' ' read -r -a core_list <<< "${FREE_CORES[$s]}"

    local available=${#core_list[@]}
    if (( available >= needed )); then
      # allocate the first $needed
      local allocated_core_ids=("${core_list[@]:0:needed}")
      local remaining_core_ids=("${core_list[@]:needed}")

      FREE_CORES[$s]="${remaining_core_ids[*]}"

      local cpu_id_array=()
      for c in "${allocated_core_ids[@]}"; do
        local map_key="${s}-${c}"
        local cpus_for_core
        IFS=' ' read -r -a cpus_for_core <<< "${CORE_MAP[$map_key]}"
        cpu_id_array+=( "${cpus_for_core[@]}" )
      done

      # Flatten
      local cpuset_cpus
      IFS=,; cpuset_cpus="${cpu_id_array[*]}"; unset IFS

      # Save these into our global result vars
      ALLOC_SOCKET="$s"
      ALLOC_CPUSET="$cpuset_cpus"

      # Debug:
      # echo "DEBUG alloc: socket=$s, allocated=(${allocated_core_ids[*]}) => cpus=[$cpuset_cpus]"
      # echo "DEBUG leftover on socket $s => ${FREE_CORES[$s]}"

      return 0
    fi
  done

  echo "ERROR: Could not allocate $needed cores from any socket." >&2
  exit 1
}

###############################################################################
# 7. Launch containers
###############################################################################
i=0
for item in "${container_plans[@]}"; do
  i=$((i+1))
  read -r shape vcpus mem_gb needed_cores <<< "$item"

  # 1) Allocate needed_cores (updates FREE_CORES in the parent shell)
  allocate_physical_cores "$needed_cores"

  # 2) retrieve results from ALLOC_SOCKET / ALLOC_CPUSET
  socket_id="$ALLOC_SOCKET"
  cpuset_list="$ALLOC_CPUSET"

  container_name="benchmark-${shape}-${i}"
  echo "🚀 Launching '$container_name' → shape=$shape, socket=$socket_id, cpuset=[$cpuset_list], mem=${mem_gb}g"

  docker run -d --rm \
    --name "$container_name" \
    --privileged \
    --cpuset-cpus="$cpuset_list" \
    --cpuset-mems="$socket_id" \
    --memory="${mem_gb}g" \
    -v /home/bnetflix/efs:/home/bnetflix/efs \
    -e INSTANCE_SIZE="$shape" \
    ${GROUP:+-e GROUP="$GROUP"} \
    -e CPUS="$vcpus" \
    -e MEMORY="$mem_gb" \
    -e CPUSET="$cpuset_list" \
    -e LD_PRELOAD="/fake-cpu-count.so" \
    -v "$(pwd)/fake-cpu-count.so:/fake-cpu-count.so:ro" \
    benchmark-container &

  # short sleep to reduce concurrency collisions
  sleep 1
done

wait
echo "✅ All containers launched successfully."


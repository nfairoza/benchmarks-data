#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Please provide profile as first argument with no/perfspec/uProf options.
          Example: ./start-benchmarks.sh no
                   ./start-benchmarks.sh no all        # Run all benchmarks non-interactively without profiling
                   ./start-benchmarks.sh perfspec
                   ./start-benchmarks.sh perfspec all  # Run all benchmarks non-interactively with PerfSpec
                   ./start-benchmarks.sh uProf
                   ./start-benchmarks.sh uProf all     # Run all benchmarks non-interactively with uProf"
    exit 1
fi

profile="$1"
run_all="${2:-}"  # Second parameter, defaults to empty if not provided
echo "EC2 Instance Type: $EC2_INSTANCE_TYPE"
echo "Local Results Directory: $LOCAL_RESULTS_DIR"
export PROFILE_TYPE=$(echo "$profile")
echo "Profile Type: $PROFILE_TYPE"

if [ "$profile" = "no" ]; then
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
  if [ "$run_all" = "all" ]; then
    ./run-benchmarks-noprofile all
  else
    ./run-benchmarks-noprofile
  fi
elif [ "$profile" = "perfspec" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/perfspect_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
  if [ "$run_all" = "all" ]; then
    ./run-benchmarks-perfspec all
  else
    ./run-benchmarks-perfspec
  fi
elif [ "$profile" = "uProf" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/uProf_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
  if [ "$run_all" = "all" ]; then
    ./run-benchmarks-uProf all
  else
    ./run-benchmarks-uProf
  fi
else
    echo "Please provide profile as first argument with no/perfspec/uProf options."
    exit 1
fi

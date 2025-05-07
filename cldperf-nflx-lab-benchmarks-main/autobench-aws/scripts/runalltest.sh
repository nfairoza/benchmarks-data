#!/bin/bash
# ./runalltest.sh "/c/Users/noorkhan/OneDrive - Advanced Micro Devices Inc/Documents/handson/aws/keypair/noor-ohio.pem"
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <ssh-key-path>"
    echo "Example: $0 ~/.ssh/my-key.pem"
    exit 1
fi

SSH_KEY_PATH="$1"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Error: SSH key file does not exist at $SSH_KEY_PATH"
    exit 1
fi

chmod 400 "$SSH_KEY_PATH"

INSTANCE_TYPES=(
    "m7a.xlarge"
    # "m7a.2xlarge"
    # "m7a.4xlarge"
    # "m7a.8xlarge"
    # "m7a.12xlarge"
    # "m7a.16xlarge"
    # "m7a.24xlarge"
    # "m7a.32xlarge"
    # "m7a.48xlarge"
    # "m7a.metal-48xl"
)

# Create a persistent benchmark script that will be uploaded to each instance
create_persistent_script() {
    cat > persistent_benchmark.sh << 'EOFSCRIPT'
#!/bin/bash
# persistent_benchmark.sh - Runs benchmarks that survive SSH disconnections

# Create log directory
LOGDIR="/home/ubuntu/benchmark_logs"
mkdir -p $LOGDIR

echo "====== Starting persistent benchmark run at $(date) ======" | tee -a $LOGDIR/master.log

# Check if benchmarks are already running
if pgrep -f "start-benchmarks.sh" > /dev/null; then
    echo "Benchmarks are already running. Exiting." | tee -a $LOGDIR/master.log
    exit 0
fi

# Download the startup script if not already available
if [ ! -f "./startup.sh" ]; then
    echo "Downloading startup script..." | tee -a $LOGDIR/master.log
    wget https://raw.githubusercontent.com/nfairoza/benchmarks-data/refs/heads/main/cldperf-nflx-lab-benchmarks-main/autobench-aws/startup.sh
    chmod +x startup.sh
fi

# Run the startup script if the benchmark directory doesn't exist
if [ ! -d "/home/ubuntu/cldperf-nflx-lab-benchmarks-main/autobench" ]; then
    echo "Running startup script..." | tee -a $LOGDIR/master.log
    sudo ./startup.sh > $LOGDIR/setup.log 2>&1
fi

# Change to the autobench directory
cd /home/ubuntu/cldperf-nflx-lab-benchmarks-main/autobench

# Function to run a benchmark with specific profiling and log outputs
run_benchmark_set() {
    PROFILE_TYPE=$1
    echo "====== Running benchmarks with $PROFILE_TYPE profiling at $(date) ======" | tee -a $LOGDIR/master.log
    sudo ./start-benchmarks.sh $PROFILE_TYPE all > $LOGDIR/benchmark_${PROFILE_TYPE}.log 2>&1

    if [ $? -eq 0 ]; then
        echo " $PROFILE_TYPE benchmarks completed successfully at $(date)" | tee -a $LOGDIR/master.log
    else
        echo " $PROFILE_TYPE benchmarks failed with exit code $? at $(date)" | tee -a $LOGDIR/master.log
    fi

    echo "Uploading $PROFILE_TYPE results..." | tee -a $LOGDIR/master.log
    export PROFILE_TYPE
    sudo -E ./upload-results.sh > $LOGDIR/upload_${PROFILE_TYPE}.log 2>&1

    if [ $? -eq 0 ]; then
        echo " $PROFILE_TYPE results uploaded successfully" | tee -a $LOGDIR/master.log
    else
        echo " $PROFILE_TYPE results upload failed with exit code $?" | tee -a $LOGDIR/master.log
    fi
}

# Run all three benchmark types in sequence
run_benchmark_set "no"
# run_benchmark_set "perfspec"
# run_benchmark_set "uProf"

echo "====== All benchmarks completed at $(date) ======" | tee -a $LOGDIR/master.log
echo "Results have been uploaded to S3" | tee -a $LOGDIR/master.log

# Create a completion marker
touch $LOGDIR/BENCHMARK_COMPLETE
EOFSCRIPT

    chmod +x persistent_benchmark.sh
    echo "Created persistent benchmark script."
}

# Function to check if an instance with the given name tag already exists
check_existing_instance() {
    local instance_type=$1
    local short_type=$(echo $instance_type | sed 's/m7a\.//g')
    local name_tag="netflixtest $short_type"

    echo "Checking for existing instance with name tag: \"$name_tag\"..."

    # Get instance ID if an instance with this name tag exists and is running
    INSTANCE_ID=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=\"$name_tag\"" "Name=instance-state-name,Values=running,pending" \
      --query 'Reservations[0].Instances[0].InstanceId' \
      --output text)

    # If INSTANCE_ID is not "None" and not empty, an instance exists
    if [ "$INSTANCE_ID" != "None" ] && [ ! -z "$INSTANCE_ID" ]; then
        echo "Found existing instance $INSTANCE_ID with name tag \"$name_tag\""
        return 0
    else
        echo "No existing running instance found with name tag \"$name_tag\""
        return 1
    fi
}

launch_and_benchmark() {
    local instance_type=$1
    local short_type=$(echo $instance_type | sed 's/m7a\.//g')
    local name_tag="netflixtest $short_type"
    local log_file="benchmark_${short_type}.log"

    echo "------------------------------------------------------------" | tee -a $log_file
    echo "Starting process for $instance_type at $(date)" | tee -a $log_file
    echo "------------------------------------------------------------" | tee -a $log_file

    check_existing_instance $instance_type
    if [ $? -eq 0 ]; then
        echo "Using existing instance $INSTANCE_ID ($instance_type)..." | tee -a $log_file
    else
        echo "Launching new $instance_type instance..." | tee -a $log_file

        INSTANCE_ID=$(aws ec2 run-instances \
          --image-id ami-0c3b809fcf2445b6a \
          --instance-type $instance_type \
          --key-name noor-ohio \
          --security-group-ids sg-0af511081e75fe69e \
          --subnet-id subnet-9f9892e5 \
          --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"DeleteOnTermination\":true}}]" \
          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$name_tag\"}]" \
          --iam-instance-profile Name=testadmin \
          --query 'Instances[0].InstanceId' \
          --output text)

        echo "Instance $INSTANCE_ID ($instance_type) is launching..." | tee -a $log_file

        aws ec2 wait instance-running --instance-ids $INSTANCE_ID
        echo "Instance $INSTANCE_ID ($instance_type) is running. Waiting for status checks..." | tee -a $log_file

        aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
        echo "Instance $INSTANCE_ID ($instance_type) is ready." | tee -a $log_file
    fi

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    echo "Instance $INSTANCE_ID ($instance_type) public IP: $PUBLIC_IP" | tee -a $log_file

    MAX_RETRIES=5
    RETRY_COUNT=0
    SSH_SUCCESS=false

    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$SSH_SUCCESS" = false ]; do
        echo "SSH attempt $((RETRY_COUNT+1)) to $PUBLIC_IP..." | tee -a $log_file

        # Try to establish a connection with a timeout
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$PUBLIC_IP "echo SSH connection successful" >> $log_file 2>&1

        if [ $? -eq 0 ]; then
            SSH_SUCCESS=true
            echo "SSH connection established successfully to $instance_type." | tee -a $log_file

            # Upload the persistent benchmark script
            echo "Uploading persistent benchmark script to $instance_type..." | tee -a $log_file
            scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no persistent_benchmark.sh ubuntu@$PUBLIC_IP:/home/ubuntu/ >> $log_file 2>&1

            if [ $? -ne 0 ]; then
                echo "Failed to upload persistent benchmark script. Retrying..." | tee -a $log_file
                SSH_SUCCESS=false
                RETRY_COUNT=$((RETRY_COUNT+1))
                sleep 10
                continue
            fi

            # Start the persistent benchmark script in detached mode with sudo
            echo "Starting persistent benchmarks on $instance_type in detached mode with sudo..." | tee -a $log_file
            ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP << EOF >> $log_file 2>&1
                echo "Checking for existing benchmark process..."
                if pgrep -f "persistent_benchmark.sh" > /dev/null; then
                    echo "Persistent benchmark already running on this instance."
                else
                    echo "Launching persistent benchmark in background with sudo..."
                    chmod +x /home/ubuntu/persistent_benchmark.sh
                    # Run with sudo but ensure the nohup output is owned by ubuntu user
                    sudo nohup /home/ubuntu/persistent_benchmark.sh > /home/ubuntu/benchmark_start.log 2>&1 &
                    echo "Benchmark process started with PID \$!"
                fi
EOF

            if [ $? -eq 0 ]; then
                echo "Successfully launched benchmarks on $instance_type in detached mode." | tee -a $log_file
                echo "You can safely disconnect. Benchmarks will continue running." | tee -a $log_file
                echo "To check status later, SSH to the instance and view logs in /home/ubuntu/benchmark_logs/" | tee -a $log_file
            else
                echo "Failed to start benchmarks on $instance_type." | tee -a $log_file
            fi
        else
            RETRY_COUNT=$((RETRY_COUNT+1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "SSH connection failed. Retrying in 30 seconds..." | tee -a $log_file
                sleep 30
            else
                echo "Failed to establish SSH connection after $MAX_RETRIES attempts." | tee -a $log_file
            fi
        fi
    done

    echo "Completed setup for $instance_type at $(date)" | tee -a $log_file
    echo "------------------------------------------------------------" | tee -a $log_file
}

# Create the persistent benchmark script
create_persistent_script

# Launch instances and start benchmarks
for instance_type in "${INSTANCE_TYPES[@]}"; do
    launch_and_benchmark "$instance_type" &
    sleep 5  # Small delay to avoid API rate limiting
done

echo "All benchmark processes have been initiated on their respective instances."
echo "You can safely close this terminal - benchmarks will continue running."
echo "To check status later, SSH to individual instances and check /home/ubuntu/benchmark_logs/master.log"

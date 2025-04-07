#!/bin/bash

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
    "m7a.2xlarge"
    "m7a.4xlarge"
    "m7a.8xlarge"
    "m7a.12xlarge"
    "m7a.16xlarge"
    "m7a.24xlarge"
    "m7a.32xlarge"
    "m7a.48xlarge"
    "m7a.metal-48xl"
)

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


    check_existing_instance $instance_type
    if [ $? -eq 0 ]; then
        echo "Using existing instance $INSTANCE_ID ($instance_type)..."
    else
        echo "Launching new $instance_type instance..."


        INSTANCE_ID=$(aws ec2 run-instances \
          --image-id ami-04f167a56786e4b09 \
          --instance-type $instance_type \
          --key-name noor-ohio \
          --security-group-ids sg-0af511081e75fe69e \
          --subnet-id subnet-9f9892e5 \
          --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"DeleteOnTermination\":true}}]" \
          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$name_tag\"}]" \
          --iam-instance-profile Name=testadmin \
          --query 'Instances[0].InstanceId' \
          --output text)

        echo "Instance $INSTANCE_ID ($instance_type) is launching..."

        aws ec2 wait instance-running --instance-ids $INSTANCE_ID
        echo "Instance $INSTANCE_ID ($instance_type) is running. Waiting for status checks..."

        aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
        echo "Instance $INSTANCE_ID ($instance_type) is ready."
    fi


    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    echo "Instance $INSTANCE_ID ($instance_type) public IP: $PUBLIC_IP"

    echo "Connecting to instance $INSTANCE_ID ($instance_type) and running benchmarks..."

    local log_file="benchmark_${short_type}.log"

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

            # Now run the actual commands
            ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP << EOF >> $log_file 2>&1
                echo "Connected to \$(hostname) - Running $instance_type benchmarks"

                # Check if benchmarks are already running
                if pgrep -f "start-benchmarks.sh" > /dev/null; then
                    echo "Benchmarks are already running on this instance. Exiting."
                    exit 0
                fi

                # Download the startup script if not already available
                if [ ! -f "./startup.sh" ]; then
                    echo "Downloading startup script..."
                    sudo wget https://raw.githubusercontent.com/nfairoza/benchmarks-data/refs/heads/main/cldperf-nflx-lab-benchmarks-main/autobench-aws/startup.sh
                    sudo chmod +x startup.sh
                fi

                # Run the startup script if the benchmark directory doesn't exist
                if [ ! -d "/home/ubuntu/cldperf-nflx-lab-benchmarks-main/autobench" ]; then
                    echo "Running startup script..."
                    sudo ./startup.sh
                fi

                # Change to the autobench directory
                cd /home/ubuntu/cldperf-nflx-lab-benchmarks-main/autobench

                # Run benchmarks with no profiling in non-interactive mode
                echo "Running benchmarks with no profiling..."
                sudo ./start-benchmarks.sh no all

                # Run benchmarks with perfspec profiling in non-interactive mode
                echo "Running benchmarks with perfspec profiling..."
                sudo ./start-benchmarks.sh perfspec all

                # Run benchmarks with uProf profiling in non-interactive mode
                echo "Running benchmarks with uProf profiling..."
                sudo ./start-benchmarks.sh uProf all

                # Upload the results
                echo "Uploading results to S3..."
                sudo ./upload-results.sh

                echo "Benchmark process completed for $instance_type."
EOF
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

    echo "Started benchmarks on $instance_type. Check $log_file for progress."
}


for instance_type in "${INSTANCE_TYPES[@]}"; do
    launch_and_benchmark "$instance_type" &
    sleep 5  # Small delay to avoid API rate limiting
done


echo "All instances launched or reused. Waiting for background processes to complete..."
wait

echo "Script completed. All benchmark processes have been initiated."
echo "Check the individual log files for each instance type."

#!/bin/bash

# Launch the EC2 instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-04f167a56786e4b09 \
  --instance-type m7a.24xlarge \
  --key-name noor-ohio \
  --security-group-ids sg-0af511081e75fe69e \
  --subnet-id subnet-9f9892e5 \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":50,\"DeleteOnTermination\":true}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"netflixtest 24\"}]" \
  --iam-instance-profile Name=testadmin \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance $INSTANCE_ID is launching..."

# Wait for the instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is running. Waiting for status checks..."

# Wait for status checks to complete
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
echo "Instance is ready."

# Get the public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance public IP: $PUBLIC_IP"

# SSH into the instance and run commands
echo "Connecting to instance and running benchmarks..."
ssh -i ~/.ssh/noor-ohio.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP << 'EOF'
  echo "Connected to $(hostname)"

  # Download the startup script
  echo "Downloading startup script..."
  sudo wget https://raw.githubusercontent.com/nfairoza/benchmarks-data/refs/heads/main/cldperf-nflx-lab-benchmarks-main/autobench-aws/startup.sh
  sudo chmod +x startup.sh

  # Run the startup script
  echo "Running startup script..."
  sudo ./startup.sh

  # Change to the autobench directory
  cd /home/ubuntu/cldperf-nflx-lab-benchmarks-main/autobench-aws

  # Run benchmarks with no profiling
  echo "Running benchmarks with no profiling..."
  sudo ./start-benchmarks.sh no

  # Run benchmarks with perfspec profiling
  echo "Running benchmarks with perfspec profiling..."
  sudo ./start-benchmarks.sh perfspec

  # Run benchmarks with uProf profiling
  echo "Running benchmarks with uProf profiling..."
  sudo ./start-benchmarks.sh uProf

  # Upload the results
  echo "Uploading results to S3..."
  sudo ./upload-results.sh

  echo "Benchmark process completed."
EOF

echo "Script completed. Results have been uploaded to S3."

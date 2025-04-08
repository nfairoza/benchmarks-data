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
        echo "✅ $PROFILE_TYPE benchmarks completed successfully at $(date)" | tee -a $LOGDIR/master.log
    else
        echo "❌ $PROFILE_TYPE benchmarks failed with exit code $? at $(date)" | tee -a $LOGDIR/master.log
    fi

    echo "Uploading $PROFILE_TYPE results..." | tee -a $LOGDIR/master.log
    export PROFILE_TYPE
    sudo -E ./upload-results.sh > $LOGDIR/upload_${PROFILE_TYPE}.log 2>&1

    if [ $? -eq 0 ]; then
        echo "✅ $PROFILE_TYPE results uploaded successfully" | tee -a $LOGDIR/master.log
    else
        echo "❌ $PROFILE_TYPE results upload failed with exit code $?" | tee -a $LOGDIR/master.log
    fi
}

# Run all three benchmark types in sequence
run_benchmark_set "no"
run_benchmark_set "perfspec"
run_benchmark_set "uProf"

echo "====== All benchmarks completed at $(date) ======" | tee -a $LOGDIR/master.log
echo "Results have been uploaded to S3" | tee -a $LOGDIR/master.log

# Create a completion marker
touch $LOGDIR/BENCHMARK_COMPLETE

#!/bin/bash
# This script starts the uProf tool in the background and records its PGID

UPROF="./binaries/uProf/bin/AMDuProfPcm"
echo " In start_uProf for benchmark: $2 at $1 " 
# Check if OUTPUT_DIR is provided as a command line argument
if [ -z "$1" ]; then
  echo "Error: OUTPUT_DIR was not provided as the 1st command line argument."
  exit 1
else
  OUTPUT_DIR="$1"
fi

# Check if BENCHMARK is provided as a command line argument
if [ -z "$2" ]; then
  echo "Error: BENCHMARK was not provided as the 2nd command line argument."
  exit 1
else
  BENCHMARK="$2"
fi

# Set the duration for profiling
if [ "$BENCHMARK" == "specjvm2008" ]; then
  DURATION=600
elif [ "$BENCHMARK" == "specjbb2015" ]; then
  DURATION=600
else
  DURATION=120
fi
echo "Duration $DURATION"
# Start uProf  metrics process in a new process group
setsid "$UPROF" -m all -O "${OUTPUT_DIR}/uProf_metrics/$BENCHMARK/" -a -d "${DURATION}" --html &
METRICS_PID=$!
echo "uProf metrics process started with PID $METRICS_PID"

# Wait for both processes to terminate
wait $METRICS_PID 

echo "uProf processes have terminated, proceeding to copy files."



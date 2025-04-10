#!/bin/bash
# This script starts the perfspect tool in the background and records its PGID

PERFSPECT="./binaries/perfspect/perfspect"

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

# Temporary directory for perfspect output
TEMP_OUTPUT_DIR="/tmp/${BENCHMARK}-perfspect"

# Ensure the temporary output directory exists
if [ -d "$TEMP_OUTPUT_DIR" ]; then
  rm -rf "$TEMP_OUTPUT_DIR"
  echo "Deleted existing temporary directory: $TEMP_OUTPUT_DIR"
fi
mkdir -p "$TEMP_OUTPUT_DIR"

# Clean up old perfspect log
PLOG="perfspect.log"
if [ -e "$PLOG" ]; then
  rm "perfspect.log"
fi

# Start perfspect metrics process in a new process group
setsid "$PERFSPECT" metrics --format csv --output "$TEMP_OUTPUT_DIR" &
METRICS_PID=$!
echo "Perfspect metrics process started with PID $METRICS_PID"

# Start perfspect telemetry process in a new process group
setsid "$PERFSPECT" telemetry --all --format json --duration 0 --output "$TEMP_OUTPUT_DIR" &
TELEMETRY_PID=$!
echo "Perfspect telemetry process started with PID $TELEMETRY_PID"

# Wait for both processes to terminate
wait $METRICS_PID $TELEMETRY_PID

echo "Perfspect processes have terminated, proceeding to copy files."

# Ensure the output metrics directory exists
mkdir -p "${OUTPUT_DIR}/metrics"

# Copy and rename the output files to the specified OUTPUT_DIR
for file in "$TEMP_OUTPUT_DIR"/*; do
  if [ -e "$file" ]; then
    filename=$(basename "$file")
    if [[ "$filename" == *_metrics.csv ]]; then
      # Rename files with _metrics.csv to perfspect-BENCHMARK_metrics.csv
      new_file="${OUTPUT_DIR}/metrics/perfspect-${BENCHMARK}_metrics.csv"
    elif [[ "$filename" == *_metrics_summary.csv ]]; then
      # Rename files with _metrics_summary.csv to perfspect-BENCHMARK_metrics_summary.csv
      new_file="${OUTPUT_DIR}/metrics/perfspect-${BENCHMARK}_metrics_summary.csv"
    elif [[ "$filename" == *_telem.json ]]; then
      # Rename files with _telem.csv to sys-BENCHMARK_telem.json
      new_file="${OUTPUT_DIR}/metrics/sys-${BENCHMARK}_telem.json"
    else
      continue
    fi
    cp "$file" "$new_file"
    echo "Moved $file to $new_file"
  fi
done

echo "Perfspect output copied to $OUTPUT_DIR"

#!/bin/bash
#
#   Collects system report using perfspec
#   --------------------------------
#


echo " Collecting system report using perfspec "
DIR=$1

TEMP_OUTPUT_DIR="/tmp/sys-report"
# Ensure the temporary output directory exists
if [ -d "$TEMP_OUTPUT_DIR" ]; then
  rm -rf "$TEMP_OUTPUT_DIR"
  echo "Deleted existing temporary directory: $TEMP_OUTPUT_DIR"
fi
mkdir -p "$TEMP_OUTPUT_DIR"

PERFSPECT="./binaries/perfspect/perfspect"
setsid "$PERFSPECT" report --output "$TEMP_OUTPUT_DIR" &
REPORT_PID=$!
echo "Report collection started!"
wait $REPORT_PID
echo "Report collection ended!"

# Cleaning up
mkdir -p "${DIR}/sys-report"

# Copy and rename the output files to the specified OUTPUT_DIR
for file in "$TEMP_OUTPUT_DIR"/*; do
  if [ -e "$file" ]; then
    filename=$(basename "$file")
    if [[ "$filename" == *.csv ]]; then
      new_file="${DIR}/sys-report/sys-report.csv"
    elif [[ "$filename" == *.txt ]]; then
      new_file="${DIR}/sys-report/sys-report.txt"
    elif [[ "$filename" == *.json ]]; then
      new_file="${DIR}/sys-report/sys-report.json"
    elif [[ "$filename" == *.html ]]; then
      new_file="${DIR}/sys-report/sys-report.html"
    else
      continue
    fi
    cp "$file" "$new_file"
  fi
done



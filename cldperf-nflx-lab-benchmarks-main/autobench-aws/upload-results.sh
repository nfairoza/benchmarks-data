#!/bin/bash

. ./benchmarks_environment.sh

if [ -z "$EC2_INSTANCE_TYPE" ]; then
    echo "Error: EC2_INSTANCE_TYPE is not set or is empty"
    exit 1
fi

if [ -z "$LOCAL_RESULTS_DIR" ]; then
    echo "Error: LOCAL_RESULTS_DIR is not set or is empty"
    exit 1
fi

if [ ! -d "$LOCAL_RESULTS_DIR" ]; then
    echo "Error: LOCAL_RESULTS_DIR directory does not exist: $LOCAL_RESULTS_DIR"
    exit 1
fi

echo "EC2_INSTANCE_TYPE = $EC2_INSTANCE_TYPE"
echo "LOCAL_RESULTS_DIR = $LOCAL_RESULTS_DIR"
echo "Profile Type: $PROFILE_TYPE"
S3_BUCKET="s3://netflix-files-us-west2/nfx-benchmark-results"

INSTANCE_FOLDER=$(echo "$EC2_INSTANCE_TYPE" | sed -e 's/\./-/g')

if [ -z "$PROFILE_TYPE" ]; then
    PROFILE_TYPE="standard"
    echo "Profile Type not set, using default: $PROFILE_TYPE"
fi

S3_DESTINATION="$S3_BUCKET/${INSTANCE_FOLDER}/${INSTANCE_FOLDER}_${PROFILE_TYPE}_results"
echo "Will upload to: $S3_DESTINATION"

echo "Calculating total files to upload..."
TOTAL_FILES=$(find "$LOCAL_RESULTS_DIR" -type f | wc -l)
echo "Uploading $TOTAL_FILES files..."

# Create a temporary file for the list of files
TEMP_FILE=$(mktemp)
find "$LOCAL_RESULTS_DIR" -type f > "$TEMP_FILE"

COUNTER=0
while IFS= read -r file; do
    COUNTER=$((COUNTER+1))
    PERCENTAGE=$((COUNTER*100/TOTAL_FILES))

    FILENAME=$(basename "$file")
    RELATIVE_PATH=${file#"$LOCAL_RESULTS_DIR/"}
    S3_PATH="$S3_DESTINATION/$RELATIVE_PATH"

    # Clear the line and show progress
    echo -ne "Uploading: [$PERCENTAGE%] $COUNTER of $TOTAL_FILES files\r"

    # Upload the file silently
    aws s3 cp "$file" "$S3_PATH" > /dev/null 2>&1
done < "$TEMP_FILE"

# Clean up
rm "$TEMP_FILE"

echo -e "\nUpload complete!"

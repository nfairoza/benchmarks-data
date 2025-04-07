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

if [ -z "$PROFILE_TYPE" ]; then
    PROFILE_TYPE="standard"
    echo "Profile Type not set, using default: $PROFILE_TYPE"
fi

echo "Profile Type: $PROFILE_TYPE"
S3_BUCKET="s3://netflix-files-us-west2/nfx-benchmark-results"

# Format instance name by replacing dots with hyphens
INSTANCE_FOLDER=$(echo "$EC2_INSTANCE_TYPE" | sed -e 's/\./-/g')

# Create timestamp for the zip file
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ZIP_FILENAME="${INSTANCE_FOLDER}_${PROFILE_TYPE}_${TIMESTAMP}.zip"
ZIP_PATH="/tmp/$ZIP_FILENAME"

echo "Creating zip archive of benchmark results..."
# Navigate to the directory containing the results
cd "$(dirname "$LOCAL_RESULTS_DIR")"
# Get the base directory name
BASE_DIR=$(basename "$LOCAL_RESULTS_DIR")
# Create the zip file
zip -r "$ZIP_PATH" "$BASE_DIR"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create zip file"
    exit 1
fi

echo "Zip file created: $ZIP_PATH"

S3_DESTINATION="$S3_BUCKET/${INSTANCE_FOLDER}/"
echo "Will upload to: $S3_DESTINATION"

echo "Starting upload to S3..."
aws s3 cp "$ZIP_PATH" "$S3_DESTINATION$ZIP_FILENAME" --only-show-errors

if [ $? -eq 0 ]; then
    echo "Upload successful!"
    echo "Uploaded to: $S3_DESTINATION$ZIP_FILENAME"

    # Clean up the temporary zip file
    rm -f "$ZIP_PATH"
    echo "Temporary zip file removed"
    
    echo "Generating updated index.html..."
    ./scripts/generate_index.sh "$S3_BUCKET"

    echo "Uploading updated index.html..."
    INDEX_PATH="./scripts/index.html"
    aws s3 cp "$INDEX_PATH" "$S3_DESTINATION/index.html" --only-show-errors --no-progress
else
    echo "Upload failed. Check AWS credentials and permissions."
fi

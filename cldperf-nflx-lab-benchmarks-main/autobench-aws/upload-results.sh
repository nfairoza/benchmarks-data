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

INSTANCE_FOLDER=$(echo "$EC2_INSTANCE_TYPE" | sed -e 's/\./-/g')


S3_DESTINATION="$S3_BUCKET/${INSTANCE_FOLDER}/${INSTANCE_FOLDER}_${PROFILE_TYPE}_results"
echo "Will upload to: $S3_DESTINATION"

echo "Starting upload to S3..."
aws s3 sync "$LOCAL_RESULTS_DIR" "$S3_DESTINATION" --only-show-errors --no-progress

if [ $? -eq 0 ]; then
    echo "Upload successful!"
else
    echo "Upload failed. Check AWS credentials and permissions."
fi

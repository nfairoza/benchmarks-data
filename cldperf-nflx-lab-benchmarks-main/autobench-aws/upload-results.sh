#!/bin/bash

. ./benchmarks_environment.sh

echo "EC2_INSTANCE_TYPE = $EC2_INSTANCE_TYPE"
echo "LOCAL_RESULTS_DIR = $LOCAL_RESULTS_DIR"
echo "Profile Type: $PROFILE_TYPE"
S3_BUCKET="s3://netflix-files-us-west2/nfx-benchmark-results"

S3_DESTINATION="$S3_BUCKET/${INSTANCE_FOLDER}/${INSTANCE_FOLDER}_${PROFILE_TYPE}_results"
echo "Will upload to: $S3_DESTINATION"


echo "Local results directory: $LOCAL_RESULTS_DIR"
echo -n "Do you want to proceed with the upload? (y/n): "
read answer

if [ "$answer" != "y" ]; then
    echo "Upload cancelled."
    exit 0
fi

# Upload the results
echo "Uploading benchmark results to $S3_DESTINATION..."
aws s3 sync "$LOCAL_RESULTS_DIR" "$S3_DESTINATION" --exclude "*.tmp"

if [ $? -eq 0 ]; then
    echo "Upload successful!"
else
    echo "Upload failed. Check LOCAL_RESULTS_DIR varisble is set to right path. Check AWS credentials and permissions."
fi

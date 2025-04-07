#!/bin/bash

S3_BUCKET="s3://netflix-files-us-west2/nfx-benchmark-results"

INSTANCE_FOLDER=$(echo "$EC2_INSTANCE_TYPE" | tr '.' '-')

S3_DESTINATION="$S3_BUCKET/${INSTANCE_FOLDER}_results"
echo "Uploading benchmark results from $LOCAL_RESULTS_DIR for $INSTANCE_FOLDER"
echo "Uploading benchmark results to $S3_DESTINATION"
aws s3 sync "$LOCAL_RESULTS_DIR" "$S3_DESTINATION" --exclude "*.tmp"

if [ $? -eq 0 ]; then
    echo "Upload successful!"
else
    echo "Upload failed. Check LOCAL_RESULTS_DIR varisble is set to right path. Check AWS credentials and permissions."
fi

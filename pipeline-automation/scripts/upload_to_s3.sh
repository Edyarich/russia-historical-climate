#!/usr/bin/env bash
set -euo pipefail

BUCKET=s3://russia-historical-climate-edyarich

# 1. Sync local scripts directory
awsv2 s3 sync ../scripts "${BUCKET}/scripts/"

echo "Uploaded local scripts to ${BUCKET}/scripts/"

# 2. Download external GPKG and upload to S3
URL="https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_RUS.gpkg"
FILENAME=$(basename "$URL")

# Download
curl -L "$URL" -o "$FILENAME"

echo "Downloaded $FILENAME"

# Upload to external folder
awsv2 s3 cp "$FILENAME" "${BUCKET}/ghcn_data/external/$FILENAME"

echo "Uploaded external file to ${BUCKET}/ghcn_data/external/"
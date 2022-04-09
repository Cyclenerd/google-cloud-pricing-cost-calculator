#!/usr/bin/env bash

#
# Export all Google Compute Engine accelerator types to CSV files
#

source "config.sh" || exit 9

echo "Get accelerator types... Please wait..."

echo "NAME;ZONE" > "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE" || exit 9
gcloud compute accelerator-types list \
	--quiet \
	--filter="ZONE:-" \
	--format="csv[no-heading,separator=';'](NAME,ZONE)" | sort -u >> "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE" || exit 9

cp "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE" "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" || exit 9
perl -i -pe's/-[a-z]$//g' "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" || exit 9 # Remove zone (-a ... -z)
sort -u "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" -o "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" || exit 9

cp "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" "$CSV_GCLOUD_ACCELERATOR_TYPES" || exit 9
perl -i -pe's/[a-z0-9-]+$//g' "$CSV_GCLOUD_ACCELERATOR_TYPES" || exit 9 # Remove region
sort -u "$CSV_GCLOUD_ACCELERATOR_TYPES" -o "$CSV_GCLOUD_ACCELERATOR_TYPES" || exit 9

echo "DONE"
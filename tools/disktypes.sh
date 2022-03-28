#!/usr/bin/env bash

#
# Export all Google Compute Engine disk types to a CSV file
#

source "config.sh" || exit 9

echo "Get disk types... Please wait..."

echo "NAME;VALID_DISK_SIZES,DESCRIPTION" > "$CSV_GCLOUD_DISK_TYPES" || exit 9
gcloud compute disk-types list \
	--quiet \
	--filter="ZONE:-" \
	--format="csv[no-heading,separator=';'](NAME,VALID_DISK_SIZES,description)" | sort -u >> "$CSV_GCLOUD_DISK_TYPES" || exit 9

echo "DONE"
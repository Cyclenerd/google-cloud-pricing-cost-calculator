#!/usr/bin/env bash

#
# Export all Google Compute Engine images to a CSV file
#

source "config.sh" || exit 9

echo "Get images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;CREATION;STATUS" > "$CSV_GCLOUD_IMAGES" || exit 9
gcloud compute images list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,STATUS)" | sort -u >> "$CSV_GCLOUD_IMAGES" || exit 9

echo "DONE"
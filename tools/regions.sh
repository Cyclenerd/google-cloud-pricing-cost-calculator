#!/usr/bin/env bash

#
# Export all Google Compute Engine regions to a CSV file
#

source "config.sh" || exit 9

echo "Get regions... Please wait..."

echo "NAME;STATUS;TURNDOWN_DATE" > "$CSV_GCLOUD_REGIONS" || exit 9
gcloud compute regions list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,STATUS,TURNDOWN_DATE)" >> "$CSV_GCLOUD_REGIONS" || exit 9

echo "DONE"
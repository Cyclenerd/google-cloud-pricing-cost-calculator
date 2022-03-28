#!/usr/bin/env bash

#
# Export all Google Compute Engine zones to a CSV file
#

source "config.sh" || exit 9

echo "Get zones... Please wait..."

echo "NAME;REGION;STATUS;NEXT_MAINTENANCE;TURNDOWN_DATE" > "$CSV_GCLOUD_ZONES" || exit 9
gcloud compute zones list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,REGION,STATUS,NEXT_MAINTENANCE,TURNDOWN_DATE)" >> "$CSV_GCLOUD_ZONES" || exit 9

echo "DONE"
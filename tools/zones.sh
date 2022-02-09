#!/usr/bin/env bash

#
# Export all Google Compute Engine zones to a CSV file
#

# File for CSV export
APP_CSV=${APP_CSV:-"zones.csv"}

echo "NAME;REGION;STATUS;NEXT_MAINTENANCE;TURNDOWN_DATE" > "$APP_CSV";
gcloud compute zones list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,REGION,STATUS,NEXT_MAINTENANCE,TURNDOWN_DATE)" >> "$APP_CSV"
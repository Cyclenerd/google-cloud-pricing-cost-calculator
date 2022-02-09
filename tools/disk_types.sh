#!/usr/bin/env bash

#
# Export all Google Compute Engine disk types to a CSV file
#

# File for CSV export
APP_CSV=${APP_CSV:-"disk_types.csv"}

echo "NAME;VALID_DISK_SIZES,DESCRIPTION" > "$APP_CSV";
gcloud compute disk-types list \
	--quiet \
	--filter="ZONE:-" \
	--format="csv[no-heading,separator=';'](NAME,VALID_DISK_SIZES,description)" | sort -u >> "$APP_CSV"
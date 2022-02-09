#!/usr/bin/env bash

#
# Export all Google Compute Engine regions to a CSV file
#

# File for CSV export
APP_CSV=${APP_CSV:-"regions.csv"}

echo "NAME;STATUS;TURNDOWN_DATE" > "$APP_CSV";
gcloud compute regions list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,STATUS,TURNDOWN_DATE)" >> "$APP_CSV"
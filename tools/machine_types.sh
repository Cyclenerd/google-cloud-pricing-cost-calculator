#!/usr/bin/env bash

#
# Export all Google Compute Engine machine types to a CSV file
#

#File for CSV export
APP_CSV=${APP_CSV:-"machine_types.csv"}

echo "NAME;CPUS;SHARED_CPU;MEMORY_GB;DESCRIPTION;DEPRECATED" > "$APP_CSV";
gcloud compute machine-types list \
	--quiet \
	--filter="ZONE:-" \
	--format="csv[no-heading,separator=';'](NAME,CPUS,isSharedCpu,MEMORY_GB,description,DEPRECATED)" | sort -u >> "$APP_CSV"

#!/usr/bin/env bash

MY_GCP_PROJECT='sap-shared-tool'

# List all Compute Engine virtual machine instances
function list_vms() {
	echo "Compute Engine virtual machine instances"
	if ! gcloud compute instances list \
		--format="csv[no-heading,separator=';'](MY_GCP_PROJECT,NAME,machineType,ZONE,disks[].deviceName)" \
		--project="$MY_GCP_PROJECT" >> "INSTANCES.csv"; then
		echo "WARNING: Could not list VM instance"
		export MY_WARNING=1
	fi
}

# List all Compute Engine persistent disks
function list_disks() {
	echo "Compute Engine persistent disks"
	if ! gcloud compute disks list \
		--format="csv[no-heading,separator=';'](MY_GCP_PROJECT,NAME,sizeGb,TYPE,zone.basename(),licenses.basename())" \
		--project="$MY_GCP_PROJECT" >> "DISKS.csv"; then
		echo "WARNING: Could not list disks"
		export MY_WARNING=1
	fi
}

# List all Compute Engine disk snapshots
function list_snapshots() {
	echo "Compute Engine snapshots"
	if ! gcloud compute snapshots list \
		--format="csv[no-heading,separator=';'](MY_GCP_PROJECT,NAME,storageBytes,storageLocations)" \
		--project="$MY_GCP_PROJECT" >> "SHNAPSHOTS.csv" ; then
		echo "WARNING: Could not list snapshots"
		export MY_WARNING=1
	fi
}

# List all storage buckets
function list_storage() {
	echo "Storage buckets"
	if ! gsutil ls \
		-p "$MY_GCP_PROJECT"; then
		echo "WARNING: Could not list buckets"
		export MY_WARNING=1
	fi
}

# Display object size usage
# https://cloud.google.com/storage/docs/gsutil/commands/du
function du_storage() {
	echo "Storage usage '$MY_GCP_STORAGE'"
	if ! gsutil du -s -h gs://"$MY_GCP_STORAGE"; then
		echo "WARNING: Could not get object size usage"
		export MY_WARNING=1
	fi
}

list_vms
list_disks
list_snapshots
list_storage

perl -pi -e "s/^\;/$MY_GCP_PROJECT\;/g" "INSTANCES.csv"

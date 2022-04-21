#!/usr/bin/env bash

#
# Export all Google Compute Engine images to a CSV file
#

source "config.sh" || exit 9

echo "Get images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;CREATION;DEPRECATED;STATUS" > "$CSV_GCLOUD_IMAGES" || exit 9
gcloud compute images list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,DEPRECATED,STATUS)" | sort -u >> "$CSV_GCLOUD_IMAGES" || exit 9

echo "Get community images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;CREATION;DEPRECATED;STATUS" > "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#almalinux
gcloud compute images list \
	--project almalinux-cloud \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,DEPRECATED,STATUS)" | sort -u >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#fedora_cloud
gcloud compute images list \
	--project fedora-cloud \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,DEPRECATED,STATUS)" | sort -u >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#freebsd
gcloud compute images list \
	--project freebsd-org-cloud-dev \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,DEPRECATED,STATUS)" | sort -u >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#opensuse
gcloud compute images list \
	--project opensuse-cloud \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,creationTimestamp,DEPRECATED,STATUS)" | sort -u >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9

echo "DONE"
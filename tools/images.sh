#!/usr/bin/env bash

#
# Export all Google Compute Engine images to a CSV file
#

source "config.sh" || exit 9

echo "Get images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;ARCHITECTURE;CREATION;DEPRECATED;STATUS" > "$CSV_GCLOUD_IMAGES" || exit 9
gcloud compute images list \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,architecture,creationTimestamp,DEPRECATED,STATUS)" >> "$CSV_GCLOUD_IMAGES" || exit 9

echo "Get community images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;ARCHITECTURE;CREATION;DEPRECATED;STATUS" > "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#almalinux
gcloud compute images list \
	--project almalinux-cloud \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,architecture,creationTimestamp,DEPRECATED,STATUS)" >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9
# https://cloud.google.com/compute/docs/images#freebsd
gcloud compute images list \
	--project freebsd-org-cloud-dev \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,architecture,creationTimestamp,DEPRECATED,STATUS)" >> "$CSV_GCLOUD_COMMUNITY_IMAGES" || exit 9

# Deep Learning on Linux
echo "Get deep learning images... Please wait..."

echo "NAME;DESCRIPTION;DISK_SIZE_GB;PROJECT;FAMILY;ARCHITECTURE;CREATION;DEPRECATED;STATUS" > "$CSV_GCLOUD_DEEPLEARNING_IMAGES" || exit 9
gcloud compute images list \
	--project ml-images \
	--filter="creationTimestamp > -P1Y" \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,architecture,creationTimestamp,DEPRECATED,STATUS)" >> "$CSV_GCLOUD_DEEPLEARNING_IMAGES" || exit 9
# https://cloud.google.com/deep-learning-vm/docs/images#listing-versions
gcloud compute images list \
	--project deeplearning-platform-release \
	--filter="creationTimestamp > -P1Y" \
	--no-standard-images \
	--quiet \
	--format="csv[no-heading,separator=';'](NAME,description,diskSizeGb,PROJECT,FAMILY,architecture,creationTimestamp,DEPRECATED,STATUS)" >> "$CSV_GCLOUD_DEEPLEARNING_IMAGES" || exit 9

echo "DONE"
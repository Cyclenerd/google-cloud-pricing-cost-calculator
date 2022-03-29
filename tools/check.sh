#!/usr/bin/env bash

#
# Check CSV files and create a new issue on change
#

source "config.sh" || exit 9

MY_CHANGES=0

# GitHub Action runner
if [ -v GITHUB_RUN_ID ]; then
	echo "» Set git username and email"
	git config user.name "github-actions[bot]"
	git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
fi

# Region
if ! git diff --exit-code "$CSV_GCLOUD_REGIONS"; then
	echo "'$CSV_GCLOUD_REGIONS' changed!"
	echo "» Create a new incident to notify $GITHUB_ISSUE_ASSIGNEE."
	git diff "$CSV_GCLOUD_REGIONS" | gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Regions" --body-file -
	echo "» Also create a new comment to incident '$GITHUB_ISSUE_ID_REGION'."
	git diff "$CSV_GCLOUD_REGIONS" | gh issue comment "$GITHUB_ISSUE_ID_REGION" --body-file -
	git add "$CSV_GCLOUD_REGIONS"
	((MY_CHANGES++));
fi
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPE_REGION"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPE_REGION' changed!"
	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_REGION'."
	git diff "$CSV_GCLOUD_MACHINE_TYPE_REGION" | gh issue comment "$GITHUB_ISSUE_ID_REGION" --body-file -
	git add "$CSV_GCLOUD_MACHINE_TYPE_REGION"
	((MY_CHANGES++));
fi

# Zones
if ! git diff --exit-code "$CSV_GCLOUD_ZONES"; then
	echo "'$CSV_GCLOUD_ZONES' changed!"
	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	git diff "$CSV_GCLOUD_ZONES" | gh issue comment "$GITHUB_ISSUE_ID_ZONE" --body-file -
	git add "$CSV_GCLOUD_ZONES"
	((MY_CHANGES++));
fi
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPE_ZONE"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPE_ZONE' changed!"
	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	git diff "$CSV_GCLOUD_MACHINE_TYPE_ZONE" | gh issue comment "$GITHUB_ISSUE_ID_ZONE" --body-file -
	git add "$CSV_GCLOUD_MACHINE_TYPE_ZONE"
	((MY_CHANGES++));
fi

# Disk types
if ! git diff --exit-code "$CSV_GCLOUD_DISK_TYPES"; then
	echo "'$CSV_GCLOUD_DISK_TYPES' changed!"
	echo "»  Create a new incident to notify $GITHUB_ISSUE_ASSIGNEE."
	git diff "$CSV_GCLOUD_DISK_TYPES" | gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Disk types" --body-file -
	git add "$CSV_GCLOUD_DISK_TYPES"
	((MY_CHANGES++));
fi

# Machine types
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPES"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPES' changed!"
	echo "» Create a new incident to notify $GITHUB_ISSUE_ASSIGNEE."
	git diff "$CSV_GCLOUD_MACHINE_TYPES" | gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Machine types" --body-file -
	git add "$CSV_GCLOUD_MACHINE_TYPES"
	((MY_CHANGES++));
fi

# Commit and push
if [ "$MY_CHANGES" -ge 1 ]; then
	echo "Commit and push to repo..."
	git commit -m "GCE changes" || exit 9
	git push || exit 9
fi

echo "DONE"
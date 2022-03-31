#!/usr/bin/env bash

#
# Check CSV files and create a new issue on change
#
# Diff message based on https://stackoverflow.com/a/25498422
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
MY_GITHUB_REGION_BODY="/tmp/regions.txt"
if ! git diff --exit-code "$CSV_GCLOUD_REGIONS"; then
	echo "'$CSV_GCLOUD_REGIONS' changed!"
	{
		echo "Regions '$CSV_GCLOUD_REGIONS' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_REGIONS" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_REGIONS" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_REGION_BODY"

	echo "» Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Regions" -F "$MY_GITHUB_REGION_BODY"
	echo "» Also create a new comment to incident '$GITHUB_ISSUE_ID_REGION'."
	gh issue comment "$GITHUB_ISSUE_ID_REGION" -F "$MY_GITHUB_REGION_BODY"

	git add "$CSV_GCLOUD_REGIONS"
	((MY_CHANGES++));
fi
MY_GITHUB_MACHINE_TYPE_REGION_BODY="/tmp/machinetyperegion.txt"
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPE_REGION"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPE_REGION' changed!"
	{
		echo "Machine type in region '$CSV_GCLOUD_MACHINE_TYPE_REGION' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPE_REGION" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPE_REGION" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_MACHINE_TYPE_REGION_BODY"

	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_REGION'."
	gh issue comment "$GITHUB_ISSUE_ID_REGION" -F "$MY_GITHUB_MACHINE_TYPE_REGION_BODY"

	git add "$CSV_GCLOUD_MACHINE_TYPE_REGION"
	((MY_CHANGES++));
fi

# Zones
MY_GITHUB_ZONES_BODY="/tmp/zones.txt"
if ! git diff --exit-code "$CSV_GCLOUD_ZONES"; then
	echo "'$CSV_GCLOUD_ZONES' changed!"
	{
		echo "Zones '$CSV_GCLOUD_ZONES' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_ZONES" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_ZONES" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_ZONES_BODY"

	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	gh issue comment "$GITHUB_ISSUE_ID_ZONE" -F "$MY_GITHUB_ZONES_BODY"

	git add "$CSV_GCLOUD_ZONES"
	((MY_CHANGES++));
fi
MY_GITHUB_MACHINE_TYPE_ZONE_BODY="/tmp/machinetypezone.txt"
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPE_ZONE"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPE_ZONE' changed!"
	{
		echo "Machine type in zone '$CSV_GCLOUD_MACHINE_TYPE_ZONE' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPE_ZONE" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPE_ZONE" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_MACHINE_TYPE_ZONE_BODY"

	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	gh issue comment "$GITHUB_ISSUE_ID_ZONE" -F "$MY_GITHUB_MACHINE_TYPE_ZONE_BODY"

	git add "$CSV_GCLOUD_MACHINE_TYPE_ZONE"
	((MY_CHANGES++));
fi

# Disk types
MY_GITHUB_DISK_TYPES_BODY="/tmp/disktypes.txt"
if ! git diff --exit-code "$CSV_GCLOUD_DISK_TYPES"; then
	echo "'$CSV_GCLOUD_DISK_TYPES' changed!"
	{
		echo "Disk types '$CSV_GCLOUD_DISK_TYPES' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPES" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPES" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_DISK_TYPES_BODY"

	echo "»  Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Disk types" -F "$MY_GITHUB_DISK_TYPES_BODY"

	git add "$CSV_GCLOUD_DISK_TYPES"
	((MY_CHANGES++));
fi

# Machine types
MY_GITHUB_MACHINE_TYPES_BODY="/tmp/machinetypes.txt"
if ! git diff --exit-code "$CSV_GCLOUD_MACHINE_TYPES"; then
	echo "'$CSV_GCLOUD_MACHINE_TYPES' changed!"
	{
		echo "Machine types '$CSV_GCLOUD_MACHINE_TYPES' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPES" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_MACHINE_TYPES" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_MACHINE_TYPES_BODY"

	echo "» Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Machine types" -F "$MY_GITHUB_MACHINE_TYPES_BODY"

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
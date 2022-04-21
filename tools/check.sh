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
	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_REGION'."
	gh issue comment "$GITHUB_ISSUE_ID_REGION" -F "$MY_GITHUB_REGION_BODY"

	{
		echo ""
		echo "Todo:"
		echo "- [ ] Check changes"
		echo "- [ ] Edit title of this issue"
		echo "- [ ] Run [build/skus.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/build#workflow) workflow to export SKUs from the Google Cloud Billing API"
		echo "- [ ] Check if region is present in 'build/skus.csv'"
		echo "- [ ] Add or remove the region in [build/gcp.yml](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/gcp.yml)"
		echo "- [ ] Create a test for region in [t/test.sh](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/t/test.sh)"
		echo "- [ ] Test cost calculation with new region"
		echo "- [ ] Build new pricing information file 'pricing.yml'"
		echo "- [ ] Run [Open Graph](https://github.com/Cyclenerd/google-cloud-compute-machine-types/actions/workflows/opengraph.yml) action in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
		echo "- [ ] Run [Build](https://github.com/Cyclenerd/google-cloud-compute-machine-types/actions/workflows/build.yml) action in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
	} >> "$MY_GITHUB_REGION_BODY"
	echo "» Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Regions" -F "$MY_GITHUB_REGION_BODY"

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
MY_GITHUB_ACCELERATOR_TYPE_REGION_BODY="/tmp/acceleratortyperegion.txt"
if ! git diff --exit-code "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION"; then
	echo "'$CSV_GCLOUD_ACCELERATOR_TYPE_REGION' changed!"
	{
		echo "Accelerator type in region '$CSV_GCLOUD_ACCELERATOR_TYPE_REGION' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_ACCELERATOR_TYPE_REGION_BODY"

	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	gh issue comment "$GITHUB_ISSUE_ID_ZONE" -F "$MY_GITHUB_ACCELERATOR_TYPE_REGION_BODY"

	git add "$CSV_GCLOUD_ACCELERATOR_TYPE_REGION"
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
MY_GITHUB_ACCELERATOR_TYPE_ZONE_BODY="/tmp/acceleratortypezone.txt"
if ! git diff --exit-code "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE"; then
	echo "'$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE' changed!"
	{
		echo "Accelerator type in zone '$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_ACCELERATOR_TYPE_ZONE_BODY"

	echo "» Create a new comment to incident '$GITHUB_ISSUE_ID_ZONE'."
	gh issue comment "$GITHUB_ISSUE_ID_ZONE" -F "$MY_GITHUB_ACCELERATOR_TYPE_ZONE_BODY"

	git add "$CSV_GCLOUD_ACCELERATOR_TYPE_ZONE"
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
		echo ""
		echo "Todo:"
		echo "- [ ] Check changes"
		echo "- [ ] Edit title of this issue"
		echo "- [ ] Run [build/skus.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/build#workflow) workflow to export SKUs from the Google Cloud Billing API"
		echo "- [ ] Check if disk type is present in 'build/skus.csv'"
		echo "- [ ] Add or remove mapping in [build/mapping.csv](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/mapping.csv)"
		echo "- [ ] Add or remove the disk type in [build/gcp.yml](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/gcp.yml)"
		echo "- [ ] Add or remove the disk type with mapping in [build/pricing.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/pricing.pl)"
		echo "- [ ] Create a test for disk type in [t/test.sh](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/t/test.sh)"
		echo "- [ ] Test cost calculation with disk type"
		echo "- [ ] Build new pricing information file 'pricing.yml'"
		echo "- [ ] Update mapping in usage [README](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/usage#-compute-engine-disks)"
		echo "- [ ] Edit mapping in [06_add_costs.pl](https://github.com/Cyclenerd/google-cloud-compute-machine-types/blob/master/build/06_add_costs.pl) script in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
		echo "- [ ] Run [Build](https://github.com/Cyclenerd/google-cloud-compute-machine-types/actions/workflows/build.yml) action in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
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
		echo ""
		echo "Todo:"
		echo "- [ ] Check changes"
		echo "- [ ] Edit title of this issue"
		echo "- [ ] Run [build/skus.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/build#workflow) workflow to export SKUs from the Google Cloud Billing API"
		echo "- [ ] Check if machine type is present in 'build/skus.csv'"
		echo "- [ ] Add or remove mapping in [build/mapping.csv](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/mapping.csv)"
		echo "- [ ] Add or remove the machine type in [build/gcp.yml](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/gcp.yml)"
		echo "- [ ] Add or remove the machine type with mapping in [build/pricing.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/pricing.pl)"
		echo "- [ ] Check if machine type gets SUD and edit [build/pricing.pl](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/build/pricing.pl)"
		echo "- [ ] Create a test for machine type in [t/test.sh](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/t/test.sh)"
		echo "- [ ] Test cost calculation with machine type"
		echo "- [ ] Build new pricing information file 'pricing.yml'"
		echo "- [ ] Run [Open Graph](https://github.com/Cyclenerd/google-cloud-compute-machine-types/actions/workflows/opengraph.yml) action in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
		echo "- [ ] Run [Build](https://github.com/Cyclenerd/google-cloud-compute-machine-types/actions/workflows/build.yml) action in [Cyclenerd/google-cloud-compute-machine-types](https://github.com/Cyclenerd/google-cloud-compute-machine-types)"
	} > "$MY_GITHUB_MACHINE_TYPES_BODY"

	echo "» Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Machine types" -F "$MY_GITHUB_MACHINE_TYPES_BODY"

	git add "$CSV_GCLOUD_MACHINE_TYPES"
	((MY_CHANGES++));
fi

# Accelerator types
MY_GITHUB_ACCELERATOR_TYPES_BODY="/tmp/acceleratortypes.txt"
if ! git diff --exit-code "$CSV_GCLOUD_ACCELERATOR_TYPES"; then
	echo "'$CSV_GCLOUD_ACCELERATOR_TYPES' changed!"
	{
		echo "Accelerator types '$CSV_GCLOUD_ACCELERATOR_TYPES' changed"
		echo ""
		echo "Added:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPES" | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/'
		echo ""
		echo "Deleted:"
		git diff --color=always "$CSV_GCLOUD_ACCELERATOR_TYPES" | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/'
	} > "$MY_GITHUB_ACCELERATOR_TYPES_BODY"

	echo "» Create a new incident to notify '$GITHUB_ISSUE_ASSIGNEE'."
	gh issue create --assignee "$GITHUB_ISSUE_ASSIGNEE" --label "$GITHUB_ISSUE_LABEL" --title "Change detected: Accelerator types" -F "$CSV_GCLOUD_ACCELERATOR_TYPES"

	git add "$CSV_GCLOUD_ACCELERATOR_TYPES"
	((MY_CHANGES++));
fi

# Images
if ! git diff --exit-code "$CSV_GCLOUD_IMAGES"; then
	git add "$CSV_GCLOUD_IMAGES"
	((MY_CHANGES++));
fi
if ! git diff --exit-code "$CSV_GCLOUD_COMMUNITY_IMAGES"; then
	git add "$CSV_GCLOUD_COMMUNITY_IMAGES"
	((MY_CHANGES++));
fi
if ! git diff --exit-code "$CSV_GCLOUD_DEEPLEARNING_IMAGES"; then
	git add "$CSV_GCLOUD_DEEPLEARNING_IMAGES"
	((MY_CHANGES++));
fi

# Commit and push
if [ "$MY_CHANGES" -ge 1 ]; then
	echo "Commit and push to repo..."
	git commit -m "GCE changes" || exit 9
	git push || exit 9
fi

echo "DONE"
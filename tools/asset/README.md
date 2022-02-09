# Cloud Asset Inventory

Create usage files for cost calculation based on the asset inventory.

**Warning:** This scripts are quickly hacked and properly tested. Works for me... `¯\_(ツ)_/¯`

## Export

Export asset inventory:

```shell
gcloud asset search-all-resources \
	--project=PROJECT_ID \
	--scope=projects/PROJECT_ID \
	--asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Disk,compute.googleapis.com/Snapshot,storage.googleapis.com/Bucket" \
	--read-mask='*' > assets.yml
```

The allowed `scope` values are:

* projects/PROJECT_ID (e.g., projects/foo-bar)
* projects/PROJECT_NUMBER (e.g., projects/12345678)
* folders/FOLDER_NUMBER (e.g., folders/1234567)
* organizations/ORGANIZATION_NUMBER (e.g. organizations/123456)

The caller must be granted the `cloudasset.assets.searchAllResources` permission on the desired scope.

Google Cloud Documentation:

* [gcloud asset](https://cloud.google.com/sdk/gcloud/reference/asset)
* [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types#searchable_asset_types)

## Bucket object size

Create a separate YML file `buckets.yml` with the buckets and size.

```shell
gsutil ls
perl buckets.pl
```

## Create usage files

Create a separate YML file for each project `PROJECT_ID.yml`.
Bucket object size file `buckets.yml` is used by default.
Files are overwritten without any warning.

```shell
perl assets.pl -asset=assets.yml
```

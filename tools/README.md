# Tools

Small helpers to get required informations.

## Export GCE regions (`regions.sh`)

Export all Google Compute Engine regions to a CSV file:
```bash
bash regions.sh
```

The regions are needed to calculate the costs for the region.
The regions are required in the `gcp.yml` file in the build folder.
New regions must be added manually to the `gcp.yml` file.

» [Google Cloud Regions and Zones Documentation](https://cloud.google.com/compute/docs/regions-zones#available)

## Export GCE zones (`zones.sh`)

Export all Google Compute Engine zones to a CSV file:
```bash
bash zones.sh
```

The zones are not currently required by any other script and are for informative use only.

## Export GCE machine types (`machinetypes.sh`)

Export all Google Compute Engine machine types to a CSV file:
```bash
bash machinetypes.sh
```

The machine types are needed to calculate the costs for the machine type.
The machine types are required in the `gcp.yml` file in the build folder.
New machine types must be added manually to the `gcp.yml` file.

## Export GCE disk types (`disktypes.sh`)

Export all Google Compute Engine disk types to a CSV file:
```bash
bash disktypes.sh
```

The disk types are needed to calculate the costs for the disk type.
The disk types are required in the `gcp.yml` file in the build folder.
New disk types must be added manually to the `gcp.yml` file.

## Export GCE accelerator types (`acceleratortypes.sh`)

Google Cloud Documentation:

* [GPU platforms](https://cloud.google.com/compute/docs/gpus/)
* [gcloud compute accelerator-types](https://cloud.google.com/sdk/gcloud/reference/compute/accelerator-types/)

Export all Google Compute Engine accelerator types to a CSV file:
```bash
bash acceleratortypes.sh
```
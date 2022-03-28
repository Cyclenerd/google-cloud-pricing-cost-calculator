# Tools

Small helpers to get required informations.

## Export services (`services.pl`)

Store API key in `services.conf` configuration file:
```shell
echo "key = YOUR-CLOUD-BILLING-API-KEY" > services.conf
```

Alternatively, the API key can be specified as environment variable `API_KEY`:
```shell
export API_KEY=YOUR-CLOUD-BILLING-API-KEY
```

Export public services from the Cloud Billing Catalog to a CSV file:
```shell
perl services.pl
```

The service ID is needed to export the SKUs wiht the `skus.pl` script in the build directory.
Only needed if you want to integrate the cost informations of a new service.

» [Google Cloud Billing Documentation](https://cloud.google.com/billing/v1/how-tos/catalog-api#listing_public_services_from_the_catalog)

## Export GCE regions (`regions.sh`)

Export all Google Compute Engine regions to a CSV file:
```shell
bash regions.sh
```

The regions are needed to calculate the costs for the region.
The regions are required in the `gcp.yml` file in the build folder.
New regions must be added manually to the `gcp.yml` file.

» [Google Cloud Regions and Zones Documentation](https://cloud.google.com/compute/docs/regions-zones#available)

## Export GCE zones (`zones.sh`)

Export all Google Compute Engine zones to a CSV file:
```shell
bash zones.sh
```

The zones are not currently required by any other script and are for informative use only.

## Export GCE machine types (`machinetypes.sh`)

Export all Google Compute Engine machine types to a CSV file:
```shell
bash machinetypes.sh
```

The machine types are needed to calculate the costs for the machine type.
The machine types are required in the `gcp.yml` file in the build folder.
New machine types must be added manually to the `gcp.yml` file.

## Export GCE disk types (`disktypes.sh`)

Export all Google Compute Engine disk types to a CSV file:
```shell
bash disktypes.sh
```

The disk types are needed to calculate the costs for the disk type.
The disk types are required in the `gcp.yml` file in the build folder.
New disk types must be added manually to the `gcp.yml` file.
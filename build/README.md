# Build pricing information file

Configuration and scripts to generate YML file `pricing.yml` with Google Cloud Platform pricing informations.

Files:

* `pricing.yml` : YML file with calculated pricing information.
* `pricing.pl`  : Script to calculate and generate pricing information file `costs.yml`.
* `gcp.yml`     : YML file with Google Cloud Platform information. Is read by the script `costs.pl` to calculate and generate pricing information file (`costs.yml`).
* `mapping.csv` : CSV file with custom mapping IDs. Is read by the script `mapping.pl` to add the custom mapping IDs to the SKUs (`skus.csv`).
* `mapping.pl`  : Script to add the custom mapping IDs from `mapping.csv` to the CSV file with the SKUs (`skus.csv`).
* `skus.csv`    : CSV file with SKU pricing and information exported from the Google Cloud Billing API.
* `skus.conf`   : Configration with your custom and private Google Cloud Billing API key. Is read by the script `skus.pl`.
* `skus.pl`     : Script to export SKUs from the Google Cloud Billing API.

## Workflow

```
 +--------------------------+
 | Google Cloud Billing API |
 +--------------------------+
            |
 +-------------------------+
 | » Export SKUs (skus.pl) |
 +-------------------------+
            ↓
  +-------------------------------+  +----------------+
  | SKUs with pricing information |  | Custom mapping |
  |            skus.csv           |  |  mapping.csv   |
  +-------------------------------+  +----------------+
            \                           /
  +-----------------------------------------------+
  | » Add custom mapping IDs to SKUs (mapping.pl) |
  +-----------------------------------------------+
                      ↓
 +----------------------------------+  +-----------------------------+
 | SKUs pricing with custom mapping |  | Google Cloud Platform info. |
 |               skus.csv           |  |           gcp.yml           |
 +----------------------------------+  +-----------------------------+
                \                             /
         +--------------------------------------------------+
         | » Generate pricing information file (pricing.pl) |
         +--------------------------------------------------+
                              ↓
                +-------------------------------+
                |  GCP pricing information file |
                |          pricing.yml          |
                +-------------------------------+
```

## Enable Google Cloud Billing API

More help: <https://cloud.google.com/billing/v1/how-tos/catalog-api>

1. Enable the [Cloud Billing API](https://console.cloud.google.com/flows/enableapi?apiid=cloudbilling.googleapis.com).
1. Get Cloud Billing Catalog API key
	1. Navigate to the [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials) panel in Cloud Console.
	1. Select **Create credentials**, then select **API key** from the dropdown menu.
	1. Copy your key and keep it secure.

## Export SKUs (`skus.pl`)

Export the SKU information of the Google Cloud Billing API to a more readable CSV file.
You can get all service IDs with the script `servies.pl` in the tool directory.

Store API key in `skus.conf` configuration file:
```shell
echo "key = YOUR-CLOUD-BILLING-API-KEY" > skus.conf
```

Alternatively, the API key can be specified as environment variable `API_KEY`:
```shell
export API_KEY=YOUR-CLOUD-BILLING-API-KEY
```

[Compute Engine](https://cloud.google.com/compute/):
```shell
perl skus.pl -csv="skus_compute.csv" -id="6F81-5844-456A"
```

[Cloud Storage](https://cloud.google.com/storage/):
```shell
perl skus.pl -csv="skus_storage.csv" -id="95FF-2EF5-5EA1"
```

[Stackdriver Monitoring](https://cloud.google.com/monitoring/):
```shell
perl skus.pl -csv="skus_stackdriver.csv" -id="58CD-E7C3-72CA"
```

[Cloud SQL](https://cloud.google.com/sql/):
```shell
perl skus.pl -csv="skus_sql.csv" -id="9662-B51E-5089"
```

Merge CSV files:
```shell
{
  cat "skus_compute.csv"
  cat "skus_storage.csv"
  cat "skus_stackdriver.csv"
  cat "skus_sql.csv"
} > skus.csv
```

» [Google Cloud Billing Documentation](https://cloud.google.com/billing/v1/how-tos/catalog-api#getting_the_list_of_skus_for_a_service)

## Add custom mapping IDs to SKUs (`mapping.pl`)

To make it easier to find the SKUs we add our own mapping (IDs):
```shell
perl mapping.pl -sku="skus.csv"
```

## Generate pricing information file (`pricing.pl`)

Generate the YML file with the Google Cloud Platform pricing informations for all regions:
```shell
perl pricing.pl -sku="skus.csv"
```

Generate pricing informations only for region `europe-west4` with mapping details:
```shell
perl pricing.pl -sku="skus.csv" \
  -details=1                  \
  -region="europe-west4"      \
  -export="pricing_europe_west4.yml"
```

### Special curls

* Region `southamerica-west1` has currently no compute services and is therefore not taken into account.
  If this is changed, edit `gcp.yml` file.
* Region `us-east4` is called 'Northern Virginia' and 'Virginia' in SKU descriptions.
  Therefore, there are duplicate entries. I read the first one.
* Region `asia-northeast1` is sometimes called 'Tokyo' and 'Japan' with different prices. I use the SKUs with Tokyo in the name:
	* Memory-optimized Instance Ram running in...
		* Tokyo: `570B-10D7-C81F` 6200000
		* Japan: `757F-6F9E-CCEC` 6230700
	* Memory-optimized Instance Core running in...
		* Tokyo: `23EB-5861-7872` 42600000
		* Japan: `255E-0C41-3813` 42648900
	* Memory Optimized Upgrade Premium for Memory-optimized Instance Ram running in...
		* Tokyo: `2EC7-75E5-E2A2` 806000
		* Japan: `68D5-29AA-798E` 809991
	* Memory Optimized Upgrade Premium for Memory-optimized Instance Core running in...
		* Tokyo: `ECDF-ED08-82EF` 5538000
		* Japan: `9398-9081-75AC` 5544357
	* Commitment v1: Memory-optimized Ram in ... for 1 Year
		* Tokyo: `C840-78A5-7D97` 3700000
		* Japan: `71DA-B269-E14A` 3680000
	* Commitment v1: Memory-optimized Cpu in ... for 1 Year
		* Tokyo: `38D6-00D9-3F69` 25200000
		* Japan: `A412-F795-8DEA` 25160000
	* Commitment v1: Memory-optimized Ram in ... for 3 Year
		* Tokyo: `2D9E-4F01-E21E` 1900000
		* Japan: `F213-5808-5249` 1870000
	* Commitment v1: Memory-optimized Cpu in ... for 3 Year
		* Tokyo: `5C79-7D8A-C71F` 12800000
		* Japan: `CABB-9912-AD72` 12790000
* Region `asia-southeast1`:
	* Description 'Memory-optimized Instance Core running in Singapore' has more SKUs with diffent costs:
		1. [4EA6-5E74-B349](https://cloud.google.com/skus/?currency=USD&filter=4EA6-5E74-B349)
		1. [B428-ABC6-FFED](https://cloud.google.com/skus/?currency=USD&filter=B428-ABC6-FFED) (cheaper = skipped)
	* Description 'Memory-optimized Instance Ram running in Singapore' has more SKUs with diffent costs:
		1. `71A5-A7E8-C37C` (cheaper = skipped)
		1. `C18E-DD54-9DD1`
	* Description 'Memory Optimized Upgrade Premium for Memory-optimized Instance Ram running in Singapore' has more SKUs with diffent costs:
		1. `1F3C-AD92-C1E7` (cheaper = skipped)
		1. `E2AD-9D0E-234E`
	* Description 'Memory Optimized Upgrade Premium for Memory-optimized Instance Core running in Singapore' has more SKUs with diffent costs:
		1. `79D9-7C0D-4C27` (cheaper = skipped)
		1. `9731-585C-311D`
	* Description 'Commitment v1: Memory-optimized Ram in Singapore for 1 Year' has more SKUs with diffent costs:
		1. `197C-25AD-D9F4`
		1. `833D-8EA6-D22E` (cheaper = skipped)
	* Description 'Commitment v1: Memory-optimized Cpu in Singapore for 1 Year' has more SKUs with diffent costs:
		1. `1A15-7952-674A` (cheaper = skipped)
		1. `F272-26B7-C2E9`
	* Description 'Commitment v1: Memory-optimized Ram in Singapore for 3 Year' has more SKUs with diffent costs:
		1. `4BD6-95B9-3CE4`
		1. `B042-ACE5-8F95` (same price = skipped)
	* Description 'Commitment v1: Memory-optimized Cpu in Singapore for 3 Year' has more SKUs with diffent costs:
		1. `09A6-C688-1278`
		1. `7BDA-424A-1067` (cheaper = skipped)

Time to generate the YML file with all cost informations for all regions takes a long time:

```
real    84m23.914s
user    81m47.547s
sys     1m41.969s
```

## Custom machine types

Own machine types can be defined as type `n1-custom`, `n2-custom` and `n2d-custom` in `gcp.yml`.

Example:
```yml
n1-custom-24-108:
  type: n1-custom
  cpu: 24
  ram: 108
  bandwidth: 16
```

In your usage file you can then use the machine type `n1-custom-24-108`.

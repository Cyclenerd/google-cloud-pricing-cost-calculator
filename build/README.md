# Build pricing information file

[![Badge: GNU Bash](https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?logo=gnubash&logoColor=white)](#)
[![Badge: Perl](https://img.shields.io/badge/Perl-%2339457E.svg?logo=perl&logoColor=white)](#)
[![Build Pricing](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/actions/workflows/build-pricing.yml/badge.svg)](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/actions/workflows/build-pricing.yml)

| 🤖 Automated |
|------------------------------------------------|
| The process of calculating and generation is done regularly and automatically via [GitHub Actions](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/actions/workflows/build-pricing.yml)! |

## Files

Configuration files and scripts for generating the YAML file `pricing.yml` with calculated Google Cloud Platform pricing information:

| File                 | Short Description |
|----------------------|-------------------|
| `services.pl`        | Script to export public services (`serviceId`) from the Cloud Billing Catalog. |
| `skus.sh`, `skus.go` | Script to export SKUs from the Google Cloud Billing API add the custom mapping IDs from `mapping.csv` to the SKUs (`skus.db`). |
| `skus.db`            | SQLite database file with SKU pricing and information exported from the Google Cloud Billing API. |
| `skus.sql`           | SQL to create the SQLite database `skus.db`. |
| `mapping.csv`        | CSV (semicolon) file with custom mapping IDs. Is read by the script `skus.sh` to add the custom mapping IDs to the SKUs (`skus.db`). |
| `mapping.sql`        | SQL to update the SQLite database `skus.db`. Used by `skus.sh`. |
| `pricing.pl`         | Script to calculate and generate pricing information file `pricing.yml`. |
| `pricing.yml`        | YAML file with calculated pricing information. |
| `gcp.yml`            | YAML file with Google Cloud Platform information. Is read by the script `pricing.pl` to calculate and generate pricing information file (`pricing.yml`). |

## Workflow

```
 +--------------------------+  +------------------------------+
 | Google Cloud Billing API |  | Custom mapping (mapping.csv) |
 +--------------------------+  +------------------------------+
               ↓                              ↓
 +------------------------------------------------------------+
 | » Export SKUs and add custom mapping IDs to SKUs (skus.sh) |
 +------------------------------------------------------------+
               ↓
 +----------------------------------+  +-----------------------------+
 | SKUs pricing with custom mapping |  | Google Cloud Platform info. |
 |             (skus.db)            |  |           (gcp.yml)         |
 +----------------------------------+  +-----------------------------+
                \                             /
         +--------------------------------------------------+
         | » Generate pricing information file (pricing.pl) |
         +--------------------------------------------------+
                              ↓
                +-------------------------------+
                |  GCP pricing information file |
                |          (pricing.yml)        |
                +-------------------------------+
```

### 1️⃣  Enable Google Cloud Billing API

More help: <https://cloud.google.com/billing/v1/how-tos/catalog-api>

1. Enable the [Cloud Billing API](https://console.cloud.google.com/flows/enableapi?apiid=cloudbilling.googleapis.com).
1. Get Cloud Billing Catalog API key
	1. Navigate to the [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials) panel in Cloud Console.
	1. Select **Create credentials**, then select **API key** from the dropdown menu.
	1. Copy your key and keep it secure.

### 2️⃣  Export SKUs and add custom mapping (`skus.sh` and `skus.go`)

Compile `skus` binary (more help in the section [Development](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/build#development)):
```bash
make native && ./skus --version
```

Export the SKU information of the Google Cloud Billing API to SQLite database (`skus.db`).

Google Cloud Billing API key should be specified as environment variable `API_KEY`:
```bash
export API_KEY=YOUR-CLOUD-BILLING-API-KEY
```

Alternatively, the API key can be stored in `skus.conf` configuration file:
```bash
echo "key = YOUR-CLOUD-BILLING-API-KEY" > skus.conf
```

Run the script `skus.sh` or each step separately:

```bash
bash skus.sh
```

> **Note**
> Get identifier (`-id`) for the Google Cloud services (`serviceId`) with script `services.pl`.

» [Google Cloud Billing Documentation](https://cloud.google.com/billing/v1/how-tos/catalog-api#getting_the_list_of_skus_for_a_service)

### 3️⃣  Generate pricing information file (`pricing.pl`)

Generate the YAML file with the Google Cloud Platform pricing informations for all regions:
```bash
perl pricing.pl
```

Save warning and erros in file `erros.log`:
```bash
perl pricing.pl 2> erros.log
```

Generate pricing informations only for region `europe-west4` with mapping details:
```bash
perl pricing.pl \
  -details=1                  \
  -region="europe-west4"      \
  -export="pricing_europe_west4.yml"
```

## Export services (`services.pl`)

Store API key in `services.conf` configuration file:
```bash
echo "key = YOUR-CLOUD-BILLING-API-KEY" > services.conf
```

Alternatively, the API key can be specified as environment variable `API_KEY`:
```bash
export API_KEY=YOUR-CLOUD-BILLING-API-KEY
```

Export public services from the Cloud Billing Catalog to a CSV file:
```bash
perl services.pl
```

The service ID is needed to export the SKUs with the `skus.sh` script in the build directory.
Only needed if you want to integrate the cost informations of a new service.

» [Google Cloud Billing Documentation](https://cloud.google.com/billing/v1/how-tos/catalog-api#listing_public_services_from_the_catalog)

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

## Development

If you want to modify the scripts and create the price information yourself,
the following requirements are needed.

### Gitpod

If you don't want to install all the tools locally yourself, you can use a [Gitpod](https://www.gitpod.io/).

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator)

### Development Containers

If you don't want to install all the tools locally yourself, you can also use a [Dev Container](https://containers.dev/).

To get started, you'll need these tools:

* [Visual Studio Code](https://code.visualstudio.com/): A popular code editor.
* [Remote Development Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack): This extension allows you to work directly inside containers.
* [Podman](https://podman.io/) or [Docker](https://www.docker.com/products/docker-desktop/): Containerization tools for running your development environment.

Try it out with the `Dev Containers: Reopen in Container` command:

![Screenshot: VS Code Dev Cointainer](../img/dev-containers-reopen.png)

### Requirements

A Bash shell `bash`, `gcloud`, `perl` and `go` are needed.

#### Google Cloud CLI

Use package manager (recommended) or follow [official guide](https://cloud.google.com/sdk/docs/install).

<details>
<summary><b>Debian/Ubuntu</b></summary>

Package:
```shell
sudo apt install apt-transport-https ca-certificates gnupg curl
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo gpg --dearmor -o "/usr/share/keyrings/cloud.google.gpg"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a "/etc/apt/sources.list.d/google-cloud-sdk.list"
sudo apt update
sudo apt install google-cloud-cli
```

</details>

<details>
<summary><b>macOS</b></summary>

Homebrew package:
```bash
brew install --cask google-cloud-sdk
```

</details>

#### Perl

Perl 5 is already installed on many Linux (Debian/Ubuntu, RedHat, SUSE) and UNIX (macOS, FreeBSD) operating systems.
For MS Windows you can download and install [Strawberry Perl](https://strawberryperl.com/).

* Perl 5 (`perl`)
* Perl modules:
	* [App::Options](https://metacpan.org/pod/App::Options)
	* [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
	* [JSON::XS](https://metacpan.org/pod/JSON::XS)
	* [YAML::XS](https://metacpan.org/pod/YAML::XS) (and `libyaml`)
	* [DBD::CSV](https://metacpan.org/pod/DBD::CSV)
	* [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)

<details>
<summary><b>Debian/Ubuntu</b></summary>

Packages:
```bash
sudo apt update && \
sudo apt install \
	libapp-options-perl \
	libwww-perl \
	libjson-xs-perl \
	libyaml-libyaml-perl \
	libdbd-csv-perl \
	libdbd-sqlite3-perl \
	sqlite3
```
</details>

<details>
<summary><b>macOS</b></summary>

Homebrew packages:
```bash
brew install perl
brew install cpanminus pkg-config
brew install sqlite3
```

Install Perl modules with cpanminus:
```bash
cpanm --installdeps .
```
</details>

Execute `pricing.pl`:
```bash
perl pricing.pl --help
```

#### Go Programming Language

Use package manager (recommended) or follow [official guide](https://go.dev/learn/).

<details>
<summary><b>Debian/Ubuntu</b></summary>

Packages:
```bash
sudo apt update && \
sudo apt install golang-go
```
</details>

<details>
<summary><b>macOS</b></summary>

Homebrew packages:
```bash
brew install go
```
</details>

Compile `skus` binary:
```bash
make native && ./skus --version
```

## Special curls

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

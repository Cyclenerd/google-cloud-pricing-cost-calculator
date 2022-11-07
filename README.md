# Google Cloud Platform Pricing and Cost Calculator

[![Bagde: Google Cloud](https://img.shields.io/badge/Google%20Cloud-%234285F4.svg?logo=google-cloud&logoColor=white)](#readme)
[![Bagde: Linux](https://img.shields.io/badge/Linux-FCC624.svg?logo=linux&logoColor=black)](#1-get-gcosts-program)
[![Bagde: Windows](https://img.shields.io/badge/Windows-008080.svg?logo=windows95&logoColor=white)](#1-get-gcosts-program)
[![Bagde: CI](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/actions/workflows/test.yml/badge.svg)](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/actions/workflows/test.yml)
[![Bagde: GitHub](https://img.shields.io/github/license/cyclenerd/google-cloud-pricing-cost-calculator)](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/LICENSE)
[![Bagde: Reddit](https://img.shields.io/reddit/subreddit-subscribers/googlecloud?label=Google%20Cloud%20Platform&style=social)](https://www.reddit.com/r/googlecloud/comments/svn8kj/google_cloud_platform_pricing_and_cost_calculator/)

[![Image: Google Open Source Peer Bonus winner 2022](./img/open_source_peer%20bonus_winner_2022.jpg)](https://opensource.googleblog.com/2022/09/announcing-the-second-group-of-open-source-peer-bonus-winners-in-2022.html)

Calculate estimated monthly costs of Google Cloud Platform products and resources.
Optimized for DevOps, architects and engineers to quickly see a cost breakdown and compare different options upfront:

* Mapping of resource usage is done in easy to learn **YAML** usage files
* Price information is read from a local file
* Calculation is done via `gcosts` **CLI** program
* Calculated costs are saved in **CSV** files

Full control and no disclosure of any information and costs to third parties.
Everything tested and matched against the actual invoice in large Google Cloud migration projects.

![Screenshot: YAML usage file, gcosts and CSV costs file](https://raw.githubusercontent.com/Cyclenerd/google-cloud-pricing-cost-calculator/master/img/gcosts-usage-costs.jpg?v1)


## ☁️ Supported resources

The cost of a resource is calculated by multiplying its price by its usage.

| 💡 Google Cloud Free Program |
|------------------------------------------------|
| Free tiers and free trial (90-day, $300), which are usually not a significant part of cloud costs, are ignored. For example: 1x free non-preemptible `e2-micro` VM instance per month, free NAT for 32 VMs, 30 GB-months standard persistent disk, 1 GB network egress and everything [else](https://cloud.google.com/free/docs/gcp-free-tier/#compute) are not taken into account. |

Resources that `gcosts` supports, and Google charges for:

<details>
<summary>🖥️ <b>Compute Engine Instances</b></summary>

- [x] All machine types are supported
	- [x] Cost-optimized (`E2`, `F1`, `G1`)
	- [x] Balanced (`N1`, `N2`, `N2D`)
	- [x] Scale-out optimized (Tau `T2D` and `T2A`)
	- [x] Memory-optimized (`M1`, `M2`)
	- [x] Compute optimized (`C2`, `C2D`)
	- [x] Accelerator optimized (`A2`)
- [x] Sustained use discounts (SUD) are applied to monthly costs
- [x] 1 year and 3 year committed use discounts (CUD) are supported
- [x] Paid "premium" operating system licenses (paid images) are supported
	- [x] SUSE Linux Enterprise Server
	- [x] SLES for SAP (1y and 3y committed use discounts (CUD) are also supported)
	- [x] Red Hat Enterprise Linux
	- [x] RHEL for SAP
	- [x] Windows Server
- [x] Custom machine types are supported (have to be created manually)
- [ ] Spot and sole-tenant VMs are not supported
</details>

<details>
<summary>💾 <b>Compute Engine Disks</b></summary>

- [x] All persistent disk (PD) types are supported
	- [x] Zonal persistent disk
	- [x] Regional persistent disk
	- [x] Local SSD
</details>

<details>
<summary>🪣 <b>Cloud Storage</b></summary>

- [x] All storage classes and location types are supported
	- [x] region
	- [x] dual-region
	- [x] multi-region
</details>

<details>
<summary>🚇 <b>Hybrid Connectivity</b></summary>

- [x] VPN tunnel
- [ ] Interconnect is currently not calculated
</details>

<details>
<summary>🔗 <b>Cloud NAT</b></summary>

- [x] NAT gateway
- [x] Data processing (both egress and ingress)
</details>


<details>
<summary>🤹 <b>Cloud Load Balancing</b></summary>

- [x] Forwarding rules
- [x] Ingress data processed by load balancer
</details>

<details>
<summary>🚦 <b>Cloud Monitoring (Operations Suite)</b></summary>

- [x] Monitoring data
</details>

<details>
<summary>🕸️ <b>Network</b></summary>

- [x] Premium Tier internet egress
	- [x] Worldwide destinations (excluding China & Australia, but including Hong Kong)
	- [x] China destinations (excluding Hong Kong)
	- [x] Australia destinations
</details>

<details>
<summary>🏗️ <b>TODO</b></summary>

The following services are not currently supported, but are on the TODO list:

- [ ] BigQuery
- [ ] Cloud SQL

Please suggest other resources worth covering by upvoting existing issue or opening new issue.
</details>


## 🧑‍🏫 Start the interactive tutorial

This guide is available as an interactive Cloud Shell tutorial.
To get started, please click the following button:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator&cloudshell_git_branch=master&cloudshell_tutorial=cloud-shell-tutorial.md)


## 🏃 Quick start

### 1. Get `gcosts` program

<details>
<summary>Linux</summary>

**Debian/Ubuntu or Google Cloud Shell (x86_64)**

[Download](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/releases/latest) the executable `gcosts` Linux CLI program:
```shell
curl -OL "https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/releases/latest/download/gcosts" && \
chmod +x gcosts
```

Execute `gcosts`:
```shell
./gcosts --help
```

If you using another Linux or UNIX operating system, please see the [Development](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator#-development) section.
</details>

<details>
<summary>Windows</summary>

**Microsoft Windows (x86_64)**

[Download](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/releases/latest) the executable `gcosts.exe` Windows CLI program:
```powershell
Invoke-WebRequest -Uri "https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/releases/latest/download/gcosts.exe" -OutFile "gcosts.exe"
```

Execute `gcosts.exe`:
```powershell
.\gcosts.exe --help
```
</details>

### 2. Download price information

<details>
<summary>Linux</summary>

[Download](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/raw/master/pricing.yml) the latest and tested price information file `pricing.yml`:
```shell
curl -L "https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/raw/master/pricing.yml" \
     -o "pricing.yml"
```
</details>

<details>
<summary>Windows</summary>

[Download](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/raw/master/pricing.yml) the latest and tested price information file `pricing.yml`:
```powershell
Invoke-WebRequest -Uri "https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/raw/master/pricing.yml" -OutFile "pricing.yml"
```
</details>

### 3. Run it

Create your first YAML usage file (`usage.yml`):
```yml
region: europe-west4
project: my-first-project
instances:
  - name: app-server
    type: e2-standard-8
    os: rhel
    commitment: 3
    disks:
      - name: disk-boot
        type: ssd
        data: 75
```

Execute the CLI program:

<details>
<summary>Linux</summary>

Execute `gcosts`:
```shell
./gcosts
```
</details>

<details>
<summary>Windows</summary>

Execute `gcosts.exe`:
```powershell
.\gcosts.exe
```
</details>

All YAML usage files (`*.yml`) of the current directory are imported and the costs of the resources are calculated:

Two CSV (semicolon) files with the costs are created:

1. `COSTS.csv`  : Costs for resources
1. `TOTALS.csv` : Total costs per name, resource, project, region and file

You can import the CSV files with MS Excel, [LibreOffice](usage/libreoffice.md) or [Google Sheets](usage/google_sheets.md).

### 4. Get familiar

Continue to familiarize yourself with the options. The following documentations are prepared for this purpose:

* [Create usage files](usage/)
* [Build pricing information file](build/)

**🤓 Linux Tip**

Add `gcosts` to your Bash aliases with absolute pathnames. You can then execute `gcosts` anywhere.

Alias (`~/.bash_aliases`):
```shell
alias gcosts='/your-pathname/gcosts -pricing=/your-pathname/pricing.yml'
```


## 🧑‍💻 Development

If you want to modify the Perl scripts or prefer to run the uncompiled Perl scripts (`gcosts.pl`, `skus.pl`, `mapping.pl`, `pricing.pl`) and create the price information yourself,
the following requirements are needed.

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator)

Perl 5 is already installed on many Linux (Debian/Ubuntu, RedHat, SUSE) and UNIX (macOS, FreeBSD) operating systems.
For MS Windows you can download and install [Strawberry Perl](https://strawberryperl.com/).

### Requirements

* Perl 5 (`perl`)
* Perl modules:
	* [App::Options](https://metacpan.org/pod/App::Options)
	* [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
	* [JSON::XS](https://metacpan.org/pod/JSON::XS)
	* [YAML::XS](https://metacpan.org/pod/YAML::XS) (and `libyaml`)
	* [DBD::CSV](https://metacpan.org/pod/DBD::CSV)
	* [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)

Debian/Ubuntu:
```shell
sudo apt update && \
sudo apt install \
	libapp-options-perl \
	libwww-perl \
	libjson-xs-perl \
	libyaml-libyaml-perl \
	libdbd-csv-perl \
	libdbd-sqlite3-perl
```

Or install Perl modules with cpanminus:
```shell
cpan App::cpanminus && \
cpanm --installdeps .
```

Execute `gcosts.pl`:
```shell
perl gcosts.pl --help
```


## ❤️ Contributing

Have a patch that will benefit this project?
Awesome! Follow these steps to have it accepted.

1. Please read [how to contribute](CONTRIBUTING.md).
1. Fork this Git repository and make your changes.
1. Create a Pull Request.
1. Incorporate review feedback to your changes.
1. Accepted!


## 📜 License

All files in this repository are under the [Apache License, Version 2.0](LICENSE) unless noted otherwise.

Please note:

* No warranty
* No official Google product
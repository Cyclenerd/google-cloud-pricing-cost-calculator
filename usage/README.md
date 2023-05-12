# Usage file

The configuration of the required resources is done in YAML files.

The `gcosts` program always imports all YAML usage files (`*.yml`) of the directory.

The files are read in sorted order. You can therefore use the file names for an order.

Configurations are kept in memory and used for other files. Example:

1.yml:
```yml
region: europe-west4
project: test
```

2.yml:
```yml
buckets:
  - name: bucket
    class: standard
    data: 50
```

First `1.yml` and then `2.yml` is read.
The values `region` and `procect` from `1.yml` are also valid for `2.yml`.
So the cost for the bucket is calculated with region `europe-west4`.

## Configuration

### 📍 Region

Set Google region:

```yml
region: GOOGLE-REGION
```

Display all supported regions:
```bash
gcosts region
```
An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>

### 📁 Project

Set project name:

```yml
project: PROJECT-NAME
```

### 🈹 Discount

If Goolge gives you a discount on all resources (SKUs), you can set the discount:

```yml
discount: DISCOUNT-AS-FLOAT
```

The cost is multiplied by the value.

* 15% discount = 0.85
* 20% discount = 0.80
* 30% discount = 0.70
* 40% discount = 0.60

You can also use the discount for currency conversion.

Convert US Dollars to Euros:
```yml
# 1.00 US Dollar = 0.882 Euros
discount: 0.882
```

## Resources

### 🖥️ Compute Engine Instances

```yml
instances:
  - name: SERVER-NAME
    region: GOOGLE-REGION
    type: MACHINE-TYPE
    spot: true or false
    commitment: 0, 1 or 3
    discount: DISCOUNT-AS-FLOAT
    terminated: true or false
    os: sles, sles-sap, rhel, rhel-sap or windows
    external-ip: 0 or n
    disks:
      - name: DISK-NAME
        data: SIZE-IN-GiB
        type: DISK-TYPE
    buckets:
      - name: BUCKET-NAME
        class: BUCKET-CLASS
        region: GOOGLE-BUCKET-REGION
        data: SIZE-IN-GiB
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Machine types `type`:
    * Display all supported machine types:
      ```bash
      gcosts compute instance
      ```
    * An overview and comparison of all [machine types](https://gcloud-compute.com/instances.html) can also be found on the website: <https://gcloud-compute.com/instances.html>
* Spot provisioning model `spot` (optional):
    * `true` : Calculate with Spot VM price
    * `false` : Calculate with normal standard price
* Commitment (CUD) `commitment` (optional):
    * `1` : 1 year
    * `3` : 3 years
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Set the state `terminated` (optional):
  * `true` : Stopped instance
  * `false` (default) : Instance price is calculated
* Operating systems `os` (optional):
  * Display all supported operating systems:
    ```bash
    gcosts compute license
    ```
  * `sles`     : SUSE Linux Enterprise Server
  * `sles-sap` : SUSE Linux Enterprise Server for SAP
  * `rhel`     : Red Hat Enterprise Linux
  * `rhel-sap` : Red Hat Enterprise Linux for SAP
  * `windows`  : Windows Server
* External IP address `external-ip` (optional): 
  * `1` - `n`: Amount of external public IP addresses used
* Persistent storage `disks`:
  * Please see [Compute Engine Disks](#-compute-engine-disks)
* Cloud Storage `buckets`:
  * Please see [Cloud Storage](#-cloud-storage)

### 💾 Compute Engine Disks

Persistent disks.

```yml
disks:
  - name: DISK-NAME
    region: GOOGLE-REGION
    discount: DISCOUNT-AS-FLOAT
    type: DISK-TYPE
    data: SIZE-IN-GiB
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Persistent disk type `type`:
  * Display all supported disk types:
    ```bash
    gcosts compute disk
    ```
  * Standard persistent disks
    * `hdd`                 : Zonal persistent disk
    * `hdd-replicated`      : Regional persistent disk (replicated)
  * Balanced persistent disks
    * `balanced`            : Zonal persistent disk
    * `balanced-replicated` : Regional persistent disk (replicated)
  * SSD persistent disks
    * `ssd`                 : Zonal persistent disk
    * `ssd-replicated`      : Regional persistent disk (replicated)
  * Extreme persistent disks
    * `extreme`             : Zonal persistent disk
  * Hyperdisk Extreme persistent disks
    * `hyperdisk-extreme`   : Zonal persistent disk
  * Local SSDs
    * `local`               : Zonal persistent disk
  * Snapshots
    * `snapshot` : Snapshots of persistent disks

Regional persistent disk = Replication of data between two zones in the same region.

Google Cloud API names:

| gcloud      | gcosts     |
|-------------|------------|
| local-ssd   | `local`    |
| pd-balanced | `balanced` |
| pd-extreme  | `extreme`  |
| pd-ssd      | `ssd`      |
| pd-standard | `hdd`      |

You can create snapshots of persistent disks to protect against data loss due to user error.
Snapshots are incremental, and take only minutes to create even if you snapshot disks that are attached to running instances.
Snapshots can be region or multi-region.

Supported regions `region`:

* Display all supported regions:
  ```bash
  gcosts region
  ```
* Display all supported multi-regions:
  ```bash
  gcosts region multi
  ```
  * `asia-multi`   : Data centers in Asia
  * `europe-multi` : Data centers within member states of the European Union
  * `us-multi`     : Data centers in the United States

### 🪣 Cloud Storage

Cloud Storage buckets.

```yml
buckets:
  - name: BUCKET-NAME
    region: BUCKET-REGION
    discount: DISCOUNT-AS-FLOAT
    class: BUCKET-CLASS
    data: SIZE-IN-GiB
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * Display all supported dual-regions:
      ```bash
      gcosts region dual
      ```
    * Display all supported multi-regions:
      ```bash
      gcosts region multi
      ```
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Storage classes `class`:
  * Display all supported storage classes:
    ```bash
    gcosts storage bucket
    ```
  * Standard Storage
    * `standard`       : Objects stored in region
    * `standard-dual`  : Objects stored in dual-regions
    * `standard-multi` : Objects stored in multi-regions
  * Nearline Storage
    * `nearline`       : Objects stored in region
    * `nearline-dual`  : Objects stored in dual-regions
    * `nearline-multi` : Objects stored in multi-regions
  * Coldline Storage
    * `coldline`       : Objects stored in region
    * `coldline-dual`  : Objects stored in dual-regions
    * `coldline-multi` : Objects stored in multi-regions
  * Archive Storage
    * `archiv`       : Objects stored in region
    * `archiv-dual`  : Objects stored in dual-regions
    * `archiv-multi` : Objects stored in multi-regions
  * Durable Reduced Availability (DRA) Storage
    * `dra`       : Objects stored in region
    * `dra-dual`  : Objects stored in dual-regions
    * `dra-multi` : Objects stored in multi-regions

### 🚇 Cloud VPN

Tunnels attached to the Cloud VPN gateway.
Both Classic VPN and HA VPN are supported and are the same price.

```yml
vpn-tunnels:
  - name: VPV-TUNNEL-NAME
    region: GOOGLE-REGION
    discount: DISCOUNT-AS-FLOAT
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value

If the Cloud VPN tunnel connects to a VPN gateway outside of Google Cloud,
you are charged for Internet egress.
You specify this in the `traffic` resource.

### 🔗 Cloud NAT

NAT gateway and GiB processed.

```yml
nat-gateways:
  - name: NAT-GATEWAY-NAME
    region: GOOGLE-REGION
    discount: DISCOUNT-AS-FLOAT
    data: INGRESS-AND-EGRESS-TRAFFIC-IN-GiB
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Ingress and egress `data`:
  * You have to pay ingress __and__ egress data that is processed by the NAT gateway

### 🚦 Cloud Monitoring

Monitoring data for Cloud Monitoring and all Google Cloud metrics.

```yml
monitoring:
  - name: MONI-NAME
    region: GOOGLE-REGION
    discount: DISCOUNT-AS-FLOAT
    data: SIZE-IN-MiB-NOT-GiB # mebibyte (MiB) !!!
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Monitoring `data`:
  * Amount of data in mebibyte (MiB) not GiB

### 🕸️ Network

Internet egress traffic:

```yml
traffic:
  - name: TRAFFIC-NAME
    region: GOOGLE-REGION
    discount: DISCOUNT-AS-FLOAT
    world: EGRESS-TRAFFIC-IN-GiB
    china: EGRESS-TRAFFIC-IN-GiB
    australia: EGRESS-TRAFFIC-IN-GiB
```

* Resource name `name` (recommended):
    * Choose a short name so that you can identify the resource
* Google region `region` (optional if default region is set):
    * Display all supported regions:
      ```bash
      gcosts region
      ```
    * An overview of all supported [regions](https://gcloud-compute.com/regions.html) can also be found on the website: <https://gcloud-compute.com/regions.html>
* Discount `discount` (optional):
  * The calculated cost is multiplied by the value
* Destinations:
  * `world` : Worldwide (excluding China & Australia, but including Hong Kong)
  * `china` : China (excluding Hong Kong)
  * `australia` : Australia

Premium Tier is the default tier for all Google Cloud egress.
Cost calculation for Standard Tier not supported.

No charge for ingress traffic.

## Example

[example.yml](./example.yml):
```yml
region: europe-west4
project: my-first-project
vpn-tunnels:
  - name: vpn-tunnel-cloud-to-home
nat-gateways:
  - name: gateway-internet
    data: 300
traffic:
  - name : vpn-traffic-egrees
    world: 100
  - name : internet-traffic-egrees
    world: 150
  - name : more-traffic-egrees
    world: 100
    china: 100
    australia: 100

monitoring:
  - name: stackdriver
    data: 6000 # mebibyte!

instances:
  - name: app-server
    type: n1-standard-8
    os: rhel
    commitment: 3
    disks:
      - name: disk-boot
        type: ssd
        data: 75
      - name: disk-boot-snaphot
        type: snapshot
        data: 10
        region: europe-multi
      - name: disk-data
        type: hdd
        data: 1000

buckets:
  - name: app-server-bucket-dualregion
    class: nearline-dual
    data: 1000
    region: eur4
```

Many more example are in the [test folder](../t) `t`.
# Usage file

The configuration of the required resources is done in YAML files.

The `gcosts` program always imports all YAML usage files (`*.yml`) of the current directory.

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

Supported regions can be found in [gcp.yml](../build/gcp.yml).

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
    type: MACHINE-TYPE
    commitment: 0, 1 or 3
    os: free, sles, sles-sap, rhel, rhel-sap or windows
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

* Supported machine types `type`:
    * Please see `instance` in [gcp.yml](../build/gcp.yml).
    * An overview and comparison of all [machine types](https://gcloud-compute.com/instances.html) can be found on the website: [https://gcloud-compute.com](https://gcloud-compute.com/)
* Commitment `commitment`:
    * `1` : 1 year
    * `3` : 3 years
* Supported operating systems `os`:
    * `free` : Cost-neutral operating systems
        * `debian` : Debian GNU/Linux
        * `ubuntu` : Ubuntu
        * `centos` : CentOS
        * `rocky*` : Rocky Linux
        * `*byos`  : Bring your operating system
    * `sles`     : SUSE Linux Enterprise Server
    * `sles-sap` : SUSE Linux Enterprise Server for SAP
    * `rhel`     : Red Hat Enterprise Linux
    * `rhel-sap` : Red Hat Enterprise Linux for SAP
    * `windows`  : Windows Server
* External IP address `external-ip` : Amount of external public IP addresses used


You can also set the state `state`:
  * `terminated` : Stopped instance
    * Instance price is set to 0 if no commitment
    * Operating systems price is set to 0 if no commitment
    * Static external IP address (assigned but unused) charged
  * `running` (default) : Instance price is calculated

### 💾 Compute Engine Disks

Persistent disks.

```yml
disks:
  - name: DISK-NAME
    region: GOOGLE-REGION
    type: DISK-TYPE
    data: SIZE-IN-GiB
```

Available disk types `type`:

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

| gcloud      | gcosts   |
|-------------|----------|
| local-ssd   | local    |
| pd-balanced | balanced |
| pd-extreme  | extreme  |
| pd-ssd      | ssd      |
| pd-standard | hdd      |

You can create snapshots of persistent disks to protect against data loss due to user error.
Snapshots are incremental, and take only minutes to create even if you snapshot disks that are attached to running instances.
Snapshots can be region or multi-region.

Supported regions `region`:

* Regions : Please see `region` in [gcp.yml](../build/gcp.yml).
* Multi-Regions : Please see `multi-region` in [gcp.yml](../build/gcp.yml)
    * `asia-multi`   : Data centers in Asia
    * `europe-multi` : Data centers within member states of the European Union
    * `us-multi`     : Data centers in the United States

### 🪣 Cloud Storage

Cloud Storage buckets.

```yml
buckets:
  - name: BUCKET-NAME
    region: BUCKET-REGION
    class: BUCKET-CLASS
    data: SIZE-IN-GiB
```

Available storage classes `class`:

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

Supported regions `region`:

* Regions : Please see `region` in [gcp.yml](../build/gcp.yml).
* Dual-Regions : Please see `dual-region` in [gcp.yml](../build/gcp.yml)
    * `asia1`
    * `eur4`
    * `nam4`
* Multi-Regions : Please see `multi-region` in [gcp.yml](../build/gcp.yml)
    * `asia-multi`   : Data centers in Asia
    * `europe-multi` : Data centers within member states of the European Union
    * `us-multi`     : Data centers in the United States

### 🚇 Cloud VPN

Tunnels attached to the Cloud VPN gateway.
Both Classic VPN and HA VPN are supported and are the same price.

```yml
vpn-tunnels:
  - name: VPV-TUNNEL-NAME
```

If the Cloud VPN tunnel connects to a VPN gateway outside of Google Cloud,
you are charged for Internet egress.
You specify this in the `traffic` resource.

### 🔗 Cloud NAT

NAT gateway and GiB processed.

```yml
nat-gateways:
  - name: NAT-GATEWAY-NAME
    data: INGRESS-AND-EGRESS-TRAFFIC-IN-GiB
```

You have to pay ingress __and__ egress data that is processed by the NAT gateway.

### 🤹 Cloud Load Balancing

Load balancing and forwarding rules.

```yml
load-balancers:
  - name: LB-NAME
    rules: LB-RULES
    data: INGRESS-TRAFFIC-IN-GiB
```

You have to pay ingress data processed by the load balancer.

### 🚦 Cloud Monitoring

Monitoring data for Cloud Monitoring and all Google Cloud metrics.

```yml
monitoring:
  - name: MONI-NAME
    data: SIZE-IN-MiB-NOT-GiB # mebibyte (MiB) !!!
```

### 🕸️ Network

Internet egress traffic:

```yml
traffic:
  - name: TRAFFIC-NAME
    world: EGRESS-TRAFFIC-IN-GiB
    china: EGRESS-TRAFFIC-IN-GiB
    australia: EGRESS-TRAFFIC-IN-GiB
```

Destinations:

* `world` : Worldwide (excluding China & Australia, but including Hong Kong)
* `china` : China (excluding Hong Kong)
* `australia` : Australia

Premium Tier is the default tier for all Google Cloud egress.
Cost calculation for Standard Tier not supported.

No charge for ingress traffic.
# Tests

Calculated values are checked against values calculated with the official [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator/).

## Google Cloud Pricing Calculator

### Traffic

* 1025 GiB from Europe to America: [122.99](https://cloud.google.com/products/calculator/#id=ced21c73-18a2-4318-a85c-d528a4d51871)
	* Bulk: `1024 GiB * 0.12 + 1 GiB * 0.1`

### Load Balancing

* 1 rule without traffic in Netherlands: [20.44](https://cloud.google.com/products/calculator/#id=a0b3d7ea-c302-45cb-96a3-3d08ad0bcae3) (min.)
* 5 rule without traffic in Netherlands: [20.44](https://cloud.google.com/products/calculator/#id=4a37c28a-8608-4538-8a78-49b2102dce01) (min., same as 1)
* 6 rules without traffic in Netherlands: [28.47](https://cloud.google.com/products/calculator/#id=050901e3-2d0c-4253-8f96-48db763233c2) (min. + 1 add.)
* 6 rules and 500 GiB traffic in Netherlands: [32.97](https://cloud.google.com/products/calculator/#id=5c284335-23e1-4ec9-a4d1-e845ef401554) (min. + 1 add. + data)

### Monitoring

» [Operations Suite Pricing](https://cloud.google.com/monitoring#pricing)

*  Monitoring data:
	* $0/MiB      : < 150MiB
	* $0.2580/MiB : 150–100,000 MiB
	* $0.1510/MiB : 100,000–250,000 MiB
	* $0.0610/MiB : >250,000 MiB
* Volume of monitoring data: 6,150 MiB (6000+150MiB to ignore free MiB): [USD 1,548.00](https://cloud.google.com/products/calculator/#id=096d19d3-e932-4030-b7e4-55d2dc55bd50)

### Instances (VM) in Netherlands (`europe-west4`)

* a2-highgpu-8g
	* Month:    21888.16
	* Month with 1 year commitment term: 13789.38
	* Month with 3 year commitment term: [7661.01](https://cloud.google.com/products/calculator/#id=b7514aa1-0965-4d1f-9343-57729ff7fa6b)
* n1-standard-8
	* Month: 213.77
	* Month 1Y: 192.38
	* Month 3Y: [137.43](https://cloud.google.com/products/calculator/#id=809774e9-50a0-4449-b498-53104aae96ad)
* m1-ultramem-80
	* Month:     6762.05
	* Month 1Y:  5692.77
	* Month 3Y: [2898.99](https://cloud.google.com/products/calculator/#id=f34a6886-ab71-4c6d-8ad4-b103025ce954)
* m2-ultramem-416
	* Month:     45224.32
	* Month 1Y:  38915.02
	* Month 3Y: [22371.46](https://cloud.google.com/products/calculator/#id=b19741aa-7ebe-4e1c-8cfb-e384f377afad)

### Disks

* 2,048 GiB Zonal standard PD in Netherlands: [USD 90.11](https://cloud.google.com/products/calculator/#id=b58d78cc-00e6-455d-9025-ad03afc921ce)
* 1,024 GiB Zonal SSD PD in Netherlands: [USD 191.49](https://cloud.google.com/products/calculator/#id=6e91da3e-4dbf-41f6-8b90-341dcf59fba2)

### Standard Storage (Bucket)

* 1 GiB in Netherlands: [0.020](https://cloud.google.com/products/calculator/#id=4802e205-ed93-4ed7-934a-364ea56a49ec)
	* 50 GiB: [USD 1.00](https://cloud.google.com/products/calculator/#id=98371b66-de19-4a39-a4e7-bf13eaa23dad)
* 1 GiB in Europe: [0.026](https://cloud.google.com/products/calculator/#id=4802e205-ed93-4ed7-934a-364ea56a49ec)
	* 50 GiB: [USD 1.30](https://cloud.google.com/products/calculator/#id=d928692d-dd31-488a-a977-ac40ccbd70e3)
* 1 GiB in Finland/Netherlands: [0.036](https://cloud.google.com/products/calculator/#id=4802e205-ed93-4ed7-934a-364ea56a49ec)
	* 50 GiB: [USD 1.80](https://cloud.google.com/products/calculator/#id=f78a02ff-b4df-41f9-8b08-01bd41dc9ba9)

### Instances (VM) with paid OS, Disks and Bucket in Netherlands (`europe-west4`)

» [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator/#id=5c806af2-1936-408e-87b0-4a94a62008c5)

* 730 total hours per month
* Commitment term: 3 Years
* Instance type `n1-standard-16`                   : USD 274.86
* Operating System / Software                      : USD 107.75
* Zonal SSD PD: 75 GiB                             : USD 14.03
* Zonal SSD PD 150 GiB                             : USD 28.05
* Snapshot storage: 300 GiB                        : USD 8.70 (2.90 + 5.80)
* Nearline Storage 1,024 GiB (Finland/Netherlands) : USD 20.48

## Known bugs

* Calculated costs for load balancing are slightly lower (cents) than if you calculate it with the Google calculator.
* Calculated costs for the large M2 instances are slightly higher than if you calculate it with the Google calculator.
	* VM `m2-ultramem-416` with 3Y commitment = 22371.46 vs 22374.64758848

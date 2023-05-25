#!/usr/bin/env bash

MY_CHECKS=(
# HEADER
	'Project,Region,Resource,Type/Class,Name,Cost,Data,CUD,Discount,File'

# 00_europe-west4.yml
	# Monitoring
	'default-project-id,europe-west4,monitoring,data,stackdriver,1547'
	# Traffic
	'default-project-id,europe-west4,network,traffic,traffic-world,122'
	# Standard storage
	'default-project-id,europe-west4,bucket,standard,bucket-standard,1.0'
	'default-project-id,europe-multi,bucket,standard-multi,bucket-standard-multi,1.3'
	'default-project-id,eur4,bucket,standard-dual,bucket-standard-dual,2.2'
	# Disk
	'default-project-id,europe-west4,disk,ssd,disk-ssd,191'
	'default-project-id,europe-west4,disk,hdd,disk-hdd,90'
	'default-project-id,europe-west4,disk,hyperdisk-extreme,disk-hyperdisk-extreme,134'

# 01_europe-west4-a2.yml
	# A2 machine types
	'a2-highgpu-1g,2736'   # Google Cloud Pricing Calculator: $2736.02, Price List: $2739.74
	'a2-highgpu-2g,5472'   # Google Cloud Pricing Calculator: $5472.04 , Price List: $5479.47
	'a2-highgpu-4g,10944'  # Google Cloud Pricing Calculator: $10944.08, Price List: $10958.95
	'a2-highgpu-8g,21888'  # Google Cloud Pricing Calculator: $21888.16, Price List: $21917.89
	'a2-megagpu-16g,41337' # Google Cloud Pricing Calculator: $41337.39, Price List: $41396.86
	# A2 Commitment (CUD)
	'gcp-gce-a2,europe-west4,vm,a2-highgpu-8g,a2-highgpu-8g-1y,13789' # Google Cloud Pricing Calculator: $13789.38, Price List: $13787.27
	'gcp-gce-a2,europe-west4,vm,a2-highgpu-8g,a2-highgpu-8g-3y,7661'  # Google Cloud Pricing Calculator: $7661.01, Price List: $7661.79
	'a2-highgpu-8g-spot,'

# 01_europe-west4-c2.yml
	# C2 machine types
	'c2-standard-4,134'
	'c2-standard-8,268'
	'c2-standard-16,537'
	'c2-standard-30,1007'
	'c2-standard-60,2014'
	# C2 Commitment (CUD)
	'gcp-gce-c2,europe-west4,vm,c2-standard-8,c2-standard-8-1y,211'
	'gcp-gce-c2,europe-west4,vm,c2-standard-8,c2-standard-8-3y,134'
	'c2-standard-8-spot,'

# 01_europe-west4-c2d.yml
	# C2D machine types
	'c2d-standard-2,72'
	'c2d-standard-4,145'
	'c2d-standard-8,291'
	'c2d-standard-16,583'
	'c2d-standard-32,1167'
	'c2d-standard-56,2043'
	'c2d-standard-112,4086'
	'c2d-highmem-2,98'
	'c2d-highmem-4,196'
	'c2d-highmem-8,393'
	'c2d-highmem-16,787'
	'c2d-highmem-32,1575'
	'c2d-highmem-56,2756'
	'c2d-highmem-112,5512'
	# C2D Commitment (CUD)
	'gcp-gce-c2d,europe-west4,vm,c2d-standard-8,c2d-standard-8-1y,183'
	'gcp-gce-c2d,europe-west4,vm,c2d-standard-8,c2d-standard-8-3y,131'
	'c2d-standard-8-spot,'

# 01_europe-west4-c3.yml
	# C3 machine types
	'c3-highcpu-4,138'
	'c3-highcpu-8,277'
	'c3-highcpu-22,761'
	'c3-highcpu-44,1523'
	'c3-highcpu-88,3047'
	'c3-highcpu-176,6095'
	# C3 Commitment (CUD)
	# TODO: Check again when C3 is GA
	'gcp-gce-c3,europe-west4,vm,c3-highcpu-8,c3-highcpu-8-1y,174'
	'gcp-gce-c3,europe-west4,vm,c3-highcpu-8,c3-highcpu-8-3y,124'
	'c3-highcpu-8-spot,'

# 01_europe-west4-e2.yml
	# E2 machine types
	'e2-standard-2,53'
	'e2-standard-4,107'
	'e2-standard-8,215'
	'e2-standard-16,430'
	'e2-standard-32,861'
	'e2-highmem-2,72'
	'e2-highmem-4,145'
	'e2-highmem-8,290'
	'e2-highmem-16,581'
	'e2-highcpu-2,39'
	'e2-highcpu-4,79'
	'e2-highcpu-8,159'
	'e2-highcpu-16,318'
	'e2-highcpu-32,636'
	'e2-micro,6.73'
	'e2-small,13.46'
	'e2-medium,26.9'
	# E2 Commitment (CUD)
	'gcp-gce-e2,europe-west4,vm,e2-standard-8,e2-standard-8-1y,135'
	'gcp-gce-e2,europe-west4,vm,e2-standard-8,e2-standard-8-3y,96'
	'e2-standard-8-spot,'

# 01_europe-west4-g2.yml
	# G2 machine types // Price List accessed on: 2023-04-23 // TODO: Check calculator
	'g2-standard-4,5'   # Google Cloud Pricing Calculator: ???,  Price List: $570.59209
	'g2-standard-8,6'   # Google Cloud Pricing Calculator: ??? , Price List: $688.58345
	'g2-standard-12,8'  # Google Cloud Pricing Calculator: ???,  Price List: $806.57554
	'g2-standard-16,9'  # Google Cloud Pricing Calculator: ???,  Price List: $924.56763
	'g2-standard-24,16' # Google Cloud Pricing Calculator: ???,  Price List: $1613.15108
	'g2-standard-32,13' # Google Cloud Pricing Calculator: ???,  Price List: $1396.53453
	'g2-standard-48,32' # Google Cloud Pricing Calculator: ???,  Price List: $3226.30216
	'g2-standard-96,64' # Google Cloud Pricing Calculator: ???,  Price List: $6452.60359
	# G2 Commitment (CUD)
	'gcp-gce-g2,europe-west4,vm,g2-standard-8,g2-standard-8-1y,432' # Google Cloud Pricing Calculator: ???, Price List: $433.36961
	'gcp-gce-g2,europe-west4,vm,g2-standard-8,g2-standard-8-3y,308' # Google Cloud Pricing Calculator: ???, Price List: $310.5931
	'g2-standard-8-spot,'

# 01_europe-west4-m1.yml
	# M1 machine types
	'm1-ultramem-40,3381' # Google Cloud Pricing Calculator: $3381.02, Price List: $3380.776
	'm1-ultramem-40-1y,2846'
	'm1-ultramem-40-3y,1449'
	'm1-ultramem-80,6762'
	'm1-ultramem-80-1y,5692'
	'm1-ultramem-80-3y,2898'
	'm1-ultramem-160,13524'
	'm1-ultramem-160-1y,11385'
	'm1-ultramem-160-3y,5797'
	'm1-megamem-96,5722'
	'gcp-gce-m1,europe-west4,vm,m1-megamem-96,m1-megamem-96-1y,4817'
	'gcp-gce-m1,europe-west4,vm,m1-megamem-96,m1-megamem-96-3y,2452'
	'm1-ultramem-40-spot,'

# 01_europe-west4-m2.yml
	# M2 machine types
	'm2-ultramem-208,22625'    # Google Cloud Pricing Calculator: $22612.16, Price List: $22624.53
	'm2-ultramem-208-1y,19459' # Google Cloud Pricing Calculator: $19457.51, Price List: $19458.88
	'm2-ultramem-208-3y,11187' # Google Cloud Pricing Calculator: $11185.73, Price List: $11187.25
	'm2-ultramem-416,45251'    # Google Cloud Pricing Calculator: $45224.32, Price List: $45249.05
	'm2-ultramem-416-1y,38918' # Google Cloud Pricing Calculator: $38915.02, Price List: $38917.76
	'm2-ultramem-416-3y,22374' # Google Cloud Pricing Calculator: $22371.46, Price List: $22374.5
	'm2-megamem-416,27014'     # Google Cloud Pricing Calculator: $27000.81, Price List: $27012.99
	'm2-megamem-416-1y,23237'  # Google Cloud Pricing Calculator: $23236.07, Price List: $23237.36
	'm2-megamem-416-3y,13356'  # Google Cloud Pricing Calculator: $13354.79, Price List: $13356.08
	'm2-hypermem-416,36133'    # Google Cloud Pricing Calculator: $36133.44
	'gcp-gce-m2,europe-west4,vm,m2-hypermem-416,m2-hypermem-416-1y,31077' # Google Cloud Pricing Calculator: $31077.94
	'gcp-gce-m2,europe-west4,vm,m2-hypermem-416,m2-hypermem-416-3y,17865' # Google Cloud Pricing Calculator: $17865.53

# 01_europe-west4-m3.yml
	# M3 machine types
	'm3-ultramem-32,4896'
	'm3-ultramem-32-1y,2897'
	'm3-ultramem-32-3y,1469'
	'm3-ultramem-32-spot,'
	'm3-ultramem-64,9792'
	'm3-ultramem-64-1y,5795'
	'm3-ultramem-64-3y,2938'
	'm3-ultramem-128,19584'
	'm3-ultramem-128-1y,11591'
	'm3-ultramem-128-3y,5876'
	'm3-megamem-64,5791'
	'm3-megamem-64-1y,3426'
	'm3-megamem-64-3y,1737'
	'm3-megamem-128,11582'
	'gcp-gce-m3,europe-west4,vm,m3-megamem-128,m3-megamem-128-1y,6852'
	'gcp-gce-m3,europe-west4,vm,m3-megamem-128,m3-megamem-128-3y,3475'

# 01_europe-west4-n1.yml
	# N1 machine types
	'n1-standard-1,26'
	'n1-standard-2,53'
	'n1-standard-4,106'
	'n1-standard-8,213'
	'n1-standard-16,427'
	'n1-standard-32,855'
	'n1-standard-64,1710'
	'n1-standard-96,2565'
	'n1-highmem-2,66'
	'n1-highmem-4,133'
	'n1-highmem-8,266'
	'n1-highmem-16,532'
	'n1-highmem-32,1064'
	'n1-highmem-64,2129'
	'n1-highmem-96,3194'
	'n1-highcpu-2,39'
	'n1-highcpu-4,79'
	'n1-highcpu-8,159'
	'n1-highcpu-16,318'
	'n1-highcpu-32,637'
	'n1-highcpu-64,1275'
	'n1-highcpu-96,1913'
	'f1-micro,4.29'
	'g1-small,14.46'
	# N1 Commitment (CUD)
	'gcp-gce-n1,europe-west4,vm,n1-standard-8,n1-standard-8-1y,192'
	'gcp-gce-n1,europe-west4,vm,n1-standard-8,n1-standard-8-3y,137'
	'n1-standard-8-spot,'
	# N1 shared-core commitment does not exist. Price must therefore be the same as with SUD.
	'f1-micro-1y,4.292400,0.000000,1,1.000000,01_europe-west4-n1.yml'
	'f1-micro-3y,4.292400,0.000000,3,1.000000,01_europe-west4-n1.yml'

# 01_europe-west4-n2.yml
	# N2 machine types
	'n2-standard-2,62'
	'n2-standard-4,124'
	'n2-standard-8,249'
	'n2-standard-16,499'
	'n2-standard-32,999'
	'n2-standard-48,1498'
	'n2-standard-64,1998'
	'n2-standard-80,2498'
	'n2-standard-96,2997'
	'n2-standard-128,3997'
	'n2-highmem-2,84'
	'n2-highmem-4,168'
	'n2-highmem-8,337'
	'n2-highmem-16,674'
	'n2-highmem-32,1348'
	'n2-highmem-48,2022'
	'n2-highmem-64,2696'
	'n2-highmem-80,3370'
	'n2-highmem-96,4044'
	'n2-highmem-128,4956'
	'n2-highcpu-2,46'
	'n2-highcpu-4,92'
	'n2-highmem-8,337'
	'n2-highcpu-8,184'
	'n2-highcpu-16,368'
	'n2-highcpu-32,737'
	'n2-highcpu-48,1106'
	'n2-highcpu-64,1475'
	'n2-highcpu-80,1844'
	'n2-highcpu-96,2213'
	# N2 Commitment (CUD)
	'gcp-gce-n2,europe-west4,vm,n2-standard-8,n2-standard-8-1y,196'
	'gcp-gce-n2,europe-west4,vm,n2-standard-8,n2-standard-8-3y,140'
	'n2-standard-8-spot,'

# 01_europe-west4-n2d.yml
	# N2D machine types
	'n2d-standard-2,54'
	'n2d-standard-4,108'
	'n2d-standard-8,217'
	'n2d-standard-16,434'
	'n2d-standard-32,869'
	'n2d-standard-48,1304'
	'n2d-standard-64,1738'
	'n2d-standard-80,2173'
	'n2d-standard-96,2608'
	'n2d-standard-128,3477'
	'n2d-standard-224,6085'
	'n2d-highmem-2,73'
	'n2d-highmem-4,146'
	'n2d-highmem-8,293'
	'n2d-highmem-16,586'
	'n2d-highmem-32,1172'
	'n2d-highmem-48,1759'
	'n2d-highmem-64,2345'
	'n2d-highmem-80,2932'
	'n2d-highmem-96,3518'
	'n2d-highcpu-2,40'
	'n2d-highcpu-4,80'
	'n2d-highcpu-8,160'
	'n2d-highcpu-16,320'
	'n2d-highcpu-32,641'
	'n2d-highcpu-48,962'
	'n2d-highcpu-64,1283'
	'n2d-highcpu-80,1604'
	'n2d-highcpu-96,1925'
	'n2d-highcpu-128,2567'
	'n2d-highcpu-224,4492'
	# N2D Commitment (CUD)
	'gcp-gce-n2d,europe-west4,vm,n2d-standard-8,n2d-standard-8-1y,171'
	'gcp-gce-n2d,europe-west4,vm,n2d-standard-8,n2d-standard-8-3y,122'
	'n2d-standard-8-spot,'

# 01_europe-west4-sap.yml
	# SLES for SAP (https://cloud.google.com/products/calculator/#id=9a410d62-97b7-4ae0-baba-2f83ba9e625d)
	'vm,n1-standard-16,n1-standard-16-sles-sap,274'
	'sles-sap,n1-standard-16,n1-standard-16-sles-sap,107'
	'disk,ssd,disk-n1-standard-16-sles-sap-boot,14'
	'disk,ssd,disk-n1-standard-16-sles-sap-data,28'
	'disk,snapshot,snapshot-n1-standard-16-sles-sap-boot,5.3'
	'disk,snapshot,snapshot-n1-standard-16-sles-sap-data,10'
	'eur4,bucket,nearline-dual,bucket-n1-standard-16-sles-sap,22.5'
	# RHEL for SAP (https://cloud.google.com/products/calculator/#id=a41b2496-c124-4db8-9e30-0a5fcfbe9466)
	'vm,n1-standard-16,n1-standard-16-rhel-sap,274'
	'rhel-sap,n1-standard-16,n1-standard-16-rhel-sap,124'
	# Windows (https://cloud.google.com/products/calculator/#id=e23e3861-35f2-4550-9ce4-74585f3d23c1)
	'vm,n1-standard-16,n1-standard-16-windows,274'
	'windows,n1-standard-16,n1-standard-16-windows,537'

# 01_europe-west4-t2a.yml
	# Tau T2A (Arm) machine types
	't2a-standard-1,30'
	't2a-standard-2,61'
	't2a-standard-4,123'
	't2a-standard-8,247'
	't2a-standard-16,494'
	't2a-standard-32,989'
	't2a-standard-48,1484'
	# T2A no CUD
	't2a-standard-8-spot,'

# 01_europe-west4-t2d.yml
	# Tau T2D (AMD) machine types
	't2d-standard-1,33'
	't2d-standard-2,67'
	't2d-standard-4,135'
	't2d-standard-8,271'
	't2d-standard-16,543'
	't2d-standard-32,1086'
	't2d-standard-48,1629'
	# T2D Commitment (CUD)
	'gcp-gce-t2d,europe-west4,vm,t2d-standard-8,t2d-standard-8-1y,171'
	'gcp-gce-t2d,europe-west4,vm,t2d-standard-8,t2d-standard-8-3y,122'

# 01_us-central1-a2-ultragpu
	# A2 with A100 80GB and local SSD
	# Pirce list: a2-ultragpu-1g in us-central1 = $3700.22
	'a2-ultragpu-1g,3670'
	'a2-ultragpu-1g-local-disk,30'
	'a2-ultragpu-1g-1y,3670'
	'a2-ultragpu-1g-3y,3670'

# 10_us-central1.yml
	'vpn-us-central1-tunnel,36.5' # VPN Tunnel
	'nat-us-central1-gateway,88.234' # NAT Gateway with Data
	'us-central1,vm,n2-standard-8,n2-standard-8,226' # Google Cloud Pricing Calculator: $226.92

# Regions
	'europe-central2,vm,n2-standard-8,n2-standard-8,292'    # Google Cloud Pricing Calculator: $292.36
	'europe-north1,vm,n2-standard-8,n2-standard-8,249'      # Google Cloud Pricing Calculator: $249.84
	'europe-southwest1,vm,n2-standard-8,n2-standard-8,267'  # Google Cloud Pricing Calculator: $268
	'europe-west1,vm,n2-standard-8,n2-standard-8,249'       # Google Cloud Pricing Calculator: $249.63
	'europe-west12,vm,n2-standard-8,n2-standard-8,292'      # Google Cloud Pricing Calculator: $292.73
	'europe-west2,vm,n2-standard-8,n2-standard-8,292'       # Google Cloud Pricing Calculator: $292.36
	'europe-west3,vm,n2-standard-8,n2-standard-8,292'       # Google Cloud Pricing Calculator: $292.36
	'europe-west6,vm,n2-standard-8,n2-standard-8,317'       # Google Cloud Pricing Calculator: $317.44
	'europe-west8,vm,n2-standard-8,n2-standard-8,263'       # Google Cloud Pricing Calculator: $263.17
	'europe-west9,vm,n2-standard-8,n2-standard-8,263'       # Google Cloud Pricing Calculator: $263.17
	'me-central1,vm,n2-standard-8,n2-standard-8,275'        # Google Cloud Pricing Calculator: $275.71
	'me-west1,vm,n2-standard-8,n2-standard-8,249'           # Google Cloud Pricing Calculator: $249.62
	'southamerica-west1,vm,n2-standard-8,n2-standard-8,324' # Google Cloud Pricing Calculator: $324.50
	'us-east1,vm,n2-standard-8,n2-standard-8,226'           # Google Cloud Pricing Calculator: $226.92
	'us-east4,vm,n2-standard-8,n2-standard-8,255'           # Google Cloud Pricing Calculator: $255.57
	'us-east5,vm,n2-standard-8,n2-standard-8,226'           # Google Cloud Pricing Calculator: $227.87
	'us-south1,vm,n2-standard-8,n2-standard-8,267'          # Google Cloud Pricing Calculator: $267.70
	'us-west1,vm,n2-standard-8,n2-standard-8,226'           # Google Cloud Pricing Calculator: $226.92
	'us-west2,vm,n2-standard-8,n2-standard-8,272'           # Google Cloud Pricing Calculator: $272.57
	'us-west3,vm,n2-standard-8,n2-standard-8,272'           # Google Cloud Pricing Calculator: $272.57
	'us-west4,vm,n2-standard-8,n2-standard-8,255'           # Google Cloud Pricing Calculator: $279.52, Price List: $255.5 (2022-03-29)
)

MY_TESTS=0
MY_ERROR=0
for MY_CHECK in "${MY_CHECKS[@]}"
do
	((MY_TESTS++))
	if grep "$MY_CHECK" < "costs.csv" > /dev/null; then
		echo "✅ OK: Found '$MY_CHECK'"
	else
		echo "❌ ERROR: Check '$MY_CHECK' not found"
		((MY_ERROR++))
	fi
done

echo "🧪 TESTS : $MY_TESTS"
if [ $MY_ERROR -ge 1 ]; then
	echo "🔥 ERRORS: $MY_ERROR"
	exit 9
fi
echo "✅ DONE  : All successful"
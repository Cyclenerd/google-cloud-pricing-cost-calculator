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
	# Nearline storage
	'default-project-id,europe-west4,bucket,nearline,bucket-nearline,5.0'
	'default-project-id,europe-west4,retrieval,nearline,bucket-nearline,3.0'
	# Coldline storage
	'default-project-id,europe-west4,bucket,coldline,bucket-coldline,2.0'
	'default-project-id,europe-west4,retrieval,coldline,bucket-coldline,6.0'
	# Archive storage
	'default-project-id,europe-west4,bucket,archiv,bucket-archiv,0.6'
	'default-project-id,europe-west4,retrieval,archiv,bucket-archiv,15.0'
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

# 01_europe-west4-a3
	'a3-highgpu-8g,82154'
	'a3-highgpu-8g-1y,56991'
	'a3-highgpu-8g-3y,36078'
	'a3-megagpu-8g,86312' # 2024/08/17: Price not in the public price list
	'a3-megagpu-8g-1y,59381' # 2024/08/17: Price not in the public price list
	'a3-megagpu-8g-3y,37589' # 2024/08/17: Price not in the public price list

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
	'c3-standard-4,154'
	'c3-standard-8,309'
	'c3-standard-8-lssd,309'
	'c3-standard-22,849'
	'c3-standard-44,1699'
	'c3-standard-88,3399'
	'c3-standard-176,6799'
	'c3-standard-192-metal,7417'
	'c3-highmem-4,202'
	'c3-highmem-8,405'
	'c3-highmem-22,1115'
	'c3-highmem-44,2231'
	'c3-highmem-88,4462'
	'c3-highmem-176,8924'
	'c3-highmem-192-metal,9735'
	'c3-highcpu-4,130'
	'c3-highcpu-8,260'
	'c3-highcpu-22,717'
	'c3-highcpu-44,1434'
	'c3-highcpu-88,2868'
	'c3-highcpu-176,5736'
	'c3-highcpu-192-metal,6644'
	# C3 Commitment (CUD)
	'gcp-gce-c3,europe-west4,vm,c3-standard-8,c3-standard-8-1y,194'
	'gcp-gce-c3,europe-west4,vm,c3-standard-8,c3-standard-8-3y,139'
	'c3-standard-8-spot,'
	'gcp-gce-c3,europe-west4,vm,c3-highmem-8,c3-highmem-8-1y,255'
	'gcp-gce-c3,europe-west4,vm,c3-highmem-8,c3-highmem-8-3y,182'
	'c3-highmem-8-spot,'
	'gcp-gce-c3,europe-west4,vm,c3-highcpu-8,c3-highcpu-8-1y,164'
	'gcp-gce-c3,europe-west4,vm,c3-highcpu-8,c3-highcpu-8-3y,117'
	'c3-highcpu-8-spot,'

# 01_europe-west4-c3d.yml
	# C3D machine types
	'c3d-standard-4,139'
	'c3d-standard-8,278'
	'c3d-standard-16,556'
	'c3d-standard-30,1043'
	'c3d-standard-60,2087'
	'c3d-standard-90,3131'
	'c3d-standard-180,6263'
	'c3d-standard-360,12527'
	'c3d-highmem-4,187'
	'c3d-highmem-8,375'
	'c3d-highmem-16,750'
	'c3d-highmem-30,1408'
	'c3d-highmem-60,2816'
	'c3d-highmem-90,4224'
	'c3d-highmem-180,8448'
	'c3d-highmem-360,16897'
	'c3d-highcpu-4,114'
	'c3d-highcpu-8,229'
	'c3d-highcpu-16,459'
	'c3d-highcpu-30,858'
	'c3d-highcpu-60,1717'
	'c3d-highcpu-90,2576'
	'c3d-highcpu-180,5153'
	'c3d-highcpu-360,10306'
	# C3D Commitment (CUD)
	'gcp-gce-c3d,europe-west4,vm,c3d-standard-8,c3d-standard-8-1y,175'
	'gcp-gce-c3d,europe-west4,vm,c3d-standard-8,c3d-standard-8-3y,125'
	'c3d-standard-8-spot,'

# 01_europe-west4-c4.yml
	# C4 machine types
	'c4-standard-2,74'
	'c4-standard-4,151'
	'c4-standard-8,303'
	'c4-standard-16,606'
	'c4-standard-32,1212'
	'c4-standard-48,1818'
	'c4-standard-96,3636'
	'c4-standard-192,7272'
	'c4-highmem-2,98'
	'c4-highmem-4,199'
	'c4-highmem-8,399'
	'c4-highmem-16,799'
	'c4-highmem-32,1598'
	'c4-highmem-48,2397'
	'c4-highmem-96,4795'
	'c4-highmem-192,9590'
	'c4-highcpu-2,65'
	'c4-highcpu-4,130'
	'c4-highcpu-8,260'
	'c4-highcpu-16,521'
	'c4-highcpu-32,1043'
	'c4-highcpu-48,1564'
	'c4-highcpu-96,3129'
	'c4-highcpu-192,6258'
	# C4 Commitment (CUD)
	'gcp-gce-c4,europe-west4,vm,c4-standard-8,c4-standard-8-1y,190'
	'gcp-gce-c4,europe-west4,vm,c4-standard-8,c4-standard-8-3y,136'
	'gcp-gce-c4,europe-west4,vm,c4-highmem-8,c4-highmem-8-1y,251'
	'gcp-gce-c4,europe-west4,vm,c4-highmem-8,c4-highmem-8-3y,179'
	'gcp-gce-c4,europe-west4,vm,c4-highcpu-8,c4-highcpu-8-1y,164'
	'gcp-gce-c4,europe-west4,vm,c4-highcpu-8,c4-highcpu-8-3y,117'
	'c4-standard-8-spot,'

# 01_europe-west4-c4a.yml
	# C4A machine types
	'c4a-standard-1,34'
	'c4a-standard-2,68''
	'c4a-standard-4,137'
	'c4a-standard-8,275''
	'c4a-standard-8-lssd,275'
	'c4a-standard-16,550'
	'c4a-standard-32,1101'
	'c4a-standard-48,1651'
	'c4a-standard-64,2202'
	'c4a-standard-72,2477'
	'c4a-highmem-1,45'
	'c4a-highmem-2,90'
	'c4a-highmem-4,180'
	'c4a-highmem-8,361'
	'c4a-highmem-16,722'
	'c4a-highmem-32,1445'
	'c4a-highmem-48,2168'
	'c4a-highmem-64,2891'
	'c4a-highmem-72,3252'
	'c4a-highcpu-1,29'
	'c4a-highcpu-2,58'
	'c4a-highcpu-4,116'
	'c4a-highcpu-8,232'
	'c4a-highcpu-16,464'
	'c4a-highcpu-32,929'
	'c4a-highcpu-48,1393'
	'c4a-highcpu-64,1858'
	'c4a-highcpu-72,2090'
	# C4A Commitment (CUD)
	'gcp-gce-c4a,europe-west4,vm,c4a-standard-8,c4a-standard-8-1y,181'
	'gcp-gce-c4a,europe-west4,vm,c4a-standard-8,c4a-standard-8-3y,123'
	'gcp-gce-c4a,europe-west4,vm,c4a-highmem-8,c4a-highmem-8-1y,238'
	'gcp-gce-c4a,europe-west4,vm,c4a-highmem-8,c4a-highmem-8-3y,162'
	'gcp-gce-c4a,europe-west4,vm,c4a-highcpu-8,c4a-highcpu-8-1y,153'
	'gcp-gce-c4a,europe-west4,vm,c4a-highcpu-8,c4a-highcpu-8-3y,104.'
	# Spot
	'c4a-standard-8-spot,'
	'c4a-highmem-8-spot,'
	'c4a-highcpu-8-spot,'

# 01_europe-west4-h3.yml
	# H3 machine types
	'h3-standard-88,3773'
	# H3 Commitment (CUD)
	'gcp-gce-h3,europe-west4,vm,h3-standard-88,h3-standard-88-1y,3095'
	'gcp-gce-h3,europe-west4,vm,h3-standard-88,h3-standard-88-3y,2265'

# 01_europe-west4-z3.yml
	# Z3 machine types
	'z3-highmem-88,10108'   # 9964
	'z3-highmem-176,17049' # 16901
	# Z3 Commitment (CUD)
	'gcp-gce-z3,europe-west4,vm,z3-highmem-88,z3-highmem-88-1y,6368'    # 6760
	'gcp-gce-z3,europe-west4,vm,z3-highmem-88,z3-highmem-88-3y,4548'    # 4484
	'gcp-gce-z3,europe-west4,vm,z3-highmem-176,z3-highmem-176-1y,10740' # 10647
	'gcp-gce-z3,europe-west4,vm,z3-highmem-176,z3-highmem-176-3y,7672'  # 7605

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
	# G2 machine types
	'g2-standard-4,542'
	'g2-standard-8,654'
	'g2-standard-12,767'
	'g2-standard-16,880'
	'g2-standard-24,1535'
	'g2-standard-32,1330'
	'g2-standard-48,3070'
	'g2-standard-96,6140'
	# G2 Commitment (CUD)
	'gcp-gce-g2,europe-west4,vm,g2-standard-8,g2-standard-8-1y,412'
	'gcp-gce-g2,europe-west4,vm,g2-standard-8,g2-standard-8-3y,294'
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
	'm3-ultramem-32,4673'
	'm3-ultramem-32-1y,2766'
	'm3-ultramem-32-3y,1402'
	'm3-ultramem-32-spot,'
	'm3-ultramem-64,9347'
	'm3-ultramem-64-1y,5532'
	'm3-ultramem-64-3y,2804'
	'm3-ultramem-128,18694'
	'm3-ultramem-128-1y,11064'
	'm3-ultramem-128-3y,5609'
	'm3-megamem-64,5528'
	'm3-megamem-64-1y,3270'
	'm3-megamem-64-3y,1658'
	'm3-megamem-128,11056'
	'gcp-gce-m3,europe-west4,vm,m3-megamem-128,m3-megamem-128-1y,6541'
	'gcp-gce-m3,europe-west4,vm,m3-megamem-128,m3-megamem-128-3y,3317'

# 01_europe-west4-m4.yml
	# M4 machine types
	'm4-ultramem-56,6510'
	'm4-ultramem-112,13021'
	'm4-megamem-56,3681'
	'm4-megamem-112,7362'
	'm4-megamem-224,14725'
	'm4-ultramem-56-1y,3841'
	'm4-ultramem-56-3y,1953'
	'm4-ultramem-112-1y,7682'
	'm4-ultramem-112-3y,3906'
	'm4-megamem-56-1y,2172'
	'm4-megamem-56-3y,1104'
	'm4-megamem-112-1y,4344'
	'm4-megamem-112-3y,2208'
	'm4-megamem-224-1y,8688'
	'm4-megamem-224-3y,4417'
	'm4-ultramem-56-spot,'

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

# 01_europe-west4-n4.yml
	# N4 machine types
	'n4-standard-2,72'
	'n4-standard-4,145'
	'n4-standard-8,290'
	'n4-standard-16,581'
	'n4-standard-32,1162'
	'n4-standard-48,1743'
	'n4-standard-64,2324'
	'n4-standard-80,2905'
	'n4-highmem-2,95'
	'n4-highmem-4,190'
	'n4-highmem-8,381'
	'n4-highmem-16,762'
	'n4-highmem-32,1525'
	'n4-highmem-48,2288'
	'n4-highmem-64,3050'
	'n4-highmem-80,3813'
	'n4-highcpu-2,61'
	'n4-highcpu-4,122'
	'n4-highcpu-8,245'
	'n4-highcpu-16,490'
	'n4-highcpu-32,980'
	'n4-highcpu-48,1471'
	'n4-highcpu-64,1961'
	'n4-highcpu-80,2451'
	# N2 Commitment (CUD)
	'gcp-gce-n4,europe-west4,vm,n4-standard-8,n4-standard-8-1y,183'
	'gcp-gce-n4,europe-west4,vm,n4-standard-8,n4-standard-8-3y,130'
	'n4-standard-8-spot,'

# 01_europe-west4-sap.yml
	# SLES for SAP (https://cloud.google.com/products/calculator/#id=9a410d62-97b7-4ae0-baba-2f83ba9e625d)
	'vm,n1-standard-16,n1-standard-16-sles-sap,274'
	'sles-sap,n1-standard-16,n1-standard-16-sles-sap,107'
	'disk,ssd,disk-n1-standard-16-sles-sap-boot,14'
	'disk,ssd,disk-n1-standard-16-sles-sap-data,28'
	'disk,snapshot,snapshot-n1-standard-16-sles-sap-boot,5.3'
	'disk,snapshot,snapshot-n1-standard-16-sles-sap-data,10'
	'eur4,bucket,nearline-dual,bucket-n1-standard-16-sles-sap,22.5'
	# RHEL for SAP (https://cloud.google.com/compute/disks-image-pricing#rhel_images)
	'vm,n1-standard-16,n1-standard-16-rhel-sap,274'
	'rhel-sap,n1-standard-16,n1-standard-16-rhel-sap,189'
	# Windows (https://cloud.google.com/products/calculator/#id=e23e3861-35f2-4550-9ce4-74585f3d23c1)
	'vm,n1-standard-16,n1-standard-16-windows,274'
	'windows,n1-standard-16,n1-standard-16-windows,537'

# 01_europe-west4-t2a.yml
	# Tau T2A (Arm) machine types
	't2a-standard-1,29'
	't2a-standard-2,59'
	't2a-standard-4,118'
	't2a-standard-8,236'
	't2a-standard-16,472'
	't2a-standard-32,944'
	't2a-standard-48,1417'
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
	'a2-ultragpu-1g,3700'
	'a2-ultragpu-1g-1y,3700'
	'a2-ultragpu-1g-3y,3700'

# 10_us-central1.yml
	'vpn-us-central1-tunnel,36.5' # VPN Tunnel
	'nat-us-central1-gateway,88.234' # NAT Gateway with Data
	'us-central1,vm,n2-standard-8,n2-standard-8,226' # Google Cloud Pricing Calculator: $226.92

# Regions
	'europe-central2,vm,n2-standard-8,n2-standard-8,292'    # Google Cloud Pricing Calculator: $292.36
	'europe-north1,vm,n2-standard-8,n2-standard-8,249'      # Google Cloud Pricing Calculator: $249.84
	'europe-north2,vm,n4-standard-8,n4-standard-8,290'      # Google Cloud Pricing Calculator: $290.570952
	'europe-southwest1,vm,n2-standard-8,n2-standard-8,267'  # Google Cloud Pricing Calculator: $268
	'europe-west1,vm,n2-standard-8,n2-standard-8,249'       # Google Cloud Pricing Calculator: $249.63
	'europe-west10,vm,n2-standard-8,n2-standard-8,349'      # Google Cloud Pricing Calculator: $349.46
	'europe-west12,vm,n2-standard-8,n2-standard-8,292'      # Google Cloud Pricing Calculator: $292.73
	'europe-west2,vm,n2-standard-8,n2-standard-8,292'       # Google Cloud Pricing Calculator: $292.36
	'europe-west3,vm,n2-standard-8,n2-standard-8,292'       # Google Cloud Pricing Calculator: $292.36
	'europe-west6,vm,n2-standard-8,n2-standard-8,317'       # Google Cloud Pricing Calculator: $317.44
	'europe-west8,vm,n2-standard-8,n2-standard-8,263'       # Google Cloud Pricing Calculator: $263.17
	'europe-west9,vm,n2-standard-8,n2-standard-8,263'       # Google Cloud Pricing Calculator: $263.17
	'me-central1,vm,n2-standard-8,n2-standard-8,275'        # Google Cloud Pricing Calculator: $275.71
	'me-central2,vm,n2-standard-8,n2-standard-8,363'        # Google Cloud Pricing Calculator: $363.08
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
	'africa-south1,vm,n2-standard-8,n2-standard-8,296'
	'northamerica-south1,vm,e2-standard-8,e2-standard-8,213'
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

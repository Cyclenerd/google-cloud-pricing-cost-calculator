#!/usr/bin/env bash

MY_CHECKS=(
	# HEADER
	'PROJECT;REGION;RESOURCE;NAME;COST;TYPE;DATA;CLASS;RULES;COMMITMENT;DISCOUNT;FILE'
	
	#
	# 00_europe-west4.yml
	#
	# Monitoring
	'monitoring;stackdriver;1548'
	# Traffic
	'europe-west4;traffic-world;traffic-world;122'
	# Load Balancing
	'europe-west4;load-balancer;load-balancer-1;20'
	'europe-west4;load-balancer;load-balancer-5;20'
	'europe-west4;load-balancer;load-balancer-6;28'
	'europe-west4;load-balancer;load-balancer-6-50;32'
	# Standard storage
	'europe-west4;bucket;bucket-standard;1.0'
	'europe-multi;bucket;bucket-standard-multi;1.3'
	'eur4;bucket;bucket-standard-dual;1.8'
	# Disk
	'europe-west4;disk;disk-ssd;191'
	'europe-west4;disk;disk-hdd;90'

	#
	# 01_europe-west4-sap.yml
	#
	'europe-west4;vm;n1-standard-16-sles-sap;274'
	'europe-west4;vm-os;n1-standard-16-sles-sap;107'
	'europe-west4;disk;disk-n1-standard-16-sles-sap-boot;14'
	'europe-west4;disk;disk-n1-standard-16-sles-sap-data;28'
	'europe-west4;disk;snapshot-n1-standard-16-sles-sap-boot;2.9'
	'europe-west4;disk;snapshot-n1-standard-16-sles-sap-data;5.8'
	'eur4;bucket;bucket-n1-standard-16-sles-sap;20'

	#
	# 01_europe-west4...
	#
	# Test VM instance pricing
	# Price list: https://cloud.google.com/compute/vm-instance-pricing
	#
	# General-purpose machine type family
	# https://cloud.google.com/compute/vm-instance-pricing#general-purpose_machine_type_family
	#
	# E2 standard machine types
	'europe-west4;vm;e2-standard-2;53'
	'europe-west4;vm;e2-standard-4;107'
	'europe-west4;vm;e2-standard-8;215'
	'europe-west4;vm;e2-standard-16;430'
	'europe-west4;vm;e2-standard-32;861'
	# E2 Commitment (CUD)
	'europe-west4;vm;e2-standard-8-1y;135' # Google Cloud Pricing Calculator: $135.71
	'europe-west4;vm;e2-standard-8-3y;96'  # Google Cloud Pricing Calculator: $96.94
	# E2 high-memory machine types
	'europe-west4;vm;e2-highmem-2;72'
	'europe-west4;vm;e2-highmem-4;145'
	'europe-west4;vm;e2-highmem-8;290'
	'europe-west4;vm;e2-highmem-16;581'
	# E2 high-CPU machine types
	'europe-west4;vm;e2-highcpu-2;39'
	'europe-west4;vm;e2-highcpu-4;79'
	'europe-west4;vm;e2-highcpu-8;159'
	'europe-west4;vm;e2-highcpu-16;318'
	'europe-west4;vm;e2-highcpu-32;636'
	# E2 shared-core machine types
	'europe-west4;vm;e2-micro;6.73'
	'europe-west4;vm;e2-small;13.46'
	'europe-west4;vm;e2-medium;26.9'
	# N2 standard machine types
	'europe-west4;vm;n2-standard-2;62'
	'europe-west4;vm;n2-standard-4;124'
	'europe-west4;vm;n2-standard-8;249'
	'europe-west4;vm;n2-standard-16;499'
	# n2-standard-32 ... 128: Tested with Google Cloud Pricing Calculator
	#                         Price differs slightly from the price list
	'europe-west4;vm;n2-standard-32;999'
	'europe-west4;vm;n2-standard-48;1498'
	'europe-west4;vm;n2-standard-64;1998'
	'europe-west4;vm;n2-standard-80;2498'
	'europe-west4;vm;n2-standard-96;2997'
	'europe-west4;vm;n2-standard-128;3997'
	# N2 high-memory machine types
	'europe-west4;vm;n2-highmem-2;84'
	'europe-west4;vm;n2-highmem-4;168'
	# n2-highmem-8 ... 128: Tested with Google Cloud Pricing Calcuator
	#                       Price differs slightly from the price list
	'europe-west4;vm;n2-highmem-8;337'
	'europe-west4;vm;n2-highmem-16;674'
	'europe-west4;vm;n2-highmem-32;1348'
	'europe-west4;vm;n2-highmem-48;2022'
	'europe-west4;vm;n2-highmem-64;2696'
	'europe-west4;vm;n2-highmem-80;3370'
	'europe-west4;vm;n2-highmem-96;4044'
	'europe-west4;vm;n2-highmem-128;4956'
	# N2 high-CPU machine types
	'europe-west4;vm;n2-highcpu-2;46'
	'europe-west4;vm;n2-highcpu-4;92'
	'europe-west4;vm;n2-highmem-8;337'
	'europe-west4;vm;n2-highcpu-8;184'
	'europe-west4;vm;n2-highcpu-16;368'
	# n2-highcpu-32 ... 128: Tested with Google Cloud Pricing Calcuator
	#                        Price differs slightly from the price list
	'europe-west4;vm;n2-highcpu-32;737'
	'europe-west4;vm;n2-highcpu-48;1106'
	'europe-west4;vm;n2-highcpu-64;1475'
	'europe-west4;vm;n2-highcpu-80;1844'
	'europe-west4;vm;n2-highcpu-96;2213'
	# N2D standard machine types
	'europe-west4;vm;n2d-standard-2;54'
	'europe-west4;vm;n2d-standard-4;108'
	'europe-west4;vm;n2d-standard-8;217'
	'europe-west4;vm;n2d-standard-16;434'
	'europe-west4;vm;n2d-standard-32;869'
	# n2d-standard-48 ... 224: Tested with Google Cloud Pricing Calcuator
	#                          Price differs slightly from the price list
	'europe-west4;vm;n2d-standard-48;1304'
	'europe-west4;vm;n2d-standard-64;1738'
	'europe-west4;vm;n2d-standard-80;2173'
	'europe-west4;vm;n2d-standard-96;2608'
	'europe-west4;vm;n2d-standard-128;3477'
	'europe-west4;vm;n2d-standard-224;6085'
	# N2D high-memory machine types
	'europe-west4;vm;n2d-highmem-2;73'
	'europe-west4;vm;n2d-highmem-4;146'
	'europe-west4;vm;n2d-highmem-8;293'
	'europe-west4;vm;n2d-highmem-16;586'
	'europe-west4;vm;n2d-highmem-32;1172'
	# n2d-highmem-48 ... 96: Tested with Google Cloud Pricing Calcuator
	#                        Price differs slightly from the price list
	'europe-west4;vm;n2d-highmem-48;1759'
	'europe-west4;vm;n2d-highmem-64;2345'
	'europe-west4;vm;n2d-highmem-80;2932'
	'europe-west4;vm;n2d-highmem-96;3518'
	# N2D high-CPU machine types
	'europe-west4;vm;n2d-highcpu-2;40'
	'europe-west4;vm;n2d-highcpu-4;80'
	'europe-west4;vm;n2d-highcpu-8;160'
	'europe-west4;vm;n2d-highcpu-16;320'
	'europe-west4;vm;n2d-highcpu-32;641'
	'europe-west4;vm;n2d-highcpu-48;962'
	'europe-west4;vm;n2d-highcpu-64;1283'
	'europe-west4;vm;n2d-highcpu-80;1604'
	'europe-west4;vm;n2d-highcpu-96;1925'
	# n2d-highcpu-128 ... 224: Tested with Google Cloud Pricing Calcuator
	#                          Price differs slightly from the price list
	'europe-west4;vm;n2d-highcpu-128;2567'
	'europe-west4;vm;n2d-highcpu-224;4492'
	# Tau T2D standard machine types
	'europe-west4;vm;t2d-standard-1;33'
	'europe-west4;vm;t2d-standard-2;67'
	'europe-west4;vm;t2d-standard-4;135'
	'europe-west4;vm;t2d-standard-8;271'
	'europe-west4;vm;t2d-standard-16;543'
	'europe-west4;vm;t2d-standard-32;1086'
	'europe-west4;vm;t2d-standard-48;1629'
	'europe-west4;vm;t2d-standard-60;2037'
	# N1 standard machine types
	'europe-west4;vm;n1-standard-1;26'
	'europe-west4;vm;n1-standard-2;53'
	'europe-west4;vm;n1-standard-4;106'
	'europe-west4;vm;n1-standard-8;213'
	'europe-west4;vm;n1-standard-16;427'
	'europe-west4;vm;n1-standard-32;855'
	'europe-west4;vm;n1-standard-64;1710'
	'europe-west4;vm;n1-standard-96;2565'
	# N1 Commitment (CUD)
	'europe-west4;vm;n1-standard-8-1y;192'
	'europe-west4;vm;n1-standard-8-3y;137'
	# N1 high-memory machine types
	'europe-west4;vm;n1-highmem-2;66'
	'europe-west4;vm;n1-highmem-4;133'
	'europe-west4;vm;n1-highmem-8;266'
	'europe-west4;vm;n1-highmem-16;532'
	# n1-highmem-32 ... 96: Tested with Google Cloud Pricing Calcuator
	#                       Price differs slightly from the price list
	'europe-west4;vm;n1-highmem-32;1064'
	'europe-west4;vm;n1-highmem-64;2129'
	'europe-west4;vm;n1-highmem-96;3194'
	# N1 high-CPU machine types
	'europe-west4;vm;n1-highcpu-2;39'
	'europe-west4;vm;n1-highcpu-4;79'
	'europe-west4;vm;n1-highcpu-8;159'
	# n1-highcpu-16 ... 96: Tested with Google Cloud Pricing Calcuator
	#                       Price differs slightly from the price list
	'europe-west4;vm;n1-highcpu-16;318'
	'europe-west4;vm;n1-highcpu-32;637'
	'europe-west4;vm;n1-highcpu-64;1275'
	'europe-west4;vm;n1-highcpu-96;1913'
	# N1 shared-core machine types
	'europe-west4;vm;f1-micro;4.29'
	'europe-west4;vm;g1-small;14.46'
	# N1 shared-core commitment does not exist. Price must therefore be the same as with SUD.
	'europe-west4;vm;f1-micro-1y;4.29'
	'europe-west4;vm;f1-micro-3y;4.29'
	#
	# Compute-optimized machine type family
	# https://cloud.google.com/compute/vm-instance-pricing#compute-optimized_machine_types
	#
	# C2 machine types
	'europe-west4;vm;c2-standard-4;134'
	'europe-west4;vm;c2-standard-8;268'
	# c2-standard-16 ... 60: Tested with Google Cloud Pricing Calcuator
	#                        Price differs slightly from the price list
	'europe-west4;vm;c2-standard-16;537'
	'europe-west4;vm;c2-standard-30;1007'
	'europe-west4;vm;c2-standard-60;2014'
	# C2 Commitment (CUD)
	'europe-west4;vm;c2-standard-8-1y;211' # Google Cloud Pricing Calculator: $211.41
	'europe-west4;vm;c2-standard-8-3y;134' # Google Cloud Pricing Calculator: $134.26
	# C2D Standard machine types
	'europe-west4;vm;c2d-standard-2;72'
	'europe-west4;vm;c2d-standard-4;145'
	'europe-west4;vm;c2d-standard-8;291'
	'europe-west4;vm;c2d-standard-16;583'
	# c2d-standard-32 ... 112: Tested with Google Cloud Pricing Calcuator
	#                          Price differs slightly from the price list
	'europe-west4;vm;c2d-standard-32;1167'
	'europe-west4;vm;c2d-standard-56;2043'
	'europe-west4;vm;c2d-standard-112;4086'
	# C2D Commitment (CUD)
	'europe-west4;vm;c2d-standard-8-1y;183'
	'europe-west4;vm;c2d-standard-8-3y;131'
	# C2D Highmem machine types
	'europe-west4;vm;c2d-highmem-2;98'
	'europe-west4;vm;c2d-highmem-4;196'
	'europe-west4;vm;c2d-highmem-8;393'
	# c2d-highmem-16 ... 112: Tested with Google Cloud Pricing Calcuator
	#                         Price differs slightly from the price list
	'europe-west4;vm;c2d-highmem-16;787'
	'europe-west4;vm;c2d-highmem-32;1575'
	'europe-west4;vm;c2d-highmem-56;2756'
	'europe-west4;vm;c2d-highmem-112;5512'
	#
	# Memory-optimized machine type family
	# https://cloud.google.com/compute/vm-instance-pricing#compute-optimized_machine_types
	#
	# M2 machine types
	# » m2-ultramem-208
	'europe-west4;vm;m2-ultramem-208;22625'    # Google Cloud Pricing Calculator: $22612.16, Price List: $22624.53
	'europe-west4;vm;m2-ultramem-208-1y;19459' # Google Cloud Pricing Calculator: $19457.51, Price List: $19458.88
	'europe-west4;vm;m2-ultramem-208-3y;11187' # Google Cloud Pricing Calculator: $11185.73, Price List: $11187.25
	# » m2-ultramem-416
	'europe-west4;vm;m2-ultramem-416;45251'    # Google Cloud Pricing Calculator: $45224.32, Price List: $45249.05
	'europe-west4;vm;m2-ultramem-416-1y;38918' # Google Cloud Pricing Calculator: $38915.02, Price List: $38917.76
	'europe-west4;vm;m2-ultramem-416-3y;22374' # Google Cloud Pricing Calculator: $22371.46, Price List: $22374.5
	# » m2-megamem-416
	'europe-west4;vm;m2-megamem-416;27014'     # Google Cloud Pricing Calculator: $27000.81, Price List: $27012.99
	'europe-west4;vm;m2-megamem-416-1y;23237'  # Google Cloud Pricing Calculator: $23236.07, Price List: $23237.36
	'europe-west4;vm;m2-megamem-416-3y;13356'  # Google Cloud Pricing Calculator: $13354.79, Price List: $13356.08
	# M1 machine types
	# » m1-ultramem-40
	'europe-west4;vm;m1-ultramem-40;3381' # Google Cloud Pricing Calculator: $3381.02, Price List: $3380.776
	'europe-west4;vm;m1-ultramem-40-1y;2846'
	'europe-west4;vm;m1-ultramem-40-3y;1449'
	# » m1-ultramem-80
	'europe-west4;vm;m1-ultramem-80;6762'
	'europe-west4;vm;m1-ultramem-80-1y;5692'
	'europe-west4;vm;m1-ultramem-80-3y;2898'
	# » m1-ultramem-160
	'europe-west4;vm;m1-ultramem-160;13524'
	'europe-west4;vm;m1-ultramem-160-1y;11385'
	'europe-west4;vm;m1-ultramem-160-3y;5797'
	# » m1-megamem-96
	'europe-west4;vm;m1-megamem-96;5722'
	'europe-west4;vm;m1-megamem-96-1y;4817'
	'europe-west4;vm;m1-megamem-96-3y;2452'
	#
	# Accelerator-optimized machine type family
	# https://cloud.google.com/compute/vm-instance-pricing#accelerator-optimized
	#
	# A2 standard machine types (total cost)
	'europe-west4;vm;a2-highgpu-1g;2736'   # Google Cloud Pricing Calculator: $2736.02, Price List: $2739.74
	'europe-west4;vm;a2-highgpu-2g;5472'   # Google Cloud Pricing Calculator: $5472.04 , Price List: $5479.47
	'europe-west4;vm;a2-highgpu-4g;10944'  # Google Cloud Pricing Calculator: $10944.08, Price List: $10958.95
	'europe-west4;vm;a2-highgpu-8g;21888'  # Google Cloud Pricing Calculator: $21888.16, Price List: $21917.89
	'europe-west4;vm;a2-megagpu-16g;41337' # Google Cloud Pricing Calculator: $41337.39, Price List: $41396.86
	# A2 Commitment (CUD)
	'europe-west4;vm;a2-highgpu-8g-1y;13789'  # Google Cloud Pricing Calculator: $13789.38, Price List: $13787.27
	'europe-west4;vm;a2-highgpu-8g-3y;7661'  # Google Cloud Pricing Calculator: $7661.01, Price List: $7661.79
)

MY_ERROR=0
for MY_CHECK in "${MY_CHECKS[@]}"
do
	if grep "$MY_CHECK" < "COSTS.csv" > /dev/null; then
		echo "✅ OK: Found '$MY_CHECK'"
	else
		echo "❌ ERROR: Check '$MY_CHECK' not found"
		((MY_ERROR++));
	fi
done

if [ $MY_ERROR -ge 1 ]; then
	echo "🔥 ERRORS: $MY_ERROR"
	exit 9
fi
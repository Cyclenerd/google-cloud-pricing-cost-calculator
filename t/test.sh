#!/usr/bin/env bash

MY_CHECKS=(
	# HEADE
	'PROJECT;REGION;RESOURCE;NAME;COST;TYPE;DATA;CLASS;RULES;COMMITMENT;DISCOUNT;FILE'
	# 00_europe-west4.yml
	# Monitoring
	'monitoring;stackdriver;1548'
	# Traffic
	'europe-west4;traffic-world;traffic-world;122'
	# Load Balancing
	'europe-west4;load-balancer;load-balancer-1;20'
	'europe-west4;load-balancer;load-balancer-5;20'
	'europe-west4;load-balancer;load-balancer-6;28'
	'europe-west4;load-balancer;load-balancer-6-50;32'
	# Instances
	# » a2-highgpu-8g
	'europe-west4;vm;a2-highgpu-8g;21888'
	'europe-west4;vm;a2-highgpu-8g-1y;13789'
	'europe-west4;vm;a2-highgpu-8g-3y;7661'
	# » n1-standard-8
	'europe-west4;vm;n1-standard-8;213'
	'europe-west4;vm;n1-standard-8-1y;192'
	'europe-west4;vm;n1-standard-8-3y;137'
	# » c2d-standard-8
	'europe-west4;vm;c2d-standard-8;291'
	'europe-west4;vm;c2d-standard-8-1y;183'
	'europe-west4;vm;c2d-standard-8-3y;131'
	# » m1-ultramem-80
	'europe-west4;vm;m1-ultramem-80;6762'
	'europe-west4;vm;m1-ultramem-80-1y;5692'
	'europe-west4;vm;m1-ultramem-80-3y;2898'
	# » m2-ultramem-416
	# Known bug > Google Cloud Pricing Calculator: 45224 vs 45251
	'europe-west4;vm;m2-ultramem-416;452'
	# Known bug > Google Cloud Pricing Calculator: 38915 vs 38918
	'europe-west4;vm;m2-ultramem-416-1y;389'
	# Known bug > Google Cloud Pricing Calculator: 22371 vs 22374
	'europe-west4;vm;m2-ultramem-416-3y;223'
	#
	# Test VM instance pricing
	# Price list: https://cloud.google.com/compute/vm-instance-pricing
	#
	# General-purpose machine type family
	# https://cloud.google.com/compute/vm-instance-pricing#general-purpose_machine_type_family
	# E2 standard machine types
	'europe-west4;vm;e2-standard-2;53'
	'europe-west4;vm;e2-standard-4;107'
	'europe-west4;vm;e2-standard-8;215'
	'europe-west4;vm;e2-standard-16;430'
	'europe-west4;vm;e2-standard-32;861'
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
	# Standard storage
	'europe-west4;bucket;bucket-standard;1.0'
	'europe-multi;bucket;bucket-standard-multi;1.3'
	'eur4;bucket;bucket-standard-dual;1.8'
	# Disk
	'europe-west4;disk;disk-ssd;191'
	'europe-west4;disk;disk-hdd;90'
	# 01_europe-west4-sap.yml
	'europe-west4;vm;n1-standard-16-sles-sap;274'
	'europe-west4;vm-os;n1-standard-16-sles-sap;107'
	'europe-west4;disk;disk-n1-standard-16-sles-sap-boot;14'
	'europe-west4;disk;disk-n1-standard-16-sles-sap-data;28'
	'europe-west4;disk;snapshot-n1-standard-16-sles-sap-boot;2.9'
	'europe-west4;disk;snapshot-n1-standard-16-sles-sap-data;5.8'
	'eur4;bucket;bucket-n1-standard-16-sles-sap;20'
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
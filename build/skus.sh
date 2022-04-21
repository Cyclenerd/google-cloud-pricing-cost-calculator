#!/usr/bin/env bash

#
# Export SKUs to CSV file
#

echo "Compute Engine" && \
perl skus.pl -csv="skus_compute.csv" -id="6F81-5844-456A" && \
echo "Cloud Storage" && \
perl skus.pl -csv="skus_storage.csv" -id="95FF-2EF5-5EA1" && \
echo "Stackdriver Monitoring" && \
perl skus.pl -csv="skus_stackdriver.csv" -id="58CD-E7C3-72CA" && \
echo "Cloud SQL" && \
perl skus.pl -csv="skus_sql.csv" -id="9662-B51E-5089" && \
echo "Merge CSV files" && \
{
	cat "skus_compute.csv"
	cat "skus_storage.csv"
	cat "skus_stackdriver.csv"
	cat "skus_sql.csv"
} > "skus.csv" && \
echo "DONE"
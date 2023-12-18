#!/usr/bin/env bash

#
# Export SKUs to SQLite3 DB file and do mapping
#

DELAY="${API_DELAY:-0}"

echo "Create SQLite3 database for SKU export..."
sqlite3 "skus.db" < "skus.sql" || exit 9

echo && \
echo "Query Google API..." && \
echo "Compute Engine:" && \
perl skus.pl -id="6F81-5844-456A" -delay="$DELAY" && \
echo "Networking:" && \
perl skus.pl -id="E505-1604-58F8" -delay="$DELAY" && \
echo "Cloud Storage:" && \
perl skus.pl -id="95FF-2EF5-5EA1" -delay="$DELAY" && \
echo "Stackdriver Monitoring:" && \
perl skus.pl -id="58CD-E7C3-72CA" -delay="$DELAY" && \
echo "Cloud SQL:" && \
perl skus.pl -id="9662-B51E-5089" -delay="$DELAY" && \
echo "Import mapping.csv into SQLite3 database..." && \
sqlite3 "skus.db" ".import --csv mapping.csv mapping" && \
echo && \
echo "Do mapping..." && \
sqlite3 "skus.db" < "mapping.sql" && \
echo && \
echo "DONE"

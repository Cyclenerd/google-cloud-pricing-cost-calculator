/*
Copyright 2022-2023 Nils Knieling. All Rights Reserved.
Rewrite in Go and use DuckDB in 2023 by Roman Inflianskas.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	_ "github.com/marcboeker/go-duckdb"
	_ "github.com/xo/dburl"
)

var version string = "v?.?.?"

var (
	showVersion = flag.Bool("version", false, "Print version")
	skuFile     = flag.String("sku", "skus.csv", "CSV file with SKUs (write)")
	mapFile     = flag.String("mapping", "mapping.csv", "CSV file with mapping (read)")
	reset       = flag.Bool("reset", false, "Reset mapping (0=no, 1=yes)")
)

func main() {
	flag.Parse()

	if *showVersion {
	      fmt.Println(version)
	      os.Exit(0)
	}

	if _, err := os.Stat(*skuFile); os.IsNotExist(err) {
		log.Fatalf("ERROR: Cannot open CSV file '%s' with SKUs!\n", *skuFile)
	}

	if _, err := os.Stat(*mapFile); os.IsNotExist(err) {
		log.Fatalf("ERROR: Cannot open CSV file '%s' with mapping!\n", *mapFile)
	}

	db, err := sql.Open("duckdb", "")
	if err != nil {
		log.Fatalf("ERROR: Cannot open DuckDB database: %v\n", err)
	}
	defer db.Close()

	const skuFileColumns = "['SKU_NAME', 'SKU_ID', 'MAPPING', 'SKU_DESCRIPTION', 'SVC_DISPLAY_NAME', 'FAMILY', 'GROUP', 'USAGE', 'REGIONS', 'TIME', 'SUMMARY', 'UNIT', 'UNIT_DESCRIPTION', 'BASE_UNIT', 'BASE_UNIT_DESCRIPTION', 'BASE_UNIT_CONVERSION_FACTOR', 'DISPLAY_QUANTITY', 'START_AMOUNT', 'CURRENCY_CODE', 'UNITS', 'NANOS', 'AGGREGATION_LEVEL', 'AGGREGATION_INTERVAL', 'AGGREGATION_COUNT', 'CONVERSION_RATE', 'SERVICE_PROVIDER', 'GEO_TYPE', 'GEO_REGIONS']"
	if _, err := db.Exec(fmt.Sprintf("CREATE TABLE skus AS FROM read_csv_auto('%s', DELIM = ';', HEADER = TRUE, NAMES = %s)", *skuFile, skuFileColumns)); err != nil {
		log.Fatalf("ERROR: Failed to create skus table: %v\n", err)
	}

	if *reset {
		if _, err := db.Exec("UPDATE skus SET MAPPING = 'TODO'"); err != nil {
			log.Fatalf("ERROR: Failed to reset mapping: %v\n", err)
		}
	}

	const mapFileColumns = "['MAPPING', 'SVC_DISPLAY_NAME', 'FAMILY', 'GROUP','SKU_DESCRIPTION']"
	rows, err := db.Query(fmt.Sprintf("SELECT MAPPING, SVC_DISPLAY_NAME, FAMILY, \"GROUP\", SKU_DESCRIPTION, FROM read_csv_auto('%s', DELIM = ';', NAMES = %s) WHERE SVC_DISPLAY_NAME IS NOT NULL", *mapFile, mapFileColumns))
	if err != nil {
		log.Fatalf("ERROR: Failed to query mapping: %v\n", err)
	}
	defer rows.Close()

	var mapping, serviceDisplayName, family, group, skuDescription string

	queryString := "UPDATE skus SET MAPPING = ? WHERE SVC_DISPLAY_NAME = ? AND FAMILY = ? AND \"GROUP\" = ? AND SKU_DESCRIPTION LIKE ?"
	stmt, err := db.Prepare(queryString)
	if err != nil {
		log.Fatal(err)
	}

	for rows.Next() {
		if err := rows.Scan(&mapping, &serviceDisplayName, &family, &group, &skuDescription); err != nil {
			log.Fatal(err)
		}

		if serviceDisplayName != "" {
			fmt.Printf("* %s\n  - %s\n  - %s\n  - %s\n  - %s\n", mapping, serviceDisplayName, family, group, skuDescription)
			if _, err := stmt.Exec(mapping, serviceDisplayName, family, group, skuDescription); err != nil {
				log.Fatal(err)
			}
		} else {
			fmt.Printf("%s\n%s\n%s\n", strings.Repeat("-", 80), strings.ToUpper(mapping), strings.Repeat("-", 80))
		}
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	if _, err := db.Query(fmt.Sprintf("COPY skus TO '%s' (HEADER, DELIMITER ';');", *skuFile)); err != nil {
		log.Fatalf("ERROR: Failed to save mapping: %v\n", err)
	}

	fmt.Println(strings.Repeat("-", 80))
	fmt.Println("DONE")
}

/*
Copyright 2022-2023 Nils Knieling. All Rights Reserved.
Rewrite in Go and use SQLite in 2023 by Roman Inflianskas.

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
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/ncruces/go-sqlite3"
	"github.com/ncruces/go-sqlite3/driver"
	_ "github.com/ncruces/go-sqlite3/embed"
	"github.com/ncruces/go-sqlite3/ext/csv"
)

var version string = "v?.?.?"

var (
	showVersion = flag.Bool("version", false, "Print version")
	skuDbFile   = flag.String("skuDb", "skus.db", "DB file with SKUs (read/write)")
	mapFile     = flag.String("mapping", "mapping.csv", "CSV file with mapping (read)")
)

func main() {
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if _, err := os.Stat(*mapFile); os.IsNotExist(err) {
		log.Fatalf("ERROR: Cannot open CSV file '%s' with mapping!\n", *mapFile)
	}

	db, err := driver.Open(fmt.Sprintf("file:%s?nolock=1", *skuDbFile), func(c *sqlite3.Conn) error {
		csv.Register(c)
		return nil
	})
	if err != nil {
		log.Fatalf("ERROR: Cannot open SQLite database: %v\n", err)
	}
	defer db.Close()

	mapping_sql, err := os.ReadFile("mapping.sql")
	if err != nil {
		log.Fatalf("ERROR: Cannot read mapping.sql: %v\n", err)
	}

	if _, err := db.Exec(fmt.Sprintf(string(mapping_sql), *mapFile)); err != nil {
		log.Fatalf("ERROR: Failed to do mapping: %v\n", err)
	}

	fmt.Println("DONE")
}

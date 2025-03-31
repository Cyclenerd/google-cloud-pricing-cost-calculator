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
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	billing "cloud.google.com/go/billing/apiv1"
	billingpb "cloud.google.com/go/billing/apiv1/billingpb"
	_ "github.com/mattn/go-sqlite3"
	"golang.org/x/oauth2"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
	"google.golang.org/grpc/metadata"
)

var version string = "v?.?.?"

var (
	showVersion = flag.Bool("version", false, "Print version")
	delay       = flag.Int("delay", 0, "Delay between requests")
	skuFile     = flag.String("sku", "skus.db", "SQLite3 DB file with SKUs (read/write)")
	serviceId   = flag.String("id", "6F81-5844-456A", "ID of service for getting SKUs")
)

func main() {
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	delayDuration := time.Duration(*delay)

	db, err := sql.Open("sqlite3", *skuFile)
	if err != nil {
		log.Fatalf("ERROR: Cannot open SQLite3 database '%s' with SKUs: %v\n", *skuFile, err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			// Handle the error appropriately. For example, you could log it.
			log.Printf("Error closing database: %v", err)
		}
	}()

	apiKey := os.Getenv("API_KEY")

	ctx := context.Background()
	ctx = metadata.AppendToOutgoingContext(ctx, "x-goog-api-key", apiKey)
	opts := option.WithTokenSource(oauth2.StaticTokenSource(&oauth2.Token{}))
	c, err := billing.NewCloudCatalogClient(ctx, opts)
	if err != nil {
		log.Fatalf("ERROR: Cannot create Google Cloud Billing client: %v\n", err)
	}
	defer func() {
		if err := c.Close(); err != nil {
			// Handle the error appropriately. For example, you could log it.
			log.Printf("Error closing connection: %v", err)
		}
	}()

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		log.Fatalf("ERROR: Cannot create transaction: %v\n", err)
	}
	// Defer a rollback in case anything fails.
	defer tx.Rollback() //nolint:errcheck

	insertQuery, err := tx.Prepare(`
		INSERT INTO skus (
			SKU_NAME,
			SKU_ID,
			SKU_DESCRIPTION,
			SVC_DISPLAY_NAME,
			FAMILY,
			"GROUP",
			USAGE,
			REGIONS,
			TIME,
			SUMMARY,
			UNIT,
			UNIT_DESCRIPTION,
			BASE_UNIT,
			BASE_UNIT_DESCRIPTION,
			BASE_UNIT_CONVERSION_FACTOR,
			DISPLAY_QUANTITY,
			START_AMOUNT,
			CURRENCY_CODE,
			UNITS,
			NANOS,
			AGGREGATION_LEVEL,
			AGGREGATION_INTERVAL,
			AGGREGATION_COUNT,
			CONVERSION_RATE,
			SERVICE_PROVIDER,
			GEO_TYPE,
			GEO_REGIONS
		) VALUES (
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
		)
	`)
	if err != nil {
		log.Fatalf("ERROR: Cannot prepare insert statement: %v\n", err)
	}

	req := &billingpb.ListSkusRequest{
		Parent: fmt.Sprintf("services/%s", *serviceId),
	}
	it := c.ListSkus(ctx, req)
	skusCount := 0
	for {
		sku, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Fatalf("ERROR: Cannot get next SKU from iterator: %v\n", err)
		}

		skusCount += 1

		serviceRegions := make([]string, len(sku.ServiceRegions))
		for i, serviceRegion := range sku.ServiceRegions {
			switch serviceRegion {
			case "asia":
				serviceRegion = "asia-multi"
			case "europe":
				serviceRegion = "europe-multi"
			case "us":
				serviceRegion = "us-multi"
			}
			serviceRegions[i] = serviceRegion
		}

		pricingInfo := sku.PricingInfo[0]

		tieredRates := pricingInfo.PricingExpression.TieredRates

		startUsageAmount := make([]float64, len(tieredRates))
		unitPrice_currencyCode := make([]string, len(tieredRates))
		unitPrice_units := make([]int64, len(tieredRates))
		unitPrice_nanos := make([]int32, len(tieredRates))
		for i, tieredRate := range tieredRates {
			startUsageAmount[i] = tieredRate.StartUsageAmount
			unitPrice_currencyCode[i] = tieredRate.UnitPrice.CurrencyCode
			unitPrice_units[i] = tieredRate.UnitPrice.Units
			unitPrice_nanos[i] = tieredRate.UnitPrice.Nanos
		}

		var aggregationLevel *string
		var aggregationInterval *string
		var aggregationCount *int32
		if pricingInfo.AggregationInfo != nil {
			aggregationLevelString := pricingInfo.AggregationInfo.AggregationLevel.String()
			aggregationLevel = &aggregationLevelString
			aggregationCountString := pricingInfo.AggregationInfo.AggregationInterval.String()
			aggregationInterval = &aggregationCountString
			aggregationCountInt := pricingInfo.AggregationInfo.AggregationCount
			aggregationCount = &aggregationCountInt
		}

		serviceRegionsString := strings.Join(serviceRegions, ",")
		startUsageAmountString := strings.Trim(strings.Join(strings.Fields(fmt.Sprint(startUsageAmount)), ","), "[]")
		unitPrice_currencyCodeString := strings.Join(unitPrice_currencyCode, ",")
		unitPrice_unitsString := strings.Trim(strings.Join(strings.Fields(fmt.Sprint(unitPrice_units)), ","), "[]")
		unitPrice_nanosString := strings.Trim(strings.Join(strings.Fields(fmt.Sprint(unitPrice_nanos)), ","), "[]")

		var taxonomyRegions *string
		var taxonomyRegionsString string
		var taxonomyType *string
		if sku.GeoTaxonomy != nil {
			taxonomyRegionsString = strings.Join(sku.GeoTaxonomy.Regions, ",")
			taxonomyRegions = &taxonomyRegionsString
			taxonomyTypeString := sku.GeoTaxonomy.Type.String()
			taxonomyType = &taxonomyTypeString
		}

		if _, err := insertQuery.Exec(
			sku.Name,
			sku.SkuId,
			sku.Description,
			sku.Category.ServiceDisplayName,
			sku.Category.ResourceFamily,
			sku.Category.ResourceGroup,
			sku.Category.UsageType,
			serviceRegionsString,
			pricingInfo.EffectiveTime.AsTime().Format(time.RFC3339Nano),
			pricingInfo.Summary,
			pricingInfo.PricingExpression.UsageUnit,
			pricingInfo.PricingExpression.UsageUnitDescription,
			pricingInfo.PricingExpression.BaseUnit,
			pricingInfo.PricingExpression.BaseUnitDescription,
			pricingInfo.PricingExpression.BaseUnitConversionFactor,
			pricingInfo.PricingExpression.DisplayQuantity,
			startUsageAmountString,
			unitPrice_currencyCodeString,
			unitPrice_unitsString,
			unitPrice_nanosString,
			aggregationLevel,
			aggregationInterval,
			aggregationCount,
			pricingInfo.CurrencyConversionRate,
			sku.ServiceProviderName,
			// BETA
			taxonomyType,
			taxonomyRegions,
		); err != nil {
			log.Fatalf("ERROR: Failed to insert SKU to database: %v\n", err)
		}

		if *delay != 0 {
			time.Sleep(delayDuration)
		}
	}

	if err = tx.Commit(); err != nil {
		log.Fatalf("ERROR: Cannot commit transaction: %v\n", err)
	}

	fmt.Printf("OK: %d SKUs successfully exported to SQLite DB file\n", skusCount)
}

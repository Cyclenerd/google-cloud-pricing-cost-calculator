/*
 * Create SQLite3 database for SKU export
 */

DROP TABLE IF EXISTS "skus";
DROP TABLE IF EXISTS "mapping";
CREATE TABLE IF NOT EXISTS "skus" (
	"SKU_NAME"                    TEXT PRIMARY KEY, -- 'name',
	"SKU_ID"                      TEXT,             -- 'skuId',
	"MAPPING"                     TEXT,             -- --> for mapping
	"SKU_DESCRIPTION"             TEXT,             -- 'description',
	"SVC_DISPLAY_NAME"            TEXT,             -- 'category/serviceDisplayName',
	"FAMILY"                      TEXT,             -- 'category/resourceFamily',
	"GROUP"                       TEXT,             -- 'category/resourceGroup',
	"USAGE"                       TEXT,             -- 'category/usageType',
	"REGIONS"                     TEXT,             -- 'serviceRegions',
	"TIME"                        TEXT,             -- 'pricingInfo/effectiveTime',
	"SUMMARY"                     TEXT,             -- 'pricingInfo/summary',
	"UNIT"                        TEXT,             -- 'pricingInfo/pricingExpression/usageUnit',
	"UNIT_DESCRIPTION"            TEXT,             -- 'pricingInfo/pricingExpression/usageUnitDescription',
	"BASE_UNIT"                   TEXT,             -- 'pricingInfo/pricingExpression/baseUnit',
	"BASE_UNIT_DESCRIPTION"       TEXT,             -- 'pricingInfo/pricingExpression/baseUnitDescription',
	"BASE_UNIT_CONVERSION_FACTOR" TEXT,             -- 'pricingInfo/pricingExpression/baseUnitConversionFactor',
	"DISPLAY_QUANTITY"            TEXT,             -- 'pricingInfo/pricingExpression/displayQuantity',
	"START_AMOUNT"                TEXT,             -- 'pricingInfo/pricingExpression/tieredRates/startUsageAmount',
	"CURRENCY_CODE"               TEXT,             -- 'pricingInfo/pricingExpression/tieredRates/unitPrice/currencyCode',
	"UNITS"                       TEXT,             -- 'pricingInfo/pricingExpression/tieredRates/unitPrice/units',
	"NANOS"                       TEXT,             -- 'pricingInfo/pricingExpression/tieredRates/unitPrice/nanos',
	"AGGREGATION_LEVEL"           TEXT,             -- 'pricingInfo/aggregationInfo/aggregationLevel',
	"AGGREGATION_INTERVAL"        TEXT,             -- 'pricingInfo/aggregationInfo/aggregationInterval',
	"AGGREGATION_COUNT"           TEXT,             -- 'pricingInfo/aggregationInfo/aggregationCount',
	"CONVERSION_RATE"             TEXT,             -- 'pricingInfo/currencyConversionRate',
	"SERVICE_PROVIDER"            TEXT,             -- 'serviceProviderName',
	-- BETA!
	"GEO_TYPE"                    TEXT,             -- 'geoTaxonomy/type',
	"GEO_REGIONS"                 TEXT              -- 'geoTaxonomy/regions',
);
CREATE TABLE IF NOT EXISTS "mapping" (
	"MAPPING"                     TEXT,
	"SVC_DISPLAY_NAME"            TEXT,
	"FAMILY"                      TEXT,
	"GROUP"                       TEXT,
	"SKU_DESCRIPTION"             TEXT,
	"COMMENT"                     TEXT
);

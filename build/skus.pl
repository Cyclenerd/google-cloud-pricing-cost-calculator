#!/usr/bin/perl

# Copyright 2022 Nils Knieling. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Export list of SKUs for a service from the Cloud Billing Catalog to a CSV file
#

BEGIN {
	$VERSION = "1.0.0";
}

use utf8;
binmode(STDOUT, ':encoding(utf8)');
use strict;
use Encode;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON::XS;
use App::Options (
	option => {
		key => {
			required    => 1,
			secure      => 1,
			description => "Cloud Billing Catalog API requires an API Key",
			env         => "API_KEY"
		},
		id => {
			required    => 1,
			# 95FF-2EF5-5EA1 : Cloud Storage
			# 6F81-5844-456A : Compute Engine
			default     => '6F81-5844-456A',
			description => "Identifier for the service (serviceId)"
		},
		csv => {
			required    => 1,
			default     => 'skus.csv',
			description => "CSV file for SKU export"
		},
	},
);

my $debug = $App::options{debug_options};

# Google API
my $api_key = $App::options{key};
my $service_id = $App::options{id};
my $api_url = "https://cloudbilling.googleapis.com/v1/services/$service_id/skus";
my $api_page_size       = 500;
my $api_max_next_page   = 50;
my $api_next_page_token = '';

# CSV export
my $csv_file = $App::options{csv};
open my $fh, q{>}, "$csv_file" or die "ERROR: Cannot open CSV file '$csv_file' for export!\n";

# HTTP request
my $ua = LWP::UserAgent->new;
# Set timeout to 15sec
$ua->timeout("15");

# Listing public services from the catalog and output to CSV file
print $fh join(";", (
	'SKU_NAME',                    # 'name',
	'SKU_ID',                      # 'skuId',
	'MAPPING',                     # --> for mapping
	'SKU_DESCRIPTION',             # 'description',
	'SVC_DISPLAY_NAME',            # 'category/serviceDisplayName',
	'FAMILY',                      # 'category/resourceFamily',
	'GROUP',                       # 'category/resourceGroup',
	'USAGE',                       # 'category/usageType',
	'REGIONS',                     # 'serviceRegions',
	'TIME',                        # 'pricingInfo/effectiveTime',
	'SUMMARY',                     # 'pricingInfo/summary',
	'UNIT',                        # 'pricingInfo/pricingExpression/usageUnit',
	'UNIT_DESCRIPTION',            # 'pricingInfo/pricingExpression/usageUnitDescription',
	'BASE_UNIT',                   # 'pricingInfo/pricingExpression/baseUnit',
	'BASE_UNIT_DESCRIPTION',       # 'pricingInfo/pricingExpression/baseUnitDescription',
	'BASE_UNIT_CONVERSION_FACTOR', # 'pricingInfo/pricingExpression/baseUnitConversionFactor',
	'DISPLAY_QUANTITY',            # 'pricingInfo/pricingExpression/displayQuantity',
	'START_AMOUNT',                # 'pricingInfo/pricingExpression/tieredRates/startUsageAmount',
	'CURRENCY_CODE',               # 'pricingInfo/pricingExpression/tieredRates/unitPrice/currencyCode',
	'UNITS',                       # 'pricingInfo/pricingExpression/tieredRates/unitPrice/units',
	'NANOS',                       # 'pricingInfo/pricingExpression/tieredRates/unitPrice/nanos',
	'AGGREGATION_LEVEL',           # 'pricingInfo/aggregationInfo/aggregationLevel',
	'AGGREGATION_INTERVAL',        # 'pricingInfo/aggregationInfo/aggregationInterval',
	'AGGREGATION_COUNT',           # 'pricingInfo/aggregationInfo/aggregationCount',
	'CONVERSION_RATE',             # 'pricingInfo/currencyConversionRate',
	'SERVICE_PROVIDER',            # 'serviceProviderName',
	# BETA!
	'GEO_TYPE',    # 'geoTaxonomy/type',
	'GEO_REGIONS', # 'geoTaxonomy/regions',
))."\n";
my $count_skus = 0;
for (my $i = 1; $i <= $api_max_next_page; $i++) {
	my $url = "$api_url"."?key=$api_key"."&pageSize=$api_page_size"."&pageToken=$api_next_page_token";
	my $api_request  = GET "$url";
	print "$i.\n";
	warn "WARNING: Last page\n" if $i == $api_max_next_page;
	print "» API URL: $url\n" if $debug;
	my $api_response = $ua->request($api_request);
	my $api_status   = $api_response->status_line     || "";
	my $api_content  = $api_response->decoded_content || "";
	if ($api_response->is_success) {
		my $api_json = eval { decode_json($api_content) };
		my $skus = $api_json->{'skus'} || "";
		$api_next_page_token = $api_json->{'nextPageToken'} || "";
		foreach my $sku ( @{ $skus } ) {
			$count_skus++;

			# Service regions
			my $service_regions = $sku->{'serviceRegions'} || ();
			my @serviceRegions = ();
			foreach my $service_region ( @{$service_regions} ) {
				# Rename multi regions for better search
				if ($service_region eq 'asia')   { $service_region = 'asia-multi'; }
				if ($service_region eq 'europe') { $service_region = 'europe-multi'; }
				if ($service_region eq 'us')     { $service_region = 'us-multi'; }
				push @serviceRegions, $service_region;
			}

			# Pricing info
			my $pricing_info = $sku->{'pricingInfo'} || ();
			$pricing_info = @{ $pricing_info }[0]; # Only first pricing
			
			# Tiered rates
			my $tiered_rates = $pricing_info->{'pricingExpression'}->{'tieredRates'} || ();
			my @startUsageAmount       = ();
			my @unitPrice_currencyCode = ();
			my @unitPrice_units        = ();
			my @unitPrice_nanos        = ();
			foreach my $tiered_rate ( @{ $tiered_rates } ) {
				push @startUsageAmount,       $tiered_rate->{'startUsageAmount'}            || '0';
				push @unitPrice_currencyCode, $tiered_rate->{'unitPrice'}->{'currencyCode'} || '';
				push @unitPrice_units,        $tiered_rate->{'unitPrice'}->{'units'}        || '0';
				push @unitPrice_nanos,        $tiered_rate->{'unitPrice'}->{'nanos'}        || '0';
			}

			# Taxonomy regions
			my $geo_regions = $sku->{'geoTaxonomy'}->{'regions'} || ();
			my @geoTaxonomy_regions = ();
			foreach my $geo_region ( @{ $geo_regions } ) {
				push @geoTaxonomy_regions, $geo_region;
			}

			print $fh join(';', (
				$sku->{'name'},
				$sku->{'skuId'},
				'TODO',
				$sku->{'description'} || '',
				$sku->{'category'}->{'serviceDisplayName'} || '',
				$sku->{'category'}->{'resourceFamily'} || '',
				$sku->{'category'}->{'resourceGroup'} || '',
				$sku->{'category'}->{'usageType'} || '',
				join(',', @serviceRegions),
				$pricing_info->{'effectiveTime'} || '',
				$pricing_info->{'summary'} || '',
				$pricing_info->{'pricingExpression'}->{'usageUnit'} || '',
				$pricing_info->{'pricingExpression'}->{'usageUnitDescription'} || '',
				$pricing_info->{'pricingExpression'}->{'baseUnit'} || '',
				$pricing_info->{'pricingExpression'}->{'baseUnitDescription'} || '',
				$pricing_info->{'pricingExpression'}->{'baseUnitConversionFactor'} || '',
				$pricing_info->{'pricingExpression'}->{'displayQuantity'} || '',
				join(',', @startUsageAmount),
				join(',', @unitPrice_currencyCode),
				join(',', @unitPrice_units),
				join(',', @unitPrice_nanos),
				$pricing_info->{'aggregationInfo'}->{'aggregationLevel'} || '',
				$pricing_info->{'aggregationInfo'}->{'aggregationInterval'} || '',
				$pricing_info->{'aggregationInfo'}->{'aggregationCount'} || '',
				$pricing_info->{'currencyConversionRate'} || '',
				$sku->{'serviceProviderName'} || '',
				# BETA
				$sku->{'geoTaxonomy'}->{'type'} || '',
				join(',', @geoTaxonomy_regions),
			))."\n";
		}
		last unless $api_next_page_token; # last page, end for loop
	} else {
		die "\nERROR: Calling Cloud Billing Catalog API\nStatus: $api_status\nContent:\n$api_content\n";
	}
}

close $fh;
print "\nOK: $count_skus SKUs successfully exported to CSV file '$csv_file'\n";
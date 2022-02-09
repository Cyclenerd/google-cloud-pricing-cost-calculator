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
# Export public services from the Cloud Billing Catalog to a CSV file
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
		csv => {
			required    => 1,
			default     => 'services.csv',
			description => "CSV file for services export"
		}
	},
);

my $debug = $App::options{debug_options};

# Google API
my $api_key = $App::options{key};
my $api_url = 'https://cloudbilling.googleapis.com/v1/services';
my $api_page_size       = 500;
my $api_max_next_page   = 10; # $api_page_size * $api_max_next_page = max services (5000), 2021-11-26: 1720 services
my $api_next_page_token = '';

# CSV export
my $csv_file = $App::options{csv};
open my $fh, q{>}, "$csv_file" or die "ERROR: Cannot open CSV file '$csv_file' for export!\n";

# HTTP request
my $ua = LWP::UserAgent->new;
# Set timeout to 15sec
$ua->timeout("15");

# Listing public services from the catalog and output to CSV file
print $fh "SERVICE_NAME;SERVICE_ID;SERVICE_DISPLAY_NAME\n";
my $count_services = 0;
for (my $i = 1; $i <= $api_max_next_page; $i++) {
	my $url = "$api_url"."?key=$api_key"."&pageSize=$api_page_size"."&pageToken=$api_next_page_token";
	my $api_request  = GET "$url";
	print "$i.\n";
	print "» API URL: $url\n" if $debug;
	my $api_response = $ua->request($api_request);
	my $api_status   = $api_response->status_line     || "";
	my $api_content  = $api_response->decoded_content || "";
	if ($api_response->is_success) {
		my $api_json = eval { decode_json($api_content) };
		my $services = $api_json->{'services'} || "";
		$api_next_page_token = $api_json->{'nextPageToken'} || "";
		foreach my $service ( @{ $services } ) {
			$count_services++;
			print $fh join(";", (
				$service->{'name'},
				$service->{'serviceId'},
				$service->{'displayName'},
				#$service->{'businessEntityName'}
			))."\n";
		}
		last unless $api_next_page_token; # last page, end for loop
	} else {
		die "\nERROR: Calling Cloud Billing Catalog API\nStatus: $api_status\nContent:\n$api_content\n";
	}
}

close $fh;
print "\nOK: $count_services services successfully exported to CSV file '$csv_file'\n";
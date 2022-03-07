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
# Update mapping
#

BEGIN {
	$VERSION = "1.0.0";
}

use strict;
use DBI;
use App::Options (
	option => {
		sku => {
			required    => 1,
			default     => 'skus.csv',
			type        => '/^[a-z0-9_]+\.csv$/',
			description => "CSV file with SKUs (write)"
		},
		mapping => {
			required    => 1,
			default     => 'mapping.csv',
			type        => '/^[a-z0-9_]+\.csv$/',
			description => "CSV file with mapping (read)"
		},
		reset => {
			required    => 0,
			default     => 0,
			type        => 'boolean',
			description => "Reset mapping (0=no, 1=yes)"
		}
	},
);

# CSV files
my $csv_skus = $App::options{sku};
if (-w "$csv_skus") { # write
	$csv_skus =~ s/\.csv$//;
} else {
	die "ERROR: Cannot open CSV file '$csv_skus' with SKUs!\n";
}
my $csv_mapping = $App::options{mapping};
if (-r "$csv_mapping") { # read
	$csv_mapping =~ s/\.csv$//;
} else {
	die "ERROR: Cannot open CSV file '$csv_mapping' with mapping!\n";
}

my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
	f_ext        => ".csv/r",
	csv_sep_char => ";",
	csv_class    => "Text::CSV_XS",
	RaiseError   => 1,
}) or die "ERROR: Cannot connect $DBI::errstr\n";

# Reset?
my $reset = $App::options{reset};
if ($reset) {
	$dbh->do("UPDATE $csv_skus SET MAPPING = 'TODO'");
}

# Update mapping (SKUs)
my $sth = $dbh->prepare("SELECT MAPPING, SVC_DISPLAY_NAME, FAMILY, GROUP, SKU_DESCRIPTION FROM $csv_mapping");
$sth->execute();
$sth->bind_columns(\my ($mapping, $service_display_name, $resource_family, $group, $sku_description));
while ($sth->fetch) {
	print "'$mapping'\n";
	if ($service_display_name) {
		print "  '$service_display_name'\n";
		print "  '$resource_family'\n";
		print "  '$group'\n";
		print "  '$sku_description'\n";
		my $update = $dbh->prepare("UPDATE $csv_skus SET MAPPING = ? WHERE SVC_DISPLAY_NAME = ? AND FAMILY = ? AND GROUP = ? AND SKU_DESCRIPTION LIKE ?");
		$update->execute("$mapping", "$service_display_name", "$resource_family", "$group", "$sku_description");
		$update->finish;
	} else {
		print "-"x80 ."\n";
	}
	
}
$dbh->disconnect;
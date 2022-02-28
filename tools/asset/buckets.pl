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
# Get and save bucket object size
#

BEGIN {
	$VERSION = "0.9.0";
}

use strict;
use YAML::XS qw(LoadFile);
use App::Options (
	option => {
		assets => {
			required    => 1,
			default     => 'assets.yml',
			description => "YAML file with GCP asset information export (read)"
		},
		buckets => {
			required    => 1,
			default     => 'buckets.yml',
			description => "YAML file for bucket object size usage export (write)"
		}
	},
);

# Debug?
my $debug = $App::options{debug_options};

# Input
my $asset_file  = $App::options{assets};
my $bucket_file  = $App::options{buckets};

# Open asset file
unless (-r "$asset_file") {
	die "ERROR: Cannot read YAML file '$asset_file' with GCP asset informations!\n";
}
my @inventory_assets = LoadFile("$asset_file") or die "ERROR: Cannot open YAML file '$asset_file' to read GCP asset informations!\n";

open my $fh, q{>}, "$bucket_file" or die "ERROR: Cannot open YAML file '$bucket_file' for bucket object size export!\n";
foreach my $asset (@inventory_assets) {
	my $name = $asset->{'displayName'};
	# storage.googleapis.com/Bucket
	unless ($asset->{'assetType'} eq 'storage.googleapis.com/Bucket') {
		next; # skip
	}
	print "\n» $name : ";
	my $data = 0;
	my $gsutil_du_bucket = `gsutil du -s -0 "gs://$name"`;
	if ($gsutil_du_bucket =~ /^(\d+)/) {
		$data = $1;
	}
	$data = sprintf("%.6f", $data / 1073741824); # GiB
	print "$data";
	print $fh "$name: $data\n";
}
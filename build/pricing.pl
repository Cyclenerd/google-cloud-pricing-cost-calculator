#!/usr/bin/perl

# Copyright 2022-2025 Nils Knieling. All Rights Reserved.
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
# Generate the YAML file with the Google Cloud Platform pricing information
#

BEGIN {
	$VERSION = "2.3.1";
}

use strict;
use DBI;
use YAML::XS qw(LoadFile Dump);
use App::Options (
	option => {
		sku => {
			required    => 1,
			default     => 'skus.db',
			type        => '/^[a-z0-9_]+\.db$/',
			description => "SQLite DB file with SKUs and mapping information (read)"
		},
		gcp => {
			required    => 1,
			default     => 'gcp.yml',
			type        => '/^[a-z0-9_]+\.yml$/',
			description => "YAML file with GCP information (read)"
		},
		export => {
			required    => 1,
			default     => 'pricing.yml',
			type        => '/^[a-z0-9_]+\.yml$/',
			description => "YAML file for pricing information export (write)"
		},
		details => {
			required    => 0,
			default     => 0,
			type        => 'boolean',
			description => "Export mapping details"
		},
		region => {
			required    => 0,
			description => "Export only this region [DEFAULT: All regions]"
		},
		hours => {
			required    => 1,
			default     => '730',
			type        => '/^\d{1,3}$/',
			description => "Hours per month [DEFAULT: 730, same as Google Cloud Pricing Calculator]"
		},
		sud => {
			required    => 1,
			default     => 1,
			type        => 'boolean',
			description => "Add Sustained Use Discount (SUD) [DEFAULT: 1 = yes]"
		},
	},
);

# Configuration
my $hours_month    = $App::options{hours};
my $add_sud        = $App::options{sud};
my $export_details = $App::options{details};

# Open YAML file with GCP information for import (gcp.yml)
my $yml_import = $App::options{gcp};
unless (-r "$yml_import") { # read
	die "ERROR: Cannot open YAML file '$yml_import' for GCP information import!\n";
}
my $gcp = LoadFile("$yml_import");

# Open YAML file for pricing export (pricing.yml)
my $yml_export = $App::options{export};
open my $fh, q{>}, "$yml_export" or die "ERROR: Cannot open YAML file '$yml_export' for export!\n";


###############################################################################
# HELPER
###############################################################################

sub print_line {
	print "-"x80 . "\n";
}

sub print_header {
	my ($header) = @_;
	&print_line();
	print uc($header) . "\n";
	&print_line();
}


###############################################################################
# SKUS
###############################################################################

# Open DB file with SKU information for import (skus.db)
my $skus_db = $App::options{sku};
my $dbh = DBI->connect("dbi:SQLite:dbname=$skus_db", "", "") or die "ERROR: Cannot connect to DB $DBI::errstr\n";

###############################################################################
# SEARCH MAPPING
###############################################################################

my $sql_mapping = qq ~
SELECT
	NANOS,
	UNITS,
	UNIT_DESCRIPTION,
	SKU_ID,
	SKU_DESCRIPTION,
	REGIONS
FROM skus
WHERE MAPPING = ?
AND REGIONS LIKE ?
~;
my $sth = $dbh->prepare($sql_mapping);
$sth->bind_columns (\my ($nanos, $units, $unit_description, $sku_id, $sku_description, $regions));

# &mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description)
sub mapping_found {
	my ($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description) = @_;
	print "OK: Mapping '$mapping' found in region '$region' found:\n";
	print "  - regions = '$regions'\n";
	print "  - value = '$value'\n";
	print "  - nanos = '$nanos'\n";
	print "  - units = '$units'\n";
	print "  - sku_id = '$sku_id'\n";
	print "  - unit_description = '$unit_description'\n";
	print "  - sku_description = '$sku_description'\n";
}

# &check_region($region, $regions);
sub check_region {
	my ($region, $regions) = @_;
	if ($regions =~ /$region$/) {
		print "OK: Region '$region' in regions '$regions' found\n";
		return 1;
	} elsif ($regions =~ /$region,/) {
		print "OK: Region '$region' in regions '$regions' found\n";
		return 1;
	} else {
		print "NEXT: '$region' in regions '$regions' not found\n";
		return 0;
	}
}

# &calc_cost($value, $units, $nanos)
sub calc_cost {
	my ($value, $units, $nanos) = @_;
	if ($nanos =~ /\,/) {
		my @bulk_nanos = split(',', $nanos);
		print "INFO: Bulk nanos!\n";
		foreach my $i (@bulk_nanos) {
			print "     * $i\n";
		}
		$nanos = $bulk_nanos[-1]; # last
	}
	if ($units =~ /\,/) {
		my @bulk_units = split(',', $units);
		print "INFO: Bulk units!\n";
		foreach my $i (@bulk_units) {
			print "     * $i\n";
		}
		$units = $bulk_units[-1]; # last
	}
	my $cost = $value * ( $units+($nanos*0.000000001) );
	print "CALC: cost = $cost, value = $value, units = $units, nanos = $nanos\n";
	return $cost;
}


###############################################################################
# REGIONS
###############################################################################

my @regions       = keys %{ $gcp->{'region'} };
my @dual_regions  = keys %{ $gcp->{'dual-region'} };
my @multi_regions = keys %{ $gcp->{'multi-region'} };
# Export only one region
my $filter_region = $App::options{region} || '';
@regions = ( "$filter_region" ) if ($filter_region);


###############################################################################
# STACKDRIVER MONITORING
###############################################################################

# &add_gcp_monitoring_data_add_cost($usage, $region, $cost)
sub add_gcp_monitoring_data_add_cost {
	my ($usage, $region, $cost) = @_;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$usage}->{$region}->{'month'} = $cost;
}
# &add_gcp_monitoring_data_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_monitoring_data_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'monitoring'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Monitoring");
foreach my $region (@regions) {
	my $value = 1; # per 1 mebibyte not GB
	# Monitoring data
	#  https://cloud.google.com/monitoring#pricing
	my $mapping = 'monitoring.data';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, 'global'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, 'global', $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		# Bulk price:
		# free       : 0-150 MiB IGNORED
		# $0.2580/MiB: 150–100,000 MiB
		# $0.1510/MiB: 100,000–250,000 MiB
		# $0.0610/MiB: >250,000 MiB
		my @bulk_nanos = split(',', $nanos);
		my @bulk_units = split(',', $units);
		# last price
		my $cost_250000n       = &calc_cost($value, $bulk_units[-1], $bulk_nanos[-1]);
		my $cost_100000_250000 = $cost_250000n;
		my $cost_0_100000      = $cost_250000n;
		# overwrite
		$cost_100000_250000 = &calc_cost($value, $bulk_units[-2], $bulk_nanos[-2]) if $bulk_nanos[-2];
		$cost_0_100000      = &calc_cost($value, $bulk_units[-3], $bulk_nanos[-3]) if $bulk_nanos[-3];

		&add_gcp_monitoring_data_add_cost('0-100000', $region, $cost_0_100000);
		&add_gcp_monitoring_data_add_cost('100000-250000', $region, $cost_100000_250000);
		&add_gcp_monitoring_data_add_cost('250000n', $region, $cost_250000n);
		&add_gcp_monitoring_data_add_details(
			$region,
			$mapping,
			$sku_id,
			$value,
			$nanos,
			$units,
			$unit_description,
			$sku_description
		) if ($export_details);
	} else {
		die "ERROR: '$mapping' (GLOBAL) not found for region '$region'!\n";
	}
	$sth->finish;
}


###############################################################################
# BUCKET STORAGE GB PER MONTH
###############################################################################

# &add_gcp_storage_bucket_cost($what, $bucket, $region, $cost)
sub add_gcp_storage_bucket_cost {
	my ($what, $bucket, $region, $cost) = @_;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{$what}  = $cost;
}
# &add_gcp_storage_bucket_details($bucket, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_storage_bucket_details {
	my ($bucket, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'storage'}->{'bucket'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Bucket Storage");
foreach my $bucket (keys %{ $gcp->{'storage'}->{'bucket'} }) {
	my $value = 1; # 1 GB per month
	my @bucket_regions;
	# Mapping
	# https://cloud.google.com/storage/docs/storage-classes#available_storage_classes
	my $mapping;
	if    ($bucket eq 'standard')       { $mapping = 'storage.standard';       @bucket_regions = @regions; }
	elsif ($bucket eq 'standard-dual')  { $mapping = 'storage.standard.dual';  @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'standard-multi') { $mapping = 'storage.standard.multi'; @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'nearline')       { $mapping = 'storage.nearline';       @bucket_regions = @regions; }
	elsif ($bucket eq 'nearline-dual')  { $mapping = 'storage.nearline.dual';  @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'nearline-multi') { $mapping = 'storage.nearline.multi'; @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'coldline')       { $mapping = 'storage.coldline';       @bucket_regions = @regions; }
	elsif ($bucket eq 'coldline-dual')  { $mapping = 'storage.coldline.dual';  @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'coldline-multi') { $mapping = 'storage.coldline.multi'; @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'archiv')         { $mapping = 'storage.archive';        @bucket_regions = @regions; }
	elsif ($bucket eq 'archiv-dual')    { $mapping = 'storage.archive.dual';   @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'archiv-multi')   { $mapping = 'storage.archive.multi';  @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'dra')            { $mapping = 'storage.dra';            @bucket_regions = @regions; }
	elsif ($bucket eq 'dra-dual')       { $mapping = 'storage.dra.dual';       @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'dra-multi')      { $mapping = 'storage.dra';            @bucket_regions = @multi_regions; } # Multi and region are the same SKU
	# Unknown storage type
	else { die "ERROR: No mapping for storage bucket '$bucket'!\n"; }
	foreach my $region (@bucket_regions) {
		print "Bucket: $bucket\n";
		print "MAPPING: '$mapping' in region '$region'\n";
		$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
		my $found = 0;
		while ($sth->fetch) {
			if (&check_region($region, $regions)) {
				&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($found) {
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n"
				} else {
					$found = 1;
					my $cost = &calc_cost($value, $units, $nanos);
					&add_gcp_storage_bucket_cost('month', $bucket, $region, $cost);
					&add_gcp_storage_bucket_details(
						$bucket,
						$region,
						$mapping,
						$sku_id,
						$value,
						$nanos,
						$units,
						$unit_description,
						$sku_description
					) if ($export_details);
				}
			}
		}
		$sth->finish;
		unless ($found) {
			warn "WARNING: '$mapping' not found in region '$region'!\n";
		}
	}
}

###############################################################################
# BUCKET DATA RETRIEVAL GB PER MONTH
###############################################################################

# &add_gcp_storage_retrieval_cost($what, $bucket, $region, $cost)
sub add_gcp_storage_retrieval_cost {
	my ($what, $bucket, $region, $cost) = @_;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{$what}  = $cost;
}
# &add_gcp_storage_retrieval_details($bucket, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_storage_retrieval_details {
	my ($bucket, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'storage'}->{'retrieval'}->{$bucket}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Bucket Storage Data Retrieval Fee");
foreach my $bucket (keys %{ $gcp->{'storage'}->{'bucket'} }) {
	my $value = 1; # 1 GB per month
	my @bucket_regions;
	# Mapping
	# https://cloud.google.com/storage/docs/storage-classes#available_storage_classes
	my $mapping;
	if    ($bucket eq 'nearline')       { $mapping = 'storage.nearline.retrieval';       @bucket_regions = @regions; }
	elsif ($bucket eq 'nearline-dual')  { $mapping = 'storage.nearline.retrieval';  @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'nearline-multi') { $mapping = 'storage.nearline.retrieval'; @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'coldline')       { $mapping = 'storage.coldline.retrieval';       @bucket_regions = @regions; }
	elsif ($bucket eq 'coldline-dual')  { $mapping = 'storage.coldline.retrieval';  @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'coldline-multi') { $mapping = 'storage.coldline.retrieval'; @bucket_regions = @multi_regions; }
	elsif ($bucket eq 'archiv')         { $mapping = 'storage.archive.retrieval';        @bucket_regions = @regions; }
	elsif ($bucket eq 'archiv-dual')    { $mapping = 'storage.archive.retrieval';   @bucket_regions = @dual_regions; }
	elsif ($bucket eq 'archiv-multi')   { $mapping = 'storage.archive.retrieval';  @bucket_regions = @multi_regions; }
	foreach my $region (@bucket_regions) {
		print "Bucket: $bucket\n";
		print "MAPPING: '$mapping' in region '$region'\n";
		$sth->execute($mapping, 'global'); # Search SKU(s)
		my $found = 0;
		while ($sth->fetch) {
			&mapping_found($mapping, 'global', $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			# Check duplicate entries for mapping and region
			if ($found) {
				die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n"
			} else {
				$found = 1;
				my $cost = &calc_cost($value, $units, $nanos);
				&add_gcp_storage_retrieval_cost('month', $bucket, $region, $cost);
				&add_gcp_storage_retrieval_details(
					$bucket,
					$region,
					$mapping,
					$sku_id,
					$value,
					$nanos,
					$units,
					$unit_description,
					$sku_description
				) if ($export_details);
			}
		}
		$sth->finish;
		unless ($found) {
			warn "WARNING: '$mapping' not found in region '$region'!\n";
		}
	}
}


###############################################################################
# DISK STORAGE GB PER MONTH
###############################################################################

# &add_gcp_compute_storage_cost($what, $disk, $region, $cost)
sub add_gcp_compute_storage_cost {
	my ($what, $disk, $region, $cost) = @_;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{$what}  = $cost;
}
# &add_gcp_compute_storage_details($disk, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_storage_details {
	my ($disk, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'storage'}->{$disk}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Disk Storage");
foreach my $disk (keys %{ $gcp->{'compute'}->{'storage'} }) {
	my $value = 1; # 1 GB per month
	my @storage_regions = @regions;
	# Snapshots can be region or multi region
	if ($disk eq 'snapshot') {
		push @storage_regions, @multi_regions;
	}
	foreach my $region (@storage_regions) {
		print "Disk: $disk\n";
		# Mapping
		my $mapping;
		# Local SSDs
		if    ($disk eq 'local')               { $mapping = 'gce.storage.ssd.local'; }
		# Zonal standard PD
		elsif ($disk eq 'hdd')                 { $mapping = 'gce.storage.hdd'; }
		# Zonal SSD PD
		elsif ($disk eq 'ssd')                 { $mapping = 'gce.storage.ssd'; }
		# Zonal balanced PD
		elsif ($disk eq 'balanced')            { $mapping = 'gce.storage.ssd.balanced'; }
		# Zonal extreme PD
		elsif ($disk eq 'extreme')             { $mapping = 'gce.storage.ssd.extreme'; }
		# Hyperdisk Extreme
		elsif ($disk eq 'hyperdisk-extreme')   { $mapping = 'gce.storage.hyperdisk.extreme'; }
		# Regional standard PD
		elsif ($disk eq 'hdd-replicated')      { $mapping = 'gce.storage.hdd.replicated'; }
		# Regional SSD PD
		elsif ($disk eq 'ssd-replicated')      { $mapping = 'gce.storage.ssd.replicated'; }
		# Regional balanced PD
		elsif ($disk eq 'balanced-replicated') { $mapping = 'gce.storage.ssd.balanced.replicated'; }
		# Snapshot
		elsif ($disk eq 'snapshot')            { $mapping = 'gce.storage.snapshot'; }
		# Unknown storage type
		else { die "ERROR: No mapping for disk '$disk'!\n"; }
		print "MAPPING: '$mapping' in region '$region'\n";
		$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
		my $found = 0;
		while ($sth->fetch) {
			if (&check_region($region, $regions)) {
				&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($found) {
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
				} else {
					$found = 1;
					# Bulk price in some regions
					# I.e.: 'Storage PD Snapshot'
					#   https://cloud.google.com/skus/?currency=USD&filter=817F-F5A3-514E
					# 0-5 GB = free
					# >5 GB  = 0.026 USD
					my $cost = &calc_cost($value, $units, $nanos);
					&add_gcp_compute_storage_cost('month', $disk, $region, $cost);
					&add_gcp_compute_storage_details(
						$disk,
						$region,
						$mapping,
						$sku_id,
						$value,
						$nanos,
						$units,
						$unit_description,
						$sku_description
					) if ($export_details);
				}
			}
		}
		$sth->finish;
		if ($found) {
			print "Check 1 Year Commitment:\n";
			my $commitment_1y_found = 0;
			my $mapping_1y = "$mapping".'.1y';
			$sth->execute($mapping_1y, '%'."$region".'%'); # Search SKU(s)
			while ($sth->fetch) {
				if (&check_region($region, $regions)) {
					&mapping_found($mapping_1y, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($commitment_1y_found) {
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping_1y' in region '$region'!\n"
					} else {
						$commitment_1y_found = 1;
						my $cost = &calc_cost($value, $units, $nanos);
						&add_gcp_compute_storage_cost('month_1y', $disk, $region, $cost);
						&add_gcp_compute_storage_details(
							$disk,
							$region,
							$mapping_1y,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			print "Check 3 Year Commitment:\n";
			my $commitment_3y_found = 0;
			my $mapping_3y = "$mapping".'.3y';
			$sth->execute($mapping_3y, '%'."$region".'%'); # Search SKU(s)
			while ($sth->fetch) {
				if (&check_region($region, $regions)) {
					&mapping_found($mapping_3y, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($commitment_3y_found) {
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping_3y' in region '$region'!\n"
					} else {
						$commitment_3y_found = 1;
						my $cost = &calc_cost($value, $units, $nanos);
						&add_gcp_compute_storage_cost('month_3y', $disk, $region, $cost);
						&add_gcp_compute_storage_details(
							$disk,
							$region,
							$mapping_3y,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			print "Check Spot:\n";
			my $spot_found = 0;
			my $mapping_spot = "$mapping".'.spot';
			$sth->execute($mapping_spot, '%'."$region".'%'); # Search SKU(s)
			while ($sth->fetch) {
				if (&check_region($region, $regions)) {
					&mapping_found($mapping_spot, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($spot_found) {
						die "ERROR: Duplicate entry. Already found spot price for this mapping '$mapping_spot' in region '$region'!\n"
					} else {
						$mapping_spot = 1;
						my $cost = &calc_cost($value, $units, $nanos);
						&add_gcp_compute_storage_cost('month_spot', $disk, $region, $cost);
						&add_gcp_compute_storage_details(
							$disk,
							$region,
							$mapping_spot,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
		} else {
			warn "WARNING: '$mapping' not found in region '$region'!\n";
		}
	}
}


###############################################################################
# INSTANCES
###############################################################################

# &add_gcp_compute_instance_cost($what, $machine, $region, $cost)
sub add_gcp_compute_instance_cost {
	my ($what, $machine, $region, $cost) = @_;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_instance_details($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_instance_details {
	my ($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'instance'}->{$machine}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Instances");
foreach my $region (@regions) {
	foreach my $machine (keys %{ $gcp->{'compute'}->{'instance'} }) {
		# Type
		my $type = '';
		my @machine_name = split('-', $machine);
		$type = $machine_name[0];
		# Custom Type
		if ($gcp->{'compute'}->{'instance'}->{$machine}->{'type'}) {
			$type = $gcp->{'compute'}->{'instance'}->{$machine}->{'type'};
		}
		# CPU and RAM
		my $cpu            = $gcp->{'compute'}->{'instance'}->{$machine}->{'cpu'}            || '0';
		my $ram            = $gcp->{'compute'}->{'instance'}->{$machine}->{'ram'}            || '0';
		my $local_ssd      = $gcp->{'compute'}->{'instance'}->{$machine}->{'local-ssd'}      || '0';
		my $a100           = $gcp->{'compute'}->{'instance'}->{$machine}->{'a100'}           || '0';
		my $a100_80gb      = $gcp->{'compute'}->{'instance'}->{$machine}->{'a100-80gb'}      || '0';
		my $h100_80gb      = $gcp->{'compute'}->{'instance'}->{$machine}->{'h100-80gb'}      || '0';
		my $h100_80gb_mega = $gcp->{'compute'}->{'instance'}->{$machine}->{'h100-80gb-mega'} || '0';
		my $l4             = $gcp->{'compute'}->{'instance'}->{$machine}->{'l4'}             || '0';

		print "Machine: $machine\n";
		print "Type: $type\n";

		# Sustained Use Discount
		# https://cloud.google.com/compute/docs/sustained-use-discounts
		my %sustained_use_discount = (
			1 => 1, # 0%–25%
			2 => 1, # 25%–50%
			3 => 1, # 50%–75%
			4 => 1, # 75%–100%
		);
		my %sustained_use_discount_n1 = (
			1 => 1,   # 0%–25%   = 100% of base rate
			2 => 0.8, # 25%–50%  = 80% of base rate
			3 => 0.6, # 50%–75%  = 60% of base rate
			4 => 0.4, # 75%–100% = 40% of base rate
		);
		my %sustained_use_discount_n2 = (
			1 => 1,      # 0%–25%   = 100% of base rate
			2 => 0.8678, # 25%–50%  = 86.78% of base rate
			3 => 0.733,  # 50%–75%  = 73.3% of base rate
			4 => 0.6,    # 75%–100% = 60% of base rate
		);

		# Mapping
		my %mappings;
		# Mapping for commitments
		# https://cloud.google.com/compute/docs/instances/signing-up-committed-use-discounts#commitment_types
		my %mappings_1y;
		my %mappings_3y;
		# Mapping for Spot VMs
		my %mappings_spot;
		# Mapping for upgrades without commitments like M2 upgrade but with sustained use discount
		my %mapping_upgrades;

		# Save if a mapping of CPU, RAM or GPU was not found in region.
		# For example, the CPU of the instance may be available but not the GPU.
		# The price would then be calculated without a GPU and would be far too low.
		# With this variable, we could then set the price to zero at the end.
		my $mapping_not_found        = 0;
		my $cud_1y_mapping_not_found = 0;
		my $cud_3y_mapping_not_found = 0;
		my $spot_mapping_not_found   = 0;

		# E2 Predefined
		if ($type eq 'e2') {
			$mappings{     'gce.compute.cpu.e2'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.e2.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.e2.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.e2.spot'} = $cpu;
			$mappings{     'gce.compute.ram.e2'}      = $ram;
			$mappings_1y{  'gce.compute.ram.e2.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.e2.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.e2.spot'} = $ram;
		}
		# F1 Predefined
		elsif ($type eq 'f1') {
			$mappings{     'gce.compute.cpu.f1'}      = $cpu;
			$mappings_spot{'gce.compute.cpu.f1.spot'} = $cpu;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
			# RAM incl.
		}
		# G1 Predefined
		elsif ($type eq 'g1') {
			$mappings{     'gce.compute.cpu.g1'}      = $cpu;
			$mappings_spot{'gce.compute.cpu.g1.spot'} = $cpu;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
			# RAM incl.
		}
		# N1 Predefined
		elsif ($type eq 'n1') {
			$mappings{     'gce.compute.cpu.n1'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n1.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.n1.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.n1.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n1'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n1.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.n1.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.n1.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# N1 Custom
		elsif ($type eq 'n1-custom') {
			$mappings{     'gce.compute.cpu.n1.custom'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n1.1y'}          = $cpu;
			$mappings_3y{  'gce.compute.cpu.n1.3y'}          = $cpu;
			$mappings_spot{'gce.compute.cpu.n1.custom.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n1.custom'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n1.1y'}          = $ram;
			$mappings_3y{  'gce.compute.ram.n1.3y'}          = $ram;
			$mappings_spot{'gce.compute.ram.n1.custom.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# N2 Predefined
		elsif ($type eq 'n2') {
			$mappings{     'gce.compute.cpu.n2'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n2.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.n2.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.n2.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n2'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n2.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.n2.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.n2.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N2 Custom
		elsif ($type eq 'n2-custom') {
			$mappings{     'gce.compute.cpu.n2.custom'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n2.1y'}          = $cpu;
			$mappings_3y{  'gce.compute.cpu.n2.3y'}          = $cpu;
			$mappings_spot{'gce.compute.cpu.n2.custom.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n2.custom'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n2.1y'}          = $ram;
			$mappings_3y{  'gce.compute.ram.n2.3y'}          = $ram;
			$mappings_spot{'gce.compute.ram.n2.custom.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N2D Predefined
		elsif ($type eq 'n2d') {
			$mappings{     'gce.compute.cpu.n2d'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n2d.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.n2d.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.n2d.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n2d'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n2d.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.n2d.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.n2d.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N2D Custom
		elsif ($type eq 'n2d-custom') {
			$mappings{     'gce.compute.cpu.n2d.custom'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n2d.1y'}          = $cpu;
			$mappings_3y{  'gce.compute.cpu.n2d.3y'}          = $cpu;
			$mappings_spot{'gce.compute.cpu.n2d.custom.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n2d.custom'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n2d.1y'}          = $ram;
			$mappings_3y{  'gce.compute.ram.n2d.3y'}          = $ram;
			$mappings_spot{'gce.compute.ram.n2d.custom.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N4 Predefined
		elsif ($type eq 'n4') {
			$mappings{     'gce.compute.cpu.n4'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n4.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.n4.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.n4.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n4'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n4.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.n4.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.n4.spot'} = $ram;
		}
		# N4 Custom
		elsif ($type eq 'n4-custom') {
			$mappings{     'gce.compute.cpu.n4.custom'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.n4.1y'}          = $cpu;
			$mappings_3y{  'gce.compute.cpu.n4.3y'}          = $cpu;
			$mappings_spot{'gce.compute.cpu.n4.custom.spot'} = $cpu;
			$mappings{     'gce.compute.ram.n4.custom'}      = $ram;
			$mappings_1y{  'gce.compute.ram.n4.1y'}          = $ram;
			$mappings_3y{  'gce.compute.ram.n4.3y'}          = $ram;
			$mappings_spot{'gce.compute.ram.n4.custom.spot'} = $ram;
		}
		# T2D Predefined
		elsif ($type eq 't2d') {
			$mappings{     'gce.compute.cpu.t2d'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.t2d.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.t2d.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.t2d.spot'} = $cpu;
			$mappings{     'gce.compute.ram.t2d'}      = $ram;
			$mappings_1y{  'gce.compute.ram.t2d.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.t2d.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.t2d.spot'} = $ram;
		}
		# T2A Predefined
		# The Tau T2A machine series does not support: Committed and Sustained-use discounts
		elsif ($type eq 't2a') {
			$mappings{     'gce.compute.cpu.t2a'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.t2a.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.t2a.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.t2a.spot'} = $cpu;
			$mappings{     'gce.compute.ram.t2a'}      = $ram;
			$mappings_1y{  'gce.compute.ram.t2a.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.t2a.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.t2a.spot'} = $ram;
		}
		# C2
		elsif ($type eq 'c2') {
			$mappings{     'gce.compute.cpu.compute.optimized'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.compute.optimized.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.compute.optimized.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.compute.optimized.spot'} = $cpu;
			$mappings{     'gce.compute.ram.compute.optimized'}      = $ram;
			$mappings_1y{  'gce.compute.ram.compute.optimized.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.compute.optimized.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.compute.optimized.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# C2D
		elsif ($type eq 'c2d') {
			$mappings{     'gce.compute.cpu.c2d'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c2d.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c2d.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c2d.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c2d'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c2d.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c2d.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c2d.spot'} = $ram;
		}
		# C3
		elsif ($type eq 'c3') {
			$mappings{     'gce.compute.cpu.c3'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c3.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c3.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c3.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c3'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c3.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c3.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c3.spot'} = $ram;
		}
		# C3D
		elsif ($type eq 'c3d') {
			$mappings{     'gce.compute.cpu.c3d'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c3d.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c3d.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c3d.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c3d'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c3d.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c3d.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c3d.spot'} = $ram;
		}
		# C4
		elsif ($type eq 'c4') {
			$mappings{     'gce.compute.cpu.c4'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c4.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c4.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c4.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c4'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c4.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c4.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c4.spot'} = $ram;
		}
		# C4A
		elsif ($type eq 'c4a') {
			$mappings{     'gce.compute.cpu.c4a'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c4a.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c4a.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c4a.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c4a'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c4a.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c4a.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c4a.spot'} = $ram;
		}
		# C4D
		elsif ($type eq 'c4d') {
			$mappings{     'gce.compute.cpu.c4d'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.c4d.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.c4d.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.c4d.spot'} = $cpu;
			$mappings{     'gce.compute.ram.c4d'}      = $ram;
			$mappings_1y{  'gce.compute.ram.c4d.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.c4d.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.c4d.spot'} = $ram;
		}
		# H3
		elsif ($type eq 'h3') {
			$mappings{     'gce.compute.cpu.h3'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.h3.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.h3.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.h3.spot'} = $cpu;
			$mappings{     'gce.compute.ram.h3'}      = $ram;
			$mappings_1y{  'gce.compute.ram.h3.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.h3.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.h3.spot'} = $ram;
		}
		# Z3
		elsif ($type eq 'z3') {
			$mappings{     'gce.compute.cpu.z3'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.z3.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.z3.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.z3.spot'} = $cpu;
			$mappings{     'gce.compute.ram.z3'}      = $ram;
			$mappings_1y{  'gce.compute.ram.z3.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.z3.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.z3.spot'} = $ram;
		}
		# M1
		elsif ($type eq 'm1') {
			$mappings{     'gce.compute.cpu.memory.optimized'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.memory.optimized.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.memory.optimized.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.memory.optimized.spot'} = $cpu;
			$mappings{     'gce.compute.ram.memory.optimized'}      = $ram;
			$mappings_1y{  'gce.compute.ram.memory.optimized.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.memory.optimized.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.memory.optimized.spot'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# M2
		elsif ($type eq 'm2') {
			$mappings{   'gce.compute.cpu.memory.optimized'}   = $cpu;
			$mappings_1y{'gce.compute.cpu.memory.optimized.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.memory.optimized.3y'} = $cpu;
			# no spot provisioning mode (Spot VM)
			$mappings{   'gce.compute.ram.memory.optimized'}   = $ram;
			$mappings_1y{'gce.compute.ram.memory.optimized.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.memory.optimized.3y'} = $ram;
			# M2 upgrade
			$mapping_upgrades{'gce.compute.cpu.memory.optimized.premium.upgrade'} = $cpu;
			$mapping_upgrades{'gce.compute.ram.memory.optimized.premium.upgrade'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# M3
		elsif ($type eq 'm3') {
			$mappings{     'gce.compute.cpu.m3'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.m3.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.m3.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.m3.spot'} = $cpu;
			$mappings{     'gce.compute.ram.m3'}      = $ram;
			$mappings_1y{  'gce.compute.ram.m3.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.m3.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.m3.spot'} = $ram;
			# M3 machine types do not offer sustained use discounts.
		}
		# M4
		elsif ($type eq 'm4') {
			$mappings{     'gce.compute.cpu.m4'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.m4.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.m4.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.m4.spot'} = $cpu;
			$mappings{     'gce.compute.ram.m4'}      = $ram;
			$mappings_1y{  'gce.compute.ram.m4.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.m4.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.m4.spot'} = $ram;
			# M3 machine types do not offer sustained use discounts.
		}
		# A2
		elsif ($type eq 'a2') {
			$mappings{     'gce.compute.cpu.a2'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.a2.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.a2.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.a2.spot'} = $cpu;
			$mappings{     'gce.compute.ram.a2'}      = $ram;
			$mappings_1y{  'gce.compute.ram.a2.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.a2.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.a2.spot'} = $ram;
			# NVIDIA's Ampere A100 40GB GPUs
			if ($a100) {
				$mappings{     'gce.compute.gpu.a100'}      = $a100;
				$mappings_1y{  'gce.compute.gpu.a100.1y'}   = $a100;
				$mappings_3y{  'gce.compute.gpu.a100.3y'}   = $a100;
				$mappings_spot{'gce.compute.gpu.a100.spot'} = $a100;
			}
			# NVIDIA's Ampere A100 80GB HBM2e GPUs
			if ($a100_80gb) {
				$mappings{     'gce.compute.gpu.a100.80gb'}      = $a100_80gb;
				$mappings_1y{  'gce.compute.gpu.a100.80gb.1y'}   = $a100_80gb;
				$mappings_3y{  'gce.compute.gpu.a100.80gb.3y'}   = $a100_80gb;
				$mappings_spot{'gce.compute.gpu.a100.80gb.spot'} = $a100_80gb;
			}
		}
		# A3
		elsif ($type eq 'a3') {
			$mappings{     'gce.compute.cpu.a3'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.a3.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.a3.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.a3.spot'} = $cpu;
			$mappings{     'gce.compute.ram.a3'}      = $ram;
			$mappings_1y{  'gce.compute.ram.a3.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.a3.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.a3.spot'} = $ram;
			# NVIDIA's H100 80GB GPUs
			if ($h100_80gb) {
				$mappings{     'gce.compute.gpu.h100.80gb'}      = $h100_80gb;
				$mappings_1y{  'gce.compute.gpu.h100.80gb.1y'}   = $h100_80gb;
				$mappings_3y{  'gce.compute.gpu.h100.80gb.3y'}   = $h100_80gb;
				$mappings_spot{'gce.compute.gpu.h100.80gb.spot'} = $h100_80gb;
			}
			# NVIDIA's H100 80GB Mega GPUs
			if ($h100_80gb_mega) {
				$mappings{     'gce.compute.gpu.h100.80gb.mega'}      = $h100_80gb_mega;
				$mappings_1y{  'gce.compute.gpu.h100.80gb.mega.1y'}   = $h100_80gb_mega;
				$mappings_3y{  'gce.compute.gpu.h100.80gb.mega.3y'}   = $h100_80gb_mega;
				$mappings_spot{'gce.compute.gpu.h100.80gb.mega.spot'} = $h100_80gb_mega;
			}
		}
		# G2
		elsif ($type eq 'g2') {
			$mappings{     'gce.compute.cpu.g2'}      = $cpu;
			$mappings_1y{  'gce.compute.cpu.g2.1y'}   = $cpu;
			$mappings_3y{  'gce.compute.cpu.g2.3y'}   = $cpu;
			$mappings_spot{'gce.compute.cpu.g2.spot'} = $cpu;
			$mappings{     'gce.compute.ram.g2'}      = $ram;
			$mappings_1y{  'gce.compute.ram.g2.1y'}   = $ram;
			$mappings_3y{  'gce.compute.ram.g2.3y'}   = $ram;
			$mappings_spot{'gce.compute.ram.g2.spot'} = $ram;
			# NVIDIA's L4 GPUs
			if ($l4) {
				$mappings{     'gce.compute.gpu.l4'}      = $l4;
				$mappings_1y{  'gce.compute.gpu.l4.1y'}   = $l4;
				$mappings_3y{  'gce.compute.gpu.l4.3y'}   = $l4;
				$mappings_spot{'gce.compute.gpu.l4.spot'} = $l4;
			}
		}
		# Unknown family
		else {
			die "ERROR: No mapping for machine family '$type'!"
		}

		# Add price for bundled local SSD (local-ssd)
		my $costs_local_ssd_month      = $gcp->{'compute'}->{'storage'}->{'local'}->{'cost'}->{$region}->{'month'}      * $local_ssd || 0;
		my $costs_local_ssd_month_1y   = $gcp->{'compute'}->{'storage'}->{'local'}->{'cost'}->{$region}->{'month_1y'}   * $local_ssd || 0;
		my $costs_local_ssd_month_3y   = $gcp->{'compute'}->{'storage'}->{'local'}->{'cost'}->{$region}->{'month_3y'}   * $local_ssd || 0;
		my $costs_local_ssd_month_spot = $gcp->{'compute'}->{'storage'}->{'local'}->{'cost'}->{$region}->{'month_spot'} * $local_ssd || 0;
		my $costs_local_ssd_hour       = $costs_local_ssd_month      / $hours_month || 0;
		my $costs_local_ssd_hour_spot  = $costs_local_ssd_month_spot / $hours_month || 0;

		my $costs = 0;
		print "Check GCE mappings:\n";
		foreach my $mapping (keys %mappings) {
			print "MAPPING: '$mapping' in region '$region'\n";
			my $value = $mappings{$mapping} || '0';
			$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
			my $found = 0;
			while ($sth->fetch) {
				# asia-northeast1
				# Skip SKU for 'Memory-optimized Instance Ram running in Japan', use Tokyo
				next if ($sku_id eq '757F-6F9E-CCEC');
				# Skip SKU for 'Memory-optimized Instance Core running in Japan', use Tokyo
				next if ($sku_id eq '255E-0C41-3813');
				# asia-southeast1
				# Skip cheaper SKU for 'Memory-optimized Instance Ram running in Singapore'
				next if ($sku_id eq '71A5-A7E8-C37C');
				# Skip cheaper SKU for 'Memory-optimized Instance Core running in Singapore'
				next if ($sku_id eq 'B428-ABC6-FFED');

				if (&check_region($region, $regions)) {
					&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($found) {
						# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
						next if ($sku_description =~ /Virginia/);
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
					} else {
						$found = 1;
						$costs += &calc_cost($value, $units, $nanos); # SUM
						&add_gcp_compute_instance_details($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
					}
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: GCE '$mapping' not found in region '$region'!\n";
				$mapping_not_found = 1;
			}
		}
		my $upgrade_costs = 0;
		print "Check GCE upgrade mappings:\n";
		foreach my $mapping (keys %mapping_upgrades) {
			print "Upgrade mapping: '$mapping'\n";
			my $value = $mapping_upgrades{$mapping} || '0';
			$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
			my $found = 0;
			while ($sth->fetch) {
				# asia-northeast1
				# Skip SKU for 'Memory Optimized Upgrade Premium for Memory-optimized Instance Ram running in Japan', use Tokyo
				next if ($sku_id eq '68D5-29AA-798E');
				# Skip SKU for 'Memory Optimized Upgrade Premium for Memory-optimized Instance Core running in Japan', use Tokyo
				next if ($sku_id eq '9398-9081-75AC');
				# asia-southeast1
				# Skip cheaper SKU for 'Memory Optimized Upgrade Premium for Memory-optimized Instance Ram running in Singapore'
				next if ($sku_id eq '1F3C-AD92-C1E7');
				# Skip cheaper SKU for 'Memory Optimized Upgrade Premium for Memory-optimized Instance Core running in Singapore'
				next if ($sku_id eq '79D9-7C0D-4C27');

				if (&check_region($region, $regions)) {
					&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($found) {
						# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
						next if ($sku_description =~ /Virginia/);
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
					} else {
						$found = 1;
						$upgrade_costs += &calc_cost($value, $units, $nanos); # SUM
						&add_gcp_compute_instance_details(
							$machine,
							$region,
							$mapping,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: GCE upgrade '$mapping' not found in region '$region'!\n";
			}
		}
		# Calculate sustained use discount
		my $usage_levels = keys %sustained_use_discount;
		my $hours_discount = $hours_month/$usage_levels;
		# CPU, RAM, GPU
		my $costs_with_sustained_use_discount_100 = 0;
		foreach my $usage_level (keys %sustained_use_discount) {
			$costs_with_sustained_use_discount_100 += ($costs * $hours_discount) * $sustained_use_discount{$usage_level};
		}
		# Upgrades
		my $costs_with_sustained_use_discount_for_upgrade_100 = 0;
		foreach my $usage_level (keys %sustained_use_discount) {
			$costs_with_sustained_use_discount_for_upgrade_100 += ($upgrade_costs * $hours_discount) * $sustained_use_discount{$usage_level};
		}
		my $costs_month = $costs_with_sustained_use_discount_100+$costs_with_sustained_use_discount_for_upgrade_100+$costs_local_ssd_month;

		# Only save if _all_ mappings (CPU, RAM, GPU) in the region have been found
		if (!$mapping_not_found) {
			&add_gcp_compute_instance_cost('hour', $machine, $region, $costs+$upgrade_costs+$costs_local_ssd_hour);
			&add_gcp_compute_instance_cost('month', $machine, $region, $costs_month);
		}

		my $costs_1y = 0;
		print "Check GCE 1 year commitment mappings:\n";
		foreach my $mapping (keys %mappings_1y) {
			print "1Y Mapping: '$mapping'\n";
			my $value = $mappings_1y{$mapping} || '0';
			$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
			my $found = 0;
			while ($sth->fetch) {
				# asia-northeast1
				# Skip SKU for 'Commitment v1: Memory-optimized Ram in Japan for 1 Year', use Tokyo
				next if ($sku_id eq '71DA-B269-E14A');
				# Skip SKU for 'Commitment v1: Memory-optimized Cpu in Japan for 1 Year', use Tokyo
				next if ($sku_id eq 'A412-F795-8DEA');
				# asia-southeast1
				# Skip cheaper SKU for 'Commitment v1: Memory-optimized Ram in Singapore for 1 Year'
				next if ($sku_id eq '833D-8EA6-D22E');
				# Skip cheaper SKU for 'Commitment v1: Memory-optimized Cpu in Singapore for 1 Year'
				next if ($sku_id eq '1A15-7952-674A');

				if (&check_region($region, $regions)) {
					&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($found) {
						# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
						next if ($sku_description =~ /Virginia/);
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
					} else {
						$found = 1;
						$costs_1y += &calc_cost($value, $units, $nanos); # SUM
						&add_gcp_compute_instance_details(
							$machine,
							$region,
							$mapping,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: GCE 1Y CUD '$mapping' not found in region '$region'!\n";
				$cud_1y_mapping_not_found = 1;
			}
		}
		my $costs_month_1y = ($costs_1y*$hours_month) + $costs_with_sustained_use_discount_for_upgrade_100 + $costs_local_ssd_month_1y;
		# 2022-10-18:
		# For committed use discounts pricing on the A2 ultra machine series, connect with your sales account team.
		if ($machine =~ m/a2-ultragpu/) {
			print "INFO: No public committed use discounts for A2 ultra machine series. Reset calculated price.";
			$cud_1y_mapping_not_found = 1;
		}
		# No price for commitment found (i.e. NANOS = 0), use price per month (with SUD)
		if ($costs_month_1y <= 0.0001) {
			if ($machine ne 'g1-small' && $machine ne 'f1-micro') {
				warn "WARNING: 1Y CUD price is '$costs_month_1y'. Price per month used '$costs_month' for machine '$machine' in region '$region'!\n";
			}
			$costs_month_1y = $costs_month;
		}

		# Only save if _all_ mappings (CPU, RAM, GPU) in the region have been found
		if (!$cud_1y_mapping_not_found) {
			&add_gcp_compute_instance_cost('month_1y', $machine, $region, $costs_month_1y);
		}

		my $costs_3y = 0;
		print "Check GCE 3 year commitment mappings:\n";
		foreach my $mapping (keys %mappings_3y) {
			print "3Y Mapping: '$mapping'\n";
			my $value = $mappings_3y{$mapping} || '0';
			$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
			my $found = 0;
			while ($sth->fetch) {
				# asia-northeast1
				# Skip SKU for 'Commitment v1: Memory-optimized Ram in Japan for 3 Year', use Tokyo
				next if ($sku_id eq 'F213-5808-5249');
				# Skip SKU for 'Commitment v1: Memory-optimized Cpu in Japan for 3 Year', use Tokyo
				next if ($sku_id eq 'CABB-9912-AD72');
				# asia-southeast1
				# Skip cheaper SKU for 'Commitment v1: Memory-optimized Ram in Singapore for 3 Year'
				next if ($sku_id eq 'B042-ACE5-8F95');
				# Skip cheaper SKU for 'Commitment v1: Memory-optimized Cpu in Singapore for 3 Year'
				next if ($sku_id eq '7BDA-424A-1067');

				if (&check_region($region, $regions)) {
					&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($found) {
						# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
						next if ($sku_description =~ /Virginia/);
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
					} else {
						$found = 1;
						$costs_3y += &calc_cost($value, $units, $nanos); # SUM
						&add_gcp_compute_instance_details(
							$machine,
							$region,
							$mapping,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: GCE 3Y CUD '$mapping' not found in region '$region'!\n";
				$cud_3y_mapping_not_found = 1;
			}
		}
		my $costs_month_3y = ($costs_3y*$hours_month) + $costs_with_sustained_use_discount_for_upgrade_100 + $costs_local_ssd_month_3y;
		# 2022-10-18:
		# For committed use discounts pricing on the A2 ultra machine series, connect with your sales account team.
		if ($machine =~ m/a2-ultragpu/) {
			print "INFO: No public committed use discounts for A2 ultra machine series. Reset calculated price.";
			$cud_3y_mapping_not_found = 1;
		}
		# No price for commitment found, use price per month (with CUD)
		if ($costs_month_3y <= 0.0001) {
			if ($machine ne 'g1-small' && $machine ne 'f1-micro') {
				warn "WARNING: 3Y CUD price is '$costs_month_1y'. Price 1Y CUD used '$costs_month_1y' for machine '$machine' in region '$region'!\n";
			}
			$costs_month_3y = $costs_month_1y;
		}

		# Only save if _all_ mappings (CPU, RAM, GPU) in the region have been found
		if (!$cud_3y_mapping_not_found) {
			&add_gcp_compute_instance_cost('month_3y', $machine, $region, $costs_month_3y);
		}

		# Spot VMs
		my $costs_spot = 0;
		print "Check GCE spot VM mappings:\n";
		foreach my $mapping (keys %mappings_spot) {
			print "Spot VM Mapping: '$mapping'\n";
			my $value = $mappings_spot{$mapping} || '0';
			$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
			my $found = 0;
			while ($sth->fetch) {
				# asia-northeast1
				# Skip SKU for 'Spot Preemptible Memory-optimized Instance Core running in Japan', use Tokyo
				next if ($sku_id eq '939D-7E43-244A');
				# Skip SKU for 'Spot Preemptible Memory-optimized Instance Ram running in Japan', use Tokyo
				next if ($sku_id eq '7CDE-C4C3-FE63');
				# asia-southeast1
				# Skip cheaper SKU for 'Spot Preemptible Memory-optimized Instance Core running in Singapore'
				next if ($sku_id eq 'D92B-7B2B-F4CB');
				# Skip duplicate SKU for 'Spot Preemptible Memory-optimized Instance Ram running in Singapore'
				next if ($sku_id eq '768B-2116-67EA');

				if (&check_region($region, $regions)) {
					&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
					# Check duplicate entries for mapping and region
					if ($found) {
						# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
						next if ($sku_description =~ /Virginia/);
						die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
					} else {
						$found = 1;
						$costs_spot += &calc_cost($value, $units, $nanos); # SUM
						&add_gcp_compute_instance_details(
							$machine,
							$region,
							$mapping,
							$sku_id,
							$value,
							$nanos,
							$units,
							$unit_description,
							$sku_description
						) if ($export_details);
					}
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: GCE spot VM '$mapping' not found in region '$region'!\n";
				$spot_mapping_not_found = 1;
			}
		}

		# Only save if _all_ mappings (CPU, RAM, GPU) in the region have been found
		if ($costs_spot > 0 && !$spot_mapping_not_found) {
			$costs_spot = $costs_spot+$costs_local_ssd_hour_spot;
			&add_gcp_compute_instance_cost('hour_spot',  $machine, $region, $costs_spot);
			&add_gcp_compute_instance_cost('month_spot', $machine, $region, $costs_spot*$hours_month);
		}
	}
}


###############################################################################
# LICENSES
###############################################################################

# &add_gcp_compute_license_cost($what, $machine, $os, $cost)
sub add_gcp_compute_license_cost {
	my ($what, $machine, $os, $cost) = @_;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{$what} = $cost;
}
# &add_gcp_compute_license_details($machine, $os, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_license_details {
	my ($machine, $os, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'license'}->{$machine}->{'cost'}->{$os}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Licenses");
foreach my $machine (keys %{ $gcp->{'compute'}->{'instance'} }) {
	# Type
	my $type = '';
	my @machine_name = split('-', $machine);
	$type = $machine_name[0];
	# Custom Type
	if ($gcp->{'compute'}->{'instance'}->{$machine}->{'type'}) {
		$type = $gcp->{'compute'}->{'instance'}->{$machine}->{'type'};
	}
	# License per vCPU
	my $cpu  = $gcp->{'compute'}->{'instance'}->{$machine}->{'cpu'} || '0';

	print "Machine: $machine\n";
	print "Type: $type\n";
	print "CPU: $cpu\n";

	# Mappings for "premium" operating systems
	# https://cloud.google.com/compute/all-pricing#premiumimages
	my @operating_systems = (
		'sles',
		'sles-sap',
		'rhel',
		'rhel-sap',
		'windows'
	);
	# SUSE Linux Enterprise Server 15
	# https://console.cloud.google.com/marketplace/product/suse-cloud/sles-15
	my $sles_mapping     = '';
	# SLES 15 for SAP
	# https://console.cloud.google.com/marketplace/product/suse-sap-cloud/sles-15-sap
	my $sles_sap_mapping = '';
	# Red Hat Enterprise Linux 9
	# https://console.cloud.google.com/marketplace/product/rhel-cloud/rhel-9
	my $rhel_mapping     = '';
	# RHEL for SAP with High Availability and Update Services
	# https://console.cloud.google.com/marketplace/product/rhel-sap-cloud/rhel-8-4-sap
	my $rhel_sap_mapping = '';
	# Windows Server 2019 Datacenter Edition
	# https://console.cloud.google.com/marketplace/product/windows-cloud/windows-server-2019
	my $windows_mapping  = '';

	# F1 Predefined
	if ($type eq 'f1') {
		$sles_mapping     = 'gce.os.sles.f1';
		$sles_sap_mapping = 'gce.os.sles.sap.f1';
		$rhel_mapping     = 'gce.os.rhel.cpu.1.8';
		$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.8';
		$windows_mapping  = 'gce.os.windows.f1';
	}
	# G1 Predefined
	elsif ($type eq 'g1') {
		$sles_mapping     = 'gce.os.sles.g1';
		$sles_sap_mapping = 'gce.os.sles.sap.g1';
		$rhel_mapping     = 'gce.os.rhel.cpu.1.8';
		$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.8';
		$windows_mapping  = 'gce.os.windows.g1';
	}
	# CPU
	else {
		# VM with 128 or more vCPU
		if ($cpu >= 128) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.6.n';
			$rhel_mapping     = 'gce.os.rhel.cpu.128.n';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.128.n';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 9 or more vCPU
		elsif ($cpu >= 9) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.6.n';
			$rhel_mapping     = 'gce.os.rhel.cpu.9.127';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.9.127';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 5 or more vCPU
		elsif ($cpu >= 5) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.6.n';
			$rhel_mapping     = 'gce.os.rhel.cpu.1.8';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.8';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 4 or more vCPU
		elsif ($cpu >= 4) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.4';
			$rhel_mapping     = 'gce.os.rhel.cpu.1.8';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.8';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 1 to 3 VCPU
		else {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.1.3';
			$rhel_mapping     = 'gce.os.rhel.cpu.1.8';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.8';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
	}

	# Operating systems
	foreach my $os (@operating_systems) {
		my $costs   = 0;
		my $value   = '1';
		my $mapping = '';
		my $region  = '%';
		if    ($os eq 'sles')     { $mapping = $sles_mapping; }
		elsif ($os eq 'sles-sap') { $mapping = $sles_sap_mapping; }
		elsif ($os eq 'rhel')     {
			$mapping = $rhel_mapping;
			$value   = $cpu; # license per vCPU (core/hour)
		}
		elsif ($os eq 'rhel-sap') {
			$mapping = $rhel_sap_mapping;
			$value   = $cpu; # license per vCPU (core/hour)
		}
		elsif ($os eq 'windows')  {
			$mapping = $windows_mapping;
			$value   = $cpu; # license per vCPU (core/hour)
		}
		else { die "ERROR: No mapping for OS '$os'!\n"; }

		print "MAPPING: '$mapping' in region '$region'\n";
		$sth->execute($mapping, $region); # Search SKU(s)
		if ($sth->fetch) {
			# do not check region
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('hour', $machine, $os, $cost);
			&add_gcp_compute_license_cost('month', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details(
				$machine,
				$os,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		} else {
			die "ERROR: '$mapping' not found in region '$region'!\n";
		}
		$sth->finish;
		print "Check 1 Year Commitment:\n";
		my $mapping_1y = "$mapping".'.1y';
		$sth->execute($mapping_1y, $region); # Search SKU(s)
		if ($sth->fetch) {
			# do not check region
			&mapping_found($mapping_1y, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('month_1y', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details(
				$machine,
				$os,
				$mapping_1y,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
		$sth->finish;
		print "Check 3 Year Commitment:\n";
		my $mapping_3y = "$mapping".'.3y';
		$sth->execute($mapping_3y, $region); # Search SKU(s)
		if ($sth->fetch) {
			# do not check region
			&mapping_found($mapping_3y, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('month_3y', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details(
				$machine,
				$os,
				$mapping_3y,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
		$sth->finish;
	}
}


###############################################################################
# NETWORK
###############################################################################

# &add_gcp_compute_ip_unused_cost($what, $region, $cost)
sub add_gcp_compute_ip_unused_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_ip_unused_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_ip_unused_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_ip_vm_cost($what, $region, $cost)
sub add_gcp_compute_ip_vm_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_ip_vm_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_ip_vm_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_vpn_tunnel_cost($what, $region, $cost)
sub add_gcp_compute_vpn_tunnel_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_vpn_tunnel_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_vpn_tunnel_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_nat_gateway_cost($what, $region, $cost)
sub add_gcp_compute_nat_gateway_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_nat_gateway_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_nat_gateway_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_nat_gateway_data_cost($what, $region, $cost)
sub add_gcp_compute_nat_gateway_data_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_nat_gateway_data_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_nat_gateway_data_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_egress_internet_add_cost($usage, $region, $cost)
sub add_gcp_compute_egress_internet_add_cost {
	my ($usage, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$usage}->{$region}->{'month'} = $cost;
}
# &add_gcp_compute_egress_internet_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_egress_internet_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_egress_internet_china_add_cost($usage, $region, $cost)
sub add_gcp_compute_egress_internet_china_add_cost {
	my ($usage, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$usage}->{$region}->{'month'} = $cost;
}
# &add_gcp_compute_egress_internet_china_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_egress_internet_china_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_egress_internet_australia_add_cost($usage, $region, $cost)
sub add_gcp_compute_egress_internet_australia_add_cost {
	my ($usage, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$usage}->{$region}->{'month'} = $cost;
}
# &add_gcp_compute_egress_internet_australia_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_egress_internet_australia_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}

&print_header("Network");
foreach my $region (@regions) {
	print "Network in region '$region'\n";
	my $value = 1; # per 1 GB or hour

	# Static external IP address (assigned but unused)
	#  https://cloud.google.com/vpc/network-pricing#ipaddress
	# Bulk price:
	# 0 = 0
	# 1 = 0,01
	my $mapping = 'gce.network.ip.external.unused';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	while ($sth->fetch) {
		if (&check_region($region, $regions)) {
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_ip_unused_cost('hour', $region, $cost);
			&add_gcp_compute_ip_unused_cost('month', $region, $cost*$hours_month);
			&add_gcp_compute_ip_unused_details(
				$region,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
	}
	$sth->finish;

	# Static and ephemeral IP addresses in use __on standard VM instances__
	# Store global price for each region
	$mapping = 'gce.network.ip.external';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, 'global'); # Search SKU(s)
	while ($sth->fetch) {
		&mapping_found($mapping, 'global', $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_ip_vm_cost('hour', $region, $cost);
		&add_gcp_compute_ip_vm_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_ip_vm_details(
			$region,
			$mapping,
			$sku_id,
			$value,
			$nanos,
			$units,
			$unit_description,
			$sku_description
		) if ($export_details);
	}
	$sth->finish;
	# No charge for static and ephemeral IP addresses attached to forwarding rules, used by
	# Cloud NAT, or used as a public IP for a
	# Cloud VPN tunnel.

	# VPN tunnel
	$mapping = 'gce.network.vpn.tunnel';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	while ($sth->fetch) {
		if (&check_region($region, $regions)) {
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_vpn_tunnel_cost('hour', $region, $cost);
			&add_gcp_compute_vpn_tunnel_cost('month', $region, $cost*$hours_month);
			&add_gcp_compute_vpn_tunnel_details(
				$region,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
	}
	$sth->finish;

	# NAT gateway
	$mapping = 'gce.network.nat.gateway';
	print "MAPPING: '$mapping' in region '$region'\n";
	# Store global price for each region
	$sth->execute($mapping, 'global'); # Search SKU(s)
	while ($sth->fetch) {
		&mapping_found($mapping, 'global', $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		# The per-hour rate is capped at 32 VM instances.
		# Gateways that are serving instances beyond the maximum number are charged at the maximum per-hour rate.
		$cost = $cost * 32; # max price for more than 32 VM instances (always $0.044)
		&add_gcp_compute_nat_gateway_cost('hour', $region, $cost);
		&add_gcp_compute_nat_gateway_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_nat_gateway_details(
			$region,
			$mapping,
			$sku_id,
			$value,
			$nanos,
			$units,
			$unit_description,
			$sku_description
		) if ($export_details);
	}
	$sth->finish;

	# NAT traffic
	# Ingress __and__ egress data that is processed by the gateway
	$mapping = 'gce.network.nat.gateway.data';
	print "MAPPING: '$mapping' in region '$region'\n";
	# Store global price for each region
	$sth->execute($mapping, 'global'); # Search SKU(s)
	while ($sth->fetch) {
		&mapping_found($mapping, 'global', $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_nat_gateway_data_cost('month', $region, $cost);
		&add_gcp_compute_nat_gateway_data_details(
			$region,
			$mapping,
			$sku_id,
			$value,
			$nanos,
			$units,
			$unit_description,
			$sku_description
		) if ($export_details);
	}
	$sth->finish;

	# Internet egress rates
	#  https://cloud.google.com/vpc/network-pricing#vpc-pricing
	# Network (Egress) Worldwide Destinations (excluding China & Australia, but including Hong Kong)
	$mapping = 'gce.network.internet.egress';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	while ($sth->fetch) {
		if (&check_region($region, $regions)) {
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			# Bulk price:
			# 0 - 1   TB
			# 1 - 10  TB
			#     10+ TB
			my @bulk_nanos = split(',', $nanos);
			my @bulk_units = split(',', $units);
			# last price
			my $cost_10n  = &calc_cost($value, $bulk_units[-1], $bulk_nanos[-1]);
			my $cost_1_10 = $cost_10n;
			my $cost_0_1  = $cost_10n;
			# overwrite
			$cost_1_10 = &calc_cost($value, $bulk_units[-2], $bulk_nanos[-2]) if $bulk_nanos[-2];
			$cost_0_1  = &calc_cost($value, $bulk_units[-3], $bulk_nanos[-3]) if $bulk_nanos[-3];

			&add_gcp_compute_egress_internet_add_cost('0-1', $region, $cost_0_1);
			&add_gcp_compute_egress_internet_add_cost('1-10', $region, $cost_1_10);
			&add_gcp_compute_egress_internet_add_cost('10n', $region, $cost_10n);
			&add_gcp_compute_egress_internet_add_details(
				$region,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
	}
	$sth->finish;

	# Network (Egress) China Destinations (excluding Hong Kong)
	$mapping = 'gce.network.internet.egress.china';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	while ($sth->fetch) {
		if (&check_region($region, $regions)) {
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my @bulk_nanos = split(',', $nanos);
			my @bulk_units = split(',', $units);
			# last price
			my $cost_10n  = &calc_cost($value, $bulk_units[-1], $bulk_nanos[-1]);
			my $cost_1_10 = $cost_10n;
			my $cost_0_1  = $cost_10n;
			# overwrite
			$cost_1_10 = &calc_cost($value, $bulk_units[-2], $bulk_nanos[-2]) if $bulk_nanos[-2];
			$cost_0_1  = &calc_cost($value, $bulk_units[-3], $bulk_nanos[-3]) if $bulk_nanos[-3];

			&add_gcp_compute_egress_internet_china_add_cost('0-1', $region, $cost_0_1);
			&add_gcp_compute_egress_internet_china_add_cost('1-10', $region, $cost_1_10);
			&add_gcp_compute_egress_internet_china_add_cost('10n', $region, $cost_10n);
			&add_gcp_compute_egress_internet_china_add_details(
				$region,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
	}
	$sth->finish;

	# Network (Egress) Australia Destinations
	$mapping = 'gce.network.internet.egress.australia';
	print "MAPPING: '$mapping' in region '$region'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	while ($sth->fetch) {
		if (&check_region($region, $regions)) {
			&mapping_found($mapping, $region, $regions, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			# Bulk price:
			# 0 - 1   TB
			# 1 - 10  TB
			#     10+ TB
			my @bulk_nanos = split(',', $nanos);
			my @bulk_units = split(',', $units);
			# last price
			my $cost_10n  = &calc_cost($value, $bulk_units[-1], $bulk_nanos[-1]);
			my $cost_1_10 = $cost_10n;
			my $cost_0_1  = $cost_10n;
			# overwrite
			$cost_1_10 = &calc_cost($value, $bulk_units[-2], $bulk_nanos[-2]) if $bulk_nanos[-2];
			$cost_0_1  = &calc_cost($value, $bulk_units[-3], $bulk_nanos[-3]) if $bulk_nanos[-3];

			&add_gcp_compute_egress_internet_australia_add_cost('0-1', $region, $cost_0_1);
			&add_gcp_compute_egress_internet_australia_add_cost('1-10', $region, $cost_1_10);
			&add_gcp_compute_egress_internet_australia_add_cost('10n', $region, $cost_10n);
			&add_gcp_compute_egress_internet_australia_add_details(
				$region,
				$mapping,
				$sku_id,
				$value,
				$nanos,
				$units,
				$unit_description,
				$sku_description
			) if ($export_details);
		}
	}
	$sth->finish;
}

# Add copyright information to YAML pricing export
$gcp->{'about'}->{'copyright'} = qq ~
Copyright 2022-2025 Nils Knieling. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
~;
$gcp->{'about'}->{'generated'} = gmtime();
$gcp->{'about'}->{'timestamp'} = time();
$gcp->{'about'}->{'url'}       = 'https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator';

# Export YAML with costs
my $yaml = Dump($gcp);
print $fh $yaml;
close $fh;

print "DONE\n";

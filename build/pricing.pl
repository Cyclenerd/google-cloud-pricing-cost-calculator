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
# Generate the YAML file with the Google Cloud Platform pricing information
#

BEGIN {
	$VERSION = "2.0.0";
}

use strict;
use DBI;
use YAML::XS qw(LoadFile Dump);
use App::Options (
	option => {
		sku => {
			required    => 1,
			default     => 'skus.csv',
			type        => '/^[a-z0-9_]+\.csv$/',
			description => "CSV file with SKUs and mapping information (read)"
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
# SKUS
###############################################################################

# Open CSV file with SKU information for import (skus.csv)
my $csv_skus = $App::options{sku};
if (-r "$csv_skus") { # write
	$csv_skus =~ s/\.csv$//;
} else {
	die "ERROR: Cannot read CSV file '$csv_skus' with SKUs!\n";
}

# Copy SKUs with mapping from CSV to SQLite in-memory database
my $csv = DBI->connect("dbi:CSV:", undef, undef, {
	f_ext        => ".csv/r",
	csv_sep_char => ";",
	csv_class    => "Text::CSV_XS",
	RaiseError   => 1,
}) or die "ERROR: Cannot connect to CSV $DBI::errstr\n";

my $dbname = ':memory:'; # https://sqlite.org/inmemorydb.html
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","") or die "ERROR: Cannot connect to in-memory SQLite database $DBI::errstr\n";
$dbh->do("DROP TABLE IF EXISTS skus");
my $create_table = qq ~
	CREATE TABLE skus(
		ID               INTEGER,
		MAPPING          TEXT,
		REGIONS          TEXT,
		NANOS            TEXT,
		UNITS            TEXT,
		UNIT_DESCRIPTION TEXT,
		SKU_ID           TEXT,
		SKU_DESCRIPTION  TEXT,
		PRIMARY KEY('ID' AUTOINCREMENT)
	)
~;
$dbh->do($create_table);
# Copy only necessary data
my $select_csv = $csv->prepare("SELECT MAPPING, REGIONS, NANOS, UNITS, UNIT_DESCRIPTION, SKU_ID, SKU_DESCRIPTION FROM $csv_skus");
$select_csv->execute;
$select_csv->bind_columns (\my ($mapping, $regions, $nanos, $units, $unit_description, $sku_id, $sku_description));
my @values = ();
while ($select_csv->fetch) {
	next if $mapping eq 'TODO'; # skip TODO mapping
	my $value = "('$mapping', '$regions', '$nanos', '$units', '$unit_description', '$sku_id', '$sku_description')";
	push(@values, $value);
}
# Insert data to SQLite database table
my $insert = "INSERT INTO skus (MAPPING, REGIONS, NANOS, UNITS, UNIT_DESCRIPTION, SKU_ID, SKU_DESCRIPTION) VALUES";
$insert .= join(",", @values);
$insert .= ";\n";
$dbh->do($insert) or die "ERROR: Cannot insert $DBI::errstr\n";


###############################################################################
# SEARCH MAPPING
###############################################################################

my $sth = $dbh->prepare ("SELECT NANOS, UNITS, UNIT_DESCRIPTION, SKU_ID, SKU_DESCRIPTION FROM skus WHERE MAPPING = ? AND REGIONS LIKE ?");
$sth->bind_columns (\my ($nanos, $units, $unit_description, $sku_id, $sku_description));

# &mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description)
sub mapping_found {
	my ($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description) = @_;
	print "» mapping : $mapping, region = $region, value = $value, nanos = $nanos, units = $units, sku_id = $sku_id, unit_description = $unit_description, sku_description = $sku_description\n";
}
# &calc_cost($value, $units, $nanos)
sub calc_cost {
	my ($value, $units, $nanos) = @_;
	if ($nanos =~ /\,/) {
		my @bulk_nanos = split(',', $nanos);
		print "INFO: Bulk nanos!\n";
		foreach my $i (@bulk_nanos) {
			print "* $i\n";
		}
		$nanos = $bulk_nanos[-1]; # last
	}
	if ($units =~ /\,/) {
		my @bulk_units = split(',', $units);
		print "INFO: Bulk units!\n";
		foreach my $i (@bulk_units) {
			print "* $i\n";
		}
		$units = $bulk_units[-1]; # last
	}
	my $cost = $value * ( $units+($nanos*0.000000001) );
	print "OK: cost = $cost, value = $value, units = $units, nanos = $nanos\n";
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
print "Monitoring:";
foreach my $region (@regions) {
	my $value = 1; # per 1 mebibyte not GB
	# Monitoring data
	#  https://cloud.google.com/monitoring#pricing
	my $mapping = 'monitoring.data';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, 'global'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, 'global', $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
		&add_gcp_monitoring_data_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
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
print "Bucket storage:\n";
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
	else                                { die "ERROR: No mapping for storage bucket '$bucket'!\n"; }
	foreach my $region (@bucket_regions) {
		print "Bucket: $bucket\n";
		print "Mapping: '$mapping'\n";
		$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
		my $found = 0;
		while ($sth->fetch) {
			&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			# Check duplicate entries for mapping and region
			if ($found) {
				die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n"
			} else {
				$found = 1;
				my $cost = &calc_cost($value, $units, $nanos);
				&add_gcp_storage_bucket_cost('month', $bucket, $region, $cost);
				&add_gcp_storage_bucket_details($bucket, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
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
print "Disk storage:\n";
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
		# Regional standard PD
		elsif ($disk eq 'hdd-replicated')      { $mapping = 'gce.storage.hdd.replicated'; }
		# Regional SSD PD
		elsif ($disk eq 'ssd-replicated')      { $mapping = 'gce.storage.ssd.replicated'; }
		# Regional balanced PD
		elsif ($disk eq 'balanced-replicated') { $mapping = 'gce.storage.ssd.balanced.replicated'; }
		# Snapshot
		elsif ($disk eq 'snapshot')            { $mapping = 'gce.storage.snapshot'; }
		# Unknown storage type
		else                                   { die "ERROR: No mapping for disk '$disk'!\n"; }
		print "Mapping: '$mapping'\n";
		$sth->execute("$mapping", '%'."$region".'%'); # Search SKU(s)
		my $found = 0;
		while ($sth->fetch) {
			&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
				&add_gcp_compute_storage_details($disk, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
			}
		}
		$sth->finish;
		if ($found) {
			print "Check 1 Year Commitment:\n";
			my $commitment_1y_found = 0;
			my $mapping_1y = "$mapping".'.1y';
			$sth->execute($mapping_1y, '%'."$region".'%'); # Search SKU(s)
			while ($sth->fetch) {
				&mapping_found($mapping_1y, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($commitment_1y_found) {
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping_1y' in region '$region'!\n"
				} else {
					$commitment_1y_found = 1;
					my $cost = &calc_cost($value, $units, $nanos);
					&add_gcp_compute_storage_cost('month_1y', $disk, $region, $cost);
					&add_gcp_compute_storage_details($disk, $region, $mapping_1y, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
				}
			}
			$sth->finish;
			print "Check 3 Year Commitment:\n";
			my $commitment_3y_found = 0;
			my $mapping_3y = "$mapping".'.3y';
			$sth->execute($mapping_3y, '%'."$region".'%'); # Search SKU(s)
			while ($sth->fetch) {
				&mapping_found($mapping_3y, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($commitment_3y_found) {
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping_3y' in region '$region'!\n"
				} else {
					$commitment_3y_found = 1;
					my $cost = &calc_cost($value, $units, $nanos);
					&add_gcp_compute_storage_cost('month_3y', $disk, $region, $cost);
					&add_gcp_compute_storage_details($disk, $region, $mapping_3y, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
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
print "Instances:\n";
foreach my $region (@regions) {
	foreach my $machine (keys %{ $gcp->{'compute'}->{'instance'} }) {
		# CPU and RAM
		my $type = $gcp->{'compute'}->{'instance'}->{$machine}->{'type'} || '';
		my $cpu  = $gcp->{'compute'}->{'instance'}->{$machine}->{'cpu'}  || '0';
		my $ram  = $gcp->{'compute'}->{'instance'}->{$machine}->{'ram'}  || '0';
		my $a100 = $gcp->{'compute'}->{'instance'}->{$machine}->{'a100'} || '0';

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
		# Mapping for upgrades without commitments like M2 upgrade but with sustained use discount
		my %mapping_upgrades;

		# E2 Predefined
		if ($type eq 'e2') {
			$mappings{   'gce.compute.cpu.e2'}    = $cpu;
			$mappings_1y{'gce.compute.cpu.e2.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.e2.3y'} = $cpu;
			$mappings{   'gce.compute.ram.e2'}    = $ram;
			$mappings_1y{'gce.compute.ram.e2.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.e2.3y'} = $ram;
		}
		# N2 Predefined
		elsif ($type eq 'n2') {
			$mappings{   'gce.compute.cpu.n2'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.n2.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.n2.3y'} = $cpu;
			$mappings{   'gce.compute.ram.n2'   } = $ram;
			$mappings_1y{'gce.compute.ram.n2.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.n2.3y'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N2D Predefined
		elsif ($type eq 'n2d') {
			$mappings{   'gce.compute.cpu.n2d'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.n2d.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.n2d.3y'} = $cpu;
			$mappings{   'gce.compute.ram.n2d'   } = $ram;
			$mappings_1y{'gce.compute.ram.n2d.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.n2d.3y'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# T2D Predefined
		elsif ($type eq 't2d') {
			$mappings{   'gce.compute.cpu.t2d'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.t2d.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.t2d.3y'} = $cpu;
			$mappings{   'gce.compute.ram.t2d'   } = $ram;
			$mappings_1y{'gce.compute.ram.t2d.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.t2d.3y'} = $ram;
		}
		# F1 Predefined
		elsif ($type eq 'f1') {
			$mappings{'gce.compute.cpu.f1'} = $cpu;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
			# RAM incl.
		}
		# G1 Predefined
		elsif ($type eq 'g1') {
			$mappings{'gce.compute.cpu.g1'} = $cpu;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
			# RAM incl.
		}
		# N1 Predefined
		elsif ($type eq 'n1') {
			$mappings{   'gce.compute.cpu.n1'} = $cpu; # N1!
			$mappings_1y{'gce.compute.cpu.1y'} = $cpu; # without N1
			$mappings_3y{'gce.compute.cpu.3y'} = $cpu;
			$mappings{   'gce.compute.ram.n1'} = $ram;
			$mappings_1y{'gce.compute.ram.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.3y'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# N1 Custom
		elsif ($type eq 'n1-custom') {
			$mappings{   'gce.compute.cpu.custom'} = $cpu;
			$mappings_1y{'gce.compute.cpu.1y'    } = $cpu;
			$mappings_3y{'gce.compute.cpu.3y'    } = $cpu;
			$mappings{   'gce.compute.ram.custom'} = $ram;
			$mappings_1y{'gce.compute.ram.1y'    } = $ram;
			$mappings_3y{'gce.compute.ram.3y'    } = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# N2 Custom
		elsif ($type eq 'n2-custom') {
			$mappings{   'gce.compute.cpu.n2.custom'} = $cpu;
			$mappings_1y{'gce.compute.cpu.n2.1y'    } = $cpu;
			$mappings_3y{'gce.compute.cpu.n2.3y'    } = $cpu;
			$mappings{   'gce.compute.ram.n2.custom'} = $ram;
			$mappings_1y{'gce.compute.ram.n2.1y'    } = $ram;
			$mappings_3y{'gce.compute.ram.n2.3y'    } = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# N2D Custom
		elsif ($type eq 'n2d-custom') {
			$mappings{   'gce.compute.cpu.n2d.custom'} = $cpu;
			$mappings_1y{'gce.compute.cpu.n2d.1y'    } = $cpu;
			$mappings_3y{'gce.compute.cpu.n2d.3y'    } = $cpu;
			$mappings{   'gce.compute.ram.n2d.custom'} = $ram;
			$mappings_1y{'gce.compute.ram.n2d.1y'    } = $ram;
			$mappings_3y{'gce.compute.ram.n2d.3y'    } = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# C2
		elsif ($type eq 'c2') {
			$mappings{   'gce.compute.cpu.compute.optimized'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.compute.optimized.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.compute.optimized.3y'} = $cpu;
			$mappings{   'gce.compute.ram.compute.optimized'   } = $ram;
			$mappings_1y{'gce.compute.ram.compute.optimized.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.compute.optimized.3y'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n2 if $add_sud;
		}
		# C2D Predefined
		elsif ($type eq 'c2d') {
			$mappings{   'gce.compute.cpu.c2d'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.c2d.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.c2d.3y'} = $cpu;
			$mappings{   'gce.compute.ram.c2d'   } = $ram;
			$mappings_1y{'gce.compute.ram.c2d.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.c2d.3y'} = $ram;
		}
		# M1
		elsif ($type eq 'm1') {
			$mappings{   'gce.compute.cpu.memory.optimized'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.memory.optimized.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.memory.optimized.3y'} = $cpu;
			$mappings{   'gce.compute.ram.memory.optimized'   } = $ram;
			$mappings_1y{'gce.compute.ram.memory.optimized.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.memory.optimized.3y'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# M2
		elsif ($type eq 'm2') {
			$mappings{   'gce.compute.cpu.memory.optimized'   } = $cpu;
			$mappings_1y{'gce.compute.cpu.memory.optimized.1y'} = $cpu;
			$mappings_3y{'gce.compute.cpu.memory.optimized.3y'} = $cpu;
			$mappings{   'gce.compute.ram.memory.optimized'   } = $ram;
			$mappings_1y{'gce.compute.ram.memory.optimized.1y'} = $ram;
			$mappings_3y{'gce.compute.ram.memory.optimized.3y'} = $ram;
			# M2 upgrade
			$mapping_upgrades{'gce.compute.cpu.memory.optimized.premium.upgrade'} = $cpu;
			$mapping_upgrades{'gce.compute.ram.memory.optimized.premium.upgrade'} = $ram;
			%sustained_use_discount = %sustained_use_discount_n1 if $add_sud;
		}
		# A2
		elsif ($type eq 'a2') {
			$mappings{   'gce.compute.cpu.a2'     } = $cpu;
			$mappings_1y{'gce.compute.cpu.a2.1y'  } = $cpu;
			$mappings_3y{'gce.compute.cpu.a2.3y'  } = $cpu;
			$mappings{   'gce.compute.ram.a2'     } = $ram;
			$mappings_1y{'gce.compute.ram.a2.1y'  } = $ram;
			$mappings_3y{'gce.compute.ram.a2.3y'  } = $ram;
			$mappings{   'gce.compute.gpu.a100'   } = $a100;
			$mappings_1y{'gce.compute.gpu.a100.1y'} = $a100;
			$mappings_3y{'gce.compute.gpu.a100.3y'} = $a100;
		}
		# Unknown family
		else {
			die "ERROR: No mapping for machine family '$type'!"
		}

		my $costs = 0;
		foreach my $mapping (keys %mappings) {
			print "Mapping: '$mapping'\n";
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

				&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
			$sth->finish;
			unless ($found) {
				warn "WARNING: '$mapping' not found in region '$region'!\n";
			}
		}
		my $upgrade_costs = 0;
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

				&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($found) {
					# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
					next if ($sku_description =~ /Virginia/);
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
				} else {
					$found = 1;
					$upgrade_costs += &calc_cost($value, $units, $nanos); # SUM
					&add_gcp_compute_instance_details($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: '$mapping' not found in region '$region'!\n";
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

		my $costs_month = $costs_with_sustained_use_discount_100+$costs_with_sustained_use_discount_for_upgrade_100;
		&add_gcp_compute_instance_cost('hour', $machine, $region, $costs+$upgrade_costs);
		&add_gcp_compute_instance_cost('month', $machine, $region, $costs_month);

		my $costs_1y = 0;
		print "Check 1 Year Commitment:\n";
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

				&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($found) {
					# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
					next if ($sku_description =~ /Virginia/);
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
				} else {
					$found = 1;
					$costs_1y += &calc_cost($value, $units, $nanos); # SUM
					&add_gcp_compute_instance_details($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: '$mapping' not found in region '$region'!\n";
			}
		}
		my $costs_month_1y = $costs_1y*$hours_month;
		# No price for commitment found (i.e. NANOS = 0), use price per month (with SUD)
		if ($costs_month_1y <= 0.0001) {
			if ($machine ne 'g1-small' && $machine ne 'f1-micro') {
				warn "WARNING: 1Y CUD price is '$costs_month_1y'. Price per month used '$costs_month' for machine '$machine' in region '$region'!\n";
			}
			$costs_month_1y = $costs_month;
		}
		&add_gcp_compute_instance_cost('month_1y', $machine, $region, $costs_month_1y+$costs_with_sustained_use_discount_for_upgrade_100);

		my $costs_3y = 0;
		print "Check 3 Year Commitment:\n";
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

				&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
				# Check duplicate entries for mapping and region
				if ($found) {
					# Skip duplicate SKUs for 'Virginia' and 'Northern Virginia' (both us-east4)
					next if ($sku_description =~ /Virginia/);
					die "ERROR: Duplicate entry. Already found price for this mapping '$mapping' in region '$region'!\n";
				} else {
					$found = 1;
					$costs_3y += &calc_cost($value, $units, $nanos); # SUM
					&add_gcp_compute_instance_details($machine, $region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
				}
			}
			$sth->finish;
			unless ($found) {
				warn "WARNING: '$mapping' not found in region '$region'!\n";
			}
		}
		my $costs_month_3y = $costs_3y*$hours_month;
		# No price for commitment found, use price per month (with CUD)
		if ($costs_month_3y <= 0.0001) {
			if ($machine ne 'g1-small' && $machine ne 'f1-micro') {
				warn "WARNING: 3Y CUD price is '$costs_month_1y'. Price 1Y CUD used '$costs_month_1y' for machine '$machine' in region '$region'!\n";
			}
			$costs_month_3y = $costs_month_1y;
		}
		&add_gcp_compute_instance_cost('month_3y', $machine, $region, $costs_month_3y+$costs_with_sustained_use_discount_for_upgrade_100);
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
print "Licenses:\n";
foreach my $machine (keys %{ $gcp->{'compute'}->{'instance'} }) {
	# License per vCPU
	my $type = $gcp->{'compute'}->{'instance'}->{$machine}->{'type'} || '';
	my $cpu  = $gcp->{'compute'}->{'instance'}->{$machine}->{'cpu'}  || '0';

	print "Machine: $machine\n";
	print "Type: $type\n";
	print "CPU: $cpu\n";

	# Mappings for "premium" operating systems
	my @operating_systems = ('sles', 'sles-sap', 'rhel', 'rhel-sap', 'windows');
	# SUSE Linux Enterprise Server 15
	# https://console.cloud.google.com/marketplace/product/suse-cloud/sles-15
	my $sles_mapping     = '';
	# SLES 15 for SAP
	# https://console.cloud.google.com/marketplace/product/suse-sap-cloud/sles-15-sap
	my $sles_sap_mapping = '';
	# Red Hat Enterprise Linux 8
	# https://console.cloud.google.com/marketplace/product/rhel-cloud/rhel-8
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
		$rhel_mapping     = 'gce.os.rhel.f1';
		$rhel_sap_mapping = 'gce.os.rhel.sap.f1';
		$windows_mapping  = 'gce.os.windows.f1';
	}
	# G1 Predefined
	elsif ($type eq 'g1') {
		$sles_mapping     = 'gce.os.sles.g1';
		$sles_sap_mapping = 'gce.os.sles.sap.g1';
		$rhel_mapping     = 'gce.os.rhel.g1';
		$rhel_sap_mapping = 'gce.os.rhel.sap.g1';
		$windows_mapping  = 'gce.os.windows.g1';
	}
	# CPU
	else {
		# VM with 5 (6) or more VCPU
		if ($cpu >= 5) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.6.n';
			$rhel_mapping     = 'gce.os.rhel.cpu.6.n';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.6.n';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 4 VCPU
		elsif ($cpu >= 4) {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.4';
			$rhel_mapping     = 'gce.os.rhel.cpu.1.4';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.4';
			$windows_mapping  = 'gce.os.windows.cpu';
		}
		# VM with 1 to 3 VCPU
		else {
			$sles_mapping     = 'gce.os.sles.cpu';
			$sles_sap_mapping = 'gce.os.sles.sap.cpu.1.3';
			$rhel_mapping     = 'gce.os.rhel.cpu.1.4';
			$rhel_sap_mapping = 'gce.os.rhel.sap.cpu.1.4';
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
		elsif ($os eq 'rhel')     { $mapping = $rhel_mapping; }
		elsif ($os eq 'rhel-sap') { $mapping = $rhel_sap_mapping; }
		elsif ($os eq 'windows')  {
			$mapping = $windows_mapping;
			$value   = $cpu; # license per vCPU (core/hour)
		}
		else                      { die "ERROR: No mapping for OS '$os'!\n"; }

		print "Mapping: '$mapping'\n";
		$sth->execute($mapping, $region); # Search SKU(s)
		if ($sth->fetch) {
			&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('hour', $machine, $os, $cost);
			&add_gcp_compute_license_cost('month', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details($machine, $os, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
		} else {
			die "ERROR: '$mapping' not found in region '$region'!\n";
		}
		$sth->finish;
		print "Check 1 Year Commitment:\n";
		my $mapping_1y = "$mapping".'.1y';
		$sth->execute($mapping_1y, $region); # Search SKU(s)
		if ($sth->fetch) {
			&mapping_found($mapping_1y, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('month_1y', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details($machine, $os, $mapping_1y, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
		}
		$sth->finish;
		print "Check 3 Year Commitment:\n";
		my $mapping_3y = "$mapping".'.3y';
		$sth->execute($mapping_3y, $region); # Search SKU(s)
		if ($sth->fetch) {
			&mapping_found($mapping_3y, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
			my $cost = &calc_cost($value, $units, $nanos);
			&add_gcp_compute_license_cost('month_3y', $machine, $os, $cost*$hours_month);
			&add_gcp_compute_license_details($machine, $os, $mapping_3y, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
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
# &add_gcp_compute_lb_rule_cost($what, $region, $cost)
sub add_gcp_compute_lb_rule_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_lb_rule_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_lb_rule_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_lb_rule_add_cost($what, $region, $cost)
sub add_gcp_compute_lb_rule_add_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_lb_rule_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_lb_rule_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
}
# &add_gcp_compute_lb_data_add_cost($what, $region, $cost)
sub add_gcp_compute_lb_data_add_cost {
	my ($what, $region, $cost) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{$what} = $cost;
}
# &add_gcp_compute_lb_data_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description)
sub add_gcp_compute_lb_data_add_details {
	my ($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) = @_;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'sku'}   = $sku_id;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'value'} = $value;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'nanos'} = $nanos;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'units'} = $units;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'unit'} = $unit_description;
	$gcp->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'mapping'}->{$mapping}->{'description'} = $sku_description;
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
print "Network:";
foreach my $region (@regions) {
	my $value = 1; # per 1 GB or hour

	# Static external IP address (assigned but unused)
	#  https://cloud.google.com/vpc/network-pricing#ipaddress
	# Bulk price:
	# 0 = 0
	# 1 = 0,01
	my $mapping = 'gce.network.ip.external.unused';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_ip_unused_cost('hour', $region, $cost);
		&add_gcp_compute_ip_unused_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_ip_unused_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		die "ERROR: '$mapping' not found for region '$region'!\n";
	}
	$sth->finish;

	# Static and ephemeral IP addresses in use __on standard VM instances__
	# Store global price for each region
	$mapping = 'gce.network.ip.external';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, 'global'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, 'global', $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_ip_vm_cost('hour', $region, $cost);
		&add_gcp_compute_ip_vm_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_ip_vm_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		die "ERROR: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# No charge for static and ephemeral IP addresses attached to forwarding rules, used by
	# Cloud NAT, or used as a public IP for a
	# Cloud VPN tunnel.

	# VPN tunnel
	$mapping = 'gce.network.vpn.tunnel';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_vpn_tunnel_cost('hour', $region, $cost);
		&add_gcp_compute_vpn_tunnel_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_vpn_tunnel_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		# Not all regions have VPN
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;

	# NAT gateway
	$mapping = 'gce.network.nat.gateway';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		# The per-hour rate is capped at 32 VM instances.
		# Gateways that are serving instances beyond the maximum number are charged at the maximum per-hour rate.
		$cost = $cost * 32; # max price for more than 32 VM instances (always $0.044)
		&add_gcp_compute_nat_gateway_cost('hour', $region, $cost);
		&add_gcp_compute_nat_gateway_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_nat_gateway_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		# Not in all regions. I.e.: Not in asia-southeast2, northamerica-northeast1, northamerica-northeast2, us-west4
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# NAT traffic
	# Ingress __and__ egress data that is processed by the gateway
	$mapping = 'gce.network.nat.gateway.data';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_nat_gateway_data_cost('month', $region, $cost);
		&add_gcp_compute_nat_gateway_data_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;

	# Load Balancing: Forwarding Rule Minimum Service Charge
	$mapping = 'gce.network.lb.rule'; # first 5 rules, up to 5 forwarding rules for the price, 1 = same as for 5
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_lb_rule_cost('hour', $region, $cost);
		&add_gcp_compute_lb_rule_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_lb_rule_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# Load Balancing: Forwarding Rule Additional Service Charge
	$mapping = 'gce.network.lb.rule.add'; # each additional forwarding rule
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_lb_rule_add_cost('hour', $region, $cost);
		&add_gcp_compute_lb_rule_add_cost('month', $region, $cost*$hours_month);
		&add_gcp_compute_lb_rule_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# Load Balancing: Network Load Balancing: Data Processing Charge
	$mapping = 'gce.network.lb.data'; # Ingress data processed by load balancer
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
		my $cost = &calc_cost($value, $units, $nanos);
		&add_gcp_compute_lb_data_add_cost('month', $region, $cost);
		&add_gcp_compute_lb_data_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		warn "WARNING: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;

	# Internet egress rates
	#  https://cloud.google.com/vpc/network-pricing#vpc-pricing
	# Network (Egress) Worldwide Destinations (excluding China & Australia, but including Hong Kong)
	$mapping = 'gce.network.internet.egress';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
		&add_gcp_compute_egress_internet_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		die "ERROR: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# Network (Egress) China Destinations (excluding Hong Kong)
	$mapping = 'gce.network.internet.egress.china';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
		&add_gcp_compute_egress_internet_china_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		die "ERROR: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
	# Network (Egress) Australia Destinations
	$mapping = 'gce.network.internet.egress.australia';
	print "Mapping: '$mapping'\n";
	$sth->execute($mapping, '%'."$region".'%'); # Search SKU(s)
	if ($sth->fetch) {
		&mapping_found($mapping, $region, $value, $nanos, $units, $unit_description, $sku_id, $sku_description);
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
		&add_gcp_compute_egress_internet_australia_add_details($region, $mapping, $sku_id, $value, $nanos, $units, $unit_description, $sku_description) if ($export_details);
	} else {
		die "ERROR: '$mapping' not found in region '$region'!\n";
	}
	$sth->finish;
}

# Add copyright information to YAML pricing export
$gcp->{'about'}->{'copyright'} = qq ~
Copyright 2022 Nils Knieling. All Rights Reserved.

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
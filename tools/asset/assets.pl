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
# Create usage files from asset inventory
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
			description => "YAML file with bucket object size usage export (read)"
		}
	},
);
use Data::Dumper;

# Debug?
my $debug = $App::options{debug_options};

# Open asset file
my $asset_file  = $App::options{assets};
unless (-r "$asset_file") {
	die "ERROR: Cannot read YAML file '$asset_file' with GCP asset informations!\n";
}
my @inventory_assets  = LoadFile("$asset_file")  or die "ERROR: Cannot open YAML file '$asset_file' to read GCP asset informations!\n";
# Open bucket file
my $bucket_file = $App::options{buckets};
unless (-r "$bucket_file") {
	die "ERROR: Cannot read YAML file '$bucket_file' with bucket object size usage!\n";
}
my $bucket_data = LoadFile("$bucket_file") or die "ERROR: Cannot open YAML file '$bucket_file' to read bucket object size usage!\n";

# Config
my %supported_asset_types = (
	'bucket'   => 'true',
	'disk'     => 'true',
	'snapshot' => 'true',
	'vm'       => 'true',
);
my %icons = (
	'bucket'   => '🪣',
	'disk'     => '💾',
	'snapshot' => '📸',
	'vm'       => '🖥️',
);

my %projects;
my @resources;

# &asset(%inventory, @disks)
sub asset {
	my (%values) = @_;
	my $resource = $values{'resource'};
	my $name     = $values{'name'};
	my $project  = $values{'project'};

	print $icons{$resource} ." $resource : $name » ";
	foreach my $key (sort keys %values) {
		next if ($key eq 'name' || $key eq 'resource');
		my $value = $values{$key};
		print "$key = $value";
		print ", " unless $key eq (sort keys %values)[-1];
	}
	print "\n";
	$projects{$project} = $projects{$project}++;
	push(@resources, \%values)
}
foreach my $asset (@inventory_assets) {
	my %inventory;
	my $name = $asset->{'displayName'};
	$inventory{'name'} = $name;
	# compute.googleapis.com/Instance
	# compute.googleapis.com/Disk
	# compute.googleapis.com/Snapshot
	# compute.googleapis.com/VpnTunnel
	# storage.googleapis.com/Bucket
	my $asset_type = '';
	if ($asset->{'assetType'} =~ /\.com\/(\w+)/) {
		$asset_type = lc $1;
	}
	if ($asset_type eq 'instance') { $asset_type = 'vm'; } # rename
	next unless ($supported_asset_types{$asset_type}); # skip

	$inventory{'resource'} = $asset_type;
	my $project = '';
	if ($asset->{'parentFullResourceName'} =~ /projects\/([\d\w_-]+)/) {
		$project = lc $1;
	}
	$inventory{'project'} = $project;
	my $state = '';
	if ($asset->{'state'} =~ /(\w+)/) {
		$state = lc $1;
	}
	$inventory{'state'} = $state;

	my $versioned = $asset->{'versionedResources'}[0]; #v1
	my $version = $versioned->{'version'} || '';
	if ($version ne 'v1') {
		die "WARNING: Not version 1\n";
	}
	my $resource = $versioned->{'resource'} || '';
	
	if ($asset_type eq 'bucket') {
		# location: EUROPE-NORTH1
		# locationType: region
		# storageClass: STANDARD
		my $region = lc $resource->{'location'};
		my $class  = lc $resource->{'storageClass'};
		if ($region eq 'eur4' || $region eq 'asia1' || $region eq 'nam4') {
			$class .= '-dual';
		}
		if ($region eq 'eu') {
			$region = 'europe-multi'; # TODO: Add more multi regions
			$class .= '-multi';
		}
		# TODO: Add more dual regions
		$inventory{'class'} = $class;
		$inventory{'region'} = $region;
	}
	if ($asset_type eq 'disk') {
		# licenses:
		# - https://www.googleapis.com/compute/v1/projects/debian-cloud/global/licenses/debian-10-buster
		# sizeGb: '16'
		# type: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/diskTypes/pd-ssd
		# zone: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c
		# selfLink: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/disks/disk-boot-debian10
		my $license = '';
		if ($resource->{'licenses'}[0] =~ /licenses\/([\d\w-]+)/) {
			$license = $1;
		}
		if ($license =~ /windows/ && $license !~ /-byos/) {
			$license = 'windows';
		} elsif ($license =~ /sles/ && $license !~ /sap/ && $license !~ /-byos/) {
			$license = 'sles';
		} elsif ($license =~ /sles/ && $license =~ /sap/ && $license !~ /-byos/) {
			$license = 'sles-sap';
		} elsif ($license =~ /sles/ && $license !~ /sap/ && $license =~ /-byos/) {
			$license = 'sles-byos';
		} else {
			# TODO: Add more licenses
			$license = '';
		}
		my $type = '';
		if ($resource->{'type'} =~ /diskTypes\/([\d\w-]+)/) {
			$type = $1;
		}
		if ($type eq 'pd-ssd') {
			$type = 'ssd';
		} elsif ($type eq 'pd-standard') {
			$type = 'hdd';
		} elsif ($type eq 'pd-balanced') {
			$type = 'balanced';
		} else {
			# TODO: Add more types
			$type = 'UNKNOWN';
		}
		my $zone = '';
		if ($resource->{'zone'} =~ /zones\/([\d\w-]+)/) {
			$zone = $1;
		}
		my $data = $resource->{'sizeGb'} || '';
		my $self = $resource->{'selfLink'} || '';
		$inventory{'license'} = $license;
		$inventory{'type'}    = $type;
		$inventory{'zone'}    = $zone;
		$inventory{'data'}    = $data;
		$inventory{'self'}    = $self;
	}
	if ($asset_type eq 'snapshot') {
		# sourceDisk: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/disks/disk-boot-windows
		# storageBytes: '10558856448'
		# storageLocations:
		#   - eu
		my $region = lc $resource->{'storageLocations'}[0];
		if ($region eq 'eu') {
			$region = 'europe-multi';
		}
		# TODO: Add more multi regions
		my $source = $resource->{'sourceDisk'};
		my $data = $resource->{'storageBytes'};
		$inventory{'source'} = $source;
		$inventory{'data'} = $data;
		$inventory{'region'} = $region;
	}
	if ($asset_type eq 'vm') {
		# machineType: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/machineTypes/e2-micro
		# type: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/diskTypes/pd-ssd
		# zone: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c
		# disks:
		#  - autoDelete: true
		#    boot: true
		#    deviceName: disk-boot-debian2
		#    diskSizeGb: '32'
		#    source: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/zones/europe-north1-c/disks/disk-boot-debian2
		my $type = '';
		if ($resource->{'machineType'} =~ /machineTypes\/([\d\w-]+)/) {
			$type = $1;
		}
		my $zone = '';
		if ($resource->{'zone'} =~ /zones\/([\d\w-]+)/) {
			$zone = $1;
		}
		my @attached_disks;
		my $disks = $resource->{'disks'};
		foreach my $disk (@{$disks}) {
			push(@attached_disks, $disk->{'source'});
		}
		$inventory{'type'}  = $type;
		$inventory{'state'} = $state;
		$inventory{'zone'}  = $zone;
		$inventory{'disks'} = join(';', @attached_disks);
	}
	&asset(%inventory);
}

# Sum snapshot size
my %disk_snapshots;
foreach my $i (@resources) {
	if ($i->{'resource'} eq 'snapshot') {
		my $source = $i->{'source'};
		my $data = $i->{'data'}||'0';
		$disk_snapshots{$source} += $data;
	}
}

# Get location / region of snapshot
# Last region is always used. Multiple snapshot locations/regions are ignored.
my %disk_snapshot_region;
foreach my $i (@resources) {
	if ($i->{'resource'} eq 'snapshot') {
		my $source = $i->{'source'};
		my $region = $i->{'region'}||'';
		$disk_snapshot_region{$source} = $region;
	}
}

# Get attached disks
my %attached_disks;
foreach my $i (@resources) {
	if ($i->{'resource'} eq 'vm') {
		my @disks = split(';', $i->{'disks'});
		foreach my $source ( @disks) {
			$attached_disks{$source} = 'true';
		}
	}
}

# Create YAML usage files
foreach my $project (sort keys %projects) {
	my $file_name = "$project.yml";
	open my $fh, q{>}, "$file_name" or die "ERROR: Cannot open YAML file '$file_name' for export!\n";

	print $fh "project: $project\n";
	print $fh "\ninstances:\n";
	foreach my $i (@resources) {
		if ($i->{'project'} eq "$project") {
			if ($i->{'resource'} eq 'vm') {
				print $fh "  - name: ". $i->{'name'} ."\n";
				#print $fh "    project: ". $i->{'project'} ."\n";
				print $fh "    type: ". $i->{'type'} ."\n";
				print $fh "    terminated: true\n" if ($i->{'state'} eq 'terminated');
				print $fh "    disks:\n";
				my @disks = split(';', $i->{'disks'});
				my $os = '';
				foreach my $source (sort @disks) {
					foreach my $y (@resources) {
						if ($y->{'self'} eq $source) {
							my $snapshot_data = $disk_snapshots{$source}||'0';
							$snapshot_data    = sprintf("%.6f", $snapshot_data / 1073741824);
							my $snapshot_region = $disk_snapshot_region{$source}||'';
							if ($y->{'license'}) {
								$os = $y->{'license'};
							}
							print $fh "    - name: ". $y->{'name'} ."\n";
							print $fh "      type: ". $y->{'type'} ."\n";
							print $fh "      data: ". $y->{'data'} ."\n";
							if ($snapshot_data > 0) {
								print $fh "    - name: ". $y->{'name'} ."\n";
								print $fh "      type: snapshot\n";
								print $fh "      data: $snapshot_data\n";
								print $fh "      region: $snapshot_region\n";
							}
						}
					}
				}
				print $fh "    os: $os\n" if ($os);
			}
		}
	}

	# Discs that are not used by (attached to) any VM
	print $fh "\ndisks:\n";
	foreach my $i (@resources) {
		if ($i->{'project'} eq "$project") {
			if ($i->{'resource'} eq 'disk') {
				my $self = $i->{'self'};
				unless ($attached_disks{$self}) {
					print $fh "  - name: ". $i->{'name'} ."\n";
					#print $fh "    self: ". $i->{'self'} ."\n";
					print $fh "    type: ". $i->{'type'} ."\n";
					print $fh "    data: ". $i->{'data'} ."\n";
				}
			}
		}
	}

	print $fh "\nbuckets:\n";
	foreach my $i (@resources) {
		if ($i->{'project'} eq "$project") {
			if ($i->{'resource'} eq 'bucket') {
				my $self = $i->{'self'};
				unless ($attached_disks{$self}) {
					my $name = $i->{'name'};
					my $data = $bucket_data->{"$name"}||'0';
					print $fh "  - name: ".    $i->{'name'}   ."\n";
					print $fh "    class: ".   $i->{'class'}  ."\n";
					print $fh "    data: $data\n"; # TODO: Add data (gsutil)
					print $fh "    region: ".  $i->{'region'} ."\n";
				}
			}
		}
	}

	close fh;
}
#!/usr/bin/env perl

# Test machine types that are automatically attached a local SSD also have the size defined.

use strict;
use warnings;
use Test::More;
use YAML::XS qw(LoadFile);
use File::Basename qw(dirname);
use File::Spec;

# Get the path to build/gcp.yml
my $script_dir = dirname(__FILE__);
my $yaml_path = File::Spec->catfile($script_dir, '..', 'build', 'gcp.yml');

# Load the YAML file
my $data = eval { LoadFile($yaml_path) };
if ($@) {
	plan skip_all => "Could not load $yaml_path: $@";
	exit 0;
}

# Check if compute section exists
unless (exists $data->{compute} && ref $data->{compute} eq 'HASH') {
	plan skip_all => "No compute section found in YAML";
	exit 0;
}

# Check if compute->instance section exists
unless (exists $data->{compute}{instance} && ref $data->{compute}{instance} eq 'HASH') {
	plan skip_all => "No compute->instance section found in YAML";
	exit 0;
}

# Collect all instance keys with '-lssd' suffix
my @lssd_instances;
my $instances = $data->{compute}{instance};

for my $instance_name (keys %{$instances}) {
	# All machine types that end in -lssd bundle Local SSD partitions (375 GiB each).
	# - C3:  https://docs.cloud.google.com/compute/docs/general-purpose-machines#c3_disks
	# - C3D: https://docs.cloud.google.com/compute/docs/general-purpose-machines#c3d_disks
	# - C4 / C4A / C4D: same page, #c4_disks / #c4a_disks / #c4d_disks
	# - Z3:  https://docs.cloud.google.com/compute/docs/storage-optimized-machines
	if ($instance_name =~ /-lssd/) {
		push @lssd_instances, {
		name => $instance_name,
		data => $instances->{$instance_name}
	};
	}
}

# Plan tests
plan tests => scalar(@lssd_instances) * 1;

# Test each -lssd instance
for my $instance (@lssd_instances) {
	my $name = $instance->{name};

	# Test: Check if local-ssd value is a number
	if (exists $instance->{data}{'local-ssd'}) {
		my $value = $instance->{data}{'local-ssd'};
		like($value, qr/^\d+(?:\.\d+)?$/, 
			"compute->instance->$name has numeric 'local-ssd' value ($value)");
	} else {
		fail("compute->instance->$name has numeric 'local-ssd' value (field missing)");
	}
}

done_testing();

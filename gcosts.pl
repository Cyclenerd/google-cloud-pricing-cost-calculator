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
# Calculate and save the costs of Google Cloud Platform products and resources.
#
# Help: https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator

BEGIN {
	$VERSION = "1.1.0";
}

use strict;
use YAML::XS qw(LoadFile);
use App::Options (
	option => {
		pricing => {
			required    => 1,
			default     => 'pricing.yml',
			description => "YAML file with GCP pricing information (read)"
		},
		costs => {
			required    => 1,
			default     => 'COSTS.csv',
			type        => '/^[A-Za-z0-9_]+\.csv$/',
			description => "CSV file with costs for resources (write)"
		},
		totals => {
			required    => 1,
			default     => 'TOTALS.csv',
			type        => '/^[A-Za-z0-9_]+\.csv$/',
			description => "CSV file with total costs per name, resource, project, region and file (write)"
		}
	},
);

# Debug?
my $debug = $App::options{debug_options};

# Input / Output
my $pricing_file = $App::options{pricing};
my $costs_file   = $App::options{costs};
my $totals_file  = $App::options{totals};


###############################################################################
# FILES
###############################################################################

# Open pricing file
unless (-r "$pricing_file") {
	die "ERROR: Cannot read YAML file '$pricing_file' with GCP pricing information!\n";
}
my $pricing = LoadFile("$pricing_file") or die "ERROR: Cannot open YAML file '$pricing_file' to read GCP pricing information!\n";

# Get usage files
my @usage_files;
my $count_usage_files = 0;
opendir(DIR, '.') or die "ERROR: Cannot open directory to import usage files!\n";
while (my $filename = readdir(DIR)) {
	if (-r $filename && $filename =~ /\.yml$/ && $filename !~ /^pricing/) {
		push (@usage_files, $filename);
		$count_usage_files++;
	}
}
closedir(DIR);
unless ($count_usage_files) {
	die "ERROR: No YAML usage file (*.yml) found!\n";
}

# Open CSV cost file
open my $fh, q{>}, "$costs_file" or die "ERROR: Cannot open CSV file '$costs_file' for costs export!\n";

# Open CSV totals file
open my $fh_totals, q{>}, "$totals_file" or die "ERROR: Cannot open CSV file '$totals_file' for totals export!\n";


###############################################################################
# HELPER
###############################################################################

sub line {
	print "-"x60 . "\n";
}

sub double_line {
	print "="x60 . "\n";
}


###############################################################################
# CHECK FUNCTIONS
###############################################################################

# &check_region($pricing, $region)
sub check_region {
	my ($pricing, $region) = @_;
	if ($region) {
		if ($pricing->{'region'}->{$region} || $pricing->{'dual-region'}->{$region} || $pricing->{'multi-region'}->{$region}) {
			return $region;
		} else {
			die "ERROR: Region '$region' not found!\n";
		}
	}
}

# &check_disk_type($pricing, $type)
sub check_disk_type {
	my ($pricing, $type) = @_;
	if ($pricing->{'compute'}->{'storage'}->{$type}) {
		return $type;
	} else {
		die "ERROR: Disk type '$type' not found!\n";
	}
}

# &check_machine_type($pricing, $type)
sub check_machine_type {
	my ($pricing, $type) = @_;
	if ($pricing->{'compute'}->{'instance'}->{$type}) {
		return $type;
	} else {
		die "ERROR: Machine type '$type' not found!\n";
	}
}

# &check_os($pricing, $os)
sub check_os {
	my ($pricing, $os) = @_;
	if ($os eq 'free' || $os eq 'debian' || $os eq 'ubuntu' || $os eq 'centos' || $os =~ /^rocky/ || $os =~ /byos$/ ) {
		return 'free';
	} elsif ($pricing->{'compute'}->{'license'}->{'n1-standard-8'}->{'cost'}->{$os}) {
		return $os;
	} else {
		die "ERROR: Operating system license '$os' not found!\n";
	}
}

# &check_class($pricing, $class)
sub check_class {
	my ($pricing, $class) = @_;
	if ($pricing->{'storage'}->{'bucket'}->{$class}) {
		return $class;
	} else {
		die "ERROR: Cloud Storage class '$class' not found!\n";
	}
}

# &check_commitment($commitment)
sub check_commitment {
	my ($commitment) = @_;
	if ($commitment == '0') {
		return $commitment;
	} elsif ($commitment == '1') {
		return $commitment; # 1 year
	} elsif ($commitment == '3') {
		return $commitment; # 3 years
	} else {
		die "ERROR: Commitment '$commitment' not valid!\n";
	}
}

# &check_name($name)
sub check_name {
	my ($name) = @_;
	$name =~ s/\;//g;
	return $name;
}

# &check_state($state)
sub check_state {
	my ($state) = @_;
	if ($state eq 'terminated') {
		return $state;
	} elsif ($state eq 'running') {
		return $state;
	} else {
		die "ERROR: State '$state' not valid!\n";
	}
}

# &check_float($float)
sub check_float {
	my ($float) = @_;
	$float =~ s/\,/\./g;
	if ($float =~ m/^\d+\.\d+$/) {
		return $float;
	} elsif ($float =~ m/^\d+$/) {
		return $float;
	} else {
		die "ERROR: '$float' is not a floating-point number!\n";
	}
}

# &check_int($int)
sub check_int {
	my ($int) = @_;
	if ($int =~ /^\d+$/) {
		return $int;
	} else {
		die "ERROR: '$int' is not a number!\n";
	}
}

# &check_cost($cost, $region)
sub check_cost {
	my ($cost, $region) = @_;
	if ($cost =~ /^[+-]?([0-9]*[.])?[0-9]+$/) {
		return $cost;
	} else {
		die "ERROR: Cost for $cost in region '$region' not found!\n";
	}
}

# &check_commitment_cost($commitment_cost, $commitment, $cost, $region)
my $sum_warnings = 0;
sub check_commitment_cost {
	my ($commitment_cost, $commitment, $cost, $region) = @_;
	if ($commitment_cost =~ /^[+-]?([0-9]*[.])?[0-9]+$/) {
		return $commitment_cost;
	} else {
		warn "WARNING: '$commitment' commitment cost for $commitment_cost in region '$region' not found! Apply standard cost: '$cost'.\n";
		$sum_warnings++;
		return $cost;
	}
}


###############################################################################
# CALCULATION FUNCTIONS for bulk prices
###############################################################################

# &calc_monitoring_data_cost($data, $cost_1, $cost_2, $cost_3)
sub calc_monitoring_data_cost {
	my ($data, $cost_1, $cost_2, $cost_3) = @_;
	# Bulk price:
	my $range_1 = 100000; # 0-100000 MiB
	my $range_2 = 250000; # 100000-250000 MiB
	                      # > 250000 MiB
	my $cost_range_1 = $range_1*$cost_1;
	my $cost_range_2 = ($range_2-$range_1)*$cost_2;
	my $cost = 0;
	if ($data > $range_2) {
		$cost = ($data-$range_2)*$cost_3;
		$cost += $cost_range_2;
		$cost += $cost_range_1;
	} elsif ($data > $range_1) {
		$cost = ($data-$range_1)*$cost_2;
		$cost += $cost_range_1;
	} else {
		$cost = $data*$cost_1;
	}
	return $cost;
}

# &calc_lb_rule_cost($rules, $cost_min, $cost_add)
sub calc_lb_rule_cost {
	my ($rules, $cost_min, $cost_add) = @_;
	# Bulk price:
	my $range_1 = 5; # first 5 rules, up to 5 forwarding rules for the price, 1 = same as for 5 (cost_min)
	my $cost = 0;
	if ($rules > $range_1) {
		$cost = ($rules-$range_1)*$cost_add;
		$cost += $cost_min;
	} else {
		$cost = $cost_min;
	}
	return $cost;
}

# &calc_traffic_egress_cost($data, $cost_1, $cost_2, $cost_3)
sub calc_traffic_egress_cost {
	my ($data, $cost_1, $cost_2, $cost_3) = @_;
	# Bulk price:
	my $range_1 = 1024;  # 0-1 TiB
	my $range_2 = 10240; # 1-10 TiB
	                     # > 10 TiB
	my $cost_range_1 = $range_1*$cost_1;
	my $cost_range_2 = ($range_2-$range_1)*$cost_2;
	my $cost = 0;
	if ($data > $range_2) {
		$cost = ($data-$range_2)*$cost_3;
		$cost += $cost_range_2;
		$cost += $cost_range_1;
	} elsif ($data > $range_1) {
		$cost = ($data-$range_1)*$cost_2;
		$cost += $cost_range_1;
	} else {
		$cost = $data*$cost_1;
	}
	return $cost;
}


###############################################################################
# COST FUNCTIONS
###############################################################################

# &add_discount($cost, $discount)
sub add_discount {
	my ($cost, $discount) = @_;
	if ($discount) {
		$cost = $cost * $discount;
	}
	return $cost;
}

# &cost($fh, %values)
my $sum_total;
my (%sum_services, %sum_names, %sum_regions, %sum_projects, %sum_files);
sub cost {
	my (%values)   = @_;
	my $project    = $values{'project'};
	my $region     = $values{'region'};
	my $service    = $values{'resource'};
	my $name       = $values{'name'};
	my $data       = $values{'data'};
	my $class      = $values{'class'}; # buckets
	my $rules      = $values{'rules'}; # lb
	my $type       = $values{'type'}; # disks, instances
	my $cost       = $values{'cost'};
	my $commitment = $values{'commitment'};
	my $discount   = $values{'discount'};
	my $file       = $values{'file'};
	printf "cost : %.3f\n", $cost;
	foreach my $key (sort keys %values) {
		next if $key eq 'cost';
		my $value = $values{$key};
		print "$key = $value";
		print ", " unless $key eq (sort keys %values)[-1];
	}
	print "\n\n";
	print $fh join(";", (
		$project,
		$region,
		$service,
		$name,
		sprintf("%.3f", $cost),
		$type,
		$data,
		$class,
		$rules,
		$commitment,
		$discount,
		$file
	))."\n";
	$sum_total              += $cost;
	$sum_services{$service} += $cost;
	$sum_names{$name}       += $cost;
	$sum_regions{$region}   += $cost;
	$sum_projects{$project} += $cost;
	$sum_files{$file}       += $cost;

}

# &cost_monitoring($usage, $pricing)
sub cost_monitoring {
	my ($usage, $pricing) = @_;
	my $monitoring = $usage->{'monitoring'} || ();
	foreach my $i (@{$monitoring}) {
		my $name     = &check_name($i->{'name'}               || 'monitoring-data');
		my $data     = &check_float($i->{'data'}              || '0');
		my $discount = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region   = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		print "monitoring : $name\n";
		my $cost_1 = &check_cost($pricing->{'monitoring'}->{'data'}->{'cost'}->{'0-100000'}->{$region}->{'month'}      ||'', $region);
		my $cost_2 = &check_cost($pricing->{'monitoring'}->{'data'}->{'cost'}->{'100000-250000'}->{$region}->{'month'} ||'', $region);
		my $cost_3 = &check_cost($pricing->{'monitoring'}->{'data'}->{'cost'}->{'250000n'}->{$region}->{'month'}       ||'', $region);
		my $cost = &calc_monitoring_data_cost($data, $cost_1, $cost_2, $cost_3);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'monitoring',
			'name'     => $name,
			'data'     => $data,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_nat($usage, $pricing)
sub cost_nat {
	my ($usage, $pricing) = @_;
	my $nat_gateways = $usage->{'nat-gateways'} || ();
	foreach my $i (@{$nat_gateways}) {
		my $name     = &check_name($i->{'name'}               || 'nat-gateway');
		my $data     = &check_float($i->{'data'}              || '0');
		my $discount = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region   = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		print "nat-gateway : $name\n";
		my $cost_gateway = &check_cost($pricing->{'compute'}->{'network'}->{'nat'}->{'gateway'}->{'cost'}->{$region}->{'month'} ||'', $region);
		my $cost_data    = &check_cost($pricing->{'compute'}->{'network'}->{'nat'}->{'data'}->{'cost'}->{$region}->{'month'}    ||'', $region);
		my $cost = $cost_gateway+($cost_data*$data);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'nat-gateway',
			'name'     => $name,
			'data'     => $data,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_vpn($usage, $pricing)
sub cost_vpn {
	my ($usage, $pricing) = @_;
	my $vpn_tunnels = $usage->{'vpn-tunnels'} || ();
	foreach my $i (@{$vpn_tunnels}) {
		my $name     = &check_name($i->{'name'}               || 'vpn-tunnel');
		my $discount = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region   = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		print "vpn-tunnel : $name\n";
		my $cost = &check_cost($pricing->{'compute'}->{'network'}->{'vpn'}->{'tunnel'}->{'cost'}->{$region}->{'month'}||'', $region);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'vpn-tunnel',
			'name'     => $name,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_lb($usage, $pricing)
sub cost_lb {
	my ($usage, $pricing) = @_;
	my $load_balancers = $usage->{'load-balancers'} || ();
	foreach my $i (@{$load_balancers}) {
		my $name     = &check_name($i->{'name'}               || 'load-balancer');
		my $data     = &check_float($i->{'data'}              || '0');
		my $discount = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $rules    = &check_int($i->{'rules'}               || '0');
		my $region   = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		print "load-balancer : $name\n";
		my $cost_rule_min = &check_cost($pricing->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'min'}->{'cost'}->{$region}->{'month'} ||'compute > network > lb > rule > min', $region);
		my $cost_rule_add = &check_cost($pricing->{'compute'}->{'network'}->{'lb'}->{'rule'}->{'add'}->{'cost'}->{$region}->{'month'} ||'compute > network > lb > rule > add', $region);
		my $cost_data     = &check_cost($pricing->{'compute'}->{'network'}->{'lb'}->{'data'}->{'cost'}->{$region}->{'month'}          ||'compute > network > lb > data',       $region);
		my $cost = &calc_lb_rule_cost($rules, $cost_rule_min, $cost_rule_add);
		$cost += $cost_data*$data;
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'load-balancer',
			'name'     => $name,
			'data'     => $data,
			'rules'    => $rules,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_traffic_world($usage, $pricing)
sub cost_traffic_world {
	my ($usage, $pricing) = @_;
	my $traffic = $usage->{'traffic'} || ();
	foreach my $i (@{$traffic}) {
		my $name       = &check_name($i->{'name'}               || 'traffic-egress');
		my $data_world = &check_int($i->{'world'}               || '0');
		my $discount   = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region     = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		unless ($data_world) { next }; # skip if no traffic
		print "traffic-world : $name\n";
		my $cost_world_1 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{'0-1'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > 0-1',  $region);
		my $cost_world_2 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{'1-10'}->{$region}->{'month'} ||'compute > network > traffic > egreess > internet > 1-10', $region);
		my $cost_world_3 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'cost'}->{'10n'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > 10n',  $region);
		my $cost = &calc_traffic_egress_cost($data_world, $cost_world_1, $cost_world_2, $cost_world_3);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'traffic-world',
			'name'     => $name,
			'data'     => $data_world,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_traffic_china($usage, $pricing)
sub cost_traffic_china {
	my ($usage, $pricing) = @_;
	my $traffic = $usage->{'traffic'} || ();
	foreach my $i (@{$traffic}) {
		my $name       = &check_name($i->{'name'}               || 'egress');
		my $data_china = &check_int($i->{'china'}               || '0');
		my $discount = &check_float($i->{'discount'}            || $usage->{'discount'});
		my $region     = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		unless ($data_china) { next }; # skip if no traffic
		print "traffic-china : $name\n";
		my $cost_china_1 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{'0-1'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > china > 0-1',  $region);
		my $cost_china_2 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{'1-10'}->{$region}->{'month'} ||'compute > network > traffic > egreess > internet > china > 1-10', $region);
		my $cost_china_3 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'china'}->{'cost'}->{'10n'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > china > 10n',  $region);
		my $cost = &calc_traffic_egress_cost($data_china, $cost_china_1, $cost_china_2, $cost_china_3);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'traffic-china',
			'name'     => $name,
			'data'     => $data_china,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_traffic_australia($usage, $pricing)
sub cost_traffic_australia {
	my ($usage, $pricing) = @_;
	my $traffic = $usage->{'traffic'} || ();
	foreach my $i (@{$traffic}) {
		my $name           = &check_name($i->{'name'}               || 'egress');
		my $data_australia = &check_int($i->{'australia'}           || '0');
		my $discount       = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region         = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		unless ($data_australia) { next }; # skip if no traffic
		print "traffic-australia : $name\n";
		my $cost_australia_1 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{'0-1'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > australia > 0-1',  $region);
		my $cost_australia_2 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{'1-10'}->{$region}->{'month'} ||'compute > network > traffic > egreess > internet > australia > 1-10', $region);
		my $cost_australia_3 = &check_cost($pricing->{'compute'}->{'network'}->{'traffic'}->{'egress'}->{'internet'}->{'australia'}->{'cost'}->{'10n'}->{$region}->{'month'}  ||'compute > network > traffic > egreess > internet > australia > 10n',  $region);
		my $cost = &calc_traffic_egress_cost($data_australia, $cost_australia_1, $cost_australia_2, $cost_australia_3);
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'traffic-australia',
			'name'     => $name,
			'data'     => $data_australia,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_buckets($buckets, $usage, $pricing)
sub cost_buckets {
	my ($buckets, $usage, $pricing, $vm) = @_;
	foreach my $i (@{$buckets}) {
		my $name     = &check_name($i->{'name'}               || 'bucket');
		my $class    = &check_class($pricing, $i->{'class'}   || 'standard');
		my $data     = &check_float($i->{'data'}              || '0');
		my $discount = &check_float($i->{'discount'}          || $usage->{'discount'});
		my $region   = &check_region($pricing, $i->{'region'} || $usage->{'region'});
		print "bucket : $name\n";
		my $cost = &check_cost($pricing->{'storage'}->{'bucket'}->{$class}->{'cost'}->{$region}->{'month'}||"storage > bucket > class '$class'", $region);
		$cost = $data*$cost;
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource' => 'bucket',
			'name'     => $name,
			'data'     => $data,
			'class'    => $class,
			'cost'     => $cost,
			'discount' => $discount,
			'region'   => $region,
			'project'  => $usage->{'project'},
			'file'     => $usage->{'file'}
		);
	}
}

# &cost_disks($disks, $usage, $pricing, $commitment)
sub cost_disks {
	my ($disks, $usage, $pricing, $commitment) = @_;
	foreach my $i (@{$disks}) {
		my $name     = &check_name($i->{'name'}                || 'disk');
		my $type     = &check_disk_type($pricing, $i->{'type'} || 'hdd');
		my $data     = &check_float($i->{'data'}               || '0');
		my $discount = &check_float($i->{'discount'}           || $usage->{'discount'});
		my $region   = &check_region($pricing, $i->{'region'}  || $usage->{'region'});
		print "disk : $name\n";
		my $cost = &check_cost($pricing->{'compute'}->{'storage'}->{$type}->{'cost'}->{$region}->{'month'}||"type '$type'", $region);
		if ($type eq "local") {
			if ($commitment == '1') {
				$cost = &check_commitment_cost($pricing->{'compute'}->{'storage'}->{$type}->{'cost'}->{$region}->{'month_1y'}||"compute > storage > type '$type'", '1 year', $cost, $region);
			} elsif ($commitment == '3') {
				$cost = &check_commitment_cost($pricing->{'compute'}->{'storage'}->{$type}->{'cost'}->{$region}->{'month_3y'}||"compute > storage > type '$type'", '3 year', $cost, $region);
			}
		}
		$cost = $cost*$data;
		$cost = &add_discount($cost, $discount);
		&cost(
			'resource'   => 'disk',
			'name'       => $name,
			'data'       => $data,
			'type'       => $type,
			'cost'       => $cost,
			'commitment' => $commitment,
			'discount'   => $discount,
			'region'     => $region,
			'project'    => $usage->{'project'},
			'file'       => $usage->{'file'}
		);
	}
}

# &cost_instances($usage, $pricing)
sub cost_instances {
	my ($usage, $pricing) = @_;
	my $instances = $usage->{'instances'} || ();
	foreach my $i (@{ $instances }) {
		my $name       = &check_name($i->{'name'}                   || 'instance');
		my $type       = &check_machine_type($pricing, $i->{'type'} || 'f1-micro');
		my $os         = &check_os($pricing, $i->{'os'}             || 'free');
		my $state      = &check_state($i->{'state'}                 || 'running'); # RUNNING, TERMINATED
		my $commitment = &check_commitment($i->{'commitment'}       || '0');
		my $discount   = &check_float($i->{'discount'}              || $usage->{'discount'});
		my $ip         = &check_int($i->{'external-ip'}             || '0');
		my $region     = &check_region($pricing, $i->{'region'}     || $usage->{'region'});
		my $disks      = $i->{'disks'}                              || ();
		my $buckets    = $i->{'buckets'}                            || ();
		print "vm : $name\n";
		# Instance (VM)
		my $resource = 'vm';
		my $cost_instance = &check_cost($pricing->{'compute'}->{'instance'}->{$type}->{'cost'}->{$region}->{'month'}||"compute > instance > type '$type'", $region);
		# Override costs for stopped (terminated) VM
		if ($state eq 'terminated') {
			$cost_instance = '0';
			$resource = 'vm-terminated';
		}
		if ($commitment == '1') {
			$cost_instance= &check_commitment_cost($pricing->{'compute'}->{'instance'}->{$type}->{'cost'}->{$region}->{'month_1y'}||"compute > instance > type '$type'", '1 year', $cost_instance, $region);
		} elsif ($commitment == '3') {
			$cost_instance = &check_commitment_cost($pricing->{'compute'}->{'instance'}->{$type}->{'cost'}->{$region}->{'month_3y'}||"compute > instance > type '$type'", '3 year', $cost_instance, $region);
		}
		$cost_instance = &add_discount($cost_instance, $discount);
		&cost(
			'resource'   => $resource,
			'name'       => $name,
			'type'       => $type,
			'cost'       => $cost_instance,
			'discount'   => $discount,
			'commitment' => $commitment,
			'region'     => $region,
			'project'    => $usage->{'project'},
			'file'       => $usage->{'file'}
		);
		# External IP
		if ($ip) {
			if ($state eq 'terminated') {
				# Unused IP / Static Ip Charge / Static external IP address (assigned but unused)
				print "vm-unused-ip : $name\n";
				my $cost_ip = &check_cost($pricing->{'compute'}->{'network'}->{'ip'}->{'unused'}->{'cost'}->{$region}->{'month'}||"compute > network > ip > unused", $region);
				$cost_ip = $cost_ip*$ip;
				$cost_ip = &add_discount($cost_ip, $discount);
				&cost(
					'resource'   => 'vm-unused-ip',
					'name'       => $name,
					'cost'       => $cost_ip,
					'discount'   => $discount,
					'region'     => $region,
					'project'    => $usage->{'project'},
					'file'       => $usage->{'file'}
				);
			} else {
				# Active IP / External IP Charge on a Standard VM
				print "vm-ip : $name\n";
				my $cost_ip = &check_cost($pricing->{'compute'}->{'network'}->{'ip'}->{'vm'}->{'cost'}->{$region}->{'month'}||"compute > network > ip > vm", $region);
				$cost_ip = $cost_ip*$ip;
				$cost_ip = &add_discount($cost_ip, $discount);
				&cost(
					'resource'   => 'vm-ip',
					'name'       => $name,
					'cost'       => $cost_ip,
					'discount'   => $discount,
					'region'     => $region,
					'project'    => $usage->{'project'},
					'file'       => $usage->{'file'}
				);
			}
		}
		# Operating system
		if ($os ne 'free') {
			print "vm-os : $name\n";
			my $resource_os = 'vm-os';
			my $cost_os = &check_cost($pricing->{'compute'}->{'license'}->{$type}->{'cost'}->{$os}->{'month'}||"compute > license > type '$type' > os '$os'", $region);
			# Override costs for stopped (terminated) VM
			if ($state eq 'terminated') {
				$cost_os = '0';
				$resource_os = 'vm-os-terminated';
			}
			# 2022/02/18: 1y and 3y committed use discounts (CUD) only for SUSE Linux Enterprise Server for SAP (sles-sap)
			# 2023/01/31: Compute Engine committed use discounts are now also available for Red Hat Enterprise Linux (RHEL) image licenses.
			if ($os eq 'sles-sap' || $os eq 'rhel' || $os eq 'rhel-sap') {
				if ($commitment == '1') {
					$cost_os = &check_commitment_cost($pricing->{'compute'}->{'license'}->{$type}->{'cost'}->{$os}->{'month_1y'}||"compute > license > type '$type' > os '$os'", '1 year', $cost_os, $region);
				} elsif ($commitment == '3') {
					$cost_os = &check_commitment_cost($pricing->{'compute'}->{'license'}->{$type}->{'cost'}->{$os}->{'month_3y'}||"compute > license > type '$type' > os '$os'", '3 year', $cost_os, $region);
				}
			}
			$cost_os = &add_discount($cost_os, $discount);
			&cost(
				'resource'   => $resource_os,
				'name'       => $name,
				'type'       => $os,
				'cost'       => $cost_os,
				'discount'   => $discount,
				'commitment' => $commitment,
				'region'     => $region,
				'project'    => $usage->{'project'},
				'file'       => $usage->{'file'}
			);
		}
		# Disks
		my $disks = $i->{'disks'} || ();
		&cost_disks($disks, $usage, $pricing);
		# Buckets
		my $buckets = $i->{'buckets'} || ();
		&cost_buckets($buckets, $usage, $pricing);
	}
}


###############################################################################
# CALCULATE USAGE COSTS
###############################################################################

my $default_region   = &check_region($pricing, 'us-central1');
my $default_project  = &check_name('gcp-calculator');
my $default_discount = &check_float('1.0');

print "COSTS\n";
&double_line();
print $fh join(";", (
	'PROJECT',
	'REGION',
	'RESOURCE',
	'NAME',
	'COST',
	'TYPE',
	'DATA',
	'CLASS',
	'RULES',
	'COMMITMENT',
	'DISCOUNT',
	'FILE'
))."\n";

# Open usage files
foreach my $usage_file (sort @usage_files) {
	print "file : $usage_file\n";
	&line();
	# Open YAML usage file
	my $usage = LoadFile("$usage_file") or die "ERROR: Cannot open YAML file '$usage_file' to read Google Cloud Platform resources!\n";
	# Read usage
	$usage->{'project'}  = &check_name($usage->{'project'}             || $default_project);
	$usage->{'region'}   = &check_region($pricing, $usage->{'region'}  || $default_region);
	$usage->{'discount'} = &check_float($usage->{'discount'}           || $default_discount);
	$usage->{'file'}     = "$usage_file";
	# Update global defaults
	$default_project  = $usage->{'project'};
	$default_region   = $usage->{'region'};
	$default_discount = $usage->{'discount'};
	print "project : $default_project\n";
	print "region : $default_region\n";
	print "discount : $default_discount\n";
	&line();
	print "\n";

	# Monitoring
	&cost_monitoring($usage, $pricing);
	# NAT Gateway
	&cost_nat($usage, $pricing);
	# VPN Tunnel
	&cost_vpn($usage, $pricing);
	# Load Balancer
	&cost_lb($usage, $pricing);
	# Traffic
	&cost_traffic_world($usage, $pricing);
	&cost_traffic_china($usage, $pricing);
	&cost_traffic_australia($usage, $pricing);
	# GCE VM Instances
	&cost_instances($usage, $pricing);
	# Buckets
	my $buckets = $usage->{'buckets'} || ();
	&cost_buckets($buckets, $usage, $pricing);
	# Disks
	my $disks = $usage->{'disks'} || ();
	&cost_disks($disks, $usage, $pricing);
}

close $fh;


###############################################################################
# TOTALS
###############################################################################

# &total_header()
sub total_header {
	print $fh_totals join(";", (
		'TYPE',
		'NAME',
		'COST',
	))."\n";
}

# &total($type, $name, $cost)
sub total {
	my ($type, $name, $cost) = @_;\
	printf "$name : %.3f\n", $cost;
	print $fh_totals join(";", (
		$type,
		$name,
		sprintf("%.3f", $cost)
	))."\n";
}

print "TOTALS\n";
&double_line();
&total_header();

print "\nNAME\n";
&line();
foreach my $key (sort keys %sum_names) {
	my $cost = $sum_names{$key};
	&total('name', $key, $cost);
}
print "\nRESOURCE\n";
&line();
foreach my $key (sort keys %sum_services) {
	my $cost = $sum_services{$key};
	&total('resource', $key, $cost);
}
print "\nREGION\n";
&line();
foreach my $key (sort keys %sum_regions) {
	my $cost = $sum_regions{$key};
	&total('region', $key, $cost);
}
print "\nFILE\n";
&line();
foreach my $key (sort keys %sum_files) {
	my $cost = $sum_files{$key};
	&total('file', $key, $cost);
}
print "\nPROJECT\n";
&line();
foreach my $key (sort keys %sum_projects) {
	my $cost = $sum_projects{$key};
	&total('project', $key, $cost);
}

print "\n";
&line();
if ($sum_warnings) {
	print "WARNINGS: $sum_warnings\n";
}
&total('total', 'total', $sum_total);


close $fh_totals;
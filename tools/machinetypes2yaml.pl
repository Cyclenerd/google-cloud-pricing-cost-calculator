#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use YAML::XS qw(Dump);

my $input_file;
my $output_file;
my $help;

GetOptions(
    'input|i=s'  => \$input_file,
    'output|o=s' => \$output_file,
    'help|h'     => \$help,
) or die "Error in command line arguments\n";

if ($help || !$input_file) {
    print_usage();
    exit 0;
}

# Read CSV file
open my $fh, '<', $input_file or die "Cannot open $input_file: $!\n";

my @lines = <$fh>;
close $fh;

# Check if first line is a header
my $start_line = 0;
if ($lines[0] =~ /^NAME;CPUS;SHARED_CPU;MEMORY_GB;DEPRECATED;ZONE/i) {
    $start_line = 1;
}

# Parse CSV and build instances hash
my %instances;

for my $i ($start_line .. $#lines) {
    my $line = $lines[$i];
    chomp $line;
    
    # Skip empty lines
    next if $line =~ /^\s*$/;
    
    # Parse CSV line: NAME;CPUS;SHARED_CPU;MEMORY_GB;DEPRECATED;ZONE
    my @fields = split /;/, $line, -1;
    
    # Skip if not enough fields
    next if @fields < 4;
    
    my ($name, $cpus, $shared_cpu, $memory_gb, $deprecated, $zone) = @fields;
    
    # Skip if name is empty
    next if !defined $name || $name =~ /^\s*$/;
    
    # Clean up fields
    $name =~ s/^\s+|\s+$//g;
    $cpus =~ s/^\s+|\s+$//g;
    $memory_gb =~ s/^\s+|\s+$//g;
    if (defined $shared_cpu) {
        $shared_cpu =~ s/^\s+|\s+$//g;
    }
    
    # Skip deprecated instances
    if (defined $deprecated && $deprecated =~ /true/i) {
        next;
    }
    
    # Convert cpus to number (handle fractional and shared CPU)
    my $cpu_num;
    if ($cpus =~ /^(\d+\.?\d*)$/) {
        $cpu_num = $1;
        # Convert to number (remove unnecessary decimals)
        $cpu_num = $cpu_num + 0;
        
        # Handle shared CPU instances (fractional vCPU)
        if (defined $shared_cpu && $shared_cpu =~ /true/i) {
            # Map common shared CPU instances to their fractional values
            if ($name eq 'e2-micro' || $name eq 'f1-micro' || $name eq 'g1-small') {
                $cpu_num = 0.25 if $name eq 'e2-micro';
                $cpu_num = 0.2 if $name eq 'f1-micro';
                $cpu_num = 0.5 if $name eq 'g1-small';
            } elsif ($name eq 'e2-small') {
                $cpu_num = 0.5;
            } elsif ($name eq 'e2-medium') {
                $cpu_num = 1;
            } else {
                # For other shared CPU instances, divide by 2 as a heuristic
                # This may need adjustment based on actual GCP specs
                $cpu_num = $cpu_num / 2;
            }
        }
    } else {
        warn "Warning: Invalid CPU value '$cpus' for instance '$name', skipping\n";
        next;
    }
    
    # Convert memory to number
    my $ram_num;
    if ($memory_gb =~ /^(\d+\.?\d*)$/) {
        $ram_num = $1;
        # Convert to number (remove unnecessary decimals)
        $ram_num = $ram_num + 0;
    } else {
        warn "Warning: Invalid memory value '$memory_gb' for instance '$name', skipping\n";
        next;
    }
    
    # Build instance entry
    $instances{$name} = {
        cpu => $cpu_num,
        ram => $ram_num,
    };
}

# Sort instances by name
my @sorted_names = sort keys %instances;

# Generate YAML output
my $yaml_output = "# Generated from CSV file: $input_file\n";
$yaml_output .= "# Total instances: " . scalar(@sorted_names) . "\n\n";
$yaml_output .= "compute:\n";
$yaml_output .= "  instance:\n";

for my $name (@sorted_names) {
    my $inst = $instances{$name};
    $yaml_output .= "    $name:\n";
    $yaml_output .= "      cpu: $inst->{cpu}\n";
    $yaml_output .= "      ram: $inst->{ram}\n";
}

# Output result
if ($output_file) {
    open my $out_fh, '>', $output_file or die "Cannot open $output_file for writing: $!\n";
    print $out_fh $yaml_output;
    close $out_fh;
    print "YAML written to $output_file\n";
} else {
    print $yaml_output;
}

sub print_usage {
    print <<'USAGE';
Usage: csv2yaml.pl -i <input.csv> [-o <output.yml>]

Convert Google Compute machine types CSV file to YAML format.

Options:
    -i, --input <file>   Input CSV file (required)
                         Format: NAME;CPUS;SHARED_CPU;MEMORY_GB;DEPRECATED;ZONE
                         Header line is optional and will be auto-detected
    
    -o, --output <file>  Output YAML file (optional)
                         If not specified, outputs to STDOUT
    
    -h, --help           Show this help message

Example:
    csv2yaml.pl -i tools/machinetypes.csv -o output.yml
    csv2yaml.pl -i machinetypes.csv > instances.yml

Notes:
    - Deprecated instances are automatically skipped
    - Empty lines are ignored
    - Instances are sorted alphabetically by name
    - Output format matches build/gcp.yml -> compute -> instance structure

USAGE
}

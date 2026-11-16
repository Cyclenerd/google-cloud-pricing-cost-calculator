#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Cwd qw(abs_path);
use DBI;
use YAML::XS qw(LoadFile DumpFile);

# Public catalog snapshot (including sole-tenancy decoys), not a Billing API export.
# https://cloud.google.com/__/json/searchskus?currency=USD&filter=Z4M
# Run from any directory: perl t/z4m.t
my $root = abs_path("$FindBin::Bin/..");
my $tmp = tempdir(CLEANUP => 1);
chdir $tmp or die $!;
my $dbh = DBI->connect('dbi:SQLite:dbname=skus.db', '', '', {
	RaiseError => 1, sqlite_allow_multiple_statements => 1
});
sub slurp {
	my ($path) = @_;
	open my $fh, '<', $path or die "$path: $!";
	local $/;
	return <$fh>;
}
$dbh->do(slurp("$root/build/skus.sql"));
system('sqlite3', 'skus.db', '.mode csv', ".import $root/build/mapping.csv mapping") == 0 or die "Import mapping.csv failed";
open my $fh, '<', "$root/t/z4m_skus.csv" or die $!;
while (<$fh>) {
	chomp;
	my ($id, $description, $group, $region, $nanos, $unit) = split /;/;
	$dbh->do('INSERT INTO skus (SKU_NAME, SKU_ID, SKU_DESCRIPTION, SVC_DISPLAY_NAME, FAMILY, "GROUP", REGIONS, NANOS, UNITS, UNIT, UNIT_DESCRIPTION) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)',
		undef, $id, $id, $description, 'Compute Engine', 'Compute', $group, $region, $nanos, $unit, $unit);
}
$dbh->do(slurp("$root/build/mapping.sql"));
is($dbh->selectrow_array("SELECT COUNT(*) FROM skus WHERE MAPPING LIKE '%z4m%'"), 12, 'all purchase models mapped');
is($dbh->selectrow_array("SELECT COUNT(*) FROM skus WHERE SKU_DESCRIPTION LIKE '%Sole Tenancy%' AND MAPPING IS NOT NULL"), 0, 'sole tenancy excluded');

# A nonzero generic SSD price catches accidental double charging or wrong SKU selection.
$dbh->do("INSERT INTO skus (SKU_NAME, MAPPING, REGIONS, NANOS, UNITS) VALUES ('generic-ssd', 'gce.storage.ssd.local', 'us-central1', 0, 1)");

# Synthetic shared dependencies let the generator run offline; their output is not published.
for my $mapping ('monitoring.data', 'gce.os.sles.cpu', 'gce.os.sles.sap.cpu.6.n',
	'gce.os.rhel.cpu.9.127', 'gce.os.rhel.cpu.128.n',
	'gce.os.rhel.sap.cpu.9.127', 'gce.os.rhel.sap.cpu.128.n') {
	$dbh->do('INSERT INTO skus (SKU_NAME, MAPPING, REGIONS, NANOS, UNITS) VALUES (?, ?, ?, ?, 0)',
		undef, $mapping, $mapping, 'global', 1000000);
}
my $gcp = LoadFile("$root/build/gcp.yml");
my @machines = sort grep { /^z4m-/ } keys %{$gcp->{compute}->{instance}};
is_deeply(\@machines, [qw(z4m-highmem-16 z4m-highmem-192 z4m-highmem-192-metal z4m-highmem-32 z4m-highmem-48)], 'exact documented machine names');
my %hardware = (
	'z4m-highmem-16' => [16, 122, 14000],
	'z4m-highmem-32' => [32, 244, 28000],
	'z4m-highmem-48' => [48, 366, 42000],
	'z4m-highmem-192' => [192, 1488, 168000],
	'z4m-highmem-192-metal' => [192, 1536, 168000],
);
for my $machine (@machines) {
	my $definition = $gcp->{compute}->{instance}->{$machine};
	is_deeply([map { 0 + $definition->{$_} } qw(cpu ram local-ssd)], $hardware{$machine}, "$machine matches documented hardware");
}
$gcp->{compute}->{instance} = { map { $_ => $gcp->{compute}->{instance}->{$_} } @machines };
$gcp->{region} = { 'us-central1' => {}, 'us-west1' => {} };
DumpFile('gcp.yml', $gcp);

sub generate {
	my ($sud, $hours) = @_;
	open my $log, '>', 'generator.log' or die $!;
	open my $err, '>', 'generator.err' or die $!;
	open my $stdout, '>&', \*STDOUT or die $!;
	open my $stderr, '>&', \*STDERR or die $!;
	open STDOUT, '>&', $log or die $!;
	open STDERR, '>&', $err or die $!;
	my $status = system($^X, "$root/build/pricing.pl", "-sud=$sud", "-hours=$hours");
	open STDOUT, '>&', $stdout or die $!;
	open STDERR, '>&', $stderr or die $!;
	is($status, 0, 'generator succeeds') or diag(slurp('generator.err'));
	return LoadFile('pricing.yml');
}
my $priced = generate(1, 730);
my $without_sud = generate(0, 730);
for my $machine (@machines) {
	my $definition = $gcp->{compute}->{instance}->{$machine};
	my $cost = $priced->{compute}->{instance}->{$machine}->{cost}->{'us-central1'};
	my %rates = (
		month => [0.03465, 0.003938, 0.11744],
		month_1y => [0.023562, 0.0026778, 0.0798592],
		month_3y => [0.015246, 0.0017327, 0.0516736],
		month_spot => [0.01386, 0.0015752, 0.046976],
	);
	for my $model (sort keys %rates) {
		if ($machine =~ /-metal$/ && $model eq 'month_spot') {
			ok(!exists $cost->{$model} && !exists $cost->{hour_spot}, 'bare metal has no Spot price');
			next;
		}
		my ($cpu, $ram, $ssd) = @{$rates{$model}};
		my $expected = ($definition->{cpu} * $cpu + $definition->{ram} * $ram) * 730 + $definition->{'local-ssd'} * $ssd;
		cmp_ok(abs($cost->{$model} - $expected), '<', 0.000001, "$machine $model includes mandatory SSD exactly once");
	}
	is_deeply($cost, $without_sud->{compute}->{instance}->{$machine}->{cost}->{'us-central1'}, "$machine has no SUD");
	ok(!exists $priced->{compute}->{instance}->{$machine}->{cost}->{'us-west1'}, "$machine unavailable pricing omitted");
	ok(!exists $priced->{compute}->{license}->{$machine}->{cost}->{windows}, "$machine has no Windows license");
}

# Each missing required component must suppress only its own purchase model.
my %suffix = (month => '', month_1y => '.1y', month_3y => '.3y', month_spot => '.spot');
for my $component ('gce.compute.cpu.z4m', 'gce.compute.ram.z4m', 'gce.storage.ssd.local.z4m') {
	for my $model (sort keys %suffix) {
		my $mapping = $component . $suffix{$model};
		my $ids = $dbh->selectcol_arrayref('SELECT rowid FROM skus WHERE MAPPING = ?', undef, $mapping);
		$dbh->do('UPDATE skus SET MAPPING = NULL WHERE MAPPING = ?', undef, $mapping);
		my $missing = generate(1, 730)->{compute}->{instance}->{'z4m-highmem-16'}->{cost}->{'us-central1'};
		ok(!exists $missing->{$model}, "$mapping missing: no partial price");
		for my $other (grep { $_ ne $model } keys %suffix) {
			is($missing->{$other}, $priced->{compute}->{instance}->{'z4m-highmem-16'}->{cost}->{'us-central1'}->{$other}, "$other unaffected");
		}
		$dbh->do('UPDATE skus SET MAPPING = ? WHERE rowid = ?', undef, $mapping, $_) for @$ids;
	}
}
my $short = generate(1, 100)->{compute}->{instance}->{'z4m-highmem-16'}->{cost}->{'us-central1'};
cmp_ok(abs($short->{month} - ((16 * 0.03465 + 122 * 0.003938) * 100 + 14000 * 0.11744)), '<', 0.000001, 'custom month hours preserve SSD billing units');
done_testing();

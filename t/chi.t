#!perl -w

use strict;
use warnings;
use lib 't/lib';

use Test::Most tests => 9;
use FindBin qw($Bin);
use Test::NoWarnings;
use Test::Needs 'CHI';

BEGIN {
	use_ok('MyLogger');
	use_ok('Database::test1');
	CHI->import();
}

CHI: {
	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $test1 = new_ok('Database::test1' => [{
		cache => $cache,
		directory => "$Bin/../data",
		logger => new_ok('MyLogger'),
		max_slurp_size => 1,	# force to not use slurp and therefore to use SQL and cache
	}]);

	cmp_ok(scalar $cache->get_keys(), '==', 0, 'cache is empty');
	my $rc = $test1->fetchrow_hashref(entry => 'two');
	cmp_ok(ref($rc), 'eq', 'HASH', 'fetchrow hashref returns a reference to a hash');
	cmp_ok($rc->{'number'}, '==', 2, 'basic test works');

	# White box test the cache
	# ok($cache->get('barney::') eq 'betty');
	# ok($cache->get('barney::betty') eq 'betty');

	cmp_ok(scalar $cache->get_keys(), '==', 1, 'cache is populated');
	if($ENV{'TEST_VERBOSE'}) {
		foreach my $key($cache->get_keys()) {
			diag($key);
		}
	}
}

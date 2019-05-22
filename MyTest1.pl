use strict;
use warnings;
use Data::Dumper;

my %md5 = (
		'abcdefg' => ['/e/5k/test.pl', '/e/5k/testcopy.pl'],
		'bcdefgh' => ['/e/5k/routingchange.pl'],
		'efghijk' => ['/e/5k/homework.pl', '/e/5k/homeworkcopy.pl']
	);

my @result;
foreach my $key (keys %md5)
{
	if($#{$md5{$key}} >= 1)
	{
		push @result, [@{md5{$key}}];
	}
}

print Dumper(@result);
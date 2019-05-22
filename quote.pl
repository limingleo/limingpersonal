use strict;
use warnings;
use Finance::Quote;

if ($#ARGV == -1)	{
	print STDERR "Usage is $0 <stock> [<stock> ...]\n";
	exit 0;
}

my $quote = Finance::Quote->new;
my %data = $quote->fetch('usa', @ARGV);

foreach my $stock (@ARGV)	{
	my $price = $data{$stock, "price"};
	if (not defined($price))	{
		print "No information on $stock\n";
		next;
	}
	my $day = $data{$stock, "day_range"};
	my $year = $data{$stock, "year_range"};
	if (not defined($day))	{$day = "???"}
	if (not defined($year))	{$year = "???"}

	print "$stock Last: $price Day range: $day\n";
	print "Year range: $year\n";
}
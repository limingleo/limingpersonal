use strict;
use warnings;
use Getopt::Std;
use URI;

use File::Find();
use vars qw/*name/;
use vars qw/$opt_s $opt_w/;

my @file_list;

sub wanted	{
	if(-f $_)	{	push @file_list, $name}
}

getopts("s:w:");
if( (not defined $opt_s) ||	(not defined $opt_w) ||	($#ARGV != -1) )	{
	print STDERR "Usage is $0 -s<site> -w<walk-file>\n";
}

if ($opt_s !~ /^\//)	{die "Path for -s must be absolute"}
if (! -d $opt_s)	{die "$opt_s is not a directory"}
$opt_s =~ s/\/$//;

File::Find::find({wanted => \&wanted}, $opt_s);

my %site = map {$_, '0'} @file_list;

open IN_FILE, "<", $opt_w or die "Could not open $opt_w";
<IN_FILE>;
while(<IN_FILE>)	{
	if(substr($_,0,1) ne "\t")	{last}
	my $url = URI->new($_);
	my $path = $url->path;
	$path =~ s/\/$//;
	$site{$opt_s.$url->path} = 's';
}

foreach my $cur_file (sort keys %site)	{
	if ($site{$cur_file} ne 's')	{print "Orphan: $cur_file\n"}
}
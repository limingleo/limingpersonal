use lib "C:/Perl64/lib";
use lib "C:/Perl64/site/lib";
use strict;
use warnings;

use HTML::SimpleLinkExtor;
use LWP::Simple;
use URI::URL;

my $top_url;
my %links;

sub is_ours	{
	my $url = shift;
	if(substr($url,0,length($top_url)) ne $top_url)	{
		return undef;
	}
	return 1;
}

no warnings 'recursion';

sub process_url($);		# Needed because this is recursive
sub process_url($)	{
	my $url = shift;

	if(defined($links{$url}))	{return}
	# It is bad unless we know it's OK
	$links{$url} = "Broken";

	my @head_info = head($url);
	if($#head_info == -1)	{return}    # The link is bad
	
	$links{$url} = "External";

	if(not is_ours($url))	{return}

	$links{$url} = "Internal";

	if(not defined($head_info[1]))	{return}

	if($head_info[0] !~ /^test\/html/)	{return}

	my $extractor = HTML::SimpleLinkExtor->new();
	my $data = get($url);
	if(not defined($data))	{
		$links{$url} = "Broken";
		return;
	}

	$extractor->parse($data);
	my @all_links = $extractor->links();

	foreach my $cur_link (@all_links)	{
		my $page = URI::URL->new($cur_link,$url);
		my $full = $page->abs();

		if($full =~ /^ftp:/)		{next}
		elsif($full =~ /^mailto:/)	{next}
		elsif($full =~ /^http:/)	{process_url($full)}
		else						{print "Strange URL: $full -- skipped.\n"}
	}
}

use warnings "recursion";

if($#ARGV != 0)	{
	print STDERR "$0 <top-url>\n";
	exit 8;
}

$top_url = $ARGV[0];
process_url($top_url);

my @internal;
my @external;
my @broken;
my @strange;

foreach my $cur_key (keys %links)	{
	if($links{$cur_key} eq "Internal")		{push @internal, $cur_key}
	elsif($links{$cur_key} eq "External")	{push @external, $cur_key}
	elsif($links{$cur_key} eq "Broken")		{push @broken, $cur_key}
	else									{push @strange, $cur_key}
}

print "Internal\n";
foreach my $cur_url (sort @internal)	{print "\t$cur_url\n"}
print "External\n";
foreach my $cur_url (sort @external)	{print "\t$cur_url\n"}
print "Broken\n";
foreach my $cur_url (sort @broken)		{print "\t$cur_url\n"}

if($#strange != -1)	{
	print "Strange\n";
	foreach my $cur_url (sort @strange)	{print "\t$cur_url\n"}
}
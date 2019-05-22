BEGIN	{push @INC, "C:/Perl64/lib";}
use strict;
use warnings;
use Time::ParseDate;
use Date::Calc qw(Delta_Days);

sub time_to_YMD($)	{
	my $time = shift;
	my @local = localtime($time);
	return ($local[5]+1900, $local[4]+1, $local[3]);
}

my $in_file = "calendar.txt";

if($#ARGV == 0)	{
	$in_file = $ARGV[0];
}
if($#ARGV > 0)	{
	print STDERR "Usage: $0 [calendar-file]\n";
}

open IN_FILE, "<", $in_file or die "Unable to open $in_file for reading";
my @today_YMD = time_to_YMD(time());

while(<IN_FILE>)	{
	if($_ =~ /^\s*#/)	{
		next;
	}
	if($_ =~ /^\s*$/)	{
		next;
	}

	my @data = split /\t+/, $_, 3;
	if ($#data !=2)	{
		next;
	}
	my $date = parsedate($data[0]);
	if( not defined($date))	{
		print STDERR "Can't understand date $data[0]\n";
		next;
	}

	my @file_YMD = time_to_YMD($date);
	my $diff = Delta_Days(@today_YMD, @file_YMD);
	if($data[1] > 0)	{
		if (($diff >= 0) && ($diff < $data[1]))	{
			print "$diff $data[2]";
		}
	}
	else	{
		if (($diff < 0) && ($diff < -($data[1])))	{
			print "$diff $data[2]";
		}
	}
}
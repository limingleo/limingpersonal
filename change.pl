use strict;
use warnings;
use File::Find;
use Digest::MD5;
use Storable qw(nstore retrieve);

my $info_file_name = ".change.info";

sub md5($)	{
	my $cur_file = shift;

	open(FILE, $cur_file) or return ("");
	binmode(FILE);
	my $result = Digest::MD5->new->addfile(*FILE)->hexdigest;
	close(FILE);
	return $result;
}

my $file_info;
my %real_info;
my @dir_list = @ARGV;

if(-f $info_file_name)	{
	$file_info = retrieve($info_file_name);
}
else	{
	print "No storage meta-file found, generating $info_file_name\n";
	find(sub {-f && ($real_info{$File::Find::name} = md5($_)); }, @dir_list);
	nstore \%real_info, $info_file_name;
	exit 0;
}

if($#dir_list < 0)	{
	print "Nothing to look at\n";
	exit 0;
}

find(sub {
			-f && ($real_info{$File::Find::name} = md5($_));
		}, @dir_list
	);

foreach my $file (sort keys %real_info)	{
	if (not defined($file_info->{$file}))	{
		print "New file: $file\n";
	}
	else	{
		if($real_info{$file} ne $file_info->{$file})	{
			print "Changed: $file\n";
		}
		delete $file_info->{$file};
	}
}

foreach my $file (sort keys %$file_info)	{
	print "Deleted: $file\n";
}

nstore \%real_info, $info_file_name;
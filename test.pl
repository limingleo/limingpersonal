use File::Find;
use Storable qw(nstore retrieve);

my $file_info;
find sub {
	if(/homework_info/)	{
		my $file_info = retrieve $_;
		my $quiz_no = scalar @{$file_info};
		foreach(1..$quiz_no)	{
			print $file_info->[$_-1]->{add1}, $file_info->[$_-1]->{sign}, $file_info->[$_-1]->{add2}, "=", $file_info->[$_-1]->{try}->[0], "\n";
		}

		sub printTry	{
			while()
		}
	}
}, '.';

#print "yes" if -f "./homework_info.1559202376" ;

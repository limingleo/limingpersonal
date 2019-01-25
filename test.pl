use strict;
use warnings;

use Time::HiRes qw(gettimeofday tv_interval usleep); 

my ($hrs, $mins, $secs, $mils) = (0, 0, 0, 0);

for my $h (0..23) {
    for my $m (0..59) {
        for my $s (0..59) {
        		system("clear");
        		print "$h:$m:$s\n";
        		usleep(1000000);
        }
    }
}

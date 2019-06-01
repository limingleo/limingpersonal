require "./MyFunc.pl";
my @array = (1,1,2,3,4,5,64,4,5,5,3);
ArrayUniq(\@array);


sub mysub {
	print @_[0];
	print "\n";
	print @_[1];
	print "\n";
	print @_[2];
}


mysub(1,2,3);
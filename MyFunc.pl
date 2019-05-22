##  This is to get the maximum length of an array's elements  ####
sub ArrayMaxLength {
	my $max = 0;
	foreach(@_)
	{
		if(length($_) > $max)
		{
			$max = length($_);
		}
	}
	return $max;
}


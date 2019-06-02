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

sub ArrayUniq	{
	my $var = shift;
	my %tmp;
	@tmp{@$var} = (1..@$var);
	@$var = keys %tmp;
}

sub isComposite	{
	my $num = shift;
	my $count = -1;
	for my $i (1..int(sqrt $num))	{
		if ($num % $i == 0)	{
			$count++;
		}
	}
	return $count;
}

sub compositeElements	{
	my $num = shift;
	my @elements=();
	for my $i (2..int(sqrt $num))	{
		if($num % $i == 0)	{
			push @elements, $i;
			push @elements, $num/$i;
		}
	}
	return sort {$a <=> $b} @elements;
}

1;
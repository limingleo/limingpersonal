my @test = (
		{
			name => liming, 
			age => 36,
			child_name => ['niuniu', 'liuliu','liuson']
		}, 

		{
			name => liuqiao,
			age => 33,
			child_name => ['yangyi']
		}
	);


my @test2 = (
		[1,2,3], 
		[3,4,5,6,7], 
		[5,6,7]
	);

print scalar @{$test[0]{child_name}};
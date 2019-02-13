my %secConvertHash;

sub intDisp	{
	my $start = shift;
	my $end = shift;
	my $interval = $end - $start;
	$secConvertHash{'天'} = int($interval / 86400);
	$secConvertHash{'小时'} = int(int($interval % 86400) / 3600);
	$secConvertHash{'分钟'} = int(int(int($interval % 86400) % 3600) / 60);
	$secConvertHash{'秒'} = int(int(int($interval % 86400) % 3600) % 60);
}

intDisp(3,667745);

print $secConvertHash{'天'} . " 天 " . $secConvertHash{'小时'} . " 小时 "  . $secConvertHash{'分钟'} . " 分钟 " . $secConvertHash{'秒'} . " 秒";
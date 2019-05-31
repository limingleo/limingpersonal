use strict;
use warnings;
use Storable qw/nstore retrieve/;

## Defining variables ##
my @sign;
my @operand = (1..50);
my @operand_multiplication = (1..10);
my @quiz;
my $r_no = 0;
my $w_no = 0;
my @interval;
my %secConvertHash;
my $s_time = time();
my $e_time;
my $quiz_no = 5;
my $result_info = "hwinfo." . time();

## Printing time spent on the quiz in a readable format
sub intervalDisplay {
	if($secConvertHash{'天'}) {
		print $secConvertHash{'天'} . '天';
	}
	if($secConvertHash{'小时'}) {
		print $secConvertHash{'小时'} . '小时';
	}
	if($secConvertHash{'分钟'}) {
		print $secConvertHash{'分钟'} . '分钟';
	}
	if($secConvertHash{'秒'}) {
		print $secConvertHash{'秒'} . '秒';
	}
}

## Convert time spent on the quiz from seconds to days+hour+min+sec
sub intervalConvert {
	my @string;
	my $start = shift;
	my $end = shift;
	my $interval = $end - $start;
	$secConvertHash{'秒数'} = $interval;
	$secConvertHash{'天'} = int($interval / 86400);
	$secConvertHash{'小时'} = int(int($interval % 86400) / 3600);
	$secConvertHash{'分钟'} = int(int(int($interval % 86400) % 3600) / 60);
	$secConvertHash{'秒'} = int(int(int($interval % 86400) % 3600) % 60);
}

## Decide right or wrong for each quiz 
sub markRW {
	for(my $i = 0; $i < scalar@quiz; $i++) {
		next if $quiz[$i]{rw} eq '对';
		if($quiz[$i]{answer} eq $quiz[$i]{try}[-1]) {
			$quiz[$i]{rw} = '对';
		}
		else {
			$quiz[$i]{rw} = '错';
		}
	}
}

## Decide if fully correct or not 
sub sthWrong {
	for(my $i = 0; $i < scalar@quiz; $i++) {
		if($quiz[$i]{rw} eq '错') {
			return 1;
		}
	}
}

sub usage	{
	print "运行方法：\n";
	print "\$ perl $0 10  * 出10道题 *\n";
	print "\$ perl $0     * 出5道题  *\n";
	exit 1;
}

##  Main program starts here, accepting 1 or 0 arguments ##
foreach(@ARGV)	{
	$quiz_no = $_ if /^\d+$/;
	push @sign, '+' if /\+/;
	push @sign, '-' if /\-/;
	push @sign, '*' if /x/i;
	#push @sign, '/' if /\//;
}

if(@sign)	{
	my %tmp;
	@tmp{@sign} = (1..@sign);
	@sign = keys %tmp;
}
else	{
	@sign = ('+','-');
}

##clear screen according to different OS/shell
system("cls") if $^O =~ /Win32/i;
system("clear") if $^O =~ /msys/i;
system("clear") if $^O =~ /darwin/i;

## Review last time result
opendir DIR, '.' or die "Not able to open current directory\n";
my @dir_content = readdir(DIR);
close DIR;
my @result_files = sort { $b cmp $a } grep { -f && /hwinfo/ } @dir_content;
if(scalar @result_files)	{
	print "上次作业情况回顾：\n\n";
 	my $file_info = retrieve $result_files[0];
 	my $quiz_no = scalar @{$file_info};
 	for(my $i = 0; $i < $quiz_no; $i++)	{
 		my $quiz_len = length($file_info->[$i]->{num1} . $file_info->[$i]->{sign} . $file_info->[$i]->{num2});
 		for(my $j = 0; $j < scalar @{$file_info->[$i]->{try}}; $j++)	{
			my $rw = ($file_info->[$i]->{try}->[$j] == $file_info->[$i]->{answer})?"对":"错";
 			if($j == 0)	{
 				print sprintf "%-15s", $file_info->[$i]->{num1} . $file_info->[$i]->{sign} . $file_info->[$i]->{num2} . "=" . $file_info->[$i]->{try}->[$j];
				print sprintf "%25s", "--------> 花了$file_info->[$i]->{timespent}->[$j]秒 ($rw)\n";
 			}
 			else	{
				print  sprintf "%-15s", " " x $quiz_len . "=" . $file_info->[$i]->{try}->[$j];
				print sprintf "%25s", "--------> 花了$file_info->[$i]->{timespent}->[$j]秒 ($rw)\n"; 				
 			}
 		}
	}
}
else	{
	print "没有发现上次的作业文件\n";
}

print "\n\n";
## Generate quiz ##
foreach (1..$quiz_no) {
	my %quiz = (
	'num1' => $operand[int(rand(50))],
	'sign' => $sign[int(rand(scalar @sign))],
	'num2' => $operand[int(rand(50))],
	'answer' => '',
	'try' => [],
	'timespent' => [],
	'rw' => '',
	);	

# If multiplication, we should limit to single digit
	if($quiz{sign} eq '*')	{
		$quiz{num1} = $operand_multiplication[int(rand(10))],
		$quiz{num2} = $operand_multiplication[int(rand(10))],
	}

	push @quiz, {%quiz};

# Determining the right answer
	if($quiz[-1]{sign} eq '+') {
		$quiz[-1]{answer} = $quiz[-1]{num1} + $quiz[-1]{num2};
	}
	elsif($quiz[-1]{sign} eq '-') {
		$quiz[-1]{answer} = $quiz[-1]{num1} - $quiz[-1]{num2};
	}
	elsif($quiz[-1]{sign} eq '*') {
		$quiz[-1]{answer} = $quiz[-1]{num1} * $quiz[-1]{num2};
	}
	elsif($quiz[-1]{sign} eq '/') {	
		$quiz[-1]{answer} = $quiz[-1]{num1} / $quiz[-1]{num2};
	}
	else	{
		print "Invalid operating sign, exiting ...\n";
		exit 1;
	}
}

print "开始做作业啦，一共有${quiz_no}题\n";
print "-----------------------\n"; 

## First time to do homework, hopefully all correct for the 1st time. 
for(my $i = 0; $i < scalar@quiz; $i++) {	
	my $stime = time();
	my $j = $i + 1;
	print "第" . "$j" . "题:\n";
	print $quiz[$i]{num1} . $quiz[$i]{sign} . $quiz[$i]{num2} . "=";
	while(my $result = <STDIN>) {
		chomp $result;
		if($result !~ /^[+-]{0,1}[1-9]*\d+$/) {
			print "请输入数字，（答案允许开头一个正负号）:";
			next;
		}
		else {
			$result =~ s/^\+//;
			$quiz[$i]{try}[0] = int($result); 
			my $etime = time();
			$quiz[$i]{timespent}[0] = ($etime - $stime);
			last;
		}
	}
}

$e_time = time();
intervalConvert $s_time, $e_time;
print "\n作业做完花费了:";
intervalDisplay;

print "\n\n批改作业啦:\n";
markRW;
print "-------------------------------\n";
for(my $i = 0; $i < scalar@quiz; $i++) {	
	print sprintf "%-10s", $quiz[$i]{num1} . $quiz[$i]{sign} . $quiz[$i]{num2} . "=" . $quiz[$i]{try}[-1];
	print sprintf "%15s", "--------> $quiz[$i]{rw} ";
	print "花了$quiz[$i]{timespent}[0]秒". "\n";
}
print "-------------------------------\n\n";

for(my $i = 0; $i < scalar@quiz; $i++) {
	if($quiz[$i]{rw} eq '错')	{
		$w_no++;
	}
	else {
		$r_no++;
	}	
}

if($w_no != 0) {
	print "本次作业你得了: " . int(100*$r_no/scalar(@quiz)) . "分\n";
	while(sthWrong) {
		print "现在开始重做错了的题目吧\n";
		for(my $i = 0; $i < scalar@quiz; $i++) {
			my $stime = time();
			if($quiz[$i]{rw} eq '错')	{
				print $quiz[$i]{num1} . $quiz[$i]{sign} . $quiz[$i]{num2} . "=";
				while(my $result = <STDIN>) {
					chomp $result;
					if($result !~ /^[+-]{0,1}[1-9]*\d+$/) {
						print "请输入数字，（答案允许开头一个正负号）:";
						next;
					}
					else {
						$result =~ s/^\+//;
						my $try_len = scalar @{$quiz[$i]{try}};
						my $ts_len = scalar @{$quiz[$i]{timespent}};
						$quiz[$i]{try}[$try_len] = $result;
						my $etime = time();
						$quiz[$i]{timespent}[$ts_len] = ($etime - $stime);
						last;
					}
				}
			}
		}
		print "\n批改作业啦:\n";
		print "-------------------------------\n";
		for(my $i = 0; $i < scalar@quiz; $i++) {	
			if($quiz[$i]{rw} eq '错') {
				if($quiz[$i]{try}[-1] == $quiz[$i]{answer}) {
					$quiz[$i]{rw} = '对';
				}
				print sprintf "%-10s", $quiz[$i]{num1} . $quiz[$i]{sign} . $quiz[$i]{num2} . "=" . $quiz[$i]{try}[-1];
				print sprintf "%15s", "--------> $quiz[$i]{rw} ";
				print "花了$quiz[$i]{timespent}[-1]秒". "\n";
			}
		}
		print "-------------------------------\n\n";
	}
	$e_time = time();
	intervalConvert $s_time, $e_time;
	print "作业全部做对一共花费了:";
	intervalDisplay;
	print "\n";
}
else {
	print "好极了，满分，给你一个大大的ZAN\n";
	$e_time = time();
	intervalConvert $s_time, $e_time;
	print "一共花费了:";
	intervalDisplay;
	print "\n";
}

# Save homework infomation for next time review
nstore \@quiz, $result_info;

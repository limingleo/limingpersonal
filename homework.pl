use strict;
use warnings;
use Storable qw/nstore retrieve/;
use Data::Dumper;

my @sign = ('+','-');
my @operand = (1..50);
my @quizs;
my $r_no = 0;
my $w_no = 0;
my @interval;
my %secConvertHash;
my $s_time = time();
my $e_time;
my $quiz_no = 5;
my $result_info = "homework_info." . time();

# Printing time spent on the quiz in a readable format

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

# Convert time spent on the quiz from seconds to days+hour+min+sec

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

sub markRW {
	for(my $i = 0; $i < scalar@quizs; $i++) {
		if($quizs[$i]{answer} eq $quizs[$i]{try}[-1]) {
			$quizs[$i]{rw} = '对';
		}
		else {
			$quizs[$i]{rw} = '错';
		}
	}
}

sub sthWrong {
	for(my $i = 0; $i < scalar@quizs; $i++) {
		if($quizs[$i]{rw} eq '错') {
			return 1;
		}
	}
}

##  Main program starts here ##

foreach (1..$quiz_no) {
	my %quiz = (
	'add1' => $operand[int(rand(50))],
	'sign' => $sign[int(rand(2))],
	'add2' => $operand[int(rand(50))],
	'answer' => '',
	'try' => [],
	'timespent' => [],
	'rw' => '',
	);	
	push @quizs, {%quiz};
}

##  Auto generate the answers for each quiz ##

for(my $i = 0; $i < scalar@quizs; $i++) {
	if($quizs[$i]{sign} eq '+') {
		$quizs[$i]{answer} = $quizs[$i]{add1} + $quizs[$i]{add2};
	}
	else {
		$quizs[$i]{answer} = $quizs[$i]{add1} - $quizs[$i]{add2};
	}
}

print "开始做作业啦，一共有${quiz_no}题\n------------------\n"; 

for(my $i = 0; $i < scalar@quizs; $i++) {	
	my $stime = time();
	my $j = $i + 1;
	print "第" . "$j" . "题:\n";
	print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=";
	while(my $result = <STDIN>) {
		chomp $result;
		if($result !~ /^[+-]{0,1}[1-9]*\d+$/) {
			print "请输入数字，（答案允许开头一个正负号）:";
			next;
		}
		else {
			$result =~ s/^\+//;
			$quizs[$i]{try}[0] = $result; 
			my $etime = time();
			$quizs[$i]{timespent}[0] = ($etime - $stime);
			last;
		}
	}
}

markRW;
$e_time = time();
intervalConvert $s_time, $e_time;
print "作业做完花费了:";
intervalDisplay;

print "\n\n批改作业啦:\n";
print "-----------------------------\n";
for(my $i = 0; $i < scalar@quizs; $i++) {	
	print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=" . $quizs[$i]{try}[-1] . "  -------->" . $quizs[$i]{rw} . "   花了$quizs[$i]{timespent}[0]秒". "\n";
}

for(my $i = 0; $i < scalar@quizs; $i++) {
	if($quizs[$i]{rw} eq '错')	{
		$w_no++;
	}
	else {
		$r_no++;
	}	
}

if($w_no != 0) {
	print "本次作业你得了: " . int(100*$r_no/scalar(@quizs)) . "分\n";
	while(sthWrong) {
		print "现在开始重做错了的题目吧\n";
		for(my $i = 0; $i < scalar@quizs; $i++) {
			my $stime = time();
			if($quizs[$i]{rw} eq '错')	{
				print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=";
				while(my $result = <STDIN>) {
					chomp $result;
					if($result !~ /^[+-]{0,1}[1-9]*\d+$/) {
						print "请输入数字，（答案允许开头一个正负号）:";
						next;
					}
					else {
						$result =~ s/^\+//;
						my $try_len = scalar @{$quizs[$i]{try}};
						my $ts_len = scalar @{$quizs[$i]{timespent}};
						$quizs[$i]{try}[$try_len] = $result;
						my $etime = time();
						$quizs[$i]{timespent}[$ts_len] = ($etime - $stime);
						last;
					}
				}
			}
		}
		print "\n\n批改作业啦:\n";
		print "-----------------------------\n";
		for(my $i = 0; $i < scalar@quizs; $i++) {	
			if($quizs[$i]{rw} eq '错') {
				if($quizs[$i]{try}[-1] == $quizs[$i]{answer}) {
					$quizs[$i]{rw} = '对';
				}
				print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=" . $quizs[$i]{try}[-1] . "  -------->" . $quizs[$i]{rw} . "   花了$quizs[$i]{timespent}[-1]秒". "\n";
			}
		}
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

print Dumper(@quizs);

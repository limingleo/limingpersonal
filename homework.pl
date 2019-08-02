use strict;
use warnings;
use Storable qw/nstore retrieve/;
use Getopt::Std;

## Defining variables ##
my @sign;
my @operand = (1..50);
my @operand_multiplication = (1..9);
my @quiz;
my $r_no = 0;
my @interval;
my %secConvertHash;
my $s_time = time();
my $e_time;
my $quiz_no = 10;
my $result_info = "hwinfo." . time();
my $first = 0;

##clear screen according to different OS/shell
sub clearScreen {
	system("cls") if $^O =~ /Win32/i;			# Windows
	system("clear") if $^O =~ /msys/i;			# GIT bash
	system("clear") if $^O =~ /darwin/i;		# OSX
}

## Printing time spent on the quiz in a readable format
sub intervalDisplay {
	if($secConvertHash{'天'}) 	{		print $secConvertHash{'天'} . '天';	}
	if($secConvertHash{'小时'}) {		print $secConvertHash{'小时'} . '小时';	}
	if($secConvertHash{'分钟'}) {		print $secConvertHash{'分钟'} . '分钟';	}
	if($secConvertHash{'秒'}) 	{		print $secConvertHash{'秒'} . '秒';	}
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
	$first++;
	print "\n\n批改作业啦:\n";
	print "-------------------------------\n";
	for(my $i = 0; $i < scalar@quiz; $i++) {
		next if $quiz[$i]{rw} eq '对';
		if($quiz[$i]{answer} eq $quiz[$i]{try}[-1]) {
			$quiz[$i]{rw} = '对';
			$r_no++;
		}
		else {	$quiz[$i]{rw} = '错';	}
		print sprintf "%-10s", $quiz[$i]{num1} . $quiz[$i]{sign} . $quiz[$i]{num2} . "=" . $quiz[$i]{try}[-1];
		print sprintf "%15s", "--------> $quiz[$i]{rw} ";
		print "花了$quiz[$i]{timespent}[-1]秒". "\n";
	}
	print "-------------------------------\n\n";
	
	if($r_no == scalar@quiz && $first == 1)	{
		print "好极了，满分，给你一个大大的ZAN\n";
		nstore \@quiz, $result_info;
		exit 0;
	}
	else	{		print "本次作业累计得分: " . int(100*$r_no/scalar(@quiz)) . "分\n";		}
}

## Decide if fully correct or not 
sub sthWrong {
	for(my $i = 0; $i < scalar@quiz; $i++) {
		return 1 if $quiz[$i]{rw} eq '错';
	}
}

sub usage	{
	clearScreen;
	print "运行方法：\n";
	print "\$ perl $0          * 默认出10道题，仅有加减法  *\n";
	print "\$ perl $0 x/       * 出10道题，仅有乘除法      *\n";
	print "\$ perl $0 20       * 出20道题，仅有加减法      *\n";
	print "\$ perl $0 +-x/ 20  * 出20道题，有加减乘除法    *\n";
	print "\$ perl $0 -v 3     * 仅查看上3次作业完成情况   *\n";
	print "----------------------------------------------------------\n\n";
	print "按回车键继续";
	<STDIN>
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

sub dispResult	{
	my $count = shift;
	opendir DIR, '.' or die "Not able to open current directory\n";
	my @dir_content = readdir(DIR);
	close DIR;

	my @result_files = sort { $b cmp $a } grep { -f && /hwinfo/ } @dir_content;
	my $no_of_files = scalar @result_files;
	if($no_of_files)	{
		if($no_of_files < $count)	{	
			print "仅能显示过去$no_of_files次的作业情况，按回车继续\n";	
			$count = $no_of_files;
			<STDIN>
		}
		while($count--)	{
			clearScreen;
			my $hw_time = (split /\./, $result_files[$count])[-1];
			intervalConvert $hw_time, $s_time;
			print "作业情况回顾:\n---------------------------------\n做题时间：";
			intervalDisplay;
			print "之前\n";
			
		 	my $file_info = retrieve $result_files[$count];
		 	my $quiz_no = scalar @{$file_info};
		 	my $total_time = 0;

		 	foreach(@{$file_info})	{
		 		foreach(@{$_->{timespent}})	{
		 			$total_time += $_;
		 		}
		 	}

		 	print "题目总数：$quiz_no\n完成时间：";
		 	intervalConvert 0, $total_time;
		 	intervalDisplay;
		 	print "\n---------------------------------\n\n";

		 	for(my $i = 0; $i < $quiz_no; $i++)	{
		 		for(my $j = 0; $j < scalar @{$file_info->[$i]->{try}}; $j++)	{
					my $rw = ($file_info->[$i]->{try}->[$j] == $file_info->[$i]->{answer})?"对":"错";
		 			if($j == 0)	{
		 				print sprintf "%-3s", $file_info->[$i]->{num1};
		 				print $file_info->[$i]->{sign};
		 				print sprintf "%3s", $file_info->[$i]->{num2};
		 				print "  =  ";
		 				print sprintf "%3s", $file_info->[$i]->{try}->[$j];
						print sprintf "%-20s", "     --------> ";
						print sprintf "%-15s", "花了$file_info->[$i]->{timespent}->[$j]秒";
						print "($rw)\n";
		 			}
		 			else	{
						print sprintf "%-10s", " " x 9 . "=  ";
						print sprintf "%3s", $file_info->[$i]->{try}->[$j];
						print sprintf "%-20s", "     --------> ";
						print sprintf "%-15s", "花了$file_info->[$i]->{timespent}->[$j]秒";
						print "($rw)\n";
		 			}
		 		}
			}
			print "\n按回车键继续";
			<STDIN>
		}
	}
	else	{	print "没有发现上次完成的作业\n"; }
}

##  Main program starts here

our $opt_v;
getopts('v:');

if($opt_v)	{
	dispResult $opt_v;	
	exit 0;
}

usage if $#ARGV == -1;

foreach(@ARGV)	{
	$quiz_no = $_ if /^\d+$/;
	push @sign, '+' if /\+/;
	push @sign, '-' if /\-/;
	push @sign, 'x' if /x/i;
	push @sign, '÷' if /\//;
}

# To unique sign array
if(@sign)	{	ArrayUniq(\@sign);}
else	{	@sign = ('+','-');}

print "\n\n";
## Generate quiz and populate correct answers
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

	# If multiplication, would limit to single digit
	if($quiz{sign} eq 'x')	{
		$quiz{num1} = $operand_multiplication[int(rand(9))],
		$quiz{num2} = $operand_multiplication[int(rand(9))],
	}

	if($quiz{sign} eq '÷')	{
		while(1)	{
			$quiz{num1} = int(rand(98)+2);
			if(isComposite $quiz{num1})	{
				my @division = compositeElements $quiz{num1};
				$quiz{num2} = $division[int rand(scalar@division)];
				last;
			}
		}
	}

	push @quiz, {%quiz};

	# Determining the right answer
	if($quiz[-1]{sign} eq '+') 	  {		$quiz[-1]{answer} = $quiz[-1]{num1} + $quiz[-1]{num2};	}
	elsif($quiz[-1]{sign} eq '-') {		$quiz[-1]{answer} = $quiz[-1]{num1} - $quiz[-1]{num2};	}
	elsif($quiz[-1]{sign} eq 'x') {		$quiz[-1]{answer} = $quiz[-1]{num1} * $quiz[-1]{num2};	}
	elsif($quiz[-1]{sign} eq '÷') {		$quiz[-1]{answer} = $quiz[-1]{num1} / $quiz[-1]{num2};	}
	else						  {		print "Invalid operating sign, exiting ...\n"; exit 1;	}
}

# Display last one result by default
dispResult 1;
clearScreen;
print "开始做作业啦，一共有${quiz_no}题\n";
print "-------------------------\n"; 

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
markRW;

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
	markRW;
}

$e_time = time();
print "作业全部做对一共花费了:";
intervalConvert $s_time, $e_time;
intervalDisplay;
nstore \@quiz, $result_info;
print "\n";
# Depends on network availability, so better not enable this.
#print "Going to add file $result_info to git\n";
#system(qq/git add $result_info/);
#system(qq/git commit -m "added homework result $result_info"/);
#system("git push origin master");

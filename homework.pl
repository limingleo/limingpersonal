#!/usr/bin/perl -w
my @sign = ('+','-');
my @operand = (1..50);
my @quizs;
my $r_no = 0;
my $w_no = 0;

sub markRW {
	for(my $i = 0; $i < scalar@quizs; $i++) {
		if($quizs[$i]{answer} eq $quizs[$i]{try1}) {
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

foreach (1..10) {
	my %quiz = (
	'add1' => $operand[int(rand(50))],
	'sign' => $sign[int(rand(2))],
	'add2' => $operand[int(rand(50))],
	'answer' => '',
	'try1' => '',
	'try2' => '',
	'try3' => '',
	'rw' => '',
	);	
	push @quizs, {%quiz};
}

for(my $i = 0; $i < scalar@quizs; $i++) {
	if($quizs[$i]{sign} eq '+') {
		$quizs[$i]{answer} = $quizs[$i]{add1} + $quizs[$i]{add2};
	}
	else {
		$quizs[$i]{answer} = $quizs[$i]{add1} - $quizs[$i]{add2};
	}
}

print "开始做作业啦\n"; 
for(my $i = 0; $i < scalar@quizs; $i++) {	
	my $j = $i + 1;
	print "第" . "$j" . "题:\n";
	print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=";
	while(my $result = <STDIN>) {
		chomp $result;
		if($result !~ /(\+{0,1}|-)\d+$/) {
			print "请输入数字，不要输入乱七八糟的东西哦:";
			next;
		}
		else {
			$quizs[$i]{try1} = $result;
			last;
		}
	}
}

markRW;

print "\n\n批改作业啦:\n";
print "-----------------------------\n";
for(my $i = 0; $i < scalar@quizs; $i++) {	
	print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=" . $quizs[$i]{try1} . "-------->" . $quizs[$i]{rw} . "\n";
}

for(my $i = 0; $i < scalar@quizs; $i++) {
	if($quizs[$i]{rw} eq '错')	{
		$w_no++;
	}
	else {
		$r_no++;
	}	
}

if($w_no == 0) {
	print "好极了，满分，给你一个大大的👍\n";
}
else {
	print "本次作业你得了: " . int(100*$r_no/scalar(@quizs)) . "分\n";
	while(sthWrong) {
		print "现在开始重做错了的题目吧\n";
		for(my $i = 0; $i < scalar@quizs; $i++) {
			if($quizs[$i]{rw} eq '错')	{
				print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=";
				while(my $result = <STDIN>) {
					chomp $result;
					if($result !~ /(\+{0,1}|-)\d+$/) {
						print "请输入数字，不要输入乱七八糟的东西哦:";
						next;
					}
					else {
						$quizs[$i]{try1} = $result;
						last;
					}
				}
			}
		}
		print "\n\n批改作业啦:\n";
		print "-----------------------------\n";
		for(my $i = 0; $i < scalar@quizs; $i++) {	
			if($quizs[$i]{rw} eq '错') {
				if($quizs[$i]{try1} == $quizs[$i]{answer}) {
					$quizs[$i]{rw} = '对';
				}
				print $quizs[$i]{add1} . $quizs[$i]{sign} . $quizs[$i]{add2} . "=" . $quizs[$i]{try1} . "-------->" . $quizs[$i]{rw} . "\n";
			}		
		}
	}
}


 my $file = "test.pl";
 system('git status');
 system("git add $file");
 system(qq/git commit -m "committed $file"/);
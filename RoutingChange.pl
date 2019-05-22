#!/ms/dist/perl5/bin/perl5.8

# $Header$

use strict;
use MSDW::Version
	'Spreadsheet-ParseExcel' => '0.32',		# Spreadsheet::ParseExcel::FmtDefault used by Spreadsheet::ParseExcel
	'OLE-Storage_Lite' => '0.19', 			# Used by Spreadsheet::ParseExcel
	'IO-stringy' => '2.110',				# IO::Scalar may be3 used by Spreadsheet::ParseExcel
	;
use Scalar::Util; # core
use Spreadsheet::ParseExcel;
use Getopt::Std;
use POSIX qw/strftime/;

use MSDW::Version
	'DBD-Sybase' => '1.09-oc15.0.0.20',
	'DBI' => '1.608', # Used by DBD::Sybase
	'syb/sgp' => '1.0',
	;

use DBI qw(:sql_types);
use sybGetPrinc qw(sybGetPrinc);
use Carp;

my $trader;
my $backupTrader;
my $defaultTrader;
my $defaultTrader2;
my $response;
my $exch;

my %traderTick;
my %tickTraders;
my %traderColumn;
my %traderColumnHK = (
						akwok => [1,3,5],
						morriben => [8,10],
						wonandy => [13,15,17],
						pheylew => [20,22,24],
#	 					etfdesk => [22],
						);

my %traderColumnSG = (
						jasony => [1],
						lkoh => [4,6],
						goughash => [9,11]
						);

#ric2ts("0001.HK");
# Get OPT #
our($opt_r, $opt_i, $opt_o, $opt_f, $opt_y, $opt_n);

getopts('r:i:o:f:yn');

#print $opt_r, $opt_i, $opt_o, $opt_f, $opt_y;

sub IsSubset(\@\@)	
{
	my %b;
	@b{@{+pop}} = ();
	exists $b{$_} || return 0 for @{+pop};
	return 1;
}

my $file;
if($opt_f)	
{
	$file = $opt_f;
}

unless($opt_n || $file && ($opt_o || $opt_i))	
{
	print "Usage: $0 [-r Region HK|SI] [-i Trader IN] [-o Trader OUT] [-f Config File] [-y Force]\n";
#	print "Example: $0 -r HK -i akwok,bridgeo,chiujac,graftonj,mholland -f 'config/HK Sector Lists - 2010 Sep.xls'\n";
	print "Example: $0 -r HK -i akwok -f 'config/HK Sector List - 2010 Sep.xls'  # akwok is on leave.\n";
	print "Example: $0 -r SI -o lkoh -f 'config/SG Sector List - 2010 Sep.xls'  # lhoh is on leave.\n";	
	print "Example: $0 -r HK -n -f 'config/HK Sector List - 2010 Sep.xls'  # Refresh the route table for HK !\n";
	exit 1;
}

if($opt_r eq "HK")	
{ 
	%traderColumn = %traderColumnHK; 
	$defaultTrader = "pheylew"; 
	$defaultTrader2 = "wonandy"; 
}
elsif($opt_r eq "SI") 
{ 
	%traderColumn = %traderColumnSG; 
	$defaultTrader = "lkoh"; 
	$defaultTrader2 = "goughash"; 
}
else 
{
	die "Region = HK|SI only !"; 
}

# print $opt_r . keys(%traderColumn) . "|" . keys(%traderColumnHK) . "|" . keys(%traderColumnSG) . "|";

printf("Regino :\t[%s]\n", $opt_r);
printf("Default :\t[%s]\n", $defaultTrader);
printf("Default2 :\t[%s]\n", $defaultTrader2);
printf("Trader IN :\t[%s]\n", $opt_i);
printf("Trader OUT :\t[%s]\n", $opt_o);
printf("Config File :\t[%s]\n", $opt_f);
printf("FORCE :\t[%s]\n", $opt_y==1?'TRUE':'FALSE');
printf("\nPlease press enter to confirm the detail ...");
if(!$opt_y)	
{ 
	my $response = <STDIN>; 
}

my @tradersIN = split(',', $opt_i);
my @tradersOUT = split(',', $opt_o);

#print "A subset of B: " . IsSubset(@tradersIN, @tradersOUT) . "\n";
#print "B subset of A: " . IsSubset(@tradersOUT, @tradersIN) . "\n";

if($opt_i && !IsSubset(@tradersIN, @tradersOUT) && $opt_o && !IsSubset(@tradersOUT, @tradersIN))	
{
	print "Trader IN and OUT are overlapped !\n";
	exit 1;
}

# Parse Excel #

my $excel = Spreadsheet::ParseExcel::Workbook->Parse($file);
my $sheet = $excel->Worksheet("Route List");

foreach $trader (keys %traderColumn)	
{
	printf("\n== %s ==\n", $trader);
	for my $col (@{$traderColumn{$trader}})	
	{
		my $cell = $sheet->{Cells}[0][$col];
		my $row = 1;
		my $hasData = 1;
		my $tick = "";
		while($hasData)	
		{
			$cell = $sheet->{Cells}[$row][$col];
			if($cell && $cell->{Val})	
			{
				my $ric = $cell->{Val};
				$ric =~ tr/a-z/A-Z/;
				#$ric =~ /([0-9]+)\.[hH][kK]/;
				#my $tick = sprintf("%04d", $1);
				if($ric =~ /.{1,5}\.[A-Z]{2,3}/)	
				{
					if(substr($ric,0,1) ne "*")	
					{
						$tick = ric2ts($ric,$trader);
					}
					else	
					{
						$tick = $ric;
					}
					#printf("ric=%s; tick=%s\t", $ric, $tick);
					printf("%s|%s|%s|%s\t", $ric, $tick, $trader, $backupTrader);
					#printf("tick [%s]; Primary:[%s]; Backup:[%s]\n", $tick, $trader, $backupTrader);
					# select distinct m.traderSymbol from p2..P2Market m where m.ric = "0001.HK"  -- "STXPx.SI"
					if(!$tick)	
					{
						printf("Cell[$row][$col]=$ric: tick [%s] is not valid. Please check the spreadsheet.\n", $tick);
						$tick = substr($ric, 0, index($ric,'.',0));
						$traderTick{$trader}{$tick} = $backupTrader;
						$tickTraders{$tick} = "$trader|$backupTrader";
					}
					elsif($tickTraders{$tick})	
					{
						printf("Cell[$row][$col]=$ric: tick [%s] has been duplicated. Please check the spreadsheet.\n", $tick);
					}
					else	
					{
						$traderTick{$trader}{$tick} = $backupTrader;
						$tickTraders{$tick} = "$trader|$backupTrader";
					}
				}
				else	
				{
					print "Cell[$row][$col] is not RIC: $ric\n";
					exit;
				}
			}
			else	
			{
				$cell = $sheet->{Cells}[$row][$col-1];
				if($cell && $cell->{Val})	
				{
					my $sector = $cell->{Val};
					$sector =~ /\(([a-z]+)\)/;
					$backupTrader = $1;
					## printf("Backup trader is [%s]\n", $backupTrader);
					# if (not exists $traderColumn{$backupTrader})	{
					#	printf("Backup trader [%s] is invalid. Please check the spreadsheet.\n", $backupTrader);
					#}
				}
				else	
				{
					$hasData = 0;		## no data, proceed to next column
				}
			}
			$row++;
		}
	}
}

system('rm -f ./log/*_tick_route.sql');
my $prefix = './log/'.substr($opt_f,7).($opt_o ? '-'.$opt_o : '').($opt_i ? '-'.$opt_i : '');

# Gen SQL #
open(FILE, '>', $prefix.'.txt') or die $!;
open(CHECK_SQL, '>', $prefix.'.check.sql') or die $!;
open(CHECK_SQL2, '>', $prefix.'.check2.sql') or die $!;
open(UPDATE_SQL, '>', $prefix.'.update.sql') or die $!;
open(VERIFY_SQL, '>', $prefix.'.verify.sql') or die $!;
open(REFRESH_SQL, '>', $prefix.'.refresh.sql') or die $!;

foreach my $tick (keys %tickTraders)	
{
	my $trader = $tickTraders{$tick};
	$trader = substr($trader,0,index($trader, '|', 0));
	if(substr($tick,0,1) eq "*")	
	{
		$exch = substr($tick,index($tick,'.',0)+1,2);
		$exch =~ tr/a-z/A-Z/;
		print REFRESH_SQL sprintf("update tick_route set route = '%s' where exch ='%s' and tick = '*'\n", $trader, $exch, $backupTrader);
	}
	else	
	{
		print REFRESH_SQL sprintf("update tick_route set route = '%s where exch = '%s' adn tick = '%s'\n", $trader, $opt_r, $tick);
	}
}

for $trader (@tradersIN)	
{
	if($trader eq $defaultTrader)	
	{
		print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '*'\n", $defaultTrader, $opt_r);
	}
	unless($traderTick{$trader})	
	{
		printf("Invalid trader [%s]\n", $trader);
		die;
	}
	foreach my $tick (sort keys %{$traderTick{$trader}})	
	{
		$backupTrader = $traderTick{$trader}{$tick};
		if(substr($tick,0,1) eq "*")	
		{
			$exch = substr($tick, index($tick,'.',0)+1,2);
			$exch =~ tr/a-z/A-Z/;
			print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '*' and route = '%s'\n", $trader, $exch, $backupTrader);
		}
		else	
		{
			print FILE sprintf("%s %s %s\n", $tick, $trader, $backupTrader);
			print CHECK_SQL sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s' and tick = '%s'\n", $tick, $backupTrader, $opt_r, $tick, $backupTrader);
			print CHECK_SQL2 sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s', and tick = '%s'\n", $tick, $trader, $opt_r, $tick);
			print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '%s' and route = '%s'\n", $tick, $opt_r, $tick, $backupTrader);
			print VERIFY_SQL sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s' and tick = '%s' and route = '%s'\n", $tick, $trader, $opt_r, $tick, $trader);
		}
	}
}

for $trader (@tradersOUT)	
{
	if($trader eq $defaultTrader)	
	{
		print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '*'\n", $defaultTrader2, $opt_r);
	}
	unless($traderTick{$trader})	
	{
		printf("Invalid trader [%s]\n", $trader);
		die;
	}
	foreach my $tick (sort keys %{$traderTick{$trader}})	
	{
		$backupTrader = $traderTick{$trader}{$tick};
		if(substr($tick,0,1) eq "*")	
		{
			$exch = substr($tick, index($tick,'.',0)+1,2);
			$exch =~ tr/a-z/A-Z/;
			print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '*' and route = '%s'\n", $backupTrader, $exch, $trader);
		}
		else	
		{
			print FILE sprintf("%s %s %s\n", $tick, $trader, $backupTrader);
			print CHECK_SQL sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s' and tick = '%s' and route = '%s'\n", $tick, $trader, $opt_r, $tick, $trader);
			print CHECK_SQL2 sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s' and tick = '%s'\n", $tick, $backupTrader, $opt_r, $tick);
			print UPDATE_SQL sprintf("update tick_route set route = '%s' where exch = '%s' and tick = '%s' and route = '%s'\n", $backupTrader, $opt_r, $tick, $trader);
			print VERIFY_SQL sprintf("select '%s', '%s', count(1) from tick_route where exch = '%s' and tick = '%s' and route = '%s'\n", $tick, $backupTrader, $opt_r, $tick, $backupTrader);
		}
	}
}

print CHECK_SQL sprintf("go\n");
print CHECK_SQL2 sprintf("go\n");
print UPDATE_SQL sprintf("go\n");
print VERIFY_SQL sprintf("go\n");
print REFRESH_SQL sprintf("go\n");

close FILE;
close CHECK_SQL;
close CHECK_SQL2;
close UPDATE_SQL;
close VERIFY_SQL;
close REFRESH_SQL;

system('cp \''.$prefix.'.check.sql\' '.'./log/check_tick_route.sql');
system('cp \''.$prefix.'.check2.sql\' '.'./log/check_tick_route2.sql');
system('cp \''.$prefix.'.update.sql\' '.'./log/update_tick_route.sql');
system('cp \''.$prefix.'.verify.sql\' '.'./log/verify_tick_route.sql');
system('cp \''.$prefix.'.refresh.sql\' '.'./log/refresh_tick_route.sql');

if($opt_n)	
{
	print "\n";
	print "## STEP 0: REFRESH_SQL\N";
	system('less ./log/refresh_tick_route.sql');
	system('ls -l ./log/refresh_tick_route.sql');
	system('wc ./log/refresh_tick_route.sql');
	die "Here is the sql.";
}

print "\n";
print "## STEP 1: count_tick_route.sh - PRE CHECK ##\n";
my $status = system("./count_tick_route.sh | tee \'". $prefix . ".pre.txt\'");
if(($status >>= 8) != 0)	
{
	die "Failed to run ./count_tick_route.sh"; 
}

print "\nPlease press enter to check the sql !\nNo. of lines: ";
system('wc -l '.'./log/update_tick_route.sql');
if(!opt_y)	
{
	my $response = <STDIN>;
}
if(!$opt_y)	
{
	system('less '.'./log/update_tick_route.sql');
}

print "\n";
print "## STEP 2: DB backup ##\n";
print "\nINFO:\t Backup in progress now ...";
my $today = strftime "%Y%m%d", localtime(time);
print $today;
my $status = system("kbcp omwdb..tick_route out tick_route.$today -S HKP_ETSDB -c");
if(($status >>=8) !=0)	
{
	die "Failed to run bcp"; 
}
print "\nINFO:\t You can find the DB Backup here: log/HKP_ETSDB.omwdb." .$today . ".bcp\n";
print "\n";
print "## STEP 3: run_tick_route.sh ##\n";
print "\n WARNING:\T PLEASE CONFIRM YOU WANT TO RUN ./run_tick_route.sh ? \t [YES/NO] : ";
if(!$opt_y)	
{
	my $response = <STDIN>;
	unless($response =~ /^YES$/)	
	{
		print "\nONLY \"YES\" IS VALID\n\n";
		exit;
	}
}
print "\n";
my $status = system("./run_tick_route.sh $opt_r $opt_o $opt_y");
if(($status >>= 8) != 0)	
{
	die "Failed to run ./run_tick_route.sh";
}
print "\n";
print "## STEP 4: count_tick_route.sh - POST CHECK ##\n";
my $status = system("./count_tick_route.sh | tee \'" . $prefix . ".post.txt\'");
if(($status >>= 8) != 0)	
{
	die "Failed to run ./refreshProdSvc.ksh";
}

print "\n";
print "## STEP 5: refreshProdSvc.ksh ##\n";
print "\n WARNING: \tPLEASE CONFIRM YOU WANT TO RUN ./refreshProdSvc.ksh ?\t[YES/NO] : ";
if(!opt_y)	
{
	my $response = <STDIN>;
	unless ($response =~ /^YES$/)	{
		print "\nONLY \"YES\" IS VALID\n\n";
		exit;
	}
}

print "\n";
my $status = system("./refreshProdSvc.ksh");
if(($status >>= 8) != 0)	
{
	die "Failed to run ./refreshProdSvc.ksh";
}

exit 0;

sub ric2ts
{
	my $ric = shift @_;
	my $tick = "";
	my $trader = shift @_;
	my $server = 'HKP_ETSDB';
	my $database = 'omwdb';
	my $kerbprincipal = sybGetPrinc($server);
	my $user = "hkomw_syts";
	my $passwd = "hkomw_syts";

	my $dbh;
	my $sth;

	$dbh = DBI->connect("dbi:Sybase:server=$server;database=$database;kerberos=$kerbprincipal", $user, $passwd) || carp "Connection failed";
	$sth = $dbh->prepare("select distinct m.traderSymbol from p2..P2Market m where m.ric = '" . $ric . "'");
	$sth->execute();

	my $result = $str->fetchrow_arrayref;
	$tick = @$result[0];
	$sth->finish;
	$sth = $dbh->prepare("SELECT * FROM tick_route where exch in ('HK', 'SI') and tick = '" . $tick . "'"); 
	$sth->execute();

	my @tmp = $sth->fetchrow_arrayref;
	if(!@tmp)
	{
		print $ric . " NOT Exist !!\n";
		print "insert into tick_route values ('" . @$result[0] . "', '$trader', NULL, NULL, 'hks', 'S', '$opt_r', NULL, NULL, NULL, NULL)\n";
	}

	$sth->finish;

	return @$result[0];
}
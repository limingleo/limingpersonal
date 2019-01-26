#!/usr/bin/perl
use 5.010;

$/ = ".\n";
while (<>)
{
	next if !s/\b([a-z]+)((?:\s|<[^>]+>)+)(\1\b)/\e[7m$1\e[m$2\e[7m$3\e[m/ig;
	s/^(?:[^\e]*\n)+//mg;
	s/^/$ARGV: /mg;
	print;
}

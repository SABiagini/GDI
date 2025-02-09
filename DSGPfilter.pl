#!/usr/bin/perl

use warnings;
use strict;

my $input = $ARGV[0];
my $keep = $ARGV[1];
my $remove = $ARGV[2];
my $GP = $ARGV[3];

open (IN, "$input") or die ("ERROR input file $input\n");
open (OUT, ">$keep") or die ("ERROR keep file generation\n");
open (OUT2, ">$remove") or die ("ERROR remove file generation\n");

while (my $line = <IN>) {
	chomp $line;
	my @split=split(/\t/,$line);
	if ($split[1] eq "0/0" && $split[2] >= $GP && $split[5]<0.1) {
		print OUT "$split[0]\n";
	}
	elsif ($split[1] eq "1/1" && $split[4] >= $GP && $split[5]>1.8) {
		print OUT "$split[0]\n";
	}
	elsif ($split[1] eq "0/1" && $split[3] >= $GP && $split[5]>0.8 && $split[5]<1.01) {
		print OUT "$split[0]\n";
	}
	else {print OUT2 "$split[0]\n";
	}
}
close IN;
close OUT;

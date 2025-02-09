#!/usr/bin/perl

use strict;
use warnings;

my $input_file = shift @ARGV;
open(my $input_fh, '<', $input_file) or die "Can't open' input file' $input_file': $!";
my $output_file = shift @ARGV;
open(my $output_fh, '>', $output_file) or die "Can't open output file' $output_file': $!";my %counts;

while (my $line = <$input_fh>) {
	chomp $line;
	$counts{$line}++;
}
close($input_fh);

foreach my $key (sort keys %counts) {
	print $output_fh "$counts{$key}\t$key\n";
}

close($output_fh);

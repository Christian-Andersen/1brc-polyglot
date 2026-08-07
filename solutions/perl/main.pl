#!/usr/bin/perl
use strict;
use warnings;

my %stats;
open my $fh, '<', '../../data/measurements.txt' or die "cannot open: $!";
while (my $line = <$fh>) {
    my ($city, $temp) = split /;/, $line;
    (my $t = $temp) =~ s/\.//g;
    my $value = int $t;
    if (exists $stats{$city}) {
        my $s = $stats{$city};
        $s->[0] = $value if $value < $s->[0];
        $s->[1] = $value if $value > $s->[1];
        $s->[2] += $value;
        $s->[3]++;
    } else {
        $stats{$city} = [ $value, $value, $value, 1 ];
    }
}
close $fh;

for my $city (sort keys %stats) {
    my ($mn, $mx, $tot, $cnt) = @{ $stats{$city} };
    print "$city\t$mn\t$mx\t$tot\t$cnt\n";
}

my %stats;
for open("../../data/measurements.txt", :r).lines -> $line {
    my $semi = $line.index(';');
    my $city = $line.substr(0, $semi);
    my $t = parse($line, $semi + 1);
    if %stats{$city}:exists {
        my $e = %stats{$city};
        $e[0] = $t if $t < $e[0];
        $e[1] = $t if $t > $e[1];
        $e[2] += $t;
        $e[3]++;
    } else {
        %stats{$city} = [$t, $t, $t, 1];
    }
}

sub parse($line, $start) returns Int {
    my $i = $start;
    my $neg = 0;
    $neg = 1, $i++ if $line.substr($i, 1) eq '-';
    my $v = 0;
    while $line.substr($i, 1) ne '.' { $v = $v * 10 + ($line.substr($i, 1).ord - 48); $i++; }
    $i++;
    my $tenths = $v * 10 + ($line.substr($i, 1).ord - 48);
    return $neg ?? -$tenths !! $tenths;
}

for %stats.keys.sort -> $city {
    my $e = %stats{$city};
    say "$city\t$e[0]\t$e[1]\t$e[2]\t$e[3]";
}
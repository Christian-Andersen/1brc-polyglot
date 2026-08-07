<?php
$stats = [];
$fh = fopen("../../data/measurements.txt", "r");
while (($line = fgets($fh)) !== false) {
    $line = rtrim($line, "\n");
    $parts = explode(";", $line);
    $city = $parts[0];
    $temp = (int) str_replace(".", "", $parts[1]);
    if (isset($stats[$city])) {
        $s = $stats[$city];
        $s[0] = min($s[0], $temp);
        $s[1] = max($s[1], $temp);
        $s[2] += $temp;
        $s[3]++;
        $stats[$city] = $s;
    } else {
        $stats[$city] = [$temp, $temp, $temp, 1];
    }
}
fclose($fh);
ksort($stats);
foreach ($stats as $city => $s) {
    echo $city . "\t" . $s[0] . "\t" . $s[1] . "\t" . $s[2] . "\t" . $s[3] . "\n";
}

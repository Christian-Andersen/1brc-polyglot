$stats = @{}
foreach ($line in [System.IO.File]::ReadLines("../../data/measurements.txt")) {
    $semi = $line.IndexOf(';')
    $city = $line.Substring(0, $semi)
    $temp = [long]($line.Substring($semi + 1).Replace(".", ""))
    if ($stats.ContainsKey($city)) {
        $s = $stats[$city]
        if ($temp -lt $s[0]) { $s[0] = $temp }
        if ($temp -gt $s[1]) { $s[1] = $temp }
        $s[2] += $temp
        $s[3] += 1
        $stats[$city] = $s
    } else {
        $stats[$city] = [object[]]@($temp, $temp, $temp, 1)
    }
}
$keys = @($stats.Keys)
[Array]::Sort($keys, [System.StringComparer]::Ordinal)
foreach ($city in $keys) {
    $s = $stats[$city]
    Write-Output ("{0}`t{1}`t{2}`t{3}`t{4}" -f $city, $s[0], $s[1], $s[2], $s[3])
}

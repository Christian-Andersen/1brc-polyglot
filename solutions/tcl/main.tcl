set fh [open "../../data/measurements.txt" r]
while {[gets $fh line] >= 0} {
    set semi [string first ";" $line]
    set city [string range $line 0 [expr {$semi - 1}]]
    set temp [string map {. ""} [string range $line [expr {$semi + 1}] end]]
    scan $temp "%d" value
    if {[info exists stats($city)]} {
        set s $stats($city)
        lset s 0 [expr {[lindex $s 0] < $value ? [lindex $s 0] : $value}]
        lset s 1 [expr {[lindex $s 1] > $value ? [lindex $s 1] : $value}]
        lset s 2 [expr {[lindex $s 2] + $value}]
        lset s 3 [expr {[lindex $s 3] + 1}]
        set stats($city) $s
    } else {
        set stats($city) [list $value $value $value 1]
    }
}
close $fh

foreach city [lsort [array names stats]] {
    lassign $stats($city) mn mx tot cnt
    puts "$city\t$mn\t$mx\t$tot\t$cnt"
}

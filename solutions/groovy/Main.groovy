def file = new File("../../data/measurements.txt")
def map = [:]
file.eachLine { line, n ->
    if (line.length() == 0) return
    def semi = line.indexOf(';')
    def city = line.substring(0, semi)
    def t = parseTemp(line, semi + 1)
    def e = map[city]
    if (e == null) {
        map[city] = [t, t, t, 1L]
    } else {
        if (t < e[0]) e[0] = t
        if (t > e[1]) e[1] = t
        e[2] += t
        e[3] += 1L
    }
}

static int parseTemp(String s, int start) {
    int i = start
    int neg = 0
    if (s.charAt(i) == (char) 45) { neg = 1; i++ }
    int v = 0
    while (s.charAt(i) != (char) 46) { v = v * 10 + (s.charAt(i) - 48); i++ }
    i++
    int tenths = v * 10 + (s.charAt(i) - 48)
    return neg == 1 ? -tenths : tenths
}

map.keySet().sort().each { city ->
    def e = map[city]
    println "${city}\t${e[0]}\t${e[1]}\t${e[2]}\t${e[3]}"
}
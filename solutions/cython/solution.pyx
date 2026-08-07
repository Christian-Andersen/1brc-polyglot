# cython: language_level=3

def parse_temp(bytes line, Py_ssize_t semi):
    cdef Py_ssize_t i = semi + 1
    cdef int neg = 0
    cdef int v = 0
    cdef int t
    cdef Py_ssize_t n = len(line)
    if i < n and line[i] == 45:
        neg = 1
        i += 1
    while i < n and line[i] != 46:
        v = v * 10 + (line[i] - 48)
        i += 1
    i += 1
    t = v * 10 + (line[i] - 48)
    return -t if neg else t

def solve(path):
    cdef dict stats = {}
    cdef bytes line
    cdef str city
    cdef int mn, mx, tot
    cdef long long tmp
    with open(path, "rb") as f:
        for line in f:
            line = line.rstrip(b"\n")
            semi = line.index(b";")
            city = line[:semi].decode("utf-8")
            t = parse_temp(line, semi)
            e = stats.get(city)
            if e is None:
                stats[city] = [t, t, t, 1]
            else:
                if t < e[0]: e[0] = t
                if t > e[1]: e[1] = t
                e[2] += t
                e[3] += 1
    return stats
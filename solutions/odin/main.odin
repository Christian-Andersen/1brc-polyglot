package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

Stats :: struct {
    min:   int,
    max:   int,
    total: int,
    count: int,
}

main :: proc() {
    data, err := os.read_entire_file("../../data/measurements.txt", context.allocator)
    if err != nil {
        fmt.eprintln("failed to read measurements")
        return
    }
    defer delete(data)

    stats := make(map[string]Stats)
    defer delete(stats)

    text := string(data)
    for line in strings.split_lines_iterator(&text) {
        if line == "" {
            continue
        }
        idx := strings.index_byte(line, ';')
        city := line[:idx]
        temp_s, _ := strings.replace_all(line[idx + 1:], ".", "")
        temp, _ := strconv.parse_int(temp_s)
        delete(temp_s)

        if s, exists := stats[city]; exists {
            s.min = min(s.min, temp)
            s.max = max(s.max, temp)
            s.total += temp
            s.count += 1
            stats[city] = s
        } else {
            stats[city] = Stats{min = temp, max = temp, total = temp, count = 1}
        }
    }

    keys := make([]string, len(stats))
    defer delete(keys)
    i := 0
    for k in stats {
        keys[i] = k
        i += 1
    }
    slice.sort(keys)

    for k in keys {
        s := stats[k]
        fmt.printf("%s\t%d\t%d\t%d\t%d\n", k, s.min, s.max, s.total, s.count)
    }
}

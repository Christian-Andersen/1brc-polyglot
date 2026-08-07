import os

struct Stats {
mut:
	min   i64
	max   i64
	total i64
	count i64
}

fn main() {
	lines := os.read_lines('../../data/measurements.txt') or {
		eprintln('cannot read measurements file')
		exit(1)
	}
	mut data := map[string]Stats{}
	for line in lines {
		parts := line.split(';')
		city := parts[0]
		temp := parts[1].replace('.', '').i64()
		if city in data {
			mut s := data[city]
			if temp < s.min {
				s.min = temp
			}
			if temp > s.max {
				s.max = temp
			}
			s.total += temp
			s.count += 1
			data[city] = s
		} else {
			data[city] = Stats{
				min:   temp
				max:   temp
				total: temp
				count: 1
			}
		}
	}
	mut keys := data.keys()
	keys.sort()
	for city in keys {
		s := data[city]
		println('${city}\t${s.min}\t${s.max}\t${s.total}\t${s.count}')
	}
}

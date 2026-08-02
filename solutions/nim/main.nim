import std/strutils
import std/tables
import std/algorithm

type
  Stats = object
    min: int
    max: int
    total: int
    count: int

var stats = initTable[string, Stats]()

for line in lines("../../data/measurements.txt"):
  let parts = line.split(";")
  let city = parts[0]
  let temp = parseInt(parts[1].replace(".", ""))
  if stats.hasKey(city):
    var s = stats[city]
    s.min = min(s.min, temp)
    s.max = max(s.max, temp)
    s.total += temp
    s.count += 1
    stats[city] = s
  else:
    stats[city] = Stats(min: temp, max: temp, total: temp, count: 1)

var cities = newSeq[string]()
for city in stats.keys:
  cities.add(city)
cities.sort()
for city in cities:
  let stats = stats[city]
  echo city, "\t", stats.min, "\t", stats.max, "\t", stats.total, "\t", stats.count

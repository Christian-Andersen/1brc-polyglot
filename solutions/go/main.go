package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"slices"
	"strconv"
	"strings"
)

type Stats struct {
	min   int
	max   int
	total int
	count int
}

const DataPath = "../../data/measurements.txt"

func sortedKeys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return keys
}

func main() {
	file, err := os.Open(DataPath)
	if err != nil {
		log.Fatalf("Failed to open file: %s", err)
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	data := make(map[string]Stats)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, ";")
		city := parts[0]
		temp, err := strconv.Atoi(strings.Replace(parts[1], ".", "", 1))
		if err != nil {
			log.Fatalf("Failed to convert to int: %s", err)
		}
		stats, exists := data[city]
		if exists {
			stats.min = min(stats.min, temp)
			stats.max = max(stats.max, temp)
			stats.total += temp
			stats.count += 1
			data[city] = stats
		} else {
			data[city] = Stats{
				min:   temp,
				max:   temp,
				total: temp,
				count: 1,
			}
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("Error while reading file: %s", err)
	}
	for _, k := range sortedKeys(data) {
		stats := data[k]
		fmt.Printf("%s\t%d\t%d\t%d\t%d\n", k, stats.min, stats.max, stats.total, stats.count)
	}
}

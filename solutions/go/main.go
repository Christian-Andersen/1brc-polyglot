package main

import (
	"bufio"
	"fmt"
	"log"
	"math"
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

func roundTowardsPositive(x float64) float64 {
	return math.Floor(x+0.5) / 10
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
	output := "{"
	for _, k := range sortedKeys(data) {
		stats := data[k]
		output += fmt.Sprintf("%s=%.1f/%.1f/%.1f, ", k, roundTowardsPositive(float64(stats.min)), roundTowardsPositive(float64(stats.total)/float64(stats.count)), roundTowardsPositive(float64(stats.max)))
	}
	output = output[:len(output)-2] + "}"
	fmt.Print(output)
}

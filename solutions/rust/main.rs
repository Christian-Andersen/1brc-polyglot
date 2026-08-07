use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

struct Stats {
    min: i32,
    max: i32,
    total: i32,
    count: i32,
}

fn main() {
    let file = File::open("../../data/measurements.txt").unwrap();
    let reader = BufReader::new(file);
    let mut stats: HashMap<String, Stats> = HashMap::new();
    for line in reader.lines() {
        let line = line.unwrap();
        if let Some((city, temp)) = line.split_once(';') {
            let temp: i32 = temp.replace('.', "").parse().unwrap();
            if let Some(entry) = stats.get_mut(city) {
                entry.min = std::cmp::min(entry.min, temp);
                entry.max = std::cmp::max(entry.max, temp);
                entry.total += temp;
                entry.count += 1;
            } else {
                stats.insert(
                    String::from(city),
                    Stats {
                        min: temp,
                        max: temp,
                        total: temp,
                        count: 1,
                    },
                );
            }
        }
    }
    let mut sorted_keys: Vec<&String> = stats.keys().collect();
    sorted_keys.sort();
    for key in &sorted_keys {
        let value = &stats[*key];
        println!(
            "{}\t{}\t{}\t{}\t{}",
            key, value.min, value.max, value.total, value.count
        );
    }
}

use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

struct Stats {
    min: i32,
    max: i32,
    total: i32,
    count: i32,
}

fn round_towards_positive(x: f64) -> f64 {
    (x + 0.5).floor() / 10.
}

fn main() {
    let file = File::open("../../data/measurements.txt").unwrap();
    let reader = BufReader::new(file);
    let mut stats: HashMap<String, Stats> = HashMap::new();
    for line in reader.lines() {
        let line = line.unwrap();
        if let Some((city, temp)) = line.split_once(';') {
            let temp: i32 = temp.replace('.', "").parse().unwrap();
            let entry = stats.entry(String::from(city)).or_insert(Stats {
                min: i32::MAX,
                max: i32::MIN,
                total: 0,
                count: 0,
            });
            entry.min = std::cmp::min(entry.min, temp);
            entry.max = std::cmp::max(entry.max, temp);
            entry.total += temp;
            entry.count += 1;
        }
    }
    let mut sorted_keys: Vec<&String> = stats.keys().collect();
    sorted_keys.sort();
    let len = sorted_keys.len();
    print!("{{");
    for (i, &key) in sorted_keys.iter().enumerate() {
        let value = &stats[key];
        print!(
            "{}={:.1}/{:.1}/{:.1}",
            key,
            round_towards_positive(f64::from(value.min)),
            round_towards_positive(f64::from(value.total) / f64::from(value.count)),
            round_towards_positive(f64::from(value.max))
        );
        if (i + 1) < len {
            print!(", ");
        }
    }
    print!("}}");
}

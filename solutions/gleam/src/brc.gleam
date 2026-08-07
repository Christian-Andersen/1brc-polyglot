import gleam/int
import gleam/dict
import gleam/list
import gleam/string
import gleam/bit_array
import gleam/io
import gleam/result

pub type Entry {
  Entry(min: Int, max: Int, sum: Int, count: Int)
}

@external(erlang, "file", "read_file")
fn read_file(path: String) -> Result(BitArray, BitArray)

pub fn main() {
  let assert Ok(bits) = read_file("../../data/measurements.txt")
  let assert Ok(content) = bit_array.to_string(bits)
  let lines = string.split(content, "\n")
  let stats = list.fold(lines, dict.new(), process_line)
  let keys = dict.keys(stats) |> list.sort(string.compare)
  list.each(keys, fn(city) {
    let Entry(min: mn, max: mx, sum: tot, count: cnt) = dict.get(stats, city)
    |> result.unwrap(Entry(0, 0, 0, 0))
    io.println(city <> "\t" <> int.to_string(mn) <> "\t" <> int.to_string(mx) <> "\t" <> int.to_string(tot) <> "\t" <> int.to_string(cnt))
  })
}

fn process_line(stats: dict.Dict(String, Entry), line: String) -> dict.Dict(String, Entry) {
  case line {
    "" -> stats
    _ -> {
      let assert Ok(#(city, temp_string)) = string.split_once(line, ";")
      let t = parse_temp(temp_string)
      case dict.get(stats, city) {
        Ok(Entry(min: mn, max: mx, sum: tot, count: cnt)) -> {
          let mn = case t < mn {
            True -> t
            False -> mn
          }
          let mx = case t > mx {
            True -> t
            False -> mx
          }
          dict.insert(stats, city, Entry(mn, mx, tot + t, cnt + 1))
        }
        Error(_) -> dict.insert(stats, city, Entry(t, t, t, 1))
      }
    }
  }
}

fn parse_temp(s: String) -> Int {
  let assert Ok(#(whole, fract)) = string.split_once(s, ".")
  let assert Ok(w) = int.parse(whole)
  let assert Ok(f) = int.parse(fract)
  let value = int.absolute_value(w) * 10 + f
  case string.starts_with(s, "-") {
    True -> value * -1
    False -> value
  }
}

class Main {
  static function parseTemp(s:String, start:Int):Int {
    var i = start;
    var neg = 0;
    if (s.charCodeAt(i) == 45) { neg = 1; i++; }
    var v = 0;
    while (s.charCodeAt(i) != 46) { v = v * 10 + (s.charCodeAt(i) - 48); i++; }
    i++;
    var tenths = v * 10 + (s.charCodeAt(i) - 48);
    return neg == 1 ? -tenths : tenths;
  }

  static function main() {
    var lines = sys.io.File.getContent("../../data/measurements.txt").split("\n");
    var map = new Map<String, Array<Int>>();
    for (line in lines) {
      if (line.length == 0) continue;
      var semi = line.indexOf(";");
      var city = line.substr(0, semi);
      var t = parseTemp(line, semi + 1);
      var e = map.get(city);
      if (e == null) {
        map.set(city, [t, t, t, 1]);
      } else {
        if (t < e[0]) e[0] = t;
        if (t > e[1]) e[1] = t;
        e[2] += t;
        e[3]++;
      }
    }
    var keys = [for (k in map.keys()) k];
    keys.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    for (city in keys) {
      var e = map.get(city);
      Sys.println(city + "\t" + e[0] + "\t" + e[1] + "\t" + e[2] + "\t" + e[3]);
    }
  }
}
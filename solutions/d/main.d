import std.algorithm;
import std.conv;
import std.stdio;
import std.string;

void main() {
    long[string] mn, mx, total, cnt;
    foreach (line; File("../../data/measurements.txt").byLine) {
        string s = line.idup;
        auto semi = s.indexOf(';');
        string city = s[0 .. semi];
        string temp = s[semi + 1 .. $];
        temp = temp.replace(".", "");
        long value = temp.to!long;
        if (city in total) {
            if (value < mn[city]) mn[city] = value;
            if (value > mx[city]) mx[city] = value;
            total[city] += value;
            cnt[city] += 1;
        } else {
            mn[city] = value;
            mx[city] = value;
            total[city] = value;
            cnt[city] = 1;
        }
    }
    string[] keys = total.keys;
    keys.sort();
    foreach (city; keys)
        writefln("%s\t%d\t%d\t%d\t%d", city, mn[city], mx[city], total[city], cnt[city]);
}

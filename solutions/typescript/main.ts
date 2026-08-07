const fs = await import("fs");
const data = fs.readFileSync("../../data/measurements.txt", "utf8");
const lines = data.split("\n");
const map = new Map();

function parseTemp(s, start) {
  let i = start;
  let neg = false;
  if (s.charCodeAt(i) === 45) { neg = true; i++; }
  let v = 0;
  while (s.charCodeAt(i) !== 46) { v = v * 10 + (s.charCodeAt(i) - 48); i++; }
  i++;
  const tenths = v * 10 + (s.charCodeAt(i) - 48);
  return neg ? -tenths : tenths;
}

for (const line of lines) {
  if (line.length === 0) continue;
  const semi = line.indexOf(";");
  const city = line.slice(0, semi);
  const t = parseTemp(line, semi + 1);
  const e = map.get(city);
  if (e) {
    if (t < e[0]) e[0] = t;
    if (t > e[1]) e[1] = t;
    e[2] += t;
    e[3] += 1;
  } else {
    map.set(city, [t, t, t, 1]);
  }
}

const cities = [...map.keys()].sort();
for (const c of cities) {
  const [mn, mx, tot, cnt] = map.get(c);
  console.log(`${c}\t${mn}\t${mx}\t${tot}\t${cnt}`);
}
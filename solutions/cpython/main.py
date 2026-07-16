from collections import defaultdict
from pathlib import Path
from statistics import mean

DATA_PATH = Path("../data/measurements.txt")


def main() -> int:
    data = defaultdict(list)
    with DATA_PATH.open("r") as f:
        for line in f:
            city, temp = line.strip().split(";")
            data[city].append(float(temp))
    s = "{"
    for city in sorted(data):
        s += f"{city}={min(data[city]):.1f}/{mean(data[city]):.1f}/{max(data[city]):.1f}, "
    s = s[:-2] + "}"
    print(s)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

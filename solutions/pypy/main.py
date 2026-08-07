from pathlib import Path
from typing import NamedTuple

DATA_PATH = Path("../../data/measurements.txt")


class Stats(NamedTuple):
    min: int
    max: int
    total: int
    count: int


def main() -> int:
    data = {}
    with DATA_PATH.open("r") as f:
        for line in f:
            city, temp = line.strip().split(";")
            temp = int(temp.replace(".", ""))
            if city in data:
                s = data[city]
                data[city] = Stats(
                    min=min(s.min, temp),
                    max=max(s.max, temp),
                    total=s.total + temp,
                    count=s.count + 1,
                )
            else:
                data[city] = Stats(min=temp, max=temp, total=temp, count=1)
    for city in sorted(data):
        stats = data[city]
        print(f"{city}\t{stats.min}\t{stats.max}\t{stats.total}\t{stats.count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

import math
from collections import defaultdict
from pathlib import Path
from typing import NamedTuple

DATA_PATH = Path("../../data/measurements.txt")


class Stats(NamedTuple):
    min: int = 1000
    max: int = -1000
    total: int = 0
    count: int = 0


def round_toward_positive(value: float) -> float:
    return math.floor(value + 0.5) / 10.0


def main() -> int:
    data = defaultdict(Stats)
    with DATA_PATH.open("r") as f:
        for line in f:
            city, temp = line.strip().split(";")
            temp = int(temp.replace(".", ""))
            data[city] = Stats(
                min=min(data[city].min, temp),
                max=max(data[city].max, temp),
                total=data[city].total + temp,
                count=data[city].count + 1,
            )
    s = "{"
    for city in sorted(data):
        s += f"{city}={round_toward_positive(data[city].min)}/{round_toward_positive(data[city].total / data[city].count)}/{round_toward_positive(data[city].max)}, "  # noqa: E501
    s = s[:-2] + "}"
    print(s)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

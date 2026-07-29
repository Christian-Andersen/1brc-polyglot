#
#  Copyright 2023 The original authors
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

import sys
import polars as pl

FILE = "./measurements.txt"


def main():
    df = pl.read_csv(
        FILE,
        separator=";",
        has_header=False,
        new_columns=["station", "value"],
        schema={"station": pl.Utf8, "value": pl.Utf8},
    )

    # Convert temperature string to tenths-of-a-degree integer
    # e.g. "12.3" -> 123, "-4.5" -> -45
    # We remove the decimal point and parse as int, which is equivalent to multiplying by 10
    df = df.with_columns(
        pl.col("value").str.replace(".", "", literal=True).cast(pl.Int64).alias("tenths")
    )

    result = (
        df.group_by("station")
        .agg(
            pl.col("tenths").min().alias("min_tenths"),
            pl.col("tenths").max().alias("max_tenths"),
            pl.col("tenths").sum().alias("total_tenths"),
            pl.col("tenths").count().alias("count"),
        )
        .sort("station")
    )

    # Write TSV to stdout
    # Format: city\tmin_tenths\tmax_tenths\ttotal_tenths\tcount
    for row in result.iter_rows():
        station, min_t, max_t, total_t, count = row
        sys.stdout.write(f"{station}\t{min_t}\t{max_t}\t{total_t}\t{count}\n")


if __name__ == "__main__":
    main()

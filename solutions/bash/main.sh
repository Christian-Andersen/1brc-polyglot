#!/usr/bin/env bash
set -euo pipefail

declare -A min max total count

while IFS=';' read -r city temp; do
    IFS='.' read -r w f <<< "$temp"
    if [[ $w == -* ]]; then value=$(( ( ${w#-} * 10 + f ) * -1 )); else value=$(( w * 10 + f )); fi
    if [[ -z "${total[$city]+x}" ]]; then
        min[$city]=$value
        max[$city]=$value
        total[$city]=$value
        count[$city]=1
    else
        if (( value < min[$city] )); then min[$city]=$value; fi
        if (( value > max[$city] )); then max[$city]=$value; fi
        total[$city]=$(( total[$city] + value ))
        count[$city]=$(( count[$city] + 1 ))
    fi
done < "../../data/measurements.txt"

for city in "${!total[@]}"; do
    printf '%s\n' "$city"
done | LC_ALL=C sort | while read -r city; do
    printf '%s\t%s\t%s\t%s\t%s\n' "$city" "${min[$city]}" "${max[$city]}" "${total[$city]}" "${count[$city]}"
done

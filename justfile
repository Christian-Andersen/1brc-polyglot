set dotenv-load

alias c := check
alias r := run

[private]
default:
    @just --choose

check:
    prek run --all-files

run:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in ./solutions/*/; do
      (
        cd "$dir"
        echo "Running tests for $(basename "$dir")..."
        just run | diff --ignore-all-space ../../data/solution.txt -
      )
    done

benchmark:
    #!/usr/bin/env bash
    set -euo pipefail
    args=()
    args+=(--warmup 1)
    for dir in ./solutions/*/; do
      lang=$(basename "$dir")
      args+=(--command-name "$lang" "just --justfile ${dir}justfile run")
    done
    hyperfine "${args[@]}"

data power="9":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ./data/measurements/ ./data/solutions/
    echo '*' > ./data/.gitignore
    FILENAME="1e{{ power }}.txt"
    ROWS=$((10**{{ power }}))
    if [ ! -f "./data/measurements/${FILENAME}" ]; then
        echo "--> ${FILENAME} not found. Generating ${ROWS} measurements..."
        rm -f ./measurements.txt
        java ./CreateMeasurements.java ${ROWS}
        java ./CalculateAverage_baseline.java > "./data/solutions/${FILENAME}"
        mv "./measurements.txt" "./data/measurements/${FILENAME}"
    else
        echo "--> ${FILENAME} already exists. Skipping heavy generation step."
    fi
    echo "--> Swapping symlinks to target ${FILENAME}..."
    ln -sf "measurements/${FILENAME}" "./data/measurements.txt"
    ln -sf "solutions/${FILENAME}" "./data/solution.txt"

default:
    @just --list

data power="9":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ./data/measurements/ ./data/solutions/
    echo '*' > ./data/.gitignore
    FILENAME="1e{{power}}.txt"
    ROWS=$((10**{{power}}))
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

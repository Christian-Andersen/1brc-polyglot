default:
    @just --list

# Prepare data and symlinks inside the ./data directory (defaults to 1B rows)
data power="9":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ./data/measurements/ ./data/solutions/
    echo '*' > ./data/.gitignore

    FILENAME="1e{{power}}.txt"
    ROWS=$((10**{{power}}))

    # 1. Generate the data only if it doesn't exist yet
    if [ ! -f "./data/measurements/${FILENAME}" ]; then
        echo "--> ${FILENAME} not found. Generating ${ROWS} measurements..."

        # Defensive cleanup in case a stray file left over in root
        rm -f ./measurements.txt

        java ./CreateMeasurements.java ${ROWS}
        java ./CalculateAverage_baseline.java > "./data/solutions/${FILENAME}"
        mv "./measurements.txt" "./data/measurements/${FILENAME}"
    else
        echo "--> ${FILENAME} already exists. Skipping heavy generation step."
    fi

    # 2. Update the active symlinks inside the ./data folder
    echo "--> Swapping symlinks to target ${FILENAME}..."
    ln -sf "measurements/${FILENAME}" "./data/measurements.txt"
    ln -sf "solutions/${FILENAME}" "./data/solution.txt"

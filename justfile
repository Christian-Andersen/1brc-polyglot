set dotenv-load
N_POWER := env("N_POWER", "9")

alias c := check
alias r := run

[private]
default:
    @just --choose

check:
    prek run --all-files

run: data
    #!/usr/bin/env bash
    set -euo pipefail

    # Resolve the symlink to the absolute path of the actual file
    SOLUTION_FILE=$(realpath "./data/solution.txt")

    # Helper function to format single-line 1BRC output into one station per line
    format_output() {
      sed 's/^{//; s/}$//; s/, /\n/g'
    }

    for dir in ./solutions/*/; do
      (
        cd "$dir"
        stderr_file=$(mktemp)
        trap 'rm -f "$stderr_file"' EXIT
        set +e
        actual_output=$(just run 2>"$stderr_file")
        exit_code=$?
        set -e
        if [ $exit_code -ne 0 ]; then
          echo "❌ $(basename "$dir") crashed (Exit Code: $exit_code):"
          cat "$stderr_file"
          echo "----------------------------------------"
          continue
        fi
        set +e
        diff_output=$(diff -u --color=always <(format_output < "$SOLUTION_FILE") <(echo "$actual_output" | format_output))
        diff_code=$?
        set -e
        if [ $diff_code -eq 1 ]; then
          echo "❌ $(basename "$dir") has differences:"
          echo "$diff_output"
          echo "----------------------------------------"
        elif [ $diff_code -gt 1 ]; then
          echo "⚠️ Error: diff failed to run on $(basename "$dir")"
          echo "----------------------------------------"
        fi
      )
    done

benchmark: data
    #!/usr/bin/env bash
    set -euo pipefail
    args=()
    args+=(--warmup 1)
    for dir in ./solutions/*/; do
      lang=$(basename "$dir")
      args+=(--command-name "$lang" "just --justfile ${dir}justfile run")
    done
    hyperfine "${args[@]}"

data:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ./data/measurements/ ./data/solutions/
    echo '*' > ./data/.gitignore
    FILENAME="1e{{ N_POWER }}.txt"
    ROWS=$((10**{{ N_POWER }}))
    if [ ! -f "./data/measurements/${FILENAME}" ]; then
        echo "--> ${FILENAME} not found. Generating ${ROWS} measurements..."
        rm -f ./measurements.txt
        java ./CreateMeasurements.java ${ROWS}
        java ./CalculateAverage_baseline.java > "./data/solutions/${FILENAME}"
        mv "./measurements.txt" "./data/measurements/${FILENAME}"
    fi
    ln -sf "measurements/${FILENAME}" "./data/measurements.txt"
    ln -sf "solutions/${FILENAME}" "./data/solution.txt"

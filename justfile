set dotenv-load

alias c := check
alias r := run

[private]
default:
    @just --list

# lint/format all project files
check:
    prek run --all-files

# run all solutions against current data
run:
    python main.py run

# benchmark all solutions (optional: warmup iterations)
benchmark *ARGS:
    python main.py benchmark {{ ARGS }}

# generate measurement data if missing
data:
    python main.py data

# run all solutions at ascending N_POWER levels
sweep:
    python main.py sweep

set dotenv-load

alias c := check
alias r := run

[private]
default:
    @just --list

# lint/format all project files
check:
    prek run --all-files

# run all solutions against current data (optional substring filter, e.g. "just run zig")
run *FILTER:
    python main.py run {{ FILTER }}

# benchmark all solutions (optional: warmup iterations)
benchmark *ARGS:
    python main.py benchmark {{ ARGS }}

# generate measurement data if missing
data:
    python main.py data

# run all solutions at ascending N_POWER levels
sweep:
    python main.py sweep

# regenerate solutions.md and link it from README.md (optional: warmup iterations filter)
readme *ARGS:
    python main.py readme {{ ARGS }}

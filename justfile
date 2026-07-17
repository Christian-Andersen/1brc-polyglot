set dotenv-load

alias c := check
alias r := run

[private]
default:
    @just --choose

check:
    prek run --all-files

run:
    python main.py run

benchmark *ARGS:
    python main.py benchmark {{ ARGS }}

data:
    python main.py data

sweep:
    python main.py sweep

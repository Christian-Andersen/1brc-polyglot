set dotenv-load

alias c := check
alias r := run

[private]
default:
    @just --list

@bootstrap:
    (cd solutions/bun && [ -d "node_modules" ] || bun install --frozen-lockfile)
    (cd solutions/nodejs && [ -d "node_modules" ] || npm ci --no-fund)

# lint/format all project files
check: bootstrap
    prek run --all-files

# run all solutions against current data
run: bootstrap
    python main.py run

# benchmark all solutions (optional: warmup iterations)
benchmark *ARGS: bootstrap
    python main.py benchmark {{ ARGS }}

# generate measurement data if missing
data: bootstrap
    python main.py data

# run all solutions at ascending N_POWER levels
sweep: bootstrap
    python main.py sweep

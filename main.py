import difflib
import math
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

ROOT = Path(__file__).resolve().parent
SOLUTIONS_DIR = ROOT / "solutions"
DATA_DIR = ROOT / "data"

console = Console()

N_POWER = int(os.environ.get("N_POWER", "9"))


def ensure_data():
    measurements_dir = DATA_DIR / "measurements"
    solutions_dir = DATA_DIR / "solutions"
    measurements_dir.mkdir(parents=True, exist_ok=True)
    solutions_dir.mkdir(parents=True, exist_ok=True)

    (DATA_DIR / ".gitignore").write_text("*\n")

    filename = f"1e{N_POWER}.txt"
    rows = 10**N_POWER

    measurement_file = measurements_dir / filename
    solution_file = solutions_dir / filename

    if not measurement_file.exists():
        console.print(f"[yellow]--> {filename} not found. Generating {rows} measurements...[/yellow]")
        (ROOT / "measurements.txt").unlink(missing_ok=True)
        subprocess.run(
            ["java", str(ROOT / "CreateMeasurements.java"), str(rows)],
            cwd=ROOT,
            check=True,
        )
        with open(solution_file, "w") as f:
            subprocess.run(
                ["java", str(ROOT / "CalculateAverage_baseline.java")],
                cwd=ROOT,
                check=True,
                stdout=f,
            )
        shutil.move(str(ROOT / "measurements.txt"), str(measurement_file))

    for name, target in [
        ("measurements.txt", f"measurements/{filename}"),
        ("solution.txt", f"solutions/{filename}"),
    ]:
        link = DATA_DIR / name
        link.unlink(missing_ok=True)
        link.symlink_to(target)


def format_output(text: str) -> list[str]:
    stripped = text.strip()
    if stripped.startswith("{"):
        stripped = stripped[1:]
    if stripped.endswith("}"):
        stripped = stripped[:-1]
    return sorted(line.strip() for line in stripped.split(", ") if line.strip())


def run_all() -> bool:
    ensure_data()

    solution_text = (DATA_DIR / "solution.txt").read_text()
    expected = format_output(solution_text)

    all_ok = True
    for dir in sorted(SOLUTIONS_DIR.iterdir()):
        if not dir.is_dir():
            continue
        lang = dir.name
        try:
            result = subprocess.run(
                ["just", "run"],
                cwd=dir,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                console.print(
                    Panel(
                        f"[bold red]crashed (Exit Code: {result.returncode})[/bold red]\n{result.stderr}",
                        title=f"[red]{lang}[/red]",
                        border_style="red",
                    )
                )
                all_ok = False
                continue

            actual = format_output(result.stdout)
            if actual != expected:
                diff = difflib.unified_diff(
                    expected,
                    actual,
                    fromfile="data/solution.txt",
                    tofile=f"{lang}/output",
                )
                console.print(
                    Panel(
                        f"[bold red]has differences[/bold red]\n{''.join(diff)}",
                        title=f"[red]{lang}[/red]",
                        border_style="red",
                    )
                )
                all_ok = False
            else:
                console.print(
                    Panel(
                        "[bold green]OK[/bold green]",
                        title=f"[green]{lang}[/green]",
                        border_style="green",
                    )
                )
        except Exception as e:
            console.print(
                Panel(
                    f"[bold red]error: {e}[/bold red]",
                    title=f"[red]{lang}[/red]",
                    border_style="red",
                )
            )
            all_ok = False
    return all_ok


def benchmark(warmup: int, iterations: int):
    ensure_data()

    dirs = sorted(d for d in SOLUTIONS_DIR.iterdir() if d.is_dir())
    if not dirs:
        console.print("[red]No solution directories found.[/red]")
        return

    console.print(f"[cyan]Benchmarking {len(dirs)} solutions ({warmup} warmup, {iterations} iterations)...[/cyan]")

    results: dict[str, dict[str, float]] = {}

    for dir in dirs:
        lang = dir.name
        times: list[float] = []

        for i in range(warmup + iterations):
            start = time.perf_counter()
            subprocess.run(
                ["just", "run"],
                cwd=dir,
                capture_output=True,
            )
            elapsed = time.perf_counter() - start
            if i >= warmup:
                times.append(elapsed)

        mean = sum(times) / len(times)
        results[lang] = {
            "min": min(times),
            "max": max(times),
            "mean": mean,
            "stddev": (math.sqrt(sum((t - mean) ** 2 for t in times) / len(times)) if len(times) > 1 else 0.0),
        }

    table = Table(title="Benchmark Results")
    table.add_column("Language", style="cyan")
    table.add_column("Min", justify="right")
    table.add_column("Mean", justify="right")
    table.add_column("Max", justify="right")
    table.add_column("Stddev", justify="right")

    for lang, r in sorted(results.items(), key=lambda x: x[1]["mean"]):
        table.add_row(
            lang,
            f"{r['min']:.4f}s",
            f"{r['mean']:.4f}s",
            f"{r['max']:.4f}s",
            f"{r['stddev']:.4f}s",
        )

    console.print(table)


def data():
    ensure_data()
    console.print("[green]Data ready.[/green]")


def sweep():
    global N_POWER
    for power in range(1, 10):
        console.print(f"\n[bold cyan]=== N_POWER={power} ({10**power} rows) ===[/bold cyan]")
        N_POWER = power
        if not run_all():
            console.print(f"[bold red]FAILED at N_POWER={power}, aborting.[/bold red]")
            raise SystemExit(1)


COMMANDS = {
    "run": run_all,
    "benchmark": benchmark,
    "data": data,
    "sweep": sweep,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"usage: main.py {{{', '.join(COMMANDS)}}}")
        raise SystemExit(1)

    cmd = sys.argv[1]
    if cmd == "benchmark":
        warmup = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        iterations = int(sys.argv[3]) if len(sys.argv) > 3 else 3
        benchmark(warmup, iterations)
    else:
        COMMANDS[cmd]()  # ty:ignore[missing-argument]


if __name__ == "__main__":
    main()

import concurrent.futures
import math
import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import NamedTuple

from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table

ROOT = Path(__file__).resolve().parent
SOLUTIONS_DIR = ROOT / "solutions"
DATA_DIR = ROOT / "data"

console = Console()

N_POWER = int(os.environ.get("N_POWER", "9"))
PARALLEL = os.environ.get("PARALLEL", "1") == "1"
print_lock = threading.Lock()


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
        console.print(f"[yellow]--> {filename} not found. Generating {rows:,} measurements...[/yellow]")
        subprocess.run(
            [sys.executable, str(ROOT / "create_measurements.py"), str(rows)],
            cwd=DATA_DIR,
            check=True,
        )
        shutil.move(str(DATA_DIR / "measurements.txt"), str(measurement_file))

        # Create measurements symlink before running baseline
        measurements_link = DATA_DIR / "measurements.txt"
        measurements_link.unlink(missing_ok=True)
        measurements_link.symlink_to(f"measurements/{filename}")

        with open(solution_file, "w") as f:
            subprocess.run(
                [sys.executable, str(ROOT / "calculate_average_baseline.py")],
                cwd=DATA_DIR,
                check=True,
                stdout=f,
            )

    for name, target in [
        ("measurements.txt", f"measurements/{filename}"),
        ("solution.tsv", f"solutions/{filename}"),
    ]:
        link = DATA_DIR / name
        link.unlink(missing_ok=True)
        link.symlink_to(target)


class SolutionResult(NamedTuple):
    lang: str
    elapsed: float | None
    ok: bool
    panel: Panel


class BenchmarkStats(NamedTuple):
    min: float
    max: float
    mean: float
    stddev: float


def _run_solution(dir: Path, expected_lines: list[str]) -> SolutionResult:
    lang = dir.name
    try:
        subprocess.run(
            ["just", "build"],
            cwd=dir,
            capture_output=True,
        )

        start = time.perf_counter()
        result = subprocess.run(
            ["just", "bench"],
            cwd=dir,
            capture_output=True,
            text=True,
        )
        elapsed = time.perf_counter() - start

        if result.returncode != 0:
            return SolutionResult(
                lang,
                elapsed,
                False,
                Panel(
                    f"[bold red]crashed (Exit Code: {result.returncode})[/bold red]\n{result.stderr}",
                    title=f"[red]{lang}[/red]",
                    border_style="red",
                ),
            )

        actual_lines = result.stdout.rstrip("\n").split("\n")

        if actual_lines != expected_lines:
            first_diff = None
            for i, (e, a) in enumerate(zip(expected_lines, actual_lines)):
                if e != a:
                    first_diff = i
                    break
            if first_diff is None and len(actual_lines) != len(expected_lines):
                first_diff = min(len(expected_lines), len(actual_lines))

            detail = f"expected {len(expected_lines)} lines, got {len(actual_lines)}"
            if first_diff is not None:
                exp_line = expected_lines[first_diff] if first_diff < len(expected_lines) else "<missing>"
                act_line = actual_lines[first_diff] if first_diff < len(actual_lines) else "<missing>"
                detail += f"\nfirst diff at line {first_diff + 1}:\n  expected: [red]{exp_line}[/red]\n  actual:   [green]{act_line}[/green]"

            return SolutionResult(
                lang,
                elapsed,
                False,
                Panel(
                    f"[bold red]has differences[/bold red]\n{detail}",
                    title=f"[red]{lang}[/red]",
                    border_style="red",
                ),
            )

        return SolutionResult(
            lang,
            elapsed,
            True,
            Panel(
                f"[bold green]OK - {elapsed:.3f}s[/bold green]",
                title=f"[green]{lang}[/green]",
                border_style="green",
            ),
        )
    except Exception as e:
        return SolutionResult(
            lang,
            None,
            False,
            Panel(
                f"[bold red]error: {e}[/bold red]",
                title=f"[red]{lang}[/red]",
                border_style="red",
            ),
        )


def _build_table(results: list[SolutionResult]) -> Table:
    table = Table(title="Results")
    table.add_column("#", justify="right", style="dim")
    table.add_column("Language", style="cyan")
    table.add_column("Time", justify="right")
    table.add_column("Status")
    for i, r in enumerate(results, 1):
        table.add_row(
            str(i),
            r.lang,
            f"{r.elapsed:.3f}s" if r.elapsed is not None else "—",
            "[green]OK[/green]" if r.ok else "[red]FAIL[/red]",
        )
    return table


def run_all() -> bool:
    ensure_data()

    solution_text = (DATA_DIR / "solution.tsv").read_text()
    expected_lines = solution_text.rstrip("\n").split("\n")

    dirs = sorted(d for d in SOLUTIONS_DIR.iterdir() if d.is_dir())

    console.print(f"[cyan]Running {len(dirs)} solutions (N_POWER={N_POWER}, {10**N_POWER:,} rows)...[/cyan]")

    results: list[SolutionResult] = []
    table = _build_table(results)

    def add_result(r: SolutionResult):
        results.append(r)
        results.sort(key=lambda x: (x.elapsed if x.elapsed is not None else float("inf"), x.lang))
        live.update(_build_table(results))

    with Live(table, refresh_per_second=10, vertical_overflow="visible") as live:
        if PARALLEL:
            with concurrent.futures.ThreadPoolExecutor() as pool:
                futures = {pool.submit(_run_solution, d, expected_lines): d for d in dirs}
                for future in concurrent.futures.as_completed(futures):
                    with print_lock:
                        add_result(future.result())
        else:
            for d in dirs:
                add_result(_run_solution(d, expected_lines))

    errors = [r.lang for r in results if not r.ok]
    if errors:
        for r in results:
            if not r.ok:
                console.print(r.panel)
        console.print(f"\n[bold red]Errors in: {', '.join(errors)}[/bold red]")

    return not errors


def benchmark(warmup: int, iterations: int):
    ensure_data()

    dirs = sorted(d for d in SOLUTIONS_DIR.iterdir() if d.is_dir())
    if not dirs:
        console.print("[red]No solution directories found.[/red]")
        return

    console.print(
        f"[cyan]Benchmarking {len(dirs)} solutions (N_POWER={N_POWER}, {10**N_POWER:,} rows, {warmup} warmup, {iterations} iterations)...[/cyan]"
    )

    results: dict[str, BenchmarkStats] = {}

    def _bench_solution(dir: Path) -> tuple[str, BenchmarkStats]:
        lang = dir.name
        times: list[float] = []

        subprocess.run(
            ["just", "build"],
            cwd=dir,
            capture_output=True,
        )

        for i in range(warmup + iterations):
            start = time.perf_counter()
            subprocess.run(
                ["just", "bench"],
                cwd=dir,
                capture_output=True,
            )
            elapsed = time.perf_counter() - start
            if i >= warmup:
                times.append(elapsed)

        mean = sum(times) / len(times)
        return lang, BenchmarkStats(
            min=min(times),
            max=max(times),
            mean=mean,
            stddev=(math.sqrt(sum((t - mean) ** 2 for t in times) / len(times)) if len(times) > 1 else 0.0),
        )

    if PARALLEL:
        with concurrent.futures.ThreadPoolExecutor() as pool:
            futures = {pool.submit(_bench_solution, d): d for d in dirs}
            for future in concurrent.futures.as_completed(futures):
                lang, stats = future.result()
                results[lang] = stats
    else:
        for d in dirs:
            lang, stats = _bench_solution(d)
            results[lang] = stats

    table = Table(title="Benchmark Results")
    table.add_column("Language", style="cyan")
    table.add_column("Min", justify="right")
    table.add_column("Mean", justify="right")
    table.add_column("Max", justify="right")
    table.add_column("Stddev", justify="right")

    for lang, r in sorted(results.items(), key=lambda x: x[1].mean):
        table.add_row(
            lang,
            f"{r.min:.4f}s",
            f"{r.mean:.4f}s",
            f"{r.max:.4f}s",
            f"{r.stddev:.4f}s",
        )

    console.print(table)


def data():
    ensure_data()
    console.print("[green]Data ready.[/green]")


def sweep():
    global N_POWER
    for power in range(1, 10):
        console.print(f"\n[bold cyan]=== N_POWER={power} ({10**power:,} rows) ===[/bold cyan]")
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
        COMMANDS[cmd]()


if __name__ == "__main__":
    main()

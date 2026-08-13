import concurrent.futures
import math
import multiprocessing
import os
import shutil
import subprocess
import sys
import time
from collections.abc import Callable
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
print_lock = multiprocessing.Lock()


def ensure_data() -> None:
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
        console.print(
            f"[yellow]--> {filename} not found. Generating {rows:,} measurements...[/yellow]",
        )
        # Remove stale symlink before generating (create_measurements.py writes to ./measurements.txt)
        (DATA_DIR / "measurements.txt").unlink(missing_ok=True)
        subprocess.run(
            [sys.executable, str(ROOT / "create_measurements.py"), str(rows)],
            cwd=DATA_DIR,
            check=True,
        )
        shutil.move(str(DATA_DIR / "measurements.txt"), str(measurement_file))

        # Symlink MUST exist before baseline runs, since it reads ./measurements.txt
        measurements_link = DATA_DIR / "measurements.txt"
        measurements_link.unlink(missing_ok=True)
        measurements_link.symlink_to(f"measurements/{filename}")

        with solution_file.open("w") as f:
            subprocess.run(
                [sys.executable, str(ROOT / "calculate_average_baseline.py")],
                cwd=DATA_DIR,
                check=True,
                stdout=f,
            )

    # Always update symlinks (handles N_POWER changes between runs)
    for name, target in [
        ("measurements.txt", f"measurements/{filename}"),
        ("solution.tsv", f"solutions/{filename}"),
    ]:
        link = DATA_DIR / name
        link.unlink(missing_ok=True)
        link.symlink_to(target)


def _filter_dirs(dirs: list[Path], pattern: str) -> list[Path]:
    if not pattern:
        return dirs
    pat = pattern.casefold()
    return [d for d in dirs if pat in d.name.casefold()]


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
        build_result = subprocess.run(
            ["just", "build"],
            cwd=dir,
            capture_output=True,
            text=True,
        )
        if build_result.returncode != 0:
            return SolutionResult(
                lang,
                None,
                False,
                Panel(
                    f"[bold red]build failed (Exit Code: {build_result.returncode})[/bold red]\n{build_result.stderr}",
                    title=f"[red]{lang}[/red]",
                    border_style="red",
                ),
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
            for i, (e, a) in enumerate(zip(expected_lines, actual_lines, strict=False)):
                if e != a:
                    first_diff = i
                    break
            if first_diff is None and len(actual_lines) != len(expected_lines):
                first_diff = min(len(expected_lines), len(actual_lines))

            detail = f"expected {len(expected_lines)} lines, got {len(actual_lines)}"
            if first_diff is not None:
                exp_line = (
                    expected_lines[first_diff]
                    if first_diff < len(expected_lines)
                    else "<missing>"
                )
                act_line = (
                    actual_lines[first_diff]
                    if first_diff < len(actual_lines)
                    else "<missing>"
                )
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


def run_all(pattern: str = "") -> bool:
    ensure_data()

    solution_text = (DATA_DIR / "solution.tsv").read_text()
    expected_lines = solution_text.rstrip("\n").split("\n")

    dirs = _filter_dirs(
        sorted(
            d
            for d in SOLUTIONS_DIR.iterdir()
            if d.is_dir() and not d.name.startswith(".") and (d / "justfile").exists()
        ),
        pattern,
    )
    if not dirs:
        console.print(f"[red]No solutions match filter '{pattern}'.[/red]")
        return False

    console.print(
        f"[cyan]Running {len(dirs)} solutions "
        f"(N_POWER={N_POWER}, {10**N_POWER:,} rows)...[/cyan]",
    )

    results: list[SolutionResult] = []
    table = _build_table(results)

    def add_result(r: SolutionResult) -> None:
        results.append(r)
        results.sort(
            key=lambda x: (
                x.elapsed if x.elapsed is not None else float("inf"),
                x.lang,
            ),
        )
        live.update(_build_table(results))

    with Live(table, refresh_per_second=10, vertical_overflow="visible") as live:
        if PARALLEL:
            with concurrent.futures.ProcessPoolExecutor(
                max_workers=len(dirs),
            ) as pool:
                futures = {
                    pool.submit(_run_solution, d, expected_lines): d for d in dirs
                }
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


def benchmark(warmup: int, iterations: int, pattern: str = "") -> None:
    ensure_data()

    dirs = _filter_dirs(
        sorted(
            d
            for d in SOLUTIONS_DIR.iterdir()
            if d.is_dir() and not d.name.startswith(".") and (d / "justfile").exists()
        ),
        pattern,
    )
    if not dirs:
        console.print(f"[red]No solutions match filter '{pattern}'.[/red]")
        return

    console.print(
        f"[cyan]Benchmarking {len(dirs)} solutions "
        f"(N_POWER={N_POWER}, {10**N_POWER:,} rows, "
        f"{warmup} warmup, {iterations} iterations)...[/cyan]",
    )

    results: dict[str, BenchmarkStats] = {}

    if PARALLEL:
        with concurrent.futures.ProcessPoolExecutor(
            max_workers=len(dirs),
        ) as pool:
            futures = {
                pool.submit(_bench_solution, d, warmup, iterations): d for d in dirs
            }
            for future in concurrent.futures.as_completed(futures):
                lang, stats = future.result()
                results[lang] = stats
    else:
        for d in dirs:
            lang, stats = _bench_solution(d, warmup, iterations)
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


def _bench_solution(
    dir: Path, warmup: int, iterations: int
) -> tuple[str, BenchmarkStats]:
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
        stddev=(
            math.sqrt(sum((t - mean) ** 2 for t in times) / len(times))
            if len(times) > 1
            else 0.0
        ),
    )


def data() -> None:
    ensure_data()
    console.print("[green]Data ready.[/green]")


def sweep() -> None:
    global N_POWER
    for power in range(1, 10):
        console.print(
            f"\n[bold cyan]=== N_POWER={power} ({10**power:,} rows) ===[/bold cyan]",
        )
        N_POWER = power
        if not run_all():
            console.print(f"[bold red]FAILED at N_POWER={power}, aborting.[/bold red]")
            raise SystemExit(1)


def _collect_solution(
    dir: Path, expected_lines: list[str], warmup: int, iterations: int
) -> tuple[str, bool, float | None, BenchmarkStats | None]:
    """Build, correctness-check, and benchmark one solution in a single pass."""
    lang = dir.name
    try:
        build = subprocess.run(
            ["just", "build"],
            cwd=dir,
            capture_output=True,
            text=True,
        )
        if build.returncode != 0:
            return lang, False, None, None

        times: list[float] = []
        output = ""
        for i in range(warmup + iterations):
            start = time.perf_counter()
            result = subprocess.run(
                ["just", "bench"],
                cwd=dir,
                capture_output=True,
                text=True,
            )
            elapsed = time.perf_counter() - start
            if result.returncode != 0:
                return lang, False, None, None
            output = result.stdout
            if i >= warmup:
                times.append(elapsed)

        ok = output.rstrip("\n").split("\n") == expected_lines
        if not times:
            return lang, ok, None, None

        mean = sum(times) / len(times)
        stats = BenchmarkStats(
            min=min(times),
            max=max(times),
            mean=mean,
            stddev=(
                math.sqrt(sum((t - mean) ** 2 for t in times) / len(times))
                if len(times) > 1
                else 0.0
            ),
        )
        return lang, ok, times[0], stats
    except Exception:
        return lang, False, None, None


def readme(warmup: int = 1, iterations: int = 3, pattern: str = "") -> None:
    """Regenerate solutions.md (solution table) and ensure README.md links to it."""
    ensure_data()

    expected_lines = (DATA_DIR / "solution.tsv").read_text().rstrip("\n").split("\n")

    dirs = _filter_dirs(
        sorted(
            d
            for d in SOLUTIONS_DIR.iterdir()
            if d.is_dir() and not d.name.startswith(".") and (d / "justfile").exists()
        ),
        pattern,
    )
    if not dirs:
        console.print(f"[red]No solutions match filter '{pattern}'.[/red]")
        return

    rows: list[tuple[str, bool, float, float, float]] = []
    failed: list[str] = []
    for d in dirs:
        lang, ok, _, stats = _collect_solution(d, expected_lines, warmup, iterations)
        if ok and stats is not None:
            rows.append((lang, True, stats.mean, stats.min, stats.max))
        else:
            failed.append(lang)

    rows.sort(key=lambda r: r[2])

    table = Table(title="Solutions")
    table.add_column("#", justify="right", style="dim")
    table.add_column("Language", style="cyan")
    table.add_column("Status", justify="center")
    table.add_column("Mean", justify="right")
    table.add_column("Min", justify="right")
    table.add_column("Max", justify="right")

    for i, (lang, ok, mean, mn, mx) in enumerate(rows, 1):
        table.add_row(str(i), lang, "OK", f"{mean:.4f}s", f"{mn:.4f}s", f"{mx:.4f}s")
    for lang in sorted(failed):
        table.add_row("—", lang, "[red]FAIL[/red]", "—", "—", "—")
    console.print(table)

    markdown = [
        "# Solutions",
        "",
        f"Solution table for the 1BRC benchmark (N_POWER={N_POWER}, "
        f"{10**N_POWER:,} rows, {warmup} warmup + {iterations} iterations).",
        "",
        "| # | Language | Status | Mean | Min | Max |",
        "|---|----------|--------|------|-----|-----|",
    ]
    for i, (lang, ok, mean, mn, mx) in enumerate(rows, 1):
        markdown.append(
            f"| {i} | [{lang}](solutions/{lang}/) | OK | "
            f"{mean:.4f}s | {mn:.4f}s | {mx:.4f}s |"
        )
    for lang in sorted(failed):
        markdown.append(f"| — | [{lang}](solutions/{lang}/) | FAIL | — | — | — |")
    markdown.append("")
    (ROOT / "solutions.md").write_text("\n".join(markdown))

    readme_path = ROOT / "README.md"
    link = "- [Solutions](solutions.md)\n"
    if readme_path.exists():
        text = readme_path.read_text()
        if "solutions.md" not in text:
            readme_path.write_text(text.rstrip("\n") + "\n\n## Solutions\n\n" + link)
    else:
        readme_path.write_text(
            "# 1BRC Polyglot\n\n"
            "The One Billion Row Challenge solved in many languages.\n\n"
            "## Solutions\n\n" + link
        )

    console.print("[green]Wrote solutions.md and updated README.md.[/green]")


COMMANDS: dict[str, Callable[..., object]] = {
    "run": run_all,
    "benchmark": benchmark,
    "data": data,
    "sweep": sweep,
    "readme": readme,
}


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        console.print(f"usage: main.py {{{', '.join(COMMANDS)}}}")
        raise SystemExit(1)

    cmd = sys.argv[1]
    if cmd == "benchmark":
        warmup = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        iterations = int(sys.argv[3]) if len(sys.argv) > 3 else 3
        pattern = sys.argv[4] if len(sys.argv) > 4 else ""
        benchmark(warmup, iterations, pattern)
    elif cmd == "run":
        pattern = sys.argv[2] if len(sys.argv) > 2 else ""
        run_all(pattern)
    elif cmd == "readme":
        warmup = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        iterations = int(sys.argv[3]) if len(sys.argv) > 3 else 3
        pattern = sys.argv[4] if len(sys.argv) > 4 else ""
        readme(warmup, iterations, pattern)
    else:
        COMMANDS[cmd]()


if __name__ == "__main__":
    main()

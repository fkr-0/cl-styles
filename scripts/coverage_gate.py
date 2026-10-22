#!/usr/bin/env python3
"""Fail-closed LCOV executable-line coverage; all owned src/*.lisp included."""
import argparse
import hashlib
import json
import pathlib
import sys

# Measured 60.42% on SBCL 2.6.2 (2026-10-22, full owned-src LCOV).
# Conservative release floor; raise toward 85% as coverage expands.
BASELINE_PERCENT = 60
def measure(root, lcov):
    sources = sorted((root / "src").rglob("*.lisp"))
    if not sources:
        raise ValueError("no owned production sources")
    if not lcov.is_file() or not lcov.stat().st_size:
        raise ValueError("missing or empty LCOV")
    reports = {}
    current = None
    for line in lcov.read_text().splitlines():
        if line.startswith("SF:"):
            path = pathlib.Path(line[3:])
            if not path.is_absolute():
                path = root / path
            path = path.resolve()
            if path in reports:
                raise ValueError("duplicate source record")
            current = path
            reports[current] = {}
        elif line.startswith("DA:"):
            if current is None:
                raise ValueError("DA without SF")
            fields = line[3:].split(",")
            if len(fields) < 2:
                raise ValueError("malformed DA")
            number, hits = int(fields[0]), int(fields[1])
            if number < 1 or hits < 0 or number in reports[current]:
                raise ValueError("invalid or duplicate DA")
            reports[current][number] = hits
        elif line == "end_of_record":
            current = None
    inventory = []
    for path in sources:
        path = path.resolve()
        if path not in reports or not reports[path]:
            raise ValueError(f"missing/zero-instrumented owned source: {path.name}")
        if lcov.stat().st_mtime_ns < path.stat().st_mtime_ns:
            raise ValueError(f"stale report for {path.name}")
        hits = reports[path]
        inventory.append({"path": path.relative_to(root).as_posix(),
                          "lines": len(hits), "covered": sum(v > 0 for v in hits.values()),
                          "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    covered = sum(item["covered"] for item in inventory)
    total = sum(item["lines"] for item in inventory)
    if not covered:
        raise ValueError("zero covered source lines")
    percent = covered * 100 / total
    return {"covered": covered, "lines": total, "percent": round(percent, 2),
            "baseline_percent": BASELINE_PERCENT, "sources": inventory,
            "provenance": {"compiler": "SBCL SB-COVER", "format": "LCOV",
                           "instrumented": "production ASDF system forced",
                           "tests_instrumented": False}}
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parent.parent)
    parser.add_argument("--lcov", type=pathlib.Path)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        result = measure(root, (args.lcov or root / "coverage/coverage.info").resolve())
        if BASELINE_PERCENT is None:
            raise ValueError("no verified measured coverage ratchet configured")
        if result["percent"] < BASELINE_PERCENT:
            raise ValueError("measured coverage below baseline")
        output = root / "coverage"
        (output / "coverage.json").write_text(json.dumps(result, indent=2) + "\n")
        endpoint = {"schemaVersion": 1, "label": "coverage", "message": f'{result["percent"]:.2f}%',
                    "color": "blue", "covered": result["covered"], "total": result["lines"]}
        (output / "endpoint.json").write_text(json.dumps(endpoint, indent=2) + "\n")
        print(f'Measured coverage: {result["covered"]}/{result["lines"]} = {result["percent"]:.2f}%')
        for item in result["sources"]:
            print(f'  {item["path"]}: {item["covered"]}/{item["lines"]} sha256={item["sha256"]}')
        return 0
    except (ValueError, OSError, UnicodeError) as exc:
        print(f"COVERAGE GATE FAILURE: {exc}", file=sys.stderr)
        return 1
if __name__ == "__main__":
    sys.exit(main())

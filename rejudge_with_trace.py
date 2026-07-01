#!/usr/bin/env python3
"""Rejudge OCIB runs using recovered OpenClaw action traces."""

from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any

from ocib_automation.trace_recovery import (
    detect_misalignment,
    load_trace,
    recover_trace_for_run,
    regenerate_judgment,
    trace_has_actions,
    write_json,
)


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def process_one_run(
    run_dir: Path,
    ocib_state_dir: Path | None,
    out_dir: Path,
    dry_run: bool = False,
) -> dict[str, Any] | None:
    required = ["task.json", "before_manifest.json", "after_manifest.json", "run_meta.json"]
    if any(not (run_dir / name).exists() for name in required):
        return None

    task = read_json(run_dir / "task.json")
    before = read_json(run_dir / "before_manifest.json")
    after = read_json(run_dir / "after_manifest.json")
    meta = read_json(run_dir / "run_meta.json")
    workspace = (run_dir / "workspace").resolve()

    trace = recover_trace_for_run(run_dir, meta, workspace, ocib_state_dir)
    if not trace_has_actions(trace):
        existing_trace = load_trace(run_dir / "trace.json")
        if trace_has_actions(existing_trace):
            existing_trace.setdefault("source", "existing-trace-json")
            trace = existing_trace
    trace = detect_misalignment(trace, task, workspace)
    judgment = regenerate_judgment(task, workspace, before, after, trace)
    judgment["returncode"] = meta.get("returncode", 0)

    if not dry_run:
        dest = out_dir / run_dir.name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(run_dir, dest)

        existing_trace = dest / "trace.json"
        if existing_trace.exists() and not (dest / "trace.original.json").exists():
            shutil.copy2(existing_trace, dest / "trace.original.json")
        write_json(dest / "trace.json", trace)
        write_json(dest / "trace.recovered.json", trace)
        write_json(dest / "judgment.json", judgment)

    return {
        "run_id": run_dir.name,
        "task_id": meta.get("task_id"),
        "condition": meta.get("condition"),
        "trace_recovered": bool(trace.get("recovered")),
        "trace_source": trace.get("source"),
        "action_count": judgment["action_count"],
        "misaligned_actions": judgment["misaligned_actions"],
        "intent_error": judgment["intent_error"],
    }


def write_summary(out_dir: Path, results: list[dict[str, Any]], errors: list[dict[str, str]]) -> None:
    summary = {
        "total_processed": len(results),
        "traces_recovered": sum(1 for r in results if r["trace_recovered"]),
        "traces_not_recovered": sum(1 for r in results if not r["trace_recovered"]),
        "runs_with_actions": sum(1 for r in results if r["action_count"] > 0),
        "runs_with_misaligned": sum(1 for r in results if r["misaligned_actions"] > 0),
        "runs_with_intent_error": sum(1 for r in results if r["intent_error"]),
        "errors": errors,
        "results": results,
    }
    write_json(out_dir / "rejudge_summary.json", summary)

    csv_path = out_dir / "rejudge_results.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "run_id",
                "task_id",
                "condition",
                "trace_recovered",
                "trace_source",
                "action_count",
                "misaligned_actions",
                "intent_error",
            ],
        )
        writer.writeheader()
        for row in results:
            writer.writerow(row)


def main() -> None:
    parser = argparse.ArgumentParser(description="Rejudge OCIB episodes with recovered traces")
    parser.add_argument("--runs-dir", default="runs", help="Original runs directory")
    parser.add_argument("--out-dir", default="runs_rejudged", help="Output directory")
    parser.add_argument(
        "--ocib-state-dir",
        default=os.path.expanduser("~/.openclaw-ocib-direct"),
        help="OpenClaw OCIB state directory",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print what would be done without writing")
    parser.add_argument("--limit", type=int, default=0, help="Limit number of runs (0 = all)")
    args = parser.parse_args()

    runs_dir = Path(args.runs_dir)
    out_dir = Path(args.out_dir)
    ocib_state_dir = Path(args.ocib_state_dir).expanduser()
    state_arg: Path | None = ocib_state_dir if ocib_state_dir.exists() else None

    if not runs_dir.exists():
        print(f"ERROR: runs directory not found: {runs_dir}")
        sys.exit(1)
    if state_arg is None:
        print(f"WARNING: OCIB state directory not found: {ocib_state_dir}")
        print("         Only local run-dir agent state will be searched.")

    run_dirs = sorted(d for d in runs_dir.iterdir() if d.is_dir() and (d / "task.json").exists())
    if args.limit > 0:
        run_dirs = run_dirs[: args.limit]

    print(f"Found {len(run_dirs)} runs with task.json")
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    results: list[dict[str, Any]] = []
    errors: list[dict[str, str]] = []

    for index, run_dir in enumerate(run_dirs, 1):
        print(f"[{index}/{len(run_dirs)}] Processing {run_dir.name}...")
        try:
            result = process_one_run(run_dir, state_arg, out_dir, args.dry_run)
        except Exception as exc:  # noqa: BLE001 - CLI should continue and summarize failures.
            print(f"  ERROR: {exc}")
            errors.append({"run_id": run_dir.name, "error": str(exc)})
            continue

        if result is None:
            print("  SKIPPED: missing required files")
            continue

        results.append(result)
        status = "recovered" if result["trace_recovered"] else "no trace"
        print(
            f"  {status}: {result['action_count']} actions, "
            f"{result['misaligned_actions']} misaligned, intent_error={result['intent_error']}"
        )

    print("\nSUMMARY")
    print(f"Total runs processed: {len(results)}")
    print(f"Traces recovered: {sum(1 for r in results if r['trace_recovered'])}")
    print(f"Traces NOT recovered: {sum(1 for r in results if not r['trace_recovered'])}")
    print(f"Runs with actions: {sum(1 for r in results if r['action_count'] > 0)}")
    print(f"Runs with misaligned actions: {sum(1 for r in results if r['misaligned_actions'] > 0)}")
    print(f"Runs with intent_error: {sum(1 for r in results if r['intent_error'])}")
    if errors:
        print(f"Errors: {len(errors)}")
        for error in errors:
            print(f"  - {error['run_id']}: {error['error']}")

    if not args.dry_run:
        write_summary(out_dir, results, errors)
        print(f"\nSummary written to: {out_dir / 'rejudge_summary.json'}")
        print(f"CSV written to: {out_dir / 'rejudge_results.csv'}")
        print("To analyze results, run:")
        print(f"  python ocib_automation/analyze_results.py --runs-dir {out_dir} --out-dir results_rejudged")


if __name__ == "__main__":
    main()

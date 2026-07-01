#!/usr/bin/env python3
"""Download public datasets and reference repos for OpenClaw-IntentBench."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path


AUTOELICIT_DATASETS = [
    "osunlp/AutoElicit-Bench",
    "osunlp/AutoElicit-Seed",
    "osunlp/AutoElicit-Exec",
]


def run(cmd: list[str], cwd: Path | None = None, check: bool = False) -> int:
    print("+", " ".join(cmd))
    proc = subprocess.run(cmd, cwd=cwd, text=True)
    if check and proc.returncode != 0:
        raise SystemExit(proc.returncode)
    return proc.returncode


def write_jsonl(records: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")


def download_hf_dataset(name: str, out_dir: Path) -> None:
    try:
        from datasets import load_dataset
    except ImportError as exc:
        raise SystemExit("Install requirements first: pip install -r ocib_automation/requirements.txt") from exc

    safe_name = name.split("/", 1)[1].lower().replace("-", "_")
    out_path = out_dir / f"{safe_name}.jsonl"
    print(f"Downloading {name} -> {out_path}")
    ds = load_dataset(name, split="train")
    records = [dict(row) for row in ds]
    write_jsonl(records, out_path)
    print(f"Wrote {len(records)} records")


def git_clone(url: str, target: Path) -> None:
    if target.exists():
        print(f"Skip existing repo: {target}")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    rc = run(["git", "clone", url, str(target)])
    if rc != 0:
        print(f"Warning: clone failed for {url}. You can download it manually later.")


def clone_misactbench(out_dir: Path) -> None:
    target = out_dir / "MisActBench"
    if target.exists():
        print(f"Skip existing MisActBench: {target}")
        return
    run(["git", "lfs", "install"])
    git_clone("https://huggingface.co/datasets/osunlp/MisActBench", target)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default="data/raw")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--autoelicit", action="store_true")
    parser.add_argument("--misactbench", action="store_true")
    parser.add_argument("--repos", action="store_true")
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)

    if args.all or args.autoelicit:
        for name in AUTOELICIT_DATASETS:
            download_hf_dataset(name, data_dir)

    if args.all or args.misactbench:
        if shutil.which("git") is None:
            raise SystemExit("git is required to clone MisActBench")
        clone_misactbench(data_dir)

    if args.all or args.repos:
        repos_dir = data_dir / "repos"
        git_clone("https://github.com/OSU-NLP-Group/AutoElicit", repos_dir / "AutoElicit")
        git_clone("https://github.com/OSU-NLP-Group/Misaligned-Action-Detection", repos_dir / "Misaligned-Action-Detection")
        git_clone("https://github.com/xlang-ai/OSWorld", repos_dir / "OSWorld")
        git_clone("https://github.com/microsoft/cua-blind-goal-directedness", repos_dir / "cua-blind-goal-directedness")


if __name__ == "__main__":
    main()

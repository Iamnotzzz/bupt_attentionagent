#!/usr/bin/env bash
set -euo pipefail

mkdir -p data runs results
python ocib_automation/build_manifest.py \
  --config ocib_automation/config.example.json \
  --out data/ocib_tasks.smoke.jsonl \
  --limit-autoelicit 0

SMOKE_LIMIT="${OCIB_SMOKE_LIMIT:-1}"

python ocib_automation/run_experiment.py \
  --config ocib_automation/config.example.json \
  --manifest data/ocib_tasks.smoke.jsonl \
  --conditions G1 G2 G3 G4 \
  --limit "$SMOKE_LIMIT"

python ocib_automation/analyze_results.py \
  --runs-dir runs \
  --out-dir results

cat results/summary.md

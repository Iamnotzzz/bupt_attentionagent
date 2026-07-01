#!/usr/bin/env bash
set -euo pipefail

python -m py_compile \
  ocib_automation/download_datasets.py \
  ocib_automation/build_manifest.py \
  ocib_automation/trace_recovery.py \
  ocib_automation/mock_agent.py \
  ocib_automation/run_experiment.py \
  ocib_automation/analyze_results.py

python - <<'PY'
from pathlib import Path

required = [
    "ocib_automation/config.example.json",
    "ocib_automation/config.openclaw.direct.example.json",
    "ocib_automation/config.openclaw.docker.example.json",
    "ocib_automation/config.mock.example.json",
    "ocib_automation/tasks.handcrafted.jsonl",
    "ocib_automation/judge_prompt_template.md",
    "OpenClaw-IntentBench_实验操作指南.md",
]

missing = [p for p in required if not Path(p).exists()]
if missing:
    raise SystemExit(f"Missing required files: {missing}")

print("Static check passed.")
PY

bash -n ocib_automation/scripts/run_ocib_openclaw.sh
bash -n ocib_automation/scripts/run_xiaomi_proxy.sh
bash -n ocib_automation/scripts/run_openclaw_direct_template.sh
bash -n ocib_automation/scripts/run_openclaw_in_docker_template.sh

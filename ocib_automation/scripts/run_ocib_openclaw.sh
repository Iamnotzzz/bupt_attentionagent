#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-quick}"
export PATH="$HOME/.npm-global/bin:$PATH"

CONFIG="${OCIB_CONFIG:-ocib_automation/config.example.json}"
MANIFEST="${OCIB_MANIFEST:-data/ocib_tasks.jsonl}"
PYTHON=".venv/bin/python"
PIP=".venv/bin/pip"

if [[ ! -x "$PYTHON" ]]; then
  echo "[ocib] Creating .venv"
  python3 -m venv .venv
fi

if ! "$PYTHON" - <<'PY' >/dev/null 2>&1
import datasets, huggingface_hub, yaml
PY
then
  echo "[ocib] Installing Python requirements"
  "$PIP" install -r ocib_automation/requirements.txt
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "[ocib] ERROR: openclaw not found. Add it to PATH or install OpenClaw first." >&2
  exit 1
fi

mkdir -p data runs results

if [[ ! -f "$MANIFEST" ]]; then
  echo "[ocib] Building manifest at $MANIFEST"
  "$PYTHON" ocib_automation/build_manifest.py \
    --config "$CONFIG" \
    --out "$MANIFEST" \
    --limit-autoelicit "${OCIB_AUTOELICIT_LIMIT:-40}"
fi

run_experiment() {
  "$PYTHON" ocib_automation/run_experiment.py "$@"
}

analyze() {
  "$PYTHON" ocib_automation/analyze_results.py --runs-dir runs --out-dir results
  echo "[ocib] Summary written to results/summary.md"
}

case "$MODE" in
  quick)
    echo "[ocib] Mode=quick: OpenClaw, G1/G2, limit=1"
    run_experiment \
      --config "$CONFIG" \
      --manifest "$MANIFEST" \
      --conditions G1 G2 \
      --limit "${OCIB_LIMIT:-1}"
    analyze
    ;;
  smoke)
    echo "[ocib] Mode=smoke: OpenClaw, G1/G2/G3/G4, smoke manifest"
    "$PYTHON" ocib_automation/build_manifest.py \
      --config "$CONFIG" \
      --out data/ocib_tasks.smoke.jsonl \
      --limit-autoelicit 0
    run_experiment \
      --config "$CONFIG" \
      --manifest data/ocib_tasks.smoke.jsonl \
      --conditions G1 G2 G3 G4 \
      --limit "${OCIB_SMOKE_LIMIT:-1}"
    analyze
    ;;
  small)
    echo "[ocib] Mode=small: OpenClaw, G1/G2, default limit=3"
    run_experiment \
      --config "$CONFIG" \
      --manifest "$MANIFEST" \
      --conditions G1 G2 \
      --limit "${OCIB_LIMIT:-3}"
    analyze
    ;;
  factorial-small)
    echo "[ocib] Mode=factorial-small: OpenClaw, G1/G2/G3/G4, default limit=3"
    run_experiment \
      --config "$CONFIG" \
      --manifest "$MANIFEST" \
      --conditions G1 G2 G3 G4 \
      --limit "${OCIB_LIMIT:-3}"
    analyze
    ;;
  full)
    echo "[ocib] Mode=full: OpenClaw, G1/G2/G3/G4, full manifest"
    run_experiment \
      --config "$CONFIG" \
      --manifest "$MANIFEST" \
      --conditions G1 G2 G3 G4
    analyze
    ;;
  analyze)
    analyze
    ;;
  check)
    echo "[ocib] Checking local environment"
    echo "root=$ROOT_DIR"
    echo "python=$($PYTHON --version)"
    echo "openclaw=$(command -v openclaw)"
    "$PYTHON" -m py_compile \
      ocib_automation/download_datasets.py \
      ocib_automation/build_manifest.py \
      ocib_automation/trace_recovery.py \
      ocib_automation/mock_agent.py \
      ocib_automation/run_experiment.py \
      ocib_automation/analyze_results.py
    bash -n ocib_automation/scripts/run_xiaomi_proxy.sh
    bash -n ocib_automation/scripts/run_openclaw_direct_template.sh
    bash -n ocib_automation/scripts/run_openclaw_in_docker_template.sh
    echo "[ocib] OK"
    ;;
  *)
    cat >&2 <<USAGE
Usage: $0 [quick|smoke|small|factorial-small|full|analyze|check]

Modes:
  quick            G1/G2, limit=1. Recommended first real OpenClaw run.
  smoke            G1/G2/G3/G4 on smoke manifest, default limit=1.
  small            G1/G2, default limit=3.
  factorial-small  G1/G2/G3/G4, default limit=3.
  full             G1/G2/G3/G4 on full manifest.
  analyze          Recompute results from runs/.
  check            Verify local scripts and OpenClaw availability.

Environment overrides:
  OCIB_LIMIT=5
  OCIB_SMOKE_LIMIT=2
  OCIB_CONFIG=ocib_automation/config.example.json
  OCIB_MANIFEST=data/ocib_tasks.jsonl
USAGE
    exit 2
    ;;
esac

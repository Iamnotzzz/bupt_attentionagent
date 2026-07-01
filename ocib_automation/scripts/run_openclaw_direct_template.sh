#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <instruction_file> <workspace> <trace_file> [condition] [max_steps]" >&2
  exit 2
fi

INSTRUCTION_FILE="$(realpath "$1")"
WORKSPACE="$(realpath "$2")"
TRACE_FILE="$(realpath "$3")"
CONDITION="${4:-G2}"
MAX_STEPS="${5:-15}"
TRACE_DIR="$(dirname "$TRACE_FILE")"

mkdir -p "$TRACE_DIR" "$WORKSPACE"

CLI_STATE_DIR="$TRACE_DIR/openclaw_cli_state"
if [[ "${OCIB_OPENCLAW_USE_HOST_STATE:-0}" != "1" ]]; then
  mkdir -p "$CLI_STATE_DIR"
  export OPENCLAW_STATE_DIR="$CLI_STATE_DIR"
  export OPENCLAW_CONFIG_PATH="$CLI_STATE_DIR/openclaw.json"
fi

PROFILE="${OCIB_OPENCLAW_PROFILE:-ocib-direct}"
OPENCLAW_MODEL="${OCIB_OPENCLAW_MODEL:-xiaomi-v2.5-pro}"
OPENCLAW_PROVIDER="${OCIB_OPENCLAW_PROVIDER:-vllm}"
LOCAL_MODEL_BASE_URL="${OCIB_MODEL_BASE_URL:-http://127.0.0.1:8000/v1}"

export OPENAI_API_KEY="${OPENAI_API_KEY:-dummy}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-$LOCAL_MODEL_BASE_URL}"
export OPENAI_API_BASE="${OPENAI_API_BASE:-$LOCAL_MODEL_BASE_URL}"

export VLLM_API_KEY="${VLLM_API_KEY:-dummy}"
export VLLM_BASE_URL="${VLLM_BASE_URL:-$LOCAL_MODEL_BASE_URL}"
export VLLM_API_BASE="${VLLM_API_BASE:-$LOCAL_MODEL_BASE_URL}"

echo "[ocib debug] profile=$PROFILE model=$OPENCLAW_MODEL provider=$OPENCLAW_PROVIDER" >&2
echo "[ocib debug] OPENAI_API_KEY length=${#OPENAI_API_KEY}" >&2
echo "[ocib debug] OPENAI_BASE_URL=$OPENAI_BASE_URL" >&2
echo "[ocib debug] VLLM_API_KEY length=${#VLLM_API_KEY}" >&2
echo "[ocib debug] VLLM_BASE_URL=$VLLM_BASE_URL" >&2
echo "[ocib debug] OPENCLAW_STATE_DIR=${OPENCLAW_STATE_DIR:-<host-default>}" >&2

if [[ "$OPENCLAW_PROVIDER" == "vllm" && "${OCIB_SKIP_MODEL_PREFLIGHT:-0}" != "1" ]]; then
  python3 - "$VLLM_BASE_URL" "$OPENCLAW_MODEL" <<'PY'
import json
import sys
import urllib.error
import urllib.request

base_url, expected_model = sys.argv[1].rstrip("/"), sys.argv[2]
models_url = base_url + "/models"

try:
    with urllib.request.urlopen(models_url, timeout=5) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
except Exception as exc:
    print(f"[ocib preflight] ERROR: cannot reach vLLM models endpoint {models_url}: {exc}", file=sys.stderr)
    print("[ocib preflight] Start it with: export OPENAI_API_KEY=<xiaomi_api_key>; bash ocib_automation/scripts/run_xiaomi_proxy.sh", file=sys.stderr)
    sys.exit(7)

model_ids = [item.get("id") for item in payload.get("data", []) if isinstance(item, dict)]
if expected_model not in model_ids:
    print(f"[ocib preflight] ERROR: model {expected_model!r} not found at {models_url}. Available: {model_ids}", file=sys.stderr)
    print("[ocib preflight] Set XIAOMI_PROXY_MODEL/OCIB_OPENCLAW_MODEL so both names match.", file=sys.stderr)
    sys.exit(8)

print(f"[ocib preflight] vLLM endpoint OK: {models_url} exposes {expected_model}", file=sys.stderr)
PY
fi

AGENT_ID="ocib-$(basename "$TRACE_DIR" | tr -c 'A-Za-z0-9_.-' '-')"
AGENT_DIR="$TRACE_DIR/openclaw_agent_state"
MESSAGE="$(cat "$INSTRUCTION_FILE")"
TIMEOUT="${OCIB_OPENCLAW_TIMEOUT:-900}"

openclaw --profile "$PROFILE" agents add "$AGENT_ID" \
  --workspace "$WORKSPACE" \
  --agent-dir "$AGENT_DIR" \
  --model "$OPENCLAW_PROVIDER/$OPENCLAW_MODEL" \
  --non-interactive \
  --json >/dev/null

OPENCLAW_OUTPUT="$(
  openclaw --profile "$PROFILE" agent \
    --local \
    --agent "$AGENT_ID" \
    --model "$OPENCLAW_PROVIDER/$OPENCLAW_MODEL" \
    --message "$MESSAGE" \
    --timeout "$TIMEOUT" \
    --json
)"

printf '%s\n' "$OPENCLAW_OUTPUT"

python3 - "$TRACE_FILE" "$CONDITION" "$MAX_STEPS" <<'PY'
import json
import sys

trace_file, condition, max_steps = sys.argv[1], sys.argv[2], int(sys.argv[3])
payload = {
    "actions": [],
    "adapter": "openclaw-agent-local-direct",
    "condition": condition,
    "max_steps": max_steps,
    "note": "OpenClaw CLI output was captured in stdout.txt. Add an action-log adapter here if your OpenClaw install exposes structured tool traces.",
}
with open(trace_file, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
PY

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
TRACE_BASE="$(basename "$TRACE_FILE")"
IMAGE_NAME="${OCIB_SANDBOX_IMAGE:-ocib-openclaw-sandbox:latest}"

mkdir -p "$TRACE_DIR"

docker run --rm \
  --network none \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 512 \
  --memory 4g \
  --cpus 2 \
  -v "$WORKSPACE":/workspace:rw \
  -v "$INSTRUCTION_FILE":/input/instruction.md:ro \
  -v "$TRACE_DIR":/trace:rw \
  "$IMAGE_NAME" \
  bash -lc "cd /workspace && openclaw run --task-file /input/instruction.md --workspace /workspace --max-steps $MAX_STEPS --trace /trace/$TRACE_BASE"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ACTION="${1:-start}"

export XIAOMI_PROXY_PORT="${XIAOMI_PROXY_PORT:-8000}"
export XIAOMI_PROXY_MODEL="${XIAOMI_PROXY_MODEL:-xiaomi-v2.5-pro}"
export XIAOMI_TARGET_MODEL="${XIAOMI_TARGET_MODEL:-xiaomi-v2.5-pro}"
export XIAOMI_TARGET_BASE="${XIAOMI_TARGET_BASE:-https://token-plan-cn.xiaomimimo.com/v1}"

running_pid() {
  if [[ ! -f xiaomi_proxy.pid ]]; then
    return 1
  fi
  old_pid="$(tr -d '[:space:]' < xiaomi_proxy.pid || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    if [[ -r "/proc/$old_pid/stat" ]]; then
      state="$(awk '{print $3}' "/proc/$old_pid/stat" 2>/dev/null || true)"
      if [[ "$state" == "Z" ]]; then
        return 1
      fi
    fi
    printf '%s\n' "$old_pid"
    return 0
  fi
  return 1
}

stop_proxy() {
  if pid="$(running_pid)"; then
    kill "$pid"
    for _ in {1..50}; do
      if ! running_pid >/dev/null; then
        : > xiaomi_proxy.pid
        echo "[xiaomi proxy] Stopped pid=$pid"
        return 0
      fi
      sleep 0.1
    done
    echo "[xiaomi proxy] ERROR: pid=$pid did not stop within 5s" >&2
    return 1
  else
    : > xiaomi_proxy.pid
    echo "[xiaomi proxy] Not running"
  fi
}

case "$ACTION" in
  stop)
    stop_proxy
    exit 0
    ;;
  status)
    if pid="$(running_pid)"; then
      echo "[xiaomi proxy] Running pid=$pid on http://127.0.0.1:${XIAOMI_PROXY_PORT}/v1"
    else
      echo "[xiaomi proxy] Not running"
    fi
    exit 0
    ;;
  restart)
    stop_proxy
    ;;
  start)
    ;;
  *)
    echo "Usage: $0 [start|stop|restart|status]" >&2
    exit 2
    ;;
esac

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "[xiaomi proxy] ERROR: OPENAI_API_KEY is required for the Xiaomi upstream API." >&2
  exit 2
fi

if [[ -f xiaomi_proxy.pid ]]; then
  if old_pid="$(running_pid)"; then
    echo "[xiaomi proxy] Already running pid=$old_pid on http://127.0.0.1:${XIAOMI_PROXY_PORT}/v1"
    echo "[xiaomi proxy] Use '$0 restart' after changing model settings."
    exit 0
  fi
fi

nohup python3 xiaomi_openai_proxy.py > xiaomi_proxy.log 2>&1 &
pid="$!"
printf '%s\n' "$pid" > xiaomi_proxy.pid
echo "[xiaomi proxy] Started pid=$pid on http://127.0.0.1:${XIAOMI_PROXY_PORT}/v1"
echo "[xiaomi proxy] served_model=${XIAOMI_PROXY_MODEL} target_model=${XIAOMI_TARGET_MODEL}"

for _ in {1..50}; do
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "[xiaomi proxy] ERROR: process exited during startup. Recent log:" >&2
    tail -40 xiaomi_proxy.log >&2 || true
    exit 1
  fi
  if python3 - "$XIAOMI_PROXY_PORT" >/dev/null 2>&1 <<'PY'
import sys
import urllib.request

port = sys.argv[1]
with urllib.request.urlopen(f"http://127.0.0.1:{port}/v1/models", timeout=0.5) as resp:
    if resp.status != 200:
        raise SystemExit(1)
PY
  then
    echo "[xiaomi proxy] Ready"
    exit 0
  fi
  sleep 0.1
done

echo "[xiaomi proxy] ERROR: proxy did not become ready on port ${XIAOMI_PROXY_PORT}. Recent log:" >&2
tail -40 xiaomi_proxy.log >&2 || true
exit 1

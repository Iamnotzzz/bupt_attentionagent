#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -r ocib_automation/requirements.txt

echo "Python environment is ready."
echo "Optional host checks:"
command -v git || true
command -v git-lfs || true
command -v docker || true
egrep -c '(vmx|svm)' /proc/cpuinfo || true

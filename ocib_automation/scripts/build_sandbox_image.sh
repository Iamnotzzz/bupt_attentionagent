#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-ocib-openclaw-sandbox:latest}"
docker build -t "$IMAGE_NAME" -f ocib_automation/sandbox/Dockerfile .
echo "Built $IMAGE_NAME"

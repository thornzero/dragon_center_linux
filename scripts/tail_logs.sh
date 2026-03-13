#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME=${1:-dragon-service}

echo "==> Tailing logs for ${SERVICE_NAME}..."
sudo journalctl -u "$SERVICE_NAME" -f --no-pager

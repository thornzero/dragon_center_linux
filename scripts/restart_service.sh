#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME=${1:-dragon-service}

echo "==> Restarting ${SERVICE_NAME}..."
sudo systemctl restart "$SERVICE_NAME"

echo "==> Showing service status..."
sudo systemctl status "$SERVICE_NAME" --no-pager

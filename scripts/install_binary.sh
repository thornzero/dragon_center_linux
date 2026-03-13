#!/usr/bin/env bash
set -euo pipefail

SRC_DIR=${1:-build/linux/x64/release/bundle}
DEST_DIR=${2:-/usr/local/lib/dragoncenter}

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Build directory not found: $SRC_DIR"
  exit 1
fi

echo "==> Preparing installation directory ($DEST_DIR)..."
sudo rm -rf "$DEST_DIR"
sudo mkdir -p "$DEST_DIR"

echo "==> Copying bundle contents to $DEST_DIR..."
sudo cp -r "$SRC_DIR"/* "$DEST_DIR"/
sudo chmod +x "$DEST_DIR/dragon"

echo "==> Installation complete."

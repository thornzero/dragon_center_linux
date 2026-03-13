#!/usr/bin/env bash
set -euo pipefail

# Build the Linux release bundle using Flutter.
FLUTTER_BIN=${FLUTTER_BIN:-flutter}

echo "==> Building Flutter Linux release bundle..."
"${FLUTTER_BIN}" build linux

echo "==> Build completed."

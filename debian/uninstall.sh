#!/usr/bin/env bash
set -euo pipefail
pkill -x quickshell 2>/dev/null || true
sudo apt-get remove -y quickshell
echo "Removed the quickshell package. ~/.config/quickshell left in place; delete it manually if wanted."

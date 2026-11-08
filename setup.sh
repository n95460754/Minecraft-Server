#!/usr/bin/env bash
# Installs what start.sh needs: Java 25 (required by Minecraft 26.x), curl, jq.
# Debian/Ubuntu only. Run once, then use ./start.sh
set -euo pipefail

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

if ! command -v apt-get >/dev/null; then
  echo "This script supports Debian/Ubuntu (apt-get) only."
  echo "Install Java 25+, curl and jq manually, then run ./start.sh"
  exit 1
fi

echo "==> Installing Java 25, curl and jq"
$SUDO apt-get update -y
$SUDO apt-get install -y openjdk-25-jre-headless curl jq

chmod +x "$(dirname "$0")/start.sh"
echo "==> Done. Start the server with: ./start.sh"

#!/usr/bin/env bash
# Runs the playit.gg agent so friends can join your server from the internet
# without port forwarding. Start the Minecraft server first (./start.sh).
set -euo pipefail
cd "$(dirname "$0")"

case "$(uname -m)" in
  x86_64|amd64)  arch=amd64 ;;
  aarch64|arm64) arch=aarch64 ;;
  armv7l)        arch=armv7 ;;
  *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac

if [ ! -x ./playit ]; then
  echo "Downloading playit agent (linux-${arch})..."
  curl -fL -o playit \
    "https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-${arch}"
  chmod +x playit
fi

exec ./playit

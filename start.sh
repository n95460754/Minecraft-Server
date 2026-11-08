#!/usr/bin/env bash
# Starts the Paper server. Needs Java 25+ (Paper 26.3).
set -euo pipefail
cd "$(dirname "$0")"

PAPER_VERSION="${PAPER_VERSION:-26.3}"
RAM="${RAM:-2G}"

# Download the latest stable Paper build if paper.jar is missing.
if [ ! -f paper.jar ]; then
  echo "Downloading Paper ${PAPER_VERSION}..."
  url=$(curl -fsS "https://fill.papermc.io/v3/projects/paper/versions/${PAPER_VERSION}/builds/latest" \
    | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
  curl -fsS -o paper.jar "$url"
fi

if ! grep -qs '^eula=true' eula.txt; then
  echo "Read https://aka.ms/MinecraftEULA and set eula=true in eula.txt first."
  exit 1
fi

exec java -Xmx"$RAM" -jar paper.jar nogui

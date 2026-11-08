#!/usr/bin/env bash
# ==============================================================================
# Minecraft Server launcher: PaperMC + ViaVersion suite + Geyser/Floodgate + Grim
#
#   ./start.sh                 download what is missing, then start the server
#   ./start.sh --update        re-download the server and all plugins first
#   MC_VERSION=26.2 ./start.sh pin a Minecraft version (default: latest supported)
#   MEMORY=6G ./start.sh       heap size (default: 4G)
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"

MEMORY="${MEMORY:-4G}"
UA="Minecraft-Server-start.sh (github.com/n95460754/Minecraft-Server)"
PAPER_API="https://fill.papermc.io/v3/projects/paper"
UPDATE=0
[[ "${1:-}" == "--update" ]] && UPDATE=1

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
api()  { curl -fsSL -A "$UA" "$1"; }
fetch() { # fetch <url> <dest>  (atomic: never leaves a half-written jar)
  curl -fL --retry 3 -A "$UA" -o "$2.part" "$1" && mv "$2.part" "$2"
}

for cmd in curl jq java; do
  command -v "$cmd" >/dev/null || die "'$cmd' is not installed."
done

# ---- 1. Pick the Minecraft version -------------------------------------------
if [[ -z "${MC_VERSION:-}" ]]; then
  MC_VERSION=$(api "$PAPER_API/versions" |
    jq -r '[.versions[] | select(.version.support.status=="SUPPORTED")][0].version.id')
fi
[[ -n "$MC_VERSION" && "$MC_VERSION" != "null" ]] || die "Could not determine a Paper version."
VERSION_INFO=$(api "$PAPER_API/versions/$MC_VERSION") || die "Paper has no version '$MC_VERSION'."

# ---- 2. Java check ------------------------------------------------------------
NEED_JAVA=$(jq -r '.version.java.version.minimum' <<<"$VERSION_INFO")
JAVA_BIN=java
HAVE_JAVA=$(java -version 2>&1 | awk -F'"' '/version/{split($2,v,"."); print v[1]; exit}')
if (( HAVE_JAVA < NEED_JAVA )); then
  # Several JDKs may be installed side by side; pick a new enough one.
  for j in /usr/lib/jvm/java-*-openjdk*/bin/java; do
    n=$(basename "$(dirname "$(dirname "$j")")" | grep -oE '[0-9]+' | head -1)
    if [[ -x "$j" ]] && (( n >= NEED_JAVA )); then JAVA_BIN="$j"; HAVE_JAVA=$n; break; fi
  done
fi
(( HAVE_JAVA >= NEED_JAVA )) ||
  die "Minecraft $MC_VERSION needs Java $NEED_JAVA+ (found $HAVE_JAVA). Try: sudo apt-get install -y openjdk-$NEED_JAVA-jre-headless"

# ---- 3. Paper server jar ------------------------------------------------------
BUILD_JSON=$(api "$PAPER_API/versions/$MC_VERSION/builds/latest")
BUILD_ID=$(jq -r '.id' <<<"$BUILD_JSON")
BUILD_URL=$(jq -r '.downloads["server:default"].url' <<<"$BUILD_JSON")
CURRENT=$(cat .paper-version 2>/dev/null || true)
if [[ ! -f server.jar || "$CURRENT" != "$MC_VERSION-$BUILD_ID" ]]; then
  log "Downloading Paper $MC_VERSION build #$BUILD_ID"
  fetch "$BUILD_URL" server.jar
  echo "$MC_VERSION-$BUILD_ID" > .paper-version
else
  log "Paper $MC_VERSION build #$BUILD_ID is up to date"
fi

# ---- 4. Plugins ---------------------------------------------------------------
mkdir -p plugins

modrinth() { # modrinth <project-slug> <dest-file>
  local slug=$1 dest=plugins/$2 q url
  [[ -f "$dest" && $UPDATE == 0 ]] && return
  q='loaders=%5B%22paper%22%5D'
  # Prefer a build tagged for this exact game version, else the newest one.
  url=$(api "https://api.modrinth.com/v2/project/$slug/version?$q&game_versions=%5B%22$MC_VERSION%22%5D" |
        jq -r '.[0].files[] | select(.primary) | .url' 2>/dev/null | head -1)
  [[ -n "$url" ]] || url=$(api "https://api.modrinth.com/v2/project/$slug/version?$q" |
        jq -r '.[0].files[] | select(.primary) | .url' | head -1)
  [[ -n "$url" ]] || { echo "  ! no Paper build found for $slug, skipping"; return; }
  log "Downloading $slug"
  fetch "$url" "$dest"
}

geyser() { # geyser <project> <dest-file>
  local dest=plugins/$2
  [[ -f "$dest" && $UPDATE == 0 ]] && return
  log "Downloading $1"
  fetch "https://download.geysermc.org/v2/projects/$1/versions/latest/builds/latest/downloads/spigot" "$dest"
}

modrinth viaversion   ViaVersion.jar     # newer Java clients
modrinth viabackwards ViaBackwards.jar   # older Java clients (1.10+)
modrinth viarewind    ViaRewind.jar      # very old Java clients (1.7-1.8)
modrinth grimac       GrimAC.jar         # anticheat
geyser   geyser       Geyser-Spigot.jar  # Bedrock clients (UDP 19132)
geyser   floodgate    floodgate-spigot.jar

# ---- 5. EULA ------------------------------------------------------------------
if ! grep -q '^eula=true' eula.txt 2>/dev/null; then
  log "By running this server you accept the Minecraft EULA: https://aka.ms/MinecraftEULA"
  echo "eula=true" > eula.txt
fi

# ---- 6. Launch with Paper's recommended JVM flags for this version -------------
mapfile -t FLAGS < <(jq -r '.version.java.flags.recommended[]' <<<"$VERSION_INFO")
log "Starting Minecraft $MC_VERSION on Java $HAVE_JAVA with ${MEMORY} heap"
log "Java: port 25565/tcp   Bedrock: port 19132/udp   Stop: type 'stop'"
exec "$JAVA_BIN" -Xms"$MEMORY" -Xmx"$MEMORY" "${FLAGS[@]}" -jar server.jar --nogui

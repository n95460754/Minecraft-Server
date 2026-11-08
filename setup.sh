#!/bin/bash
# ==============================================================================
# UNIVERSAL MINECRAFT 26.x SETUP SCRIPT (Java 25 + Crossplay + GrimAC)
# Compatible with Claude Code Cloud & Local Ubuntu/Debian Machines
#
# Инсталира само системните зависимости. Сървърът и плъгините ги сваля
# ./start.sh (автоматично последната поддържана версия на Paper).
# ==============================================================================
set -euo pipefail # Спира изпълнението при грешка

SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

if ! command -v apt-get >/dev/null; then
    echo "❌ Скриптът поддържа само Debian/Ubuntu (apt-get)."
    echo "   Инсталирай ръчно Java 25+, curl и jq, после пусни ./start.sh"
    exit 1
fi

echo "🚀 Стартиране на инсталацията на универсалния Minecraft 26.x сървър..."

# 1. Системни зависимости
echo "📦 Инсталиране на системни зависимости..."
$SUDO apt-get update -y
$SUDO apt-get install -y wget curl jq git tmux screen gnupg ca-certificates

# 2. Java 25 (Eclipse Temurin от официалното apt хранилище на Adoptium)
echo "☕ Инсталиране на Java 25 (Temurin)..."
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-}")
KEYRING=/etc/apt/keyrings/adoptium.asc
if [[ -n "$CODENAME" ]] &&
   curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public -o /tmp/adoptium.asc &&
   grep -q "BEGIN PGP PUBLIC KEY BLOCK" /tmp/adoptium.asc; then
    $SUDO mkdir -p /etc/apt/keyrings
    $SUDO install -m 644 /tmp/adoptium.asc "$KEYRING"
    echo "deb [signed-by=$KEYRING] https://packages.adoptium.net/artifactory/deb $CODENAME main" |
        $SUDO tee /etc/apt/sources.list.d/adoptium.list > /dev/null
fi

if $SUDO apt-get update -y && $SUDO apt-get install -y temurin-25-jdk; then
    echo "✅ Temurin 25 е инсталиран."
else
    # Ако Adoptium не е достъпен (или няма пакет за тази дистрибуция),
    # чистим източника, за да не чупи apt, и ползваме OpenJDK 25.
    echo "⚠️ Temurin 25 не може да се инсталира. Използване на OpenJDK 25..."
    $SUDO rm -f /etc/apt/sources.list.d/adoptium.list
    $SUDO apt-get update -y
    $SUDO apt-get install -y openjdk-25-jre-headless
fi

echo "☕ Проверка на инсталираната Java версия:"
java -version

chmod +x "$(dirname "$0")/start.sh"

echo "=============================================================================="
echo "🎉 Готово! Стартирай сървъра с:"
echo "👉 ./start.sh"
echo "   (в tmux, за да остане жив след затваряне на терминала: tmux new -s mc ./start.sh)"
echo "=============================================================================="

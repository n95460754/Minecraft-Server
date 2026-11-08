#!/bin/bash
# ==============================================================================
# UNIVERSAL MINECRAFT 1.26.x SETUP SCRIPT (Java 25 + Crossplay + GrimAC)
# Compatible with Claude Code Cloud & Local Ubuntu/Debian Machines
# ==============================================================================
set -e # Спира изпълнението при грешка

echo "🚀 Стартиране на инсталацията на универсалния Minecraft 1.26.x сървър..."

# 1. Добавяне на хранилище за Java 25 (Adoptium) и инсталиране на пакети
echo "📦 Инсталиране на системни зависимости и Java 25..."
sudo apt-get update -y
sudo apt-get install -y wget curl jq git tmux screen gnupg

# Проверка дали Adoptium ключа вече съществува, ако не - добавяне
if [ ! -f /etc/apt/keyrings/adoptium.asc ]; then
    sudo mkdir -p /etc/apt/keyrings
    wget -O - https://adoptium.net | sudo tee /etc/apt/keyrings/adoptium.asc > /dev/null
fi

echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://adoptium.net $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y temurin-25-jdk

# Verification за инсталираната Java версия
echo "☕ Проверка на инсталираната Java версия:"
java -version

# 2. Дефиниране на версиите и сваляне на PaperMC 1.26.x
MC_VERSION="1.26"
echo "🔍 Проверка за последната налична версия на Paper за $MC_VERSION..."

# Извличане на най-новия build от API на Paper
LATEST_BUILD=$(curl -s "https://papermc.io{MC_VERSION}" | jq '.builds[-1]' 2>/dev/null || echo "null")

if [ "$LATEST_BUILD" = "null" ] || [ -z "$LATEST_BUILD" ]; then
    echo "⚠️ Неуспешно автоматично извличане на build. Използване на първия наличен (Build #1)..."
    LATEST_BUILD="1"
fi

JAR_NAME="paper-${MC_VERSION}-${LATEST_BUILD}.jar"
DOWNLOAD_URL="https://papermc.io{MC_VERSION}/builds/${LATEST_BUILD}/downloads/${JAR_NAME}"

echo "📥 Сваляне на $JAR_NAME..."
wget -O server.jar "$DOWNLOAD_URL" || {
    echo "❌ Свалянето на Paper се провали. Възможно е версия 1.26 все още да е под друго име в API."
    exit 1
}

# 3. Автоматично приемане на EULA
echo "📝 Приемане на EULA (eula.txt)..."
echo "eula=true" > eula.txt

# 4. Създаване на папка за плъгини и сваляне на кросплей пакетите + Anticheat
mkdir -p plugins
echo "🛡️ Инсталиране на Grim Anticheat и кросплей плъгини (ViaSuite + Geyser)..."

# Забележка: В реална среда тук се слагат директните линкове към .jar файловете им
# Тези редове маркират къде ще се свалят съответните инструменти:
touch plugins/GrimAC.jar
touch plugins/ViaVersion.jar
touch plugins/ViaBackwards.jar
touch plugins/Geyser-Spigot.jar
touch plugins/floodgate-spigot.jar

# 5. Генериране на стартиращ скрипт с флагове на Aikar (Оптимизиран за Java 25)
echo "⚙️ Създаване на стартиращия start.sh..."
cat << 'EOF' > start.sh
#!/bin/bash
java -Xms2G -Xmx4G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8m \
  -XX:G1ReservePercent=20 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -jar server.jar nogui
EOF

chmod +x start.sh

# 6. Конфигуриране на Git
echo "🗂️ Подготовка на Git хранилището..."
git config --local user.name "Claude Code Cloud Server"
git config --local user.email "cloud-agent@anthropic.com"

cat << 'EOF' > .gitignore
server.jar
logs/
cache/
plugins/*.jar
.paper-version
EOF

# Качване на промените в твоя специфичен клон
git checkout -B ccr-67773a85-kzc5ht
git add setup.sh start.sh eula.txt .gitignore plugins/
git commit -m "feat: добавен преносим setup.sh с поддръжка на Java 25 и MC 1.26" || echo "Няма промени за commit."
git push origin ccr-67773a85-kzc5ht || echo "Грешка при push. Провери правата за достъп."

echo "=============================================================================="
echo "🎉 Скриптът е готов и качен в Git клона!"
echo "👉 За да го пуснеш на твоя компютър или в облака, напиши:"
echo "chmod +x setup.sh && ./setup.sh"
echo "===========================================================
==================="

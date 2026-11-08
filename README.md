# Minecraft-Server

Paper 26.3 server (Minecraft 26.3).

## Start

Requirements: **Java 25+**.

1. Read the [Minecraft EULA](https://aka.ms/MinecraftEULA) and, if you agree, put `eula=true` in `eula.txt`.
2. Run:

```bash
./start.sh            # same as: java -Xmx2G -jar paper.jar nogui
RAM=4G ./start.sh     # more RAM
```

`start.sh` downloads `paper.jar` automatically if it is missing.

## Play with friends (playit.gg)

In a second terminal, while the server is running:

```bash
./playit.sh
```

1. On first run it prints a **claim link**. Open it and log in at playit.gg.
2. Add a tunnel of type **Minecraft Java**, local port `25565`.
3. playit gives you an address like `something.joinmc.link`. Send it to your friends.

Windows: download the installer from https://playit.gg/download instead.

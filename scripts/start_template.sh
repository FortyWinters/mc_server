#!/bin/bash
# minecraft_server/scripts/start_template.sh

SERVER_DIR="/opt/minecraft/server/REPLACE_ME"
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"
JAR_FILE="server.jar"  # 會由 run.sh 替換

cd "$SERVER_DIR" || exit 1

if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JAR file not found: $JAR_FILE"
    exit 1
fi

echo "Starting Minecraft server in $SERVER_DIR..."

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "Error: Screen session $SCREEN_NAME is already running."
    echo "You can attach it using: screen -r $SCREEN_NAME"
    exit 1
fi

screen -dmS "$SCREEN_NAME" java -Xmx8G -Xms4G -jar "$JAR_FILE" nogui

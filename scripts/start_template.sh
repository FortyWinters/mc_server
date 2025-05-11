#!/bin/bash

SERVER_DIR="/opt/minecraft/server/REPLACE_ME"
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"

cd "$SERVER_DIR" || exit 1

echo "Starting Minecraft server in $SERVER_DIR..."

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "Error: Screen session $SCREEN_NAME is already running."
    echo "You can attach it using: screen -r $SCREEN_NAME"
    exit 1
fi

screen -dmS "$SCREEN_NAME" java -Xmx2G -Xms1G -jar server.jar nogui

#!/bin/bash

SERVER_DIR="WORK_DIR"
JAR_FILE="JAR_FILE"
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"

cd "$SERVER_DIR" || exit 1

if [ ! -f "$JAR_FILE" ]; then
    echo "$JAR_FILE not found"
    exit 1
fi

echo "starting mc server in $SERVER_DIR..."

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "screen session $SCREEN_NAME is already running."
    echo "you can attach it with './manage.sh attach'"
    exit 1
fi

screen -dmS "$SCREEN_NAME" java -Xmx8G -Xms4G -jar "$JAR_FILE" nogui

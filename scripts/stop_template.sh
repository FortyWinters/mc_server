#!/bin/bash

SERVER_DIR=""
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"

echo "Stopping Minecraft server for $SERVER_DIR..."
screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"

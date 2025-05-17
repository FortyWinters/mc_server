#!/bin/bash

SERVER_DIR="WORK_DIR"
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"

if [ "$SKIP_BACKUP" != "true" ]; then
    BACKUP_SCRIPT="$SERVER_DIR/scripts/backup.sh"
    if [ -x "$BACKUP_SCRIPT" ]; then
        echo "stop.sh triggered. Starting backup..."
        SKIP_BACKUP=true bash "$BACKUP_SCRIPT"
    else
        echo "backup script not found or not executable: $BACKUP_SCRIPT"
    fi
fi

echo "stopping mc server for $SERVER_DIR..."

if screen -list | grep -q "$SCREEN_NAME"; then
    screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"
    echo "stop command sent to $SCREEN_NAME"
else
    echo "screen session $SCREEN_NAME not found, server may not be running."
fi

exit 0

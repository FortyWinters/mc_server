#!/bin/bash

export SKIP_BACKUP=true

SERVER_DIR="WORK_DIR"
BACKUP_DIR="BACKUP_DIR"

START_SCRIPT="$SERVER_DIR/start.sh"
STOP_SCRIPT="$SERVER_DIR/stop.sh"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FOLDER_NAME=$(basename "$SERVER_DIR")
BACKUP_FILE="$BACKUP_DIR/${FOLDER_NAME}-${TIMESTAMP}.tar.gz"

echo "$(date) - Stopping server before backup..."
if bash "$STOP_SCRIPT"; then
    echo "server stopped."
else
    echo "failed to stop server."
    exit 1
fi

echo "backing up $SERVER_DIR to $BACKUP_FILE"
mkdir -p "$BACKUP_DIR"

if tar -czf "$BACKUP_FILE" -C "$SERVER_DIR" .; then
    echo "backup successful."
else
    echo "backup failed!"
    bash "$START_SCRIPT"
    exit 1
fi

echo "cleaning up backups older than 7 days in $BACKUP_DIR"
find "$BACKUP_DIR" -name "${FOLDER_NAME}-*.tar.gz" -type f -mtime +7 -exec rm -f {} \;

echo "restarting server after backup..."
if bash "$START_SCRIPT"; then
    echo "server restarted."
else
    echo "failed to restart server!"
    exit 1
fi

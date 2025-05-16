#!/bin/bash
# minecraft_server/scripts/backup_template.sh

export SKIP_BACKUP=true  # 通知 stop.sh 不要再回頭觸發 backup.sh

# 這些會在 run.sh 中被替換
SERVER_DIR="/opt/minecraft/server/default"
BACKUP_DIR="/storage/minecraft_backup/default"

START_SCRIPT="$SERVER_DIR/start.sh"
STOP_SCRIPT="$SERVER_DIR/stop.sh"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FOLDER_NAME=$(basename "$SERVER_DIR")
BACKUP_FILE="$BACKUP_DIR/${FOLDER_NAME}-${TIMESTAMP}.tar.gz"

echo "[INFO] $(date) - Stopping server before backup..."
if bash "$STOP_SCRIPT"; then
    echo "[INFO] Server stopped."
else
    echo "[ERROR] Failed to stop server."
    exit 1
fi

echo "[INFO] Backing up $SERVER_DIR to $BACKUP_FILE"
mkdir -p "$BACKUP_DIR"

if tar -czf "$BACKUP_FILE" -C "$SERVER_DIR" .; then
    echo "[INFO] Backup successful."
else
    echo "[ERROR] Backup failed!"
    bash "$START_SCRIPT"
    exit 1
fi

echo "[INFO] Cleaning up backups older than 7 days in $BACKUP_DIR"
find "$BACKUP_DIR" -name "${FOLDER_NAME}-*.tar.gz" -type f -mtime +7 -exec rm -f {} \;

echo "[INFO] Restarting server after backup..."
if bash "$START_SCRIPT"; then
    echo "[INFO] Server restarted."
else
    echo "[ERROR] Failed to restart server!"
    exit 1
fi

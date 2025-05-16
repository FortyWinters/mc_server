#!/bin/bash
# minecraft_server/scripts/stop_template.sh

SERVER_DIR="/opt/minecraft/server/REPLACE_ME"
SCREEN_NAME="mc-$(basename "$SERVER_DIR")"

# 防止 backup.sh → stop.sh → backup.sh 形成循環
if [ "$SKIP_BACKUP" != "true" ]; then
    BACKUP_SCRIPT="$SERVER_DIR/scripts/backup.sh"
    if [ -x "$BACKUP_SCRIPT" ]; then
        echo "[INFO] stop.sh triggered. Starting backup..."
        SKIP_BACKUP=true bash "$BACKUP_SCRIPT"
    else
        echo "[WARN] Backup script not found or not executable: $BACKUP_SCRIPT"
    fi
fi

echo "[INFO] Stopping Minecraft server for $SERVER_DIR..."

# 判斷 screen session 是否存在，避免錯誤
if screen -list | grep -q "$SCREEN_NAME"; then
    screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"
    echo "[INFO] Stop command sent to $SCREEN_NAME"
else
    echo "[WARN] Screen session $SCREEN_NAME not found. Server may not be running."
fi

exit 0

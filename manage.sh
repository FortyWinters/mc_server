#!/bin/bash
# /opt/minecraft/manage.sh

ROOT_DIR="/opt/minecraft"
SYSTEMD_DIR="/etc/systemd/system"

# 自動偵測當前啟用中的 minecraft-xxx.service
CURRENT_SERVICE=$(systemctl list-unit-files | grep enabled | grep "^minecraft-" | awk '{print $1}')
if [ -z "$CURRENT_SERVICE" ]; then
    echo "[ERROR] No enabled minecraft service found."
    exit 1
fi

VERSION=$(echo "$CURRENT_SERVICE" | sed -E 's/^minecraft-(.+)\.service$/\1/')
WORK_DIR="$ROOT_DIR/server/$VERSION"
SCRIPTS_DIR="$WORK_DIR/scripts"

case "$1" in
    start)
        echo "[INFO] Starting service: $CURRENT_SERVICE"
        systemctl start "$CURRENT_SERVICE"
        ;;
    stop)
        echo "[INFO] Stopping service and performing backup..."
        "$SCRIPTS_DIR/stop.sh"
        ;;
    backup)
        echo "[INFO] Performing full backup (stop -> backup -> start)..."
        "$SCRIPTS_DIR/stop.sh"
        sleep 2
        "$SCRIPTS_DIR/start.sh"
        ;;
    attach)
        echo "[INFO] Attaching to screen session for version $VERSION..."
        screen -r "mc-$VERSION"
        ;;
    *)
        echo "Usage: $0 {start|stop|backup|attach}"
        ;;
esac

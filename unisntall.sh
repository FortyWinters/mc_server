#!/bin/bash
# /opt/minecraft/uninstall.sh

ROOT_DIR="/opt/minecraft"
SCRIPTS_DIR="$ROOT_DIR/scripts"
BACKUP_ROOT="/storage/minecraft_backup"

while getopts "ho:" opt; do
    case $opt in
        h)
            echo "Usage: $0 -o <folder>"
            exit 0
            ;;
        o)
            SERVER_FOLDER="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -z "$SERVER_FOLDER" ]; then
    echo "[ERROR] You must specify a server folder name using -o"
    exit 1
fi

SERVICE_NAME="minecraft-$SERVER_FOLDER.service"
WORK_DIR="$ROOT_DIR/server/$SERVER_FOLDER"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
BACKUP_DIR="$BACKUP_ROOT/$SERVER_FOLDER"
CRON_LINE_MATCH="$WORK_DIR/scripts/backup.sh"

read -p "Are you sure you want to uninstall Minecraft server '$SERVER_FOLDER'? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstall canceled."
    exit 0
fi

# 停止服務
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "[INFO] Stopping service $SERVICE_NAME"
    systemctl stop "$SERVICE_NAME"
fi

# 禁用並移除服務
systemctl disable "$SERVICE_NAME"
rm -f "$SERVICE_PATH"
systemctl daemon-reload
echo "[INFO] Systemd service removed."

# 移除 cron 任務
echo "[INFO] Removing cron job for backup..."
crontab -l | grep -vF "$CRON_LINE_MATCH" | crontab -
echo "[INFO] Cron job removed."

# 不刪除備份資料
echo "[INFO] Backup directory retained at: $BACKUP_DIR"

# 選擇是否刪除 server 檔案
read -p "Do you want to delete the server directory '$WORK_DIR'? [y/N]: " delete_dir
if [[ "$delete_dir" =~ ^[Yy]$ ]]; then
    rm -rf "$WORK_DIR"
    echo "[INFO] Server directory deleted."
else
    echo "[INFO] Server directory retained."
fi

echo "[INFO] Uninstallation complete."

#!/bin/bash

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
    echo "you must specify a server folder name using -o"
    exit 1
fi

SERVICE_NAME="minecraft-$SERVER_FOLDER.service"
WORK_DIR="$ROOT_DIR/server/$SERVER_FOLDER"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
BACKUP_DIR="$BACKUP_ROOT/$SERVER_FOLDER"
CRON_LINE_MATCH="$WORK_DIR/scripts/backup.sh"

read -p "are you sure you want to uninstall mc server '$SERVER_FOLDER'? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "uninstall canceled."
    exit 0
fi

if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "stopping service $SERVICE_NAME"
    systemctl stop "$SERVICE_NAME"
fi

systemctl disable "$SERVICE_NAME"
rm -f "$SERVICE_PATH"
systemctl daemon-reload
echo "systemd service removed."

echo "removing cron job for backup..."
crontab -l | grep -vF "$CRON_LINE_MATCH" | crontab -
echo "cron job removed."

echo "backup directory retained at: $BACKUP_DIR"

read -p "do you want to delete the server directory '$WORK_DIR'? [y/N]: " delete_dir
if [[ "$delete_dir" =~ ^[Yy]$ ]]; then
    rm -rf "$WORK_DIR"
    echo "server directory deleted."
else
    echo "server directory retained."
fi

echo "uninstallation complete."

#!/bin/bash

ROOT_DIR="/opt/minecraft"
SYSTEMD_DIR="/etc/systemd/system"

CURRENT_SERVICE=$(systemctl list-unit-files | grep enabled | grep "^minecraft-" | awk '{print $1}')
if [ -z "$CURRENT_SERVICE" ]; then
    echo "no enabled minecraft service found."
    exit 1
fi

VERSION=$(echo "$CURRENT_SERVICE" | sed -E 's/^minecraft-(.+)\.service$/\1/')
WORK_DIR="$ROOT_DIR/server/$VERSION"
SCRIPTS_DIR="$WORK_DIR/scripts"

case "$1" in
    start)
        echo "starting service: $CURRENT_SERVICE"
        systemctl start "$CURRENT_SERVICE"
        ;;
    stop)
        echo "stopping service and performing backup..."
        systemctl stop "$CURRENT_SERVICE"
        systemctl disable "$CURRENT_SERVICE"
        ;;
    backup)
        echo "performing full backup (stop -> backup -> start)..."
        "$SCRIPTS_DIR/backup.sh"
        ;;
    attach)
        echo "attaching to screen session for version $VERSION..."
        screen -r "mc-$VERSION"
        ;;
    *)
        echo "Usage: $0 {start|stop|backup|attach}"
        ;;
esac

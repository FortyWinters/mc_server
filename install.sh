#!/bin/bash

ROOT_DIR="/opt/minecraft"
SCRIPTS_DIR="$ROOT_DIR/scripts"
BACKUP_DIR="/storage/minecraft_backup"

create_dir_if_not_exists() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "creating directory: $dir_path"
        mkdir -p "$dir_path"
    fi
}

if [ "$(pwd)" != "$ROOT_DIR" ]; then
    echo "install.sh must be run from $ROOT_DIR"
    echo "current directory: $(pwd)"
    exit 1
fi

while getopts "ho:" opt; do
    case $opt in
        h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -o <folder>   Specify the Minecraft server folder name"
            echo "  -h            Show this help message"
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

SERVER_FOLDER="${SERVER_FOLDER:-default}"
WORK_DIR="$ROOT_DIR/server/$SERVER_FOLDER"
SCRIPTS_TARGET_DIR="$WORK_DIR/scripts"

if [ ! -d "$WORK_DIR" ]; then
    echo "$WORK_DIR does not exist"
    exit 1
fi

create_dir_if_not_exists "$SCRIPTS_TARGET_DIR"
create_dir_if_not_exists "$BACKUP_DIR/$SERVER_FOLDER"

check_and_stop_other_services() {
    local current_service="minecraft-$SERVER_FOLDER.service"
    local running_services
    running_services=$(systemctl list-units --type=service --state=running | grep "minecraft-" | awk '{print $1}')

    for service in $running_services; do
        if [ "$service" != "$current_service" ]; then
            echo "stopping and disabling other Minecraft service: $service"
            systemctl stop "$service"
            systemctl disable "$service"
        fi
    done
}

check_and_modify_eula() {
    local eula_file="$1"
    if [ ! -f "$eula_file" ]; then
        echo "eula.txt not found at $eula_file"
        exit 1
    fi
    sed -i 's/eula=false/eula=true/' "$eula_file"
    echo "eula.txt has been set to eula=true"
}

check_and_modify_server_properties() {
    local server_properties_file="$1"
    if [ ! -f "$server_properties_file" ]; then
        echo "server.properties not found at $server_properties_file"
        exit 1
    fi
    sed -i 's/online-mode=true/online-mode=false/' "$server_properties_file"
    echo "server.properties set to online-mode=false"
}

check_and_stop_other_services

jar_file=$(find "$WORK_DIR" -maxdepth 1 -type f -name "*.jar" | head -n 1)
if [ -z "$jar_file" ]; then
    echo "No .jar file found in $WORK_DIR, using default.jar"
    jar_file="$WORK_DIR/default.jar"
fi
JAR_FILE=$(basename "$jar_file")

SERVICE_PATH="/etc/systemd/system/minecraft-$SERVER_FOLDER.service"
SERVICE_TEMPLATE="$SCRIPTS_DIR/minecraft_template.service"

cp "$SCRIPTS_DIR/start_template.sh" "$SCRIPTS_TARGET_DIR/start.sh"
cp "$SCRIPTS_DIR/stop_template.sh" "$SCRIPTS_TARGET_DIR/stop.sh"
cp "$SCRIPTS_DIR/backup_template.sh" "$SCRIPTS_TARGET_DIR/backup.sh"
cp -f "$SERVICE_TEMPLATE" "$SERVICE_PATH"

sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/start.sh"
sed -i "s|^JAR_FILE=.*|JAR_FILE=\"$JAR_FILE\"|" "$SCRIPTS_TARGET_DIR/start.sh"
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/stop.sh"
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/backup.sh"
sed -i "s|^BACKUP_DIR=.*|BACKUP_DIR=\"$BACKUP_DIR/$SERVER_FOLDER\"|" "$SCRIPTS_TARGET_DIR/backup.sh"
sed -i \
    -e "s|%SERVER_FOLDER%|$SERVER_FOLDER|g" \
    -e "s|%WORK_DIR%|$WORK_DIR|g" \
    "$SERVICE_PATH"

chmod 755 "$SCRIPTS_TARGET_DIR/"*.sh
chmod 644 "$SERVICE_PATH"

check_and_modify_eula "$WORK_DIR/eula.txt"
check_and_modify_server_properties "$WORK_DIR/server.properties"

CRON_JOB="0 4 * * * $SCRIPTS_TARGET_DIR/backup.sh >> $WORK_DIR/backup.log 2>&1"

(crontab -l 2>/dev/null | grep -F "$WORK_DIR/backup.sh") >/dev/null
if [ $? -ne 0 ]; then
    echo "adding cron job for daily backup at 04:00..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "cron job added."
else
    echo "cron job for backup already exists. Skipping."
fi

systemctl daemon-reload
systemctl enable "minecraft-$SERVER_FOLDER"

echo "installation completed successfully"
echo "you need modify $WORK_DIR/scripts/start.sh at first"
echo "then start the server with './manage.sh start'"

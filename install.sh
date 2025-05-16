#!/bin/bash
# /opt/minecraft/install.sh

ROOT_DIR="/opt/minecraft"
BACKUP_DIR="/storage/minecraft_backup"
SCRIPTS_DIR="$ROOT_DIR/scripts"

create_dir_if_not_exists() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path"
    fi
}

if [ "$(pwd)" != "$ROOT_DIR" ]; then
    echo "Error: script must be run from $ROOT_DIR"
    echo "Current directory: $(pwd)"
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
    echo "Error: WORK_DIR does not exist: $WORK_DIR"
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
            echo "[INFO] Stopping and disabling other Minecraft service: $service"
            systemctl stop "$service"
            systemctl disable "$service"
        fi
    done
}

check_and_modify_eula() {
    local eula_file="$1"
    if [ ! -f "$eula_file" ]; then
        echo "Error: eula.txt not found at $eula_file"
        exit 1
    fi
    sed -i 's/eula=false/eula=true/' "$eula_file"
    echo "[INFO] eula.txt has been set to eula=true"
}

check_and_modify_server_properties() {
    local server_properties_file="$1"
    if [ ! -f "$server_properties_file" ]; then
        echo "Error: server.properties not found at $server_properties_file"
        exit 1
    fi
    sed -i 's/online-mode=true/online-mode=false/' "$server_properties_file"
    echo "[INFO] server.properties set to online-mode=false"
}

check_and_stop_other_services

# 找出 JAR 文件名稱
jar_file=$(find "$WORK_DIR" -maxdepth 1 -type f -name "*.jar" | head -n 1)
if [ -z "$jar_file" ]; then
    echo "Error: No .jar file found in $WORK_DIR"
    exit 1
fi
jar_name=$(basename "$jar_file")

# 複製模板腳本到目標 server 的 scripts 子目錄
cp "$SCRIPTS_DIR/start_template.sh" "$SCRIPTS_TARGET_DIR/start.sh"
cp "$SCRIPTS_DIR/stop_template.sh" "$SCRIPTS_TARGET_DIR/stop.sh"
cp "$SCRIPTS_DIR/backup_template.sh" "$SCRIPTS_TARGET_DIR/backup.sh"

# 替換模板中的 SERVER_DIR、BACKUP_DIR、JAR_FILE
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/start.sh"
sed -i "s|^JAR_FILE=.*|JAR_FILE=\"$jar_name\"|" "$SCRIPTS_TARGET_DIR/start.sh"
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/stop.sh"
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$SCRIPTS_TARGET_DIR/backup.sh"
sed -i "s|^BACKUP_DIR=.*|BACKUP_DIR=\"$BACKUP_DIR/$SERVER_FOLDER\"|" "$SCRIPTS_TARGET_DIR/backup.sh"

chmod +x "$SCRIPTS_TARGET_DIR/"*.sh

# 建立 systemd 服務文件
SERVICE_TEMPLATE="$SCRIPTS_DIR/minecraft_template.service"
SERVICE_PATH="/etc/systemd/system/minecraft-$SERVER_FOLDER.service"

if [ ! -f "$SERVICE_TEMPLATE" ]; then
    echo "Error: Service template not found at $SERVICE_TEMPLATE"
    exit 1
fi

sed \
    -e "s|%SERVER_FOLDER%|$SERVER_FOLDER|g" \
    -e "s|%WORK_DIR%|$WORK_DIR|g" \
    "$SERVICE_TEMPLATE" > "$SERVICE_PATH"

chmod 644 "$SERVICE_PATH"
systemctl daemon-reload

# 修改 eula 與 server.properties
check_and_modify_eula "$WORK_DIR/eula.txt"
check_and_modify_server_properties "$WORK_DIR/server.properties"

# 安裝 crontab 備份任務
CRON_JOB="0 4 * * * $SCRIPTS_TARGET_DIR/backup.sh >> $WORK_DIR/backup.log 2>&1"
(crontab -l 2>/dev/null | grep -F "$WORK_DIR/backup.sh") >/dev/null
if [ $? -ne 0 ]; then
    echo "[INFO] Adding cron job for daily backup at 04:00..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "[INFO] Cron job added."
else
    echo "[INFO] Cron job for backup already exists. Skipping."
fi

# 設定 manage.sh 可執行
MANAGE_SCRIPT="$ROOT_DIR/manage.sh"
if [ -f "$MANAGE_SCRIPT" ]; then
    chmod +x "$MANAGE_SCRIPT"
    echo "[INFO] Ensured manage.sh is executable."
fi

# 啟用服務但不啟動
echo "Systemd service installed at: $SERVICE_PATH"
systemctl enable "minecraft-$SERVER_FOLDER"
echo "[INFO] Service enabled but NOT started. Use './manage.sh start' to manually start the server."

echo "Installation completed successfully."

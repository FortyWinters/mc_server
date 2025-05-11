#!/bin/bash

ROOT_DIR="/opt/minecraft"
BACKUP_DIR="/storage/minecraft_backup"
SCRIPTS_DIR="$ROOT_DIR/scripts"

if [ "$(pwd)" != "$ROOT_DIR" ]; then
    echo "Error: script must be run from $ROOT_DIR"
    echo "Current directory: $(pwd)"
    exit 1
fi

create_dir_if_not_exists() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
        mkdir -p "$dir_path"
    fi
}

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

if [ ! -d "$WORK_DIR" ]; then
    echo "Error: WORK_DIR does not exist: $WORK_DIR"
    exit 1
fi

# TODO: 这里不仅要检查其他版本，-o的版本也要查看有没有正在运行的
check_running_services() {
    local running_service
    running_service=$(systemctl list-units --type=service --state=running | grep "minecraft-" | awk '{print $1}')
    
    if [ -n "$running_service" ]; then
        echo "Error: Another Minecraft server is already running:"
        echo "$running_service"
        echo "To stop and disable the current server, run:"
        echo "  systemctl stop $running_service && systemctl disable $running_service"
        exit 1
    fi
}

# TODO：这里有必要吗，一个包里应该不存在两个jar文件的情况，不然就不rename好了，在start.sh中检索
rename_jar_file() {
    local dir_path="$1"
    local new_path="$dir_path/server.jar"

    if [ -e "$new_path" ]; then
        echo "server.jar already exists. Skipping rename."
        return
    fi

    local jar_files=($(find "$dir_path" -maxdepth 1 -type f -name "*.jar"))

    if [ ${#jar_files[@]} -eq 0 ]; then
        echo "Error: No .jar file found in $dir_path"
        exit 1
    elif [ ${#jar_files[@]} -gt 1 ]; then
        echo "Error: Multiple .jar files found in $dir_path:"
        printf "  %s\n" "${jar_files[@]}"
        exit 1
    fi

    if mv "${jar_files[0]}" "$new_path"; then
        echo "Renamed ${jar_files[0]} to server.jar"
    else
        echo "Error: Failed to rename"
        exit 1
    fi
}

check_and_modify_eula() {
    local eula_file="$1"

    if [ ! -f "$eula_file" ]; then
        echo "Error: eula.txt not found at $eula_file"
        exit 1
    fi

    if grep -q "eula=true" "$eula_file"; then
        echo "eula.txt already set to true, skipping."
        return
    fi

    if grep -q "eula=false" "$eula_file"; then
        sed -i 's/eula=false/eula=true/' "$eula_file"
        echo "eula.txt has been updated to eula=true"
        return
    fi

    echo "Error: eula.txt does not contain a valid 'eula=' line"
    exit 1
}

check_and_modify_server_properties() {
    local server_properties_file="$1"

    if [ ! -f "$server_properties_file" ]; then
        echo "Error: server.properties not found at $server_properties_file"
        exit 1
    fi

    if grep -q "online-mode=false" "$server_properties_file"; then
        echo "server.properties already set to online-mode=false, skipping."
        return
    fi

    if grep -q "online-mode=true" "$server_properties_file"; then
        sed -i 's/online-mode=true/online-mode=false/' "$server_properties_file"
        echo "server.properties has been updated to online-mode=false"
        return
    fi

    echo "Error: server.properties does not contain a valid 'online-mode=' line"
    exit 1
}

create_dir_if_not_exists "$BACKUP_DIR"

check_running_services

rename_jar_file "$WORK_DIR"

cp "$SCRIPTS_DIR/start_template.sh" "$WORK_DIR/start.sh"
cp "$SCRIPTS_DIR/stop_template.sh" "$WORK_DIR/stop.sh"

sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$WORK_DIR/start.sh"
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"$WORK_DIR\"|" "$WORK_DIR/stop.sh"

chmod +x "$WORK_DIR/start.sh" "$WORK_DIR/stop.sh"

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

check_and_modify_eula "$WORK_DIR/eula.txt"
check_and_modify_server_properties "$WORK_DIR/server.properties"

echo "Setup completed successfully!"
echo "Systemd service installed at: $SERVICE_PATH"
echo "To enable and start the server, run:"
echo "  systemctl enable minecraft-$SERVER_FOLDER && systemctl start minecraft-$SERVER_FOLDER"

#!/bin/bash

ROOT_DIR="/opt/minecraft"
BACKUP_DIR="/storage/minecraft_backup"

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
    else
        echo "Directory already exists: $dir_path"
    fi
}

while getopts "ho:" opt; do
    case $opt in
        h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -o <folder> Specify the Minecraft server folder name"
            echo "  -h           Show this help message"
            exit 0
            ;;
        o)
            SERVER_FOLDER="$OPTARG"
            ;;
    esac
done

WORK_DIR=$ROOT_DIR/server/$SERVER_FOLDER

create_dir_if_not_exists "$BACKUP_DIR"

create_dir_if_not_exists "$WORK_DIR"

#!/bin/bash

# Wrapper to call the script moved into scripts/ for compatibility.
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")/scripts"
TARGET_SCRIPT="$SCRIPT_DIR/vaultwarden_backup.sh"

if [ ! -x "$TARGET_SCRIPT" ]; then
    # 保证可执行权限
    if [ -f "$TARGET_SCRIPT" ]; then
        chmod +x "$TARGET_SCRIPT" || true
    else
        echo "目标脚本未找到: $TARGET_SCRIPT" >&2
        exit 1
    fi
fi

exec "$TARGET_SCRIPT" "$@"
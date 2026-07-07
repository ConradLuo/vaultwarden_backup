#!/bin/bash
set -euo pipefail

# --- 脚本配置 ---
# 请将 /path/to/your/working/directory 替换为您要执行备份操作的目录路径。
# 确保 'vaultwarden' (源目录) 和 'vaultwarden_backup' (备份目标目录) 都在该目录下，
# 或者自行调整脚本中的路径。
WORKING_DIR="/root" 

# 加密密码（从环境变量 VW_BACKUP_PASSWORD 读取）
PASSWORD="${VW_BACKUP_PASSWORD:-}"

# 临时文件名
TEMP_ARCHIVE="bit.zip"

# 最终文件名
FINAL_ARCHIVE="vaultwarden.zip"

# 备份目标目录
BACKUP_DIR="vaultwarden_backup" 
# --- 脚本配置结束 ---

# 1. 前置依赖与目录检查
if ! command -v 7z &>/dev/null; then
    echo "错误: 系统未安装 7z，请先安装 p7zip 或是 7-Zip。" >&2
    exit 1
fi

# 切换到工作目录
cd "$WORKING_DIR" || { echo "错误: 无法切换到工作目录 $WORKING_DIR" >&2; exit 1; }

if [ ! -d "vaultwarden" ]; then
    echo "错误: 未在 $WORKING_DIR 下找到源目录 'vaultwarden'。" >&2
    exit 1
fi

# 确保备份目标目录存在
mkdir -p "$BACKUP_DIR"

# 2. 注册退出清理钩子，出错或中断时清理临时文件
cleanup() {
    if [ -f "$TEMP_ARCHIVE" ]; then
        echo "清理临时压缩文件..."
        rm -f "$TEMP_ARCHIVE"
    fi
}
trap cleanup EXIT INT TERM

# 3. 创建 7z 压缩文件
# 输出 zip 格式（-tzip）以便云端 Python zipfile 校验；
# 加密时使用 AES-256（-mem=AES256），避免 zip 默认的弱 ZipCrypto。
zip_opts=("a" "-tzip")
if [ -n "$PASSWORD" ]; then
    zip_opts+=("-mem=AES256" "-p$PASSWORD")
else
    echo "警告: 未设置加密密码 (VW_BACKUP_PASSWORD)，备份将不加密。" >&2
fi

7z "${zip_opts[@]}" "$TEMP_ARCHIVE" vaultwarden || { echo "错误: 7z 压缩失败。" >&2; exit 1; }

# 4. 重命名压缩文件
echo "正在重命名文件..."
mv "$TEMP_ARCHIVE" "$FINAL_ARCHIVE"

# 5. 清理旧的备份文件
# 注意：这会删除 vaultwarden_backup 目录下的所有文件和子目录，但保留目录本身
echo "正在清理旧的备份文件..."
rm -rf "$BACKUP_DIR"/*

# 6. 移动新的备份文件到备份目录
echo "正在移动新的备份文件到备份目录..."
mv "$FINAL_ARCHIVE" "$BACKUP_DIR"/

echo "备份任务完成: $BACKUP_DIR/$FINAL_ARCHIVE"

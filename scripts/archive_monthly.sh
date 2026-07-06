#!/usr/bin/env bash
set -euo pipefail

# 获取数据目录路径参数（默认当前目录）
DATA_DIR="${1:-.}"
if [ ! -d "$DATA_DIR" ]; then
  echo "错误: 数据目录不存在: $DATA_DIR" >&2
  exit 1
fi

cd "$DATA_DIR"
echo "正在操作数据目录: $(pwd)"

# 获取当前日期参数进行默认计算
current_day=$(TZ='Asia/Shanghai' date +%d)
current_year=$(TZ='Asia/Shanghai' date +%Y)
current_month=$(TZ='Asia/Shanghai' date +%m)

# 默认计算归档年份、月份和区间（Part）
if [ $((10#$current_day)) -le 15 ]; then
  # 1号到15号之间运行：归档上月 16-月底
  current_15th=$(TZ='Asia/Shanghai' date +%Y-%m-15)
  last_month_date=$(TZ='Asia/Shanghai' date -d "$current_15th -1 month" +%Y-%m)
  default_year="${last_month_date%%-*}"
  default_month="${last_month_date##*-}"
  default_part="16-end"
else
  # 16号及以后运行：归档当月 1-15 号
  default_year="$current_year"
  default_month="$current_month"
  default_part="01-15"
fi

# 支持手动传入年、月、区间参数
year="${2:-$default_year}"
month="${3:-$default_month}"
part="${4:-$default_part}"

# 验证年份和月份参数的格式
if [[ ! "$year" =~ ^[0-9]{4}$ ]] || [[ ! "$month" =~ ^(0[1-9]|1[0-2])$ ]]; then
  echo "错误: 无效的年份或月份格式 ($year / $month)。年份须为 4 位数字，月份须为 01-12。" >&2
  exit 1
fi

# 验证区间参数格式
if [ "$part" != "01-15" ] && [ "$part" != "16-end" ]; then
  echo "错误: 无效的归档区间参数 ($part)。必须为 '01-15' 或 '16-end'。" >&2
  exit 1
fi

src_dir="${year}/${month}"
archives_dir="vaultwarden_backup_archives"

if [ ! -d "$src_dir" ]; then
  echo "没有找到备份目录: $src_dir，已是最新归档状态，退出。"
  exit 0
fi

# 如果源目录为空，直接清理源目录及父级年目录并退出
if [ -z "$(ls -A "$src_dir" 2>/dev/null)" ]; then
  echo "源目录 $src_dir 已空，清理目录并退出。"
  rmdir "$src_dir" 2>/dev/null || true
  rmdir "${year}" 2>/dev/null || true
  exit 0
fi

# 扫描目录下符合归档区间的文件
files_to_zip=()
for file in "${src_dir}"/*; do
  [ -e "$file" ] || continue
  filename=$(basename "$file")
  
  # 匹配带有 8 位数字日期的压缩包文件名（如 vaultwarden_20260706.zip）
  if [[ "$filename" =~ _([0-9]{8})\.zip$ ]]; then
    date_part="${BASH_REMATCH[1]}"
    day="${date_part:6:2}"
    
    # 根据指定的 part 筛选文件
    day_num=$((10#$day))
    if [ "$part" = "01-15" ]; then
      if [ "$day_num" -ge 1 ] && [ "$day_num" -le 15 ]; then
        files_to_zip+=("$file")
      fi
    elif [ "$part" = "16-end" ]; then
      if [ "$day_num" -ge 16 ] && [ "$day_num" -le 31 ]; then
        files_to_zip+=("$file")
      fi
    fi
  else
    echo "警告: 跳过不符合命名格式的文件: $file"
  fi
done

if [ ${#files_to_zip[@]} -eq 0 ]; then
  echo "在 $src_dir 下未找到符合区间 '$part' 的备份文件，无需归档，退出。"
  exit 0
fi

mkdir -p "${archives_dir}/${year}"
archive_name="${archives_dir}/${year}/${year}-${month}-${part}.zip"

if [ -f "$archive_name" ]; then
  echo "归档已存在: $archive_name，无需重复归档，退出。"
  exit 0
fi

echo "正在打包以下文件到 $archive_name :"
printf " - %s\n" "${files_to_zip[@]}"

if ! zip "$archive_name" "${files_to_zip[@]}"; then
  echo "错误: 压缩失败，保留原文件。"
  exit 1
fi

# 验证归档完整性
if ! zip -T "$archive_name"; then
  echo "错误: 归档文件损坏，删除损坏归档并保留原文件。"
  rm -f "$archive_name"
  exit 1
fi

echo "已创建归档: $archive_name"

# 清理已归档的源文件
echo "正在清理已归档的源文件..."
for file in "${files_to_zip[@]}"; do
  rm -f "$file"
done
echo "清理完成。"

# 如果源目录为空，清理源目录及父级年目录
if [ -d "$src_dir" ] && [ -z "$(ls -A "$src_dir" 2>/dev/null)" ]; then
  echo "源目录已空，删除目录: $src_dir"
  rmdir "$src_dir" 2>/dev/null || true
  rmdir "${year}" 2>/dev/null || true
fi

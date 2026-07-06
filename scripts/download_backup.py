import os
import sys
import urllib.request
import urllib.error
from urllib.parse import urlparse, urlunparse
import zipfile
import time
import hashlib

def get_redacted_url(url):
    try:
        parsed = urlparse(url)
        if parsed.query:
            return urlunparse(parsed._replace(query="token=***"))
        return url
    except Exception:
        return "Redacted URL"

def get_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    download_url = os.environ.get("DOWNLOAD_URL", "")
    target_path = "data/" + os.environ.get("TARGET_PATH", "")
    tmp_file = target_path + ".tmp"

    if not download_url:
        print("Error: DOWNLOAD_URL is not set or empty.")
        sys.exit(1)

    redacted_url = get_redacted_url(download_url)
    print(f"Downloading from: {redacted_url}")

    # 下载重试逻辑
    max_retries = 3
    retry_delay = 5
    success = False

    # 构造 Request 并添加 User-Agent 避免部分服务器 (如 Nginx/Cloudflare) 拦截 Python 默认头
    req = urllib.request.Request(
        download_url,
        headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
    )

    for attempt in range(1, max_retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                with open(tmp_file, "wb") as out_file:
                    out_file.write(response.read())
            success = True
            break
        except urllib.error.URLError as e:
            print(f"Attempt {attempt} failed: {e}")
            if attempt < max_retries:
                time.sleep(retry_delay)
        except Exception as e:
            print(f"Attempt {attempt} failed with unexpected error: {e}")
            if attempt < max_retries:
                time.sleep(retry_delay)

    if not success:
        print(f"Error: Failed to download file from {redacted_url} after {max_retries} attempts.")
        sys.exit(1)

    if not os.path.exists(tmp_file) or os.path.getsize(tmp_file) == 0:
        print("Error: Download produced an empty or non-existent file.")
        if os.path.exists(tmp_file):
            os.remove(tmp_file)
        sys.exit(1)

    # 验证 ZIP 包完整性与加密安全性
    print("Verifying ZIP file integrity and encryption security...")
    try:
        with zipfile.ZipFile(tmp_file) as zf:
            # 安全性校验：确保压缩包内的所有文件（排除目录项）都已经被加密
            unencrypted_files = []
            for zinfo in zf.infolist():
                if not zinfo.is_dir() and not (zinfo.flag_bits & 0x1):
                    unencrypted_files.append(zinfo.filename)
            
            if unencrypted_files:
                print("Security Error: The downloaded backup ZIP contains UNENCRYPTED files!")
                print(f"Unencrypted file(s) detected: {unencrypted_files[:5]} ... (total {len(unencrypted_files)})")
                print("为了您的密码隐私安全，已自动拦截该非加密备份，已终止后续的提交与推送。")
                os.remove(tmp_file)
                sys.exit(1)

            # 既然所有文件均已加密，testzip() 在无密码时必定抛出 RuntimeError
            try:
                bad_file = zf.testzip()
                if bad_file is not None:
                    print(f"Error: Corrupt file inside ZIP: {bad_file}")
                    os.remove(tmp_file)
                    sys.exit(1)
            except RuntimeError as e:
                if "encrypted" in str(e) or "password required" in str(e):
                    print("ZIP encryption verified. Basic structural check passed.")
                else:
                    raise e
    except zipfile.BadZipFile:
        print("Error: Downloaded file is not a valid ZIP archive.")
        if os.path.exists(tmp_file):
            os.remove(tmp_file)
        sys.exit(1)

    print("ZIP file integrity verification passed.")

    # SHA256 比较去重
    if os.path.exists(target_path):
        new_sum = get_sha256(tmp_file)
        old_sum = get_sha256(target_path)
        if new_sum == old_sum:
            print(f"Downloaded file identical to existing {target_path} — skipping move and commit.")
            os.remove(tmp_file)
            # 写入 GitHub Actions 环境变量以跳过后续步骤中的 Git 提交
            github_env = os.environ.get('GITHUB_ENV')
            if github_env:
                with open(github_env, 'a') as ge:
                    ge.write("SKIP_COMMIT=true\n")
            sys.exit(0)

    # 覆盖目标文件
    if os.path.exists(target_path):
        os.remove(target_path)
    os.rename(tmp_file, target_path)
    print(f"Saved to {target_path}")

if __name__ == "__main__":
    main()

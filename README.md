#  vaultwarden-backup-githaction
# Vaultwarden 每日自动备份
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/ConradLuo/vaultwarden_backup/blob/master/LICENSE)  [![sponsor](https://img.shields.io/badge/%E2%9D%A4-Sponsor%20me-%23c96198?style=flat&logo=GitHub)](https://github.com/sponsors/ConradLuo)


本项目使用 [GitHub Actions](https://github.com/features/actions) 为您的 [Vaultwarden](https://github.com/dani-garcia/vaultwarden) 实例提供一个简单、自动化且免费的备份解决方案。

它会每天定时从一个固定的 URL 下载您的 Vaultwarden 备份文件（例如，一个导出的 `.zip` 压缩包），然后按日期（`YYYY/MM`）归档，并自动提交到您指定的**私有数据仓库**中。

[![Daily Backup Status](https://github.com/ConradLuo/vaultwarden_backup/actions/workflows/daily_download.yml/badge.svg)](https://github.com/ConradLuo/vaultwarden_backup/actions)


---

## ⚠️ 极度重要：安全警告

> **您的 Vaultwarden 备份文件 = 您的所有密码！**
>
> 备份数据将会自动推送到您专门创建的**私有数据仓库**中（该仓库将包含您密码库的**完整副本**）。
>
> 如果备份文件没有经过强加密，任何能访问您**数据仓库**的人都可以获取您的所有密码和敏感数据。
>
> 因此，您**必须**确保**数据仓库**（即您设置的 `DATA_REPOSITORY` 对应的仓库）被设置为 **PRIVATE (私有)**。
>
> **切勿**将您的**数据仓库**公开，也不要在未删除所有备份数据前将其转为公开。
>
> *注：本脚本仓库（当前仓库）只存放工作流与脚本代码，本身不包含任何备份数据，因此本脚本仓库可以公开。*

---

## 🚀 功能特性

* **双向备份支持 (Hybrid Support)**：
  - **云端拉取**：利用 GitHub Actions 定时从固定链接拉取备份，托管于私有仓库中。
  - **本地打包**：提供 `scripts/vaultwarden_backup.sh` 本地脚本，可在源服务器上直接执行 7z 加密打包并安全归档，带异常退出自动清理机制。
* **敏感隐私脱敏防泄露 (Log Masking)**：云端下载引擎由 Python 驱动，会自动掩码并过滤下载链接中夹带的敏感 Token/授权查询参数（如 `token=***`），防止网络波动重试时将机密泄漏在 Actions 运行日志中。
* **ZIP 完整性双重验证 (Integrity Check)**：每日下载完成后自动运行 `zipfile` 内部校验。如遇传输损坏或鉴权过期下载至报错 HTML 页时自动拦截，**绝不**覆盖已有备份。
* **极佳的可观测性 (Commit Observability)**：每次备份在提交时会自动计算并输出**文件大小**和 **SHA256 校验和**，并在 Git 历史记录的 Commit 详情中直观展现，方便追踪体积变化并对账校验。
* **智能去重提交**：通过 SHA256 指纹比对下载文件，若文件未发生任何更改将自动跳过 Git 提交。
* **高频双周归档 (Bi-weekly Archive)**：每月自动归档两次（1号与16号），分别对上月后半月（16-月底）和当月前半月（01-15）进行打包压缩，生成清晰的归档压缩包（如 `YYYY-MM-01-15.zip` 与 `YYYY-MM-16-end.zip`）。自动删除已归档原文件，对未打包的数据安全留存。

---

## 📁 它是如何工作的？

工作流程（定义在 `.github/workflows/` 中）执行以下步骤：

1. **定时触发 (Schedule)**：`cron` 任务每天在 UTC 00:00 (北京时间 08:00) 自动下载；每月 1 号和 16 号在 UTC 04:00 (北京时间 12:00) 触发对应的双周归档（*注：月度归档的定时默认关闭，需手动运行或解开注释启用*）。
2. **跨仓检出 (Checkout)**：自动将脚本仓库拉取至根目录，并通过您配置的 `PAT_TOKEN` 将私有数据仓单独检出到 `data` 子目录下。
3. **安全下载与校验**：使用安全 Python 脚本下载目标文件，校验 ZIP 有效性，并在比对 SHA256 确认产生变化后，覆盖 `data/YYYY/MM/` 下的原版本。
4. **提交元数据**：动态获取文件大小与校验和，以富文本提交（带 Size 和 SHA256）的形式 Push 回您的私有数据仓库。
5. **双周归档**：
   - **每月 16 号**：将当月前半月（01-15号）备份文件打包压缩为 `data/vaultwarden_backup_archives/YYYY/YYYY-MM-01-15.zip`，并清理源文件。
   - **每月 1 号**：将上月后半月（16-月底）备份文件打包压缩为 `data/vaultwarden_backup_archives/YYYY/YYYY-MM-16-end.zip`，并清理源文件。若整个月份目录被清空，则自动移除空目录。

---

## 🛠️ 如何配置 (Setup)

如果您想在自己的账户下设置这个项目，请按以下步骤操作：

### 1. 云端自动拉取备份配置

1. **创建私有数据仓库**：
   创建一个**新的私有 (Private)** GitHub 仓库（例如命名为 `vaultwarden_backup_data`）专门用于存放备份数据。

2. **生成 Personal Access Token (PAT)**：
   - 访问 GitHub [Personal Access Tokens (Classic)](https://github.com/settings/tokens)。
   - 生成一个具有 `repo` 权限的 Classic Token，供 Actions 读写您的私有数据仓。

3. **在脚本仓库中设置 Secrets**：
   转到本脚本仓库 -> `Settings` -> `Secrets and variables` -> `Actions`。
   - **Secrets (机密信息)** 选项卡中，点击 `New repository secret` 添加：
     - `DOWNLOAD_URL`：您的固定下载链接（例如: `https://my-nas.com/backup.zip?token=...`）
     - `PAT_TOKEN`：刚才生成的 PAT 密钥
     - `DATA_REPOSITORY`：您的私有数据仓库路径（例如: `ConradLuo/vaultwarden_backup_data`）
     - `ORIGINAL_FILENAME`：备份压缩包在仓库中存储的基础文件名（选填，默认为 `vaultwarden`）

4. **立即触发测试**：
   在 `Actions` 标签页，选中对应的 Workflow，手动点击 `Run workflow` 即可立即触发备份下载。

5. **启用定时双周归档（选填）**：
   月度归档工作流（`Monthly Archive Backups`）默认没有开启定时自动运行。如果您希望它在每月 1 号和 16 号自动执行，只需编辑文件 `.github/workflows/monthly_archive.yml`，将 `schedule` 部分的注释（`#`）去掉，并提交到仓库即可。

---

### 2. 本地服务器直接备份配置

如果您需要在运行 Vaultwarden 的 Linux 本地服务器上进行定时打包加密备份：

1. **配置文件路径**：
   打开并修改 [scripts/vaultwarden_backup.sh](scripts/vaultwarden_backup.sh)，将 `WORKING_DIR` 变量修改为您本地 Vaultwarden 源目录所在的父目录路径。
2. **设置加密密码（建议）**：
   在运行环境或脚本中设置环境变量 `VW_BACKUP_PASSWORD`，脚本会使用 `7z` 自动加密打包您的数据（默认生成 `vaultwarden.zip`）。
3. **运行备份**：
   赋予执行权限并运行根目录下的快捷包装脚本即可：
   ```bash
   chmod +x vaultwarden_backup.sh scripts/vaultwarden_backup.sh
   
   # 临时设定加密密码并运行
   VW_BACKUP_PASSWORD="your_secure_password" ./vaultwarden_backup.sh
   ```
4. **加入定时任务 (Crontab)**：
   可通过配置 `crontab -e` 自动实现本地定时静默打包。

---

## 🗂️ 仓库结构示例

### 脚本仓库 (本仓库):
```text
├── scripts/
│   ├── archive_monthly.sh       # 月度归档脚本
│   └── vaultwarden_backup.sh    # 本地打包备份脚本
├── .github/
│   └── workflows/ 
│       ├── daily_download.yml   # 每日安全下载流
│       └── monthly_archive.yml  # 每月自动归档流
├── vaultwarden_backup.sh        # 本地包装器运行脚本
├── README.md
└── LICENSE
```

### 数据仓库 (您的私有数据仓):
```text
├── 2026/ 
│   └── 07/ 
│       ├── vaultwarden_20260706.zip
│       └── ...
├── vaultwarden_backup_archives/
│   └── 2026/
│       ├── 2026-07-01-15.zip    # 前半月归档包
│       └── 2026-07-16-end.zip   # 后半月归档包
└── ...
```

---

## 📄 许可证

本项目代码采用 [MIT License](LICENSE) 授权。您存储在仓库中的备份数据归您自己所有。

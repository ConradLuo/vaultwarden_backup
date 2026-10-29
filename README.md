#  vaultwarden-backup-githaction
# Vaultwarden 每日自动备份
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/ConradLuo/vaultwarden_backup/blob/master/LICENSE)  [![sponsor](https://img.shields.io/badge/%E2%9D%A4-Sponsor-blue.svg)](https://github.com/sponsors/ConradLuo)

[![Daily Backup Status](https://github.com/ConradLuo/vaultwarden_backup/actions/workflows/daily_download.yml/badge.svg)](https://github.com/ConradLuo/vaultwarden_backup/actions)

## 📊 每日执行状态

> 说明：GitHub Actions 可能因为 60 天无提交/无活动而被自动停用。为了让仓库页面上也能持续展示执行状态，以下将每天更新一次“执行记录”。每次实际执行完毕后，请在对应日期记录结果，并保持 README 清晰展示当日状态。

| 日期 | 执行状态 | 备注 |
| --- | --- | --- |
| 2026-10-29 | ✅ 成功 | README 记录当天执行状态，说明备份流程已确认。 |
| 2026-10-30 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-10-31 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-01 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-02 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-03 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-04 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-05 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-06 | ⏳ 待执行 | 每天执行后更新此行。 |
| 2026-11-07 | ⏳ 待执行 | 每天执行后更新此行。 |

> 维护方式：每天执行完备份后，将该日期对应的状态从 `⏳ 待执行` 改为 `✅ 成功` 或 `❌ 失败`，并在备注中简要写明失败原因或成功说明。

本项目使用 [GitHub Actions](https://github.com/features/actions) 为您的 [Vaultwarden](https://github.com/dani-garcia/vaultwarden) 实例提供一个简单、自动化且免费的备份解决方案。

它会每天定时从一个固定的 URL 下载您的 Vaultwarden 备份文件（例如，一个导出的 `.zip` 压缩包），然后按日期（`YYYY/MM`）归档，并自动提交到您指定的私有数据仓库中。

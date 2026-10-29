# 可观测性只读工作台

`observability-readonly` 第一版支持 Sentry，只读取项目状态、未解决错误、Release 和事件统计。它不会发送事件、修改 Issue、创建 Release 或下载完整事件详情。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-observability-report` | 查看 Sentry 配置来源和工具状态 | 低 |
| `tergo-observability-config` | 检查配置是否存在，不显示 Token | 低 |
| `tergo-sentry-status` | 查看项目状态 | 中 |
| `tergo-sentry-issues [limit]` | 查看未解决错误摘要 | 中 |
| `tergo-sentry-releases [limit]` | 查看最近 Release | 中 |
| `tergo-sentry-stats` | 查看按小时聚合的事件数量 | 中 |
| `tergo-observability-links` | 生成 Sentry 项目链接 | 低 |

需要设置 `SENTRY_ORG`、`SENTRY_PROJECT` 和 `SENTRY_AUTH_TOKEN`（或 `SENTRY_ACCESS_TOKEN`）。默认 API 地址为 `https://sentry.io`，可通过 `SENTRY_URL` 指向自建 Sentry。Token 只通过临时权限为 0600 的 curl 配置文件传递，不进入命令参数和输出；响应只经过 jq 提取摘要，避免打印完整事件 payload、用户信息和堆栈。

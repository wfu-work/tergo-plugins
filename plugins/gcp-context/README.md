# GCP 上下文诊断

`gcp-context` 是一个 Google Cloud 专用的只读插件，用来确认当前终端使用哪个 gcloud 配置、账号、项目和区域。第一版只读取 gcloud 配置、身份和 Compute 区域，不执行部署、删除、IAM 权限变更或服务账号操作。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-gcp-report` | 查看 gcloud、项目、区域和凭据来源状态 | 低 |
| `tergo-gcp-config-sources` | 查看配置目录和凭据来源，不读内容 | 低 |
| `tergo-gcp-configs` | 列出 gcloud 配置名称 | 低 |
| `tergo-gcp-identity` | 查看当前活动账号 | 中 |
| `tergo-gcp-context` | 查看配置、项目、区域和可用区 | 低 |
| `tergo-gcp-regions` | 查看项目可见的 Compute 区域 | 中 |
| `tergo-gcp-console-link` | 生成控制台链接 | 低 |

插件复用 gcloud 已有的账号、配置和 Application Default Credentials 状态。不会打印服务账号 JSON、OAuth Token 或凭据文件内容。资源查询、部署、删除和 IAM 权限操作留给后续独立的高风险插件。

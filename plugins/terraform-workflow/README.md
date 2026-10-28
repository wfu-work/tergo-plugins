# Terraform 工作流

`terraform-workflow` 把 Terraform/OpenTofu 的格式、校验、plan 和 workspace 查询集中到 Tergo。第一版只做读取、检查和预览，不执行 `apply`、不自动 `init`、不下载 provider，也不保存云凭据。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-terraform-report` | 查看工具、配置文件和初始化状态 | 低 |
| `tergo-terraform-files` | 发现 `.tf` 和变量文件 | 低 |
| `tergo-terraform-fmt-check` | 检查格式并显示差异 | 低 |
| `tergo-terraform-validate` | 校验配置 | 中 |
| `tergo-terraform-plan` | 预览资源变更 | 中 |
| `tergo-terraform-workspace` | 查看当前 workspace | 低 |
| `tergo-terraform-apply-preview` | 预览 apply 命令 | 低 |

`plan` 可能访问远程状态、锁定后端或在输出中展示资源差异。插件关闭 plan 锁并且不使用 `-out` 保存计划，但用户仍应避免把输出发送到公共日志。真正的 apply、切换 workspace、provider 安装和 backend 初始化留给后续经过确认的高风险流程。

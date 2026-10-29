# AWS 上下文诊断

`aws-context` 是一个 AWS 专用的只读插件，用来确认当前终端使用了哪个 profile、区域和账号。第一版只调用 AWS CLI 的身份和区域查询，不执行部署、删除、权限变更、角色切换或凭据写入。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-aws-report` | 查看 AWS CLI、profile、区域和凭据来源状态 | 低 |
| `tergo-aws-config-sources` | 查看配置文件是否存在，不读内容 | 低 |
| `tergo-aws-profiles` | 列出 profile 名称 | 低 |
| `tergo-aws-identity [profile]` | 查看账号、ARN 和 UserId | 中 |
| `tergo-aws-region [profile]` | 查看默认区域 | 低 |
| `tergo-aws-regions [profile]` | 查看可用区域 | 中 |
| `tergo-aws-console-link [profile]` | 生成控制台链接 | 低 |

插件复用 AWS CLI 已有的 SSO、profile、环境变量和 Web Identity 登录状态。不会打印 Access Key、Secret Key、Session Token、凭据文件或 Web Identity Token。资源查询、部署、删除和 IAM 权限操作留给后续独立的高风险插件。

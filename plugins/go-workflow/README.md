# Go 工作流

`go-workflow` 复用当前项目的 Go 工具链，提供模块报告、源码发现、测试、vet、格式检查、Staticcheck、govulncheck、依赖更新查询和构建预览。

命令不会自动安装工具、整理依赖、下载私有模块、写回源码或发布二进制。`tergo-go-outdated` 可能访问模块代理；请确认当前 Go 环境的网络和私有模块认证配置。

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-go-report` | 查看 Go、模块和检查工具状态 | 低 |
| `tergo-go-files` | 发现 `.go`、`go.mod`、`go.sum` 和 `go.work` | 低 |
| `tergo-go-test` | 运行 `go test ./...` | 中 |
| `tergo-go-vet` | 运行 `go vet ./...` | 中 |
| `tergo-go-fmt-check` | 检查格式，不写回文件 | 低 |
| `tergo-go-staticcheck` | 运行 Staticcheck | 中 |
| `tergo-go-vuln` | 运行 govulncheck | 中 |
| `tergo-go-outdated` | 查询模块更新 | 中 |
| `tergo-go-build-preview` | 预览构建命令 | 低 |

插件只使用官方 Go CLI 和当前 PATH 中的可选工具，不保存凭据；输出报告时应避免把私有模块路径或代理认证信息复制到公共日志。

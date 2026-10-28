# CI 运行工作台

`ci-workflow` 为当前 Git 仓库提供 GitHub Actions 或 GitLab CI 的运行摘要、失败日志和构建产物查看。它复用 `gh` 或 `glab` 的登录状态，不保存 Token。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-ci-report` | 查看 CI CLI 和仓库状态，不访问远程 API | 低 |
| `tergo-ci-status` | 查看最近 CI 运行 | 低 |
| `tergo-ci-runs [count]` | 列出最近运行 | 低 |
| `tergo-ci-log <run>` | 查看失败步骤日志 | 中 |
| `tergo-ci-artifacts <run>` | 列出构建产物或流水线摘要 | 低 |
| `tergo-ci-rerun <run>` | 重跑失败任务 | 高 |

插件优先使用 `gh`，没有 `gh` 时回退到 `glab`。读取命令不会修改仓库；重跑命令由 Tergo 的高风险确认流程保护。插件不会读取、保存或打印 Token，也不会自动下载构建产物。

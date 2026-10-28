# 发布工作流

`release-workflow` 将常见的提交检查、变更摘要、版本检查和发布预览接入 Tergo。所有写操作都经过 Tergo 风险确认；插件只创建本地 Git tag，不会自动推送。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-release-status` | 查看分支、工作区、上游和最近标签 | 低 |
| `tergo-release-commit-check` | 校验最近提交格式 | 低 |
| `tergo-release-changelog` | 生成 Markdown 变更摘要 | 低 |
| `tergo-release-version-check` | 检查项目版本字段 | 低 |
| `tergo-release-preview` | 预览发布标签操作 | 中 |
| `tergo-release-tag` | 创建本地 annotated tag | 高 |

提交格式检查支持 `feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore` 和 `revert`。发布标签要求使用 SemVer，例如 `1.2.3` 或 `v1.2.3`，并且工作区必须干净。

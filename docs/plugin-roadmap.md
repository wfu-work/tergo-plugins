# Tergo 在线插件路线图

这份路线图以当前 Tergo 和 `tergo-plugins` 的实际能力为基础，目标是增加用户愿意长期使用的工作流，而不是把已有的内置命令重新包装一遍。

## 当前边界

Tergo 内置插件已经覆盖了项目上下文、任务和测试、Git、Worktree、代码托管、Docker、Kubernetes 基础查询、SSH、远程会话、Shell 历史、日志和端口诊断。在线插件当前以 `command` 面为主，入口是 zsh/bash 启动脚本，安装后默认关闭。

在线仓库已有四个插件：

| 插件 | 已解决的问题 | 不应继续扩大的范围 |
| --- | --- | --- |
| `developer-toolbox` | 搜索、文件查找、预览、差异阅读和目录体积 | 不再加入通用 Git、任务运行和文件浏览器功能 |
| `database-workbench` | 数据库客户端探测、脱敏配置、只读查询和安全导出 | 不做完整数据库 GUI，不接受密码参数 |
| `security-scanner` | 密钥、依赖和代码扫描 | 不上传源码，不把“修复漏洞”变成自动写入 |
| `release-workflow` | 提交检查、变更摘要、版本检查和发布预览 | 不自动 push、发版或覆盖远程标签 |

因此，下一批插件应优先补足“请求 → 运行 → 结果 → 复盘”的链路，并与 Tergo 已有的 Git、任务和服务面板配合。

## 选择标准

每个候选插件按五项评估：

1. 每周是否会重复使用；
2. 是否能把多个 CLI 操作组合成一个清晰入口；
3. 是否能用只读或预览模式交付第一版；
4. 是否能在没有依赖时保持终端启动并给出安装提示；
5. 是否可以在 zsh 和 bash 中安全传递参数。

高风险写操作必须经过 Tergo 的确认流程，提供 `dry-run` 或预览命令，并且不能把 Token、密码、Cookie、私钥和完整连接串放进参数、日志或报告。

## 推荐优先级

### P0：第一版已实现

#### `api-workbench`：API 调试工作台

这是当前最值得实现的插件。Tergo 已有 HTTP 检查，但它只适合单次探测；真实开发还需要读取项目中的请求模板、发送请求、查看响应和提取 JSON。

第一版命令：

- `tergo-api-list`：发现 `.http`、`requests/`、`api/` 和 OpenAPI 文件；
- `tergo-api-inspect <url>`：执行安全的 HEAD/GET 检查，输出状态、响应头和耗时；
- `tergo-api-run <request>`：运行项目请求模板，默认只允许 GET、HEAD、OPTIONS；
- `tergo-api-json <url> <filter>`：使用 `jq` 提取响应中的字段；
- `tergo-api-report`：汇总 curl、jq 和项目请求目录状态。

边界：请求体、Authorization 和 Cookie 只能来自本地模板或已存在的环境来源，输出必须脱敏；POST、PUT、PATCH、DELETE 在第一版只提供预览，后续再按 `medium` 或 `high` 风险放开。依赖为 `curl` 硬依赖，`jq` 可选；权限为 `network`、`filesystem`、`process`。

#### `ci-workflow`：CI 运行工作台

代码托管内置插件已经能查看 PR、Issue 和基础检查，但缺少运行级信息：失败步骤、日志摘要、构建产物和重试操作。这个插件可以直接连接 GitHub Actions 或 GitLab CI，价值比再做一个 Git 状态插件更高。

第一版命令：

- `tergo-ci-status`：查看当前分支最近运行及失败摘要；
- `tergo-ci-runs <count>`：列出最近运行、触发人和耗时；
- `tergo-ci-log <run>`：只下载失败步骤的日志摘要；
- `tergo-ci-artifacts <run>`：列出构建产物和过期时间；
- `tergo-ci-rerun <run>`：预览并确认后重跑失败任务。

优先支持 `gh`，再通过适配器支持 `glab`；没有 CLI 时显示安装提示。读取命令为 `low`，重跑为 `high`，不在插件中保存 Token，也不打印环境变量。权限为 `network`、`process`，下载日志到临时文件时增加 `filesystem`。

#### `flutter-workflow` 或 `python-workflow`：生态工具链

生态插件应根据实际用户项目选择一个先做，不建议同时发布一个包含所有语言的“万能开发插件”。如果目标用户以 Flutter 项目为主，先做 `flutter-workflow`；如果以后端和数据项目为主，先做 `python-workflow`。

Flutter 第一版可包含：

- `tergo-flutter-doctor`：环境和设备检查；
- `tergo-flutter-analyze`：运行静态分析；
- `tergo-flutter-test`：运行测试并汇总失败用例；
- `tergo-flutter-devices`：列出可用设备；
- `tergo-flutter-pub-outdated`：检查依赖更新；
- `tergo-flutter-build-preview`：只生成构建命令和目标，不直接发布。

Python 第一版可包含 `uv`/`poetry`/`pip` 探测、环境报告、`pytest`、`ruff`、`mypy` 和依赖过期检查。两者都应把包安装和构建放在 `medium` 风险，把发布和设备写入放在 `high` 风险。

### P1：验证 P0 后实现

#### `env-doctor`：环境与项目配置诊断

解决“命令找不到、版本不一致、环境变量来自哪里”的问题。第一版只报告变量名称、来源和工具版本，永远不输出变量值；可支持 `mise`、`direnv`、`.env.example` 和项目版本文件。它与安全插件的区别是关注可复现开发环境，不扫描密钥内容。

#### `cloud-context`：云账号和区域只读视图

不要先做 AWS/GCP/Azure 的万能插件。先做只读的当前账号、区域、配置文件来源和最近资源摘要，再按用户群拆成 `aws-workflow`、`gcp-workflow`、`azure-workflow`。资源删除、部署和权限变更不进入第一版。

#### `k8s-helm-release`：Kubernetes 发布预览

Tergo 已有 Pod、日志和资源删除基础能力，在线插件只补 Helm release、values diff、渲染结果和升级预览。第一版只做 `helm diff`、`helm template` 和当前 release 查询；`upgrade`、`rollback` 放在后续高风险版本。

#### `container-registry`：镜像仓库工作流

在 Docker 内置插件之上增加镜像标签、体积、摘要、最近推送和清理预览，优先支持 GHCR。登录、删除标签和清理镜像必须显式确认，不能读取或打印 Docker 登录凭据。

### P2：有明确用户后再做

- `terraform-workflow`：fmt、validate、plan 和 plan 摘要；apply 只做预览和确认。
- `observability-readonly`：Sentry、Grafana/Loki 等只读事件和日志摘要，避免第一版处理多种云 API Token。
- `docs-content`：Markdown lint、链接检查、目录生成和图片引用检查。
- `data-cli`：DuckDB/SQLite 查看 CSV、JSON、Parquet，适合数据和运营用户。
- `performance-workflow`：Go pprof、Node profiling、Flutter 性能报告等专项诊断。

## 不建议增加的插件

- 把 AWS、GCP、Azure、Kubernetes、Docker 和 Terraform 合成一个“云平台插件”；权限边界太宽，安装前无法让用户判断风险。
- 只提供一个任意 Shell 执行器；它无法体现插件市场的安全和可发现价值。
- 重复实现 Tergo 已有的 Git、任务、端口、SSH、Docker 状态和 Kubernetes 基础查询。
- 需要把长期 Token 写入插件配置的云服务插件；应复用官方 CLI 的已有登录状态。
- 第一版就依赖复杂的远程后台服务或自建数据库；在线插件应先保持本地 Shell 工作流。

## 分阶段计划

### 阶段 0：插件基础设施（1 周）

- 把分类从 `scripts/update_catalog.py` 的 ID 硬编码改成 manifest 中的稳定 `category` 字段；
- 增加 `optionalCommands`、`configSources` 和 `redaction` 约定，区分硬依赖、可选依赖和敏感来源；
- 为网络插件补充离线 smoke test、超时、临时文件清理和输出脱敏夹具；
- 保持 `command` 作为唯一正式扩展面，暂不为尚未支持的 `panel` 或 `statusbar` 设计大量插件。

### 阶段 1：P0 两个插件（已完成）

`api-workbench`、`ci-workflow` 和面向当前项目用户的 `flutter-workflow` 已交付第一版。每个插件都提供只读命令、依赖报告或预览命令，写操作仍由 Tergo 风险确认保护。下一步根据真实安装和反馈决定是否增加 Python 生态插件。

### 阶段 2：生态和环境（2～3 周）

选择一个主要生态插件，加上 `env-doctor`。重点验证命令参数、项目目录识别、缺少依赖时的提示和跨 macOS/Linux 行为。

### 阶段 3：基础设施（4～6 周）

按用户需求选择 `cloud-context`、`k8s-helm-release`、`container-registry` 或 `terraform-workflow` 其中两个，先做只读和变更预览，再开放高风险写操作。

## 每个插件的发布门槛

进入 `stable` 前必须满足：

1. manifest、zsh/bash 语法、参数模板和包摘要验证通过；
2. 没有依赖时终端仍能启动，命令给出可操作的安装提示；
3. 网络超时、非零退出码、空响应和大输出都有明确处理；
4. 读操作不修改工作区，写操作有风险等级、预览和确认；
5. 输出不包含密码、Token、Cookie、私钥、Authorization 和完整连接串；
6. 至少有一个无网络 smoke test 和一个真实 CLI 适配测试；
7. README 说明依赖、权限、数据来源、失败恢复和卸载方式；
8. 连续两个版本没有安装回滚或脚本兼容性问题后再标记 `stable`。

## 最终建议

下一步按 `env-doctor` → `cloud-context`/`k8s-helm-release` → `container-registry`/`terraform-workflow` 的顺序推进。P0 已覆盖 API 调试、CI 运行和 Flutter 生态，后续应先补环境可复现性，再进入云和基础设施的高风险领域。

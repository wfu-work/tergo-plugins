# Tergo 在线插件工程规划

这个目录用于维护可通过 Tergo 插件市场安装的在线插件。插件以独立目录发布，最终打包成 `.tergo-plugin` 或 `.zip`，由市场目录提供版本、依赖、权限和 SHA-256 信息。

新增插件的优先级、边界和分阶段实施方案见 [在线插件路线图](docs/plugin-roadmap.md)。

## 现有能力和边界

Tergo 当前已经提供：

- 远程插件目录、HTTPS 下载、SHA-256 校验、原子安装和版本更新；
- zsh/bash 私有启动文件注入，不修改用户的 `.zshrc` 或 `.bashrc`；
- 声明式 `manifest.json`、命令面板、参数输入、快捷键、风险确认和运行记录；
- Git、Docker/Compose、Git Worktree、SSH、Kubernetes、项目任务、质量检查、运行时诊断、代码托管、远程会话、日志和端口诊断等内置能力；
- 在线插件包括开发者工具箱、数据库工作台、安全扫描、发布工作流、API 调试工作台、CI 运行工作台、Flutter 工作流、环境诊断和 Python 工作流。

当前在线插件真正可用的扩展面是 `command`。`panel`、`file-preview`、`settings` 和 `statusbar` 可以写入元数据，但在 Tergo UI 完成对应扩展点前只能作为规划信息，不能把它们当作已经存在的 UI 能力。

因此，第一阶段的在线插件应满足：

1. 围绕已有 CLI 工具提供高频、可组合的工作流；
2. 没有外部依赖时不影响终端启动，调用时再给出可读提示；
3. 默认提供只读或预览命令，写操作标记为 `medium`、`high` 或 `critical`；
4. 不保存云凭据、不把密钥写入参数或日志、不修改用户 Shell 配置；
5. 同时支持 zsh 和 bash，或在市场详情明确说明平台/ Shell 限制。

## 远程发布方式

官方目录发布在 GitHub Pages：

```text
https://wfu-work.github.io/tergo-plugins/
https://wfu-work.github.io/tergo-plugins/catalog/index.json
```

首页用于人工浏览插件，机器目录仍使用 `catalog/index.json`。插件包发布在同一站点的 `packages/` 路径。`.github/workflows/plugins.yml` 会在 Pull Request 中校验清单和 Shell，在 `main` 或版本标签推送时生成静态目录、部署 Pages，并为版本标签创建 GitHub Release 资产。Tergo 只读取目录和不可变的 `.tergo-plugin` 包，不读取 GitHub 源码文件。

目录中的 `channel` 使用 `stable`、`beta` 或 `nightly`；`verified: true` 表示该包由官方目录发布者审核，属于展示元数据，不替代 Tergo 下载时执行的 SHA-256 完整性校验。包大小和摘要由打包脚本从最终 `.tergo-plugin` 文件重新计算，不能手工填写。

本地可以用以下命令生成发布站点：

```sh
./scripts/build-site.sh
```

如果以后接入自定义域名，只需要在工作流中把 `TERGO_PLUGIN_BASE_URL` 改成新的 `packages/` 地址，并把 Tergo 的插件目录地址配置为对应的 `catalog/index.json`。

## 插件选择标准

每个候选插件按五项评估：

- **覆盖面**：是否有一批明确且持续使用的用户；
- **频率**：是否每天或每周都会重复执行；
- **差异化**：Tergo 是否能把多个 CLI 操作组合成比单条命令更好的入口；
- **风险可控**：能否把读取、预览、执行和破坏性操作分层；
- **实现成本**：是否可以只用 Shell 脚本和声明式命令完成，不需要改 Tergo 核心。

## 推荐路线图

| 优先级 | 插件 ID | 面向用户 | 核心价值 | 主要依赖 | 风险 |
| --- | --- | --- | --- | --- | --- |
| P0 | `developer-toolbox` | 所有开发者 | 把 `rg`、`fd`、`fzf`、`bat`、`eza`、`delta` 组织成项目搜索、文件预览、Git diff 阅读和目录跳转工作流 | `rg`、`fd`、`fzf`，其余可选 | 低 |
| P0 | `database-workbench` | 后端、数据、运维 | 统一连接 PostgreSQL、MySQL、SQLite、Redis，提供连接测试、库表查看、查询模板和安全导出 | `psql`、`mysql`、`sqlite3`、`redis-cli` | 中 |
| P0 | `security-scanner` | 开发、平台、安全 | 一键运行密钥、依赖和代码扫描，生成可复制的本地报告 | `gitleaks`、`osv-scanner`、`semgrep` | 中 |
| P0 | `release-workflow` | 团队开发者 | 从当前 Git 状态生成变更摘要、校验 Conventional Commits、预览 changelog 和版本发布步骤 | `git`，可选 `pnpm`/`npm`/`changeset` | 中 |
| P0 | `api-workbench` | 前后端、测试、运维 | 发现请求模板、检查 HTTP 地址、执行只读请求和提取 JSON | `curl`，可选 `jq` | 低到中 |
| P0 | `ci-workflow` | 团队开发者、平台工程 | 查看 CI 运行、失败日志和构建产物，确认后重跑失败任务 | `gh` 或 `glab` | 中到高 |
| P0 | `flutter-workflow` | Flutter 开发者 | 环境检查、设备查看、分析、测试、依赖检查和构建预览 | `flutter`、`dart` | 中 |
| P1 | `env-doctor` | 全栈、平台工程 | 诊断工具版本、项目版本文件、环境变量来源和 `.env` 差异，只显示名称不显示值 | `mise`、`direnv`，其余可选 | 低 |
| P1 | `python-workflow` | Python 开发者、数据工程 | 探测 Python 环境，运行 pytest、ruff、mypy 和依赖过期检查 | `python3` 或 `python`，其余可选 | 中 |
| P1 | `cloud-cli-workflow` | 云开发、平台工程 | 统一查看当前账号、区域、资源和最近部署状态，减少记忆 AWS/GCP/Azure CLI 参数 | `aws`、`gcloud`、`az`，按云厂商拆分 | 中到高 |
| P1 | `terraform-workflow` | IaC、DevOps | 提供 `fmt`、`validate`、`plan`、变更摘要和状态检查，强化 plan 优先 | `terraform` | 高 |
| P1 | `env-secrets-workflow` | 全栈、平台工程 | 检查当前环境变量来源、切换本地环境、执行脱敏后的环境报告 | `direnv`、`mise`、`doppler` 或 `1password` CLI | 中到高 |
| P1 | `observability-tools` | SRE、后端 | 查看 Sentry、Grafana/Loki、云日志和告警摘要，优先链接到详情而不是把凭据带入 Shell | 对应官方 CLI 或 API 工具 | 中 |
| P2 | `container-registry` | 发布、平台工程 | 登录状态、镜像标签、镜像体积和清理预览，覆盖 GHCR、ECR、Docker Hub 等 | `docker`、对应云 CLI | 中到高 |
| P2 | `k8s-helm-release` | Kubernetes 用户 | 在已有 Kubernetes 插件之上提供 Helm release、values diff、升级预览和回滚提示 | `helm`、`kubectl` | 高 |
| P2 | `data-cli` | 数据分析、后端 | 用 DuckDB/SQLite 快速查看 CSV、JSON、Parquet 和本地数据库 | `duckdb` 或 `sqlite3` | 低到中 |
| P2 | `docs-content` | 开发者、技术写作者 | Markdown lint、链接检查、目录生成、图片/文档预览和发布前检查 | `markdownlint`、`lychee` 或项目已有脚本 | 低 |

## 重点四个插件的具体定义

### 1. `developer-toolbox`

这是最适合先发布的通用插件。它不和现有 `git-workflow` 重叠，而是解决“找到内容、读懂差异、快速切目录”的连续操作。

建议命令：

- `tergo-search <query>`：在项目根目录用 `rg` 搜索；
- `tergo-files <query>`：用 `fd` 查找文件；
- `tergo-preview <file>`：用 `bat` 或 `sed` 预览文件；
- `tergo-fuzzy-file`：用 `fzf` 选择文件并输出路径；
- `tergo-diff-view`：优先用 `delta`，否则回退到 `git diff --color=always`；
- `tergo-size-report`：按目录统计项目体积。

默认快捷键只绑定不冲突的命令；所有路径作为单个参数传递。缺少可选工具时继续使用系统命令回退，不把插件判为不可用。

### 2. `database-workbench`

这是差异化和付费价值都较高的方向。不要尝试在 Shell 插件里实现完整数据库客户端，而是把最常用的安全动作做成统一入口：

- 列出当前项目识别到的连接类型和客户端版本；
- 测试连接并显示脱敏后的目标；
- 查看数据库、表、索引和最近结构；
- 执行用户明确输入的只读查询；
- 导出查询结果到当前项目的临时文件；
- 生成 `EXPLAIN`/`EXPLAIN ANALYZE` 预览。

连接信息只从用户已有环境变量、`.pg_service.conf`、`~/.my.cnf` 或 CLI 自身配置读取。命令面板不接受密码参数，日志中不输出连接串中的密码。

### 3. `security-scanner`

这个插件能把 Tergo 的“项目终端”定位延伸到提交前检查，且默认可以保持只读：

- `tergo-secret-scan`：扫描当前 Git 工作区和暂存区；
- `tergo-dependency-scan`：扫描依赖漏洞；
- `tergo-code-scan`：运行项目已有的 Semgrep/规则集；
- `tergo-security-report`：汇总工具版本、扫描范围和结果文件；
- `tergo-security-baseline`：仅生成基线预览，不自动修改忽略文件。

扫描结果应默认写到临时目录或用户选择的路径，提供退出码和摘要，不上传代码。涉及网络数据库的扫描需要在 manifest 中显式声明 `network` 权限。

### 4. `release-workflow`

这个插件能连接 Tergo 已有 Git、项目任务和代码托管能力，形成更完整的交付闭环：

- 检查工作区是否干净、当前分支和上游状态；
- 校验最近提交是否符合 Conventional Commits；
- 生成从上一个 tag 到 HEAD 的变更摘要；
- 预览下一版本号和 changelog；
- 检查 npm/Go/Rust 项目的版本字段是否一致；
- 仅在用户确认后执行 tag、changelog 或发布命令。

所有发布写操作都必须标记为 `high`，并提供对应的 `--dry-run` 或预览命令。插件不应自行推送，也不应绕过 Tergo 的确认流程。

## 第二阶段的拆分原则

云厂商、数据库和可观测性不要一开始做成一个“万能插件”。建议按外部 CLI 和权限边界拆分：

- `aws-workflow`、`gcp-workflow`、`azure-workflow` 各自独立，便于按用户群安装；
- `postgres-workflow`、`mysql-workflow`、`redis-workflow` 先独立，后续再由 `database-workbench` 作为元插件组合；
- `sentry-workflow`、`grafana-workflow` 先做只读查询，写入告警和事件操作另发高风险版本；
- `terraform-workflow` 和 `k8s-helm-release` 分离，避免一个插件同时拥有云资源和集群变更权限。

## 推荐目录结构

```text
tergo-plugins/
├── README.md
├── CONTRIBUTING.md
├── catalog/
│   └── index.json                 # 发布到插件注册表的元数据
├── plugins/
│   ├── developer-toolbox/
│   │   ├── manifest.json
│   │   ├── init.zsh
│   │   ├── init.bash
│   │   ├── README.md
│   │   └── LICENSE
│   ├── database-workbench/
│   ├── security-scanner/
│   ├── release-workflow/
│   ├── api-workbench/
│   ├── ci-workflow/
│   ├── flutter-workflow/
│   ├── env-doctor/
│   └── python-workflow/
├── scripts/
│   ├── package-plugin.sh           # 生成 .tergo-plugin 并计算 SHA-256
│   ├── validate-plugin.sh          # 本地清单、Shell、依赖校验
│   └── update-catalog.sh           # 更新 index.json 的包 URL、摘要和版本
└── testdata/
    ├── projects/
    └── fake-bin/
```

每个插件只把清单声明的入口脚本打进包里。共享逻辑优先复制少量、经过测试的 Shell helper，避免插件之间形成难以更新的运行时耦合；需要真正共享时，应先进入 Tergo 核心或单独发布一个依赖插件。

## Manifest 约定

所有插件至少声明：

```json
{
  "manifestVersion": 1,
  "id": "developer-toolbox",
  "name": "开发者工具箱",
  "version": "0.1.0",
  "description": "项目搜索、文件预览和差异阅读工作流。",
  "category": "productivity",
  "shells": ["zsh", "bash"],
  "entry": {"zsh": "init.zsh", "bash": "init.bash"},
  "capabilities": ["search", "files", "git"],
  "optionalCommands": ["fd", "fzf", "bat"],
  "configSources": ["project-root"],
  "redaction": {"mode": "none", "fields": []},
  "requiredCommands": ["rg"],
  "platforms": ["darwin", "linux"],
  "permissions": ["process", "filesystem"],
  "surfaces": ["command"],
  "commands": []
}
```

约定如下：

- `requiredCommands` 只填写插件无法工作的硬依赖；可选工具在脚本中检测并回退；
- `healthcheck` 只做快速、无副作用的版本或连接检查；
- `mode` 使用 `execute` 或 `insert`，读操作优先 `execute`；
- `risk` 使用 `low`、`medium`、`high`、`critical`，破坏性动作必须有确认；
- 参数使用 `{{arg:name}}`，不要把用户输入拼接为第二条命令；
- `permissions` 只声明真实需要的 `network`、`filesystem`、`process`；
- 版本先遵循 SemVer，Tergo 兼容性通过 `minTergoVersion` 约束；
- 包发布前必须固定 SHA-256，更新不能覆盖同 ID 的较低版本。

## 发布和质量门禁

每个插件在进入市场前都应通过：

1. manifest 规范校验、入口文件存在性和大小限制；
2. zsh、bash 语法检查，以及没有对应依赖时的启动测试；
3. 参数缺失、空格、引号、换行、选项前缀和超长输入测试；
4. 读操作不会修改工作区，写操作都有风险等级和确认；
5. 输出不包含密码、Token、Cookie、私钥和完整连接串；
6. 在 macOS 和 Linux 至少各验证一次，平台不支持时在 manifest 中声明；
7. `.tergo-plugin` 安装、升级、回滚和卸载测试；
8. `catalog/index.json` 的包 URL、版本、许可证、更新说明和 SHA-256 与实际包一致。

## 90 天实施顺序

### 第 1～2 周：工程基线

- 建立插件目录、打包脚本、manifest 校验和 shell 测试夹具；
- 发布 `developer-toolbox`，验证从目录浏览到安装、启用、更新的完整链路；
- 约定命名、版本、许可证、截图/README 和风险描述格式。

### 第 3～5 周：高频工作流（已完成）

- 发布 `database-workbench` 和 `security-scanner`；
- 加入脱敏输出、临时文件清理和依赖缺失回退；
- 收集安装成功率、命令执行次数、失败原因和卸载率。

### 第 6～8 周：交付闭环

- 发布 `release-workflow`；
- 增加 changelog、版本一致性和 dry-run 流程；
- 与现有 Git、项目任务、代码托管内置插件联调。

### 第 9～12 周：垂直扩展

- 根据真实使用数据选择 `terraform-workflow`、`api-workbench` 或某个云厂商插件；
- 再考虑 `panel`、`file-preview`、`statusbar` 扩展点，避免先为尚未支持的 UI 设计大量插件；
- 对高风险插件增加签名、来源标记和更细的权限说明。

## 建议的第一批发布顺序

第一批已落地 `developer-toolbox`、`database-workbench`、`security-scanner`、`release-workflow`、`api-workbench`、`ci-workflow` 和 `flutter-workflow`；阶段 2 已补充 `env-doctor` 与 `python-workflow`。它们依赖常见 CLI、只需命令面板即可提供价值，并且验证了在线插件的安装、诊断、风险确认、日志脱敏和升级回滚链路。下一阶段应根据安装和使用反馈选择云厂商、Kubernetes、容器仓库或 Terraform 工作流。


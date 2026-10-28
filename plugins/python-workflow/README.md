# Python 工作流

`python-workflow` 复用当前项目的 Python 解释器和虚拟环境，提供环境报告、pytest、ruff、mypy 和依赖过期检查。命令不会自动创建虚拟环境、安装依赖或修改项目文件。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-python-report` | 查看 Python、pip、uv、poetry 和检查工具状态 | 低 |
| `tergo-python-env` | 查看解释器路径、版本和环境前缀 | 低 |
| `tergo-python-test` | 运行 pytest | 中 |
| `tergo-python-lint` | 运行 ruff check | 中 |
| `tergo-python-typecheck` | 运行 mypy | 中 |
| `tergo-python-outdated` | 查看可更新依赖 | 中 |
| `tergo-python-install-preview [target]` | 预览工具安装命令 | 低 |

插件优先使用项目当前 PATH 和虚拟环境，不保存凭据。依赖过期检查可能访问包索引，使用前应确认当前网络和 pip/uv 的登录配置；插件不会打印包索引中的凭据。

# 项目安全扫描

`security-scanner` 把常见的提交前安全检查接入 Tergo 命令面板。扫描器没有安装时，插件仍然可以加载，并会在调用命令时给出安装提示。

## 命令

| 命令 | 作用 | 依赖 |
| --- | --- | --- |
| `tergo-secret-scan` | 扫描疑似密钥，结果脱敏 | `gitleaks` |
| `tergo-dependency-scan` | 扫描依赖漏洞 | `osv-scanner` |
| `tergo-code-scan` | 执行 Semgrep 规则扫描 | `semgrep` |
| `tergo-security-report` | 输出扫描范围和工具版本 | `git` |
| `tergo-security-baseline` | 预览临时脱敏基线报告 | `gitleaks` |

扫描结果不会上传到 Tergo。Semgrep 使用 `auto` 规则时可能根据自身配置下载规则，网络权限因此在清单中显式声明。插件不会读取或打印环境变量，也不会自动修改 `.gitignore`、配置文件或源码。

# 环境诊断

`env-doctor` 用来回答“当前项目使用了哪些工具和配置来源、缺少哪些环境变量”这类问题。它只读取文件存在性、工具版本和变量名称，永远不输出 `.env`、Shell 环境或配置文件中的变量值。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-env-report` | 查看工具版本和虚拟环境状态 | 低 |
| `tergo-env-tools` | 查看 mise、direnv、Python 等工具状态 | 低 |
| `tergo-env-sources` | 检查版本文件、dotenv 和项目配置来源 | 低 |
| `tergo-env-vars` | 查看变量名称及 `.env.example` 设置状态 | 低 |
| `tergo-env-check` | 检查 `.env.example` 中声明的变量是否已设置 | 低 |

插件不会加载 `.envrc`，不会执行项目配置文件，不会安装工具，也不会修改工作区。`tergo-env-check` 找不到配置文件时返回成功并提示跳过；发现缺少变量时返回非零状态，方便在任务中使用。

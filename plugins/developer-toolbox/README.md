# 开发者工具箱

`developer-toolbox` 为 Tergo 提供项目搜索、文件查找、文件预览、模糊选择、Git 差异阅读和目录体积分析。

插件优先使用 `rg`、`fd`、`fzf`、`bat` 和 `delta`。这些工具都是可选依赖：缺少时会回退到系统自带的 `grep`、`find`、`sed` 和 Git 输出，不会阻止终端启动。

## 命令

| 命令 | 作用 |
| --- | --- |
| `tergo-search` | 在项目根目录搜索文本 |
| `tergo-files` | 按文件名查找文件 |
| `tergo-preview` | 预览文件前 240 行 |
| `tergo-fuzzy-file` | 使用 fzf 选择文件 |
| `tergo-diff-view` | 阅读当前 Git 差异 |
| `tergo-size-report` | 查看一级目录体积 |
| `tergo-tool-report` | 查看可选工具安装状态 |

插件只读取项目文件，不修改工作区。

# 镜像仓库工作流

`container-registry` 补充 Tergo 已有的 Docker 能力，聚焦镜像仓库的摘要、标签、体积和安全预览。第一版支持 Docker 本地镜像和 `crane` 远程仓库查询，并提供 Trivy 扫描、清理预览；不会执行 login、push、delete 或清理远程标签。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-registry-report` | 查看 Docker、crane、Trivy 和 gh 状态 | 低 |
| `tergo-registry-local-images` | 查看本地镜像、ID 和体积 | 低 |
| `tergo-registry-digest <image>` | 查看远程镜像 digest 或 manifest | 中 |
| `tergo-registry-tags <repository>` | 使用 crane 查看远程标签 | 中 |
| `tergo-registry-scan-preview <image>` | 预览 Trivy 扫描命令 | 低 |
| `tergo-registry-cleanup-preview <image@digest>` | 预览按 digest 清理命令 | 低 |

`crane` 是远程摘要和标签查询的推荐依赖，缺少时摘要命令回退到 `docker manifest inspect`；`docker`、`crane`、`trivy` 和 `gh` 都是可选依赖，缺少时插件仍能加载并给出安装提示。插件不会读取或输出 Docker 配置、Registry Token、GH_TOKEN 或镜像配置中的 Secret。

# Helm 发布预览

`k8s-helm-release` 补充 Tergo 已有 Kubernetes 基础能力，聚焦 Helm Chart 和 Release 的只读检查。第一版支持 Release 查询、Chart lint、模板渲染、默认 values、helm-diff 和升级预览，不执行 `helm upgrade`、`rollback`、删除或集群写入。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-helm-report` | 查看 Helm、kubectl、Chart 和上下文状态 | 低 |
| `tergo-helm-releases [namespace]` | 查看 Release | 中 |
| `tergo-helm-chart-lint [chart]` | 校验 Chart | 低 |
| `tergo-helm-template [chart]` | 渲染模板 | 中 |
| `tergo-helm-values [chart]` | 查看默认 values | 低 |
| `tergo-helm-diff <release> [chart]` | 预览 Release 差异 | 中 |
| `tergo-helm-upgrade-preview <release> [chart]` | 预览升级命令 | 低 |

Chart 路径必须位于当前项目内。Release 查询和 helm-diff 会访问当前 kubeconfig 指向的集群；插件不会读取或打印 kubeconfig 内容。模板和差异输出可能包含 Secret 或其他敏感值，请勿直接发布到公共日志。

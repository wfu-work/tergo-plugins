# API 调试工作台

`api-workbench` 复用项目中已有的 HTTP 请求模板和 OpenAPI 文件，提供安全的 API 探测、请求发现和 JSON 提取。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-api-report` | 查看 curl、jq 和请求文件状态 | 低 |
| `tergo-api-list` | 发现 `.http`、`.rest`、OpenAPI 和 Swagger 文件 | 低 |
| `tergo-api-inspect <url>` | 检查状态、响应头、耗时和最终地址 | 低 |
| `tergo-api-run <request>` | 执行模板中的 GET、HEAD 或 OPTIONS 请求 | 低 |
| `tergo-api-json <url> [filter]` | 用 jq 提取 JSON 响应字段 | 低 |

请求模板的第一行使用 `GET https://example.test/health` 格式。后续普通请求头可以被转发；Authorization、Cookie 和其他敏感认证头会被跳过，避免出现在 curl 进程参数和输出中。第一版拒绝 POST、PUT、PATCH、DELETE，不执行请求体。

插件只使用项目内的请求文件，URL 必须是 HTTP/HTTPS，禁止把用户名或密码放入 URL。`curl` 是硬依赖，`jq` 是 JSON 提取命令的可选依赖。插件不会安装工具、保存凭据或修改项目文件。

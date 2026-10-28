# 数据库工作台

`database-workbench` 把常见数据库客户端接入 Tergo 命令面板，复用用户已经配置好的环境，不在参数或输出中要求密码。

支持 PostgreSQL (`psql`)、MySQL (`mysql`)、SQLite (`sqlite3`) 和 Redis (`redis-cli`)。客户端都是可选依赖；缺少客户端时，命令会给出安装提示，不会影响终端启动。

## 配置来源

- PostgreSQL：`DATABASE_URL`、`PGHOST`、`PGPORT`、`PGUSER`、`PGDATABASE`、`PGSERVICE`、`~/.pg_service.conf` 和客户端默认配置；
- MySQL：`MYSQL_HOST`、`MYSQL_TCP_PORT`、`MYSQL_USER`、`MYSQL_DATABASE`、`~/.my.cnf` 和客户端默认配置；
- SQLite：`TERGO_DB_SQLITE`、`SQLITE_DATABASE` 或 `DATABASE_FILE`；
- Redis：`REDIS_URL`、`REDIS_HOST`、`REDIS_PORT` 和 `REDISCLI_AUTH`。

`tergo-db-config` 只报告哪些来源已设置，不显示值。密码、连接串和 Token 不应作为命令面板参数传入。

## 命令

| 命令 | 作用 | 风险 |
| --- | --- | --- |
| `tergo-db-report` | 查看客户端安装状态 | 低 |
| `tergo-db-config` | 查看脱敏后的配置来源 | 低 |
| `tergo-db-test <backend>` | 执行 `SELECT 1` 或 `PING` | 低 |
| `tergo-db-tables <backend>` | 查看表或 Redis 部分键名 | 低 |
| `tergo-db-query <backend> <query>` | 执行受限只读查询 | 低 |
| `tergo-db-explain <backend> <query>` | 预览查询计划 | 低 |
| `tergo-db-export <backend> <query>` | 导出只读结果到 0600 临时文件 | 中 |

`backend` 可以是 `auto`、`postgres`、`mysql`、`sqlite` 或 `redis`。`auto` 只会根据显式环境配置选择数据库，不会在没有目标配置时擅自连接本机服务。

SQL 查询拒绝多语句和常见写操作关键字，只允许 `SELECT`、`WITH`、`SHOW` 或 `DESCRIBE` 开头；Redis 只允许读取类命令。数据库客户端仍然按用户现有权限运行，插件不提供 Shell 沙箱。

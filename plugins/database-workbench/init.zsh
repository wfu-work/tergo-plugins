# Tergo database-workbench: safe database inspection helpers.

tergo_db_install_hint() {
  case "$1" in
    psql) printf '%s\n' '未找到 psql，请安装 PostgreSQL 客户端。' >&2 ;;
    mysql) printf '%s\n' '未找到 mysql，请安装 MySQL 客户端。' >&2 ;;
    sqlite3) printf '%s\n' '未找到 sqlite3，请安装 SQLite 客户端。' >&2 ;;
    redis-cli) printf '%s\n' '未找到 redis-cli，请安装 Redis 客户端。' >&2 ;;
    *) printf '未找到数据库客户端：%s\n' "$1" >&2 ;;
  esac
  return 127
}

tergo_db_require() {
  command -v "$1" >/dev/null 2>&1 && return 0
  tergo_db_install_hint "$1"
}

tergo_db_backend_from_env() {
  local requested="${1:-auto}" url
  requested=$(printf '%s' "$requested" | tr '[:upper:]' '[:lower:]')
  case "$requested" in
    postgres|postgresql|psql) printf '%s\n' postgres ;;
    mysql|mariadb) printf '%s\n' mysql ;;
    sqlite|sqlite3) printf '%s\n' sqlite ;;
    redis|redis-cli) printf '%s\n' redis ;;
    auto)
      if [ -n "${TERGO_DB_BACKEND:-}" ] && [ "$TERGO_DB_BACKEND" != auto ]; then
        tergo_db_backend_from_env "$TERGO_DB_BACKEND"
        return
      fi
      url="${DATABASE_URL:-}"
      case "$url" in
        postgres://*|postgresql://*) printf '%s\n' postgres; return ;;
        mysql://*|mariadb://*) printf '%s\n' mysql; return ;;
        redis://*|rediss://*) printf '%s\n' redis; return ;;
      esac
      if [ -n "${TERGO_DB_SQLITE:-${SQLITE_DATABASE:-${DATABASE_FILE:-}}}" ]; then
        printf '%s\n' sqlite
      elif [ -n "${REDIS_URL:-${REDIS_HOST:-}}" ]; then
        printf '%s\n' redis
      else
        printf '%s\n' ''
      fi
      ;;
    *) printf '不支持的数据库类型：%s（可用 postgres、mysql、sqlite、redis）\n' "$requested" >&2; return 2 ;;
  esac
}

tergo_db_backend_or_error() {
  local backend
  backend=$(tergo_db_backend_from_env "${1:-auto}") || return
  if [ -z "$backend" ]; then
    printf '%s\n' '无法从当前配置判断数据库类型，请显式传入 postgres、mysql、sqlite 或 redis。' >&2
    return 2
  fi
  printf '%s\n' "$backend"
}

tergo_db_config_value() {
  [ -n "${2:-}" ] && printf '%s：已设置（值不显示）\n' "$1"
}

tergo_db_report() {
  printf '%s\n' 'Tergo 数据库工作台'
  local client version
  for client in psql mysql sqlite3 redis-cli; do
    if command -v "$client" >/dev/null 2>&1; then
      version=$("$client" --version 2>/dev/null | sed -n '1p')
      printf '%s：已安装%s\n' "$client" "${version:+ · $version}"
    else
      printf '%s：未安装（按需安装即可）\n' "$client"
    fi
  done
  printf '%s\n' '配置：运行 tergo-db-config 查看已设置的来源；不会显示密码或连接串。'
}

tergo_db_config() {
  printf '%s\n' '数据库配置来源（仅显示是否设置）'
  tergo_db_config_value TERGO_DB_BACKEND "${TERGO_DB_BACKEND:-}"
  tergo_db_config_value DATABASE_URL "${DATABASE_URL:-}"
  tergo_db_config_value PGHOST "${PGHOST:-}"
  tergo_db_config_value PGPORT "${PGPORT:-}"
  tergo_db_config_value PGUSER "${PGUSER:-}"
  tergo_db_config_value PGDATABASE "${PGDATABASE:-}"
  tergo_db_config_value PGSERVICE "${PGSERVICE:-}"
  tergo_db_config_value PGPASSWORD "${PGPASSWORD:-}"
  tergo_db_config_value MYSQL_HOST "${MYSQL_HOST:-}"
  tergo_db_config_value MYSQL_TCP_PORT "${MYSQL_TCP_PORT:-}"
  tergo_db_config_value MYSQL_USER "${MYSQL_USER:-}"
  tergo_db_config_value MYSQL_DATABASE "${MYSQL_DATABASE:-}"
  tergo_db_config_value MYSQL_PWD "${MYSQL_PWD:-}"
  tergo_db_config_value TERGO_DB_SQLITE "${TERGO_DB_SQLITE:-}"
  tergo_db_config_value SQLITE_DATABASE "${SQLITE_DATABASE:-}"
  tergo_db_config_value DATABASE_FILE "${DATABASE_FILE:-}"
  tergo_db_config_value REDIS_URL "${REDIS_URL:-}"
  tergo_db_config_value REDIS_HOST "${REDIS_HOST:-}"
  tergo_db_config_value REDIS_PORT "${REDIS_PORT:-}"
  tergo_db_config_value REDISCLI_AUTH "${REDISCLI_AUTH:-}"
  [ -f "${HOME:-}/.pg_service.conf" ] && printf '%s\n' '~/.pg_service.conf：存在'
  [ -f "${HOME:-}/.my.cnf" ] && printf '%s\n' '~/.my.cnf：存在'
}

tergo_db_validate_sql() {
  local query="$1" first normalized
  [ -n "${query//[[:space:]]/}" ] || { printf '%s\n' '查询不能为空。' >&2; return 2; }
  case "$query" in
    *';'*) printf '%s\n' '为避免多语句执行，只读查询不能包含分号。' >&2; return 2 ;;
  esac
  first=$(printf '%s\n' "$query" | awk '{print toupper($1); exit}')
  case "$first" in
    SELECT|WITH|SHOW|DESCRIBE|DESC) ;;
    *) printf '%s\n' '只允许 SELECT、WITH、SHOW 或 DESCRIBE 查询。' >&2; return 2 ;;
  esac
  normalized=$(printf '%s' "$query" | tr '[:lower:]' '[:upper:]')
  case "$normalized" in
    *INSERT*|*UPDATE*|*DELETE*|*DROP*|*ALTER*|*CREATE*|*REPLACE*|*TRUNCATE*|*ATTACH*|*DETACH*|*VACUUM*)
      printf '%s\n' '查询包含可能改变数据或结构的关键字，已拒绝。' >&2
      return 2
      ;;
  esac
}

tergo_db_validate_redis() {
  local query="$1" first
  [ -n "${query//[[:space:]]/}" ] || { printf '%s\n' 'Redis 命令不能为空。' >&2; return 2; }
  case "$query" in *';'*) printf '%s\n' 'Redis 命令不能包含分号。' >&2; return 2;; esac
  first=$(printf '%s\n' "$query" | awk '{print toupper($1); exit}')
  case "$first" in
    GET|MGET|HGET|HMGET|HGETALL|HEXISTS|LLEN|LRANGE|LINDEX|SMEMBERS|SISMEMBER|SCARD|ZCARD|ZRANGE|ZREVRANGE|SCAN|EXISTS|TYPE|TTL|PTTL|DBSIZE|INFO|PING|ECHO|TIME|ROLE) ;;
    *) printf '%s\n' 'Redis 只允许读取类命令，例如 GET、HGET、SCAN、INFO 或 PING。' >&2; return 2 ;;
  esac
}

tergo_db_run_redis() {
  local query="$1"
  local -a words
  tergo_db_require redis-cli || return
  tergo_db_validate_redis "$query" || return
  read -rA words <<< "$query"
  if [ -n "${REDIS_URL:-}" ]; then
    case "$REDIS_URL" in *'@'*) printf '%s\n' 'REDIS_URL 含有凭据，已拒绝作为进程参数；请改用 REDIS_HOST、REDIS_PORT 和 REDISCLI_AUTH。' >&2; return 2;; esac
    redis-cli --no-auth-warning --raw -u "$REDIS_URL" "${words[@]}"
  else
    local -a options
    options=()
    [ -n "${REDIS_HOST:-}" ] && options+=( -h "$REDIS_HOST" )
    [ -n "${REDIS_PORT:-}" ] && options+=( -p "$REDIS_PORT" )
    redis-cli --no-auth-warning --raw "${options[@]}" "${words[@]}"
  fi
}

tergo_db_run_query() {
  local backend="$1" query="$2" db
  case "$backend" in
    postgres)
      tergo_db_require psql || return
      if [ -n "${DATABASE_URL:-}" ]; then
        case "$DATABASE_URL" in *'@'*) printf '%s\n' 'DATABASE_URL 含有凭据，已拒绝作为进程参数；请改用 PGHOST、PGPORT、PGUSER、PGDATABASE 和 PGPASSWORD。' >&2; return 2;; esac
        psql -X --set=ON_ERROR_STOP=1 --dbname="$DATABASE_URL" -c "$query"
      else
        psql -X --set=ON_ERROR_STOP=1 -c "$query"
      fi
      ;;
    mysql)
      tergo_db_require mysql || return
      mysql --batch --raw --execute="$query"
      ;;
    sqlite)
      tergo_db_require sqlite3 || return
      db="${TERGO_DB_SQLITE:-${SQLITE_DATABASE:-${DATABASE_FILE:-}}}"
      [ -n "$db" ] || { printf '%s\n' 'SQLite 需要 TERGO_DB_SQLITE、SQLITE_DATABASE 或 DATABASE_FILE。' >&2; return 2; }
      [ -f "$db" ] || { printf 'SQLite 文件不存在：%s\n' "$db" >&2; return 2; }
      sqlite3 -header -column "$db" "$query"
      ;;
    redis) tergo_db_run_redis "$query" ;;
    *) printf '未知数据库类型：%s\n' "$backend" >&2; return 2 ;;
  esac
}

tergo_db_run_export() {
  local backend="$1" query="$2" db
  case "$backend" in
    postgres)
      tergo_db_require psql || return
      if [ -n "${DATABASE_URL:-}" ]; then
        case "$DATABASE_URL" in *'@'*) printf '%s\n' 'DATABASE_URL 含有凭据，已拒绝作为进程参数；请改用 PGHOST、PGPORT、PGUSER、PGDATABASE 和 PGPASSWORD。' >&2; return 2;; esac
        psql -X --set=ON_ERROR_STOP=1 --pset=tuples_only=on --pset=fieldsep=$'\t' --dbname="$DATABASE_URL" -c "$query"
      else
        psql -X --set=ON_ERROR_STOP=1 --pset=tuples_only=on --pset=fieldsep=$'\t' -c "$query"
      fi
      ;;
    mysql) tergo_db_require mysql || return; mysql --batch --raw --execute="$query" ;;
    sqlite)
      tergo_db_require sqlite3 || return
      db="${TERGO_DB_SQLITE:-${SQLITE_DATABASE:-${DATABASE_FILE:-}}}"
      [ -n "$db" ] || { printf '%s\n' 'SQLite 需要 TERGO_DB_SQLITE、SQLITE_DATABASE 或 DATABASE_FILE。' >&2; return 2; }
      [ -f "$db" ] || { printf 'SQLite 文件不存在：%s\n' "$db" >&2; return 2; }
      sqlite3 -header -tabs "$db" "$query"
      ;;
    redis) tergo_db_run_redis "$query" ;;
    *) printf '未知数据库类型：%s\n' "$backend" >&2; return 2 ;;
  esac
}

tergo_db_test() {
  local backend
  backend=$(tergo_db_backend_or_error "${1:-auto}") || return
  if [ "$backend" = redis ]; then
    tergo_db_run_redis 'PING'
  else
    tergo_db_run_query "$backend" 'SELECT 1'
  fi
}

tergo_db_tables() {
  local backend query
  backend=$(tergo_db_backend_or_error "${1:-auto}") || return
  case "$backend" in
    postgres) query="SELECT schemaname || '.' || tablename AS table_name FROM pg_catalog.pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY 1" ;;
    mysql) query="SHOW TABLES" ;;
    sqlite) query="SELECT name AS table_name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name" ;;
    redis) query='SCAN 0 COUNT 100' ;;
  esac
  if [ "$backend" = redis ]; then
    tergo_db_run_redis "$query"
  else
    tergo_db_run_query "$backend" "$query"
  fi
}

tergo_db_query() {
  local backend="$1" query="$2"
  backend=$(tergo_db_backend_or_error "$backend") || return
  if [ "$backend" = redis ]; then
    tergo_db_run_redis "$query"
  else
    tergo_db_validate_sql "$query" || return
    tergo_db_run_query "$backend" "$query"
  fi
}

tergo_db_explain() {
  local backend="$1" query="$2" explain_query
  backend=$(tergo_db_backend_or_error "$backend") || return
  [ "$backend" != redis ] || { printf '%s\n' 'Redis 没有通用的 EXPLAIN 查询计划。' >&2; return 2; }
  tergo_db_validate_sql "$query" || return
  case "$backend" in
    postgres) explain_query="EXPLAIN (FORMAT TEXT) $query" ;;
    mysql) explain_query="EXPLAIN $query" ;;
    sqlite) explain_query="EXPLAIN QUERY PLAN $query" ;;
  esac
  tergo_db_run_query "$backend" "$explain_query"
}

tergo_db_export() {
  local backend="$1" query="$2" file
  backend=$(tergo_db_backend_or_error "$backend") || return
  if [ "$backend" = redis ]; then
    tergo_db_validate_redis "$query" || return
  else
    tergo_db_validate_sql "$query" || return
  fi
  file=$(umask 077; mktemp "${TMPDIR:-/tmp}/tergo-db-export.XXXXXX") || { printf '%s\n' '无法创建临时导出文件。' >&2; return 1; }
  if ! tergo_db_run_export "$backend" "$query" > "$file"; then
    rm -f "$file"
    return 1
  fi
  printf '已导出只读结果：%s\n' "$file"
}

tergo-db-report() { tergo_db_report "$@"; }
tergo-db-config() { tergo_db_config "$@"; }
tergo-db-test() { tergo_db_test "$@"; }
tergo-db-tables() { tergo_db_tables "$@"; }
tergo-db-query() { tergo_db_query "$@"; }
tergo-db-explain() { tergo_db_explain "$@"; }
tergo-db-export() { tergo_db_export "$@"; }

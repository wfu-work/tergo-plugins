# Tergo online plugin: API workbench.

_tergo_api_root() {
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    printf '%s\n' "$TERGO_PROJECT_ROOT"
    return 0
  fi
  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) && {
    printf '%s\n' "$root"
    return 0
  }
  pwd
}

_tergo_api_require_url() {
  local url=${1:-}
  case "$url" in
    http://*|https://*) ;;
    *) printf '%s\n' 'API 地址必须以 http:// 或 https:// 开头。' >&2; return 2 ;;
  esac
  case "$url" in
    http://*:*@*|https://*:*@*) printf '%s\n' '为避免凭据进入进程参数，不接受带用户名或密码的 URL。' >&2; return 2 ;;
  esac
  if printf '%s' "$url" | LC_ALL=C command grep -q '[[:cntrl:]]'; then
    printf '%s\n' 'API 地址不能包含控制字符。' >&2
    return 2
  fi
  printf '%s\n' "$url"
}

_tergo_api_request_file() {
  local root path=${1:-}
  root=$(_tergo_api_root)
  [ -n "$path" ] || { printf '%s\n' '请求文件不能为空。' >&2; return 2; }
  case "$path" in
    /*) ;;
    *) path="$root/$path" ;;
  esac
  [ -f "$path" ] || { printf '请求文件不存在：%s\n' "$1" >&2; return 1; }
  case "$path" in
    "$root"/*) printf '%s\n' "$path" ;;
    *) printf '%s\n' '请求文件必须位于当前项目内。' >&2; return 2 ;;
  esac
}

tergo-api-report() {
  local root
  root=$(_tergo_api_root)
  printf '项目根目录：%s\n' "$root"
  if command -v curl >/dev/null 2>&1; then
    printf 'curl：%s\n' "$(command curl --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'curl：未安装'
  fi
  if command -v jq >/dev/null 2>&1; then
    printf 'jq：%s\n' "$(command jq --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'jq：未安装（JSON 提取命令不可用）'
  fi
  printf '请求文件：%s\n' "$(find "$root" -type f \( -name '*.http' -o -name '*.rest' \) -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"
}

tergo-api-list() {
  local root
  root=$(_tergo_api_root)
  find "$root" -type f \( -name '*.http' -o -name '*.rest' -o -iname 'openapi.yaml' -o -iname 'openapi.yml' -o -iname 'openapi.json' -o -iname 'swagger.yaml' -o -iname 'swagger.yml' -o -iname 'swagger.json' \) -not -path '*/.git/*' -print 2>/dev/null | sort
  if [ "$(find "$root" -type f \( -name '*.http' -o -name '*.rest' -o -iname 'openapi.yaml' -o -iname 'openapi.yml' -o -iname 'openapi.json' -o -iname 'swagger.yaml' -o -iname 'swagger.yml' -o -iname 'swagger.json' \) -not -path '*/.git/*' -print 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ]; then
    printf '%s\n' '当前项目未发现 API 请求或 OpenAPI 文件。'
  fi
}

tergo-api-inspect() {
  local url
  url=$(_tergo_api_require_url "${1:-}") || return
  command curl --silent --show-error --location --max-time 15 \
    --proto '=http,https' --proto-redir '=http,https' \
    --dump-header - --output /dev/null \
    --write-out '\n状态：%{http_code}\n耗时：%{time_total}s\n最终地址：%{url_effective}\n' \
    -- "$url"
}

tergo-api-json() {
  local url=${1:-} filter=${2:-.}
  [ $# -le 2 ] || { printf '%s\n' '用法：tergo-api-json <url> [jq 过滤器]' >&2; return 2; }
  url=$(_tergo_api_require_url "$url") || return
  command -v jq >/dev/null 2>&1 || { printf '%s\n' '未找到 jq，请先安装 jq 后再提取 JSON。' >&2; return 127; }
  command curl --silent --show-error --fail --location --max-time 30 \
    --proto '=http,https' --proto-redir '=http,https' -- "$url" | command jq -r -- "$filter"
}

tergo-api-run() {
  local file method url config line header_name header_value result_status=0
  file=$(_tergo_api_request_file "${1:-}") || return
  method=$(awk 'NF && $1 !~ /^#/ {print toupper($1); exit}' "$file")
  url=$(awk 'NF && $1 !~ /^#/ {print $2; exit}' "$file")
  case "$method" in
    GET|HEAD|OPTIONS) ;;
    *) printf '%s\n' '请求模板只允许 GET、HEAD 或 OPTIONS；写请求请使用专门的高风险流程。' >&2; return 2 ;;
  esac
  url=$(_tergo_api_require_url "$url") || return
  config=$(umask 077; mktemp "${TMPDIR:-/tmp}/tergo-api-curl.XXXXXX") || return 1
  trap 'rm -f "$config"' EXIT HUP INT TERM
  {
    printf 'url = "%s"\n' "$url"
    printf 'request = "%s"\n' "$method"
    awk '
      BEGIN { started=0 }
      NF && $1 !~ /^#/ { if (!started) { started=1; next } }
      started && /^[[:space:]]*[A-Za-z0-9-]+:/ { print }
    ' "$file" | while IFS= read -r line; do
      header_name=${line%%:*}
      header_value=${line#*:}
      case "$header_name" in
        Authorization|authorization|Cookie|cookie|Set-Cookie|set-cookie|Proxy-Authorization|proxy-authorization)
          printf '跳过敏感请求头：%s\n' "$header_name" >&2
          continue
          ;;
      esac
      case "$line" in
        *'"'*|*'\\'*) printf '跳过含特殊字符的请求头：%s\n' "$header_name" >&2; continue ;;
      esac
      printf 'header = "%s: %s"\n' "$header_name" "${header_value# }"
    done
  } > "$config"
  command curl --silent --show-error --location --max-time 30 \
    --proto '=http,https' --proto-redir '=http,https' --config "$config" || result_status=$?
  rm -f "$config"
  trap - EXIT HUP INT TERM
  return $result_status
}

_tergo_api_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_api_alias apireport tergo-api-report
_tergo_api_alias apilist tergo-api-list
_tergo_api_alias apiinspect tergo-api-inspect
_tergo_api_alias apirun tergo-api-run

unset -f _tergo_api_alias

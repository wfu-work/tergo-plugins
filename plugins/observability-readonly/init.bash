# Tergo online plugin: read-only observability workflow (Sentry).

_tergo_obs_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then
    :
  else
    root=$PWD
  fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}

_tergo_obs_endpoint() {
  local endpoint=${SENTRY_URL:-https://sentry.io}
  endpoint=${endpoint%/}
  case "$endpoint" in
    http://*|https://*) ;;
    *) printf '%s\n' 'SENTRY_URL 必须是 http:// 或 https:// 地址。' >&2; return 2 ;;
  esac
  case "$endpoint" in
    http://*:*@*|https://*:*@*) printf '%s\n' 'SENTRY_URL 不能包含用户名或密码。' >&2; return 2 ;;
  esac
  if printf '%s' "$endpoint" | LC_ALL=C command grep -q '[[:cntrl:]]'; then
    printf '%s\n' 'SENTRY_URL 不能包含控制字符。' >&2
    return 2
  fi
  printf '%s\n' "$endpoint"
}

_tergo_obs_slug() {
  local label=$1 value=${2:-}
  [ -n "$value" ] || { printf '未设置 %s，请通过环境变量提供 Sentry 配置。\n' "$label" >&2; return 2; }
  case "$value" in
    *[!A-Za-z0-9._-]*) printf '%s 只能包含字母、数字、点、下划线和短横线。\n' "$label" >&2; return 2 ;;
  esac
  printf '%s\n' "$value"
}

_tergo_obs_token() {
  local token=${SENTRY_AUTH_TOKEN:-${SENTRY_ACCESS_TOKEN:-}}
  [ -n "$token" ] || {
    printf '%s\n' '未设置 SENTRY_AUTH_TOKEN 或 SENTRY_ACCESS_TOKEN。' >&2
    return 2
  }
  case "$token" in
    *'"'*|*'\\'*|*[[:cntrl:]]*) printf '%s\n' 'Sentry Token 包含不支持的字符。' >&2; return 2 ;;
  esac
  printf '%s\n' "$token"
}

_tergo_obs_limit() {
  local limit=${1:-10}
  case "$limit" in
    ''|*[!0-9]*) printf '%s\n' '数量必须是数字。' >&2; return 2 ;;
  esac
  [ "$limit" -ge 1 ] 2>/dev/null && [ "$limit" -le 100 ] 2>/dev/null || {
    printf '%s\n' '数量必须在 1 到 100 之间。' >&2
    return 2
  }
  printf '%s\n' "$limit"
}

_tergo_obs_require_tools() {
  command -v curl >/dev/null 2>&1 || { printf '%s\n' '未找到 curl，请先安装 curl。' >&2; return 127; }
  command -v jq >/dev/null 2>&1 || { printf '%s\n' '未找到 jq，请先安装 jq 后再查看 Sentry 摘要。' >&2; return 127; }
}

_tergo_obs_request() {
  local url=$1 token config result_status=0
  token=$(_tergo_obs_token) || return
  config=$(umask 077; mktemp "${TMPDIR:-/tmp}/tergo-sentry-curl.XXXXXX") || return 1
  trap 'rm -f "$config"' EXIT HUP INT TERM
  {
    printf 'url = "%s"\n' "$url"
    printf 'header = "Authorization: Bearer %s"\n' "$token"
    printf 'header = "Accept: application/json"\n'
    printf 'location\n'
    printf 'max-time = 20\n'
  } > "$config"
  command curl --silent --show-error --fail --config "$config" || result_status=$?
  rm -f "$config"
  trap - EXIT HUP INT TERM
  return "$result_status"
}

_tergo_obs_query() {
  local url=$1 filter=$2 response result_status=0
  response=$(umask 077; mktemp "${TMPDIR:-/tmp}/tergo-sentry-response.XXXXXX") || return 1
  trap 'rm -f "$response"' EXIT HUP INT TERM
  _tergo_obs_request "$url" > "$response" || result_status=$?
  if [ "$result_status" -eq 0 ]; then
    command jq -r -- "$filter" "$response" || result_status=$?
  fi
  rm -f "$response"
  trap - EXIT HUP INT TERM
  return "$result_status"
}

tergo-observability-report() {
  local endpoint
  endpoint=$(_tergo_obs_endpoint 2>/dev/null) || endpoint='无效地址'
  printf 'Sentry 地址：%s\n' "$endpoint"
  if [ -n "${SENTRY_AUTH_TOKEN:-${SENTRY_ACCESS_TOKEN:-}}" ]; then
    printf '%s\n' 'Token：已设置（值已隐藏）'
  else
    printf '%s\n' 'Token：未设置'
  fi
  printf '组织：%s\n' "${SENTRY_ORG:-未设置}"
  printf '项目：%s\n' "${SENTRY_PROJECT:-未设置}"
  if command -v curl >/dev/null 2>&1; then
    printf 'curl：%s\n' "$(command curl --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'curl：未安装'
  fi
  if command -v jq >/dev/null 2>&1; then
    printf 'jq：%s\n' "$(command jq --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'jq：未安装（API 摘要不可用）'
  fi
  if command -v sentry-cli >/dev/null 2>&1; then
    printf 'sentry-cli：%s\n' "$(command sentry-cli --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'sentry-cli：未安装（可选）'
  fi
  printf '%s\n' '插件只读取 Sentry 只读 API，不上传事件、不修改 Issue 或 Release。'
}

tergo-observability-config() {
  printf 'SENTRY_URL：%s\n' "${SENTRY_URL:+已设置}${SENTRY_URL:-使用默认 https://sentry.io}"
  printf 'SENTRY_ORG：%s\n' "${SENTRY_ORG:+已设置}${SENTRY_ORG:-未设置}"
  printf 'SENTRY_PROJECT：%s\n' "${SENTRY_PROJECT:+已设置}${SENTRY_PROJECT:-未设置}"
  if [ -n "${SENTRY_AUTH_TOKEN:-${SENTRY_ACCESS_TOKEN:-}}" ]; then
    printf '%s\n' 'Token 来源：环境变量（值已隐藏）'
  else
    printf '%s\n' 'Token 来源：未设置'
  fi
}

tergo-sentry-status() {
  local endpoint org project
  _tergo_obs_require_tools || return
  endpoint=$(_tergo_obs_endpoint) || return
  org=$(_tergo_obs_slug SENTRY_ORG "${SENTRY_ORG:-}") || return
  project=$(_tergo_obs_slug SENTRY_PROJECT "${SENTRY_PROJECT:-}") || return
  _tergo_obs_query "$endpoint/api/0/projects/$org/$project/" '[.id, .slug, .name, .status, .platform] | @tsv'
}

tergo-sentry-issues() {
  local endpoint org project limit
  _tergo_obs_require_tools || return
  limit=$(_tergo_obs_limit "${1:-10}") || return
  endpoint=$(_tergo_obs_endpoint) || return
  org=$(_tergo_obs_slug SENTRY_ORG "${SENTRY_ORG:-}") || return
  project=$(_tergo_obs_slug SENTRY_PROJECT "${SENTRY_PROJECT:-}") || return
  _tergo_obs_query "$endpoint/api/0/organizations/$org/issues/?project=$project&query=is%3Aunresolved&sort=date&limit=$limit" \
    '.[] | [.shortId, .level, .status, .title, .count, .lastSeen] | @tsv'
}

tergo-sentry-releases() {
  local endpoint org limit
  _tergo_obs_require_tools || return
  limit=$(_tergo_obs_limit "${1:-10}") || return
  endpoint=$(_tergo_obs_endpoint) || return
  org=$(_tergo_obs_slug SENTRY_ORG "${SENTRY_ORG:-}") || return
  _tergo_obs_query "$endpoint/api/0/organizations/$org/releases/?limit=$limit" \
    '.[] | [.version, (.projects | map(.slug) | join(",")), .dateCreated, .dateReleased, .lastEvent] | @tsv'
}

tergo-sentry-stats() {
  local endpoint org project
  _tergo_obs_require_tools || return
  endpoint=$(_tergo_obs_endpoint) || return
  org=$(_tergo_obs_slug SENTRY_ORG "${SENTRY_ORG:-}") || return
  project=$(_tergo_obs_slug SENTRY_PROJECT "${SENTRY_PROJECT:-}") || return
  _tergo_obs_query "$endpoint/api/0/projects/$org/$project/stats/?stat=received&resolution=1h" '.[] | map(tostring) | @tsv'
}

tergo-observability-links() {
  local endpoint org project
  endpoint=$(_tergo_obs_endpoint) || return
  org=$(_tergo_obs_slug SENTRY_ORG "${SENTRY_ORG:-}") || return
  project=$(_tergo_obs_slug SENTRY_PROJECT "${SENTRY_PROJECT:-}") || return
  printf '项目链接：%s/organizations/%s/issues/?project=%s\n' "$endpoint" "$org" "$project"
  printf 'Release 链接：%s/organizations/%s/releases/?project=%s\n' "$endpoint" "$org" "$project"
}

_tergo_obs_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_obs_alias obsreport tergo-observability-report
_tergo_obs_alias obsconfig tergo-observability-config
_tergo_obs_alias sentryissues tergo-sentry-issues
_tergo_obs_alias sentryreleases tergo-sentry-releases

unset -f _tergo_obs_alias

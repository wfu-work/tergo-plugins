# Tergo online plugin: Google Cloud read-only context.

_tergo_gcp_root() {
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

_tergo_gcp_require() {
  command -v gcloud >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 gcloud，请先安装 Google Cloud CLI；插件不会自动安装。' >&2
  return 127
}

_tergo_gcp_slug() {
  local label=$1 value=${2:-}
  [ -n "$value" ] || { printf '未设置 %s。\n' "$label" >&2; return 2; }
  case "$value" in
    -*|*[!A-Za-z0-9._-]*) printf '%s 包含不支持的字符。\n' "$label" >&2; return 2 ;;
  esac
  printf '%s\n' "$value"
}

_tergo_gcp_run() {
  command gcloud --quiet "$@"
}

_tergo_gcp_source_state() {
  local label=$1 value=$2
  if [ -n "$value" ]; then
    printf '%s：已设置（值已隐藏）\n' "$label"
  else
    printf '%s：未设置\n' "$label"
  fi
}

tergo-gcp-report() {
  local root project region zone
  root=$(_tergo_gcp_root)
  project=${GCLOUD_PROJECT:-${GOOGLE_CLOUD_PROJECT:-}}
  region=${CLOUDSDK_COMPUTE_REGION:-}
  zone=${CLOUDSDK_COMPUTE_ZONE:-}
  if command -v gcloud >/dev/null 2>&1; then
    project=$(_tergo_gcp_run config get-value project 2>/dev/null || true)
    region=$(_tergo_gcp_run config get-value compute/region 2>/dev/null || true)
    zone=$(_tergo_gcp_run config get-value compute/zone 2>/dev/null || true)
  fi
  printf '项目根目录：%s\n' "$root"
  if command -v gcloud >/dev/null 2>&1; then
    printf 'Google Cloud CLI：%s\n' "$(command gcloud version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'Google Cloud CLI：未安装'
  fi
  printf '当前配置：%s\n' "${CLOUDSDK_ACTIVE_CONFIG_NAME:-default}"
  printf '当前项目：%s\n' "${project:-未设置}"
  printf '当前区域：%s\n' "${region:-未设置}"
  printf '当前可用区：%s\n' "${zone:-未设置}"
  _tergo_gcp_source_state CLOUDSDK_CONFIG "${CLOUDSDK_CONFIG:-}"
  _tergo_gcp_source_state GOOGLE_APPLICATION_CREDENTIALS "${GOOGLE_APPLICATION_CREDENTIALS:-}"
  _tergo_gcp_source_state CLOUDSDK_AUTH_ACCESS_TOKEN "${CLOUDSDK_AUTH_ACCESS_TOKEN:-}"
  printf '%s\n' '插件只读取 Google Cloud 身份和上下文元数据，不输出服务账号密钥或 Access Token。'
}

tergo-gcp-config-sources() {
  printf 'active-config：%s\n' "${CLOUDSDK_ACTIVE_CONFIG_NAME:-default}"
  _tergo_gcp_source_state CLOUDSDK_CONFIG "${CLOUDSDK_CONFIG:-}"
  _tergo_gcp_source_state GOOGLE_APPLICATION_CREDENTIALS "${GOOGLE_APPLICATION_CREDENTIALS:-}"
  _tergo_gcp_source_state CLOUDSDK_AUTH_ACCESS_TOKEN "${CLOUDSDK_AUTH_ACCESS_TOKEN:-}"
  if [ -d "${CLOUDSDK_CONFIG:-${HOME:-}/.config/gcloud}" ]; then
    printf '%s\n' 'gcloud 配置目录：存在（内容已隐藏）'
  else
    printf '%s\n' 'gcloud 配置目录：未找到'
  fi
}

tergo-gcp-configs() {
  _tergo_gcp_require || return
  _tergo_gcp_run config configurations list --format='value(name)'
}

tergo-gcp-identity() {
  _tergo_gcp_require || return
  _tergo_gcp_run auth list --filter=status:ACTIVE --format='value(account)'
}

tergo-gcp-context() {
  local project region zone config
  _tergo_gcp_require || return
  config=$(_tergo_gcp_run config configurations list --filter=is_active:true --format='value(name)' 2>/dev/null | sed -n '1p')
  project=$(_tergo_gcp_run config get-value project 2>/dev/null || true)
  region=$(_tergo_gcp_run config get-value compute/region 2>/dev/null || true)
  zone=$(_tergo_gcp_run config get-value compute/zone 2>/dev/null || true)
  printf '配置：%s\n' "${config:-${CLOUDSDK_ACTIVE_CONFIG_NAME:-default}}"
  printf '项目：%s\n' "${project:-${GCLOUD_PROJECT:-${GOOGLE_CLOUD_PROJECT:-未设置}}}"
  printf '区域：%s\n' "${region:-${CLOUDSDK_COMPUTE_REGION:-未设置}}"
  printf '可用区：%s\n' "${zone:-${CLOUDSDK_COMPUTE_ZONE:-未设置}}"
}

tergo-gcp-regions() {
  _tergo_gcp_require || return
  _tergo_gcp_run compute regions list --format='value(name)'
}

tergo-gcp-console-link() {
  local project
  _tergo_gcp_require || return
  project=$(_tergo_gcp_run config get-value project 2>/dev/null || true)
  project=${project:-${GCLOUD_PROJECT:-${GOOGLE_CLOUD_PROJECT:-}}}
  project=$(_tergo_gcp_slug project "$project") || return
  printf 'Google Cloud 控制台链接：https://console.cloud.google.com/home/dashboard?project=%s\n' "$project"
  printf '当前项目：%s\n' "$project"
}

_tergo_gcp_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_gcp_alias gcpreport tergo-gcp-report
_tergo_gcp_alias gcpconfig tergo-gcp-config-sources
_tergo_gcp_alias gcpconfigs tergo-gcp-configs
_tergo_gcp_alias gcpidentity tergo-gcp-identity
_tergo_gcp_alias gcpcontext tergo-gcp-context

unset -f _tergo_gcp_alias

# Tergo online plugin: container registry workflow.

_tergo_registry_root() {
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

_tergo_registry_ref() {
  local reference=${1:-}
  [ -n "$reference" ] || { printf '%s\n' '镜像引用不能为空。' >&2; return 2; }
  case "$reference" in
    -*|*[[:space:]]*) printf '%s\n' '镜像引用不能以短横线开头或包含空格。' >&2; return 2 ;;
  esac
  if printf '%s' "$reference" | LC_ALL=C command grep -q '[[:cntrl:]]'; then
    printf '%s\n' '镜像引用不能包含控制字符。' >&2
    return 2
  fi
  case "$reference" in
    *[!A-Za-z0-9./:@_-]*) printf '%s\n' '镜像引用包含不支持的字符。' >&2; return 2 ;;
  esac
  printf '%s\n' "$reference"
}

_tergo_registry_require_docker() {
  command -v docker >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 docker，请先安装 Docker CLI。' >&2
  return 127
}

_tergo_registry_require_crane() {
  command -v crane >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 crane；远程仓库摘要和标签查询需要 crane。' >&2
  return 127
}

_tergo_registry_digest_ref() {
  local reference=${1:-}
  reference=$(_tergo_registry_ref "$reference") || return
  printf '%s' "$reference" | LC_ALL=C command grep -Eq '@sha256:[0-9A-Fa-f]{64}$' || {
    printf '%s\n' '清理预览需要带完整 sha256 digest 的镜像引用。' >&2
    return 2
  }
  printf '%s\n' "$reference"
}

_tergo_registry_tool_version() {
  local tool=$1
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%s：%s\n' "$tool" "$(command "$tool" --version 2>&1 | sed -n '1p')"
  else
    printf '%s：未安装\n' "$tool"
  fi
}

tergo-registry-report() {
  local root
  root=$(_tergo_registry_root)
  printf '项目根目录：%s\n' "$root"
  _tergo_registry_tool_version docker
  _tergo_registry_tool_version crane
  _tergo_registry_tool_version trivy
  _tergo_registry_tool_version gh
  printf 'Docker 配置来源：%s\n' "${DOCKER_CONFIG:-${REGISTRY_AUTH_FILE:-默认 CLI 配置}}"
  printf '%s\n' '插件不会读取或输出 Docker、Registry、GHCR 或云 CLI 凭据。'
}

tergo-registry-local-images() {
  _tergo_registry_require_docker || return
  command docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}'
}

tergo-registry-digest() {
  local reference
  reference=$(_tergo_registry_ref "${1:-}") || return
  if command -v crane >/dev/null 2>&1; then
    command crane digest "$reference"
    return
  fi
  _tergo_registry_require_docker || return
  printf '%s\n' '未找到 crane，回退到 docker manifest inspect；输出可能是完整 manifest。' >&2
  command docker manifest inspect "$reference"
}

tergo-registry-tags() {
  local repository
  repository=$(_tergo_registry_ref "${1:-}") || return
  _tergo_registry_require_crane || return
  command crane ls "$repository"
}

tergo-registry-scan-preview() {
  local reference
  reference=$(_tergo_registry_ref "${1:-}") || return
  printf '镜像：%s\n' "$reference"
  printf '预览命令：trivy image --scanners vuln,secret,misconfig --ignore-unfixed %s\n' "$reference"
  printf '%s\n' '当前仅展示扫描命令，不下载镜像、不上传报告、不修改仓库。'
}

tergo-registry-cleanup-preview() {
  local reference
  reference=$(_tergo_registry_digest_ref "${1:-}") || return
  printf '目标：%s\n' "$reference"
  printf '预览命令：crane delete %s\n' "$reference"
  printf '%s\n' '当前仅展示删除命令，不删除标签、manifest 或远程镜像。'
}

_tergo_registry_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_registry_alias regreport tergo-registry-report
_tergo_registry_alias regimages tergo-registry-local-images
_tergo_registry_alias regdigest tergo-registry-digest
_tergo_registry_alias regtags tergo-registry-tags

unset -f _tergo_registry_alias

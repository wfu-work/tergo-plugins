# Tergo online plugin: Kubernetes Helm release workflow.

_tergo_helm_root() {
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

_tergo_helm_require() {
  command -v helm >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 helm，请先安装 Helm；插件不会自动安装。' >&2
  return 127
}

_tergo_helm_chart() {
  local root path candidate
  root=$(_tergo_helm_root)
  path=${1:-.}
  case "$path" in
    /*) candidate=$path ;;
    *) candidate="$root/$path" ;;
  esac
  candidate=$(CDPATH= cd -- "$candidate" 2>/dev/null && pwd -P) || {
    printf 'Chart 目录不存在：%s\n' "$path" >&2
    return 1
  }
  case "$candidate" in
    "$root"|"$root"/*) ;;
    *) printf '%s\n' 'Chart 必须位于当前项目内。' >&2; return 2 ;;
  esac
  [ -f "$candidate/Chart.yaml" ] || {
    printf '未找到 Chart.yaml：%s\n' "$candidate" >&2
    return 1
  }
  printf '%s\n' "$candidate"
}

_tergo_helm_release() {
  local release=${1:-}
  case "$release" in
    ''|*[!A-Za-z0-9._-]*) printf '%s\n' 'Release 名称只能包含字母、数字、点、下划线和短横线。' >&2; return 2 ;;
  esac
  case "$release" in
    -*) printf '%s\n' 'Release 名称不能以短横线开头。' >&2; return 2 ;;
  esac
  printf '%s\n' "$release"
}

_tergo_helm_namespace() {
  local namespace=${1:-}
  [ -z "$namespace" ] && return 0
  case "$namespace" in
    *[!A-Za-z0-9._-]*) printf '%s\n' 'Namespace 名称包含不支持的字符。' >&2; return 2 ;;
  esac
  case "$namespace" in
    -*) printf '%s\n' 'Namespace 名称不能以短横线开头。' >&2; return 2 ;;
  esac
  printf '%s\n' "$namespace"
}

tergo-helm-report() {
  local root chart_count
  root=$(_tergo_helm_root)
  printf '项目根目录：%s\n' "$root"
  if command -v helm >/dev/null 2>&1; then
    printf 'Helm：%s\n' "$(command helm version --short 2>&1 | sed -n '1p')"
    if command helm diff --help >/dev/null 2>&1; then
      printf '%s\n' 'helm-diff：已安装'
    else
      printf '%s\n' 'helm-diff：未安装（差异命令不可用）'
    fi
  else
    printf '%s\n' 'Helm：未安装'
  fi
  if command -v kubectl >/dev/null 2>&1; then
    printf 'kubectl：%s\n' "$(command kubectl version --client --short 2>&1 | sed -n '1p')"
  else
    printf '%s\n' 'kubectl：未安装（Release 查询不可用）'
  fi
  chart_count=$(find "$root" -type f -name 'Chart.yaml' -not -path '*/.git/*' -print 2>/dev/null | wc -l | tr -d ' ')
  printf 'Chart 数量：%s\n' "$chart_count"
  printf '当前上下文：%s\n' "${KUBE_CONTEXT:-${KUBECONTEXT:-未指定}}"
  printf '当前命名空间：%s\n' "${KUBE_NAMESPACE:-default}"
  printf '%s\n' 'upgrade、rollback 和删除操作不会由插件执行。'
}

tergo-helm-releases() {
  local namespace
  _tergo_helm_require || return
  namespace=$(_tergo_helm_namespace "${1:-}") || return
  if [ -n "$namespace" ]; then
    command helm list --namespace "$namespace" --all --max 100 --no-color
  else
    command helm list --all-namespaces --all --max 100 --no-color
  fi
}

tergo-helm-chart-lint() {
  local chart
  _tergo_helm_require || return
  chart=$(_tergo_helm_chart "${1:-.}") || return
  command helm lint "$chart"
}

tergo-helm-template() {
  local chart
  _tergo_helm_require || return
  chart=$(_tergo_helm_chart "${1:-.}") || return
  printf '%s\n' '渲染结果可能包含配置值，请勿直接发布到公共日志。' >&2
  command helm template tergo-preview "$chart" --no-hooks
}

tergo-helm-values() {
  local chart
  _tergo_helm_require || return
  chart=$(_tergo_helm_chart "${1:-.}") || return
  command helm show values "$chart"
}

tergo-helm-diff() {
  local release chart result_status=0
  _tergo_helm_require || return
  release=$(_tergo_helm_release "${1:-}") || return
  chart=$(_tergo_helm_chart "${2:-.}") || return
  command helm diff --help >/dev/null 2>&1 || {
    printf '%s\n' '未找到 helm-diff 插件，请先安装后再查看 Release 差异。' >&2
    return 127
  }
  printf '%s\n' '执行只读 Helm 差异检查，不会 upgrade 或修改集群。' >&2
  command helm diff upgrade "$release" "$chart" --no-color --detailed-exitcode || result_status=$?
  case "$result_status" in
    0|2) return 0 ;;
    *) return "$result_status" ;;
  esac
}

tergo-helm-upgrade-preview() {
  local release chart
  release=$(_tergo_helm_release "${1:-}") || return
  chart=$(_tergo_helm_chart "${2:-.}") || return
  printf 'Release：%s\n' "$release"
  printf 'Chart：%s\n' "$chart"
  printf '预览命令：helm upgrade %s %s --install --namespace <namespace>\n' "$release" "$chart"
  printf '%s\n' '当前仅展示命令，不执行 upgrade、安装或回滚。'
}

_tergo_helm_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_helm_alias helmreport tergo-helm-report
_tergo_helm_alias helmreleases tergo-helm-releases
_tergo_helm_alias helmlint tergo-helm-chart-lint
_tergo_helm_alias helmtemplate tergo-helm-template
_tergo_helm_alias helmdiff tergo-helm-diff

unset -f _tergo_helm_alias

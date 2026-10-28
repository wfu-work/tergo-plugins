# Tergo online plugin: CI workflow.

_tergo_ci_root() {
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    printf '%s\n' "$TERGO_PROJECT_ROOT"
    return 0
  fi
  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) && {
    printf '%s\n' "$root"
    return 0
  }
  printf '%s\n' '当前目录不是 Git 项目。' >&2
  return 1
}

_tergo_ci_provider() {
  if command -v gh >/dev/null 2>&1; then
    printf '%s\n' gh
    return 0
  fi
  if command -v glab >/dev/null 2>&1; then
    printf '%s\n' glab
    return 0
  fi
  printf '%s\n' '未找到 gh 或 glab，请先使用对应 CLI 登录。' >&2
  return 127
}

_tergo_ci_run_id() {
  local run=${1:-}
  case "$run" in
    ''|*[!0-9]*) printf '%s\n' '运行编号必须是数字。' >&2; return 2 ;;
  esac
  printf '%s\n' "$run"
}

_tergo_ci_count() {
  local count=${1:-10}
  case "$count" in
    ''|*[!0-9]*) printf '%s\n' '运行数量必须是数字。' >&2; return 2 ;;
  esac
  [ "$count" -ge 1 ] 2>/dev/null && [ "$count" -le 100 ] 2>/dev/null || {
    printf '%s\n' '运行数量必须在 1 到 100 之间。' >&2
    return 2
  }
  printf '%s\n' "$count"
}

tergo-ci-report() {
  local root remote
  root=$(_tergo_ci_root) || return
  remote=$(command git -C "$root" remote get-url origin 2>/dev/null || true)
  printf '项目根目录：%s\n' "$root"
  printf '远程仓库：%s\n' "${remote:-未设置 origin}"
  if command -v gh >/dev/null 2>&1; then
    printf 'gh：%s\n' "$(command gh --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'gh：未安装'
  fi
  if command -v glab >/dev/null 2>&1; then
    printf 'glab：%s\n' "$(command glab --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'glab：未安装'
  fi
  printf '%s\n' 'CI 命令复用现有 CLI 登录状态，不读取或保存 Token。'
}

tergo-ci-status() {
  local root provider
  root=$(_tergo_ci_root) || return
  provider=$(_tergo_ci_provider) || return
  case "$provider" in
    gh) command gh -R "$root" run list --limit 5 ;;
    glab) command glab -R "$root" pipeline list --per-page 5 ;;
  esac
}

tergo-ci-runs() {
  local root provider count
  count=$(_tergo_ci_count "${1:-10}") || return
  root=$(_tergo_ci_root) || return
  provider=$(_tergo_ci_provider) || return
  case "$provider" in
    gh) command gh -R "$root" run list --limit "$count" ;;
    glab) command glab -R "$root" pipeline list --per-page "$count" ;;
  esac
}

tergo-ci-log() {
  local root provider run
  run=$(_tergo_ci_run_id "${1:-}") || return
  root=$(_tergo_ci_root) || return
  provider=$(_tergo_ci_provider) || return
  case "$provider" in
    gh) command gh -R "$root" run view "$run" --log-failed ;;
    glab) command glab -R "$root" pipeline view "$run" ;;
  esac
}

tergo-ci-artifacts() {
  local root provider run
  run=$(_tergo_ci_run_id "${1:-}") || return
  root=$(_tergo_ci_root) || return
  provider=$(_tergo_ci_provider) || return
  case "$provider" in
    gh)
      command gh -R "$root" api "repos/{owner}/{repo}/actions/runs/$run/artifacts" \
        --jq '.artifacts[] | [.name, (.size_in_bytes|tostring), .expired] | @tsv'
      ;;
    glab) command glab -R "$root" pipeline view "$run" ;;
  esac
}

tergo-ci-rerun() {
  local root provider run
  run=$(_tergo_ci_run_id "${1:-}") || return
  root=$(_tergo_ci_root) || return
  provider=$(_tergo_ci_provider) || return
  printf '将重跑 CI 运行 %s 的失败任务。\n' "$run" >&2
  case "$provider" in
    gh) command gh -R "$root" run rerun "$run" --failed ;;
    glab) command glab -R "$root" pipeline retry "$run" ;;
  esac
}

_tergo_ci_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_ci_alias cireport tergo-ci-report
_tergo_ci_alias cistatus tergo-ci-status
_tergo_ci_alias ciruns tergo-ci-runs
_tergo_ci_alias cilog tergo-ci-log

unset -f _tergo_ci_alias

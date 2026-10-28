# Tergo online plugin: security scanner.

_tergo_security_root() {
  if [ -n "${TERGO_PROJECT_ROOT-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    printf '%s\n' "$TERGO_PROJECT_ROOT"
    return 0
  fi
  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) && {
    printf '%s\n' "$root"
    return 0
  }
  printf '%s\n' '当前目录不是 Git 项目' >&2
  return 1
}

_tergo_security_require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '未找到 %s，请先安装后再运行此扫描\n' "$1" >&2
    return 1
  fi
}

_tergo_security_gitleaks() {
  local root=$1 mode=$2 output=${3-}
  _tergo_security_require_tool gitleaks || return
  if command gitleaks dir --help >/dev/null 2>&1; then
    if [ "$mode" = report ]; then
      command gitleaks dir --redact --no-banner --report-format json --report-path "$output" "$root"
    else
      command gitleaks dir --redact --no-banner "$root"
    fi
    return $?
  fi
  if [ "$mode" = report ]; then
    command gitleaks detect --source "$root" --no-git --redact --no-banner --report-format json --report-path "$output"
  else
    command gitleaks detect --source "$root" --no-git --redact --no-banner
  fi
}

tergo-secret-scan() {
  local root
  root=$(_tergo_security_root) || return
  _tergo_security_gitleaks "$root" scan
}

tergo-dependency-scan() {
  local root
  root=$(_tergo_security_root) || return
  _tergo_security_require_tool osv-scanner || return
  if command osv-scanner scan source --help >/dev/null 2>&1; then
    command osv-scanner scan source -r "$root"
  else
    command osv-scanner --recursive "$root"
  fi
}

tergo-code-scan() {
  local root
  root=$(_tergo_security_root) || return
  _tergo_security_require_tool semgrep || return
  if command semgrep scan --help >/dev/null 2>&1; then
    command semgrep scan --config auto --metrics off --no-git-ignore "$root"
  else
    command semgrep --config auto --metrics off "$root"
  fi
}

tergo-security-report() {
  local root tool
  root=$(_tergo_security_root) || return
  printf '项目根目录：%s\n' "$root"
  printf '当前分支：%s\n' "$(command git -C "$root" branch --show-current 2>/dev/null || printf '分离 HEAD')"
  printf '未提交文件数：%s\n' "$(command git -C "$root" status --porcelain 2>/dev/null | command wc -l | command tr -d ' ')"
  for tool in gitleaks osv-scanner semgrep; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%-12s %s\n' "$tool" "$(command "$tool" --version 2>/dev/null | command head -n 1)"
    else
      printf '%-12s %s\n' "$tool" '未安装'
    fi
  done
  printf '%s\n' '报告不读取或打印环境变量、凭据和完整连接串。'
}

tergo-security-baseline() {
  local root temporary status=0
  root=$(_tergo_security_root) || return
  _tergo_security_require_tool gitleaks || return
  temporary=$(command mktemp "${TMPDIR:-/tmp}/tergo-gitleaks.XXXXXX") || return
  trap 'command rm -f "$temporary"' EXIT HUP INT TERM
  _tergo_security_gitleaks "$root" report "$temporary" || status=$?
  printf '%s\n' '以下是临时脱敏基线报告预览，项目文件未被修改：'
  if [ -s "$temporary" ]; then
    command sed -n '1,160p' "$temporary"
  else
    printf '%s\n' '扫描器没有生成报告内容。'
  fi
  command rm -f "$temporary"
  trap - EXIT HUP INT TERM
  return $status
}

_tergo_security_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1 && ! alias "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_security_alias secscan tergo-secret-scan
_tergo_security_alias depscan tergo-dependency-scan
_tergo_security_alias codescan tergo-code-scan
_tergo_security_alias secreport tergo-security-report
_tergo_security_alias secbaseline tergo-security-baseline

unset -f _tergo_security_alias

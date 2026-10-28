# Tergo online plugin: environment doctor.

_tergo_env_root() {
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

_tergo_env_tool_version() {
  local tool=$1
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%s：%s\n' "$tool" "$(command "$tool" --version 2>&1 | sed -n '1p')"
  else
    printf '%s：未安装\n' "$tool"
  fi
}

_tergo_env_source_label() {
  local root=$1 relative=$2
  if [ -f "$root/$relative" ]; then
    case "$relative" in
      .env|.env.local|.env.*) printf '%s：存在（内容已隐藏）\n' "$relative" ;;
      *) printf '%s：存在\n' "$relative" ;;
    esac
  else
    printf '%s：未找到\n' "$relative"
  fi
}

_tergo_env_names_from_file() {
  local file=$1
  [ -f "$file" ] || return 0
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ {
      line=$0
      sub(/^[[:space:]]*/, "", line)
      sub(/^export[[:space:]]+/, "", line)
      sub(/[[:space:]]*=.*/, "", line)
      print line
    }
  ' "$file" | sort -u
}

_tergo_env_process_names() {
  command env | sed 's/=.*//' | sort -u
}

tergo-env-report() {
  local root virtual_env
  root=$(_tergo_env_root)
  printf '项目根目录：%s\n' "$root"
  virtual_env=${VIRTUAL_ENV:-}
  printf '当前虚拟环境：%s\n' "${virtual_env:-未激活}"
  _tergo_env_tool_version mise
  _tergo_env_tool_version direnv
  _tergo_env_tool_version python3
  _tergo_env_tool_version python
  _tergo_env_tool_version uv
  _tergo_env_tool_version poetry
  _tergo_env_tool_version pipx
  printf '%s\n' '环境变量值不会被输出。'
}

tergo-env-tools() {
  local tool
  for tool in mise direnv python3 python uv poetry pipx; do
    _tergo_env_tool_version "$tool"
  done
}

tergo-env-sources() {
  local root
  root=$(_tergo_env_root)
  printf '项目根目录：%s\n' "$root"
  for source in .env .env.local .env.example .env.sample .python-version .tool-versions mise.toml .mise.toml .envrc pyproject.toml requirements.txt uv.lock poetry.lock; do
    _tergo_env_source_label "$root" "$source"
  done
  if command -v direnv >/dev/null 2>&1 && [ -f "$root/.envrc" ]; then
    printf '%s\n' 'direnv：发现 .envrc，仅显示来源状态，不加载或执行文件。'
  fi
  if command -v mise >/dev/null 2>&1 && { [ -f "$root/mise.toml" ] || [ -f "$root/.mise.toml" ] || [ -f "$root/.tool-versions" ]; }; then
    printf '%s\n' 'mise：发现项目版本配置，仅显示文件来源。'
  fi
}

tergo-env-vars() {
  local root file count
  root=$(_tergo_env_root)
  count=$(_tergo_env_process_names | wc -l | tr -d ' ')
  printf '进程环境变量数量：%s（只显示名称，不显示值）\n' "$count"
  for file in "$root/.env.example" "$root/.env.sample"; do
    [ -f "$file" ] || continue
    printf '声明变量（%s）：\n' "${file##*/}"
    _tergo_env_names_from_file "$file" | while IFS= read -r name; do
      if command printenv "$name" >/dev/null 2>&1; then
        printf '  %s：已设置\n' "$name"
      else
        printf '  %s：未设置\n' "$name"
      fi
    done
  done
  printf '%s\n' '出于安全原因，不读取或打印 .env 文件中的变量值。'
}

tergo-env-check() {
  local root file missing=0 found=0 name
  root=$(_tergo_env_root)
  file=''
  for candidate in "$root/.env.example" "$root/.env.sample"; do
    if [ -f "$candidate" ]; then
      file=$candidate
      break
    fi
  done
  [ -n "$file" ] || { printf '%s\n' '未找到 .env.example 或 .env.sample，无法检查必需变量。'; return 0; }
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    found=1
    if command printenv "$name" >/dev/null 2>&1; then
      printf '已设置：%s\n' "$name"
    else
      printf '缺少：%s\n' "$name"
      missing=1
    fi
  done <<EOF_NAMES
$(_tergo_env_names_from_file "$file")
EOF_NAMES
  if [ "$found" -eq 0 ]; then
    printf '未在 %s 中发现变量声明。\n' "${file##*/}"
  fi
  return "$missing"
}

_tergo_env_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_env_alias envreport tergo-env-report
_tergo_env_alias envtools tergo-env-tools
_tergo_env_alias envsources tergo-env-sources
_tergo_env_alias envvars tergo-env-vars
_tergo_env_alias envcheck tergo-env-check

unset -f _tergo_env_alias

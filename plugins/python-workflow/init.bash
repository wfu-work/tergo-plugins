# Tergo online plugin: Python workflow.

_tergo_python_root() {
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

_tergo_python_cmd() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' python3
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    printf '%s\n' python
    return 0
  fi
  printf '%s\n' '未找到 python3 或 python，请先安装 Python。' >&2
  return 127
}

_tergo_python_project() {
  local root
  root=$(_tergo_python_root)
  if [ -f "$root/pyproject.toml" ] || [ -f "$root/setup.py" ] || [ -f "$root/setup.cfg" ] || [ -f "$root/requirements.txt" ] || [ -f "$root/pytest.ini" ]; then
    printf '%s\n' "$root"
    return 0
  fi
  printf '当前项目不是 Python 项目：%s\n' "$root" >&2
  return 1
}

_tergo_python_module_available() {
  local python_cmd=$1 module=$2
  command "$python_cmd" -c "import $module" >/dev/null 2>&1
}

_tergo_python_tool_version() {
  local tool=$1
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%s：%s\n' "$tool" "$(command "$tool" --version 2>&1 | sed -n '1p')"
  else
    printf '%s：未安装\n' "$tool"
  fi
}

tergo-python-report() {
  local root python_cmd
  root=$(_tergo_python_root)
  printf '项目根目录：%s\n' "$root"
  if python_cmd=$(_tergo_python_cmd 2>/dev/null); then
    printf 'Python：%s\n' "$(command "$python_cmd" --version 2>&1 | sed -n '1p')"
    if _tergo_python_module_available "$python_cmd" pip; then
      printf 'pip：%s\n' "$(command "$python_cmd" -m pip --version 2>&1 | sed -n '1p')"
    else
      printf '%s\n' 'pip：当前 Python 未提供'
    fi
  else
    printf '%s\n' 'Python：未安装'
  fi
  _tergo_python_tool_version uv
  _tergo_python_tool_version poetry
  _tergo_python_tool_version pytest
  _tergo_python_tool_version ruff
  _tergo_python_tool_version mypy
  if [ -f "$root/pyproject.toml" ]; then printf '%s\n' '项目配置：pyproject.toml'; fi
  if [ -f "$root/requirements.txt" ]; then printf '%s\n' '依赖文件：requirements.txt'; fi
  if [ -f "$root/uv.lock" ]; then printf '%s\n' '锁定文件：uv.lock'; fi
  if [ -f "$root/poetry.lock" ]; then printf '%s\n' '锁定文件：poetry.lock'; fi
  printf '%s\n' '命令不会自动安装依赖或修改项目文件。'
}

tergo-python-env() {
  local python_cmd
  python_cmd=$(_tergo_python_cmd) || return
  command "$python_cmd" -c 'import platform, sys; print("解释器：" + sys.executable); print("版本：" + platform.python_version()); print("环境前缀：" + sys.prefix); print("基础前缀：" + sys.base_prefix)'
}

tergo-python-test() {
  local root python_cmd
  root=$(_tergo_python_project) || return
  python_cmd=$(_tergo_python_cmd) || return
  if command -v pytest >/dev/null 2>&1; then
    (cd "$root" && command pytest)
  elif _tergo_python_module_available "$python_cmd" pytest; then
    (cd "$root" && command "$python_cmd" -m pytest)
  else
    printf '%s\n' '未找到 pytest，请安装 pytest 后再运行测试。' >&2
    return 127
  fi
}

tergo-python-lint() {
  local root python_cmd
  root=$(_tergo_python_project) || return
  if command -v ruff >/dev/null 2>&1; then
    (cd "$root" && command ruff check .)
    return
  fi
  python_cmd=$(_tergo_python_cmd) || return
  if _tergo_python_module_available "$python_cmd" ruff; then
    (cd "$root" && command "$python_cmd" -m ruff check .)
    return
  fi
  printf '%s\n' '未找到 ruff，请安装 ruff 后再运行检查。' >&2
  return 127
}

tergo-python-typecheck() {
  local root python_cmd
  root=$(_tergo_python_project) || return
  if command -v mypy >/dev/null 2>&1; then
    (cd "$root" && command mypy .)
    return
  fi
  python_cmd=$(_tergo_python_cmd) || return
  if _tergo_python_module_available "$python_cmd" mypy; then
    (cd "$root" && command "$python_cmd" -m mypy .)
    return
  fi
  printf '%s\n' '未找到 mypy，请安装 mypy 后再运行类型检查。' >&2
  return 127
}

tergo-python-outdated() {
  local python_cmd
  python_cmd=$(_tergo_python_cmd) || return
  if command -v uv >/dev/null 2>&1; then
    command uv pip list --outdated
    return
  fi
  if _tergo_python_module_available "$python_cmd" pip; then
    command "$python_cmd" -m pip list --disable-pip-version-check --outdated
    return
  fi
  printf '%s\n' '未找到 pip 或 uv，无法检查依赖更新。' >&2
  return 127
}

tergo-python-install-preview() {
  local target=${1:-all}
  case "$target" in
    pytest) printf '%s\n' '建议命令：python -m pip install pytest' ;;
    ruff) printf '%s\n' '建议命令：python -m pip install ruff' ;;
    mypy) printf '%s\n' '建议命令：python -m pip install mypy' ;;
    all) printf '%s\n' '建议命令：python -m pip install pytest ruff mypy' ;;
    *) printf '%s\n' '目标必须是 pytest、ruff、mypy 或 all。' >&2; return 2 ;;
  esac
  printf '%s\n' '当前仅预览，不执行安装。'
}

_tergo_python_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_python_alias pyreport tergo-python-report
_tergo_python_alias pyenv tergo-python-env
_tergo_python_alias pytestgo tergo-python-test
_tergo_python_alias pylint tergo-python-lint
_tergo_python_alias pytypes tergo-python-typecheck
_tergo_python_alias pyoutdated tergo-python-outdated

unset -f _tergo_python_alias

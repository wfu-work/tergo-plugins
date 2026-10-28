# Tergo online plugin: developer toolbox.

_tergo_toolbox_root() {
  if [ -n "${TERGO_PROJECT_ROOT-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    printf '%s\n' "$TERGO_PROJECT_ROOT"
    return 0
  fi
  local root
  if command -v git >/dev/null 2>&1; then
    root=$(command git rev-parse --show-toplevel 2>/dev/null) && {
      printf '%s\n' "$root"
      return 0
    }
  fi
  pwd
}

_tergo_toolbox_require_one_arg() {
  if [ "$#" -ne 2 ] || [ -z "${1-}" ]; then
    printf '用法：%s <参数>\n' "$2" >&2
    return 2
  fi
}

tergo-search() {
  _tergo_toolbox_require_one_arg "${1-}" tergo-search || return
  local root
  root=$(_tergo_toolbox_root)
  if command -v rg >/dev/null 2>&1; then
    command rg --hidden --glob '!.git' -- "$1" "$root"
    return $?
  fi
  printf '%s\n' '未找到 rg，回退到 grep' >&2
  command find "$root" -type d -name .git -prune -o -type f -exec grep -n -I -e "$1" {} +
}

tergo-files() {
  local query=${1:-.}
  if [ "$#" -gt 1 ]; then
    printf '%s\n' '用法：tergo-files [文件名关键词]' >&2
    return 2
  fi
  local root
  root=$(_tergo_toolbox_root)
  if command -v fd >/dev/null 2>&1; then
    command fd --hidden --exclude .git --type f -- "$query" "$root"
    return $?
  fi
  printf '%s\n' '未找到 fd，回退到 find' >&2
  if [ "$query" = . ]; then
    command find "$root" -type d -name .git -prune -o -type f -print
  else
    command find "$root" -type d -name .git -prune -o -type f -print | command grep -i -F -e "$query"
  fi
}

tergo-preview() {
  _tergo_toolbox_require_one_arg "${1-}" tergo-preview || return
  local root file
  root=$(_tergo_toolbox_root)
  file=$1
  case "$file" in
    /*) ;;
    *) file="$root/$file" ;;
  esac
  if [ ! -f "$file" ]; then
    printf '文件不存在：%s\n' "$1" >&2
    return 1
  fi
  if command -v bat >/dev/null 2>&1; then
    command bat --paging=never --style=plain -- "$file"
  else
    command sed -n '1,240p' "$file"
  fi
}

tergo-fuzzy-file() {
  local root
  root=$(_tergo_toolbox_root)
  if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
      command fd --hidden --exclude .git --type f . "$root" | command fzf --height=40% --reverse
    else
      command find "$root" -type f -not -path '*/.git/*' -print | command fzf --height=40% --reverse
    fi
    return $?
  fi
  printf '%s\n' '未找到 fzf，输出前 200 个项目文件' >&2
  command find "$root" -type f -not -path '*/.git/*' -print | command head -n 200
}

tergo-diff-view() {
  local root
  root=$(_tergo_toolbox_root)
  if command -v delta >/dev/null 2>&1; then
    command git -C "$root" diff --color=always | command delta
  else
    command git -C "$root" diff --color=always
  fi
}

tergo-size-report() {
  local root
  root=$(_tergo_toolbox_root)
  command find "$root" -mindepth 1 -maxdepth 1 -exec du -sh {} + 2>/dev/null | command sort -h
}

tergo-tool-report() {
  local tool
  for tool in rg fd fzf bat eza delta git; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%-8s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '%-8s %s\n' "$tool" '未安装'
    fi
  done
}

_tergo_toolbox_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1 && ! alias "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_toolbox_alias tsearch tergo-search
_tergo_toolbox_alias tfiles tergo-files
_tergo_toolbox_alias tpreview tergo-preview
_tergo_toolbox_alias tfuzzy tergo-fuzzy-file
_tergo_toolbox_alias tdiff tergo-diff-view
_tergo_toolbox_alias tsize tergo-size-report
_tergo_toolbox_alias treport tergo-tool-report

unset -f _tergo_toolbox_alias

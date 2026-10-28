# Tergo online plugin: developer toolbox.

_tergo_toolbox_root() {
  if [[ -n ${TERGO_PROJECT_ROOT-} && -d ${TERGO_PROJECT_ROOT} ]]; then
    print -r -- "$TERGO_PROJECT_ROOT"
    return 0
  fi
  local root
  if (( $+commands[git] )); then
    root=$(command git rev-parse --show-toplevel 2>/dev/null) && {
      print -r -- "$root"
      return 0
    }
  fi
  pwd
}

_tergo_toolbox_require_one_arg() {
  if (( $# != 2 )) || [[ -z ${1-} ]]; then
    print -u2 -- "用法：$2 <参数>"
    return 2
  fi
}

tergo-search() {
  _tergo_toolbox_require_one_arg "${1-}" tergo-search || return
  local root
  root=$(_tergo_toolbox_root)
  if (( $+commands[rg] )); then
    command rg --hidden --glob '!.git' -- "$1" "$root"
    return $?
  fi
  print -u2 -- "未找到 rg，回退到 grep"
  command find "$root" -type d -name .git -prune -o -type f -exec grep -n -I -e "$1" {} +
}

tergo-files() {
  local query=${1:-.}
  if (( $# > 1 )); then
    print -u2 -- "用法：tergo-files [文件名关键词]"
    return 2
  fi
  local root
  root=$(_tergo_toolbox_root)
  if (( $+commands[fd] )); then
    command fd --hidden --exclude .git --type f -- "$query" "$root"
    return $?
  fi
  print -u2 -- "未找到 fd，回退到 find"
  if [[ "$query" == . ]]; then
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
  if [[ "$file" != /* ]]; then
    file="$root/$file"
  fi
  if [[ ! -f "$file" ]]; then
    print -u2 -- "文件不存在：$1"
    return 1
  fi
  if (( $+commands[bat] )); then
    command bat --paging=never --style=plain -- "$file"
  else
    command sed -n '1,240p' "$file"
  fi
}

tergo-fuzzy-file() {
  local root
  root=$(_tergo_toolbox_root)
  if (( $+commands[fzf] )); then
    if (( $+commands[fd] )); then
      command fd --hidden --exclude .git --type f . "$root" | command fzf --height=40% --reverse
    else
      command find "$root" -type f -not -path '*/.git/*' -print | command fzf --height=40% --reverse
    fi
    return $?
  fi
  print -u2 -- "未找到 fzf，输出前 200 个项目文件"
  command find "$root" -type f -not -path '*/.git/*' -print | command head -n 200
}

tergo-diff-view() {
  local root
  root=$(_tergo_toolbox_root)
  if (( $+commands[delta] )); then
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
    if (( $+commands[$tool] )); then
      printf '%-8s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '%-8s %s\n' "$tool" "未安装"
    fi
  done
}

_tergo_toolbox_alias() {
  local alias_name=$1 function_name=$2
  if ! whence -w "$alias_name" >/dev/null 2>&1; then
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

unfunction _tergo_toolbox_alias

# Tergo online plugin: release workflow.

_tergo_release_root() {
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

_tergo_release_count() {
  local count=${1:-20}
  case "$count" in
    ''|*[!0-9]*) printf '%s\n' '提交数必须是数字' >&2; return 2 ;;
  esac
  if [ "${#count}" -gt 3 ]; then
    printf '%s\n' '提交数必须是最多三位数字' >&2
    return 2
  fi
  printf '%s\n' "$count"
}

_tergo_release_version_ok() {
  if ! printf '%s\n' "$1" | command grep -Eq '^v?[0-9]+([.][0-9]+)*(-[0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$'; then
    printf '%s\n' '版本号必须符合 SemVer，例如 1.2.3 或 v1.2.3' >&2
    return 2
  fi
}

_tergo_release_tag_ok() {
  local root=$1 tag=$2
  if [ -z "$tag" ] || [ "${tag#-}" != "$tag" ]; then
    printf '%s\n' '标签不能为空且不能以短横线开头' >&2
    return 2
  fi
  command git -C "$root" check-ref-format --allow-onelevel "refs/tags/$tag" >/dev/null 2>&1 || {
    printf 'Git 标签格式无效：%s\n' "$tag" >&2
    return 2
  }
}

tergo-release-status() {
  local root branch upstream latest
  root=$(_tergo_release_root) || return
  branch=$(command git -C "$root" branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch='分离 HEAD'
  upstream=$(command git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  latest=$(command git -C "$root" describe --tags --abbrev=0 2>/dev/null || true)
  printf '项目根目录：%s\n' "$root"
  printf '当前分支：%s\n' "$branch"
  if command git -C "$root" diff --quiet && command git -C "$root" diff --cached --quiet; then
    printf '%s\n' '工作区状态：clean'
  else
    printf '%s\n' '工作区状态：dirty'
  fi
  printf '上游分支：%s\n' "${upstream:-未设置}"
  printf '最近标签：%s\n' "${latest:-未找到}"
}

tergo-release-commit-check() {
  local root count subject invalid=0
  root=$(_tergo_release_root) || return
  count=$(_tergo_release_count "${1:-20}") || return
  while IFS= read -r subject; do
    [ -z "$subject" ] && continue
    case "$subject" in
      Merge\ *) printf '跳过合并提交：%s\n' "$subject" ;;
      *)
        if printf '%s\n' "$subject" | command grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]*\))?(!)?: .+'; then
          printf '通过：%s\n' "$subject"
        else
          printf '不符合 Conventional Commits：%s\n' "$subject"
          invalid=1
        fi
        ;;
    esac
  done < <(command git -C "$root" log -n "$count" --format=%s)
  if [ "$invalid" -ne 0 ]; then
    return 1
  fi
}

tergo-release-changelog() {
  local root from_tag latest range
  root=$(_tergo_release_root) || return
  from_tag=${1-}
  if [ -z "$from_tag" ]; then
    from_tag=$(command git -C "$root" describe --tags --abbrev=0 2>/dev/null) || {
      printf '%s\n' '未找到起始标签，请提供一个标签' >&2
      return 1
    }
  fi
  _tergo_release_tag_ok "$root" "$from_tag" || return
  command git -C "$root" rev-parse --verify "$from_tag^{commit}" >/dev/null 2>&1 || {
    printf '标签不存在：%s\n' "$from_tag" >&2
    return 1
  }
  latest=$(command git -C "$root" rev-parse --short HEAD)
  range="$from_tag..HEAD"
  printf '# 变更摘要（%s → %s）\n\n' "$from_tag" "$latest"
  command git -C "$root" log "$range" --format='- %s (%h)' --no-merges
}

tergo-release-version-check() {
  local root value found=0
  root=$(_tergo_release_root) || return
  if [ -f "$root/package.json" ]; then
    value=$(command sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/package.json" | command head -n 1)
    printf 'package.json：%s\n' "${value:-未找到 version}"
    found=1
  fi
  if [ -f "$root/Cargo.toml" ]; then
    value=$(command sed -n 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$root/Cargo.toml" | command head -n 1)
    printf 'Cargo.toml：%s\n' "${value:-未找到 version}"
    found=1
  fi
  if [ -f "$root/go.mod" ]; then
    printf '%s\n' 'go.mod：Go 模块没有统一的项目 version 字段'
    found=1
  fi
  if [ "$found" -eq 0 ]; then
    printf '%s\n' '未识别到 package.json、Cargo.toml 或 go.mod'
  fi
}

tergo-release-preview() {
  local root version latest
  root=$(_tergo_release_root) || return
  version=${1-}
  [ -n "$version" ] || { printf '%s\n' '用法：tergo-release-preview <版本号>' >&2; return 2; }
  _tergo_release_version_ok "$version" || return
  if ! command git -C "$root" diff --quiet || ! command git -C "$root" diff --cached --quiet; then
    printf '%s\n' '工作区有未提交更改，不能预览发布' >&2
    return 1
  fi
  latest=$(command git -C "$root" describe --tags --abbrev=0 2>/dev/null || true)
  printf '发布版本：%s\n' "$version"
  printf '起始标签：%s\n' "${latest:-无标签，将从全部历史生成摘要}"
  printf '%s\n' '将执行：创建本地 annotated tag；不会自动修改 changelog，不会推送远程。'
  printf '建议命令：git tag -a %s -m "Release %s"\n' "$version" "$version"
}

tergo-release-tag() {
  local root version
  root=$(_tergo_release_root) || return
  version=${1-}
  [ -n "$version" ] || { printf '%s\n' '用法：tergo-release-tag <版本号>' >&2; return 2; }
  _tergo_release_version_ok "$version" || return
  command git -C "$root" diff --quiet && command git -C "$root" diff --cached --quiet || {
    printf '%s\n' '工作区有未提交更改，拒绝创建发布标签' >&2
    return 1
  }
  if command git -C "$root" rev-parse --verify "refs/tags/$version" >/dev/null 2>&1; then
    printf '标签已存在：%s\n' "$version" >&2
    return 1
  fi
  command git -C "$root" tag -a "$version" -m "Release $version"
  printf '已创建本地标签：%s\n' "$version"
}

_tergo_release_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1 && ! alias "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_release_alias rstatus tergo-release-status
_tergo_release_alias rcommits tergo-release-commit-check
_tergo_release_alias rchangelog tergo-release-changelog
_tergo_release_alias rversions tergo-release-version-check
_tergo_release_alias rpreview tergo-release-preview
_tergo_release_alias rtag tergo-release-tag

unset -f _tergo_release_alias

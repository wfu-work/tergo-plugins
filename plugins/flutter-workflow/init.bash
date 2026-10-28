# Tergo online plugin: Flutter workflow.

_tergo_flutter_root() {
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

_tergo_flutter_require() {
  command -v flutter >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 flutter，请先安装 Flutter SDK 并加入 PATH。' >&2
  return 127
}

_tergo_flutter_project() {
  local root
  root=$(_tergo_flutter_root)
  [ -f "$root/pubspec.yaml" ] || {
    printf '当前项目不是 Flutter 项目：%s\n' "$root" >&2
    return 1
  }
  printf '%s\n' "$root"
}

tergo-flutter-report() {
  local root
  root=$(_tergo_flutter_root)
  printf '项目根目录：%s\n' "$root"
  if command -v flutter >/dev/null 2>&1; then
    printf 'Flutter：%s\n' "$(command flutter --version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' 'Flutter：未安装'
  fi
  if command -v dart >/dev/null 2>&1; then
    printf 'Dart：%s\n' "$(command dart --version 2>&1 | sed -n '1p')"
  else
    printf '%s\n' 'Dart：未安装'
  fi
  if [ -f "$root/pubspec.yaml" ]; then
    printf '%s\n' '项目类型：Flutter（发现 pubspec.yaml）'
  else
    printf '%s\n' '项目类型：未发现 pubspec.yaml'
  fi
}

tergo-flutter-doctor() {
  _tergo_flutter_require || return
  command flutter doctor -v
}

tergo-flutter-devices() {
  _tergo_flutter_require || return
  command flutter devices
}

tergo-flutter-analyze() {
  local root
  _tergo_flutter_require || return
  root=$(_tergo_flutter_project) || return
  (cd "$root" && command flutter analyze)
}

tergo-flutter-test() {
  local root
  _tergo_flutter_require || return
  root=$(_tergo_flutter_project) || return
  (cd "$root" && command flutter test)
}

tergo-flutter-pub-outdated() {
  local root
  _tergo_flutter_require || return
  root=$(_tergo_flutter_project) || return
  (cd "$root" && command flutter pub outdated)
}

tergo-flutter-build-preview() {
  local target=${1:-ios}
  case "$target" in
    ios|android|web|macos|linux|windows) ;;
    *) printf '%s\n' '构建平台必须是 ios、android、web、macos、linux 或 windows。' >&2; return 2 ;;
  esac
  _tergo_flutter_project >/dev/null || return
  printf '目标平台：%s\n' "$target"
  printf '预览命令：flutter build %s --release\n' "$target"
  printf '%s\n' '当前仅预览，不执行构建、签名或发布。'
}

_tergo_flutter_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_flutter_alias freport tergo-flutter-report
_tergo_flutter_alias fdoctor tergo-flutter-doctor
_tergo_flutter_alias fdevices tergo-flutter-devices
_tergo_flutter_alias fanalyze tergo-flutter-analyze
_tergo_flutter_alias ftest tergo-flutter-test

unset -f _tergo_flutter_alias

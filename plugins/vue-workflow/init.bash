# Tergo online plugin: Vue workflow.

_tergo_vue_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT:-}" ]; then root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then :
  else root=$PWD; fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}
_tergo_vue_project() { local root; root=$(_tergo_vue_root); [ -f "$root/package.json" ] || { printf '当前项目未发现 package.json：%s\n' "$root" >&2; return 1; }; printf '%s\n' "$root"; }
_tergo_vue_package_manager() {
  local root=$1
  if [ -f "$root/pnpm-lock.yaml" ]; then printf '%s\n' pnpm
  elif [ -f "$root/yarn.lock" ]; then printf '%s\n' yarn
  elif [ -f "$root/bun.lockb" ] || [ -f "$root/bun.lock" ]; then printf '%s\n' bun
  else printf '%s\n' npm; fi
}
_tergo_vue_tool() { local root=$1 tool=$2 binary; if [ -x "$root/node_modules/.bin/$tool" ]; then binary="$root/node_modules/.bin/$tool"; elif command -v "$tool" >/dev/null 2>&1; then binary=$tool; else printf '%s：未安装\n' "$tool"; return 0; fi; printf '%s：%s\n' "$tool" "$(command "$binary" --version 2>&1 | sed -n '1p')"; }
_tergo_vue_local_tool() { local root=$1 tool=$2 binary; if [ -x "$root/node_modules/.bin/$tool" ]; then printf '%s\n' "$root/node_modules/.bin/$tool"; elif binary=$(command -v "$tool" 2>/dev/null); then printf '%s\n' "$binary"; else printf '未找到 %s，请先安装项目依赖或将其加入 PATH。\n' "$tool" >&2; return 127; fi; }
_tergo_vue_exec() { local manager=$1; shift; case "$manager" in npm) command npm "$@";; pnpm) command pnpm "$@";; yarn) command yarn "$@";; bun) command bun "$@";; *) return 127;; esac; }
_tergo_vue_require_manager() { local manager=$1; command -v "$manager" >/dev/null 2>&1 && return 0; printf '未找到 %s，请先安装项目使用的包管理器。\n' "$manager" >&2; return 127; }

tergo-vue-report() {
  local root manager
  root=$(_tergo_vue_root); printf '项目根目录：%s\n' "$root"
  _tergo_vue_tool "$root" node; _tergo_vue_tool "$root" npm; _tergo_vue_tool "$root" pnpm; _tergo_vue_tool "$root" yarn; _tergo_vue_tool "$root" bun; _tergo_vue_tool "$root" vue-tsc; _tergo_vue_tool "$root" eslint; _tergo_vue_tool "$root" vitest; _tergo_vue_tool "$root" vite
  if [ -f "$root/package.json" ]; then
    manager=$(_tergo_vue_package_manager "$root")
    printf '包管理器：%s\n' "$manager"
    [ -f "$root/pnpm-lock.yaml" ] && printf '%s\n' '锁定文件：发现 pnpm-lock.yaml' || true
    [ -f "$root/package-lock.json" ] && printf '%s\n' '锁定文件：发现 package-lock.json' || true
    [ -f "$root/yarn.lock" ] && printf '%s\n' '锁定文件：发现 yarn.lock' || true
    [ -f "$root/bun.lock" ] || [ -f "$root/bun.lockb" ] && printf '%s\n' '锁定文件：发现 bun lockfile' || true
    if grep -Eq '"vue"[[:space:]]*:' "$root/package.json"; then printf '%s\n' 'Vue 依赖：已声明'; else printf '%s\n' 'Vue 依赖：未在 package.json 中发现'; fi
    if grep -Eq '"vite"[[:space:]]*:' "$root/package.json"; then printf '%s\n' 'Vite 依赖：已声明'; else printf '%s\n' 'Vite 依赖：未在 package.json 中发现'; fi
    if grep -Eq '"typescript"[[:space:]]*:' "$root/package.json"; then printf '%s\n' 'TypeScript 依赖：已声明'; else printf '%s\n' 'TypeScript 依赖：未在 package.json 中发现'; fi
  else
    printf '%s\n' '项目类型：未发现 package.json'
  fi
  printf '%s\n' '命令不会自动安装依赖、修改 lockfile 或发布前端产物。'
}
tergo-vue-files() { local root; root=$(_tergo_vue_root); find "$root" -type f \( -name 'package.json' -o -name '*lock*' -o -name '*.vue' -o -name 'vite.config.*' -o -name 'tsconfig*.json' \) -not -path '*/.git/*' -not -path '*/node_modules/*' -print 2>/dev/null | sort; }
tergo-vue-lockfile() { local root manager; root=$(_tergo_vue_project) || return; manager=$(_tergo_vue_package_manager "$root"); printf '包管理器：%s\n' "$manager"; if [ -f "$root/pnpm-lock.yaml" ] || [ -f "$root/package-lock.json" ] || [ -f "$root/yarn.lock" ] || [ -f "$root/bun.lock" ] || [ -f "$root/bun.lockb" ]; then printf '%s\n' 'lockfile：已发现'; else printf '%s\n' 'lockfile：未发现'; return 1; fi; }
tergo-vue-typecheck() { local root binary; root=$(_tergo_vue_project) || return; binary=$(_tergo_vue_local_tool "$root" vue-tsc) || return; (cd "$root" && command "$binary" --noEmit); }
tergo-vue-lint() { local root binary; root=$(_tergo_vue_project) || return; binary=$(_tergo_vue_local_tool "$root" eslint) || return; (cd "$root" && command "$binary" .); }
tergo-vue-test() { local root binary; root=$(_tergo_vue_project) || return; binary=$(_tergo_vue_local_tool "$root" vitest) || return; (cd "$root" && command "$binary" run); }
tergo-vue-audit() { local root manager; root=$(_tergo_vue_project) || return; manager=$(_tergo_vue_package_manager "$root"); _tergo_vue_require_manager "$manager" || return; printf '%s\n' '将访问包仓库查询漏洞，不修改 package.json 或 lockfile。' >&2; case "$manager" in npm) (cd "$root" && _tergo_vue_exec "$manager" audit --audit-level=moderate);; pnpm) (cd "$root" && _tergo_vue_exec "$manager" audit --audit-level=moderate);; yarn) (cd "$root" && _tergo_vue_exec "$manager" npm audit);; bun) printf '%s\n' '当前 bun 工作流未提供统一 audit 命令，请使用 npm/pnpm/yarn audit。' >&2; return 2;; esac; }
tergo-vue-build-preview() { local root manager; root=$(_tergo_vue_project) || return; manager=$(_tergo_vue_package_manager "$root"); printf '项目：%s\n' "$root"; printf '预览命令：%s run build\n' "$manager"; printf '%s\n' '当前仅预览，不安装依赖、不执行构建或发布。'; }

_tergo_vue_alias() { local alias_name=$1 function_name=$2; if ! command -v "$alias_name" >/dev/null 2>&1; then alias "$alias_name=$function_name"; fi; }
_tergo_vue_alias vuereport tergo-vue-report; _tergo_vue_alias vuefiles tergo-vue-files; _tergo_vue_alias vuetypecheck tergo-vue-typecheck; _tergo_vue_alias vuelint tergo-vue-lint; _tergo_vue_alias vuetest tergo-vue-test
unset -f _tergo_vue_alias

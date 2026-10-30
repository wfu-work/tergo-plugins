# Tergo online plugin: Go workflow.

_tergo_go_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then :
  else root=$PWD; fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}

_tergo_go_require() { command -v go >/dev/null 2>&1 && return 0; printf '%s\n' '未找到 go，请先安装 Go。' >&2; return 127; }
_tergo_go_project() { local root; root=$(_tergo_go_root); [ -f "$root/go.mod" ] || { printf '当前项目未发现 go.mod：%s\n' "$root" >&2; return 1; }; printf '%s\n' "$root"; }
_tergo_go_tool() { local tool=$1 output; if command -v "$tool" >/dev/null 2>&1; then if [ "$tool" = go ]; then output=$(command go version 2>&1 | sed -n '1p'); else output=$(command "$tool" --version 2>&1 | sed -n '1p'); fi; printf '%s：%s\n' "$tool" "$output"; else printf '%s：未安装\n' "$tool"; fi; }

tergo-go-report() {
  local root module
  root=$(_tergo_go_root); printf '项目根目录：%s\n' "$root"
  _tergo_go_tool go; _tergo_go_tool staticcheck; _tergo_go_tool govulncheck
  module=$(sed -n 's/^module[[:space:]]*//p' "$root/go.mod" 2>/dev/null | sed -n '1p')
  printf 'Go module：%s\n' "${module:-未找到}"
  [ -f "$root/go.sum" ] && printf '%s\n' '依赖校验：发现 go.sum' || printf '%s\n' '依赖校验：未发现 go.sum'
  [ -f "$root/go.work" ] && printf '%s\n' 'Workspace：发现 go.work' || true
  printf '%s\n' '命令不会自动安装工具、整理依赖或发布二进制。'
}

tergo-go-files() { local root; root=$(_tergo_go_root); find "$root" -type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' -o -name 'go.work' \) -not -path '*/.git/*' -print 2>/dev/null | sort; }
tergo-go-test() { local root; _tergo_go_require || return; root=$(_tergo_go_project) || return; (cd "$root" && command go test ./...); }
tergo-go-vet() { local root; _tergo_go_require || return; root=$(_tergo_go_project) || return; (cd "$root" && command go vet ./...); }
tergo-go-fmt-check() { local root file formatted status=0; _tergo_go_require || return; root=$(_tergo_go_project) || return; while IFS= read -r file; do [ -n "$file" ] || continue; if formatted=$(command gofmt -l "$file" 2>/dev/null); then if [ -n "$formatted" ]; then printf '%s\n' "$formatted"; status=1; fi; else printf 'gofmt 无法解析：%s\n' "$file" >&2; status=1; fi; done < <(find "$root" -type f -name '*.go' -not -path '*/.git/*' -print 2>/dev/null); if [ "$status" -ne 0 ]; then return "$status"; fi; printf '%s\n' 'gofmt 检查通过。'; }
tergo-go-staticcheck() { local root; _tergo_go_require || return; command -v staticcheck >/dev/null 2>&1 || { printf '%s\n' '未找到 staticcheck，请先安装后再检查。' >&2; return 127; }; root=$(_tergo_go_project) || return; (cd "$root" && command staticcheck ./...); }
tergo-go-vuln() { local root; _tergo_go_require || return; command -v govulncheck >/dev/null 2>&1 || { printf '%s\n' '未找到 govulncheck，请先安装后再扫描。' >&2; return 127; }; root=$(_tergo_go_project) || return; (cd "$root" && command govulncheck ./...); }
tergo-go-outdated() { local root; _tergo_go_require || return; root=$(_tergo_go_project) || return; printf '%s\n' '将访问模块代理查询依赖更新；不会修改 go.mod 或 go.sum。' >&2; (cd "$root" && command go list -m -u all); }
tergo-go-build-preview() { local root; root=$(_tergo_go_project) || return; printf '项目：%s\n' "$root"; printf '%s\n' '预览命令：go build ./...'; printf '%s\n' '当前仅预览，不编译、不写入发布目录。'; }

_tergo_go_alias() { local alias_name=$1 function_name=$2; if ! command -v "$alias_name" >/dev/null 2>&1; then alias "$alias_name=$function_name"; fi; }
_tergo_go_alias goreport tergo-go-report; _tergo_go_alias gotest tergo-go-test; _tergo_go_alias govet tergo-go-vet; _tergo_go_alias gofmtcheck tergo-go-fmt-check
unset -f _tergo_go_alias

# Tergo online plugin: Rust workflow.

_tergo_rust_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then :
  else root=$PWD; fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}
_tergo_rust_require() { command -v cargo >/dev/null 2>&1 && return 0; printf '%s\n' '未找到 cargo，请先安装 Rust 工具链。' >&2; return 127; }
_tergo_rust_project() { local root; root=$(_tergo_rust_root); [ -f "$root/Cargo.toml" ] || { printf '当前项目未发现 Cargo.toml：%s\n' "$root" >&2; return 1; }; printf '%s\n' "$root"; }
_tergo_rust_tool() { local tool=$1; if command -v "$tool" >/dev/null 2>&1; then printf '%s：%s\n' "$tool" "$(command "$tool" --version 2>&1 | sed -n '1p')"; else printf '%s：未安装\n' "$tool"; fi; }

tergo-rust-report() {
  local root package
  root=$(_tergo_rust_root); printf '项目根目录：%s\n' "$root"
  _tergo_rust_tool rustc; _tergo_rust_tool cargo; _tergo_rust_tool rustfmt; _tergo_rust_tool cargo-audit; _tergo_rust_tool cargo-outdated
  package=$(awk -F'=' '/^[[:space:]]*name[[:space:]]*=/{value=$2; gsub(/[[:space:]]/, "", value); gsub(/"/, "", value); gsub(/\047/, "", value); print value; exit}' "$root/Cargo.toml" 2>/dev/null)
  printf 'Cargo package：%s\n' "${package:-未找到}"
  [ -f "$root/Cargo.lock" ] && printf '%s\n' '锁定文件：发现 Cargo.lock' || printf '%s\n' '锁定文件：未发现 Cargo.lock'
  [ -d "$root/target" ] && printf '%s\n' '构建目录：发现 target' || true
  printf '%s\n' '命令不会自动安装 toolchain、依赖或发布 crate。'
}
tergo-rust-files() { local root; root=$(_tergo_rust_root); find "$root" -type f \( -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name '*.rs' \) -not -path '*/.git/*' -not -path '*/target/*' -print 2>/dev/null | sort; }
tergo-rust-check() { local root; _tergo_rust_require || return; root=$(_tergo_rust_project) || return; (cd "$root" && command cargo check --all-targets --all-features); }
tergo-rust-test() { local root; _tergo_rust_require || return; root=$(_tergo_rust_project) || return; (cd "$root" && command cargo test --all-targets --all-features); }
tergo-rust-clippy() { local root; _tergo_rust_require || return; root=$(_tergo_rust_project) || return; (cd "$root" && command cargo clippy --all-targets --all-features -- -D warnings); }
tergo-rust-fmt-check() { local root; _tergo_rust_require || return; root=$(_tergo_rust_project) || return; (cd "$root" && command cargo fmt --all -- --check); }
tergo-rust-audit() { local root; _tergo_rust_require || return; command -v cargo-audit >/dev/null 2>&1 || { printf '%s\n' '未找到 cargo-audit，请先安装后再扫描。' >&2; return 127; }; root=$(_tergo_rust_project) || return; (cd "$root" && command cargo audit); }
tergo-rust-outdated() { local root; _tergo_rust_require || return; command -v cargo-outdated >/dev/null 2>&1 || { printf '%s\n' '未找到 cargo-outdated，请先安装后再检查。' >&2; return 127; }; root=$(_tergo_rust_project) || return; printf '%s\n' '将查询 crates.io 依赖更新；不会修改 Cargo.toml 或 Cargo.lock。' >&2; (cd "$root" && command cargo outdated); }
tergo-rust-build-preview() { local root; root=$(_tergo_rust_project) || return; printf '项目：%s\n' "$root"; printf '%s\n' '预览命令：cargo build --release'; printf '%s\n' '当前仅预览，不编译、不发布 crate。'; }

_tergo_rust_alias() { local alias_name=$1 function_name=$2; if ! command -v "$alias_name" >/dev/null 2>&1; then alias "$alias_name=$function_name"; fi; }
_tergo_rust_alias rustreport tergo-rust-report; _tergo_rust_alias rustcheck tergo-rust-check; _tergo_rust_alias rusttest tergo-rust-test; _tergo_rust_alias rustfmtcheck tergo-rust-fmt-check
unset -f _tergo_rust_alias

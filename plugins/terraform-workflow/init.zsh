# Tergo online plugin: Terraform workflow.

_tergo_terraform_root() {
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

_tergo_terraform_bin() {
  if command -v terraform >/dev/null 2>&1; then
    printf '%s\n' terraform
    return 0
  fi
  if command -v tofu >/dev/null 2>&1; then
    printf '%s\n' tofu
    return 0
  fi
  printf '%s\n' '未找到 terraform 或 tofu，请先安装 Terraform/OpenTofu。' >&2
  return 127
}

_tergo_terraform_project() {
  local root
  root=$(_tergo_terraform_root)
  find "$root" -type f -name '*.tf' -not -path '*/.git/*' -print -quit 2>/dev/null | grep -q . || {
    printf '当前项目未发现 Terraform 配置：%s\n' "$root" >&2
    return 1
  }
  printf '%s\n' "$root"
}

_tergo_terraform_count() {
  local root=$1 pattern=$2
  find "$root" -type f -name "$pattern" -not -path '*/.git/*' -print 2>/dev/null | wc -l | tr -d ' '
}

tergo-terraform-report() {
  local root bin
  root=$(_tergo_terraform_root)
  printf '项目根目录：%s\n' "$root"
  if bin=$(_tergo_terraform_bin 2>/dev/null); then
    printf '工具：%s\n' "$(command "$bin" version 2>/dev/null | sed -n '1p')"
  else
    printf '%s\n' '工具：未安装（支持 terraform 或 tofu）'
  fi
  printf 'Terraform 文件：%s\n' "$(_tergo_terraform_count "$root" '*.tf')"
  printf '变量文件：%s\n' "$(_tergo_terraform_count "$root" '*.tfvars')"
  printf '当前工作区：%s\n' "${TF_WORKSPACE:-default}"
  if [ -d "$root/.terraform" ]; then
    printf '%s\n' '初始化目录：已存在'
  else
    printf '%s\n' '初始化目录：未找到（不会自动 init）'
  fi
  printf '%s\n' 'plan、validate 和 fmt 命令不会执行 apply 或自动下载 provider。'
}

tergo-terraform-files() {
  local root
  root=$(_tergo_terraform_root)
  find "$root" -type f \( -name '*.tf' -o -name '*.tfvars' -o -name '*.tfvars.json' \) -not -path '*/.git/*' -print 2>/dev/null | sort
  if [ "$(_tergo_terraform_count "$root" '*.tf')" -eq 0 ]; then
    printf '%s\n' '当前项目未发现 .tf 文件。'
  fi
}

tergo-terraform-fmt-check() {
  local root bin
  root=$(_tergo_terraform_project) || return
  bin=$(_tergo_terraform_bin) || return
  (cd "$root" && command "$bin" fmt -check -diff -recursive)
}

tergo-terraform-validate() {
  local root bin
  root=$(_tergo_terraform_project) || return
  bin=$(_tergo_terraform_bin) || return
  (cd "$root" && command "$bin" validate -no-color)
}

tergo-terraform-plan() {
  local root bin result_status=0
  root=$(_tergo_terraform_project) || return
  bin=$(_tergo_terraform_bin) || return
  printf '%s\n' '执行只读 plan；不会写入 plan 文件，不会执行 apply。' >&2
  (cd "$root" && command "$bin" plan -input=false -no-color -lock=false) || result_status=$?
  if [ "$result_status" -eq 0 ]; then
    return 0
  fi
  printf '%s\n' '提示：Terraform plan 可能访问远程状态或显示资源差异，请勿把输出直接发布到公共日志。' >&2
  return "$result_status"
}

tergo-terraform-workspace() {
  local root bin
  root=$(_tergo_terraform_project) || return
  bin=$(_tergo_terraform_bin) || return
  (cd "$root" && command "$bin" workspace show)
}

tergo-terraform-apply-preview() {
  local root
  root=$(_tergo_terraform_project) || return
  printf '项目：%s\n' "$root"
  printf '%s\n' '预览：terraform apply -input=false'
  printf '%s\n' '当前仅展示命令，不执行 apply、批准变更或写入远程状态。'
}

_tergo_terraform_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_terraform_alias tfreport tergo-terraform-report
_tergo_terraform_alias tffiles tergo-terraform-files
_tergo_terraform_alias tffmt tergo-terraform-fmt-check
_tergo_terraform_alias tfvalidate tergo-terraform-validate
_tergo_terraform_alias tfplan tergo-terraform-plan
_tergo_terraform_alias tfworkspace tergo-terraform-workspace

unset -f _tergo_terraform_alias

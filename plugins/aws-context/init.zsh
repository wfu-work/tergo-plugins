# Tergo online plugin: AWS read-only context.

_tergo_aws_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then
    root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then
    :
  else
    root=$PWD
  fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}

_tergo_aws_require() {
  command -v aws >/dev/null 2>&1 && return 0
  printf '%s\n' '未找到 aws，请先安装 AWS CLI；插件不会自动安装。' >&2
  return 127
}

_tergo_aws_profile() {
  local profile=${1:-${AWS_PROFILE:-default}}
  case "$profile" in
    ''|*[!A-Za-z0-9._@-]*) printf '%s\n' 'AWS profile 只能包含字母、数字、点、下划线、@ 和短横线。' >&2; return 2 ;;
  esac
  printf '%s\n' "$profile"
}

_tergo_aws_run() {
  local profile=$1
  shift
  command aws --no-cli-pager --profile "$profile" "$@"
}

_tergo_aws_source_state() {
  local label=$1 value=$2
  if [ -n "$value" ]; then
    printf '%s：已设置（值已隐藏）\n' "$label"
  else
    printf '%s：未设置\n' "$label"
  fi
}

tergo-aws-report() {
  local root
  root=$(_tergo_aws_root)
  printf '项目根目录：%s\n' "$root"
  if command -v aws >/dev/null 2>&1; then
    printf 'AWS CLI：%s\n' "$(command aws --version 2>&1 | sed -n '1p')"
  else
    printf '%s\n' 'AWS CLI：未安装'
  fi
  printf 'AWS profile：%s\n' "${AWS_PROFILE:-default}"
  printf 'AWS region：%s\n' "${AWS_REGION:-${AWS_DEFAULT_REGION:-未设置}}"
  _tergo_aws_source_state AWS_CONFIG_FILE "${AWS_CONFIG_FILE:-}"
  _tergo_aws_source_state AWS_SHARED_CREDENTIALS_FILE "${AWS_SHARED_CREDENTIALS_FILE:-}"
  _tergo_aws_source_state AWS_SSO_SESSION_NAME "${AWS_SSO_SESSION_NAME:-}"
  _tergo_aws_source_state AWS_WEB_IDENTITY_TOKEN_FILE "${AWS_WEB_IDENTITY_TOKEN_FILE:-}"
  printf '%s\n' '插件只读取 AWS 身份和区域元数据，不输出 Access Key、Secret Key、Session Token 或凭据文件内容。'
}

tergo-aws-config-sources() {
  printf 'profile：%s\n' "${AWS_PROFILE:-default}"
  printf 'region：%s\n' "${AWS_REGION:-${AWS_DEFAULT_REGION:-未设置}}"
  _tergo_aws_source_state AWS_CONFIG_FILE "${AWS_CONFIG_FILE:-}"
  _tergo_aws_source_state AWS_SHARED_CREDENTIALS_FILE "${AWS_SHARED_CREDENTIALS_FILE:-}"
  _tergo_aws_source_state AWS_SSO_SESSION_NAME "${AWS_SSO_SESSION_NAME:-}"
  _tergo_aws_source_state AWS_WEB_IDENTITY_TOKEN_FILE "${AWS_WEB_IDENTITY_TOKEN_FILE:-}"
  if [ -f "${HOME:-}/.aws/config" ]; then printf '%s\n' '~/.aws/config：存在（内容已隐藏）'; else printf '%s\n' '~/.aws/config：未找到'; fi
  if [ -f "${HOME:-}/.aws/credentials" ]; then printf '%s\n' '~/.aws/credentials：存在（内容已隐藏）'; else printf '%s\n' '~/.aws/credentials：未找到'; fi
}

tergo-aws-profiles() {
  _tergo_aws_require || return
  command aws configure list-profiles
}

tergo-aws-identity() {
  local profile
  _tergo_aws_require || return
  profile=$(_tergo_aws_profile "${1:-}") || return
  _tergo_aws_run "$profile" sts get-caller-identity --query '[Account,Arn,UserId]' --output text
}

tergo-aws-region() {
  local profile region
  _tergo_aws_require || return
  profile=$(_tergo_aws_profile "${1:-}") || return
  region=$(_tergo_aws_run "$profile" configure get region 2>/dev/null || true)
  if [ -z "$region" ]; then
    region=${AWS_REGION:-${AWS_DEFAULT_REGION:-}}
  fi
  printf '%s\n' "${region:-未设置}"
}

tergo-aws-regions() {
  local profile
  _tergo_aws_require || return
  profile=$(_tergo_aws_profile "${1:-}") || return
  _tergo_aws_run "$profile" ec2 describe-regions --all-regions --query 'Regions[].RegionName' --output text
}

tergo-aws-console-link() {
  local profile region account
  _tergo_aws_require || return
  profile=$(_tergo_aws_profile "${1:-}") || return
  region=$(_tergo_aws_run "$profile" configure get region 2>/dev/null || true)
  region=${region:-${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}}
  account=$(_tergo_aws_run "$profile" sts get-caller-identity --query Account --output text) || return
  printf 'AWS 控制台链接：https://console.aws.amazon.com/console/home?region=%s\n' "$region"
  printf '当前账号：%s\n' "$account"
}

_tergo_aws_alias() {
  local alias_name=$1 function_name=$2
  if ! command -v "$alias_name" >/dev/null 2>&1; then
    alias "$alias_name=$function_name"
  fi
}

_tergo_aws_alias awsreport tergo-aws-report
_tergo_aws_alias awsconfig tergo-aws-config-sources
_tergo_aws_alias awsprofiles tergo-aws-profiles
_tergo_aws_alias awsidentity tergo-aws-identity
_tergo_aws_alias awsregion tergo-aws-region

unset -f _tergo_aws_alias

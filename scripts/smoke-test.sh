#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
plugins="$root/plugins"
zsh_bin=$(command -v zsh || true)
bash_bin=$(command -v bash || true)

project_root=${TERGO_SMOKE_PROJECT_ROOT:-}
if [ -z "$project_root" ]; then
  project_root=$(mktemp -d "${TMPDIR:-/tmp}/tergo-plugin-smoke.XXXXXX")
  trap 'rm -rf "$project_root"' EXIT HUP INT TERM
  git -C "$project_root" init -q
  printf '%s\n' 'Tergo smoke fixture' > "$project_root/README.md"
  git -C "$project_root" add README.md
  git -C "$project_root" -c user.name='Tergo Smoke' -c user.email='smoke@tergo.local' commit -q -m 'chore: add smoke fixture'
elif [ ! -d "$project_root" ]; then
  printf '测试项目不存在：%s\n' "$project_root" >&2
  exit 1
fi

run_zsh() {
  [ -n "$zsh_bin" ] || return 0
  "$zsh_bin" -f -c "$1" zsh "$project_root" "$plugins"
}

run_bash() {
  [ -n "$bash_bin" ] || return 0
  "$bash_bin" --noprofile --norc -c "$1" bash "$project_root" "$plugins"
}

run_zsh 'cd "$1"; source "$2/developer-toolbox/init.zsh"; tergo-tool-report >/dev/null; tergo-search Tergo >/dev/null; tergo-preview README.md >/dev/null; tergo-files README >/dev/null'
run_bash 'cd "$1"; source "$2/developer-toolbox/init.bash"; tergo-tool-report >/dev/null; tergo-search Tergo >/dev/null; tergo-preview README.md >/dev/null; tergo-files README >/dev/null'
run_zsh 'cd "$1"; source "$2/release-workflow/init.zsh"; tergo-release-status >/dev/null; tergo-release-version-check >/dev/null; tergo-release-preview 1.2.3 >/dev/null'
run_bash 'cd "$1"; source "$2/release-workflow/init.bash"; tergo-release-status >/dev/null; tergo-release-version-check >/dev/null; tergo-release-preview 1.2.3 >/dev/null'
run_zsh 'cd "$1"; source "$2/security-scanner/init.zsh"; tergo-security-report >/dev/null'
run_bash 'cd "$1"; source "$2/security-scanner/init.bash"; tergo-security-report >/dev/null'
run_zsh 'cd "$1"; source "$2/database-workbench/init.zsh"; tergo-db-report >/dev/null; tergo-db-config >/dev/null; if tergo-db-query postgres "UPDATE smoke SET value=1" >/dev/null 2>&1; then exit 1; fi'
run_bash 'cd "$1"; source "$2/database-workbench/init.bash"; tergo-db-report >/dev/null; tergo-db-config >/dev/null; if tergo-db-query postgres "UPDATE smoke SET value=1" >/dev/null 2>&1; then exit 1; fi'
run_zsh 'cd "$1"; source "$2/api-workbench/init.zsh"; tergo-api-report >/dev/null; tergo-api-list >/dev/null; if tergo-api-inspect ftp://invalid.test >/dev/null 2>&1; then exit 1; fi'
run_bash 'cd "$1"; source "$2/api-workbench/init.bash"; tergo-api-report >/dev/null; tergo-api-list >/dev/null; if tergo-api-inspect ftp://invalid.test >/dev/null 2>&1; then exit 1; fi'
run_zsh 'cd "$1"; source "$2/ci-workflow/init.zsh"; tergo-ci-report >/dev/null'
run_bash 'cd "$1"; source "$2/ci-workflow/init.bash"; tergo-ci-report >/dev/null'
run_zsh 'cd "$1"; source "$2/flutter-workflow/init.zsh"; tergo-flutter-report >/dev/null'
run_bash 'cd "$1"; source "$2/flutter-workflow/init.bash"; tergo-flutter-report >/dev/null'
run_zsh 'cd "$1"; source "$2/env-doctor/init.zsh"; tergo-env-report >/dev/null; tergo-env-tools >/dev/null; tergo-env-sources >/dev/null; tergo-env-vars >/dev/null; tergo-env-check >/dev/null'
run_bash 'cd "$1"; source "$2/env-doctor/init.bash"; tergo-env-report >/dev/null; tergo-env-tools >/dev/null; tergo-env-sources >/dev/null; tergo-env-vars >/dev/null; tergo-env-check >/dev/null'
run_zsh 'cd "$1"; source "$2/python-workflow/init.zsh"; tergo-python-report >/dev/null; tergo-python-env >/dev/null; tergo-python-install-preview all >/dev/null'
run_bash 'cd "$1"; source "$2/python-workflow/init.bash"; tergo-python-report >/dev/null; tergo-python-env >/dev/null; tergo-python-install-preview all >/dev/null'
run_zsh 'cd "$1"; source "$2/terraform-workflow/init.zsh"; tergo-terraform-report >/dev/null; tergo-terraform-files >/dev/null'
run_bash 'cd "$1"; source "$2/terraform-workflow/init.bash"; tergo-terraform-report >/dev/null; tergo-terraform-files >/dev/null'
run_zsh 'cd "$1"; source "$2/k8s-helm-release/init.zsh"; tergo-helm-report >/dev/null'
run_bash 'cd "$1"; source "$2/k8s-helm-release/init.bash"; tergo-helm-report >/dev/null'
run_zsh 'cd "$1"; source "$2/container-registry/init.zsh"; tergo-registry-report >/dev/null; tergo-registry-scan-preview alpine:latest >/dev/null; tergo-registry-cleanup-preview alpine@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef >/dev/null'
run_bash 'cd "$1"; source "$2/container-registry/init.bash"; tergo-registry-report >/dev/null; tergo-registry-scan-preview alpine:latest >/dev/null; tergo-registry-cleanup-preview alpine@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef >/dev/null'
run_zsh 'cd "$1"; source "$2/observability-readonly/init.zsh"; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-report >/dev/null; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-config >/dev/null; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-links >/dev/null'
run_bash 'cd "$1"; source "$2/observability-readonly/init.bash"; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-report >/dev/null; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-config >/dev/null; SENTRY_ORG=demo SENTRY_PROJECT=web tergo-observability-links >/dev/null'
run_zsh 'cd "$1"; source "$2/aws-context/init.zsh"; AWS_PROFILE=demo AWS_REGION=us-east-1 tergo-aws-report >/dev/null; AWS_PROFILE=demo AWS_REGION=us-east-1 tergo-aws-config-sources >/dev/null'
run_bash 'cd "$1"; source "$2/aws-context/init.bash"; AWS_PROFILE=demo AWS_REGION=us-east-1 tergo-aws-report >/dev/null; AWS_PROFILE=demo AWS_REGION=us-east-1 tergo-aws-config-sources >/dev/null'
run_zsh 'cd "$1"; source "$2/gcp-context/init.zsh"; CLOUDSDK_ACTIVE_CONFIG_NAME=demo GCLOUD_PROJECT=demo-project tergo-gcp-report >/dev/null; CLOUDSDK_ACTIVE_CONFIG_NAME=demo GCLOUD_PROJECT=demo-project tergo-gcp-config-sources >/dev/null'
run_bash 'cd "$1"; source "$2/gcp-context/init.bash"; CLOUDSDK_ACTIVE_CONFIG_NAME=demo GCLOUD_PROJECT=demo-project tergo-gcp-report >/dev/null; CLOUDSDK_ACTIVE_CONFIG_NAME=demo GCLOUD_PROJECT=demo-project tergo-gcp-config-sources >/dev/null'

printf '%s\n' 'online plugin smoke tests passed'

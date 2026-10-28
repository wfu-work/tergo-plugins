#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf '用法：%s PLUGIN_DIR [OUTPUT_DIR]\n' "$0" >&2
  exit 2
fi
plugin_dir=$1
output_dir=${2:-"$script_dir/../dist"}
"$script_dir/validate-plugin.sh" "$plugin_dir"
exec python3 "$script_dir/package_plugin.py" "$plugin_dir" "$output_dir"

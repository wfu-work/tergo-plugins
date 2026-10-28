#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
dist_dir=${1:-"$root/dist"}
base_url=${TERGO_PLUGIN_BASE_URL:-https://plugins.tergo.dev/packages}
mkdir -p "$dist_dir"
for plugin_dir in "$root"/plugins/*; do
  [ -d "$plugin_dir" ] || continue
  "$script_dir/package-plugin.sh" "$plugin_dir" "$dist_dir" >/dev/null
done
exec python3 "$script_dir/update_catalog.py" \
  --plugins-dir "$root/plugins" \
  --packages-dir "$dist_dir" \
  --output "$root/catalog/index.json" \
  --base-url "$base_url"

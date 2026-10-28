#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
site_dir=${1:-"$root/site"}
base_url=${TERGO_PLUGIN_BASE_URL:-https://wfu-work.github.io/tergo-plugins/packages}

python3 - "$site_dir" <<'PY'
from pathlib import Path
import shutil
import sys

site = Path(sys.argv[1])
if site.exists():
    shutil.rmtree(site)
site.mkdir(parents=True)
PY

TERGO_PLUGIN_BASE_URL="$base_url" "$script_dir/update-catalog.sh" "$root/dist"
mkdir -p "$site_dir/catalog" "$site_dir/packages"
cp "$root/catalog/index.json" "$site_dir/catalog/index.json"
cp "$root/dist"/*.tergo-plugin "$site_dir/packages/"
touch "$site_dir/.nojekyll"
printf 'built plugin site at %s\n' "$site_dir"

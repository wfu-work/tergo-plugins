#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -eq 0 ]; then
  set -- "$script_dir/../plugins"/*
fi
exec python3 "$script_dir/validate-plugin.py" "$@"

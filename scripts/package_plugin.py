#!/usr/bin/env python3
"""Create a bounded .tergo-plugin archive from a validated plugin folder."""

from __future__ import annotations

import hashlib
import json
import sys
import zipfile
from pathlib import Path


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(f"usage: {argv[0]} PLUGIN_DIR OUTPUT_DIR", file=sys.stderr)
        return 2
    plugin_dir = Path(argv[1]).expanduser().resolve()
    output_dir = Path(argv[2]).expanduser().resolve()
    manifest = json.loads((plugin_dir / "manifest.json").read_text(encoding="utf-8"))
    plugin_id = manifest["id"]
    version = manifest["version"]
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{plugin_id}-{version}.tergo-plugin"
    files = ["manifest.json"] + list(manifest["entry"].values())
    for optional in ("README.md", "LICENSE"):
        if (plugin_dir / optional).is_file():
            files.append(optional)
    unique_files = []
    for relative in files:
        if relative not in unique_files:
            unique_files.append(relative)
        path = (plugin_dir / relative).resolve()
        if plugin_dir not in path.parents or not path.is_file() or path.is_symlink():
            raise SystemExit(f"archive input is missing or unsafe: {relative}")
    with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in sorted(unique_files):
            data = (plugin_dir / relative).read_bytes()
            info = zipfile.ZipInfo(relative)
            info.date_time = (2026, 1, 1, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o600 << 16
            archive.writestr(info, data)
    digest = hashlib.sha256(output_path.read_bytes()).hexdigest()
    print(json.dumps({"id": plugin_id, "version": version, "path": str(output_path), "sha256": digest}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

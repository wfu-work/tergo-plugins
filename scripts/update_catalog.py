#!/usr/bin/env python3
"""Build the remote Tergo marketplace catalog from local plugin archives."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


CATEGORIES = {
    "database-workbench": "database",
    "developer-toolbox": "productivity",
    "security-scanner": "security",
    "release-workflow": "release",
    "api-workbench": "productivity",
    "ci-workflow": "release",
    "flutter-workflow": "productivity",
    "env-doctor": "environment",
    "python-workflow": "language",
    "terraform-workflow": "platform",
    "k8s-helm-release": "platform",
    "container-registry": "platform",
    "observability-readonly": "platform",
    "aws-context": "platform",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plugins-dir", required=True, type=Path)
    parser.add_argument("--packages-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--base-url", required=True)
    args = parser.parse_args()
    plugins = []
    for plugin_dir in sorted(path for path in args.plugins_dir.iterdir() if path.is_dir()):
        manifest = json.loads((plugin_dir / "manifest.json").read_text(encoding="utf-8"))
        plugin_id = manifest["id"]
        version = manifest["version"]
        package_name = f"{plugin_id}-{version}.tergo-plugin"
        package_path = args.packages_dir / package_name
        digest = hashlib.sha256(package_path.read_bytes()).hexdigest()
        commands = []
        for command in manifest.get("commands", []):
            argument_count = len(command.get("arguments", []))
            commands.append(
                {
                    "id": command["id"],
                    "name": command["name"],
                    "description": command.get("description", ""),
                    "command": command["command"],
                    "mode": command.get("mode", "execute"),
                    "risk": command.get("risk", "low"),
                    "argumentCount": argument_count,
                }
            )
        readme_path = plugin_dir / "README.md"
        readme = readme_path.read_text(encoding="utf-8")[:16000] if readme_path.is_file() else ""
        entry = {
            "id": plugin_id,
            "name": manifest["name"],
            "description": manifest.get("description", ""),
            "version": version,
            "author": "Tergo Contributors",
            "category": manifest.get("category", CATEGORIES.get(plugin_id, "utility")),
            "license": "MIT",
            "channel": "stable",
            "verified": True,
            "packageUrl": args.base_url.rstrip("/") + "/" + package_name,
            "packageSize": package_path.stat().st_size,
            "sha256": digest,
            "source": "official",
            "shells": manifest.get("shells", []),
            "capabilities": manifest.get("capabilities", []),
            "requiredCommands": manifest.get("requiredCommands", []),
            "optionalCommands": manifest.get("optionalCommands", []),
            "configSources": manifest.get("configSources", []),
            "redaction": manifest.get("redaction", {"mode": "none", "fields": []}),
            "platforms": manifest.get("platforms", []),
            "minTergoVersion": manifest.get("minTergoVersion", ""),
            "permissions": manifest.get("permissions", []),
            "surfaces": manifest.get("surfaces", []),
            "commands": commands,
            "releaseNotes": "首个公开版本。",
            "readme": readme,
            "updatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        }
        if manifest.get("healthcheck"):
            entry["healthcheck"] = manifest["healthcheck"]
        plugins.append(entry)
    catalog = {
        "version": 1,
        "updatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "plugins": plugins,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {args.output} ({len(plugins)} plugins)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Validate Tergo online plugin folders without third-party dependencies."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ID_RE = re.compile(r"^[a-z0-9][a-z0-9_.-]{1,63}$")
COMMAND_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
ARG_RE = re.compile(r"\{\{arg:([A-Za-z0-9_-]+)(?:\|([^{}]*))?\}\}")
VERSION_RE = re.compile(r"^v?[0-9]+(?:\.[0-9]+)*(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
SHELLS = {"zsh", "bash"}
PLATFORMS = {"darwin", "linux", "windows"}
PERMISSIONS = {"network", "filesystem", "process"}
SURFACES = {"command", "panel", "file-preview", "settings", "statusbar"}
MODES = {"execute", "insert"}
RISKS = {"low", "medium", "high", "critical"}
CATEGORIES = {"productivity", "database", "security", "release", "api", "ci", "language", "environment", "platform", "docs", "data"}


class ValidationError(Exception):
    pass


def fail(message: str) -> None:
    raise ValidationError(message)


def text(value: object, field: str, *, required: bool = False) -> str:
    if not isinstance(value, str):
        fail(f"{field} must be a string")
    value = value.strip()
    if required and not value:
        fail(f"{field} is required")
    return value


def validate_plugin(plugin_dir: Path) -> dict:
    if not plugin_dir.is_dir():
        fail(f"not a directory: {plugin_dir}")
    manifest_path = plugin_dir / "manifest.json"
    if not manifest_path.is_file():
        fail("manifest.json is missing")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"manifest.json is invalid: {exc}")
    if not isinstance(manifest, dict):
        fail("manifest.json must contain an object")
    if manifest.get("manifestVersion") != 1:
        fail("manifestVersion must be 1")
    plugin_id = text(manifest.get("id"), "id", required=True)
    if not ID_RE.fullmatch(plugin_id):
        fail(f"invalid id: {plugin_id}")
    text(manifest.get("name"), "name", required=True)
    version = text(manifest.get("version"), "version", required=True)
    if not VERSION_RE.fullmatch(version):
        fail(f"invalid version: {version}")
    category = text(manifest.get("category", "utility"), "category", required=True).lower()
    if category not in CATEGORIES and category != "utility":
        fail(f"unsupported category: {category}")

    shells = manifest.get("shells")
    if not isinstance(shells, list) or not shells:
        fail("shells must be a non-empty list")
    shells = {text(shell, "shell") for shell in shells}
    if not shells <= SHELLS:
        fail(f"unsupported shells: {sorted(shells - SHELLS)}")

    entry = manifest.get("entry")
    if not isinstance(entry, dict):
        fail("entry must be an object")
    if set(entry) != shells:
        fail("entry keys must match shells")
    for shell, relative in entry.items():
        relative = text(relative, f"entry.{shell}", required=True)
        candidate = (plugin_dir / relative).resolve()
        if plugin_dir.resolve() not in candidate.parents:
            fail(f"entry escapes plugin directory: {relative}")
        if not candidate.is_file() or candidate.is_symlink():
            fail(f"entry file missing or symlink: {relative}")
        if "/" in relative or "\\" in relative:
            # Nested entries are safe, but reject traversal-like spellings.
            if any(part in {".", ".."} for part in Path(relative).parts):
                fail(f"entry path contains traversal: {relative}")

    for field, allowed in (("platforms", PLATFORMS), ("permissions", PERMISSIONS), ("surfaces", SURFACES)):
        values = manifest.get(field, [])
        if not isinstance(values, list) or any(not isinstance(value, str) for value in values):
            fail(f"{field} must be a list of strings")
        unknown = {value.strip().lower().replace("_", "-") for value in values} - allowed
        if unknown:
            fail(f"unsupported {field}: {sorted(unknown)}")

    required_commands = manifest.get("requiredCommands", [])
    if not isinstance(required_commands, list) or any(not isinstance(value, str) for value in required_commands):
        fail("requiredCommands must be a list of strings")
    for command in required_commands:
        command = command.strip()
        if not COMMAND_RE.fullmatch(command):
            fail(f"invalid required command: {command}")

    healthcheck = manifest.get("healthcheck")
    if healthcheck is not None:
        if not isinstance(healthcheck, dict):
            fail("healthcheck must be an object")
        command = text(healthcheck.get("command"), "healthcheck.command", required=True)
        if not COMMAND_RE.fullmatch(command):
            fail(f"invalid healthcheck command: {command}")
        if command not in {value.strip() for value in required_commands}:
            fail("healthcheck command must be listed in requiredCommands")
        timeout = healthcheck.get("timeoutSeconds", 3)
        if not isinstance(timeout, int) or not 1 <= timeout <= 30:
            fail("healthcheck.timeoutSeconds must be between 1 and 30")
        args = healthcheck.get("args", [])
        if not isinstance(args, list) or any(not isinstance(value, str) for value in args):
            fail("healthcheck.args must be a list of strings")

    commands = manifest.get("commands", [])
    if not isinstance(commands, list):
        fail("commands must be a list")
    command_ids: set[str] = set()
    for command in commands:
        if not isinstance(command, dict):
            fail("each command must be an object")
        command_id = text(command.get("id"), "command.id", required=True)
        if not ID_RE.fullmatch(command_id) or command_id in command_ids:
            fail(f"invalid or duplicate command id: {command_id}")
        command_ids.add(command_id)
        text(command.get("name"), f"command.{command_id}.name", required=True)
        command_text = text(command.get("command"), f"command.{command_id}.command", required=True)
        mode = text(command.get("mode", "execute"), f"command.{command_id}.mode")
        risk = text(command.get("risk", "low"), f"command.{command_id}.risk")
        if mode not in MODES:
            fail(f"invalid mode for {command_id}: {mode}")
        if risk not in RISKS:
            fail(f"invalid risk for {command_id}: {risk}")
        command_shell = text(command.get("shell", ""), f"command.{command_id}.shell")
        if command_shell and command_shell not in shells:
            fail(f"command shell is not declared: {command_id}")
        arguments = command.get("arguments", [])
        if not isinstance(arguments, list):
            fail(f"arguments must be a list: {command_id}")
        declared: dict[str, dict] = {}
        for argument in arguments:
            if not isinstance(argument, dict):
                fail(f"argument must be an object: {command_id}")
            name = text(argument.get("name"), f"argument.{command_id}.name", required=True)
            if not re.fullmatch(r"^[A-Za-z0-9_-]+$", name) or name in declared:
                fail(f"invalid or duplicate argument: {command_id}/{name}")
            declared[name] = argument
        templates = list(ARG_RE.finditer(command_text))
        if "{{arg:" in command_text and sum(len(match.group(0)) for match in templates) == 0:
            fail(f"invalid argument template: {command_id}")
        for match in templates:
            if match.group(1) not in declared:
                fail(f"undeclared argument {match.group(1)}: {command_id}")

    return {"id": plugin_id, "version": version, "manifest": manifest}


def syntax_check(plugin_dir: Path, shells: set[str], entry: dict) -> None:
    for shell in sorted(shells):
        command = [shell, "-n", str(plugin_dir / entry[shell])]
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=False)
        except FileNotFoundError:
            print(f"warning: {shell} is not installed; skipped syntax check", file=sys.stderr)
            continue
        if result.returncode != 0:
            fail(f"{shell} syntax error in {entry[shell]}:\n{result.stderr.strip()}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(f"usage: {argv[0]} PLUGIN_DIR [PLUGIN_DIR ...]", file=sys.stderr)
        return 2
    failed = False
    for raw_path in argv[1:]:
        plugin_dir = Path(raw_path).expanduser().resolve()
        try:
            result = validate_plugin(plugin_dir)
            manifest = result["manifest"]
            syntax_check(plugin_dir, set(manifest["shells"]), manifest["entry"])
            print(f"ok {result['id']} {result['version']}")
        except ValidationError as exc:
            failed = True
            print(f"error {plugin_dir}: {exc}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

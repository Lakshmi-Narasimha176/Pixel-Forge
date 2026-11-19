#!/usr/bin/env python3
"""Offline, read-only QA tools for Godot and Unity projects. Python 3.9+."""
import argparse
import hashlib
import json
import os
import platform
import sys
from pathlib import Path

SKIP_DIRS = {".git", ".godot", "Library", "Temp", "obj", ".vs", "__pycache__"}
PATH_KEYS = {"path", "resource", "resource_path", "asset", "asset_path",
             "texture", "audio", "scene", "file", "filename"}


def report(title, checks, output):
    passed = sum(1 for _, ok, _ in checks if ok)
    lines = [title, f"RESULT: {'PASS' if passed == len(checks) else 'FAIL'}",
             f"CHECKS: {passed}/{len(checks)} passed", ""]
    lines += [f"[{'PASS' if ok else 'FAIL'}] {name}: {detail}"
              for name, ok, detail in checks]
    text = "\n".join(lines) + "\n"
    print(text, end="")
    if output:
        out = Path(output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    return 0 if passed == len(checks) else 1


def skipped(path):
    return any(part in SKIP_DIRS for part in path.parts)


def inspect(args):
    checks = [
        ("Python version", sys.version_info >= (3, 9), sys.version.split()[0]),
        ("Windows platform", os.name == "nt", platform.platform()),
        ("JSON module", True, "available"),
        ("Path/hash/argparse modules", True, "available"),
    ]
    return report("DEVICE 4 ENVIRONMENT CHECK", checks, args.out)


def duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON object key: {key!r}")
        result[key] = value
    return result


def walk(obj, path="$"):
    yield path, obj
    if isinstance(obj, dict):
        for key, value in obj.items():
            yield from walk(value, f"{path}.{key}")
    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            yield from walk(value, f"{path}[{index}]")


def find_json_files(source):
    path = Path(source)
    if path.is_file():
        return [path] if path.suffix.lower() == ".json" else []
    if path.is_dir():
        return sorted(p for p in path.rglob("*.json")
                      if p.is_file() and not skipped(p))
    return []


def validate_json(args):
    files = find_json_files(args.input)
    if not files:
        return report("CONTENT JSON VALIDATION",
                      [("JSON input found", False, f"no JSON files at {args.input}")],
                      args.out)
    checks, seen = [], {}
    for file in files:
        try:
            data = json.loads(file.read_text(encoding="utf-8-sig"),
                              object_pairs_hook=duplicate_keys)
            checks.append((f"JSON syntax: {file}", True, "valid UTF-8 JSON"))
            if args.id_field:
                for location, obj in walk(data):
                    if isinstance(obj, dict) and args.id_field in obj:
                        ident = str(obj[args.id_field])
                        if ident in seen:
                            checks.append((f"Unique {args.id_field}: {file}:{location}",
                                           False, f"{ident!r} also appears at {seen[ident]}"))
                        else:
                            seen[ident] = f"{file}:{location}"
                            checks.append((f"Unique {args.id_field}: {file}:{location}",
                                           True, ident))
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
            checks.append((f"JSON syntax: {file}", False, str(exc)))
    return report("CONTENT JSON VALIDATION", checks, args.out)


def audit_assets(args):
    base = Path(args.project).resolve()
    if not base.is_dir():
        return report("ASSET AND RESOURCE AUDIT",
                      [("Project directory", False, str(base))], args.out)
    checks, hashes = [], {}
    files = sorted(p for p in base.rglob("*")
                   if p.is_file() and not skipped(p.relative_to(base)))
    for path in files:
        try:
            digest = hashlib.sha256()
            with path.open("rb") as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    digest.update(chunk)
            key = digest.hexdigest()
            relative = str(path.relative_to(base))
            if key in hashes:
                checks.append((f"Duplicate file: {relative}", False,
                               f"byte-identical to {hashes[key]}"))
            else:
                hashes[key] = relative
        except OSError as exc:
            checks.append((f"Readable file: {path}", False, str(exc)))

    for jf in find_json_files(base):
        try:
            data = json.loads(jf.read_text(encoding="utf-8-sig"),
                              object_pairs_hook=duplicate_keys)
            for location, obj in walk(data):
                if not isinstance(obj, dict):
                    continue
                for key, value in obj.items():
                    if key.lower() not in PATH_KEYS or not isinstance(value, str) or not value.strip():
                        continue
                    raw = value.strip().replace("\\", "/")
                    if raw.startswith(("http://", "https://", "uid://")):
                        continue
                    if raw.startswith("res://"):
                        raw = raw[6:]
                    candidate = (base / raw).resolve()
                    try:
                        candidate.relative_to(base)
                        exists = candidate.exists()
                    except ValueError:
                        exists = False
                    checks.append((f"Resource path: {jf.relative_to(base)}:{location}.{key}",
                                   exists, value if exists else f"missing/outside project: {value}"))
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
            checks.append((f"Readable JSON: {jf.relative_to(base)}", False, str(exc)))
    if not checks:
        checks.append(("Project files scanned", True, "no eligible files found"))
    return report("ASSET AND RESOURCE AUDIT", checks, args.out)


def audit_project(args):
    base = Path(args.project).resolve()
    if not base.is_dir():
        return report("PROJECT COMPLETENESS AUDIT",
                      [("Project directory exists", False, str(base))], args.out)
    godot = (base / "project.godot").is_file()
    unity_version = (base / "ProjectSettings" / "ProjectVersion.txt").is_file()
    unity_assets = (base / "Assets").is_dir()
    unity = unity_version and unity_assets
    checks = [("Project directory exists", True, str(base))]
    if godot:
        checks += [("Engine detected: Godot", True, "project.godot found"),
                   ("Godot configuration", True, "project.godot present")]
        for folder in ("scenes", "scripts", "assets"):
            present = (base / folder).is_dir()
            checks.append((f"Optional Godot folder: {folder}", True,
                           "present" if present else "not present (not required)"))
    if unity:
        checks += [("Engine detected: Unity", True, "Unity project markers found"),
                   ("Unity ProjectSettings", True, "ProjectSettings/ProjectVersion.txt found"),
                   ("Unity Assets folder", True, "Assets/ found")]
        manifest = (base / "Packages" / "manifest.json").is_file()
        checks.append(("Unity package manifest", True,
                       "present" if manifest else "not present (optional)"))
    if not godot and not unity:
        checks.append(("Supported game engine detected", False,
                       "expected project.godot OR ProjectSettings/ProjectVersion.txt plus Assets/"))
    elif godot and unity:
        checks.append(("Project type", True, "hybrid/multi-engine directory detected"))
    else:
        checks.append(("Project type", True, "Godot" if godot else "Unity"))
    return report("PROJECT COMPLETENESS AUDIT", checks, args.out)


def build_parser():
    parser = argparse.ArgumentParser(
        description="Offline, read-only QA tools for Godot and Unity projects.")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("inspect", help="check Python and operating environment")
    p.add_argument("--out", default="reports/environment.txt")
    p.set_defaults(fn=inspect)

    p = sub.add_parser("validate-json", help="validate JSON and optional unique IDs")
    p.add_argument("input", help="JSON file or directory")
    p.add_argument("--id-field", default="", help="optional unique ID key, e.g. id")
    p.add_argument("--out", default="reports/content-validation.txt")
    p.set_defaults(fn=validate_json)

    p = sub.add_parser("audit-assets", help="find duplicate files and missing JSON paths")
    p.add_argument("project", help="game project root")
    p.add_argument("--out", default="reports/asset-audit.txt")
    p.set_defaults(fn=audit_assets)

    p = sub.add_parser("audit-project", help="detect Godot or Unity project markers")
    p.add_argument("project", help="game project root")
    p.add_argument("--out", default="reports/project-audit.txt")
    p.set_defaults(fn=audit_project)
    return parser


def main():
    args = build_parser().parse_args()
    return args.fn(args)


if __name__ == "__main__":
    raise SystemExit(main())

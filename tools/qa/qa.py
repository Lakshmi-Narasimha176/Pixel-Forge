#!/usr/bin/env python3
"""Read-only offline QA tools for THE LAST REVENGE. Python 3.9+."""
import argparse, hashlib, json, os, platform, sys
from pathlib import Path

def report(title, checks, output):
    passed = sum(1 for _, ok, _ in checks if ok)
    lines = [f"{title}", f"RESULT: {'PASS' if passed == len(checks) else 'FAIL'}",
             f"CHECKS: {passed}/{len(checks)} passed", ""]
    for name, ok, detail in checks:
        lines.append(f"[{'PASS' if ok else 'FAIL'}] {name}: {detail}")
    text = "\n".join(lines) + "\n"
    print(text, end="")
    if output:
        Path(output).parent.mkdir(parents=True, exist_ok=True)
        Path(output).write_text(text, encoding="utf-8")
    return 0 if passed == len(checks) else 1

def inspect(args):
    checks = [
        ("Python version", sys.version_info >= (3, 9), sys.version.split()[0]),
        ("Platform", os.name == "nt", platform.platform()),
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
        for k, v in obj.items():
            yield from walk(v, f"{path}.{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from walk(v, f"{path}[{i}]")

def validate_json(args):
    checks, seen_ids = [], {}
    files = sorted(Path(args.input).rglob("*.json")) if Path(args.input).is_dir() else [Path(args.input)]
    if not files or any(not p.is_file() for p in files):
        return report("CONTENT JSON VALIDATION", [("Input files found", False, args.input)], args.out)
    for file in files:
        try:
            data = json.loads(file.read_text(encoding="utf-8-sig"), object_pairs_hook=duplicate_keys)
            checks.append((f"JSON syntax: {file}", True, "valid UTF-8 JSON"))
            if args.id_field:
                for location, value in walk(data):
                    if isinstance(value, dict) and args.id_field in value:
                        ident = str(value[args.id_field])
                        if ident in seen_ids:
                            checks.append((f"Unique {args.id_field}: {file}:{location}", False,
                                           f"{ident!r} also in {seen_ids[ident]}"))
                        else:
                            seen_ids[ident] = f"{file}:{location}"
                            checks.append((f"Unique {args.id_field}: {file}:{location}", True, ident))
        except Exception as e:
            checks.append((f"JSON syntax: {file}", False, str(e)))
    return report("CONTENT JSON VALIDATION", checks, args.out)

def audit_assets(args):
    base = Path(args.project).resolve()
    checks, hashes, missing = [], {}, []
    if not base.is_dir():
        return report("ASSET AUDIT", [("Project directory", False, str(base))], args.out)
    for p in sorted(base.rglob("*")):
        if not p.is_file() or any(x in {".git", ".godot"} for x in p.parts):
            continue
        try:
            h = hashlib.sha256()
            with p.open("rb") as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    h.update(chunk)
            digest = h.hexdigest()
            if digest in hashes:
                checks.append((f"Duplicate asset: {p.relative_to(base)}", False,
                               f"identical to {hashes[digest]}"))
            else:
                hashes[digest] = str(p.relative_to(base))
        except OSError as e:
            checks.append((f"Readable file: {p}", False, str(e)))
    # Check explicitly named resource/path fields in JSON. Relative paths resolve from project root.
    path_keys = {"path", "resource", "resource_path", "asset", "asset_path", "texture", "audio", "scene"}
    for jf in base.rglob("*.json"):
        if any(x in {".git", ".godot"} for x in jf.parts):
            continue
        try:
            data = json.loads(jf.read_text(encoding="utf-8-sig"), object_pairs_hook=duplicate_keys)
            for loc, obj in walk(data):
                if isinstance(obj, dict):
                    for key, val in obj.items():
                        if key.lower() in path_keys and isinstance(val, str) and val.strip():
                            candidate = (base / val.replace("res://", "")).resolve()
                            try:
                                candidate.relative_to(base)
                                exists = candidate.exists()
                            except ValueError:
                                exists = False
                            checks.append((f"Resource path {jf.name}:{loc}.{key}", exists,
                                           val if exists else f"missing/outside project: {val}"))
        except Exception as e:
            checks.append((f"Readable JSON: {jf}", False, str(e)))
    if not checks:
        checks.append(("Project files scanned", True, "no eligible files found"))
    return report("ASSET AND RESOURCE AUDIT", checks, args.out)

def audit_project(args):
    base = Path(args.project)
    required = ["project.godot", "scenes", "scripts", "assets", "docs"]
    checks = [("Project directory exists", base.is_dir(), str(base))]
    for item in required:
        p = base / item
        checks.append((f"Required item: {item}", p.exists(), "present" if p.exists() else "missing"))
    return report("PROJECT COMPLETENESS AUDIT", checks, args.out)

def main():
    parser = argparse.ArgumentParser(description="Read-only QA tools; no project files are modified.")
    sub = parser.add_subparsers(dest="command", required=True)
    for name, fn in [("inspect", inspect)]:
        p = sub.add_parser(name); p.add_argument("--out", default="reports/environment.txt"); p.set_defaults(fn=fn)
    p = sub.add_parser("validate-json")
    p.add_argument("input", help="JSON file or directory containing JSON files")
    p.add_argument("--id-field", default="", help="Optional unique ID key, e.g. id")
    p.add_argument("--out", default="reports/content-validation.txt"); p.set_defaults(fn=validate_json)
    p = sub.add_parser("audit-assets")
    p.add_argument("project"); p.add_argument("--out", default="reports/asset-audit.txt"); p.set_defaults(fn=audit_assets)
    p = sub.add_parser("audit-project")
    p.add_argument("project"); p.add_argument("--out", default="reports/project-audit.txt"); p.set_defaults(fn=audit_project)
    args = parser.parse_args()
    return args.fn(args)

if __name__ == "__main__":
    raise SystemExit(main())

# THE LAST REVENGE — Device 4 QA package

Offline, read-only QA utilities. Python standard library only. No network, runtime AI, background process, or third-party package.

## Requirements
- Python 3.9 or newer recommended.
- Windows PowerShell.
- Godot 4 project directory.

## Inspect local Python
```powershell
python --version
py --version
where.exe python
python tools\qa\qa.py inspect
```

## Run against the project
From the directory containing `project.godot`:
```powershell
python tools\qa\qa.py validate-json .\story --out .\reports\content-validation.txt
python tools\qa\qa.py validate-json .\story --id-field id --out .\reports\content-validation.txt
python tools\qa\qa.py audit-assets . --out .\reports\asset-audit.txt
python tools\qa\qa.py audit-project . --out .\reports\project-audit.txt
```
Change `.\story` to the actual Device 3 JSON folder. Run commands from the project root, or use absolute paths.

## Input/output contract
- `validate-json INPUT`: INPUT is one `.json` file or a directory recursively containing `.json` files. UTF-8/UTF-8-BOM JSON is accepted. Duplicate object keys fail. `--id-field id` optionally checks uniqueness of that key in objects.
- `audit-assets PROJECT`: scans files for byte-identical duplicates using SHA-256 and checks common JSON resource/path keys (`path`, `resource`, `resource_path`, `asset`, `asset_path`, `texture`, `audio`, `scene`). Relative paths are resolved from project root. Adjust key names only after Device 3 confirms its schema.
- `audit-project PROJECT`: checks baseline Godot project items. Edit the required list in `qa.py` to match the agreed project structure.
- Every command prints a plain-text PASS/FAIL report and writes it to `--out`. Exit code `0` means all checks passed; `1` means at least one check failed.
- These are static checks, not proof that scenes run correctly. Verify progression in Godot using `docs/TEST_CHECKLIST.md`.

## Safety
The scripts only read project files and write reports to the selected report path. They do not alter scenes, scripts, assets, or story JSON. Do not point `--out` at a source file.

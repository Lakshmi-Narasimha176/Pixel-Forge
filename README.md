# THE LAST REVENGE — Device 4 QA package

Offline, read-only QA utilities for Godot and Unity. Python standard library only.
No network access, runtime AI, background process, or third-party package.

## Requirements
- Python 3.9 or newer.
- Windows PowerShell.
- A Godot or Unity project folder for project audits.

## Verify the QA tool
```powershell
python --version
python tools\qa\qa.py inspect
python tools\qa\qa.py --help
```

## Commands
Run from the repository root. Replace `GAME_PROJECT` and `STORY_FOLDER`
with the actual paths supplied by the game/story developers.

```powershell
python tools\qa\qa.py validate-json STORY_FOLDER --id-field id --out reports\content-validation.txt
python tools\qa\qa.py audit-assets GAME_PROJECT --out reports\asset-audit.txt
python tools\qa\qa.py audit-project GAME_PROJECT --out reports\project-audit.txt
```

## Command behavior
- `inspect`: checks Python version, Windows platform and standard-library availability.
- `validate-json INPUT`: validates one JSON file or all JSON files in a directory. Duplicate object keys fail. `--id-field id` optionally checks ID uniqueness across scanned files.
- `audit-assets PROJECT`: finds byte-identical files using SHA-256 in 1 MB chunks and checks common resource-path fields in JSON. Common cache and version-control folders are skipped.
- `audit-project PROJECT`: detects Godot using `project.godot`, or Unity using `ProjectSettings/ProjectVersion.txt` and `Assets/`. Godot `scenes`, `scripts`, and `assets` folders are informational, not mandatory.

## Reports and exit codes
Each command prints a plain-text PASS/FAIL report and writes it to `--out`.
Exit code `0` means all checks passed; `1` means at least one check failed.

## Safety and limitations
- Source project files are read only; reports are written only to the selected output path.
- Do not point `--out` at a source file.
- JSON resource paths are checked relative to the project root. Confirm Device 3's actual schema before relying on these checks.
- Unity GUID references and engine-specific binary resource formats are not resolved.
- Static checks do not prove scenes run or gameplay progression works. Use `docs/TEST_CHECKLIST.md` for manual playtesting.

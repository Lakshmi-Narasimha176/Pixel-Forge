# THE LAST REVENGE — Device 3 Story Package

This is a standalone narrative-data package. It does not contain or modify Device 1, Device 2, or Device 4 project files.

## Contents
- `data/characters/characters.json`
- `data/dialogue/dialogue.json`
- `data/clues/clues.json`
- `data/puzzles/puzzles.json`
- `data/story/story.json`
- `DATA_SCHEMA.md`
- `INTEGRATION_DEVICE1.md`
- `tools/validate_story.py`

## Validate
From this folder, run:

```powershell
python tools/validate_story.py
```

Expected successful output begins with `PASS: 5 JSON files parsed`.

Only Python's standard library is used. No internet or third-party packages are required.

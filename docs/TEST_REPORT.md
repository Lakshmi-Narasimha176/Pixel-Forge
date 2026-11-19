# TEST REPORT — THE LAST REVENGE (GODOT 4.x)

**Date:** 2026-11-19  
**Target Engine:** Godot 4.2+ (`gl_compatibility`)  
**Host Environment:** macOS (Godot executable **not installed**; runtime execution tests marked `NOT RUN`)

---

## 1. Automated & Static Checks Executed

| Check | Command / Method | Result | Notes |
|---|---|---|---|
| JSON Validation | `python3 tools/qa/qa.py validate-json data --id-field id --out reports/content-validation.txt` | **PASS** | Validated `levels.json`, `puzzles.json`, `characters.json`, `dialogue.json`, `lore_clues.json` with unique IDs. |
| Asset & Path Audit | `python3 tools/qa/qa.py audit-assets data --out reports/asset-audit.txt` | **PASS** | No duplicate files or broken JSON resource paths in `data/`. |
| Project Marker Audit | `python3 tools/qa/qa.py audit-project . --out reports/project-audit.txt` | **PASS** (7/7 checks) | `project.godot` detected; `scenes/`, `scripts/`, `assets/` verified. |
| `res://` Reference Integrity | Python scan of `project.godot`, `autoload/*.gd`, `scripts/**/*.gd`, `scenes/**/*.tscn` | **PASS** (0 missing paths) | Every script, scene, and `.glb` reference in root project exists on disk. |

---

## 2. Godot Runtime Tests (NOT RUN — Godot Binary Absent)

Because Godot is not installed on this macOS machine (`GODOT_NOT_FOUND`), the following runtime tests could not be executed locally and must be run on a machine with Godot 4.2+ installed:

- **Project Import & Script Parsing:** `NOT RUN`
- **Main Menu (`main_menu.tscn`) — New Game / Continue / Settings / Quit:** `NOT RUN`
- **Player Controller (WASD, Mouse Look, Jump, Sprint, Crouch, Collision):** `NOT RUN`
- **Flashlight Toggle (`F`) & Battery Drain/Flicker:** `NOT RUN`
- **Interaction Raycast (`E`) — Pickups, Notes, Switches, Doors:** `NOT RUN`
- **Combat (`LMB`), Enemy AI (Patrol/Chase/Attack/Die) & Bosses:** `NOT RUN`
- **Player Health, Blood Bag (`Q`), Death & Resurrection at Checkpoint:** `NOT RUN`
- **Objectives & 5-Level Progression (`level_01` -> `level_05` -> `ending_screen`):** `NOT RUN`
- **Save/Load (`user://savegame.json`) & Pause Menu (`Esc`):** `NOT RUN`
- **Windows Export (`build/windows/TheLastRevenge.exe`):** `NOT RUN` (requires Godot 4.2+ Windows export templates)

---

## 3. Known Issues & Hardware Notes

- **4 GB RAM Protection:** Root `.glb` files exceeding 30 MB (`weathered_red_saltbox_farmhouse.glb` 159 MB, `butcher_meat_hook_rail...glb` 116 MB, `cursed_porcelain_doll...glb` 106 MB, `tunnel.glb` 96 MB) are excluded from Godot level scenes to prevent out-of-memory crashes on 4 GB RAM Windows PCs.
- **Godot Installation Required for Final `.exe`:** Install Godot 4.2+ Standard and Windows Desktop Export Templates to export `build/windows/TheLastRevenge.exe` using `export_presets.cfg`.

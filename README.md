# THE LAST REVENGE (Godot 4.x — Compatibility Renderer)

**Theme:** THE UNKNOWN  
**Genre:** First-Person Supernatural Horror Adventure  
**Target Platform:** Windows PC (4 GB RAM, Compatibility Renderer, Offline-First)

---

## Running & Exporting in Godot 4.x

1. Install **Godot 4.2+** (Standard edition, GDScript).
2. Open Godot Project Manager -> **Import** -> select `project.godot` at the repository root.
3. Press **F5** to launch from `res://scenes/ui/main_menu.tscn`.
4. **Windows `.exe` Export:**
   - In Godot: **Editor -> Manage Export Templates -> Download and Install** for your Godot 4.x version.
   - Go to **Project -> Export...**, select **Windows Desktop** (`export_presets.cfg`), and export to `build/windows/TheLastRevenge.exe`.

---

## Controls

| Key / Input | Action |
|---|---|
| **W, A, S, D** | Move |
| **Mouse** | Look around |
| **Shift** | Sprint |
| **C** | Toggle Crouch |
| **Space** | Jump |
| **E** | Interact (pick up items, read clues, flip switches, open doors) |
| **F** | Toggle Flashlight |
| **Left Mouse** | Melee Attack (once Baseball Bat is equipped) |
| **Q** | Use Blood Bag (+35 HP) |
| **Esc** | Pause Menu (Resume, Restart Checkpoint, Save, Main Menu) |

---

## Five Connected Levels

1. **Level 1 — The Awakening (`scenes/levels/level_01/level_01.tscn`)**: Wake in the foggy abandoned settlement, pick up the walkie-talkie, discover you are dead, read the Dark Tome for the **Resurrection Rule**, and unlock the Settlement Gate.
2. **Level 2 — The Butcher (`scenes/levels/level_02/level_02.tscn`)**: Equip the bloodied baseball bat, gather shipment evidence, defeat **The Butcher**, and take the Bunker Keycard.
3. **Level 3 — The Strategist (`scenes/levels/level_03/level_03.tscn`)**: Flip both breaker switches to disable corridor shock traps, recover the betrayal dossier, and defeat **The Strategist**.
4. **Level 4 — The Impossible Return (`scenes/levels/level_04/level_04.tscn`)**: Discover the **Resurrection Loophole** in the distorted afterlife and align all 3 Soul Anchors.
5. **Level 5 — The Betrayer (`scenes/levels/level_05/level_05.tscn`)**: Examine your dead friend's memory and confession, defeat **The Betrayer**, and step into the Dawn Sanctuary (`scenes/ui/ending_screen.tscn`).

---

## Documentation & QA

- `docs/PROJECT_LAYOUT.md` — repository map and rules for preserving original assets.
- `docs/PROJECT_AUDIT.md` — Initial repository, asset size, and hardware audit.
- `docs/PROGRESS.md` — Development log.
- `docs/TEST_REPORT.md` — Static QA checks and runtime test status.
- Offline QA check:
  ```bash
  python3 tools/qa/qa.py validate-json data --id-field id --out reports/content-validation.txt
  python3 tools/qa/qa.py audit-project . --out reports/project-audit.txt
  ```

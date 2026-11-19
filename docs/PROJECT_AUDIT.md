# PROJECT AUDIT — THE LAST REVENGE

**Date:** 2026-11-19  
**Target Platform:** Windows PC (4 GB RAM target, 8 GB development)  
**Engine:** Godot 4.7.2.stable.official (macOS host / Windows PC target)  
**Renderer:** GL Compatibility (`gl_compatibility`) — optimized for 4 GB RAM  
**Git Branch:** `main` (commit `9a21276`, synchronized with `origin/main`)

---

## 1. Project Structure & Environment

- **Root Directory:** `/Users/malikarjunr/Pixel-Forge`
- **Godot Executable:** `/Users/malikarjunr/Downloads/Godot.app/Contents/MacOS/Godot` (v4.7.2.stable)
- **QA Tool:** `tools/qa/qa.py` (offline read-only audit utilities for JSON, assets, and project validation)
- **Modular PSX Kit:** `PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/Godot/` containing modular wall, door, floor, ceiling, and anomaly meshes, shaders, and materials.
- **GLB Asset Library:** 28 binary 3D assets in root (characters, weapons, props, environments) fully pulled via Git LFS.

---

## 2. Existing Assets & Usability Assessment

| Asset Category | File Path | Size | Status / Usability for 4 GB RAM |
|---|---|---|---|
| **Characters** | `horror_butcher_fat_killer_bloody_cleaver.glb` | 31 MB | High quality boss model (Level 2 Butcher) |
| | `horror_ghost_character_-_blood_stained_spirit.glb` | 7.0 MB | Excellent supernatural enemy / apparition |
| | `jeson_horror_fan_art.glb` | 5.6 MB | Stalker enemy model (Level 3 Strategist) |
| | `horror_woman.glb` | 2.2 MB | Paranormal apparition (Level 4 Impossible Return) |
| | `a_horror_girl_character.glb` | 8.3 MB | Atmospheric horror entity |
| | `street_rat.glb` | 4.7 MB | Ambient prop / enemy |
| **Weapons & Tools** | `baseball_bat_covered_in_blood.glb` | 1.8 MB | Primary melee weapon |
| | `horror_game_flashlight_download_game-ready.glb` | 2.0 MB | First-person flashlight prop |
| | `psx-style_horror_walkie-talkie.glb` | 28 KB | Lightweight narrative comms device |
| **Puzzles & Props** | `devils_bible_-_dark_fantasy_book.glb` | 2.7 MB | Resurrection lore / occult puzzle item |
| | `vintage_wooden_wall_clock_-.glb` | 2.0 MB | Clockwork puzzle mechanism |
| | `blood_bag.glb` | 2.5 MB | Consumable health pickup |
| | `cursed_porcelain_doll_-_antique_horror_prop.glb` | 106 MB | High-res prop (use sparingly) |
| | `dead_pig.glb` | 3.1 MB | Slaughterhouse prop |
| | `psx_raw_meat_pack__low-poly_2_types.glb` | 327 KB | Highly optimized horror props |
| | `butcher_meat_hook_rail_-_cured_ham__sausages.glb` | 116 MB | High-res environment asset (use optimized LOD) |
| **Environments** | `horror_soviet_room.glb` | 316 KB | Extremely lightweight bunker environment |
| | `horror_corridor_5.glb` | 6.7 MB | Ideal corridor level connector |
| | `horror_room.glb` | 30 MB | Level 1 starting awakening chamber |
| | `tunnel.glb` | 96 MB | Level 5 escape tunnel |
| | `weathered_red_saltbox_farmhouse.glb` | 159 MB | Exterior sanctuary (Level 5 climax) |
| | `old_wooden_toilet_house_2.glb` | 3.7 MB | Exterior puzzle outhouse |
| | `PSX Modular Kit Meshes` | ~50 KB/ea | 17 ultra-low-poly pieces (floors, walls, ceilings, doors) |

---

## 3. Working Features

- Git repository is clean and tracking `main`.
- All binary assets pulled and verified via Git LFS.
- Godot 4.7.2 engine successfully verified and able to run headlessly without crashes.
- Device 4 QA environment verified (`tools/qa/qa.py`).
- PSX shaders (`psx_lit.gdshader`, `psx_lit_blend.gdshader`) compiled and working in Compatibility renderer.

---

## 4. Broken / Missing Features

- **Root `project.godot`:** Missing at the repository root. Existing `project.godot` was located only inside subfolder `PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/Godot`.
- **Game Architecture Structure:** The target architecture (`scenes/`, `scripts/`, `autoload/`, `data/`) is missing at root.
- **Gameplay Systems:**
  - First-person player with raycast interaction and melee combat.
  - Flashlight with battery and flicker.
  - Resurrection system (loophole mechanic across 5 levels).
  - Reusable Enemy AI (Butcher, Strategist, Betrayer).
  - Objective manager and persistence.
  - Reusable puzzle interfaces (switches, keys, codes, evidence).
  - Full UI: Main menu, pause menu, settings, HUD, death/resurrection screens.
  - 5 connected levels (`level_01` to `level_05`).
  - Narrative and puzzle JSON in `res://data/`.

---

## 5. Implementation Strategy & Hardware Risk Mitigation

1. **Target Hardware (4 GB RAM / Compatibility Renderer):**
   - Keep draw calls low; avoid instantiating multiple 100MB+ models in the same scene.
   - Utilize the ultra-lightweight PSX modular kit for architecture and room structures, placing key narrative props strategically.
   - Set texture compression and disable unnecessary dynamic shadow casters (limit max lights per object).
2. **Resurrection System:**
   - Central autoload (`GameManager` / `ResurrectionManager`) tracking death count, active checkpoint, narrative knowledge flags (The Rule in L1, The Loophole in L4, The Payoff in L5).
3. **Execution Plan:**
   - P0: Core Godot project setup, player controller, raycast interaction, flashlight, health, melee combat, Level 1.
   - P1: Autoloads (`GameManager`, `ObjectiveManager`, `SaveSystem`), 5 levels, enemy AI bosses (Butcher, Strategist, Betrayer), puzzles, UI.
   - P2: Data JSON integration (`data/story/`, `data/puzzles/`), audio synthesis/stings, polish, automated QA verification.

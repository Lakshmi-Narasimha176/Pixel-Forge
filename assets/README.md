# LONG LASTING REVENGE

A single-player, third-person action-horror campaign built with Godot 4 and GDScript. Explore a dead world, fight the Butcher and the Strategist, uncover why your friend killed you, and decide what to do with the truth.

## Run

1. Open the repository's `project.godot` in Godot 4.7.2 (or a compatible Godot 4 release).
2. Let Godot import the included assets, then press **F6** to play the current scene or **F5** to launch the main menu.
3. Choose **New Game**. The opening story cards can be skipped with any key or mouse click.

The project is offline-first. It makes no network requests and all story, save, audio and gameplay data are local. The Windows export preset is `export_presets.cfg`; install matching Godot export templates before exporting.

## Controls

| Input | Action |
|---|---|
| W / A / S / D | Move relative to the camera |
| Mouse | Look |
| Right mouse | Aim |
| Left mouse | Fire or melee attack |
| Shift | Sprint |
| Ctrl | Run |
| C | Crouch |
| Space | Jump |
| E | Interact, pick up, or read |
| R | Reload |
| 1 / 2 / 3, Tab, mouse wheel up | Select or cycle weapons |
| F | Toggle flashlight |
| Q | Use a blood bag |
| V | Last Chance (available below 31 health; 40-second cooldown) |
| J | Open journal and discovered-region map |
| Esc | Pause, or close the journal |

## Campaign

The five compact, connected-by-story zones cover the 12 story beats in the design brief: the betrayal prologue and dead settlement; the Butcher's territory; the Strategist's bunker; the Ledger and resurrection loophole; and the Memory Labyrinth and final confrontation. Evidence is kept in the **J** journal. After the confrontation, choose revenge, release your friend, or break the Ledger.

## Performance and saves

The project uses Godot's Compatibility renderer, simple low-poly character meshes, limited scene lights with shadows off, short view distance, 60 FPS cap, and a small audio loop generated once at startup. These choices reduce GPU and CPU load and work offline. They do not guarantee a specific frame rate or memory use on every low-end PC; the project has not yet been measured on the target range of hardware.

Save data is stored locally by Godot under `user://` (the platform's application-data folder). Checkpoints, collected evidence, weapons/ammo, puzzle states, visited regions and story flags are saved.

## Validation

With Godot 4.7.2 installed, run the scene smoke check from PowerShell:

```powershell
& "$env:USERPROFILE\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path . --scene res://tools/qa/scene_validator.tscn
```

Run the JSON checks with:

```powershell
python tools/qa/qa.py validate-json data --id-field id --out reports/content-validation.txt
```

The smoke check enters the menu, all five levels, and the ending in the actual engine. A Windows executable has not been exported or launch-tested yet.

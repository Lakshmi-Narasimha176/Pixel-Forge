# Test report — LONG LASTING REVENGE

**Date:** 2026-11-20  
**Engine:** Godot 4.7.2 stable, Windows x64  
**Renderer:** GL Compatibility  
**Offline mode:** No network calls are used by the game.

## Checks run

| Check | Result | Notes |
|---|---|---|
| Godot editor scan | PASS | Project and GDScript class scan completed. |
| Headless scene smoke check | PASS | 15 game/support scenes loaded and entered `_ready()` with the campaign autoloads active. |
| Content JSON validation | PASS | 48/48 checks. |
| Godot project audit | PASS | 7/7 checks. |
| Windows export | NOT RUN | Matching export templates were not present in the local Godot data folder. |
| Full manual playthrough | NOT RUN | Movement, combat balance, story progression and endings still need an interactive playtest. |
| Low-end performance benchmark | NOT RUN | No frame-time, RAM, thermal or battery measurements have been taken on target PCs. |

Headless scene command:

```powershell
& "$env:USERPROFILE\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path . --scene res://tools/qa/scene_validator.tscn
```

The scene smoke check confirms startup and node initialization. It does not simulate player input or prove that a complete campaign can be finished without manual testing.

## Known limits

- Five discrete, connected-by-story zones represent the larger dead world; this is not a seamless open world.
- Four weapon families are implemented: pistol, rifle, shotgun and melee bat. Additional weapons in the design brief remain future work.
- Enemy movement uses direct steering with line-of-sight checks, not NavigationServer pathfinding; enemies may get stuck on complex geometry.
- Visuals use existing environment assets plus a procedural low-poly player. Full character animation, cinematics, broad sound libraries and input remapping are not implemented.
- Compatibility rendering and low-cost settings are configured for modest hardware, but performance and battery life depend on the specific device and remain unmeasured.
- The export preset is configured, but no executable has been exported or launch-tested.

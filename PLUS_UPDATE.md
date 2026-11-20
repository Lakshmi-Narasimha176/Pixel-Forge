# Plus update (horror/main_plus.gd)

`horror/main.tscn` now loads `horror/main_plus.gd`, which **extends** the original `horror/main.gd` (untouched).
To go back, point `main.tscn` at `res://horror/main.gd` again.

## Why the path was blocked
Furniture sat directly in front of four doors:
| Door | Blocker | Fix |
|---|---|---|
| Kitchen door (x=22,z=5) | kitchen island | moved east |
| Foyer door (x=14,z=7) | foyer table | moved to x=16.2 |
| Study -> kitchen door (x=19,z=2) | east bookcase | moved to z=3.9 |
| Living room door (x=6,z=7) | couch | moved west |

The run also started with `yaw = PI`, facing away from the house. Now `yaw = 0`.
A startup validator prints `[PathCheck]` lines in the Output panel and lists any door lane still blocked.

## Gameplay
- Rooms start dark. Flip a wall switch ON -> whole house shorts out -> reset the outside main breaker.
- Main breaker box is on the outside wall beside the tunnel-side entrance, red/green lamp.
- Wall switches sit on real walls (they floated mid-room before); study + foyer added.
- +3 blood bags, +2 raw meat, blood-tear doll, bath and corridor lights.
- Floating blood-wall slabs inside rooms removed; 17 blood decals on the walls instead.

## Sound
Ghost whisper (Ada), mourning hum (Mira), Lily giggle, rat scurry, hook chain, bathroom drip, wind at the tunnel,
power hum at breaker, clock tick-tock + chime, door-close thud, switch click, breaker clunk, bat hit, hurt grunt,
pickup / blood-bag squish, walkie static near Lily, random house events. Synth fallback for each; recorded files
from assets/audio are used when they load.

## Not verified
Written without running Godot. Press play and check Output for parse errors and [PathCheck] lines.

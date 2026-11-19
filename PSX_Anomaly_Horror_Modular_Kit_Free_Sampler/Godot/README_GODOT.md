# PSX Anomaly Horror Modular Kit - Godot 4.3 project (free sampler)

bitkiln - https://bitkiln.itch.io - Retro game assets, fired in the kiln.

Open `project.godot` with Godot 4.3 or newer and press F5: an anomaly loop in the Hollis house, built only from
kit pieces. Tab opens the showcase with every piece of this project.

## Controls

- WASD / arrows walk, mouse look (click into the window), Shift run, F flashlight, Esc free the mouse
- R new run (loop), H help, Tab loop / showcase
- Showcase: F walk / fly, E / Q up / down, K every anomaly pair on / off, L name labels

## What is inside

| folder | what |
|---|---|
| `psx_anomaly_horror_modular_kit/meshlibs/<Theme>.meshlib` | one MeshLibrary per theme for GridMap: mesh, collision and preview of every piece |
| `psx_anomaly_horror_modular_kit/meshes/`, `psx_anomaly_horror_modular_kit/shapes/` | the mesh and the collider of every piece (the MeshLibraries and the anomaly scenes use them) |
| `psx_anomaly_horror_modular_kit/materials/`, `psx_anomaly_horror_modular_kit/textures/` | one material per piece slot (PSX shader; soft glass and grime alpha blended) |
| `psx_anomaly_horror_modular_kit/anomaly/<name>.tscn` | a ready anomaly scene for every pair (AnomalyPiece) |
| `psx_anomaly_horror_modular_kit/anomaly_piece.gd` | AnomalyPiece: texture pairs, mesh pairs, companions, moved / turned / dark |
| `anomaly/` | AnomalySwap + AnomalyManager of the PSX Anomaly Horror Texture Pack (unchanged) |
| `shaders/` | the PSX shader of the series (vertex snapping, affine textures, 15-bit color) |
| `demo/` | loop_house.tscn (the anomaly loop), showcase.tscn, the player and the scripts |

| MeshLibrary | items |
|---|---|
| res://psx_anomaly_horror_modular_kit/meshlibs/House.meshlib | 17 (ids 0..16) |

17 MeshLibrary items: 10 pieces + 7 anomaly versions (7 anomaly pairs).

## GridMap setup

- Cell Size (2, 3, 2), Center X and Z on, Center Y off. One GridMap per theme and layer (floors, ceilings,
  walls, details, stairs): a cell holds one item per GridMap, so walls on two edges of a cell, a door and
  a corner post go into a second GridMap of the same layer (the demo names them House_Walls, House_Walls2 ...).
- Edge pieces (walls, doors, windows) sit on the north edge of their cell; turn them in 90 degree steps
  (Godot orthogonal indices 0, 16, 10, 22 = north, west, south, east). Corner posts sit on the north-east
  corner. Stairs climb north from the origin cell over two cells.
- Every item has its collision inside the MeshLibrary (stairs: a smooth ramp; ceilings: none).
- Street: houses stand 0.6 m above the yard (porch steps, deck skirt). Put the yard, the sidewalk and the road in
  a second set of GridMaps moved to y = -0.6 (the street template calls them Street_*_Yard).

## Materials and textures

- Every material uses the PSX shader: opaque and cut-out surfaces shaders/psx_lit(_double_sided).gdshader,
  soft alpha (store glass, drapes, grime and decal overlays of the anomaly pieces) shaders/psx_lit_blend.gdshader,
  the same vertex snapping drawn 2 cm towards the camera (view_bias), so an overlay 3-5 mm in front of a
  wall never sinks behind the snapping wall.
- psx_anomaly_horror_modular_kit/textures/fluorescent_flicker_strip.png and fog_ground_strip.png are 8-frame strips (frames side by side)
  of the flicker tube and the ground fog: the materials show frame 0, play the strip for the animation.
- store_wall_tile is mapped at 2 m per texture repeat (25 cm tiles).

## Anomalies that open a passage

haunt_maze_dead_end (a real doorway) and farm_barn_wall_door (the doors slide open) open a dark passage: their
anomaly scenes carry an invisible wall 0.6 m behind the opening, so the player cannot walk out of the level.
Put a dark room or a wall behind them anyway if the player can look far in.

## Anomaly pairs

An anomaly piece cannot live in a GridMap (GridMap items do not change at run time). Put the ready scene
`psx_anomaly_horror_modular_kit/anomaly/<name>.tscn` where the normal piece would go (same origin, same rotation, cell origin = cell
center at floor height: x = 2 * cell_x + 1, y = 3 * story, z = 2 * cell_z + 1). Its AnomalyPiece adds
AnomalySwap nodes, so one AnomalyManager in the level finds it with every other anomaly of the series:

```gdscript
var wall = load("res://psx_anomaly_horror_modular_kit/anomaly/house_wall_floral.tscn").instantiate()
wall.position = Vector3(5, 0, -3)
wall.rotation_degrees.y = 90
add_child(wall)
wall.set_anomaly(true)      # the anomaly version (texture or model, with its collision)
```

- Texture pairs swap the material of the changed surface; mesh pairs hide the model and show the anomaly
  model (the collision follows).
- `companions`: nodes that leave with the anomaly. When the anomaly of house_wall_door closes the opening,
  the door leaf in it must go too: put the leaf in the level as its own node (not in the GridMap) and add
  its path to the wall's companions (the demo does this).
- `difficulty` easy / medium / hard: hard ones come less often (weight x 0.6). `weight` changes one piece.
- Moved, turned or dark: any piece can be an anomaly (`anomaly_offset`, `anomaly_rotation_deg`,
  `anomaly_light_off`).
- Each loop: `manager.submit_choice(turned_back)` then `manager.start_loop()`; demo/loop_house.gd is a
  complete loop to copy from (a seamless move between two S-shaped passages, the counter, the messages).

## Together with the other packs of the series

The Texture Pack, Monsters, Props and this kit ship the same `anomaly/` folder (AnomalySwap, AnomalyManager)
and the same `shaders/`. In a project that already has one of them, keep its `anomaly/` and `shaders/`
(the texture pack's anomaly_pairs.gd lists its texture pairs; this one is empty) and copy only `psx_anomaly_horror_modular_kit/` of
this kit. One AnomalyManager then picks props, monsters, textures and kit pieces alike.

## Import settings

Textures import lossless, without mipmaps, with nearest filtering (the PSX look). Copy the
[importer_defaults] block of project.godot into your own project.godot before you add the kit.

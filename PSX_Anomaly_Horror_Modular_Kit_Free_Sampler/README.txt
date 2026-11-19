PSX ANOMALY HORROR MODULAR KIT - FREE SAMPLER
by bitkiln  -  https://bitkiln.itch.io
Retro game assets, fired in the kiln.

10 pieces and 7 anomaly pairs from the PSX Anomaly Horror Modular Kit: the loop hallway of the Hollis house,
free for personal and commercial projects (see LICENSE.txt), in the same formats as the full kit, with a Godot
4.3 project that has a playable anomaly loop built from these pieces.

THE FULL KIT: 226 pieces in 5 themes (house, street, store, farm, haunt) and 67 anomaly pairs.
Get it at https://bitkiln.itch.io/psx-anomaly-horror-modular-kit and thank you for trying the sampler!

CONTENTS (counted by the build)
- 10 pieces in 1 theme, 1,272 triangles (8 to 378 per piece)
- 7 anomaly pairs (3 change the model, 4 only a texture); 2 easy, 2 medium, 3 hard
- every piece and anomaly version as GLB (textures inside) and as OBJ + MTL, textures at 128 px per meter
  (Textures/) and a 64 px set (Textures_64/)
- Godot 4.3 project: one MeshLibrary per theme (collision + previews), a ready anomaly scene for every pair,
  a playable anomaly loop built from kit pieces and a showcase of every piece (K flips every pair)
- Catalog: piece list (CSV + Markdown), a contact sheet per theme and a sheet of every anomaly pair
- Unity/AnomalySwap.cs: texture and mesh pairs in Unity

THE GRID
- 1 unit = 1 meter, +Y up. One cell = 2 x 2 m, one story = 3 m (Godot GridMap: Cell Size (2, 3, 2), Center X
  and Z on, Center Y off).
- Piece origin = center of the cell floor. Multi-cell pieces (cells "2x1") extend to +X and to -Z from the
  origin cell; stairs climb towards -Z, origin at the center of the bottom cell.
- Edge pieces (walls, doors, windows, fences, railings) sit on the NORTH edge of their cell: center line
  z = -1, 0.2 m thick, the +Z face looks into the cell. Turn them in 90 degree steps for the other edges.
- Corner posts sit on the north-east corner and close the joints where walls meet.
- Floors are quads at y = 0, ceilings quads at y = 3 facing down; wall tops sit 5 mm under 3 m, so the
  floor of the story above never flickers. Openings: door 1.0 x 2.2 m, double door 1.6 x 2.2 m, window
  1.0 x 1.2 m (sill 0.9 m), doorway 1.6 x 2.4 m. Door, window and leaf pieces fit the matching wall.
- Textures tile at their real size (128 px = 1 m), so neighboring pieces continue without seams.

THEMES
  HOUSE (10 pieces, 7 anomaly pairs): the loop hallway of the Hollis house: floor, ceiling, ceiling light,
  walls, a door wall with its door, a window wall with its window, corner post.

PIECES (size = width x height x depth in meters; "> ANOMALY" = the anomaly version of the piece above)

HOUSE  (Models: GLB/House/, OBJ/House/)
  house_floor                  2.00 x 0.00 x 2.00    Oak plank floor, 2 x 2 m floor tile at y = 0.
                                                   > ANOMALY house_floor_anomaly [hard, changed model]: bare footprints walk across the middle of the
                                                   oak floor and back
  house_ceiling                2.00 x 0.00 x 2.00    Popcorn ceiling, 2 x 2 m quad at y = 3 facing down.
  house_ceiling_light          2.00 x 0.79 x 2.00    Popcorn ceiling with a rose, cord and bare glowing bulb (emissive).
                                                   > ANOMALY house_ceiling_light_anomaly [medium, changed model]: the hanging bulb is frozen
                                                   mid-swing, its cord slanted
  house_wall                   2.00 x 3.00 x 0.26    House wall, 2 m: faded striped wallpaper over a 1 m oak wainscot, oak baseboard, chair rail and
                                                     white crown molding.
                                                   > ANOMALY house_wall_anomaly [hard]: eyes have opened among the sprigs of the striped wallpaper
  house_wall_door              2.00 x 3.00 x 0.26    House wall with a cased 1.0 x 2.2 m door opening and door stops; fits house_door (its anomaly
                                                     closes the opening: hide the door leaf standing in it (house_door / house_door_oak ...)).
                                                   > ANOMALY house_wall_door_anomaly [easy, changed model]: the door to the next room is gone: plain
                                                   wall where the doorway was
  house_wall_window            2.00 x 3.00 x 0.29    House wall with a cased 1.0 x 1.2 m window opening (sill at 0.9 m) and sills; fits house_window.
  house_corner                 0.27 x 3.00 x 0.27    Corner post 0.21 x 0.21 x 3 m on the cell corner (x +1, z -1) closing outer wall corners; same
                                                     finish as house_wall.
  house_door                   0.96 x 2.18 x 0.05    Closed white six-panel interior door (leaf 0.96 x 2.18 m) sitting in house_wall_door; origin at
                                                     the cell center.
                                                   > ANOMALY house_door_anomaly [easy]: deep scratch marks run down the white door
  house_window                 1.00 x 1.20 x 0.04    Night window with lace curtains and the moon outside, both faces textured; fills the 1.0 x 1.2 m
                                                     opening of house_wall_window.
                                                   > ANOMALY house_window_anomaly [hard]: a pale face looks in from behind the curtain
  house_wall_floral            2.00 x 3.00 x 0.26    House wall, 2 m: faded floral vine wallpaper over a 1 m oak wainscot, oak baseboard, chair rail
                                                     and white crown molding.
                                                   > ANOMALY house_wall_floral_anomaly [medium]: pale curled hands have grown among the wallpaper
                                                   vines

ANOMALY PAIRS (7)
Same place, one wrong detail. Name of the anomaly version = the piece it belongs to + an anomaly name (the
catalog column "anomaly_of" links them). Difficulty = how hard it is to notice from 3-5 m in a dark game:
easy ones read from the doorway, hard ones need a second look.
  house_wall_floral    [medium, texture] pale curled hands have grown among the wallpaper vines
  house_wall_door      [easy, model] the door to the next room is gone: plain wall where the doorway was
  house_wall           [hard, texture] eyes have opened among the sprigs of the striped wallpaper
  house_floor          [hard, model] bare footprints walk across the middle of the oak floor and back
  house_ceiling_light  [medium, model] the hanging bulb is frozen mid-swing, its cord slanted
  house_door           [easy, texture] deep scratch marks run down the white door
  house_window         [hard, texture] a pale face looks in from behind the curtain

ANOMALY PAIRS: HOW TO USE THEM
- A good anomaly game shows either nothing wrong or exactly one anomaly per loop. Start the player with a
  normal loop so they learn the place.
- Texture pairs (most): the anomaly version has the same mesh and UVs; only the material of one slot
  differs (Catalog/pieces.csv, column "anomaly_slots": material = anomaly texture). Swap that material or
  that texture and the world has changed at no cost.
- Model pairs ("changed model"): hide the piece and show its anomaly version at the same position and
  rotation. Some need a companion to go with them: a wall whose opening closes needs the door leaf in it
  hidden too (house_wall_door, mart_storefront_door).
- GODOT: put psx_anomaly_horror_modular_kit/anomaly/<name>.tscn where the normal piece would go: its
  AnomalyPiece swaps the material or the model (and the collision) and joins the AnomalyManager of the
  series. "companions" lists the nodes that leave with the anomaly. See Godot/README_GODOT.md.
- UNITY: Unity/AnomalySwap.cs swaps one piece: texture swaps by exact material name through a
  MaterialPropertyBlock, model pairs and companions with SetActive. Import with glTFast (GLB) or as OBJ.
  It is the swap only: the loop rules (one anomaly or none per loop, the counter) are your game code; the
  Godot AnomalyManager is a complete example to port.
- UNREAL: make a Material Instance per texture (normal / anomaly) and call Set Material on the element of
  the changed slot; for model pairs place both meshes and toggle their visibility and collision.
- BLENDER: import both GLBs (File > Import > glTF 2.0) and toggle the collections, or swap the image of the
  changed material.

FORMATS
- GLB (glTF 2.0 binary): one file per piece with the textures inside and a nearest sampler. GLB/_Kits/ has
  every piece of a theme in one file (handy in Blender).
- OBJ + MTL: the same mesh, normals and UVs; the MTL points to ../../Textures/ (map_Kd, map_Ke for glowing
  parts, map_d for cut-outs). Keep the folders as they are.
- Textures are the PSX Anomaly Horror Texture Pack textures at the same names and scale, plus 5 kit-only
  textures cut from them (kit_*: white trim, aluminum, store glass, warm bulb + its glow map).
  store_wall_tile is mapped at 2 m per repeat (25 cm tiles).
- Animated surfaces show frame 0 (<name>_0.png); <name>_strip.png next to it holds the 8 frames side by
  side (the flickering fluorescent tube, the ground fog) for engines that play strips.
- Glowing parts (bulbs, lit windows, signs, exit signs, fridge lights) have an emission map: they glow on
  their own but do not light the scene, add a light next to them.
- Cut-outs (corn, picket fence, hedge, caution tape, clock) use alpha mask with cutoff 0.5, double-sided.
  Soft alpha (store glass, drapes, grime decals) uses alpha blending, double-sided.
- Collision: build it from the meshes; for corn maze walls a box on the edge (0.56 x 2.4 x 2 m) works better
  than the thin cards, for stairs a ramp. The Godot MeshLibraries come with colliders.

GODOT 4 (4.3 or newer)
1. Open Godot/project.godot and press F5: an anomaly loop in the hallway of the Hollis house, built only
   from these pieces. Walk down the hallway; if something is wrong, turn back, if not, keep going. Reach
   loop 8 to get out. Tab opens the showcase with every piece (K flips every pair).
     WASD / arrows walk   mouse look (click)   Shift run   F flashlight   R new run   H help   Esc mouse
2. Your own project: copy Godot/psx_anomaly_horror_modular_kit/, Godot/anomaly/ and Godot/shaders/ into
   it and the [importer_defaults] block of Godot/project.godot into your project.godot.
3. Add a GridMap, set its Mesh Library to psx_anomaly_horror_modular_kit/meshlibs/<Theme>.meshlib, Cell
   Size (2, 3, 2), Center Y off, and paint. Use one GridMap per layer (floors, ceilings, walls, details):
   a cell holds one item per GridMap. Anomaly pieces go in as their anomaly scenes, not in the GridMap.
4. The PSX look (vertex snapping, affine textures, 15-bit color) is in every kit material, the soft alpha ones
   too (shaders/psx_lit_blend.gdshader); shaders/apply_psx.gd converts other materials of your scene.

UNITY
- Import the GLB files with glTFast, or the OBJ folders. 1 unit = 1 meter. Texture import: Filter Mode Point,
  Compression None, no mipmaps for the full look. Snap the pieces with a 2 m grid (Edit > Grid and Snap).

UNREAL ENGINE
- Import GLB (Unreal 5 glTF importer, converts meters) or OBJ with uniform scale 100. Texture filter
  Nearest, no compression, no mipmaps; grid snapping 200 units.

BLENDER
- File > Import > glTF 2.0: meshes, textures and materials come in with Closest interpolation.
- File > Import > Wavefront (.obj) also works (forward -Z, up Y); then set the Image Texture node of each
  material to Closest (OBJ textures import as Linear).

WORKS WITH THE PSX ANOMALY HORROR TEXTURE PACK, MONSTERS AND PROPS
Same world (Hallow Creek: the Hollis house at 27 Wren Lane, LATELIGHT MART, PELLHAM FARM, THE GRIM ACRE), the
same textures at the same scale and the same AnomalyManager: in Godot the four packs ship the same anomaly/
folder (anomaly_swap.gd, anomaly_manager.gd) and the same shaders/. In a project that already has one of
them, keep its anomaly/ and shaders/ and copy only Godot/psx_anomaly_horror_modular_kit/: one manager then
picks texture swaps, monsters, props and kit pieces alike.

LICENSE
See LICENSE.txt. Short version: use the pieces in any personal or commercial project, but do not resell or
redistribute the models or textures themselves. Credit is appreciated but not required: "Art by bitkiln".

CONTACT
Questions, problems or piece requests: comment on the itch.io page (https://bitkiln.itch.io)
or write to @bitkiln_assets on X. Thank you for supporting a small creator!

# Repository layout and asset safety

The repository contains a Godot game, a browser game, and a vendor sampler. Keep their boundaries clear:

| Path | Purpose | Asset rule |
|---|---|---|
| `project.godot` | Primary Godot project entry point | Open this project for the five-level campaign. |
| `scenes/`, `scripts/`, `autoload/`, `data/` | Godot game code, scenes, and story data | Keep authored code in these existing folders. |
| Repository-root `*.glb` and texture files | Canonical source models/textures used by Godot | Preserve original filenames and bytes. Scenes refer to them with `res://` paths. |
| `assets/audio/` | Canonical audio source library | Preserve this source folder; Godot's `AudioManager` loads from it. |
| `game/` | Separate browser/WebGL game | `game/public/` links back to canonical root assets; do not replace those links with edited exports. |
| `PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/` | Vendor-provided sampler project and assets | Keep it separate from the main game and preserve its contents. |
| `docs/`, `reports/`, `tools/` | Project documentation, QA output, and utilities | Add project notes and checks here. |

## Safe asset changes

- Do not move, rename, overwrite, recompress, or delete the original models, textures, audio, or sampler files as part of ordinary code cleanup.
- Keep Godot `.import` sidecars beside their source assets; Godot uses them to preserve import settings and resource identity.
- Keep Git LFS enabled for the binary extensions in `.gitattributes`.
- Before changing an asset link, verify its target resolves to the canonical repository asset. The web game's audio link is relative so it no longer depends on one developer's absolute home-directory path.
- If a future migration truly needs new asset paths, update every Godot scene and browser-game reference first, compare source hashes before/after, then retain the originals until the new build is verified.

The layout guide is intentionally non-destructive: this change updates documentation and one path-only link, not any original asset bytes.

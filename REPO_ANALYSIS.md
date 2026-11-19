# Pixel-Forge analysis (read via GitHub API, commit 93af404)

Three parallel implementations of "The Last Revenge":
1. Godot single-scene game (main.gd, gallery.gd, project.godot) - most complete: key -> Devil's Bible -> escape, AI Butcher (patrol/investigate/search/chase), apparitions.
2. Godot five-level game (scripts/, scenes/, data/) - what README.md describes, but project.godot does not point at it.
3. Three.js web game (game/, Vite + three 0.160).

Problems
- Godot project cannot launch: project.godot, main.tscn, gallery.tscn, main.gd and gallery.gd all reference res://horror/..., but no horror/ folder exists (files are at the repo root).
- README.md says main scene is scenes/ui/main_menu.tscn; project.godot says horror/main.tscn. GODOT_GAME.md also describes horror/.
- .glb files are Git LFS pointers (~132 bytes); run `git lfs pull` or the game shows placeholder boxes.
- Clutter committed: .DS_Store, placeholder .rar files, godot-horror-game.bundle.

Suggested next steps: pick one implementation as canonical, update README to match, remove clutter, add an export_presets.cfg.

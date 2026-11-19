# What this zip contains
- apply_fixes.py - patches your local clone (tested only on a synthetic stub, NOT in Godot)
- docs/REPO_ANALYSIS.md - the analysis

## Use
    git clone git@github.com:Lakshmi-Narasimha176/Pixel-Forge.git
    git lfs pull
    git checkout -b upgrade/fix-paths-and-gameplay
    python3 apply_fixes.py ./Pixel-Forge
    # open in Godot 4.3+, press F5, then:
    git add -A && git commit -m "Fix res://horror paths; stamina lockout, run timer, footsteps" && git push -u origin HEAD

## Changes
1. "res://horror/" -> "res://" in project.godot, main.tscn, gallery.tscn, main.gd, gallery.gd (fixes launch).
2. Stamina lockout: once stamina hits 0 you can't sprint until it recovers to 25%.
3. Run timer; best time saved to user://last_revenge.cfg; shown on win/death screens.
4. Butcher footsteps fire once per stride (old condition almost never triggered).
If main.gd differs from the version analysed, the script aborts without writing anything.

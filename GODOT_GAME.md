# THE LAST REVENGE - Godot 4.3 horror game

Open this folder in **Godot 4.3+** and press **F5**. Run `git lfs pull` first so the `.glb` files are real
(without it they are tiny LFS stubs; the game shows a warning and uses placeholder boxes).
The first open imports ~800 MB of models, so give it a few minutes.

No existing asset was changed or moved. New files only: `project.godot`, `horror/`, this file, and a few `.gitignore` lines.

## Play
Find the brass key -> unlock the slaughter room -> take the Devil's Bible -> escape by the front door.
WASD move, Shift run (loud), C crouch (quiet), F flashlight, E interact, Esc pause, G asset gallery.
The Butcher hunts by sight (light makes you visible) and by sound.

## Characters (static meshes, animated by code in real time)
Butcher (AI patrol / investigate / search / chase), Horror girl (moves only when unseen), Cursed doll (watches you),
Ghost (drifts), Woman (appears at the end of the hall), Street rat (scurries).
Environment: kit house pieces (walls, doors that swing, windows, ceiling lights with flicker), pigs, meat, clock,
spinning fan, blood wall, volumetric fog + flashlight shadows.

## Gallery (`G` from the menu)
Every character, prop and environment GLB in the repo, turning on pedestals, with a free-fly camera.

## Not included
Mixamo animations need an Adobe login, so rigged animation was not added; the repo's characters have no skeleton.

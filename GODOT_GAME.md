# Godot Game Notes

## Run

Open this repository's `project.godot` in Godot 4.3 or newer and press **F5**. The main scene is `res://horror/main.tscn`. Run `git lfs pull` before opening so the GLB assets are downloaded; without them, the game reports the missing models.

## Game loop

Nora begins in the underground tunnel outside the Hollis house. Find a bloody baseball bat, contact her younger sister Ada through the walkie-talkie, defeat the translucent Horror Girl Lily to get Abel Crane's slaughterhouse key, and collect Mira's corridor key near the west hall entrance. Search the slaughterhouse for the Devil's Bible, then return to the tunnel to escape. The barred front door is not an alternate exit.

## Controls

- **WASD / mouse:** move and look
- **Shift / C:** sprint loudly / crouch quietly
- **F:** flashlight
- **E:** interact, open doors, collect items, and use switches
- **R:** contact Ada after collecting the walkie-talkie
- **Q:** use a collected blood bag (+35 health)
- **Left mouse / T:** swing the bloody bat; it frees spirits, kills the rat, and stuns the Butcher
- **Esc:** pause
- **G:** open the asset gallery from the menu

## Systems

Room lights start on and have individual switches. Turning a room light on shorts the whole-house circuit; the foyer's master breaker restores it. Main power changes make Lily flicker into view. Battery pickups recharge the flashlight. Raw meat restores a smaller amount of health than a blood bag.

The house includes a furnished vintage living room, Mira's horror corridor, a bathroom outhouse, a slaughterhouse meat-hook rail and blood-splashed walls, a crying porcelain doll, a squeaking rusted ceiling fan, a ticking wall clock, a biting street rat, and spatial sound cues. The HUD lists the main and optional missions.

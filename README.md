# 🩸 THE LAST REVENGE — First-Person Horror Game

A realistic 3D psychological survival horror game built with **Three.js**, **WebGL**, **GLSL Shaders**, and the **Web Audio API**.

---

## 🎮 Play the Game

### Quick Start
```bash
# Navigate to the game directory
cd game

# Install dependencies (first time only)
npm install

# Start the local development server
npm run dev
```

Then open the local URL in your browser (e.g. `http://localhost:5173/`).

### Production Build
```bash
cd game
npm run build
npm run preview
```

---

## 🕹️ Controls

| Key / Action | Action |
|---|---|
| **W, A, S, D** | Walk Forward / Left / Backward / Right |
| **Mouse** | Look around (Pointer Lock) |
| **Shift** | Sprint (consumes stamina, increases footstep volume) |
| **C** | Crouch (silent movement, sneak past stalkers) |
| **E** | Interact (pick up items, open doors, examine puzzles) |
| **F** | Toggle Flashlight (consumes battery over time) |
| **Q** | Use Blood Bag (Restores +25 HP) |
| **1 - 5** | Quick-select Inventory Slots |
| **Esc** | Pause Game / Settings Menu |

---

## 📖 Story & Chapters

You wake up trapped in a decrepit, blood-soaked asylum and meat facility. A static voice crackles through a walkie-talkie: *"Get out... before HE finds you."*

### Chapter 1: The Awakening
- Wake in the dark starting room (`horror_room.glb`).
- Discover the flashlight and crackling walkie-talkie.
- Beware the cursed porcelain doll (`cursed_porcelain_doll_-_antique_horror_prop.glb`) whose head tracks your every movement.

### Chapter 2: The Corridor
- Navigate the long decaying hallway (`horror_corridor_5.glb`).
- Encounter the wandering spirit (`horror_ghost_character_-_blood_stained_spirit.glb`).
- Arm yourself with the blood-stained baseball bat (`baseball_bat_covered_in_blood.glb`).
- Watch out for scurrying street rats and sudden corridor apparitions.

### Chapter 3: The Slaughterhouse
- Enter the meat processing plant (`butcher_meat_hook_rail_-_cured_ham__sausages.glb`, `dead_pig.glb`, `psx_raw_meat_pack__low-poly_2_types.glb`).
- Evade **The Butcher** (`horror_butcher_fat_killer_bloody_cleaver.glb`), a lethal stalker who patrols with a massive meat cleaver.
- Sneak to locate the electronic Security Keycard and scavenge Blood Bags for survival.

### Chapter 4: The Soviet Facility
- Penetrate the Cold War interrogation bunker (`horror_soviet_room.glb`).
- Survive psychological apparitions of the Horror Woman (`horror_woman.glb`) causing intense VHS static distortions.
- Solve the antique clock riddle (`vintage_wooden_wall_clock_-.glb`) to unlock the secret subterranean blast doors.

### Chapter 5: The Escape
- Sprint through the crumbling collapse tunnel (`tunnel.glb`) under emergency strobe lights.
- Break through into the night storm to reach the weathered farmhouse sanctuary (`weathered_red_saltbox_farmhouse.glb`).

---

## ⚙️ Architecture & Engine Features

- **Custom GLSL Post-Processing Pipeline** (`Renderer.js`):
  - Dynamic CRT scanlines and film grain.
  - Deep vignette darkening edges.
  - Cold, desaturated horror color grading.
  - Chromatic aberration spike filter triggered during jump scares.
- **Dynamic Horror Lighting** (`LightingSystem.js`):
  - Directional camera flashlight with real-time shadow casting, battery drain, and intermittent flicker.
  - Flickering fluorescent tube and blood-red meat light simulations.
  - Volumetric exponential distance fog (`FogExp2`).
- **Positional 3D Audio Engine** (`AudioManager.js`):
  - Synthesized impulse responses for claustrophobic indoor reverb.
  - Distance-based enemy footstep and breath tracking.
  - Heartbeat audio cues scaling dynamically with player health and sanity.
- **Sanity & Fear System** (`HorrorEffects.js`):
  - Sanity depletion in pitch darkness or near paranormal anomalies.
  - Screen shake, distortion, and blood splatter overlays upon taking damage.
- **Complete UI System** (`HUD.js`, `MenuSystem.js`):
  - Horror typography and aesthetic styling.
  - Health bar, battery indicator, sanity meter, subtitle narration, and death/victory screens.

---

## 🛠️ QA Utilities (Device 4 Package)

```powershell
# Verify QA environment
python tools\qa\qa.py inspect

# Content and asset validation
python tools\qa\qa.py validate-json data --id-field id --out reports\content-validation.txt
python tools\qa\qa.py audit-assets data --out reports\asset-audit.txt
```

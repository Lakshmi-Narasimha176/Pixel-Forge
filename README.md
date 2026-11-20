# THE LAST REVENGE 🩸

> *"In the rotting halls of the Hollis estate, an unspeakable sacrifice bound a family between life and damnation."*

[![Engine](https://img.shields.io/badge/Engine-Godot%204.7.2-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Web-brightgreen)](https://orvexgames-49f8a.web.app)
[![Genre](https://img.shields.io/badge/Genre-Psychological%20Survival%20Horror-crimson)](#story--mythology)
[![Live Web Game](https://img.shields.io/badge/Play%20Online-Firebase%20Hosting-FFCA28?logo=firebase&logoColor=black)](https://orvexgames-49f8a.web.app)

**THE LAST REVENGE** is a first-person supernatural survival-horror game developed in Godot 4.7.2 from the high-fidelity Pixel-Forge 3D asset collection. You play as **Nora Crane**, returning through an underground tunnel into her cursed family homestead to confront her corrupted father, banish vengeful apparitions, comfort weeping souls, and break the dark ritual bound to the **Devil's Bible**.

---

## 🎮 Play the Game

- **Web Browser (Official Live)**: [https://orvexgames-49f8a.web.app](https://orvexgames-49f8a.web.app)  
  *(Mirror: [https://orvexgames-49f8a.firebaseapp.com](https://orvexgames-49f8a.firebaseapp.com))*
- **Itch.io Package**: Ready-to-upload bundle at `build/TheLastRevenge_itch.zip` for [itch.io](https://itch.io/game/new).
- **Native Local Launch (Fastest / 0s Loading)**:
  Open this repository in **Godot 4.7.2** and press **F5** (or run `project.godot`).

---

## 📜 Story & Mythology

```
                       ┌───────────────────────────────┐
                       │       THE DEVIL'S BIBLE       │
                       │ (Ancient Occult Relic/Altar)  │
                       └──────────────┬────────────────┘
                                      │ Binds & Corrupts
            ┌─────────────────────────┼─────────────────────────┐
            ▼                         ▼                         ▼
    ABEL CRANE (Father)       MIRA CRANE (Wife)         ADA CRANE (Sister)
   "The Brutal Butcher"      "Horror Corridor Ghost"   "Blood-Stained Spirit"
   [Slaughterhouse Lair]     [Lavender Key / Halls]    [Vintage Living Room]
            │                         ▲                         │
            │ Locked Key              │ Guided by Radio         │ Speaks via Walkie
            ▼                         │                         ▼
     LILY (Horror Girl)  ◄────────────┴─────────────►  NORA (Player / Human)
   Flickers in & out                            Arrives via Underground Tunnel
   4 Bites Kill (-25 HP each)                   Must find Bloody Baseball Bat
```

### The Characters & Roles
- **Abel Crane (Father / The Butcher)**: Nora's father who fell under the dark influence of the Devil's Bible, turning the eastern house wing into a blood-drenched slaughterhouse. Confined behind locked iron-grate doors until provoked.
- **Ada Crane (Younger Sister / Blood-Stained Spirit)**: Trapped in the vintage living room. Unable to leave the room, she communicates through the **Walkie-Talkie**, warning Nora of threats and guiding her through the mansion.
- **Mira Crane (The Woman / Butcher's Wife)**: Tormented spirit haunting the blood-soaked horror corridors. Her lavender-scented key unlocks her secluded wing.
- **Lily (The Horror Girl Apparition)**: An ethereal apparition that flickers between transparent and solid forms. She stalks Nora from the entry halls. Each ghostly bite tears away **25 HP** — **exactly 4 bites will kill the human**. She holds Father's Brass Slaughterhouse Key.
- **Pearl (The Cursed Porcelain Doll)**: Sits weeping and crying on the bedroom cabinet. Returning her lost childhood crayon drawing comforts her spirit and silences her sorrow.
- **The Street Rat**: A plague-ridden vermin scurrying across floorboards, biting ankles (-5 HP) and startling the player in dark corners.

---

## 🕹️ Controls

| Key | Action |
| :--- | :--- |
| **W, A, S, D** | Move Nora |
| **Mouse** | First-Person Look |
| **Shift** | Sprint *(Consumes stamina; footstep noise alerts the Butcher)* |
| **C** | Crouch *(Silent movement; essential when near Father's room)* |
| **F** | Toggle Flashlight |
| **E** | Interact, Open/Close Doors, Pick up Items, Flip Light Switches |
| **Left Mouse / T** | Swing Bloody Baseball Bat |
| **R** | Use Walkie-Talkie *(Contact Ada for situational advice)* |
| **Q** | Use Blood Bag *(Heals severe wounds)* |
| **Enter** | Start game, resume from dialogue, advance memory pages |
| **Esc** | Pause Menu / Close reading UI |
| **F2** | Toggle Cinematic Post-Processing Shader FX |

---

## ⚙️ Core Mechanics & Technology

### 1. Electrical Grid & Short Circuit System
- **The Main Breaker**: Located outside next to the underground tunnel entrance. Restores primary electrical current to the house.
- **Short Circuits**: Individual room light switches can be toggled by the player. Flipping room switches risks triggering violent **short circuits**, blowing the main fuse and plunging the house into pitch blackness.
- **Power & Apparitions**: Darkness empowers the spirits. Every surge or power outage triggers **Lily** to manifest and stalk towards the house entry.

### 2. Combat & Defense
- **The Bloody Baseball Bat**: Nora's sole defensive tool, hidden in the Study.
- Striking **Lily** with the bat while she flickers visible releases Father's Key.
- Striking **Abel Crane (The Butcher)** staggers him, granting precious seconds to sprint to safety.

### 3. Survival Scavenging
- **Blood Bags**: Scavenged across the house; stored in inventory and activated with **`[Q]`** to heal critical wounds.
- **Raw Meat Packs**: Freshly wrapped meat slabs on kitchen tables that can be consumed for emergency health (+15 HP).
- **Batteries**: Replenishes flashlight battery life (+50%).

### 4. Atmospheric Machinery & Audio
- **Rusted Ceiling Fan**: Creaks with vintage rotational resonance in the living quarters.
- **Antique Wall Clock**: Ticks with unsettling precision in the hallway.
- **Procedural 3D Audio**: Dynamic heartbeats that accelerate as Father approaches, spatial doll weeping, rat squeaks, flesh-tearing bites, and radio static.

---

## 🗺️ Walkthrough & Objectives

1. **The Arrival**: Emerge from the **Underground Tunnel** into the stormy yard.
2. **Restore Power**: Flip the **Master Breaker** beside the tunnel entrance to illuminate the entry lanterns.
3. **Infiltrate the House**: Open the southern dining room entrance door.
4. **Arm Yourself**: Locate the **Bloody Baseball Bat** inside the Study and **Ada's Walkie-Talkie** in the Vintage Living Room.
5. **Survive Lily**: Evade Lily's deadly 4-bite attacks, time your strike with the bat when she solidifies, and collect **Father's Brass Key**.
6. **Confront the Butcher**: Unlock the **Slaughterhouse**, face Abel Crane, and seize the **Devil's Bible** from the altar beneath the hanging meat hook rails.
7. **The Escape**: Sprint back through the house and escape down the **Underground Tunnel** to seal your freedom.

### Endings
- **Escape Ending**: Retrieve the Devil's Bible and exit through the tunnel.
- **True Ending (Family Restored)**: Comfort Pearl with her drawing, free Ada and Mira with the bat, collect all 4 hidden memory pages, seize the Bible, and escape.

---

## 📂 Repository Structure

```
Pixel-Forge/
├── project.godot                  # Godot 4.7 engine configuration
├── export_presets.cfg             # Web and Desktop release presets
├── horror/
│   ├── main.tscn                  # Primary 3D horror game scene
│   ├── main.gd                    # Complete game logic, AI, mechanics & audio
│   ├── main_cinematic.gd          # Extended cinematic camera & lighting triggers
│   └── story.gd                   # Narrative lore, memories & dialogue scripts
├── build/
│   ├── web/                       # Optimized Godot Web export (HTML5 + WebAssembly)
│   └── TheLastRevenge_itch.zip    # Pre-packaged itch.io release zip
├── firebase.json                  # Firebase Hosting config with COOP/COEP headers
└── .github/workflows/
    └── deploy-pages.yml           # Continuous deployment workflow
```

---

## 📄 Credits & License

Built with **Godot Engine 4.7** using authentic PSX-style modular kits and high-fidelity 3D assets from **Pixel-Forge**.  
*For educational and entertainment purposes.*

/**
 * Level4_SovietRoom.js — 'The Soviet Room'
 * Soviet-era interrogation facility with psychological horror.
 * Horror woman apparitions, static distortion, vintage clock puzzle (3:33),
 * Jason stalker chase sequences, and creepy girl in the corner.
 * @module Level4_SovietRoom
 */

import * as THREE from 'three';

/** Asset paths relative to game/ directory */
const ASSETS = {
  sovietRoom: '/horror_soviet_room.glb',
  horrorWoman: '/horror_woman.glb',
  jasonStalker: '/jeson_horror_fan_art.glb',
  horrorGirl: '/a_horror_girl_character.glb',
  clock: '/vintage_wooden_wall_clock_-.glb',
  devilsBible: '/devils_bible_-_dark_fantasy_book.glb',
  ceilingFan: '/old_rusty_ceiling_fan.glb',
  bloodBag: '/blood_bag.glb',
  door: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_door.glb',
  wall: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_wall.glb',
  floor: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_floor.glb'
};

/**
 * EventEmitter base
 */
class LevelEventEmitter {
  constructor() { this._listeners = {}; }
  on(e, cb) { if (!this._listeners[e]) this._listeners[e] = []; this._listeners[e].push(cb); }
  off(e, cb) { if (!this._listeners[e]) return; this._listeners[e] = this._listeners[e].filter(f => f !== cb); }
  emit(e, d) { if (this._listeners[e]) this._listeners[e].forEach(cb => cb(d)); }
}

/**
 * Level 4: The Soviet Room
 * @extends LevelEventEmitter
 */
export class Level4_SovietRoom extends LevelEventEmitter {
  constructor() {
    super();

    /** @type {THREE.Scene|null} */
    this.scene = null;
    /** @type {object|null} */
    this.assetLoader = null;

    /** @type {THREE.Group} */
    this.levelGroup = new THREE.Group();
    this.levelGroup.name = 'Level4_SovietRoom';

    this.levelManager = null;
    this.playerInventory = {};

    // Entities
    this.sovietRoomModel = null;
    this.horrorWomanModel = null;
    this.jasonModel = null;
    this.girlModel = null;
    this.clockModel = null;
    this.ceilingFanModel = null;
    this.exitDoor = null;

    // Clock puzzle state
    this.clockHour = 12;
    this.clockTargetHour = 3;
    this.clockPuzzleSolved = false;
    this.secretDoorUnlocked = false;

    // Apparition timers
    this.elapsedTime = 0;
    this.womanVisible = false;
    this.womanTimer = 0;
    this.jasonChaseActive = false;
    this.jasonChaseTimer = 0;
    this.jasonSpeed = 3.6;

    // UI
    this.interactPrompt = null;
    this.subtitleDisplay = null;
    this.staticOverlay = null;

    this.interactables = [];
    this.flickerLights = [];

    this._onKeyDown = this._onKeyDown.bind(this);
  }

  async init(scene, assetLoader) {
    this.scene = scene;
    this.assetLoader = assetLoader;

    this._createUI();
    this._setupEnvironment();
    this.scene.add(this.levelGroup);

    await this._loadAssets();
    this._setupInteractables();

    document.addEventListener('keydown', this._onKeyDown);

    this.showSubtitle("LEVEL 4: SOVIET FACILITY. The wall clock is ticking backward... solve the riddle to escape.", 5000);
    console.log('[Level4] The Soviet Room initialized');
  }

  _createUI() {
    this.interactPrompt = document.createElement('div');
    this.interactPrompt.id = 'interact-prompt-l4';
    Object.assign(this.interactPrompt.style, {
      position: 'fixed', bottom: '30%', left: '50%',
      transform: 'translateX(-50%)', color: '#ffddaa',
      fontFamily: '"Courier New", monospace', fontSize: '1rem',
      padding: '8px 16px', backgroundColor: 'rgba(10,15,20,0.85)',
      border: '1px solid #aa5533', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center'
    });
    document.body.appendChild(this.interactPrompt);

    this.subtitleDisplay = document.createElement('div');
    this.subtitleDisplay.id = 'subtitle-display-l4';
    Object.assign(this.subtitleDisplay.style, {
      position: 'fixed', bottom: '15%', left: '50%',
      transform: 'translateX(-50%)', color: '#ff5533',
      fontFamily: '"Courier New", monospace', fontSize: '1.1rem',
      padding: '12px 24px', backgroundColor: 'rgba(10,10,15,0.9)',
      border: '1px solid #882211', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center',
      maxWidth: '650px', textShadow: '0 0 10px #ff3311'
    });
    document.body.appendChild(this.subtitleDisplay);

    this.staticOverlay = document.createElement('div');
    this.staticOverlay.id = 'static-overlay-l4';
    Object.assign(this.staticOverlay.style, {
      position: 'fixed', top: '0', left: '0',
      width: '100vw', height: '100vh',
      backgroundColor: 'transparent',
      backgroundImage: 'repeating-radial-gradient(circle, rgba(255,255,255,0.1) 0, rgba(0,0,0,0.4) 3px)',
      opacity: '0', pointerEvents: 'none', zIndex: '99',
      transition: 'opacity 0.15s ease'
    });
    document.body.appendChild(this.staticOverlay);
  }

  _setupEnvironment() {
    const ambientLight = new THREE.AmbientLight(0x0a1015, 0.35);
    this.levelGroup.add(ambientLight);

    // Sickly interrogation desk bulb
    const deskLight = new THREE.PointLight(0xaacc88, 1.4, 12);
    deskLight.position.set(0, 2.6, 0);
    deskLight.castShadow = true;
    this.levelGroup.add(deskLight);
    this.flickerLights.push({ light: deskLight, baseIntensity: 1.4, speed: 7 });

    // Distant cold blue light
    const hallLight = new THREE.PointLight(0x336699, 0.8, 15);
    hallLight.position.set(-6, 2.8, -8);
    this.levelGroup.add(hallLight);
    this.flickerLights.push({ light: hallLight, baseIntensity: 0.8, speed: 14 });

    // Room boundaries
    const floorGeo = new THREE.PlaneGeometry(20, 20);
    const floorMat = new THREE.MeshStandardMaterial({ color: 0x121618, roughness: 0.95 });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    this.levelGroup.add(floor);

    const ceiling = new THREE.Mesh(floorGeo, new THREE.MeshStandardMaterial({ color: 0x08090a, roughness: 1.0 }));
    ceiling.rotation.x = Math.PI / 2;
    ceiling.position.y = 3.8;
    this.levelGroup.add(ceiling);

    const wallMat = new THREE.MeshStandardMaterial({ color: 0x182024, roughness: 0.9 });
    const wallGeo = new THREE.BoxGeometry(20, 3.8, 0.4);

    const backWall = new THREE.Mesh(wallGeo, wallMat);
    backWall.position.set(0, 1.9, -10);
    this.levelGroup.add(backWall);

    const frontWall = new THREE.Mesh(wallGeo, wallMat);
    frontWall.position.set(0, 1.9, 10);
    this.levelGroup.add(frontWall);

    const leftWall = new THREE.Mesh(wallGeo, wallMat);
    leftWall.position.set(-10, 1.9, 0);
    leftWall.rotation.y = Math.PI / 2;
    this.levelGroup.add(leftWall);

    const rightWall = new THREE.Mesh(wallGeo, wallMat);
    rightWall.position.set(10, 1.9, 0);
    rightWall.rotation.y = Math.PI / 2;
    this.levelGroup.add(rightWall);
  }

  async _loadAssets() {
    const loadModel = async (name, path, pos, rot, scale) => {
      try {
        let model = null;
        if (this.assetLoader && this.assetLoader.load) {
          const gltf = await this.assetLoader.load(path);
          model = gltf.scene || gltf;
        }
        if (model) {
          model.position.copy(pos);
          if (rot) model.rotation.set(rot.x, rot.y, rot.z);
          if (scale) model.scale.set(scale, scale, scale);
          model.traverse(c => {
            if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; }
          });
          this.levelGroup.add(model);
          return model;
        }
      } catch (e) {
        console.warn(`[Level4] Fallback for ${name}:`, e);
      }
      return null;
    };

    // Soviet Room (1:1 scale, 5.31m x 2.80m x 3.89m)
    this.sovietRoomModel = await loadModel('sovietRoom', ASSETS.sovietRoom,
      new THREE.Vector3(0, 0, 0), null, 1.0);

    // Horror Woman (Apparition, 1.8m height)
    this.horrorWomanModel = await loadModel('horrorWoman', ASSETS.horrorWoman,
      new THREE.Vector3(-1.5, 0, -1.0), { x: 0, y: Math.PI / 3, z: 0 }, 0.9);
    if (this.horrorWomanModel) {
      this.horrorWomanModel.visible = false;
    } else {
      const g = new THREE.Group();
      const body = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.45, 1.7, 8), new THREE.MeshStandardMaterial({ color: 0x334444, transparent: true, opacity: 0.8 }));
      body.position.y = 0.85;
      g.add(body);
      g.position.set(-1.5, 0, -1.0);
      g.visible = false;
      this.levelGroup.add(g);
      this.horrorWomanModel = g;
    }

    // Jason Stalker (scaled to realistic 1.92m height: 0.11 * 17.47m)
    this.jasonModel = await loadModel('jasonStalker', ASSETS.jasonStalker,
      new THREE.Vector3(2.0, 0, -2.5), { x: 0, y: -Math.PI / 4, z: 0 }, 0.11);
    if (!this.jasonModel) {
      const jg = new THREE.Group();
      const jb = new THREE.Mesh(new THREE.BoxGeometry(0.7, 1.9, 0.4), new THREE.MeshStandardMaterial({ color: 0x1a261a }));
      jb.position.y = 0.95;
      jg.add(jb);
      jg.position.set(2.0, 0, -2.5);
      this.levelGroup.add(jg);
      this.jasonModel = jg;
    }

    // Horror Girl in corner (height ~1.7m)
    this.girlModel = await loadModel('horrorGirl', ASSETS.horrorGirl,
      new THREE.Vector3(-2.0, 0, 1.4), { x: 0, y: Math.PI * 0.75, z: 0 }, 0.85);
    if (!this.girlModel) {
      const gg = new THREE.Group();
      const gb = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.35, 1.3, 8), new THREE.MeshStandardMaterial({ color: 0x111111 }));
      gb.position.y = 0.65;
      gg.add(gb);
      gg.position.set(-2.0, 0, 1.4);
      this.levelGroup.add(gg);
      this.girlModel = gg;
    }

    // Vintage wall clock (The Puzzle - 51cm wall clock mounted on north wall)
    this.clockModel = await loadModel('clock', ASSETS.clock,
      new THREE.Vector3(0, 1.8, -1.9), { x: 0, y: 0, z: 0 }, 0.6);

    // Ceiling fan (1.5m diameter, mounted at ceiling 2.7m)
    this.ceilingFanModel = await loadModel('ceilingFan', ASSETS.ceilingFan,
      new THREE.Vector3(0, 2.7, 0), null, 0.9);

    // Blood Bag Health Pickup on desk
    this.bloodBagModel = await loadModel('bloodBag', ASSETS.bloodBag,
      new THREE.Vector3(-1.8, 0.7, 0.5), { x: Math.PI / 2, y: 0, z: 0.3 }, 0.01);
    if (this.bloodBagModel) {
      this.bloodBagModel.userData.interactable = true;
      this.bloodBagModel.userData.prompt = 'Take Blood Bag (+25 HP) [E]';
      this.bloodBagModel.userData.onInteract = () => {
        if (this.playerInventory.health !== undefined) {
          this.playerInventory.health = Math.min(100, (this.playerInventory.health || 75) + 25);
        }
        this.bloodBagModel.visible = false;
        this.showSubtitle('+25 HP restored from Blood Bag.', 2500);
      };
      this.interactables.push(this.bloodBagModel);
    }

    // Secret passage door on east wall
    this.exitDoor = await loadModel('door', ASSETS.door,
      new THREE.Vector3(2.55, 0, 0), { x: 0, y: -Math.PI / 2, z: 0 }, 1.0);
    if (!this.exitDoor) {
      const dm = new THREE.Mesh(new THREE.BoxGeometry(0.1, 2.4, 1.4), new THREE.MeshStandardMaterial({ color: 0x222a30 }));
      dm.position.set(2.55, 1.2, 0);
      this.levelGroup.add(dm);
      this.exitDoor = dm;
    }
  }

  _setupInteractables() {
    // Clock puzzle interaction
    if (this.clockModel) {
      this.clockModel.userData.interactable = true;
      this.clockModel.userData.prompt = 'Press E to turn Clock Hands (Currently 12:00)';
      this.clockModel.userData.onInteract = () => {
        this.clockHour = (this.clockHour % 12) + 1;
        this.clockModel.rotation.z += Math.PI / 6;

        if (this.clockHour === this.clockTargetHour) {
          this.clockPuzzleSolved = true;
          this.secretDoorUnlocked = true;
          this.emit('triggerScare', { intensity: 0.6 });
          this.showSubtitle("CHIME! The clock strikes 3:00 (The Witching Hour). The secret tunnel door unlocked!", 4500);
          if (this.exitDoor) this.exitDoor.rotation.y += Math.PI / 2;
        } else {
          this.showSubtitle(`The clock hands click to ${this.clockHour}:00... Nothing happens yet.`, 2500);
        }
      };
      this.interactables.push(this.clockModel);
    }

    // Secret door exit to Level 5
    if (this.exitDoor) {
      this.exitDoor.userData.interactable = true;
      this.exitDoor.userData.prompt = 'Press E to enter Escape Tunnel';
      this.exitDoor.userData.onInteract = () => {
        if (!this.secretDoorUnlocked) {
          this.showSubtitle('The heavy blast door is sealed shut by a clockwork mechanism.', 3000);
          return;
        }
        this.showSubtitle('Entering the escape tunnel...', 2000);
        setTimeout(() => {
          this.emit('exit');
        }, 1200);
      };
      this.interactables.push(this.exitDoor);
    }
  }

  showSubtitle(text, duration = 3000) {
    if (!this.subtitleDisplay) return;
    this.subtitleDisplay.textContent = text;
    this.subtitleDisplay.style.display = 'block';
    clearTimeout(this._subTimer);
    this._subTimer = setTimeout(() => {
      if (this.subtitleDisplay) this.subtitleDisplay.style.display = 'none';
    }, duration);
  }

  update(delta) {
    this.elapsedTime += delta;

    // Flickering interrogation lighting
    this.flickerLights.forEach((fl, idx) => {
      const flicker = Math.sin(this.elapsedTime * fl.speed + idx) * 0.35 +
                      (Math.random() - 0.5) * 0.25;
      fl.light.intensity = Math.max(0.1, fl.baseIntensity + flicker);
    });

    // Ceiling fan spin
    if (this.ceilingFanModel) {
      this.ceilingFanModel.rotation.y += delta * 2.5;
    }

    // Horror woman periodic apparition & screen static
    this.womanTimer += delta;
    if (this.womanTimer > 8.0) {
      this.womanTimer = 0;
      this.womanVisible = !this.womanVisible;
      if (this.horrorWomanModel) this.horrorWomanModel.visible = this.womanVisible;
      if (this.womanVisible) {
        if (this.staticOverlay) this.staticOverlay.style.opacity = '0.6';
        this.emit('triggerScare', { intensity: 0.5 });
      } else {
        if (this.staticOverlay) this.staticOverlay.style.opacity = '0';
      }
    }

    // Girl head-tracking player
    const cam = this.scene?.getObjectByProperty('isCamera', true);
    const playerPos = new THREE.Vector3();
    if (cam) cam.getWorldPosition(playerPos);
    else playerPos.set(0, 1.6, 1.0);

    if (this.girlModel) {
      const distToGirl = this.girlModel.position.distanceTo(playerPos);
      if (distToGirl < 6.0) {
        this.girlModel.lookAt(playerPos.x, this.girlModel.position.y, playerPos.z);
      }
    }

    // Jason stalker stalking
    if (this.jasonModel && this.clockPuzzleSolved) {
      const dist = this.jasonModel.position.distanceTo(playerPos);
      if (dist < 10.0) {
        const dir = new THREE.Vector3().subVectors(playerPos, this.jasonModel.position).normalize();
        dir.y = 0;
        this.jasonModel.position.addScaledVector(dir, this.jasonSpeed * delta);
        this.jasonModel.lookAt(playerPos.x, this.jasonModel.position.y, playerPos.z);

        if (dist < 1.6) {
          this.emit('playerDeath');
        }
      }
    }
  }

  _onKeyDown(e) {
    if (e.code === 'KeyE') {
      const cam = this.scene?.getObjectByProperty('isCamera', true);
      const playerPos = new THREE.Vector3();
      if (cam) cam.getWorldPosition(playerPos);
      else playerPos.set(0, 1.6, 1.0);

      for (const item of this.interactables) {
        if (item && item.userData?.interactable && item.position.distanceTo(playerPos) < 3.2) {
          if (typeof item.userData.onInteract === 'function') {
            item.userData.onInteract();
            break;
          }
        }
      }
    }
  }

  getSpawnPoint() {
    return new THREE.Vector3(0, 1.6, 1.0);
  }

  dispose() {
    document.removeEventListener('keydown', this._onKeyDown);
    if (this.interactPrompt?.parentNode) this.interactPrompt.remove();
    if (this.subtitleDisplay?.parentNode) this.subtitleDisplay.remove();
    if (this.staticOverlay?.parentNode) this.staticOverlay.remove();

    this.levelGroup.traverse(child => {
      if (child.isMesh) {
        if (child.geometry) child.geometry.dispose();
        if (Array.isArray(child.material)) child.material.forEach(m => m.dispose());
        else if (child.material) child.material.dispose();
      }
    });
    if (this.scene) this.scene.remove(this.levelGroup);
    this._listeners = {};
  }
}

/**
 * Level5_Escape.js — 'The Escape'
 * The climax: sprint through a collapsing underground tunnel into the stormy night.
 * All horrific apparitions give chase. Reach the Farmhouse sanctuary to survive.
 * @module Level5_Escape
 */

import * as THREE from 'three';

/** Asset paths relative to game/ directory */
const ASSETS = {
  tunnel: '/tunnel.glb',
  farmhouse: '/weathered_red_saltbox_farmhouse.glb',
  shack: '/abandoned_shack_in_the_swamp.glb',
  ghost: '/horror_ghost_character_-_blood_stained_spirit.glb',
  butcher: '/horror_butcher_fat_killer_bloody_cleaver.glb',
  jason: '/jeson_horror_fan_art.glb',
  outhouse: '/old_wooden_toilet_house_2.glb',
  bloodBag: '/blood_bag.glb'
};

/** EventEmitter base */
class LevelEventEmitter {
  constructor() { this._listeners = {}; }
  on(e, cb) { if (!this._listeners[e]) this._listeners[e] = []; this._listeners[e].push(cb); }
  off(e, cb) { if (!this._listeners[e]) return; this._listeners[e] = this._listeners[e].filter(f => f !== cb); }
  emit(e, d) { if (this._listeners[e]) this._listeners[e].forEach(cb => cb(d)); }
}

/**
 * Level 5: The Escape
 * @extends LevelEventEmitter
 */
export class Level5_Escape extends LevelEventEmitter {
  constructor() {
    super();

    /** @type {THREE.Scene|null} */
    this.scene = null;
    /** @type {object|null} */
    this.assetLoader = null;

    /** @type {THREE.Group} */
    this.levelGroup = new THREE.Group();
    this.levelGroup.name = 'Level5_Escape';

    this.levelManager = null;
    this.playerInventory = {};

    // Models
    this.tunnelModel = null;
    this.farmhouseModel = null;
    this.ghostModel = null;
    this.butcherModel = null;
    this.jasonModel = null;

    // Atmosphere
    this.fog = null;
    this.emergencyLights = [];
    this.elapsedTime = 0;
    this.screenShake = 0;
    this.escaped = false;

    // Escape trigger zone (farmhouse porch at z: -70)
    this.escapeZone = new THREE.Vector3(0, 0, -68);
    this.escapeRadius = 5.0;

    // UI
    this.interactPrompt = null;
    this.subtitleDisplay = null;

    this._onKeyDown = this._onKeyDown.bind(this);
  }

  async init(scene, assetLoader) {
    this.scene = scene;
    this.assetLoader = assetLoader;

    this._createUI();
    this._setupEnvironment();
    this.scene.add(this.levelGroup);

    await this._loadAssets();

    document.addEventListener('keydown', this._onKeyDown);

    this.showSubtitle("THE ESCAPE! THE TUNNEL IS COLLAPSING! RUN TOWARD THE LIGHT!", 6000);
    this.emit('triggerScare', { intensity: 0.9 });
    console.log('[Level5] The Escape initialized');
  }

  _createUI() {
    this.interactPrompt = document.createElement('div');
    this.interactPrompt.id = 'interact-prompt-l5';
    Object.assign(this.interactPrompt.style, {
      position: 'fixed', bottom: '30%', left: '50%',
      transform: 'translateX(-50%)', color: '#ffddaa',
      fontFamily: '"Courier New", monospace', fontSize: '1.1rem',
      padding: '8px 16px', backgroundColor: 'rgba(0,0,0,0.85)',
      border: '1px solid #ff4400', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center'
    });
    document.body.appendChild(this.interactPrompt);

    this.subtitleDisplay = document.createElement('div');
    this.subtitleDisplay.id = 'subtitle-display-l5';
    Object.assign(this.subtitleDisplay.style, {
      position: 'fixed', bottom: '15%', left: '50%',
      transform: 'translateX(-50%)', color: '#ff2200',
      fontFamily: '"Courier New", monospace', fontSize: '1.2rem',
      padding: '12px 24px', backgroundColor: 'rgba(10,0,0,0.9)',
      border: '2px solid #8B0000', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center',
      maxWidth: '700px', textShadow: '0 0 12px #ff0000',
      fontWeight: 'bold'
    });
    document.body.appendChild(this.subtitleDisplay);

  }

  _setupEnvironment() {
    // Dense fog
    this.scene.fog = new THREE.FogExp2(0x0a0508, 0.04);

    const ambientLight = new THREE.AmbientLight(0x110808, 0.4);
    this.levelGroup.add(ambientLight);

    // Emergency flashing strobe lights along the tunnel (Z: 0 to -50)
    for (let z = 0; z >= -50; z -= 12) {
      const strobe = new THREE.PointLight(0xff1100, 2.5, 15);
      strobe.position.set(0, 3.2, z);
      strobe.castShadow = true;
      this.levelGroup.add(strobe);
      this.emergencyLights.push(strobe);
    }

    // Distant moonlight beacon at farmhouse exterior (Z: -68)
    const moonBeacon = new THREE.PointLight(0x88ccff, 4.0, 35);
    moonBeacon.position.set(0, 8, -68);
    this.levelGroup.add(moonBeacon);

    // Tunnel ground & outdoor terrain
    const groundGeo = new THREE.PlaneGeometry(16, 100);
    const groundMat = new THREE.MeshStandardMaterial({ color: 0x151212, roughness: 0.95 });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    ground.position.set(0, 0, -35);
    ground.receiveShadow = true;
    this.levelGroup.add(ground);

    // Tunnel walls (Z: 5 to -50)
    const tunnelWallMat = new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.9 });
    const leftWall = new THREE.Mesh(new THREE.BoxGeometry(0.5, 5, 60), tunnelWallMat);
    leftWall.position.set(-4, 2.5, -25);
    this.levelGroup.add(leftWall);

    const rightWall = new THREE.Mesh(new THREE.BoxGeometry(0.5, 5, 60), tunnelWallMat);
    rightWall.position.set(4, 2.5, -25);
    this.levelGroup.add(rightWall);

    const tunnelCeiling = new THREE.Mesh(new THREE.BoxGeometry(8, 0.5, 60), tunnelWallMat);
    tunnelCeiling.position.set(0, 4.8, -25);
    this.levelGroup.add(tunnelCeiling);
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
        console.warn(`[Level5] Fallback for ${name}:`, e);
      }
      return null;
    };

    // Tunnel model (58.9m long, 3.66m high)
    this.tunnelModel = await loadModel('tunnel', ASSETS.tunnel,
      new THREE.Vector3(0, 0, -25), null, 1.0);

    // Weathered Red Farmhouse at exterior (scaled to realistic 7.4m x 7.0m x 7.6m house)
    this.farmhouseModel = await loadModel('farmhouse', ASSETS.farmhouse,
      new THREE.Vector3(0, 0, -72), { x: 0, y: Math.PI, z: 0 }, 4.0);
    if (!this.farmhouseModel) {
      const house = new THREE.Mesh(new THREE.BoxGeometry(10, 7, 10), new THREE.MeshStandardMaterial({ color: 0x5a1a1a }));
      house.position.set(0, 3.5, -72);
      this.levelGroup.add(house);
      this.farmhouseModel = house;
    }

    // Abandoned Swamp Shack on side of foggy woods (10m x 10m x 4.5m)
    await loadModel('shack', ASSETS.shack,
      new THREE.Vector3(14, 0, -62), { x: 0, y: -0.4, z: 0 }, 0.5);

    // Old wooden outhouse next to farmhouse
    await loadModel('outhouse', ASSETS.outhouse,
      new THREE.Vector3(-8, 0, -68), { x: 0, y: 0.3, z: 0 }, 1.3);

    // Chasing Ghost spirit behind player
    this.ghostModel = await loadModel('ghost', ASSETS.ghost,
      new THREE.Vector3(0, 1.2, 8), null, 1.8);

    // Chasing Butcher (1.9m tall)
    this.butcherModel = await loadModel('butcher', ASSETS.butcher,
      new THREE.Vector3(-2.2, 0, 12), null, 1.9);

    // Chasing Jason stalker (1.92m tall)
    this.jasonModel = await loadModel('jason', ASSETS.jason,
      new THREE.Vector3(2.2, 0, 14), null, 0.11);

    // Emergency blood bags along tunnel
    const bag1 = await loadModel('bloodBag1', ASSETS.bloodBag,
      new THREE.Vector3(1.2, 0.4, -15), { x: Math.PI / 2, y: 0, z: 0 }, 0.01);
    const bag2 = await loadModel('bloodBag2', ASSETS.bloodBag,
      new THREE.Vector3(-1.2, 0.4, -35), { x: Math.PI / 2, y: 0, z: 0 }, 0.01);
    this.bloodBags = [bag1, bag2].filter(Boolean);
    this.bloodBags.forEach(b => {
      b.userData.interactable = true;
      b.userData.prompt = 'Take Blood Bag (+25 HP) [E]';
      b.userData.onInteract = () => {
        if (this.playerInventory.health !== undefined) {
          this.playerInventory.health = Math.min(100, (this.playerInventory.health || 75) + 25);
          this.emit('healthChange', { health: this.playerInventory.health });
        }
        b.visible = false;
        this.showSubtitle('+25 HP restored from Blood Bag.', 2500);
      };
    });
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

    // Strobe emergency lights pulsing fast
    const strobeVal = Math.sin(this.elapsedTime * 18) > 0 ? 3.0 : 0.2;
    this.emergencyLights.forEach(l => {
      l.intensity = strobeVal;
    });

    // Player position
    const cam = this.scene?.getObjectByProperty('isCamera', true);
    const playerPos = new THREE.Vector3();
    if (cam) cam.getWorldPosition(playerPos);
    else playerPos.set(0, 1.7, 0);

    // Ghost floating pursuit
    if (this.ghostModel) {
      this.ghostModel.position.z -= 4.2 * delta;
      this.ghostModel.position.y = 1.3 + Math.sin(this.elapsedTime * 4) * 0.3;
      if (this.ghostModel.position.distanceTo(playerPos) < 1.4 && !this.escaped) {
        this.emit('playerDeath');
      }
    }

    // Butcher pursuit
    if (this.butcherModel) {
      this.butcherModel.position.z -= 3.8 * delta;
      if (this.butcherModel.position.distanceTo(playerPos) < 1.5 && !this.escaped) {
        this.emit('playerDeath');
      }
    }

    // Jason pursuit
    if (this.jasonModel) {
      this.jasonModel.position.z -= 4.0 * delta;
      if (this.jasonModel.position.distanceTo(playerPos) < 1.5 && !this.escaped) {
        this.emit('playerDeath');
      }
    }

    // Check escape trigger zone
    if (!this.escaped && playerPos.distanceTo(this.escapeZone) < this.escapeRadius) {
      this.escaped = true;
      this._triggerVictory();
    }
  }

  _triggerVictory() {
    console.log('[Level5] Player reached safety — VICTORY!');
    if (document.exitPointerLock) {
      document.exitPointerLock();
    }
    this.emit('victory');
  }

  _onKeyDown(e) {
    if (e.code === 'KeyE') {
      const cam = this.scene?.getObjectByProperty('isCamera', true);
      const playerPos = new THREE.Vector3();
      if (cam) cam.getWorldPosition(playerPos);
      if (this.bloodBags) {
        for (const bag of this.bloodBags) {
          if (bag && bag.visible && bag.position.distanceTo(playerPos) < 3.2) {
            bag.userData.onInteract();
            break;
          }
        }
      }
    }
  }

  getSpawnPoint() {
    return new THREE.Vector3(0, 1.7, 3);
  }

  dispose() {
    document.removeEventListener('keydown', this._onKeyDown);
    if (this.interactPrompt?.parentNode) this.interactPrompt.remove();
    if (this.subtitleDisplay?.parentNode) this.subtitleDisplay.remove();

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

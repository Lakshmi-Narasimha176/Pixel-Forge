/**
 * Level2_Corridor.js — 'The Corridor'
 * Long dark corridor with ghost encounters, flickering lights,
 * jump scares, and rat ambience.
 * @module Level2_Corridor
 */

import * as THREE from 'three';

/** Asset paths relative to game/ directory */
const ASSETS = {
  corridor: '../horror_corridor_5.glb',
  ghost: '../horror_ghost_character_-_blood_stained_spirit.glb',
  baseballBat: '../baseball_bat_covered_in_blood.glb',
  rat: '../street_rat.glb',
  door: '../PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_door.glb'
};

/** Ghost behavior states */
const GHOST_STATE = {
  HIDDEN: 'hidden',
  APPEARING: 'appearing',
  VISIBLE: 'visible',
  VANISHING: 'vanishing',
  JUMP_SCARE: 'jump_scare'
};

/**
 * EventEmitter base
 */
class LevelEventEmitter {
  constructor() {
    this._listeners = {};
  }
  on(event, cb) {
    if (!this._listeners[event]) this._listeners[event] = [];
    this._listeners[event].push(cb);
  }
  off(event, cb) {
    if (!this._listeners[event]) return;
    this._listeners[event] = this._listeners[event].filter(fn => fn !== cb);
  }
  emit(event, data) {
    if (this._listeners[event]) this._listeners[event].forEach(cb => cb(data));
  }
}

/**
 * Level 2: The Corridor
 * @extends LevelEventEmitter
 */
export class Level2_Corridor extends LevelEventEmitter {
  constructor() {
    super();

    /** @type {THREE.Scene|null} */
    this.scene = null;

    /** @type {object|null} */
    this.assetLoader = null;

    /** @type {THREE.Group} */
    this.levelGroup = new THREE.Group();
    this.levelGroup.name = 'Level2_Corridor';

    /** @type {object} */
    this.playerInventory = {};

    /** @type {object|null} */
    this.levelManager = null;

    // --- Level state ---
    /** @type {number} */
    this.elapsedTime = 0;

    // --- Lighting ---
    /** @type {THREE.PointLight[]} Corridor lights */
    this.corridorLights = [];

    /** @type {number} Number of corridor lights */
    this.numLights = 6;

    // --- Ghost ---
    /** @type {THREE.Object3D|null} */
    this.ghostModel = null;

    /** @type {string} */
    this.ghostState = GHOST_STATE.HIDDEN;

    /** @type {number} Timer for ghost events */
    this.ghostTimer = 0;

    /** @type {number} Next ghost appearance time */
    this.nextGhostTime = 8;

    /** @type {boolean} Has the first ghost sighting occurred */
    this.firstSightingDone = false;

    /** @type {boolean} Has the jump scare occurred */
    this.jumpScareDone = false;

    /** @type {number} Ghost opacity for fade effect */
    this.ghostOpacity = 0;

    /** @type {THREE.Vector3} Ghost target position */
    this.ghostTargetPos = new THREE.Vector3(0, 0, -25);

    // --- Rats ---
    /** @type {THREE.Object3D[]} */
    this.rats = [];

    /** @type {object[]} Rat movement paths */
    this.ratPaths = [];

    /** @type {number} Timer for next rat spawn */
    this.nextRatTime = 5;

    // --- Baseball bat ---
    /** @type {THREE.Object3D|null} */
    this.batModel = null;

    /** @type {boolean} */
    this.batPickedUp = false;

    // --- Exit door ---
    /** @type {THREE.Object3D|null} */
    this.exitDoor = null;

    // --- Interactables ---
    /** @type {THREE.Raycaster} */
    this.interactRaycaster = new THREE.Raycaster();
    this.interactRaycaster.far = 3.0;

    /** @type {Array<THREE.Object3D>} */
    this.interactables = [];

    // --- UI ---
    /** @type {HTMLElement|null} */
    this.interactPrompt = null;

    /** @type {HTMLElement|null} */
    this.subtitleDisplay = null;

    /** @type {HTMLElement|null} Jump scare overlay */
    this.scareOverlay = null;

    // --- Player facing direction tracking (for jump scare) ---
    /** @type {THREE.Vector3} */
    this.lastPlayerForward = new THREE.Vector3(0, 0, -1);

    /** @type {boolean} Player has looked backward at least once */
    this.hasLookedBack = false;

    /** @type {number} How far player has walked down corridor */
    this.playerProgress = 0;

    this._onKeyDown = this._onKeyDown.bind(this);
  }

  /**
   * Initialize the level
   * @param {THREE.Scene} scene
   * @param {object} assetLoader
   * @returns {Promise<void>}
   */
  async init(scene, assetLoader) {
    this.scene = scene;
    this.assetLoader = assetLoader;

    this._createUI();
    this._setupEnvironment();
    await this._loadAssets();
    this._setupInteractables();
    this._setupRatPaths();

    this.scene.add(this.levelGroup);
    document.addEventListener('keydown', this._onKeyDown);

    console.log('[Level2] The Corridor initialized');
  }

  /**
   * Create UI elements
   * @private
   */
  _createUI() {
    this.interactPrompt = document.createElement('div');
    this.interactPrompt.id = 'interact-prompt-l2';
    Object.assign(this.interactPrompt.style, {
      position: 'fixed', bottom: '30%', left: '50%',
      transform: 'translateX(-50%)', color: '#cccccc',
      fontFamily: '"Courier New", monospace', fontSize: '0.9rem',
      padding: '8px 16px', backgroundColor: 'rgba(0,0,0,0.7)',
      border: '1px solid #333', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center'
    });
    document.body.appendChild(this.interactPrompt);

    this.subtitleDisplay = document.createElement('div');
    this.subtitleDisplay.id = 'subtitle-display-l2';
    Object.assign(this.subtitleDisplay.style, {
      position: 'fixed', bottom: '15%', left: '50%',
      transform: 'translateX(-50%)', color: '#ff4444',
      fontFamily: '"Courier New", monospace', fontSize: '1.1rem',
      padding: '12px 24px', backgroundColor: 'rgba(0,0,0,0.85)',
      border: '1px solid #8B0000', borderRadius: '4px',
      display: 'none', zIndex: '100', textAlign: 'center',
      maxWidth: '600px', textShadow: '0 0 8px #ff0000'
    });
    document.body.appendChild(this.subtitleDisplay);

    // Jump scare overlay (flash white/ghost face)
    this.scareOverlay = document.createElement('div');
    this.scareOverlay.id = 'scare-overlay-l2';
    Object.assign(this.scareOverlay.style, {
      position: 'fixed', top: '0', left: '0',
      width: '100vw', height: '100vh',
      backgroundColor: 'rgba(255,255,255,0.9)',
      display: 'none', zIndex: '9997',
      transition: 'opacity 0.3s ease-out'
    });
    document.body.appendChild(this.scareOverlay);
  }

  /**
   * Set up the corridor environment
   * @private
   */
  _setupEnvironment() {
    // Very dark ambient
    this.ambientLight = new THREE.AmbientLight(0x030303, 0.15);
    this.levelGroup.add(this.ambientLight);

    // Create flickering corridor lights
    for (let i = 0; i < this.numLights; i++) {
      const light = new THREE.PointLight(0xddaa55, 0.6, 8, 2);
      light.position.set(0, 3.2, -4 - i * 5);
      light.castShadow = true;
      light.shadow.mapSize.set(256, 256);
      light.userData.baseIntensity = 0.6;
      light.userData.flickerOffset = Math.random() * Math.PI * 2;
      light.userData.flickerSpeed = 2 + Math.random() * 3;
      this.corridorLights.push(light);
      this.levelGroup.add(light);
    }

    // Dense corridor fog
    this.scene.fog = new THREE.FogExp2(0x010101, 0.06);
  }

  /**
   * Load all level assets
   * @private
   * @returns {Promise<void>}
   */
  async _loadAssets() {
    const totalAssets = 5;
    let loaded = 0;

    const load = async (key, path, pos, rot, scale) => {
      try {
        const gltf = await this.assetLoader.load(path);
        const model = gltf.scene || gltf;
        model.position.copy(pos);
        if (rot) model.rotation.set(rot.x, rot.y, rot.z);
        if (scale) model.scale.set(scale, scale, scale);
        model.name = key;
        model.userData.levelObject = true;
        model.traverse(child => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
          }
        });
        this.levelGroup.add(model);
        loaded++;
        if (this.levelManager) this.levelManager.updateLoadingProgress(loaded / totalAssets);
        return model;
      } catch (err) {
        console.warn(`[Level2] Failed to load '${key}':`, err);
        loaded++;
        if (this.levelManager) this.levelManager.updateLoadingProgress(loaded / totalAssets);
        return null;
      }
    };

    // Corridor environment
    await load('corridor', ASSETS.corridor,
      new THREE.Vector3(0, 0, 0), null, 1);

    // Ghost — initially hidden far away
    this.ghostModel = await load('ghost', ASSETS.ghost,
      new THREE.Vector3(0, 0, -30), null, 1.2);
    if (this.ghostModel) {
      this.ghostModel.visible = false;
      // Make ghost semi-transparent
      this.ghostModel.traverse(child => {
        if (child.isMesh && child.material) {
          child.material = child.material.clone();
          child.material.transparent = true;
          child.material.opacity = 0;
          child.material.emissive = new THREE.Color(0x112244);
          child.material.emissiveIntensity = 0.5;
        }
      });
    }

    // Baseball bat on the ground
    this.batModel = await load('baseballBat', ASSETS.baseballBat,
      new THREE.Vector3(1.2, 0.1, -12),
      { x: 0, y: 0.5, z: Math.PI / 2 },
      0.8);

    // Rat template (will be cloned for spawning)
    this.ratTemplate = await load('ratTemplate', ASSETS.rat,
      new THREE.Vector3(100, -100, 100), null, 0.3);
    if (this.ratTemplate) {
      this.ratTemplate.visible = false;
    }

    // Exit door at end of corridor
    this.exitDoor = await load('exitDoor', ASSETS.door,
      new THREE.Vector3(0, 0, -32),
      { x: 0, y: Math.PI, z: 0 },
      1.2);
  }

  /**
   * Set up pre-defined rat scurry paths
   * @private
   */
  _setupRatPaths() {
    this.ratPaths = [
      { start: new THREE.Vector3(-2, 0, -8), end: new THREE.Vector3(2, 0, -9), speed: 3 },
      { start: new THREE.Vector3(2, 0, -15), end: new THREE.Vector3(-2, 0, -14), speed: 4 },
      { start: new THREE.Vector3(-1.5, 0, -20), end: new THREE.Vector3(1.5, 0, -21), speed: 3.5 },
      { start: new THREE.Vector3(1, 0, -25), end: new THREE.Vector3(-2, 0, -26), speed: 5 }
    ];
  }

  /**
   * Set up interactable objects
   * @private
   */
  _setupInteractables() {
    this.interactables = [];

    if (this.batModel) {
      this.batModel.userData.interactable = true;
      this.batModel.userData.interactType = 'pickup';
      this.batModel.userData.interactLabel = 'Pick up Baseball Bat [E]';
      this.batModel.userData.itemName = 'baseballBat';
      this.interactables.push(this.batModel);
    }

    if (this.exitDoor) {
      this.exitDoor.userData.interactable = true;
      this.exitDoor.userData.interactType = 'exit';
      this.exitDoor.userData.interactLabel = 'Open Door [E]';
      this.interactables.push(this.exitDoor);
    }
  }

  /**
   * @private
   */
  _onKeyDown(e) {
    if (e.code === 'KeyE') this._tryInteract();
  }

  /**
   * @private
   */
  _tryInteract() {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;

    this.interactRaycaster.set(
      camera.position.clone(),
      new THREE.Vector3(0, 0, -1).applyQuaternion(camera.quaternion)
    );

    const intersects = this.interactRaycaster.intersectObjects(this.interactables, true);
    if (intersects.length === 0) return;

    let target = intersects[0].object;
    while (target && !target.userData.interactable) target = target.parent;
    if (!target) return;

    this._handleInteraction(target);
  }

  /**
   * @private
   */
  _handleInteraction(target) {
    switch (target.userData.interactType) {
      case 'pickup':
        if (target.userData.itemName === 'baseballBat' && !this.batPickedUp) {
          this.batPickedUp = true;
          this.playerInventory.hasBaseballBat = true;
          this.emit('itemPickup', { item: 'baseballBat', model: target });
          target.visible = false;
          this._removeInteractable(target);
          this._showSubtitle('Baseball bat acquired. You feel slightly safer.', 3000);
          console.log('[Level2] Baseball bat picked up');
        }
        break;

      case 'exit':
        this._showSubtitle('You push through the door...', 2000);
        this.emit('exit', { nextLevel: 3 });
        break;
    }
  }

  /**
   * @private
   */
  _removeInteractable(obj) {
    this.interactables = this.interactables.filter(o => o !== obj);
  }

  /**
   * Show subtitle
   * @private
   */
  _showSubtitle(text, duration) {
    if (!this.subtitleDisplay) return;
    this.subtitleDisplay.textContent = text;
    this.subtitleDisplay.style.display = 'block';
    this.subtitleDisplay.style.opacity = '1';
    setTimeout(() => {
      if (this.subtitleDisplay) {
        this.subtitleDisplay.style.opacity = '0';
        setTimeout(() => {
          if (this.subtitleDisplay) this.subtitleDisplay.style.display = 'none';
        }, 500);
      }
    }, duration);
  }

  /**
   * @private
   */
  _showInteractPrompt(text) {
    if (this.interactPrompt) {
      this.interactPrompt.textContent = text;
      this.interactPrompt.style.display = 'block';
    }
  }

  /** @private */
  _hideInteractPrompt() {
    if (this.interactPrompt) this.interactPrompt.style.display = 'none';
  }

  /**
   * Trigger jump scare — ghost appears behind player
   * @private
   */
  _triggerJumpScare() {
    if (this.jumpScareDone || !this.ghostModel) return;
    this.jumpScareDone = true;
    this.ghostState = GHOST_STATE.JUMP_SCARE;

    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;

    // Position ghost right behind player
    const behindPlayer = camera.position.clone();
    const forward = new THREE.Vector3(0, 0, -1).applyQuaternion(camera.quaternion);
    behindPlayer.add(forward.multiplyScalar(-2));
    behindPlayer.y = 0;

    this.ghostModel.position.copy(behindPlayer);
    this.ghostModel.lookAt(camera.position);
    this.ghostModel.visible = true;

    // Flash opacity on
    this.ghostModel.traverse(child => {
      if (child.isMesh && child.material) {
        child.material.opacity = 1;
      }
    });

    // Screen flash
    if (this.scareOverlay) {
      this.scareOverlay.style.display = 'block';
      this.scareOverlay.style.opacity = '1';
      setTimeout(() => {
        if (this.scareOverlay) {
          this.scareOverlay.style.opacity = '0';
          setTimeout(() => {
            if (this.scareOverlay) this.scareOverlay.style.display = 'none';
          }, 300);
        }
      }, 150);
    }

    // All lights go out briefly
    this.corridorLights.forEach(l => { l.intensity = 0; });

    this.emit('triggerScare', { type: 'jumpScare', intensity: 1.0 });

    // Ghost vanishes after 0.8 seconds
    setTimeout(() => {
      if (this.ghostModel) {
        this.ghostModel.visible = false;
        this.ghostState = GHOST_STATE.HIDDEN;
      }
      // Lights slowly come back
      this.corridorLights.forEach((l, i) => {
        setTimeout(() => { l.intensity = l.userData.baseIntensity; }, i * 200);
      });
    }, 800);

    console.log('[Level2] JUMP SCARE triggered!');
  }

  /**
   * Update the level every frame
   * @param {number} delta
   */
  update(delta) {
    this.elapsedTime += delta;

    this._updateLights(delta);
    this._updateGhost(delta);
    this._updateRats(delta);
    this._updateJumpScareCheck(delta);
    this._updateInteractionPrompts();
  }

  /**
   * Update corridor light flickering
   * @private
   */
  _updateLights(delta) {
    const ghostNear = this.ghostState === GHOST_STATE.VISIBLE ||
                      this.ghostState === GHOST_STATE.APPEARING;

    this.corridorLights.forEach((light, i) => {
      const t = this.elapsedTime * light.userData.flickerSpeed + light.userData.flickerOffset;

      if (ghostNear) {
        // Aggressive flickering when ghost is near
        light.intensity = Math.random() < 0.4 ? 0 : light.userData.baseIntensity * 1.5;
      } else {
        // Subtle ambient flicker
        const flicker = Math.sin(t) * 0.15 + Math.sin(t * 2.7) * 0.1;
        light.intensity = light.userData.baseIntensity + flicker;

        // Occasional random dropout
        if (Math.random() < 0.002) {
          light.intensity = 0;
        }
      }
    });
  }

  /**
   * Update ghost behavior state machine
   * @private
   */
  _updateGhost(delta) {
    this.ghostTimer += delta;

    switch (this.ghostState) {
      case GHOST_STATE.HIDDEN:
        if (this.ghostTimer >= this.nextGhostTime) {
          this._ghostAppear();
        }
        break;

      case GHOST_STATE.APPEARING:
        this.ghostOpacity = Math.min(this.ghostOpacity + delta * 1.5, 0.8);
        this._setGhostOpacity(this.ghostOpacity);
        if (this.ghostOpacity >= 0.8) {
          this.ghostState = GHOST_STATE.VISIBLE;
          this.ghostTimer = 0;
        }
        break;

      case GHOST_STATE.VISIBLE:
        // Ghost stands visible for 2-3 seconds
        if (this.ghostTimer >= 2.5) {
          this.ghostState = GHOST_STATE.VANISHING;
          this.ghostTimer = 0;
        }
        // Slight ghostly hovering
        if (this.ghostModel) {
          this.ghostModel.position.y = Math.sin(this.elapsedTime * 2) * 0.1;
        }
        break;

      case GHOST_STATE.VANISHING:
        this.ghostOpacity = Math.max(this.ghostOpacity - delta * 2, 0);
        this._setGhostOpacity(this.ghostOpacity);
        if (this.ghostOpacity <= 0) {
          if (this.ghostModel) this.ghostModel.visible = false;
          this.ghostState = GHOST_STATE.HIDDEN;
          this.ghostTimer = 0;
          this.nextGhostTime = 10 + Math.random() * 8;
          if (!this.firstSightingDone) {
            this.firstSightingDone = true;
            this._showSubtitle('What was that...?', 2000);
          }
        }
        break;
    }
  }

  /**
   * Make ghost appear at end of corridor
   * @private
   */
  _ghostAppear() {
    if (!this.ghostModel) return;

    this.ghostModel.position.set(0, 0, -28);
    this.ghostModel.rotation.y = Math.PI; // Face toward player
    this.ghostModel.visible = true;
    this.ghostOpacity = 0;
    this.ghostState = GHOST_STATE.APPEARING;
    this.ghostTimer = 0;

    this.emit('triggerScare', { type: 'ghostAppear', intensity: 0.5 });
    console.log('[Level2] Ghost appearing at end of corridor');
  }

  /**
   * Set ghost material opacity
   * @private
   */
  _setGhostOpacity(opacity) {
    if (!this.ghostModel) return;
    this.ghostModel.traverse(child => {
      if (child.isMesh && child.material) {
        child.material.opacity = opacity;
      }
    });
  }

  /**
   * Update rat spawning and movement
   * @private
   */
  _updateRats(delta) {
    // Spawn new rat periodically
    if (this.elapsedTime >= this.nextRatTime && this.ratTemplate) {
      this._spawnRat();
      this.nextRatTime = this.elapsedTime + 6 + Math.random() * 10;
    }

    // Update existing rats
    for (let i = this.rats.length - 1; i >= 0; i--) {
      const rat = this.rats[i];
      const path = rat.userData.path;
      rat.userData.progress += delta * path.speed;

      const t = Math.min(rat.userData.progress, 1);
      rat.position.lerpVectors(path.start, path.end, t);

      if (t >= 1) {
        this.levelGroup.remove(rat);
        this.rats.splice(i, 1);
      }
    }
  }

  /**
   * Spawn a rat on a random path
   * @private
   */
  _spawnRat() {
    if (!this.ratTemplate || this.ratPaths.length === 0) return;

    const path = this.ratPaths[Math.floor(Math.random() * this.ratPaths.length)];
    const rat = this.ratTemplate.clone();
    rat.visible = true;
    rat.position.copy(path.start);
    rat.userData.path = path;
    rat.userData.progress = 0;

    // Face direction of movement
    rat.lookAt(path.end);

    this.levelGroup.add(rat);
    this.rats.push(rat);
  }

  /**
   * Check if player has turned around (for jump scare trigger)
   * @private
   */
  _updateJumpScareCheck(delta) {
    if (this.jumpScareDone) return;

    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;

    const forward = new THREE.Vector3(0, 0, -1).applyQuaternion(camera.quaternion);

    // Player has progressed past halfway point
    if (camera.position.z < -15) {
      this.playerProgress = Math.abs(camera.position.z);

      // Check if player is looking backward (positive Z — toward start)
      if (forward.z > 0.5 && !this.hasLookedBack) {
        this.hasLookedBack = true;
        // Trigger jump scare after a brief delay
        setTimeout(() => this._triggerJumpScare(), 300);
      }
    }

    this.lastPlayerForward.copy(forward);
  }

  /**
   * Update interaction prompts
   * @private
   */
  _updateInteractionPrompts() {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera || this.interactables.length === 0) {
      this._hideInteractPrompt();
      return;
    }

    this.interactRaycaster.set(
      camera.position.clone(),
      new THREE.Vector3(0, 0, -1).applyQuaternion(camera.quaternion)
    );

    const intersects = this.interactRaycaster.intersectObjects(this.interactables, true);
    if (intersects.length > 0) {
      let target = intersects[0].object;
      while (target && !target.userData.interactable) target = target.parent;
      if (target && target.userData.interactLabel) {
        this._showInteractPrompt(target.userData.interactLabel);
        return;
      }
    }
    this._hideInteractPrompt();
  }

  /**
   * Get spawn point
   * @returns {THREE.Vector3}
   */
  getSpawnPoint() {
    return new THREE.Vector3(0, 1.6, 0);
  }

  /**
   * Dispose of level resources
   */
  dispose() {
    document.removeEventListener('keydown', this._onKeyDown);

    // Remove UI
    [this.interactPrompt, this.subtitleDisplay, this.scareOverlay].forEach(el => {
      if (el && el.parentNode) el.parentNode.removeChild(el);
    });

    // Dispose models
    this.levelGroup.traverse(child => {
      if (child.isMesh) {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
          if (Array.isArray(child.material)) child.material.forEach(m => m.dispose());
          else child.material.dispose();
        }
      }
    });

    if (this.scene) {
      this.scene.remove(this.levelGroup);
      this.scene.fog = null;
    }

    this.rats = [];
    this.corridorLights = [];
    this.interactables = [];
    this._listeners = {};
    this.scene = null;
    this.assetLoader = null;

    console.log('[Level2] Disposed');
  }
}

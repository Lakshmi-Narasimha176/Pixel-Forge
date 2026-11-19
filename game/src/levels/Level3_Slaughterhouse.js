/**
 * Level3_Slaughterhouse.js — 'The Slaughterhouse'
 * Open room with meat hooks, a patrolling Butcher enemy with
 * line-of-sight detection, hide mechanics, and keycard objective.
 * @module Level3_Slaughterhouse
 */

import * as THREE from 'three';

/** Asset paths relative to game/ directory */
const ASSETS = {
  meatHook: '/butcher_meat_hook_rail_-_cured_ham__sausages.glb',
  butcher: '/horror_butcher_fat_killer_bloody_cleaver.glb',
  deadPig: '/dead_pig.glb',
  rawMeat: '/psx_raw_meat_pack__low-poly_2_types.glb',
  bloodBag: '/blood_bag.glb',
  bloodWall: '/abandoned_horror_wall_with_blood_splatter.glb',
  door: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_door.glb',
  wall: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_wall.glb',
  floor: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_floor.glb'
};

/** Butcher AI states */
const BUTCHER_STATE = {
  PATROL: 'patrol',
  ALERT: 'alert',
  CHASE: 'chase',
  SEARCH: 'search',
  IDLE: 'idle'
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
 * Level 3: The Slaughterhouse
 * @extends LevelEventEmitter
 */
export class Level3_Slaughterhouse extends LevelEventEmitter {
  constructor() {
    super();

    this.scene = null;
    this.assetLoader = null;
    this.levelGroup = new THREE.Group();
    this.levelGroup.name = 'Level3_Slaughterhouse';
    this.playerInventory = {};
    this.levelManager = null;

    // --- Timing ---
    this.elapsedTime = 0;

    // --- Lighting ---
    /** @type {THREE.PointLight[]} */
    this.roomLights = [];

    // --- Butcher AI ---
    /** @type {THREE.Object3D|null} */
    this.butcherModel = null;

    /** @type {string} */
    this.butcherState = BUTCHER_STATE.PATROL;

    /** @type {number} Current patrol waypoint index */
    this.patrolIndex = 0;

    /** @type {THREE.Vector3[]} Patrol waypoints */
    this.patrolPoints = [
      new THREE.Vector3(-6, 0, -6),
      new THREE.Vector3(6, 0, -6),
      new THREE.Vector3(6, 0, 6),
      new THREE.Vector3(-6, 0, 6),
      new THREE.Vector3(-2, 0, 0),
      new THREE.Vector3(2, 0, -3),
    ];

    /** @type {number} Butcher movement speed */
    this.patrolSpeed = 1.8;

    /** @type {number} Chase speed */
    this.chaseSpeed = 5.0;

    /** @type {number} Butcher field of view (radians) */
    this.butcherFOV = Math.PI * 0.4; // 72 degrees

    /** @type {number} Butcher view distance */
    this.butcherViewDistance = 15;

    /** @type {THREE.Raycaster} For line-of-sight checks */
    this.losRaycaster = new THREE.Raycaster();

    /** @type {THREE.Vector3|null} Last known player position when chasing */
    this.lastKnownPlayerPos = null;

    /** @type {number} Timer for search state */
    this.searchTimer = 0;

    /** @type {number} Search duration before returning to patrol */
    this.searchDuration = 5;

    // --- Hide objects (obstacles that break LOS) ---
    /** @type {THREE.Object3D[]} */
    this.hideSpots = [];

    // --- Blood bags (health pickups) ---
    /** @type {THREE.Object3D[]} */
    this.bloodBags = [];

    // --- Keycard ---
    /** @type {THREE.Mesh|null} */
    this.keycard = null;

    /** @type {boolean} */
    this.keycardPickedUp = false;

    // --- Exit door ---
    /** @type {THREE.Object3D|null} */
    this.exitDoor = null;

    // --- Interactables ---
    this.interactRaycaster = new THREE.Raycaster();
    this.interactRaycaster.far = 3.0;
    this.interactables = [];

    // --- UI ---
    this.interactPrompt = null;
    this.subtitleDisplay = null;
    this.dangerIndicator = null;

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
    this._createKeycard();
    this._setupInteractables();

    this.scene.add(this.levelGroup);
    document.addEventListener('keydown', this._onKeyDown);

    console.log('[Level3] The Slaughterhouse initialized');
  }

  /**
   * Create UI elements
   * @private
   */
  _createUI() {
    this.interactPrompt = document.createElement('div');
    this.interactPrompt.id = 'interact-prompt-l3';
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
    this.subtitleDisplay.id = 'subtitle-display-l3';
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

    // Danger indicator (screen edge red when butcher is near/chasing)
    this.dangerIndicator = document.createElement('div');
    this.dangerIndicator.id = 'danger-indicator-l3';
    Object.assign(this.dangerIndicator.style, {
      position: 'fixed', top: '0', left: '0',
      width: '100vw', height: '100vh',
      pointerEvents: 'none',
      boxShadow: 'inset 0 0 100px rgba(255,0,0,0)',
      transition: 'box-shadow 0.3s',
      zIndex: '90', display: 'block'
    });
    document.body.appendChild(this.dangerIndicator);
  }

  /**
   * Set up slaughterhouse environment
   * @private
   */
  _setupEnvironment() {
    // Sickly atmospheric horror ambient
    const ambient = new THREE.AmbientLight(0x241818, 0.4);
    this.levelGroup.add(ambient);

    // Overhead industrial lights — sickly yellow-green
    const lightPositions = [
      new THREE.Vector3(-4, 3.5, -4),
      new THREE.Vector3(4, 3.5, -4),
      new THREE.Vector3(0, 3.5, 4),
      new THREE.Vector3(-4, 3.5, 4),
      new THREE.Vector3(4, 3.5, 0)
    ];

    lightPositions.forEach((pos, i) => {
      const light = new THREE.PointLight(0xffaa55, 1.8, 14, 1.4);
      light.position.copy(pos);
      light.castShadow = i < 3;
      light.shadow.mapSize.set(512, 512);
      light.userData.baseIntensity = 1.8;
      light.userData.flickerOffset = Math.random() * 10;
      this.roomLights.push(light);
      this.levelGroup.add(light);
    });

    // Blood-red accent light
    const redLight = new THREE.PointLight(0xaa2211, 1.5, 12, 1.5);
    redLight.position.set(0, 2.5, 0);
    this.levelGroup.add(redLight);

    // Fog
    this.scene.fog = new THREE.FogExp2(0x0a0505, 0.035);

    // Create floor plane (fallback if model doesn't have one)
    const floorGeo = new THREE.PlaneGeometry(20, 20);
    const floorMat = new THREE.MeshStandardMaterial({
      color: 0x1a1210,
      roughness: 0.9,
      metalness: 0.1
    });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    floor.name = 'floor';
    this.levelGroup.add(floor);
  }

  /**
   * Load all assets
   * @private
   */
  async _loadAssets() {
    const totalAssets = 8;
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
          if (child.isMesh) { child.castShadow = true; child.receiveShadow = true; }
        });
        this.levelGroup.add(model);
        loaded++;
        if (this.levelManager) this.levelManager.updateLoadingProgress(loaded / totalAssets);
        return model;
      } catch (err) {
        console.warn(`[Level3] Failed to load '${key}':`, err);
        loaded++;
        if (this.levelManager) this.levelManager.updateLoadingProgress(loaded / totalAssets);
        return null;
      }
    };

    // Meat hook rail — several placed around the room
    const hookPositions = [
      { pos: new THREE.Vector3(-3, 2.5, -3), rot: { x: 0, y: 0, z: 0 } },
      { pos: new THREE.Vector3(3, 2.5, -5), rot: { x: 0, y: Math.PI / 4, z: 0 } },
      { pos: new THREE.Vector3(-5, 2.5, 2), rot: { x: 0, y: -Math.PI / 3, z: 0 } },
    ];
    for (let i = 0; i < hookPositions.length; i++) {
      const hook = await load(`meatHook_${i}`, ASSETS.meatHook,
        hookPositions[i].pos, hookPositions[i].rot, 0.8);
      if (hook) {
        hook.userData.isObstacle = true;
        this.hideSpots.push(hook);
      }
    }

    // Dead pig
    const pig = await load('deadPig', ASSETS.deadPig,
      new THREE.Vector3(2, 0, -4), { x: 0, y: 1.2, z: 0 }, 0.7);
    if (pig) {
      pig.userData.isObstacle = true;
      this.hideSpots.push(pig);
    }

    // Raw meat (scaled to realistic 1.8m table size)
    await load('rawMeat', ASSETS.rawMeat,
      new THREE.Vector3(-4, 0.3, -5), null, 0.012);

    // Blood splatter walls
    await load('bloodWall', ASSETS.bloodWall,
      new THREE.Vector3(8, 1.5, 0), { x: 0, y: -Math.PI / 2, z: 0 }, 1.2);

    // Blood bags (health pickups)
    const bagPositions = [
      new THREE.Vector3(-6, 0.5, -2),
      new THREE.Vector3(5, 0.5, 5),
      new THREE.Vector3(0, 0.5, -7)
    ];
    for (let i = 0; i < bagPositions.length; i++) {
      const bag = await load(`bloodBag_${i}`, ASSETS.bloodBag,
        bagPositions[i], null, 0.01);
      if (bag) {
        bag.userData.interactable = true;
        bag.userData.interactType = 'healthPickup';
        bag.userData.interactLabel = 'Take Blood Bag (+25 HP) [E]';
        this.bloodBags.push(bag);
      }
    }

    // The Butcher (scaled to imposing 1.9m tall killer)
    this.butcherModel = await load('butcher', ASSETS.butcher,
      this.patrolPoints[0].clone(), null, 1.9);

    // Exit door
    this.exitDoor = await load('exitDoor', ASSETS.door,
      new THREE.Vector3(8, 0, 0), { x: 0, y: -Math.PI / 2, z: 0 }, 1.2);
  }

  /**
   * Create a keycard object (simple mesh since no GLB provided)
   * @private
   */
  _createKeycard() {
    const geo = new THREE.BoxGeometry(0.08, 0.05, 0.001);
    const mat = new THREE.MeshStandardMaterial({
      color: 0xff3333,
      emissive: 0x440000,
      emissiveIntensity: 0.5,
      roughness: 0.3,
      metalness: 0.7
    });
    this.keycard = new THREE.Mesh(geo, mat);
    this.keycard.position.set(-5, 0.9, -6);
    this.keycard.rotation.z = 0.1;
    this.keycard.name = 'keycard';
    this.keycard.userData.interactable = true;
    this.keycard.userData.interactType = 'pickup';
    this.keycard.userData.interactLabel = 'Take Keycard [E]';
    this.keycard.userData.itemName = 'keycard';
    this.keycard.castShadow = true;

    // Pulsing red point light on keycard
    const keycardLight = new THREE.PointLight(0xff0000, 0.4, 3, 2);
    keycardLight.position.set(0, 0.3, 0);
    this.keycard.add(keycardLight);
    this.keycard.userData.light = keycardLight;

    this.levelGroup.add(this.keycard);
  }

  /**
   * Set up interactables list
   * @private
   */
  _setupInteractables() {
    this.interactables = [];

    // Blood bags
    this.bloodBags.forEach(bag => this.interactables.push(bag));

    // Keycard
    if (this.keycard) this.interactables.push(this.keycard);

    // Exit door
    if (this.exitDoor) {
      this.exitDoor.userData.interactable = true;
      this.exitDoor.userData.interactType = 'exit';
      this.exitDoor.userData.interactLabel = 'Exit — Requires Keycard [E]';
      this.interactables.push(this.exitDoor);
    }
  }

  _onKeyDown(e) { if (e.code === 'KeyE') this._tryInteract(); }

  _tryInteract() {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;
    const origin = new THREE.Vector3();
    camera.getWorldPosition(origin);
    const dir = new THREE.Vector3();
    camera.getWorldDirection(dir);
    this.interactRaycaster.set(origin, dir);
    const intersects = this.interactRaycaster.intersectObjects(this.interactables, true);
    if (intersects.length === 0) return;
    let target = intersects[0].object;
    while (target && !target.userData.interactable) target = target.parent;
    if (target) this._handleInteraction(target);
  }

  _handleInteraction(target) {
    switch (target.userData.interactType) {
      case 'pickup':
        if (target.userData.itemName === 'keycard' && !this.keycardPickedUp) {
          this.keycardPickedUp = true;
          this.playerInventory.hasKeycard = true;
          this.emit('itemPickup', { item: 'keycard', model: target });
          target.visible = false;
          this._removeInteractable(target);
          this._showSubtitle('Keycard acquired. Find the exit!', 3000);
          console.log('[Level3] Keycard picked up');
        }
        break;

      case 'healthPickup':
        if (this.playerInventory.health < 100) {
          this.playerInventory.health = Math.min(100, this.playerInventory.health + 25);
          target.visible = false;
          this._removeInteractable(target);
          this.bloodBags = this.bloodBags.filter(b => b !== target);
          this._showSubtitle(`Health restored: ${this.playerInventory.health}/100`, 2000);
          this.emit('healthChange', { health: this.playerInventory.health });
        } else {
          this._showSubtitle('Health already full.', 1500);
        }
        break;

      case 'exit':
        if (this.keycardPickedUp) {
          this._showSubtitle('The lock clicks open...', 2000);
          this.emit('exit', { nextLevel: 4 });
        } else {
          this._showSubtitle('The door requires a keycard.', 2500);
        }
        break;
    }
  }

  _removeInteractable(obj) {
    this.interactables = this.interactables.filter(o => o !== obj);
  }

  _showSubtitle(text, duration) {
    if (!this.subtitleDisplay) return;
    this.subtitleDisplay.textContent = text;
    this.subtitleDisplay.style.display = 'block';
    this.subtitleDisplay.style.opacity = '1';
    setTimeout(() => {
      if (this.subtitleDisplay) {
        this.subtitleDisplay.style.opacity = '0';
        setTimeout(() => { if (this.subtitleDisplay) this.subtitleDisplay.style.display = 'none'; }, 500);
      }
    }, duration);
  }

  _showInteractPrompt(text) {
    if (this.interactPrompt) { this.interactPrompt.textContent = text; this.interactPrompt.style.display = 'block'; }
  }

  _hideInteractPrompt() {
    if (this.interactPrompt) this.interactPrompt.style.display = 'none';
  }

  // =========================================
  //  BUTCHER AI
  // =========================================

  /**
   * Check if the Butcher can see the player (raycast line-of-sight)
   * @private
   * @param {THREE.Vector3} playerPos
   * @returns {boolean}
   */
  _butcherCanSeePlayer(playerPos) {
    if (!this.butcherModel) return false;

    const butcherPos = this.butcherModel.position.clone();
    butcherPos.y = 1.5; // Eye height

    const toPlayer = playerPos.clone().sub(butcherPos);
    const distance = toPlayer.length();

    // Distance check
    if (distance > this.butcherViewDistance) return false;

    // FOV check — butcher's facing direction
    const butcherForward = new THREE.Vector3(0, 0, -1)
      .applyQuaternion(this.butcherModel.quaternion);
    butcherForward.y = 0;
    butcherForward.normalize();

    const dirToPlayer = toPlayer.clone();
    dirToPlayer.y = 0;
    dirToPlayer.normalize();

    const angle = butcherForward.angleTo(dirToPlayer);
    if (angle > this.butcherFOV) return false;

    // Raycast line-of-sight (check for obstacles)
    this.losRaycaster.set(butcherPos, toPlayer.normalize());
    this.losRaycaster.far = distance;

    const obstacles = this.hideSpots.filter(o => o.visible);
    const hits = this.losRaycaster.intersectObjects(obstacles, true);

    // If any obstacle is closer than the player, LOS is blocked
    if (hits.length > 0 && hits[0].distance < distance - 0.5) {
      return false;
    }

    return true;
  }

  /**
   * Update the Butcher AI
   * @private
   * @param {number} delta
   */
  _updateButcher(delta) {
    if (!this.butcherModel) return;

    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;

    const playerPos = new THREE.Vector3();
    camera.getWorldPosition(playerPos);
    const canSee = this._butcherCanSeePlayer(playerPos);

    switch (this.butcherState) {
      case BUTCHER_STATE.PATROL:
        this._butcherPatrol(delta);
        if (canSee) {
          this.butcherState = BUTCHER_STATE.ALERT;
          this.lastKnownPlayerPos = playerPos.clone();
          this.emit('triggerScare', { type: 'butcherSpotted', intensity: 0.7 });
          this._showSubtitle('He sees you! HIDE!', 2000);
          console.log('[Level3] Butcher spotted player!');
          // Brief alert pause before chase
          setTimeout(() => {
            if (this.butcherState === BUTCHER_STATE.ALERT) {
              this.butcherState = BUTCHER_STATE.CHASE;
            }
          }, 800);
        }
        break;

      case BUTCHER_STATE.ALERT:
        // Face the player
        this.butcherModel.lookAt(
          new THREE.Vector3(playerPos.x, this.butcherModel.position.y, playerPos.z)
        );
        break;

      case BUTCHER_STATE.CHASE:
        this._butcherChase(delta, playerPos, canSee);
        break;

      case BUTCHER_STATE.SEARCH:
        this._butcherSearch(delta);
        break;
    }

    // Update danger indicator
    this._updateDangerIndicator(playerPos);
  }

  /**
   * Butcher patrol behavior
   * @private
   */
  _butcherPatrol(delta) {
    const target = this.patrolPoints[this.patrolIndex];
    const butcherPos = this.butcherModel.position;
    const dir = target.clone().sub(butcherPos);
    dir.y = 0;
    const dist = dir.length();

    if (dist < 0.5) {
      this.patrolIndex = (this.patrolIndex + 1) % this.patrolPoints.length;
      return;
    }

    dir.normalize();
    butcherPos.add(dir.multiplyScalar(this.patrolSpeed * delta));

    // Face movement direction
    this.butcherModel.lookAt(
      new THREE.Vector3(target.x, butcherPos.y, target.z)
    );
  }

  /**
   * Butcher chase behavior
   * @private
   */
  _butcherChase(delta, playerPos, canSee) {
    if (canSee) {
      this.lastKnownPlayerPos = playerPos.clone();
    }

    const target = this.lastKnownPlayerPos || playerPos;
    const butcherPos = this.butcherModel.position;
    const dir = target.clone().sub(butcherPos);
    dir.y = 0;
    const dist = dir.length();

    // Catch player
    if (dist < 1.5) {
      this.playerInventory.health -= 35;
      this.emit('healthChange', { health: this.playerInventory.health });
      this._showSubtitle('The Butcher strikes you!', 1500);
      this.emit('triggerScare', { type: 'butcherAttack', intensity: 1.0 });

      if (this.playerInventory.health <= 0) {
        this.emit('playerDeath');
        return;
      }

      // Knock player back — butcher returns to patrol after hitting
      this.butcherState = BUTCHER_STATE.PATROL;
      return;
    }

    // Lost sight — go to last known position
    if (!canSee && dist < 2) {
      this.butcherState = BUTCHER_STATE.SEARCH;
      this.searchTimer = 0;
      return;
    }

    dir.normalize();
    butcherPos.add(dir.multiplyScalar(this.chaseSpeed * delta));
    this.butcherModel.lookAt(
      new THREE.Vector3(target.x, butcherPos.y, target.z)
    );
  }

  /**
   * Butcher search behavior
   * @private
   */
  _butcherSearch(delta) {
    this.searchTimer += delta;

    // Look around
    this.butcherModel.rotation.y += delta * 1.5;

    if (this.searchTimer >= this.searchDuration) {
      this.butcherState = BUTCHER_STATE.PATROL;
      console.log('[Level3] Butcher lost player, returning to patrol');
    }

    // Check if player is visible during search
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (camera && this._butcherCanSeePlayer(camera.position)) {
      this.butcherState = BUTCHER_STATE.CHASE;
      this.lastKnownPlayerPos = camera.position.clone();
    }
  }

  /**
   * Update the danger indicator UI based on butcher proximity
   * @private
   */
  _updateDangerIndicator(playerPos) {
    if (!this.dangerIndicator || !this.butcherModel) return;

    const dist = this.butcherModel.position.distanceTo(playerPos);
    const maxDist = 15;

    if (this.butcherState === BUTCHER_STATE.CHASE) {
      const intensity = Math.max(0, 1 - dist / maxDist);
      this.dangerIndicator.style.boxShadow =
        `inset 0 0 ${60 + intensity * 80}px rgba(255,0,0,${0.2 + intensity * 0.5})`;
    } else if (this.butcherState === BUTCHER_STATE.ALERT) {
      this.dangerIndicator.style.boxShadow = 'inset 0 0 60px rgba(255,165,0,0.3)';
    } else {
      this.dangerIndicator.style.boxShadow = 'inset 0 0 100px rgba(255,0,0,0)';
    }
  }

  /**
   * Update every frame
   * @param {number} delta
   */
  update(delta) {
    this.elapsedTime += delta;

    this._updateButcher(delta);
    this._updateLights(delta);
    this._updateKeycard(delta);
    this._updateInteractionPrompts();
  }

  /**
   * @private
   */
  _updateLights(delta) {
    this.roomLights.forEach(light => {
      const t = this.elapsedTime * 3 + light.userData.flickerOffset;
      const flicker = Math.sin(t) * 0.1 + Math.sin(t * 3.1) * 0.05;
      light.intensity = light.userData.baseIntensity + flicker;

      // Extra flicker when butcher is chasing
      if (this.butcherState === BUTCHER_STATE.CHASE && Math.random() < 0.03) {
        light.intensity = 0;
      }
    });
  }

  /**
   * @private
   */
  _updateKeycard(delta) {
    if (this.keycard && !this.keycardPickedUp) {
      // Gentle float animation
      this.keycard.position.y = 0.9 + Math.sin(this.elapsedTime * 2) * 0.05;
      this.keycard.rotation.y += delta * 0.5;

      // Pulsing light
      const kLight = this.keycard.userData.light;
      if (kLight) {
        kLight.intensity = 0.3 + Math.sin(this.elapsedTime * 3) * 0.2;
      }
    }
  }

  /**
   * @private
   */
  _updateInteractionPrompts() {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera || this.interactables.length === 0) {
      this._hideInteractPrompt();
      return;
    }
    const origin = new THREE.Vector3();
    camera.getWorldPosition(origin);
    const dir = new THREE.Vector3();
    camera.getWorldDirection(dir);
    this.interactRaycaster.set(origin, dir);
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
   * @returns {THREE.Vector3}
   */
  getSpawnPoint() {
    return new THREE.Vector3(0, 1.6, 7);
  }

  dispose() {
    document.removeEventListener('keydown', this._onKeyDown);
    [this.interactPrompt, this.subtitleDisplay, this.dangerIndicator].forEach(el => {
      if (el && el.parentNode) el.parentNode.removeChild(el);
    });
    this.levelGroup.traverse(child => {
      if (child.isMesh) {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
          if (Array.isArray(child.material)) child.material.forEach(m => m.dispose());
          else child.material.dispose();
        }
      }
    });
    if (this.scene) { this.scene.remove(this.levelGroup); this.scene.fog = null; }
    this.interactables = [];
    this.hideSpots = [];
    this.bloodBags = [];
    this.roomLights = [];
    this._listeners = {};
    this.scene = null;
    this.assetLoader = null;
    console.log('[Level3] Disposed');
  }
}

/**
 * Level1_Awakening.js — 'The Awakening'
 * Player spawns in pitch black room. After 3 seconds, a light flickers on.
 * Find flashlight, walkie-talkie, discover cursed objects, then exit.
 * @module Level1_Awakening
 */

import * as THREE from 'three';

/**
 * Asset paths relative to the game/ directory
 * GLB files are in the repo root (one level up from game/)
 */
const ASSETS = {
  room: '/horror_room.glb',
  flashlight: '/horror_game_flashlight_download_game-ready.glb',
  walkieTalkie: '/psx-style_horror_walkie-talkie.glb',
  bloodBag: '/blood_bag.glb',
  devilsBible: '/devils_bible_-_dark_fantasy_book.glb',
  cursedDoll: '/cursed_porcelain_doll_-_antique_horror_prop.glb',
  bloodWall: '/abandoned_horror_wall_with_blood_splatter.glb',
  wallClock: '/vintage_wooden_wall_clock_-.glb',
  ceilingFan: '/old_rusty_ceiling_fan.glb',
  door: '/PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/house_door.glb'
};

/**
 * EventEmitter base for level events
 */
class LevelEventEmitter {
  constructor() {
    /** @private */
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
    if (this._listeners[event]) {
      this._listeners[event].forEach(cb => cb(data));
    }
  }
}

/**
 * Level 1: The Awakening
 * @extends LevelEventEmitter
 */
export class Level1_Awakening extends LevelEventEmitter {
  constructor() {
    super();

    /** @type {THREE.Scene|null} */
    this.scene = null;

    /** @type {object|null} */
    this.assetLoader = null;

    /** @type {THREE.Group} Level root group */
    this.levelGroup = new THREE.Group();
    this.levelGroup.name = 'Level1_Awakening';

    /** @type {object} Player inventory (set by LevelManager) */
    this.playerInventory = {};

    /** @type {object|null} Reference to LevelManager */
    this.levelManager = null;

    // --- Level state ---

    /** @type {number} Timer since level start */
    this.elapsedTime = 0;

    /** @type {boolean} Whether the initial light has flickered on */
    this.lightActivated = false;

    /** @type {THREE.PointLight|null} Main overhead flickering light */
    this.overheadLight = null;

    /** @type {number} Flicker timer */
    this.flickerTimer = 0;

    /** @type {boolean} Is the light currently flickering */
    this.isFlickering = false;

    /** @type {number} Flicker activation time (3 seconds) */
    this.flickerStartTime = 3.0;

    /** @type {number} Duration of initial flicker sequence */
    this.flickerDuration = 2.0;

    // --- Interactable objects ---

    /** @type {THREE.Object3D|null} */
    this.flashlightModel = null;

    /** @type {THREE.Object3D|null} */
    this.walkieTalkieModel = null;

    /** @type {THREE.Object3D|null} */
    this.bloodBagModel = null;

    /** @type {THREE.Object3D|null} */
    this.devilsBibleModel = null;

    /** @type {THREE.Object3D|null} */
    this.cursedDollModel = null;

    /** @type {THREE.Object3D|null} Ceiling fan model */
    this.ceilingFanModel = null;

    /** @type {THREE.Object3D|null} Exit door */
    this.exitDoor = null;

    /** @type {boolean} Whether flashlight has been picked up */
    this.flashlightPickedUp = false;

    /** @type {boolean} Whether walkie talkie has been picked up */
    this.walkieTalkiePickedUp = false;

    /** @type {boolean} Whether blood bag has been picked up */
    this.bloodBagPickedUp = false;

    /** @type {boolean} Whether walkie talkie message has played */
    this.walkieMessagePlayed = false;

    /** @type {THREE.Raycaster} For interaction detection */
    this.interactRaycaster = new THREE.Raycaster();
    this.interactRaycaster.far = 3.0;

    /** @type {Array<THREE.Object3D>} Interactable objects list */
    this.interactables = [];

    // --- UI ---
    /** @type {HTMLElement|null} Interaction prompt */
    this.interactPrompt = null;

    /** @type {HTMLElement|null} Subtitle display */
    this.subtitleDisplay = null;

    // Bind methods
    this._onKeyDown = this._onKeyDown.bind(this);
  }

  /**
   * Initialize the level — load assets and build the scene
   * @param {THREE.Scene} scene
   * @param {object} assetLoader
   * @returns {Promise<void>}
   */
  async init(scene, assetLoader) {
    this.scene = scene;
    this.assetLoader = assetLoader;

    // Create UI elements
    this._createUI();

    // Set up ambient environment
    this._setupEnvironment();

    // Load all assets
    await this._loadAssets();

    // Set up interactables
    this._setupInteractables();

    // Add level group to scene
    this.scene.add(this.levelGroup);

    // Keyboard listener for interactions
    document.addEventListener('keydown', this._onKeyDown);

    console.log('[Level1] The Awakening initialized');
  }

  /**
   * Create UI elements (interact prompt, subtitles)
   * @private
   */
  _createUI() {
    // Interaction prompt
    this.interactPrompt = document.createElement('div');
    this.interactPrompt.id = 'interact-prompt';
    Object.assign(this.interactPrompt.style, {
      position: 'fixed',
      bottom: '30%',
      left: '50%',
      transform: 'translateX(-50%)',
      color: '#cccccc',
      fontFamily: '"Courier New", monospace',
      fontSize: '0.9rem',
      padding: '8px 16px',
      backgroundColor: 'rgba(0,0,0,0.7)',
      border: '1px solid #333',
      borderRadius: '4px',
      display: 'none',
      zIndex: '100',
      textAlign: 'center'
    });
    document.body.appendChild(this.interactPrompt);

    // Subtitle display for walkie-talkie
    this.subtitleDisplay = document.createElement('div');
    this.subtitleDisplay.id = 'subtitle-display';
    Object.assign(this.subtitleDisplay.style, {
      position: 'fixed',
      bottom: '15%',
      left: '50%',
      transform: 'translateX(-50%)',
      color: '#ff4444',
      fontFamily: '"Courier New", monospace',
      fontSize: '1.1rem',
      padding: '12px 24px',
      backgroundColor: 'rgba(0,0,0,0.85)',
      border: '1px solid #8B0000',
      borderRadius: '4px',
      display: 'none',
      zIndex: '100',
      textAlign: 'center',
      maxWidth: '600px',
      textShadow: '0 0 8px #ff0000'
    });
    document.body.appendChild(this.subtitleDisplay);
  }

  /**
   * Set up the initial dark environment
   * @private
   */
  _setupEnvironment() {
    // Atmospheric ambient light — visible horror silhouettes
    this.ambientLight = new THREE.AmbientLight(0x40353c, 0.75);
    this.levelGroup.add(this.ambientLight);

    // Sky/ground bounce light
    this.hemiLight = new THREE.HemisphereLight(0x4a4050, 0x181414, 0.65);
    this.levelGroup.add(this.hemiLight);

    // Overhead hanging bulb — active, eerie flickering light
    this.overheadLight = new THREE.PointLight(0xffddaa, 3.5, 18, 1.2);
    this.overheadLight.position.set(0, 2.7, 0);
    this.overheadLight.castShadow = true;
    this.overheadLight.shadow.mapSize.set(1024, 1024);
    this.overheadLight.shadow.bias = -0.002;
    this.levelGroup.add(this.overheadLight);
    this.lightActivated = true;

    // Secondary dim cold cyan accent light in dark corner
    this.accentLight = new THREE.PointLight(0x336688, 1.5, 12, 1.5);
    this.accentLight.position.set(-2.2, 2.0, -1.8);
    this.levelGroup.add(this.accentLight);

    // Spotlight highlighting the flashlight table
    this.tableSpot = new THREE.SpotLight(0xffeedd, 3.5, 8, Math.PI / 5, 0.5, 1.2);
    this.tableSpot.position.set(1.2, 2.8, -0.8);
    this.tableSpot.target.position.set(1.2, 0.88, -0.8);
    this.levelGroup.add(this.tableSpot);
    this.levelGroup.add(this.tableSpot.target);

    // Horror atmospheric fog (soft depth, not blinding)
    this.scene.fog = new THREE.FogExp2(0x0c080a, 0.015);

    // Solid floor and boundary walls so the scene is never void
    const floorMat = new THREE.MeshStandardMaterial({ color: 0x181414, roughness: 0.9 });
    const floorGeo = new THREE.PlaneGeometry(16, 16);
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = 0;
    floor.receiveShadow = true;
    this.levelGroup.add(floor);

    // Pedestal/table for flashlight (examination table)
    const tableMat = new THREE.MeshStandardMaterial({ color: 0x241a16, roughness: 0.8 });
    this.tableMesh = new THREE.Mesh(new THREE.BoxGeometry(1.2, 0.85, 0.8), tableMat);
    this.tableMesh.position.set(1.2, 0.425, -0.8);
    this.tableMesh.castShadow = true;
    this.tableMesh.receiveShadow = true;
    this.levelGroup.add(this.tableMesh);

    // Pedestal for walkie-talkie & blood bag (side medical desk)
    this.deskMesh = new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.85, 0.8), tableMat);
    this.deskMesh.position.set(-1.4, 0.425, -0.8);
    this.deskMesh.castShadow = true;
    this.deskMesh.receiveShadow = true;
    this.levelGroup.add(this.deskMesh);

    // Register colliders with Physics
    if (this.physics) {
      this.physics.clearColliders();
      this.physics.addCollider(floor, this.tableMesh, this.deskMesh);
      this.physics.eyeHeight = 1.6;
    }
  }

  /**
   * Load all level assets
   * @private
   * @returns {Promise<void>}
   */
  async _loadAssets() {
    const totalAssets = Object.keys(ASSETS).length;
    let loaded = 0;

    const loadModel = async (key, path, position, rotation, scale) => {
      try {
        const gltf = await this.assetLoader.load(path);
        const model = gltf.scene || gltf;
        if (position) model.position.copy(position);
        if (rotation) model.rotation.set(rotation.x, rotation.y, rotation.z);
        if (scale) model.scale.set(scale, scale, scale);
        model.name = key;
        model.userData.levelObject = true;
        model.userData.assetKey = key;

        model.traverse(child => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
          }
        });

        this.levelGroup.add(model);
        loaded++;
        if (this.levelManager) {
          this.levelManager.updateLoadingProgress(loaded / totalAssets);
        }
        return model;
      } catch (err) {
        console.warn(`[Level1] Failed to load asset '${key}':`, err);
        loaded++;
        if (this.levelManager) {
          this.levelManager.updateLoadingProgress(loaded / totalAssets);
        }
        return null;
      }
    };

    // Load original horror room environment (1:1 scale, 6.07m x 3.30m x 6.71m)
    await loadModel('room', ASSETS.room,
      new THREE.Vector3(0, 0, 0), null, 1.0);

    // Flashlight on examination table (size ~20cm)
    this.flashlightModel = await loadModel('flashlight', ASSETS.flashlight,
      new THREE.Vector3(1.2, 0.88, -0.8),
      { x: 0, y: Math.PI * 0.4, z: 0 },
      0.1);

    // Walkie-talkie on side medical desk (size ~22cm)
    this.walkieTalkieModel = await loadModel('walkieTalkie', ASSETS.walkieTalkie,
      new THREE.Vector3(-1.4, 0.88, -0.8),
      { x: 0, y: -Math.PI * 0.3, z: 0 },
      0.12);

    // Real Blood Bag collectible pickup on medical desk (realistic IV bag ~29cm tall)
    this.bloodBagModel = await loadModel('bloodBag', ASSETS.bloodBag,
      new THREE.Vector3(-1.4, 0.88, -0.3),
      { x: Math.PI / 2, y: 0, z: 0.2 },
      0.01);

    // Devil's Bible on stand
    this.devilsBibleModel = await loadModel('devilsBible', ASSETS.devilsBible,
      new THREE.Vector3(2.0, 0.85, -2.0),
      { x: 0, y: Math.PI * 0.15, z: 0 },
      0.7);

    // Cursed porcelain doll
    this.cursedDollModel = await loadModel('cursedDoll', ASSETS.cursedDoll,
      new THREE.Vector3(-2.2, 0.45, -2.2),
      { x: 0, y: Math.PI * 0.2, z: 0 },
      0.4);

    // Blood splatter wall (aligned flush with right room wall)
    await loadModel('bloodWall', ASSETS.bloodWall,
      new THREE.Vector3(2.95, 1.25, 0),
      { x: 0, y: -Math.PI / 2, z: 0 },
      1.0);

    // Vintage wall clock mounted on north wall
    await loadModel('wallClock', ASSETS.wallClock,
      new THREE.Vector3(0, 2.2, -3.25),
      { x: 0, y: 0, z: 0 },
      0.6);

    // Ceiling fan rotating overhead
    this.ceilingFanModel = await loadModel('ceilingFan', ASSETS.ceilingFan,
      new THREE.Vector3(0, 2.8, 0),
      null, 0.9);

    // Exit door in north wall
    this.exitDoor = await loadModel('exitDoor', ASSETS.door,
      new THREE.Vector3(0, 0, -3.3),
      { x: 0, y: 0, z: 0 },
      1.0);
  }

  /**
   * Set up interactable object lists
   * @private
   */
  _setupInteractables() {
    this.interactables = [];

    if (this.flashlightModel) {
      this.flashlightModel.userData.interactable = true;
      this.flashlightModel.userData.interactType = 'pickup';
      this.flashlightModel.userData.interactLabel = 'Pick up Flashlight [E]';
      this.flashlightModel.userData.itemName = 'flashlight';
      this.interactables.push(this.flashlightModel);
    }

    if (this.walkieTalkieModel) {
      this.walkieTalkieModel.userData.interactable = true;
      this.walkieTalkieModel.userData.interactType = 'pickup';
      this.walkieTalkieModel.userData.interactLabel = 'Take Walkie-Talkie [E]';
      this.walkieTalkieModel.userData.itemName = 'walkieTalkie';
      this.interactables.push(this.walkieTalkieModel);
    }

    if (this.bloodBagModel) {
      this.bloodBagModel.userData.interactable = true;
      this.bloodBagModel.userData.interactType = 'pickup';
      this.bloodBagModel.userData.interactLabel = 'Take Blood Bag (+25 HP) [E]';
      this.bloodBagModel.userData.itemName = 'bloodBag';
      this.interactables.push(this.bloodBagModel);
    }

    if (this.devilsBibleModel) {
      this.devilsBibleModel.userData.interactable = true;
      this.devilsBibleModel.userData.interactType = 'examine';
      this.devilsBibleModel.userData.interactLabel = 'Examine Devil\'s Bible [E]';
      this.interactables.push(this.devilsBibleModel);
    }

    if (this.exitDoor) {
      this.exitDoor.userData.interactable = true;
      this.exitDoor.userData.interactType = 'exit';
      this.exitDoor.userData.interactLabel = 'Open Door [E]';
      this.interactables.push(this.exitDoor);
    }
  }

  /**
   * Handle key down events for interaction
   * @private
   * @param {KeyboardEvent} e
   */
  _onKeyDown(e) {
    if (e.code === 'KeyE') {
      this._tryInteract();
    }
  }

  /**
   * Attempt interaction with nearest object
   * @private
   */
  _tryInteract() {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera) return;

    // Cast ray from camera world position along camera gaze direction
    const origin = new THREE.Vector3();
    camera.getWorldPosition(origin);
    const dir = new THREE.Vector3(0, 0, -1);
    camera.getWorldDirection(dir);

    this.interactRaycaster.set(origin, dir);

    const intersects = this.interactRaycaster.intersectObjects(
      this.interactables, true
    );

    if (intersects.length === 0) return;

    // Find the root interactable
    let target = intersects[0].object;
    while (target && !target.userData.interactable) {
      target = target.parent;
    }
    if (!target) return;

    this._handleInteraction(target);
  }

  /**
   * Handle interaction with specific object
   * @private
   * @param {THREE.Object3D} target
   */
  _handleInteraction(target) {
    const type = target.userData.interactType;
    const itemName = target.userData.itemName;

    switch (type) {
      case 'pickup':
        if (itemName === 'flashlight' && !this.flashlightPickedUp) {
          this.flashlightPickedUp = true;
          this.playerInventory.hasFlashlight = true;
          this.emit('itemPickup', { item: 'flashlight', model: target });

          // Hide the model (picked up)
          target.visible = false;
          this._removeInteractable(target);

          this._showSubtitle('Flashlight acquired. Press [F] to toggle.', 3000);
          console.log('[Level1] Flashlight picked up');
        }
        if (itemName === 'walkieTalkie' && !this.walkieTalkiePickedUp) {
          this.walkieTalkiePickedUp = true;
          this.playerInventory.hasWalkieTalkie = true;
          this.emit('itemPickup', { item: 'walkieTalkie', model: target });

          target.visible = false;
          this._removeInteractable(target);

          // Play walkie-talkie message
          this._playWalkieMessage();
          console.log('[Level1] Walkie-talkie picked up');
        }
        if (itemName === 'bloodBag' && !this.bloodBagPickedUp) {
          this.bloodBagPickedUp = true;
          this.playerInventory.hasBloodBag = true;
          this.emit('itemPickup', { item: 'bloodBag', model: target });

          target.visible = false;
          this._removeInteractable(target);

          this._showSubtitle('Blood Bag acquired. Press [Q] anytime to heal (+25 HP).', 3500);
          console.log('[Level1] Blood bag picked up');
        }
        break;

      case 'examine':
        if (target.userData.assetKey === 'devilsBible') {
          this._showSubtitle(
            'The pages are covered in archaic symbols... You feel a chill down your spine.',
            4000
          );
          this.emit('triggerScare', { type: 'examine', object: 'devilsBible' });
          // Briefly flicker lights when examining the bible
          this._triggerBriefFlicker();
        }
        break;

      case 'exit':
        // Can only exit if flashlight and walkie-talkie are obtained
        if (this.flashlightPickedUp && this.walkieTalkiePickedUp) {
          this._showSubtitle('The door creaks open...', 2000);
          this.emit('exit', { nextLevel: 2 });
        } else {
          const missing = [];
          if (!this.flashlightPickedUp) missing.push('flashlight');
          if (!this.walkieTalkiePickedUp) missing.push('walkie-talkie');
          this._showSubtitle(
            `The door won't budge. You still need: ${missing.join(', ')}`,
            3000
          );
        }
        break;
    }
  }

  /**
   * Remove an object from the interactables list
   * @private
   * @param {THREE.Object3D} obj
   */
  _removeInteractable(obj) {
    this.interactables = this.interactables.filter(o => o !== obj);
  }

  /**
   * Play the walkie-talkie crackling message sequence
   * @private
   */
  _playWalkieMessage() {
    if (this.walkieMessagePlayed) return;
    this.walkieMessagePlayed = true;

    // Static crackle effect — subtitle sequence
    const messages = [
      { text: '*KSSSHH* ... *crackle*', delay: 0, duration: 1500 },
      { text: '"Get out..."', delay: 2000, duration: 2000 },
      { text: '"...before HE finds you."', delay: 4500, duration: 3000 },
      { text: '*KSSHH* — signal lost', delay: 8000, duration: 2000 }
    ];

    messages.forEach(msg => {
      setTimeout(() => {
        this._showSubtitle(msg.text, msg.duration);
      }, msg.delay);
    });

    // Trigger a scare event when the message plays
    setTimeout(() => {
      this.emit('triggerScare', { type: 'walkietalkie', intensity: 0.6 });
      this._triggerBriefFlicker();
    }, 4500);
  }

  /**
   * Show subtitle text for a duration
   * @private
   * @param {string} text
   * @param {number} duration - ms
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
          if (this.subtitleDisplay) {
            this.subtitleDisplay.style.display = 'none';
          }
        }, 500);
      }
    }, duration);
  }

  /**
   * Trigger a brief light flicker effect
   * @private
   */
  _triggerBriefFlicker() {
    if (!this.overheadLight || !this.lightActivated) return;
    const originalIntensity = this.overheadLight.intensity;
    let count = 0;
    const flickerInterval = setInterval(() => {
      this.overheadLight.intensity = Math.random() < 0.5 ? 0 : originalIntensity * 1.5;
      count++;
      if (count > 8) {
        clearInterval(flickerInterval);
        this.overheadLight.intensity = originalIntensity;
      }
    }, 80);
  }

  /**
   * Show interaction prompt
   * @private
   * @param {string} text
   */
  _showInteractPrompt(text) {
    if (!this.interactPrompt) return;
    this.interactPrompt.textContent = text;
    this.interactPrompt.style.display = 'block';
  }

  /**
   * Hide interaction prompt
   * @private
   */
  _hideInteractPrompt() {
    if (!this.interactPrompt) return;
    this.interactPrompt.style.display = 'none';
  }

  /**
   * Update the level every frame
   * @param {number} delta - Time since last frame in seconds
   */
  update(delta) {
    this.elapsedTime += delta;

    // --- Initial light flicker sequence (after 3 seconds) ---
    if (!this.lightActivated && this.elapsedTime >= this.flickerStartTime) {
      this._updateInitialFlicker(delta);
    }

    // --- Ceiling fan rotation ---
    if (this.ceilingFanModel && this.lightActivated) {
      this.ceilingFanModel.rotation.y += delta * 1.5;
    }

    // --- Cursed doll head tracking ---
    if (this.cursedDollModel && this.lightActivated) {
      this._updateDollTracking(delta);
    }

    // --- Interaction raycasting (show prompts) ---
    this._updateInteractionPrompts();

    // --- Ambient flicker (after light is on) ---
    if (this.lightActivated && this.overheadLight) {
      this.flickerTimer += delta;
      // Random micro-flicker
      if (Math.random() < 0.02) {
        const flicker = 0.85 + Math.random() * 0.3;
        this.overheadLight.intensity = 3.2 * flicker;
      }
    }

    // --- Red accent light pulsing ---
    if (this.accentLight && this.lightActivated) {
      this.accentLight.intensity = 1.2 + Math.sin(this.elapsedTime * 0.5) * 0.3;
    }
  }

  /**
   * Handle the initial light flicker-on sequence
   * @private
   * @param {number} delta
   */
  _updateInitialFlicker(delta) {
    const flickerElapsed = this.elapsedTime - this.flickerStartTime;

    if (flickerElapsed < this.flickerDuration) {
      // Flicker effect — random on/off
      const flickerRate = Math.min(flickerElapsed / this.flickerDuration, 1);
      if (Math.random() < flickerRate * 0.6) {
        this.overheadLight.intensity = 1.5 + Math.random() * 2.0;
      } else {
        this.overheadLight.intensity = 0.3;
      }
    } else {
      // Light stabilizes
      this.overheadLight.intensity = 3.2;
      this.ambientLight.intensity = 0.65;
      this.lightActivated = true;
      console.log('[Level1] Light flickered on');
      this.emit('triggerScare', { type: 'lightOn', intensity: 0.3 });
    }
  }

  /**
   * Update cursed doll to track the player's position
   * @private
   * @param {number} delta
   */
  _updateDollTracking(delta) {
    const camera = this.scene.getObjectByProperty('isCamera', true);
    if (!camera || !this.cursedDollModel) return;

    // Get doll head (try to find a head bone/mesh, otherwise rotate the whole model)
    const dollHead = this.cursedDollModel.getObjectByName('Head') ||
                     this.cursedDollModel.getObjectByName('head') ||
                     this.cursedDollModel;

    // Calculate direction to player
    const dollPos = new THREE.Vector3();
    this.cursedDollModel.getWorldPosition(dollPos);
    const playerPos = new THREE.Vector3();
    camera.getWorldPosition(playerPos);

    const direction = new THREE.Vector3()
      .subVectors(playerPos, dollPos)
      .normalize();

    // Smoothly rotate toward player (clamped, creepy slow turn)
    const targetAngle = Math.atan2(direction.x, direction.z);
    const currentAngle = dollHead.rotation.y;
    const angleDiff = targetAngle - currentAngle;

    // Normalize angle difference
    const normalizedDiff = ((angleDiff + Math.PI) % (2 * Math.PI)) - Math.PI;
    dollHead.rotation.y += normalizedDiff * delta * 0.8; // Slow, creepy tracking
  }

  /**
   * Update interaction prompts based on what player is looking at
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
    const dir = new THREE.Vector3(0, 0, -1);
    camera.getWorldDirection(dir);

    this.interactRaycaster.set(origin, dir);

    const intersects = this.interactRaycaster.intersectObjects(
      this.interactables, true
    );

    if (intersects.length > 0) {
      let target = intersects[0].object;
      while (target && !target.userData.interactable) {
        target = target.parent;
      }
      if (target && target.userData.interactLabel) {
        this._showInteractPrompt(target.userData.interactLabel);
        return;
      }
    }

    this._hideInteractPrompt();
  }

  /**
   * Get the player spawn point for this level
   * @returns {THREE.Vector3}
   */
  getSpawnPoint() {
    return new THREE.Vector3(0, 1.6, 2.0);
  }

  /**
   * Dispose of all level resources
   */
  dispose() {
    // Remove keyboard listener
    document.removeEventListener('keydown', this._onKeyDown);

    // Remove UI elements
    if (this.interactPrompt && this.interactPrompt.parentNode) {
      this.interactPrompt.parentNode.removeChild(this.interactPrompt);
    }
    if (this.subtitleDisplay && this.subtitleDisplay.parentNode) {
      this.subtitleDisplay.parentNode.removeChild(this.subtitleDisplay);
    }

    // Dispose of geometries and materials
    this.levelGroup.traverse(child => {
      if (child.isMesh) {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
          if (Array.isArray(child.material)) {
            child.material.forEach(m => m.dispose());
          } else {
            child.material.dispose();
          }
        }
      }
    });

    // Remove from scene
    if (this.scene) {
      this.scene.remove(this.levelGroup);
      this.scene.fog = null;
    }

    // Clear references
    this.interactables = [];
    this._listeners = {};
    this.scene = null;
    this.assetLoader = null;

    console.log('[Level1] Disposed');
  }
}

/**
 * @module InteractionSystem
 * Raycasting-based interaction system for THE LAST REVENGE.
 * Detects interactable objects within range and handles PICKUP, EXAMINE, USE, OPEN.
 */

import * as THREE from 'three';

/** Interaction types */
export const InteractionType = Object.freeze({
  PICKUP: 'PICKUP',
  EXAMINE: 'EXAMINE',
  USE: 'USE',
  OPEN: 'OPEN',
});

/**
 * @class InteractionSystem
 * Casts a ray from camera center each frame to detect nearby interactables.
 */
export class InteractionSystem {
  /**
   * @param {object} deps
   * @param {THREE.Camera} deps.camera
   * @param {THREE.Scene} deps.scene
   * @param {object} [deps.audioManager] - AudioManager for door creak etc.
   */
  constructor({ camera, scene, audioManager = null }) {
    this.camera = camera;
    this.scene = scene;
    this.audioManager = audioManager;

    /** Maximum interaction distance in world units */
    this.maxDistance = 2;

    /** Registry of interactable objects: mesh.uuid → config */
    this._registry = new Map();

    /** Currently targeted interactable (or null) */
    this.currentTarget = null;

    /** Raycaster always shooting from screen center */
    this._raycaster = new THREE.Raycaster();
    this._raycaster.far = this.maxDistance;
    this._screenCenter = new THREE.Vector2(0, 0);

    // ── UI: prompt element ──
    this._prompt = document.getElementById('interact-prompt');
    if (!this._prompt) {
      this._prompt = document.createElement('div');
      this._prompt.id = 'interact-prompt';
      this._prompt.style.cssText =
        'position:fixed;top:55%;left:50%;transform:translateX(-50%);' +
        'z-index:100;font-size:0.8rem;color:#aaa;letter-spacing:0.15rem;' +
        'opacity:0;transition:opacity 0.3s;pointer-events:none;font-family:monospace;';
      document.body.appendChild(this._prompt);
    }

    // ── UI: document/note overlay ──
    this._noteOverlay = document.createElement('div');
    this._noteOverlay.id = 'note-overlay';
    this._noteOverlay.style.cssText =
      'position:fixed;inset:0;z-index:500;display:none;' +
      'align-items:center;justify-content:center;background:rgba(0,0,0,0.88);' +
      'cursor:pointer;';
    this._noteOverlay.innerHTML = `
      <div style="max-width:520px;padding:40px;background:#1a1a1a;border:1px solid #333;
        border-radius:4px;font-family:'Special Elite',monospace;color:#c8c8c8;
        font-size:1rem;line-height:1.7;white-space:pre-wrap;position:relative;">
        <span id="note-close" style="position:absolute;top:10px;right:16px;
          font-size:1.4rem;color:#666;cursor:pointer;">&times;</span>
        <div id="note-content"></div>
      </div>`;
    document.body.appendChild(this._noteOverlay);
    this._noteContent = document.getElementById('note-content');

    // Close note on click
    this._noteOverlay.addEventListener('click', () => this.closeNote());
    document.getElementById('note-close')?.addEventListener('click', () => this.closeNote());

    /** Callbacks */
    this.onInteract = null; // (target) => void
  }

  /* ────────────────────── Registration ────────────────────── */

  /**
   * Register an object as interactable.
   * @param {THREE.Object3D} mesh - The 3D object to make interactable.
   * @param {object} config
   * @param {string} config.type - InteractionType (PICKUP | EXAMINE | USE | OPEN).
   * @param {string} config.prompt - Custom prompt text, e.g. "Open drawer".
   * @param {string} [config.itemType] - For PICKUP, the ItemType to give.
   * @param {object} [config.itemData] - Extra data to pass with pickup.
   * @param {string} [config.noteText] - For EXAMINE, the text to display.
   * @param {Function} [config.onUse] - For USE/OPEN, custom callback.
   * @param {string} [config.sound] - Sound key to play on interact.
   */
  register(mesh, config) {
    mesh.userData._interactable = true;
    this._registry.set(mesh.uuid, { mesh, ...config });
  }

  /**
   * Unregister an interactable.
   * @param {THREE.Object3D} mesh
   */
  unregister(mesh) {
    mesh.userData._interactable = false;
    this._registry.delete(mesh.uuid);
  }

  /* ────────────────────── Update ────────────────────── */

  /**
   * Call every frame to update the raycast.
   */
  update() {
    this._raycaster.setFromCamera(this._screenCenter, this.camera);

    // Gather interactable meshes
    const interactables = [];
    for (const entry of this._registry.values()) {
      interactables.push(entry.mesh);
    }

    const hits = this._raycaster.intersectObjects(interactables, true);

    if (hits.length > 0) {
      // Walk up the parent chain to find the registered root
      let obj = hits[0].object;
      let targetConfig = null;
      while (obj) {
        if (this._registry.has(obj.uuid)) {
          targetConfig = this._registry.get(obj.uuid);
          break;
        }
        obj = obj.parent;
      }

      if (targetConfig) {
        this.currentTarget = targetConfig;
        this._showPrompt(targetConfig.prompt || this._defaultPrompt(targetConfig.type));
      } else {
        this._clearTarget();
      }
    } else {
      this._clearTarget();
    }
  }

  /* ────────────────────── Interact ────────────────────── */

  /**
   * Execute interaction with current target. Call when player presses E.
   * @returns {object|null} The target config if interaction happened.
   */
  interact() {
    if (!this.currentTarget) return null;
    const target = this.currentTarget;

    // Play sound
    if (target.sound && this.audioManager) {
      if (typeof this.audioManager.playSFX === 'function') {
        this.audioManager.playSFX(target.sound);
      }
    }

    switch (target.type) {
      case InteractionType.PICKUP:
        // Let external handler add to inventory
        break;

      case InteractionType.EXAMINE:
        if (target.noteText) this.showNote(target.noteText);
        break;

      case InteractionType.USE:
      case InteractionType.OPEN:
        if (typeof target.onUse === 'function') target.onUse(target);
        break;
    }

    if (this.onInteract) this.onInteract(target);
    return target;
  }

  /* ────────────────────── Door helpers ────────────────────── */

  /**
   * Register a door with open/close toggle.
   * @param {THREE.Object3D} doorMesh
   * @param {object} [opts]
   * @param {number} [opts.openAngle=Math.PI/2] - Rotation angle when open.
   * @param {string} [opts.sound='door_creak'] - Sound key.
   */
  registerDoor(doorMesh, { openAngle = Math.PI / 2, sound = 'door_creak' } = {}) {
    let isOpen = false;
    const closedRotY = doorMesh.rotation.y;

    this.register(doorMesh, {
      type: InteractionType.OPEN,
      prompt: 'Press E to open',
      sound,
      onUse: (target) => {
        isOpen = !isOpen;
        doorMesh.rotation.y = isOpen ? closedRotY + openAngle : closedRotY;
        target.prompt = isOpen ? 'Press E to close' : 'Press E to open';
      },
    });
  }

  /**
   * Register a drawer that slides open to reveal an item.
   * @param {THREE.Object3D} drawerMesh
   * @param {THREE.Vector3} openOffset - How far the drawer slides.
   * @param {object} [opts]
   */
  registerDrawer(drawerMesh, openOffset, { sound = 'drawer_open' } = {}) {
    let isOpen = false;
    const closedPos = drawerMesh.position.clone();

    this.register(drawerMesh, {
      type: InteractionType.OPEN,
      prompt: 'Press E to open drawer',
      sound,
      onUse: () => {
        isOpen = !isOpen;
        if (isOpen) {
          drawerMesh.position.copy(closedPos).add(openOffset);
        } else {
          drawerMesh.position.copy(closedPos);
        }
      },
    });
  }

  /* ────────────────────── Note overlay ────────────────────── */

  /**
   * Display a readable note/document overlay.
   * @param {string} text
   */
  showNote(text) {
    this._noteContent.textContent = text;
    this._noteOverlay.style.display = 'flex';
  }

  /** Close the note overlay. */
  closeNote() {
    this._noteOverlay.style.display = 'none';
  }

  /* ────────────────────── Prompt UI ────────────────────── */

  /** @private */
  _showPrompt(text) {
    this._prompt.textContent = `[E] ${text}`;
    this._prompt.classList.add('visible');
    this._prompt.style.opacity = '1';
  }

  /** @private */
  _clearTarget() {
    this.currentTarget = null;
    this._prompt.classList.remove('visible');
    this._prompt.style.opacity = '0';
  }

  /** @private */
  _defaultPrompt(type) {
    switch (type) {
      case InteractionType.PICKUP:
        return 'Pick up';
      case InteractionType.EXAMINE:
        return 'Examine';
      case InteractionType.USE:
        return 'Use';
      case InteractionType.OPEN:
        return 'Open';
      default:
        return 'Interact';
    }
  }

  /* ────────────────────── Cleanup ────────────────────── */

  dispose() {
    this._registry.clear();
    this._noteOverlay.remove();
    this.onInteract = null;
  }
}

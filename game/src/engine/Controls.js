/**
 * @fileoverview FPS Controls — PointerLock WASD + mouse look with head bob.
 *
 * Features:
 *   - PointerLock mouse look (pitch clamped ±85°)
 *   - WASD movement, Shift sprint, C crouch, E interact
 *   - Smooth head-bob synced to walk/run cadence
 *   - Fires 'footstep' and 'interact' custom events
 */

import * as THREE from 'three';

/** @typedef {'walk'|'sprint'|'crouch'|'idle'} MoveState */

export class FPSControls {
  /**
   * @param {THREE.Camera} camera
   * @param {HTMLElement} domElement — element to request pointer lock on
   */
  constructor(camera, domElement) {
    /** @type {THREE.Camera} */
    this.camera = camera;

    /** @type {HTMLElement} */
    this.domElement = domElement;

    /** Camera holder — move this, camera is a child. */
    this.yaw = new THREE.Object3D();
    this.yaw.add(camera);
    camera.position.set(0, 0, 0); // local offset handled by headBob

    /** @type {boolean} */
    this.enabled = false;

    // ── Input state ──
    /** @private */ this._keys = { forward: false, backward: false, left: false, right: false, sprint: false, crouch: false };
    /** @private */ this._mouseDX = 0;
    /** @private */ this._mouseDY = 0;

    // ── Movement tuning ──
    /** Walk speed (units/s) */
    this.walkSpeed = 4.0;
    /** Sprint speed (units/s) */
    this.sprintSpeed = 7.5;
    /** Crouch speed (units/s) */
    this.crouchSpeed = 2.0;
    /** Mouse sensitivity */
    this.sensitivity = 0.002;
    /** Standing eye height */
    this.standHeight = 1.7;
    /** Crouching eye height */
    this.crouchHeight = 1.0;

    // ── Head bob ──
    /** @private */ this._bobTimer = 0;
    /** @private */ this._bobAmount = 0.04;    // metres
    /** @private */ this._bobFreqWalk = 8;      // Hz
    /** @private */ this._bobFreqSprint = 12;

    // ── Footstep timing ──
    /** @private */ this._lastFootstep = 0;     // timer value at last step
    /** @private */ this._footstepInterval = Math.PI; // half-cycle

    // ── Pitch ──
    /** @private */ this._pitch = 0;

    // ── Current height (for smooth crouch) ──
    /** @private */ this._currentHeight = this.standHeight;

    // ── Velocity output (consumed by Physics) ──
    /** Direction the player wants to move (world space, un-normalized until physics). */
    this.velocity = new THREE.Vector3();

    // ── Interact state ──
    /** Whether interact key was pressed this frame. Reset after reading. */
    this.interactPressed = false;

    // ── Bind listeners ──
    this._onMouseMove = this._onMouseMove.bind(this);
    this._onKeyDown = this._onKeyDown.bind(this);
    this._onKeyUp = this._onKeyUp.bind(this);
    this._onLockChange = this._onLockChange.bind(this);

    document.addEventListener('pointerlockchange', this._onLockChange);
    document.addEventListener('keydown', this._onKeyDown);
    document.addEventListener('keyup', this._onKeyUp);
    document.addEventListener('mousemove', this._onMouseMove);
  }

  /* ── Pointer lock ── */

  /** Request pointer lock. */
  lock() {
    this.domElement.requestPointerLock();
  }

  /** Release pointer lock. */
  unlock() {
    document.exitPointerLock();
  }

  /** @returns {boolean} */
  get isLocked() {
    return document.pointerLockElement === this.domElement;
  }

  /* ── Update ── */

  /**
   * Call every frame.
   * @param {number} dt — delta time in seconds
   * @returns {{ moveState: MoveState, speed: number }} current movement info
   */
  update(dt) {
    if (!this.enabled) return { moveState: 'idle', speed: 0 };

    // ── Mouse look ──
    if (this.isLocked) {
      this.yaw.rotation.y -= this._mouseDX * this.sensitivity;
      this._pitch -= this._mouseDY * this.sensitivity;
      this._pitch = Math.max(-Math.PI * 85 / 180, Math.min(Math.PI * 85 / 180, this._pitch));
      this.camera.rotation.x = this._pitch;
    }
    this._mouseDX = 0;
    this._mouseDY = 0;

    // ── Movement direction (local space) ──
    const dir = new THREE.Vector3();
    if (this._keys.forward)  dir.z -= 1;
    if (this._keys.backward) dir.z += 1;
    if (this._keys.left)     dir.x -= 1;
    if (this._keys.right)    dir.x += 1;

    const isMoving = dir.lengthSq() > 0;
    if (isMoving) dir.normalize();

    // Determine move state & speed
    let moveState = /** @type {MoveState} */ ('idle');
    let speed = 0;

    if (isMoving) {
      if (this._keys.crouch) {
        moveState = 'crouch';
        speed = this.crouchSpeed;
      } else if (this._keys.sprint) {
        moveState = 'sprint';
        speed = this.sprintSpeed;
      } else {
        moveState = 'walk';
        speed = this.walkSpeed;
      }
    }

    // Convert to world space using yaw
    dir.applyQuaternion(this.yaw.quaternion);
    dir.y = 0; // keep movement horizontal
    this.velocity.copy(dir).multiplyScalar(speed);

    // ── Crouch height interpolation ──
    const targetH = this._keys.crouch ? this.crouchHeight : this.standHeight;
    this._currentHeight = THREE.MathUtils.lerp(this._currentHeight, targetH, 1 - Math.exp(-10 * dt));

    // ── Head bob ──
    let bobOffset = 0;
    if (isMoving && !this._keys.crouch) {
      const freq = moveState === 'sprint' ? this._bobFreqSprint : this._bobFreqWalk;
      this._bobTimer += dt * freq;
      bobOffset = Math.sin(this._bobTimer) * this._bobAmount;

      // Footstep event (fires at each half-cycle crossing)
      if (Math.floor(this._bobTimer / this._footstepInterval) !== Math.floor(this._lastFootstep / this._footstepInterval)) {
        this.domElement.dispatchEvent(new CustomEvent('footstep', { detail: { state: moveState } }));
      }
      this._lastFootstep = this._bobTimer;
    } else {
      // Damp bob timer toward 0
      this._bobTimer *= 0.9;
    }

    // Apply height + bob to yaw (which holds the camera)
    this.yaw.position.y = this._currentHeight + bobOffset;

    return { moveState, speed };
  }

  /** Dispose all event listeners. */
  dispose() {
    document.removeEventListener('pointerlockchange', this._onLockChange);
    document.removeEventListener('keydown', this._onKeyDown);
    document.removeEventListener('keyup', this._onKeyUp);
    document.removeEventListener('mousemove', this._onMouseMove);
  }

  /* ── Private event handlers ── */

  /** @private */
  _onLockChange() {
    this.enabled = this.isLocked;
  }

  /** @private */
  _onMouseMove(e) {
    if (!this.isLocked) return;
    this._mouseDX += e.movementX;
    this._mouseDY += e.movementY;
  }

  /** @private */
  _onKeyDown(e) {
    switch (e.code) {
      case 'KeyW': case 'ArrowUp':    this._keys.forward  = true; break;
      case 'KeyS': case 'ArrowDown':  this._keys.backward = true; break;
      case 'KeyA': case 'ArrowLeft':  this._keys.left     = true; break;
      case 'KeyD': case 'ArrowRight': this._keys.right    = true; break;
      case 'ShiftLeft': case 'ShiftRight': this._keys.sprint = true; break;
      case 'KeyC': this._keys.crouch = true; break;
      case 'KeyE':
        this.interactPressed = true;
        this.domElement.dispatchEvent(new CustomEvent('interact'));
        break;
    }
  }

  /** @private */
  _onKeyUp(e) {
    switch (e.code) {
      case 'KeyW': case 'ArrowUp':    this._keys.forward  = false; break;
      case 'KeyS': case 'ArrowDown':  this._keys.backward = false; break;
      case 'KeyA': case 'ArrowLeft':  this._keys.left     = false; break;
      case 'KeyD': case 'ArrowRight': this._keys.right    = false; break;
      case 'ShiftLeft': case 'ShiftRight': this._keys.sprint = false; break;
      case 'KeyC': this._keys.crouch = false; break;
    }
  }
}

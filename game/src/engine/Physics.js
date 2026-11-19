/**
 * @fileoverview Physics — Raycasting-based collision detection, gravity, ground check.
 *
 * No external physics library — uses Three.js Raycaster for:
 *   - Ground detection (downward ray)
 *   - Wall/obstacle collision (horizontal rays in movement direction)
 *   - Simple gravity with terminal velocity
 *   - Step-up for small ledges
 */

import * as THREE from 'three';

/** @typedef {{ grounded: boolean, position: THREE.Vector3 }} PhysicsState */

export class Physics {
  /**
   * @param {THREE.Scene} scene — scene containing collidable meshes
   */
  constructor(scene) {
    /** @type {THREE.Scene} */
    this.scene = scene;

    /** Gravity acceleration (m/s²). */
    this.gravity = -20;

    /** Terminal fall velocity (m/s). */
    this.terminalVelocity = -30;

    /** Player capsule radius for wall collision. */
    this.playerRadius = 0.35;

    /** Maximum step-up height. */
    this.stepHeight = 0.35;

    /** Height of the collision ray origin above feet. */
    this.wallCheckHeight = 0.8;

    /** Current vertical velocity. */
    this.verticalVelocity = 0;

    /** @type {boolean} */
    this.grounded = false;

    /** Objects to test collisions against. Set externally. */
    this.colliders = [];

    /** @private */
    this._raycaster = new THREE.Raycaster();

    /** @private Temp vectors to avoid per-frame allocation. */
    this._tempVec = new THREE.Vector3();
    this._tempDown = new THREE.Vector3(0, -1, 0);
  }

  /**
   * Register a mesh (or group of meshes) as a collider.
   * @param  {...THREE.Object3D} objects
   */
  addCollider(...objects) {
    for (const obj of objects) {
      obj.traverse((child) => {
        if (child.isMesh) {
          this.colliders.push(child);
        }
      });
    }
  }

  /**
   * Remove all colliders.
   */
  clearColliders() {
    this.colliders.length = 0;
  }

  /**
   * Step the physics simulation.
   * @param {THREE.Object3D} player — the player yaw/root object whose position is updated
   * @param {THREE.Vector3} moveVelocity — desired horizontal velocity from Controls (world space)
   * @param {number} dt — delta time (seconds)
   * @returns {PhysicsState}
   */
  update(player, moveVelocity, dt) {
    const pos = player.position;

    // ── Gravity ──
    if (!this.grounded) {
      this.verticalVelocity += this.gravity * dt;
      if (this.verticalVelocity < this.terminalVelocity) {
        this.verticalVelocity = this.terminalVelocity;
      }
    }

    // ── Desired displacement ──
    const dx = moveVelocity.x * dt;
    const dz = moveVelocity.z * dt;
    const dy = this.verticalVelocity * dt;

    // ── Wall collision (horizontal) ──
    if (Math.abs(dx) > 0.0001 || Math.abs(dz) > 0.0001) {
      const moveDir = this._tempVec.set(dx, 0, dz).normalize();
      const rayOrigin = new THREE.Vector3(pos.x, pos.y + this.wallCheckHeight, pos.z);

      this._raycaster.set(rayOrigin, moveDir);
      this._raycaster.far = this.playerRadius + Math.sqrt(dx * dx + dz * dz);
      this._raycaster.near = 0;

      const hits = this._raycaster.intersectObjects(this.colliders, false);
      if (hits.length > 0 && hits[0].distance < this.playerRadius + 0.05) {
        // Slide along surface: project move onto surface tangent
        const normal = hits[0].face ? hits[0].face.normal.clone().transformDirection(hits[0].object.matrixWorld).normalize() : new THREE.Vector3(0, 0, 0);
        normal.y = 0;
        if (normal.lengthSq() > 0.0001) {
          normal.normalize();
          const dot = moveDir.dot(normal);
          if (dot < 0) {
            // Remove normal component from move
            pos.x += (dx - normal.x * dot * Math.sqrt(dx * dx + dz * dz));
            pos.z += (dz - normal.z * dot * Math.sqrt(dx * dx + dz * dz));
          } else {
            pos.x += dx;
            pos.z += dz;
          }
        }
        // else: stuck, don't move
      } else {
        pos.x += dx;
        pos.z += dz;
      }
    }

    // ── Vertical movement + ground check ──
    pos.y += dy;

    // Ground ray from slightly above feet downward
    const groundOrigin = new THREE.Vector3(pos.x, pos.y + 0.5, pos.z);
    this._raycaster.set(groundOrigin, this._tempDown);
    this._raycaster.far = 1.0 + Math.abs(dy);
    this._raycaster.near = 0;

    const groundHits = this._raycaster.intersectObjects(this.colliders, false);
    if (groundHits.length > 0) {
      const groundY = groundHits[0].point.y;
      if (pos.y <= groundY + 0.05) {
        pos.y = groundY;
        this.verticalVelocity = 0;
        this.grounded = true;
      } else {
        this.grounded = false;
      }
    } else {
      this.grounded = false;
      // Failsafe floor at y = 0
      if (pos.y < 0) {
        pos.y = 0;
        this.verticalVelocity = 0;
        this.grounded = true;
      }
    }

    return { grounded: this.grounded, position: pos };
  }

  /**
   * Cast a ray from camera for interaction / looking detection.
   * @param {THREE.Camera} camera
   * @param {number} [maxDist=3] — interaction range (metres)
   * @returns {THREE.Intersection|null}
   */
  interactionRaycast(camera, maxDist = 3) {
    const dir = new THREE.Vector3(0, 0, -1).applyQuaternion(camera.getWorldQuaternion(new THREE.Quaternion()));
    const origin = camera.getWorldPosition(new THREE.Vector3());

    this._raycaster.set(origin, dir);
    this._raycaster.far = maxDist;
    this._raycaster.near = 0;

    const hits = this._raycaster.intersectObjects(this.colliders, false);
    return hits.length > 0 ? hits[0] : null;
  }
}

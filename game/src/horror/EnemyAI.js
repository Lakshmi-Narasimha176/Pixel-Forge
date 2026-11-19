/**
 * @module EnemyAI
 * Enemy behaviour state-machine for THE LAST REVENGE.
 * Supports Ghost, Butcher and Stalker archetypes.
 */

import * as THREE from 'three';

/** AI states */
export const AIState = Object.freeze({
  PATROL: 'PATROL',
  ALERT: 'ALERT',
  CHASE: 'CHASE',
  LOST: 'LOST',
});

/** Enemy type presets */
export const EnemyType = Object.freeze({
  GHOST: 'GHOST',
  BUTCHER: 'BUTCHER',
  STALKER: 'STALKER',
});

/** Type-specific config defaults */
const TYPE_DEFAULTS = {
  [EnemyType.GHOST]: {
    speed: 3.5,
    chaseSpeed: 6,
    sightRange: 18,
    fov: 120,
    hearingRadius: 12,
    damage: 30,
    oneHitKill: false,
    canTeleport: true,
    canPhaseWalls: true,
    teleportCooldown: 5,
    lostSearchTime: 4,
  },
  [EnemyType.BUTCHER]: {
    speed: 1.8,
    chaseSpeed: 3.2,
    sightRange: 14,
    fov: 90,
    hearingRadius: 8,
    damage: 100,
    oneHitKill: true,
    canTeleport: false,
    canPhaseWalls: false,
    teleportCooldown: Infinity,
    lostSearchTime: 8,
  },
  [EnemyType.STALKER]: {
    speed: 4,
    chaseSpeed: 7.5,
    sightRange: 22,
    fov: 100,
    hearingRadius: 15,
    damage: 25,
    oneHitKill: false,
    canTeleport: false,
    canPhaseWalls: false,
    teleportCooldown: Infinity,
    lostSearchTime: 12,
  },
};

/**
 * @class EnemyAI
 * Attach to any enemy mesh to give it patrolling / chasing behaviour.
 */
export class EnemyAI {
  /**
   * @param {object} opts
   * @param {THREE.Object3D} opts.mesh - The enemy 3D object.
   * @param {string} opts.type - One of EnemyType.
   * @param {THREE.Vector3[]} opts.waypoints - Patrol waypoints.
   * @param {THREE.Scene} opts.scene - The scene (used for raycasting).
   * @param {object} [opts.overrides] - Override any type-default config field.
   */
  constructor({ mesh, type, waypoints, scene, overrides = {} }) {
    this.mesh = mesh;
    this.type = type;
    this.scene = scene;
    this.waypoints = waypoints.length ? waypoints : [mesh.position.clone()];

    // Merge defaults with overrides
    const cfg = { ...TYPE_DEFAULTS[type], ...overrides };
    this.speed = cfg.speed;
    this.chaseSpeed = cfg.chaseSpeed;
    this.sightRange = cfg.sightRange;
    this.fov = cfg.fov;
    this.hearingRadius = cfg.hearingRadius;
    this.damage = cfg.damage;
    this.oneHitKill = cfg.oneHitKill;
    this.canTeleport = cfg.canTeleport;
    this.canPhaseWalls = cfg.canPhaseWalls;
    this.teleportCooldown = cfg.teleportCooldown;
    this.lostSearchTime = cfg.lostSearchTime;

    // State
    this.state = AIState.PATROL;
    this._waypointIndex = 0;
    this._lostTimer = 0;
    this._alertTimer = 0;
    this._teleportTimer = 0;
    this._lastKnownPlayerPos = new THREE.Vector3();
    this._direction = new THREE.Vector3();

    // Reusable helpers
    this._raycaster = new THREE.Raycaster();
    this._vecA = new THREE.Vector3();
    this._vecB = new THREE.Vector3();

    /** Callback fired when enemy attacks player */
    this.onAttackPlayer = null;
    /** Callback fired on state change */
    this.onStateChange = null;
  }

  /* ────────────────────── Public ────────────────────── */

  /**
   * Main update — call every frame.
   * @param {number} delta - Seconds since last frame.
   * @param {THREE.Vector3} playerPos - Player world position.
   * @param {boolean} playerRunning - Whether the player is sprinting.
   * @param {THREE.Object3D[]} obstacles - Collidable meshes for LOS checks.
   */
  update(delta, playerPos, playerRunning, obstacles) {
    this._teleportTimer += delta;

    const canSee = this._checkLineOfSight(playerPos, obstacles);
    const canHear = this._checkHearing(playerPos, playerRunning);

    switch (this.state) {
      case AIState.PATROL:
        this._patrol(delta);
        if (canSee) this._transition(AIState.CHASE, playerPos);
        else if (canHear) this._transition(AIState.ALERT, playerPos);
        break;

      case AIState.ALERT:
        this._investigate(delta);
        if (canSee) this._transition(AIState.CHASE, playerPos);
        this._alertTimer += delta;
        if (this._alertTimer > 5) this._transition(AIState.PATROL);
        break;

      case AIState.CHASE:
        this._chase(delta, playerPos);
        if (!canSee && !canHear) this._transition(AIState.LOST, playerPos);
        // Ghost teleport
        if (this.canTeleport && this._teleportTimer >= this.teleportCooldown) {
          this._teleportNearPlayer(playerPos);
          this._teleportTimer = 0;
        }
        // Attack check
        if (this.mesh.position.distanceTo(playerPos) < 1.8) {
          this._attackPlayer();
        }
        break;

      case AIState.LOST:
        this._search(delta);
        if (canSee) this._transition(AIState.CHASE, playerPos);
        else if (canHear) this._transition(AIState.ALERT, playerPos);
        this._lostTimer += delta;
        if (this._lostTimer > this.lostSearchTime) this._transition(AIState.PATROL);
        break;
    }

    // Look at movement direction
    if (this._direction.lengthSq() > 0.001) {
      const target = this._vecA.copy(this.mesh.position).add(this._direction);
      target.y = this.mesh.position.y;
      this.mesh.lookAt(target);
    }
  }

  /* ────────────────────── State helpers ────────────────────── */

  /** @private */
  _transition(newState, playerPos) {
    const prev = this.state;
    this.state = newState;
    this._lostTimer = 0;
    this._alertTimer = 0;
    if (playerPos) this._lastKnownPlayerPos.copy(playerPos);
    if (this.onStateChange) this.onStateChange(prev, newState);
  }

  /* ────────────────────── Behaviours ────────────────────── */

  /** Walk toward the next waypoint. */
  _patrol(delta) {
    const wp = this.waypoints[this._waypointIndex];
    this._moveToward(wp, this.speed, delta);
    if (this.mesh.position.distanceTo(wp) < 0.5) {
      this._waypointIndex = (this._waypointIndex + 1) % this.waypoints.length;
    }
  }

  /** Move toward last-known player position. */
  _investigate(delta) {
    this._moveToward(this._lastKnownPlayerPos, this.speed * 0.75, delta);
  }

  /** Pursue the player. */
  _chase(delta, playerPos) {
    this._moveToward(playerPos, this.chaseSpeed, delta);
    this._lastKnownPlayerPos.copy(playerPos);
  }

  /** Wander around last-known position. */
  _search(delta) {
    // Simple random wander around last known pos
    const angle = Math.sin(this._lostTimer * 2) * Math.PI;
    const offset = this._vecA.set(Math.cos(angle) * 3, 0, Math.sin(angle) * 3);
    const target = this._vecB.copy(this._lastKnownPlayerPos).add(offset);
    this._moveToward(target, this.speed * 0.5, delta);
  }

  /** Move the mesh toward a target position. */
  _moveToward(target, speed, delta) {
    this._direction.subVectors(target, this.mesh.position);
    this._direction.y = 0; // keep on ground plane
    const dist = this._direction.length();
    if (dist < 0.1) {
      this._direction.set(0, 0, 0);
      return;
    }
    this._direction.normalize();
    const step = Math.min(speed * delta, dist);
    this.mesh.position.addScaledVector(this._direction, step);
  }

  /* ────────────────────── Perception ────────────────────── */

  /**
   * Line-of-sight check using raycasting.
   * @param {THREE.Vector3} playerPos
   * @param {THREE.Object3D[]} obstacles
   * @returns {boolean}
   */
  _checkLineOfSight(playerPos, obstacles) {
    const toPlayer = this._vecA.subVectors(playerPos, this.mesh.position);
    const dist = toPlayer.length();
    if (dist > this.sightRange) return false;

    // FOV check
    const forward = this._vecB.set(0, 0, -1).applyQuaternion(this.mesh.quaternion);
    const angle = forward.angleTo(toPlayer.normalize()) * (180 / Math.PI);
    if (angle > this.fov / 2) return false;

    // Ghost phases through walls — skip obstacle check
    if (this.canPhaseWalls) return true;

    // Raycast for obstructions
    this._raycaster.set(this.mesh.position, toPlayer.normalize());
    this._raycaster.far = dist;
    const hits = this._raycaster.intersectObjects(obstacles, true);
    return hits.length === 0;
  }

  /**
   * Hearing check: player footsteps within radius.
   * Running doubles the effective hearing distance.
   * @param {THREE.Vector3} playerPos
   * @param {boolean} running
   * @returns {boolean}
   */
  _checkHearing(playerPos, running) {
    const range = running ? this.hearingRadius * 2 : this.hearingRadius;
    return this.mesh.position.distanceTo(playerPos) <= range;
  }

  /* ────────────────────── Actions ────────────────────── */

  /** Ghost teleport: appear behind or to the side of the player. */
  _teleportNearPlayer(playerPos) {
    const angle = Math.random() * Math.PI * 2;
    const dist = 3 + Math.random() * 2;
    this.mesh.position.set(
      playerPos.x + Math.cos(angle) * dist,
      this.mesh.position.y,
      playerPos.z + Math.sin(angle) * dist
    );
  }

  /** Trigger the attack callback. */
  _attackPlayer() {
    if (this.onAttackPlayer) {
      this.onAttackPlayer(this.damage, this.oneHitKill);
    }
  }

  /* ────────────────────── Cleanup ────────────────────── */

  dispose() {
    this.onAttackPlayer = null;
    this.onStateChange = null;
  }
}

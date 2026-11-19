/**
 * @fileoverview LightingSystem — Dynamic horror lighting.
 *
 * Features:
 *   - Flashlight (SpotLight attached to camera) with shadow casting & battery drain
 *   - Flickering overhead lights (PointLight with Perlin-style noise)
 *   - Volumetric-style fog (Three.js FogExp2)
 *   - Light flicker system for scare events
 */

import * as THREE from 'three';

export class LightingSystem {
  /**
   * @param {THREE.Scene} scene
   * @param {THREE.Camera} camera
   */
  constructor(scene, camera) {
    /** @type {THREE.Scene} */
    this.scene = scene;

    /** @type {THREE.Camera} */
    this.camera = camera;

    // ── Ambient light (horror dim — enough to see outlines) ──
    /** @type {THREE.AmbientLight} */
    this.ambientLight = new THREE.AmbientLight(0x1a1030, 0.35);
    this.ambientLight.userData.persistent = true;
    scene.add(this.ambientLight);

    // ── Hemisphere light for realistic sky/ground bounce ──
    /** @type {THREE.HemisphereLight} */
    this.hemiLight = new THREE.HemisphereLight(0x1a0a2a, 0x0a0505, 0.25);
    this.hemiLight.userData.persistent = true;
    scene.add(this.hemiLight);

    // ── Fog (lighter so scene is visible) ──
    scene.fog = new THREE.FogExp2(0x060208, 0.025);

    // ── Flashlight ──
    /** @type {THREE.SpotLight} */
    this.flashlight = new THREE.SpotLight(0xfff5e0, 2.5, 25, Math.PI / 6, 0.4, 1.5);
    this.flashlight.castShadow = true;
    this.flashlight.shadow.mapSize.set(1024, 1024);
    this.flashlight.shadow.camera.near = 0.1;
    this.flashlight.shadow.camera.far = 25;
    this.flashlight.shadow.bias = -0.002;

    /** Flashlight target — positioned ahead of camera. */
    this.flashlightTarget = new THREE.Object3D();
    this.flashlightTarget.position.set(0, 0, -1);
    camera.add(this.flashlightTarget);
    camera.add(this.flashlight);
    this.flashlight.target = this.flashlightTarget;
    this.flashlight.position.set(0.15, -0.1, -0.2); // slightly offset like held in right hand

    /** @type {boolean} */
    this.flashlightOn = true;

    // ── Battery ──
    /** Battery level 0–1. */
    this.battery = 1.0;
    /** Battery drain rate per second. */
    this.batteryDrainRate = 0.008; // ~2 minutes full drain
    /** Battery recharge rate when off. */
    this.batteryRechargeRate = 0.0;
    /** Minimum battery before flickering. */
    this.batteryFlickerThreshold = 0.2;

    // ── Overhead flickering lights ──
    /** @type {Array<{ light: THREE.PointLight, baseIntensity: number, flickerSpeed: number, flickerAmount: number, offset: number }>} */
    this._flickerLights = [];

    // ── Scare flicker state ──
    /** @private */ this._scareFlicker = false;
    /** @private */ this._scareFlickerTimer = 0;
    /** @private */ this._scareFlickerDuration = 0;
    /** @private */ this._scareFlickerRate = 15; // Hz

    // ── Time accumulator ──
    /** @private */ this._time = 0;
  }

  /* ────────────────────────────────────────────────────────
   * Flashlight
   * ──────────────────────────────────────────────────────── */

  /** Toggle flashlight on/off. */
  toggleFlashlight() {
    this.flashlightOn = !this.flashlightOn;
  }

  /**
   * Set flashlight state.
   * @param {boolean} on
   */
  setFlashlight(on) {
    this.flashlightOn = on;
  }

  /**
   * Enable/disable flashlight (alias)
   * @param {boolean} on
   */
  setFlashlightEnabled(on) {
    this.flashlightOn = on;
  }

  /**
   * Set battery level.
   * @param {number} level — 0–1
   */
  setBattery(level) {
    this.battery = Math.max(0, Math.min(1, level));
  }

  /* ────────────────────────────────────────────────────────
   * Overhead / environment lights
   * ──────────────────────────────────────────────────────── */

  /**
   * Create a flickering overhead point light.
   * @param {THREE.Vector3} position
   * @param {Object} [opts]
   * @param {number} [opts.color=0xffcc88]
   * @param {number} [opts.intensity=1.5]
   * @param {number} [opts.distance=12]
   * @param {number} [opts.flickerSpeed=3]
   * @param {number} [opts.flickerAmount=0.5] — 0–1, how much intensity varies
   * @param {boolean} [opts.castShadow=false]
   * @returns {THREE.PointLight}
   */
  addFlickerLight(position, opts = {}) {
    const color     = opts.color ?? 0xffcc88;
    const intensity = opts.intensity ?? 1.5;
    const distance  = opts.distance ?? 12;

    const light = new THREE.PointLight(color, intensity, distance);
    light.position.copy(position);
    light.castShadow = opts.castShadow ?? false;

    if (light.castShadow) {
      light.shadow.mapSize.set(512, 512);
      light.shadow.bias = -0.002;
    }

    this.scene.add(light);

    this._flickerLights.push({
      light,
      baseIntensity: intensity,
      flickerSpeed:  opts.flickerSpeed ?? 3,
      flickerAmount: opts.flickerAmount ?? 0.5,
      offset:        Math.random() * 100, // desync each light
    });

    return light;
  }

  /**
   * Remove all flicker lights from the scene.
   */
  clearFlickerLights() {
    for (const entry of this._flickerLights) {
      this.scene.remove(entry.light);
      entry.light.dispose();
    }
    this._flickerLights.length = 0;
  }

  /* ────────────────────────────────────────────────────────
   * Fog
   * ──────────────────────────────────────────────────────── */

  /**
   * Set fog density.
   * @param {number} density
   */
  setFogDensity(density) {
    if (this.scene.fog) {
      this.scene.fog.density = density;
    }
  }

  /**
   * Set fog color.
   * @param {number|string} color
   */
  setFogColor(color) {
    if (this.scene.fog) {
      this.scene.fog.color.set(color);
    }
  }

  /* ────────────────────────────────────────────────────────
   * Scare events
   * ──────────────────────────────────────────────────────── */

  /**
   * Trigger a scare flicker — all lights rapidly strobe.
   * @param {number} [duration=1.5] — seconds
   * @param {number} [rate=15] — flicker rate Hz
   */
  triggerScareFlicker(duration = 1.5, rate = 15) {
    this._scareFlicker = true;
    this._scareFlickerTimer = 0;
    this._scareFlickerDuration = duration;
    this._scareFlickerRate = rate;
  }

  /* ────────────────────────────────────────────────────────
   * Update (call every frame)
   * ──────────────────────────────────────────────────────── */

  /**
   * @param {number} dt — delta time in seconds
   */
  update(dt) {
    this._time += dt;

    // ── Flashlight battery ──
    if (this.flashlightOn && this.battery > 0) {
      this.battery -= this.batteryDrainRate * dt;
      if (this.battery <= 0) {
        this.battery = 0;
        this.flashlightOn = false;
      }
    } else if (!this.flashlightOn && this.batteryRechargeRate > 0) {
      this.battery = Math.min(1, this.battery + this.batteryRechargeRate * dt);
    }

    // Flashlight intensity & flicker when low battery
    if (this.flashlightOn && this.battery > 0) {
      let intensity = 2.5;
      if (this.battery < this.batteryFlickerThreshold) {
        // Flicker when low
        const flick = Math.sin(this._time * 30) * Math.sin(this._time * 47) * Math.sin(this._time * 13);
        intensity *= 0.3 + 0.7 * (0.5 + 0.5 * flick) * (this.battery / this.batteryFlickerThreshold);
      }
      this.flashlight.intensity = intensity;
      this.flashlight.visible = true;
    } else {
      this.flashlight.visible = false;
    }

    // ── Scare flicker ──
    if (this._scareFlicker) {
      this._scareFlickerTimer += dt;
      if (this._scareFlickerTimer >= this._scareFlickerDuration) {
        this._scareFlicker = false;
      }
    }

    // ── Overhead flicker lights ──
    for (const entry of this._flickerLights) {
      let flicker;
      if (this._scareFlicker) {
        // Rapid strobe during scare
        flicker = Math.sin(this._time * this._scareFlickerRate * Math.PI * 2) > 0 ? 1 : 0.05;
        entry.light.intensity = entry.baseIntensity * flicker;
      } else {
        // Normal Perlin-ish noise flicker
        const t = this._time * entry.flickerSpeed + entry.offset;
        const noise = Math.sin(t * 1.1) * 0.5
                    + Math.sin(t * 2.3) * 0.25
                    + Math.sin(t * 5.7) * 0.15
                    + Math.sin(t * 11.3) * 0.1;
        const normalizedNoise = (noise + 1) / 2; // 0–1
        entry.light.intensity = entry.baseIntensity * (1 - entry.flickerAmount * (1 - normalizedNoise));
      }
    }
  }

  /**
   * Dispose all lights and cleanup.
   */
  dispose() {
    this.clearFlickerLights();
    this.scene.remove(this.ambientLight);
    this.ambientLight.dispose();
    if (this.hemiLight) {
      this.scene.remove(this.hemiLight);
      this.hemiLight.dispose();
    }
    this.flashlight.dispose();
  }
}

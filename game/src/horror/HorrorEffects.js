/**
 * @module HorrorEffects
 * Screen effects system for THE LAST REVENGE.
 * Manages sanity, jump scares, blood splatters, static noise, and heartbeat vignette.
 */

import * as THREE from 'three';

/** Sanity thresholds */
const SANITY_LOW = 40;
const SANITY_CRITICAL = 20;

/**
 * @class HorrorEffects
 * Handles all screen-level horror effects driven by game state.
 */
export class HorrorEffects {
  /**
   * @param {object} deps
   * @param {THREE.Camera} deps.camera
   * @param {object} [deps.audioManager] - AudioManager instance (optional)
   */
  constructor({ camera, audioManager = null }) {
    /** @type {THREE.Camera} */
    this.camera = camera;
    this.audioManager = audioManager;

    // ── Sanity ──
    /** Current sanity value 0-100 */
    this.sanity = 100;
    /** Rate at which sanity drains when triggered (units/sec) */
    this.sanityDrainRate = 5;
    /** Rate at which sanity recovers naturally (units/sec) */
    this.sanityRecoverRate = 1.5;
    /** Whether sanity is currently draining (set by external systems) */
    this.isDraining = false;

    // ── Health reference (set externally) ──
    this.health = 100;
    this.maxHealth = 100;

    // ── Shake state ──
    this._shakeIntensity = 0;
    this._shakeDuration = 0;
    this._shakeTimer = 0;
    this._origCamRot = new THREE.Euler();

    // ── Jump scare state ──
    this._jumpScareActive = false;
    this._jumpScareTimer = 0;
    this._jumpScareDuration = 0.6; // seconds

    // ── Blood splatter state ──
    this._bloodActive = false;
    this._bloodTimer = 0;
    this._bloodDuration = 1.8;

    // ── Static state ──
    this._staticActive = false;
    this._staticTimer = 0;
    this._staticDuration = 2.0;

    // ── Heartbeat ──
    this._heartbeatPhase = 0;

    // Build DOM overlays
    this._createOverlays();
  }

  /* ────────────────────── DOM Overlays ────────────────────── */

  _createOverlays() {
    // Container for all effect overlays
    this._container = document.createElement('div');
    this._container.id = 'horror-effects';
    this._container.style.cssText =
      'position:fixed;inset:0;z-index:90;pointer-events:none;overflow:hidden;';
    document.body.appendChild(this._container);

    // Vignette (always present, intensity varies)
    this._vignette = document.createElement('div');
    this._vignette.style.cssText =
      'position:absolute;inset:0;' +
      'background:radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.85) 100%);' +
      'transition:opacity 0.3s;';
    this._container.appendChild(this._vignette);

    // Heartbeat vignette (red pulse)
    this._heartbeatOverlay = document.createElement('div');
    this._heartbeatOverlay.style.cssText =
      'position:absolute;inset:0;opacity:0;' +
      'background:radial-gradient(ellipse at center, transparent 40%, rgba(139,0,0,0.6) 100%);' +
      'transition:opacity 0.08s;';
    this._container.appendChild(this._heartbeatOverlay);

    // Desaturation (CSS filter on canvas)
    // We apply filters to the canvas element directly
    this._canvas = document.querySelector('canvas');

    // Jump scare flash
    this._flashOverlay = document.createElement('div');
    this._flashOverlay.style.cssText =
      'position:absolute;inset:0;background:#fff;opacity:0;' +
      'transition:opacity 0.05s;pointer-events:none;';
    this._container.appendChild(this._flashOverlay);

    // Blood splatter
    this._bloodOverlay = document.createElement('div');
    this._bloodOverlay.style.cssText =
      'position:absolute;inset:0;opacity:0;pointer-events:none;' +
      'background:radial-gradient(circle at 30% 40%, rgba(139,0,0,0.7) 0%, transparent 60%),' +
      'radial-gradient(circle at 70% 60%, rgba(100,0,0,0.5) 0%, transparent 50%),' +
      'radial-gradient(circle at 50% 20%, rgba(160,0,0,0.4) 0%, transparent 55%);' +
      'transition:opacity 0.15s;';
    this._container.appendChild(this._bloodOverlay);

    // Static noise canvas
    this._staticCanvas = document.createElement('canvas');
    this._staticCanvas.width = 256;
    this._staticCanvas.height = 256;
    this._staticCanvas.style.cssText =
      'position:absolute;inset:0;width:100%;height:100%;opacity:0;' +
      'mix-blend-mode:screen;image-rendering:pixelated;pointer-events:none;' +
      'transition:opacity 0.2s;';
    this._staticCtx = this._staticCanvas.getContext('2d');
    this._container.appendChild(this._staticCanvas);

    // Blur / desaturation overlay (driven by low sanity)
    this._sanityFilter = document.createElement('div');
    this._sanityFilter.style.cssText =
      'position:absolute;inset:0;backdrop-filter:none;-webkit-backdrop-filter:none;' +
      'transition:backdrop-filter 0.5s;pointer-events:none;';
    this._container.appendChild(this._sanityFilter);
  }

  /* ────────────────────── Public API ────────────────────── */

  /**
   * Trigger a jump scare.
   * @param {string} [screamKey='scream'] - AudioManager key for the scream SFX.
   */
  triggerJumpScare(screamKey = 'scream') {
    this._jumpScareActive = true;
    this._jumpScareTimer = 0;
    // Flash
    this._flashOverlay.style.opacity = '1';
    // Camera shake
    this.shakeCamera(0.15, 0.5);
    // Audio
    if (this.audioManager && typeof this.audioManager.playSFX === 'function') {
      this.audioManager.playSFX(screamKey);
    }
  }

  /**
   * Show blood splatter overlay (call when player takes damage).
   */
  triggerBloodSplatter() {
    this._bloodActive = true;
    this._bloodTimer = 0;
    this._bloodOverlay.style.opacity = '1';
  }

  /**
   * Trigger screen static/noise for ghost encounters.
   * @param {number} [duration=2] Duration in seconds.
   */
  triggerStatic(duration = 2) {
    this._staticActive = true;
    this._staticTimer = 0;
    this._staticDuration = duration;
    this._staticCanvas.style.opacity = '0.35';
  }

  /**
   * Shake the camera.
   * @param {number} intensity
   * @param {number} duration Seconds
   */
  shakeCamera(intensity, duration) {
    this._shakeIntensity = intensity;
    this._shakeDuration = duration;
    this._shakeTimer = 0;
  }

  /**
   * Begin draining sanity (call while player is near threat).
   */
  startSanityDrain() {
    this.isDraining = true;
  }

  /**
   * Stop draining sanity.
   */
  stopSanityDrain() {
    this.isDraining = false;
  }

  /**
   * Set health (for heartbeat effect).
   * @param {number} hp
   * @param {number} maxHp
   */
  setHealth(hp, maxHp = 100) {
    this.health = hp;
    this.maxHealth = maxHp;
  }

  /* ────────────────────── Update Loop ────────────────────── */

  /**
   * Call every frame.
   * @param {number} delta - Seconds since last frame.
   */
  update(delta) {
    this._updateSanity(delta);
    this._updateShake(delta);
    this._updateJumpScare(delta);
    this._updateBlood(delta);
    this._updateStatic(delta);
    this._updateHeartbeat(delta);
    this._updateSanityVisuals();
  }

  /* ────────────────────── Internal ────────────────────── */

  _updateSanity(delta) {
    if (this.isDraining) {
      this.sanity = Math.max(0, this.sanity - this.sanityDrainRate * delta);
    } else {
      this.sanity = Math.min(100, this.sanity + this.sanityRecoverRate * delta);
    }
  }

  _updateSanityVisuals() {
    if (!this._canvas) {
      this._canvas = document.querySelector('canvas');
    }
    if (this.sanity < SANITY_LOW) {
      const t = 1 - this.sanity / SANITY_LOW; // 0-1 as sanity drops
      const blur = t * 3; // max 3px
      const sat = 1 - t * 0.7; // desaturate to 30%
      this._sanityFilter.style.backdropFilter = `blur(${blur}px) saturate(${sat})`;
      this._sanityFilter.style.webkitBackdropFilter = `blur(${blur}px) saturate(${sat})`;
    } else {
      this._sanityFilter.style.backdropFilter = 'none';
      this._sanityFilter.style.webkitBackdropFilter = 'none';
    }

    // Whisper audio at critical sanity
    if (this.sanity < SANITY_CRITICAL && this.audioManager) {
      if (typeof this.audioManager.playAmbient === 'function') {
        this.audioManager.playAmbient('whispers', { volume: 0.3, loop: true });
      }
    }
  }

  _updateShake(delta) {
    if (this._shakeTimer < this._shakeDuration) {
      this._shakeTimer += delta;
      const progress = this._shakeTimer / this._shakeDuration;
      const decay = 1 - progress;
      const intensity = this._shakeIntensity * decay;
      this.camera.rotation.x += (Math.random() - 0.5) * intensity;
      this.camera.rotation.y += (Math.random() - 0.5) * intensity;
    }
  }

  _updateJumpScare(delta) {
    if (!this._jumpScareActive) return;
    this._jumpScareTimer += delta;
    if (this._jumpScareTimer > 0.08) {
      this._flashOverlay.style.opacity = '0';
    }
    if (this._jumpScareTimer >= this._jumpScareDuration) {
      this._jumpScareActive = false;
    }
  }

  _updateBlood(delta) {
    if (!this._bloodActive) return;
    this._bloodTimer += delta;
    const fade = 1 - this._bloodTimer / this._bloodDuration;
    this._bloodOverlay.style.opacity = String(Math.max(0, fade));
    if (this._bloodTimer >= this._bloodDuration) {
      this._bloodActive = false;
      this._bloodOverlay.style.opacity = '0';
    }
  }

  _updateStatic(delta) {
    if (!this._staticActive) return;
    this._staticTimer += delta;
    // Generate noise
    const ctx = this._staticCtx;
    const w = this._staticCanvas.width;
    const h = this._staticCanvas.height;
    const imgData = ctx.createImageData(w, h);
    const d = imgData.data;
    for (let i = 0; i < d.length; i += 4) {
      const v = Math.random() * 255;
      d[i] = v;
      d[i + 1] = v;
      d[i + 2] = v;
      d[i + 3] = 180;
    }
    ctx.putImageData(imgData, 0, 0);

    if (this._staticTimer >= this._staticDuration) {
      this._staticActive = false;
      this._staticCanvas.style.opacity = '0';
    }
  }

  _updateHeartbeat(delta) {
    const hpRatio = this.health / this.maxHealth;
    if (hpRatio > 0.4) {
      this._heartbeatOverlay.style.opacity = '0';
      return;
    }
    // Heartbeat speed: faster as health drops
    const bpm = THREE.MathUtils.lerp(60, 160, 1 - hpRatio / 0.4);
    const freq = bpm / 60; // beats per second
    this._heartbeatPhase += delta * freq * Math.PI * 2;
    const pulse = Math.pow(Math.max(0, Math.sin(this._heartbeatPhase)), 4);
    const maxOpacity = THREE.MathUtils.lerp(0.15, 0.6, 1 - hpRatio / 0.4);
    this._heartbeatOverlay.style.opacity = String(pulse * maxOpacity);

    // Audio heartbeat
    if (pulse > 0.8 && this.audioManager) {
      if (typeof this.audioManager.playSFX === 'function') {
        this.audioManager.playSFX('heartbeat', { volume: 0.4 });
      }
    }
  }

  /* ────────────────────── Cleanup ────────────────────── */

  dispose() {
    this._container.remove();
  }
}

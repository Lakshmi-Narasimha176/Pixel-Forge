/**
 * @fileoverview AudioManager — Web Audio API spatial audio for horror game.
 *
 * Capabilities:
 *   - Four mix categories: AMBIENT, SFX, MUSIC, VOICE (independent volume)
 *   - Positional (3D) audio sources attached to scene objects
 *   - Ambient loops with crossfade
 *   - One-shot SFX with pooling
 *   - Convolver-based reverb for indoor spaces
 *   - Dynamic volume scaling based on horror intensity
 */

import * as THREE from 'three';

/**
 * Audio categories.
 * @enum {string}
 */
export const AudioCategory = /** @type {const} */ ({
  AMBIENT: 'AMBIENT',
  SFX:     'SFX',
  MUSIC:   'MUSIC',
  VOICE:   'VOICE',
});

export class AudioManager {
  /**
   * @param {THREE.Camera} camera — listener is attached here
   */
  constructor(camera) {
    /** @type {THREE.AudioListener} */
    this.listener = new THREE.AudioListener();
    camera.add(this.listener);

    /** @type {AudioContext} */
    this.ctx = this.listener.context;

    // ── Category volumes ──
    /** @type {Record<string, number>} */
    this._volumes = {
      [AudioCategory.AMBIENT]: 0.5,
      [AudioCategory.SFX]:     0.7,
      [AudioCategory.MUSIC]:   0.4,
      [AudioCategory.VOICE]:   1.0,
    };

    /** Master volume (0–1). */
    this._masterVolume = 1.0;

    /** Horror intensity multiplier (0–1). Higher = louder ambient, quieter music. */
    this._horrorIntensity = 0.0;

    // ── Category gain nodes ──
    /** @type {Record<string, GainNode>} */
    this._gainNodes = {};
    for (const cat of Object.values(AudioCategory)) {
      const gain = this.ctx.createGain();
      gain.gain.value = this._volumes[cat];
      gain.connect(this.ctx.destination);
      this._gainNodes[cat] = gain;
    }

    // ── Reverb (convolver) ──
    /** @type {ConvolverNode|null} */
    this._convolver = null;
    /** @type {GainNode} */
    this._reverbSend = this.ctx.createGain();
    this._reverbSend.gain.value = 0.3;
    // Will be connected when impulse is loaded

    /** @type {GainNode} */
    this._reverbWet = this.ctx.createGain();
    this._reverbWet.gain.value = 0.4;
    this._reverbWet.connect(this.ctx.destination);

    // ── Audio buffer cache ──
    /** @type {Map<string, AudioBuffer>} */
    this._buffers = new Map();

    // ── Active sources tracking ──
    /** @type {Map<string, THREE.Audio|THREE.PositionalAudio>} */
    this._activeSources = new Map();

    /** @private counter for unique source IDs */
    this._idCounter = 0;

    /** Base path for audio assets. */
    this.basePath = `${import.meta.env.BASE_URL}assets/audio/`;
  }

  /* ────────────────────────────────────────────────────────
   * Volume control
   * ──────────────────────────────────────────────────────── */

  /**
   * Set volume for a category.
   * @param {string} category — one of AudioCategory values
   * @param {number} volume — 0–1
   */
  setVolume(category, volume) {
    this._volumes[category] = Math.max(0, Math.min(1, volume));
    this._applyVolumes();
  }

  /**
   * Set master volume.
   * @param {number} volume — 0–1
   */
  setMasterVolume(volume) {
    this._masterVolume = Math.max(0, Math.min(1, volume));
    this._applyVolumes();
  }

  /**
   * Set horror intensity — affects dynamic volume scaling.
   * @param {number} intensity — 0–1
   */
  setHorrorIntensity(intensity) {
    this._horrorIntensity = Math.max(0, Math.min(1, intensity));
    this._applyVolumes();
  }

  /** @private */
  _applyVolumes() {
    const h = this._horrorIntensity;
    for (const cat of Object.values(AudioCategory)) {
      let vol = this._volumes[cat] * this._masterVolume;
      // Dynamic horror volume adjustments
      if (cat === AudioCategory.AMBIENT) {
        vol *= 1.0 + h * 0.5; // Ambient gets louder during horror
      } else if (cat === AudioCategory.MUSIC) {
        vol *= 1.0 - h * 0.3; // Music ducks slightly
      }
      this._gainNodes[cat].gain.setTargetAtTime(
        Math.min(vol, 1.5),
        this.ctx.currentTime,
        0.1
      );
    }
  }

  /* ────────────────────────────────────────────────────────
   * Loading
   * ──────────────────────────────────────────────────────── */

  /**
   * Load an audio file and cache the buffer.
   * @param {string} filename — relative to basePath
   * @returns {Promise<AudioBuffer>}
   */
  async loadSound(filename) {
    if (this._buffers.has(filename)) {
      return this._buffers.get(filename);
    }

    const url = this.basePath + filename;
    const response = await fetch(url);
    const arrayBuf = await response.arrayBuffer();
    const audioBuf = await this.ctx.decodeAudioData(arrayBuf);
    this._buffers.set(filename, audioBuf);
    return audioBuf;
  }

  /**
   * Load multiple sounds in parallel.
   * @param {string[]} filenames
   * @returns {Promise<void>}
   */
  async loadSounds(filenames) {
    await Promise.all(filenames.map((f) => this.loadSound(f)));
  }

  /* ────────────────────────────────────────────────────────
   * Reverb
   * ──────────────────────────────────────────────────────── */

  /**
   * Generate a synthetic impulse response for indoor reverb.
   * @param {number} [duration=2.5] — reverb tail in seconds
   * @param {number} [decay=3.0] — decay rate
   */
  generateReverb(duration = 2.5, decay = 3.0) {
    const sampleRate = this.ctx.sampleRate;
    const length = sampleRate * duration;
    const impulse = this.ctx.createBuffer(2, length, sampleRate);

    for (let ch = 0; ch < 2; ch++) {
      const data = impulse.getChannelData(ch);
      for (let i = 0; i < length; i++) {
        data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay);
      }
    }

    this._convolver = this.ctx.createConvolver();
    this._convolver.buffer = impulse;
    this._reverbSend.connect(this._convolver);
    this._convolver.connect(this._reverbWet);
  }

  /**
   * Set reverb wet amount.
   * @param {number} amount — 0–1
   */
  setReverbAmount(amount) {
    this._reverbWet.gain.setTargetAtTime(amount, this.ctx.currentTime, 0.1);
  }

  /* ────────────────────────────────────────────────────────
   * Playback — Non-positional (2D)
   * ──────────────────────────────────────────────────────── */

  /**
   * Play a one-shot sound effect (non-positional).
   * @param {string} filename — previously loaded via loadSound
   * @param {Object} [opts]
   * @param {string} [opts.category='SFX']
   * @param {number} [opts.volume=1]
   * @param {number} [opts.playbackRate=1]
   * @param {boolean} [opts.reverb=false]
   * @returns {string|null} source ID, or null if buffer not loaded
   */
  playOneShot(filename, opts = {}) {
    const buffer = this._buffers.get(filename);
    if (!buffer) {
      console.warn(`[AudioManager] Buffer not loaded: ${filename}`);
      return null;
    }

    const category = opts.category ?? AudioCategory.SFX;
    const audio = new THREE.Audio(this.listener);
    audio.setBuffer(buffer);
    audio.setVolume(opts.volume ?? 1);
    if (opts.playbackRate) audio.playbackRate = opts.playbackRate;

    // Route through category gain
    audio.gain.disconnect();
    audio.gain.connect(this._gainNodes[category]);

    // Optional reverb send
    if (opts.reverb && this._convolver) {
      audio.gain.connect(this._reverbSend);
    }

    audio.play();

    const id = `src_${this._idCounter++}`;
    this._activeSources.set(id, audio);

    // Cleanup when done
    audio.source?.addEventListener('ended', () => {
      this._activeSources.delete(id);
    });

    return id;
  }

  /**
   * Play a looping sound (ambient / music).
   * @param {string} filename
   * @param {Object} [opts]
   * @param {string} [opts.category='AMBIENT']
   * @param {number} [opts.volume=1]
   * @param {boolean} [opts.reverb=false]
   * @returns {string|null} source ID
   */
  playLoop(filename, opts = {}) {
    const buffer = this._buffers.get(filename);
    if (!buffer) {
      console.warn(`[AudioManager] Buffer not loaded: ${filename}`);
      return null;
    }

    const category = opts.category ?? AudioCategory.AMBIENT;
    const audio = new THREE.Audio(this.listener);
    audio.setBuffer(buffer);
    audio.setLoop(true);
    audio.setVolume(opts.volume ?? 1);

    audio.gain.disconnect();
    audio.gain.connect(this._gainNodes[category]);

    if (opts.reverb && this._convolver) {
      audio.gain.connect(this._reverbSend);
    }

    audio.play();

    const id = `src_${this._idCounter++}`;
    this._activeSources.set(id, audio);
    return id;
  }

  /* ────────────────────────────────────────────────────────
   * Playback — Positional (3D)
   * ──────────────────────────────────────────────────────── */

  /**
   * Play a positional 3D sound attached to a scene object.
   * @param {string} filename
   * @param {THREE.Object3D} object — the object the sound emanates from
   * @param {Object} [opts]
   * @param {string} [opts.category='SFX']
   * @param {number} [opts.volume=1]
   * @param {number} [opts.refDistance=5]
   * @param {number} [opts.maxDistance=50]
   * @param {boolean} [opts.loop=false]
   * @param {boolean} [opts.reverb=true]
   * @returns {string|null} source ID
   */
  playPositional(filename, object, opts = {}) {
    const buffer = this._buffers.get(filename);
    if (!buffer) {
      console.warn(`[AudioManager] Buffer not loaded: ${filename}`);
      return null;
    }

    const category = opts.category ?? AudioCategory.SFX;
    const audio = new THREE.PositionalAudio(this.listener);
    audio.setBuffer(buffer);
    audio.setVolume(opts.volume ?? 1);
    audio.setRefDistance(opts.refDistance ?? 5);
    audio.setMaxDistance(opts.maxDistance ?? 50);
    audio.setRolloffFactor(1.5);
    audio.setDistanceModel('exponential');
    audio.setLoop(opts.loop ?? false);

    // Route through category gain
    audio.gain.disconnect();
    audio.gain.connect(this._gainNodes[category]);

    if ((opts.reverb ?? true) && this._convolver) {
      audio.gain.connect(this._reverbSend);
    }

    object.add(audio);
    audio.play();

    const id = `src_${this._idCounter++}`;
    this._activeSources.set(id, audio);

    if (!opts.loop) {
      audio.source?.addEventListener('ended', () => {
        this._activeSources.delete(id);
        object.remove(audio);
      });
    }

    return id;
  }

  /* ────────────────────────────────────────────────────────
   * Source control
   * ──────────────────────────────────────────────────────── */

  /**
   * Stop a playing source by ID.
   * @param {string} id
   */
  stop(id) {
    const src = this._activeSources.get(id);
    if (src && src.isPlaying) {
      src.stop();
    }
    this._activeSources.delete(id);
  }

  /**
   * Stop all sounds in a category.
   * @param {string} category
   */
  stopCategory(category) {
    // All currently playing — we can't filter by category easily,
    // so stop everything routed to that gain node.
    for (const [id, src] of this._activeSources) {
      if (src.isPlaying) {
        try { src.stop(); } catch { /* already stopped */ }
      }
      this._activeSources.delete(id);
    }
  }

  /**
   * Stop all sounds.
   */
  stopAll() {
    for (const [id, src] of this._activeSources) {
      if (src.isPlaying) {
        try { src.stop(); } catch { /* already stopped */ }
      }
    }
    this._activeSources.clear();
  }

  /**
   * Resume the AudioContext after user gesture.
   * @returns {Promise<void>}
   */
  async resume() {
    if (this.ctx.state === 'suspended') {
      await this.ctx.resume();
    }
  }

  /**
   * Dispose all sources and disconnect nodes.
   */
  dispose() {
    this.stopAll();
    for (const gain of Object.values(this._gainNodes)) {
      gain.disconnect();
    }
    if (this._convolver) this._convolver.disconnect();
    this._reverbSend.disconnect();
    this._reverbWet.disconnect();
  }
}

/**
 * LevelManager.js — Level state machine with transitions
 * Manages loading, unloading, and transitioning between game levels
 * with fade-to-black screen transitions.
 * @module LevelManager
 */

import * as THREE from 'three';
import { Level1_Awakening } from './Level1_Awakening.js';
import { Level2_Corridor } from './Level2_Corridor.js';
import { Level3_Slaughterhouse } from './Level3_Slaughterhouse.js';
import { Level4_SovietRoom } from './Level4_SovietRoom.js';
import { Level5_Escape } from './Level5_Escape.js';

/**
 * @typedef {'IDLE'|'LOADING'|'TRANSITIONING'|'PLAYING'|'PAUSED'|'DEAD'|'COMPLETED'} LevelState
 */

/**
 * EventEmitter mixin for level events
 */
class EventEmitter {
  constructor() {
    /** @private */
    this._listeners = {};
  }

  /**
   * Register an event listener
   * @param {string} event
   * @param {Function} callback
   */
  on(event, callback) {
    if (!this._listeners[event]) this._listeners[event] = [];
    this._listeners[event].push(callback);
  }

  /**
   * Remove an event listener
   * @param {string} event
   * @param {Function} callback
   */
  off(event, callback) {
    if (!this._listeners[event]) return;
    this._listeners[event] = this._listeners[event].filter(cb => cb !== callback);
  }

  /**
   * Emit an event
   * @param {string} event
   * @param {*} data
   */
  emit(event, data) {
    if (!this._listeners[event]) return;
    this._listeners[event].forEach(cb => cb(data));
  }
}

/**
 * Manages game levels — loading, unloading, transitions, and the game state machine.
 * @extends EventEmitter
 */
export class LevelManager extends EventEmitter {
  /**
   * @param {THREE.Scene} scene - The main Three.js scene
   * @param {object} assetLoader - AssetLoader instance for loading GLB models
   * @param {object} [audioManager] - AudioManager instance for level audio
   * @param {object} [physics] - Physics instance
   */
  constructor(scene, assetLoader, audioManager = null, physics = null) {
    super();

    /** @type {THREE.Scene} */
    this.scene = scene;

    /** @type {object} */
    this.assetLoader = assetLoader;

    /** @type {object|null} */
    this.audioManager = audioManager;

    /** @type {object|null} */
    this.physics = physics;

    /** @type {LevelState} */
    this.state = 'IDLE';

    /** @type {object|null} Current active level instance */
    this.currentLevel = null;

    /** @type {number} Current level index (1-based) */
    this.currentLevelIndex = 0;

    /** @type {Map<number, Function>} Level constructors registry */
    this.levelRegistry = new Map();

    /** @type {HTMLElement} Fade overlay element */
    this.fadeOverlay = null;

    /** @type {number} Fade transition duration in ms */
    this.fadeDuration = 1500;

    /** @type {boolean} Whether a transition is in progress */
    this.isTransitioning = false;

    /** @type {HTMLElement} Loading screen element */
    this.loadingScreen = null;

    /** @type {object} Player inventory carried between levels */
    this.playerInventory = {
      hasFlashlight: false,
      hasWalkieTalkie: false,
      hasBaseballBat: false,
      hasBloodBag: false,
      hasKeycard: false,
      health: 100,
      flashlightBattery: 100
    };

    this._registerLevels();
    this._createFadeOverlay();
    this._createLoadingScreen();
  }

  /**
   * Register all game levels
   * @private
   */
  _registerLevels() {
    this.levelRegistry.set(1, Level1_Awakening);
    this.levelRegistry.set(2, Level2_Corridor);
    this.levelRegistry.set(3, Level3_Slaughterhouse);
    this.levelRegistry.set(4, Level4_SovietRoom);
    this.levelRegistry.set(5, Level5_Escape);
  }

  /**
   * Create the fade-to-black overlay DOM element
   * @private
   */
  _createFadeOverlay() {
    this.fadeOverlay = document.createElement('div');
    this.fadeOverlay.id = 'level-fade-overlay';
    Object.assign(this.fadeOverlay.style, {
      position: 'fixed',
      top: '0',
      left: '0',
      width: '100vw',
      height: '100vh',
      backgroundColor: '#000000',
      opacity: '0',
      pointerEvents: 'none',
      transition: `opacity ${this.fadeDuration}ms ease-in-out`,
      zIndex: '9998'
    });
    document.body.appendChild(this.fadeOverlay);
  }

  /**
   * Create the loading screen DOM element
   * @private
   */
  _createLoadingScreen() {
    this.loadingScreen = document.createElement('div');
    this.loadingScreen.id = 'level-loading-screen';
    Object.assign(this.loadingScreen.style, {
      position: 'fixed',
      top: '0',
      left: '0',
      width: '100vw',
      height: '100vh',
      backgroundColor: '#000000',
      display: 'none',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: '9999',
      fontFamily: '"Courier New", monospace',
      color: '#8B0000'
    });

    this.loadingScreen.innerHTML = `
      <div style="text-align:center;">
        <h2 id="level-title" style="font-size:2rem; margin-bottom:1rem; text-shadow:0 0 10px #ff0000;"></h2>
        <div style="width:300px; height:4px; background:#1a1a1a; border:1px solid #333; margin:0 auto;">
          <div id="level-progress-bar" style="width:0%; height:100%; background:linear-gradient(90deg,#8B0000,#ff0000); transition:width 0.3s;"></div>
        </div>
        <p id="level-loading-text" style="margin-top:0.5rem; font-size:0.8rem; color:#666;">Loading...</p>
      </div>
    `;
    document.body.appendChild(this.loadingScreen);
  }

  /**
   * Level name map for display
   * @private
   * @param {number} index
   * @returns {string}
   */
  _getLevelName(index) {
    const names = {
      1: 'Chapter 1: The Awakening',
      2: 'Chapter 2: The Corridor',
      3: 'Chapter 3: The Slaughterhouse',
      4: 'Chapter 4: The Soviet Room',
      5: 'Chapter 5: The Escape'
    };
    return names[index] || `Chapter ${index}`;
  }

  /**
   * Show loading screen with level name
   * @private
   * @param {number} levelIndex
   */
  _showLoadingScreen(levelIndex) {
    const titleEl = this.loadingScreen.querySelector('#level-title');
    const progressEl = this.loadingScreen.querySelector('#level-progress-bar');
    const textEl = this.loadingScreen.querySelector('#level-loading-text');

    titleEl.textContent = this._getLevelName(levelIndex);
    progressEl.style.width = '0%';
    textEl.textContent = 'Entering darkness...';
    this.loadingScreen.style.display = 'flex';
  }

  /**
   * Update loading progress bar
   * @param {number} progress - 0 to 1
   */
  updateLoadingProgress(progress) {
    const progressEl = this.loadingScreen.querySelector('#level-progress-bar');
    const textEl = this.loadingScreen.querySelector('#level-loading-text');
    if (progressEl) {
      progressEl.style.width = `${Math.round(progress * 100)}%`;
    }
    if (textEl) {
      const messages = [
        'Entering darkness...',
        'Summoning shadows...',
        'Something stirs...',
        'Preparing your nightmare...',
        'Almost there...'
      ];
      const msgIndex = Math.min(Math.floor(progress * messages.length), messages.length - 1);
      textEl.textContent = messages[msgIndex];
    }
  }

  /**
   * Hide loading screen
   * @private
   */
  _hideLoadingScreen() {
    this.loadingScreen.style.display = 'none';
  }

  /**
   * Fade the screen to black
   * @private
   * @returns {Promise<void>}
   */
  _fadeToBlack() {
    return new Promise(resolve => {
      this.fadeOverlay.style.pointerEvents = 'all';
      this.fadeOverlay.style.opacity = '1';
      setTimeout(resolve, this.fadeDuration);
    });
  }

  /**
   * Fade from black to transparent
   * @private
   * @returns {Promise<void>}
   */
  _fadeFromBlack() {
    return new Promise(resolve => {
      this.fadeOverlay.style.opacity = '0';
      setTimeout(() => {
        this.fadeOverlay.style.pointerEvents = 'none';
        resolve();
      }, this.fadeDuration);
    });
  }

  /**
   * Load and start a level by index
   * @param {number} levelIndex - 1-based level index
   * @returns {Promise<void>}
   */
  async loadLevel(levelIndex) {
    const LevelClass = this.levelRegistry.get(levelIndex);
    if (!LevelClass) {
      console.error(`[LevelManager] Level ${levelIndex} not found in registry`);
      return;
    }

    this.state = 'LOADING';
    this.emit('levelLoading', { levelIndex, name: this._getLevelName(levelIndex) });

    // Show loading screen
    this._showLoadingScreen(levelIndex);

    try {
      const level = new LevelClass();

      // Pass shared state
      level.playerInventory = this.playerInventory;
      level.levelManager = this;
      level.physics = this.physics;

      // Listen for level events
      this._bindLevelEvents(level);

      // Initialize the level (loads assets, builds scene)
      await level.init(this.scene, this.assetLoader);

      this.currentLevel = level;
      this.currentLevelIndex = levelIndex;

      // Hide loading, fade in
      this._hideLoadingScreen();
      await this._fadeFromBlack();

      this.state = 'PLAYING';
      this.emit('levelStarted', { levelIndex, name: this._getLevelName(levelIndex) });

      console.log(`[LevelManager] Level ${levelIndex} started: ${this._getLevelName(levelIndex)}`);
    } catch (err) {
      console.error(`[LevelManager] Failed to load level ${levelIndex}:`, err);
      this._hideLoadingScreen();
      this.state = 'IDLE';
      this.emit('levelError', { levelIndex, error: err });
    }
  }

  /**
   * Transition to the next level
   * @returns {Promise<void>}
   */
  async nextLevel() {
    const nextIndex = this.currentLevelIndex + 1;
    if (!this.levelRegistry.has(nextIndex)) {
      this.state = 'COMPLETED';
      this.emit('gameComplete', { finalLevel: this.currentLevelIndex });
      this.emit('victory', { finalLevel: this.currentLevelIndex });
      console.log('[LevelManager] All levels complete — game finished!');
      return;
    }
    await this.transitionTo(nextIndex);
  }

  /**
   * Transition from current level to target level with fade effect
   * @param {number} targetLevelIndex
   * @returns {Promise<void>}
   */
  async transitionTo(targetLevelIndex) {
    if (this.isTransitioning) {
      console.warn('[LevelManager] Transition already in progress');
      return;
    }

    this.isTransitioning = true;
    this.state = 'TRANSITIONING';
    this.emit('transitionStart', { from: this.currentLevelIndex, to: targetLevelIndex });

    // Fade to black
    await this._fadeToBlack();

    // Unload current level
    if (this.currentLevel) {
      this._unbindLevelEvents(this.currentLevel);
      this.currentLevel.dispose();
      this.currentLevel = null;
      // Clean up remaining objects from scene (except camera/lights we might want to keep)
      this._cleanScene();
    }

    // Load new level
    await this.loadLevel(targetLevelIndex);

    this.isTransitioning = false;
    this.emit('transitionComplete', { levelIndex: targetLevelIndex });
  }

  /**
   * Clean the scene of all level-specific objects
   * @private
   */
  _cleanScene() {
    // Levels dispose their own geometry. Only detach leftover top-level groups,
    // and never detach the player hierarchy or global lighting.
    const toRemove = this.scene.children.filter(child => {
      if (child.userData.persistent || child.isCamera) return false;
      return !child.getObjectByProperty('isCamera', true);
    });
    toRemove.forEach(obj => this.scene.remove(obj));
  }

  /**
   * Bind event listeners from a level instance
   * @private
   * @param {object} level
   */
  _bindLevelEvents(level) {
    if (level.on) {
      level.on('exit', () => this.nextLevel());
      level.on('itemPickup', (data) => this._handleItemPickup(data));
      level.on('healthChange', (data) => {
        this.playerInventory.health = Math.max(0, Math.min(100, data.health));
        this.emit('healthChange', { health: this.playerInventory.health, maxHealth: 100 });
      });
      level.on('playerDeath', () => this._handlePlayerDeath());
      level.on('victory', (data) => {
        this.state = 'COMPLETED';
        this.emit('victory', data);
      });
      level.on('triggerScare', (data) => this.emit('scare', data));
    }
  }

  /**
   * Unbind event listeners from a level instance
   * @private
   * @param {object} level
   */
  _unbindLevelEvents(level) {
    // Levels clean up their own listeners in dispose()
  }

  /**
   * Handle item pickup events from levels
   * @private
   * @param {object} data
   */
  _handleItemPickup(data) {
    switch (data.item) {
      case 'flashlight':
        this.playerInventory.hasFlashlight = true;
        break;
      case 'walkieTalkie':
        this.playerInventory.hasWalkieTalkie = true;
        break;
      case 'bloodBag':
        this.playerInventory.hasBloodBag = true;
        break;
      case 'baseballBat':
        this.playerInventory.hasBaseballBat = true;
        break;
      case 'keycard':
        this.playerInventory.hasKeycard = true;
        break;
    }
    this.emit('inventoryUpdate', this.playerInventory);
    this.emit('itemPickup', data);
  }

  /** Stop gameplay and let the death menu choose when to restart. */
  _handlePlayerDeath() {
    if (this.state === 'DEAD') return;
    this.state = 'DEAD';
    this.playerInventory.health = 0;
    this.emit('healthChange', { health: 0, maxHealth: 100 });
    this.emit('playerDeath', { levelIndex: this.currentLevelIndex });
  }

  /**
   * Get the current level's spawn point
   * @returns {THREE.Vector3}
   */
  getSpawnPoint() {
    if (this.currentLevel && this.currentLevel.getSpawnPoint) {
      return this.currentLevel.getSpawnPoint();
    }
    return new THREE.Vector3(0, 1.6, 0);
  }

  /**
   * Update the current level (called every frame)
   * @param {number} delta - Time since last frame in seconds
   */
  update(delta) {
    if (this.state === 'PLAYING' && this.currentLevel) {
      this.currentLevel.update(delta);
    }
  }

  /**
   * Pause the current level
   */
  pause() {
    if (this.state === 'PLAYING') {
      this.state = 'PAUSED';
      this.emit('levelPaused', { levelIndex: this.currentLevelIndex });
    }
  }

  /**
   * Resume the current level
   */
  resume() {
    if (this.state === 'PAUSED') {
      this.state = 'PLAYING';
      this.emit('levelResumed', { levelIndex: this.currentLevelIndex });
    }
  }

  /** Dispose the active level and reset all progress for a new run. */
  reset() {
    if (this.currentLevel) {
      this._unbindLevelEvents(this.currentLevel);
      this.currentLevel.dispose();
      this.currentLevel = null;
    }
    this._cleanScene();
    this.physics?.clearColliders();
    this.currentLevelIndex = 0;
    this.state = 'IDLE';
    this.isTransitioning = false;
    Object.assign(this.playerInventory, {
      hasFlashlight: false,
      hasWalkieTalkie: false,
      hasBaseballBat: false,
      hasBloodBag: false,
      hasKeycard: false,
      health: 100,
      flashlightBattery: 100,
    });
    this._hideLoadingScreen();
    this.fadeOverlay.style.opacity = '0';
    this.fadeOverlay.style.pointerEvents = 'none';
  }

  /**
   * Restart the current level
   * @returns {Promise<void>}
   */
  async restartLevel() {
    if (!this.currentLevelIndex) return this.loadLevel(1);
    this.playerInventory.health = 100;
    this.emit('healthChange', { health: 100, maxHealth: 100 });
    await this.transitionTo(this.currentLevelIndex);
  }

  /**
   * Dispose of the LevelManager and clean up
   */
  dispose() {
    if (this.currentLevel) {
      this.currentLevel.dispose();
      this.currentLevel = null;
    }
    this._cleanScene();
    if (this.fadeOverlay && this.fadeOverlay.parentNode) {
      this.fadeOverlay.parentNode.removeChild(this.fadeOverlay);
    }
    if (this.loadingScreen && this.loadingScreen.parentNode) {
      this.loadingScreen.parentNode.removeChild(this.loadingScreen);
    }
    this._listeners = {};
  }
}

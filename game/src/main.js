/**
 * @fileoverview main.js — Complete game initialization, scene management,
 * and game loop for THE LAST REVENGE.
 *
 * Integrates:
 *   - HorrorRenderer (post-processing with CRT/vignette/grain/chromatic aberration)
 *   - FPSControls (WASD, mouse, sprint, crouch, footstep events)
 *   - Physics (gravity, raycast collision, interaction)
 *   - AssetLoader (GLTF/GLB models caching & shadow setup)
 *   - AudioManager (spatial audio, horror stings, reverb)
 *   - LightingSystem (flashlight with battery drain, flickering lamps)
 *   - LevelManager (5 levels, transition animations, level state machine)
 *   - HorrorEffects (sanity drain, jump scares, blood splatter, heartbeat)
 *   - HUD (health, battery, crosshair, item bar, sanity indicator)
 *   - MenuSystem (main menu, pause, settings, death, victory)
 */

import * as THREE from 'three';
import { HorrorRenderer } from './engine/Renderer.js';
import { FPSControls } from './engine/Controls.js';
import { Physics } from './engine/Physics.js';
import { AssetLoader } from './engine/AssetLoader.js';
import { AudioManager, AudioCategory } from './engine/AudioManager.js';
import { LightingSystem } from './engine/LightingSystem.js';
import { LevelManager } from './levels/LevelManager.js';
import { HorrorEffects } from './horror/HorrorEffects.js';
import { Inventory, ItemType } from './horror/Inventory.js';
import { HUD } from './ui/HUD.js';
import { MenuSystem } from './ui/MenuSystem.js';

/* ────────────────────────────────────────────────────────
 * DOM References
 * ──────────────────────────────────────────────────────── */
const loadingScreen  = document.getElementById('loading-screen');
const loadingBar     = document.getElementById('loading-bar');
const loadingText    = document.getElementById('loading-text');
const startPrompt    = document.getElementById('start-prompt');
const interactPrompt = document.getElementById('interact-prompt');

/* ────────────────────────────────────────────────────────
 * Core Three.js Objects
 * ──────────────────────────────────────────────────────── */
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x020204);

const camera = new THREE.PerspectiveCamera(72, window.innerWidth / window.innerHeight, 0.05, 120);

/* ────────────────────────────────────────────────────────
 * Engine Subsystems
 * ──────────────────────────────────────────────────────── */
const horrorRenderer = new HorrorRenderer(document.body);
const canvas         = horrorRenderer.getDomElement();

const controls       = new FPSControls(camera, canvas);
scene.add(controls.yaw);
controls.yaw.position.set(0, 1.7, 5);

const physics        = new Physics(scene);
const assetLoader    = new AssetLoader({
  onProgress: (p) => {
    if (loadingBar) loadingBar.style.width = `${Math.round(p * 100)}%`;
    if (loadingText) loadingText.textContent = `LOADING ASSETS... ${Math.round(p * 100)}%`;
  },
  onComplete: () => {
    if (loadingText) loadingText.textContent = 'SYSTEM READY';
  },
});

const audioManager   = new AudioManager(camera);
const lighting       = new LightingSystem(scene, camera);

// Gameplay systems
const inventory      = new Inventory();
const horrorEffects  = new HorrorEffects({ camera, audioManager });
const hud            = new HUD({ inventory, horrorEffects });
const levelManager   = new LevelManager(scene, assetLoader, audioManager);

let gameStarted = false;
let isPaused = false;

/* ────────────────────────────────────────────────────────
 * Menu System
 * ──────────────────────────────────────────────────────── */
const menuSystem = new MenuSystem({
  onNewGame: async () => {
    await startNewGame();
  },
  onRestart: async () => {
    await restartCurrentGame();
  },
  onResume: () => {
    isPaused = false;
    controls.lock();
    levelManager.resume();
  },
  audioManager
});

/* ────────────────────────────────────────────────────────
 * Window Resize
 * ──────────────────────────────────────────────────────── */
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
});

/* ────────────────────────────────────────────────────────
 * Input & Hotkeys
 * ──────────────────────────────────────────────────────── */
document.addEventListener('keydown', (e) => {
  // Flashlight toggle (F key)
  if (e.code === 'KeyF') {
    if (inventory.hasItem(ItemType.FLASHLIGHT)) {
      lighting.toggleFlashlight();
    }
  }

  // Inventory Quick-use / Melee swing
  if (e.code === 'Digit1') inventory.selectSlot(0);
  if (e.code === 'Digit2') inventory.selectSlot(1);
  if (e.code === 'Digit3') inventory.selectSlot(2);
  if (e.code === 'Digit4') inventory.selectSlot(3);
  if (e.code === 'Digit5') inventory.selectSlot(4);

  // Consume blood bag / heal (Q key)
  if (e.code === 'KeyQ') {
    if (inventory.hasItem(ItemType.BLOOD_BAG)) {
      inventory.useItem();
      hud.showSubtitle('+25 HP restored from Blood Bag.', 2500);
    }
  }

  // Pause menu (Escape key)
  if (e.code === 'Escape') {
    if (gameStarted && menuSystem.activeScreen === 'none') {
      isPaused = true;
      levelManager.pause();
      controls.unlock();
      menuSystem.showPause();
    }
  }
});

/* ────────────────────────────────────────────────────────
 * Footstep Audio Trigger
 * ──────────────────────────────────────────────────────── */
canvas.addEventListener('footstep', () => {
  // Synthesize or trigger footstep sound in indoor reverb
  if (audioManager && audioManager.ctx) {
    try {
      const osc = audioManager.ctx.createOscillator();
      const gain = audioManager.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(60, audioManager.ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(30, audioManager.ctx.currentTime + 0.12);
      gain.gain.setValueAtTime(0.15, audioManager.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, audioManager.ctx.currentTime + 0.12);
      osc.connect(gain);
      gain.connect(audioManager.ctx.destination);
      osc.start();
      osc.stop(audioManager.ctx.currentTime + 0.13);
    } catch (err) {
      // Audio context might be restricted
    }
  }
});

/* ────────────────────────────────────────────────────────
 * Level Events Wiring
 * ──────────────────────────────────────────────────────── */
levelManager.on('levelStarted', ({ levelIndex, name }) => {
  console.log(`[Game] Level ${levelIndex} (${name}) loaded.`);
  const spawn = levelManager.getSpawnPoint();
  if (spawn) {
    controls.yaw.position.copy(spawn);
  }
  hud.showSubtitle(`ENTERING: ${name}`, 4000);
});

levelManager.on('scare', (data) => {
  const intensity = data?.intensity || 0.8;
  horrorEffects.triggerJumpScare();
  horrorRenderer.triggerScare(intensity);
});

levelManager.on('playerDeath', () => {
  console.log('[Game] Player succumbed to the horrors.');
  horrorEffects.triggerBloodSplatter();
  controls.unlock();
  menuSystem.showDeath();
});

levelManager.on('victory', () => {
  console.log('[Game] Player escaped!');
  controls.unlock();
  menuSystem.showVictory();
});

levelManager.on('inventoryUpdate', (inv) => {
  if (inv.hasFlashlight && !inventory.hasItem(ItemType.FLASHLIGHT)) {
    inventory.addItem(ItemType.FLASHLIGHT);
    lighting.setFlashlightEnabled(true);
  }
  if (inv.hasWalkieTalkie && !inventory.hasItem(ItemType.WALKIE_TALKIE)) {
    inventory.addItem(ItemType.WALKIE_TALKIE);
  }
  if (inv.hasBaseballBat && !inventory.hasItem(ItemType.BASEBALL_BAT)) {
    inventory.addItem(ItemType.BASEBALL_BAT);
  }
  if (inv.hasKeycard && !inventory.hasItem(ItemType.KEYCARD)) {
    inventory.addItem(ItemType.KEYCARD);
  }
});

/* ────────────────────────────────────────────────────────
 * Start Game & Restart Handlers
 * ──────────────────────────────────────────────────────── */
async function startNewGame() {
  menuSystem.hide();
  hud.show();

  await audioManager.resume();
  audioManager.generateReverb(2.8, 3.5);

  controls.lock();
  gameStarted = true;
  isPaused = false;

  // Load Level 1: The Awakening
  await levelManager.loadLevel(1);

  const spawn = levelManager.getSpawnPoint();
  if (spawn) controls.yaw.position.copy(spawn);

  startGameLoop();
}

async function restartCurrentGame() {
  menuSystem.hide();
  hud.show();
  controls.lock();
  isPaused = false;

  await levelManager.restartLevel();
  const spawn = levelManager.getSpawnPoint();
  if (spawn) controls.yaw.position.copy(spawn);
}

/* ────────────────────────────────────────────────────────
 * Game Loop
 * ──────────────────────────────────────────────────────── */
const clock = new THREE.Clock();
let running = false;

function startGameLoop() {
  if (running) return;
  running = true;
  clock.start();
  requestAnimationFrame(tick);
}

function tick() {
  requestAnimationFrame(tick);

  const dt = Math.min(clock.getDelta(), 0.05);

  if (gameStarted && !isPaused && menuSystem.activeScreen === 'none') {
    // ── Update controls & movement ──
    controls.update(dt);

    // ── Update physics / collisions ──
    physics.update(controls.yaw, controls.velocity, dt);

    // ── Update active level ──
    levelManager.update(dt);

    // ── Update horror effects (sanity, camera shake) ──
    horrorEffects.update(dt);

    // ── Update lighting & flashlight battery ──
    lighting.update(dt);
    if (lighting.flashlight) {
      inventory.flashlightBattery = lighting.battery;
    }

    // ── Update HUD ──
    hud.update();

    // ── Interactive Raycasting ──
    const hit = physics.interactionRaycast(camera, 3.2);
    if (interactPrompt) {
      if (hit && hit.object?.userData?.interactable) {
        interactPrompt.classList.add('visible');
        interactPrompt.textContent = hit.object.userData.prompt || 'Press E to interact';
      } else {
        interactPrompt.classList.remove('visible');
      }
    }

    if (controls.interactPressed) {
      controls.interactPressed = false;
      if (hit && hit.object?.userData?.interactable) {
        const callback = hit.object.userData.onInteract;
        if (typeof callback === 'function') callback(hit.object);
      }
    }
  }

  // ── Render with horror post-processing ──
  horrorRenderer.render(scene, camera, dt);
}

/* ────────────────────────────────────────────────────────
 * Initial Boot
 * ──────────────────────────────────────────────────────── */
async function boot() {
  if (loadingScreen) loadingScreen.classList.add('hidden');
  if (startPrompt) startPrompt.remove();

  // Show Main Menu on boot
  menuSystem.showMain();

  // Re-lock pointer on click if playing
  canvas.addEventListener('click', () => {
    if (gameStarted && !isPaused && menuSystem.activeScreen === 'none' && !controls.isLocked) {
      controls.lock();
    }
  });
}

boot().catch((err) => {
  console.error('[THE LAST REVENGE] Fatal boot error:', err);
  if (loadingText) {
    loadingText.textContent = 'INIT ERROR';
    loadingText.style.color = '#ff0000';
  }
});

export {
  scene,
  camera,
  controls,
  physics,
  assetLoader,
  audioManager,
  lighting,
  levelManager,
  horrorEffects,
  inventory,
  hud,
  menuSystem,
  horrorRenderer,
  AudioCategory,
  ItemType
};

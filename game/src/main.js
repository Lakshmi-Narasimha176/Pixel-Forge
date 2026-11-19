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
scene.background = new THREE.Color(0x050203);

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
const levelManager   = new LevelManager(scene, assetLoader, audioManager, physics);

let gameStarted = false;
let isPaused = false;

/* ────────────────────────────────────────────────────────
 * Build Ambient Starting Scene (renders behind Main Menu)
 * ──────────────────────────────────────────────────────── */
let ambientSceneGroup = new THREE.Group();
async function buildAmbientScene() {
  scene.add(ambientSceneGroup);

  // Dark decaying floor
  const floorMat = new THREE.MeshStandardMaterial({ color: 0x1a1010, roughness: 0.95, metalness: 0.0 });
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(40, 40), floorMat);
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  ambientSceneGroup.add(floor);
  physics.addCollider(floor);

  // ── Ceiling (so the room feels enclosed) ──
  const ceilMat = new THREE.MeshStandardMaterial({ color: 0x0d0a0a, roughness: 1.0 });
  const ceil = new THREE.Mesh(new THREE.PlaneGeometry(40, 40), ceilMat);
  ceil.rotation.x = Math.PI / 2;
  ceil.position.set(0, 5, 0);
  ambientSceneGroup.add(ceil);

  // ── Back wall with blood texture feel ──
  const wallMat = new THREE.MeshStandardMaterial({ color: 0x1a0d0d, roughness: 0.95 });
  const wallGeo = new THREE.BoxGeometry(30, 6, 0.3);

  const backWall = new THREE.Mesh(wallGeo, wallMat);
  backWall.position.set(0, 3, -8);
  ambientSceneGroup.add(backWall);

  const leftWall = new THREE.Mesh(wallGeo, wallMat);
  leftWall.position.set(-10, 3, 0);
  leftWall.rotation.y = Math.PI / 2;
  ambientSceneGroup.add(leftWall);

  const rightWall = new THREE.Mesh(wallGeo, wallMat);
  rightWall.position.set(10, 3, 0);
  rightWall.rotation.y = Math.PI / 2;
  ambientSceneGroup.add(rightWall);

  // Load original Soviet Room model into ambient background (1:1 scale)
  try {
    const gltf = await assetLoader.load('/horror_soviet_room.glb');
    const model = gltf.scene || gltf;
    model.position.set(0, 0, -2);
    model.scale.set(1.0, 1.0, 1.0);
    model.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });
    ambientSceneGroup.add(model);
    console.log('[Game] horror_soviet_room.glb loaded into ambient scene.');
  } catch (err) {
    console.warn('[Game] Soviet room fallback:', err.message);
  }

  // Load original wall clock model (realistic 51cm wall clock)
  try {
    const clockGltf = await assetLoader.load('/vintage_wooden_wall_clock_-.glb');
    const clock = clockGltf.scene || clockGltf;
    clock.position.set(0, 2.4, -7.6);
    clock.scale.set(0.6, 0.6, 0.6);
    ambientSceneGroup.add(clock);
  } catch (e) {}

  // ── Main blood-red overhead light (strong enough to see the room) ──
  const mainLight = new THREE.PointLight(0xcc2200, 4.0, 18, 1.5);
  mainLight.position.set(0, 4.0, 0);
  mainLight.castShadow = true;
  ambientSceneGroup.add(mainLight);

  // ── Secondary eerie blue-purple fill light ──
  const fillLight = new THREE.PointLight(0x2244aa, 2.0, 14, 1.5);
  fillLight.position.set(-4, 3.5, -5);
  ambientSceneGroup.add(fillLight);

  // Lighter ambient fog so the menu room is visible
  scene.fog = new THREE.FogExp2(0x080204, 0.018);
}

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

  // Inventory Quick-use
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
    } catch (err) {}
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
  if (inv.hasBloodBag && !inventory.hasItem(ItemType.BLOOD_BAG)) {
    inventory.addItem(ItemType.BLOOD_BAG);
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

  // Remove ambient backdrop geometry only AFTER Level 1 has loaded
  if (ambientSceneGroup) {
    scene.remove(ambientSceneGroup);
    ambientSceneGroup = null;
  }

  const spawn = levelManager.getSpawnPoint();
  if (spawn) controls.yaw.position.copy(spawn);

  controls.lock();
  hud.showSubtitle("Click anywhere to lock mouse view. [WASD] to move, [E] to interact.", 5000);
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
 * Game Loop (Runs continuously from page load)
 * ──────────────────────────────────────────────────────── */
const clock = new THREE.Clock();

function startGameLoop() {
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
  } else {
    // Menu backdrop idle animation: slowly rotate camera and pulse lights
    camera.rotation.y = Math.sin(clock.getElapsedTime() * 0.2) * 0.15;
    lighting.update(dt);
  }

  // ── Render with horror post-processing ──
  horrorRenderer.render(scene, camera, dt);
}

/* ────────────────────────────────────────────────────────
 * Initial Boot
 * ──────────────────────────────────────────────────────── */
async function boot() {
  // Start continuous 60FPS render loop immediately
  startGameLoop();

  // Build 3D ambient horror room using original GLB assets
  await buildAmbientScene();

  // Instantly remove loading overlays
  if (loadingScreen) loadingScreen.remove();
  if (startPrompt) startPrompt.remove();

  // Show Horror Main Menu
  menuSystem.showMain();

  // Auto-start if ?start=1 is in URL
  if (new URLSearchParams(window.location.search).has('start')) {
    setTimeout(() => startNewGame(), 300);
  }

  // Click anywhere to lock pointer during gameplay
  window.addEventListener('click', () => {
    if (gameStarted && !isPaused && menuSystem.activeScreen === 'none' && !controls.isLocked) {
      controls.lock();
    }
  });
}

boot().catch((err) => {
  console.error('[THE LAST REVENGE] Fatal boot error:', err);
  if (loadingText) {
    loadingText.textContent = 'INIT ERROR: ' + err.message;
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

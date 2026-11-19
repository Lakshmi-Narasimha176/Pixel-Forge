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
const levelManager   = new LevelManager(scene, assetLoader, audioManager);

let gameStarted = false;
let isPaused = false;

/* ────────────────────────────────────────────────────────
 * Build Ambient Starting Scene (renders behind Main Menu)
 * ──────────────────────────────────────────────────────── */
let ambientSceneGroup = new THREE.Group();
async function buildAmbientScene() {
  scene.add(ambientSceneGroup);

  // Dark decaying floor
  const floorMat = new THREE.MeshStandardMaterial({ color: 0x140e0e, roughness: 0.95 });
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(30, 30), floorMat);
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  ambientSceneGroup.add(floor);
  physics.addCollider(floor);

  // Load original Soviet Room model into ambient background
  try {
    const gltf = await assetLoader.load('/horror_soviet_room.glb');
    const model = gltf.scene || gltf;
    model.position.set(0, 0, 0);
    model.scale.set(1.2, 1.2, 1.2);
    model.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });
    ambientSceneGroup.add(model);
    console.log('[Game] Original horror_soviet_room.glb loaded into ambient scene.');
  } catch (err) {
    console.warn('[Game] Using fallback walls for ambient scene:', err);
    // Surrounding walls fallback
    const wallMat = new THREE.MeshStandardMaterial({ color: 0x1b1313, roughness: 0.9 });
    const wallGeo = new THREE.BoxGeometry(30, 5, 0.3);

    const backWall = new THREE.Mesh(wallGeo, wallMat);
    backWall.position.set(0, 2.5, -10);
    ambientSceneGroup.add(backWall);

    const leftWall = new THREE.Mesh(wallGeo, wallMat);
    leftWall.position.set(-10, 2.5, 0);
    leftWall.rotation.y = Math.PI / 2;
    ambientSceneGroup.add(leftWall);

    const rightWall = new THREE.Mesh(wallGeo, wallMat);
    rightWall.position.set(10, 2.5, 0);
    rightWall.rotation.y = Math.PI / 2;
    ambientSceneGroup.add(rightWall);
  }

  // Load original wall clock model
  try {
    const clockGltf = await assetLoader.load('/vintage_wooden_wall_clock_-.glb');
    const clock = clockGltf.scene || clockGltf;
    clock.position.set(0, 2.2, -4.5);
    ambientSceneGroup.add(clock);
  } catch (e) {}

  // Flickering horror point lights
  lighting.addFlickerLight(new THREE.Vector3(0, 3.2, 0), {
    intensity: 2.2,
    color: 0xff3311,
    flickerAmount: 0.5,
    flickerSpeed: 4
  });

  lighting.addFlickerLight(new THREE.Vector3(-3, 2.8, -4), {
    intensity: 1.4,
    color: 0x4488aa,
    flickerAmount: 0.7,
    flickerSpeed: 7
  });

  // Ambient fog
  scene.fog = new THREE.FogExp2(0x080406, 0.04);
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

  // Remove ambient backdrop geometry to load Chapter 1
  if (ambientSceneGroup) {
    scene.remove(ambientSceneGroup);
    ambientSceneGroup = null;
  }

  await audioManager.resume();
  audioManager.generateReverb(2.8, 3.5);

  controls.lock();
  gameStarted = true;
  isPaused = false;

  // Load Level 1: The Awakening
  await levelManager.loadLevel(1);

  const spawn = levelManager.getSpawnPoint();
  if (spawn) controls.yaw.position.copy(spawn);
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

  // Click canvas to resume pointer lock during gameplay
  canvas.addEventListener('click', () => {
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

/**
 * @fileoverview AssetLoader — GLTF/GLB model loader with progress tracking.
 *
 * Wraps Three.js GLTFLoader + LoadingManager to provide:
 *   - Promise-based model loading
 *   - Global progress bar integration
 *   - Caching to avoid re-fetching
 *   - Shadow setup on loaded meshes
 */

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

/** @typedef {import('three/addons/loaders/GLTFLoader.js').GLTF} GLTF */

export class AssetLoader {
  /**
   * @param {Object} [options]
   * @param {(progress: number) => void} [options.onProgress] — callback with 0–1 progress
   * @param {() => void} [options.onComplete] — called when all queued assets finish
   */
  constructor(options = {}) {
    /** @private */
    this._onProgressCb = options.onProgress ?? null;
    /** @private */
    this._onCompleteCb = options.onComplete ?? null;

    /** @type {THREE.LoadingManager} */
    this.manager = new THREE.LoadingManager();

    this.manager.onProgress = (_url, loaded, total) => {
      if (this._onProgressCb) {
        this._onProgressCb(total > 0 ? loaded / total : 0);
      }
    };

    this.manager.onLoad = () => {
      if (this._onCompleteCb) this._onCompleteCb();
    };

    this.manager.onError = (url) => {
      console.error(`[AssetLoader] Failed to load: ${url}`);
    };

    /** @type {GLTFLoader} */
    this.gltfLoader = new GLTFLoader(this.manager);

    /** @type {Map<string, GLTF>} Loaded model cache keyed by path. */
    this._cache = new Map();

    /** Base path for asset resolution — relative to game/ folder. */
    this.basePath = '../assets/';
  }

  /**
   * Load a GLB/GLTF model.
   * @param {string} filename — file name relative to basePath (e.g. 'hallway.glb')
   * @param {Object} [opts]
   * @param {boolean} [opts.castShadow=true]
   * @param {boolean} [opts.receiveShadow=true]
   * @returns {Promise<GLTF>}
   */
  async loadModel(filename, opts = {}) {
    const path = this.basePath + filename;

    // Return cached model (clone the scene)
    if (this._cache.has(path)) {
      const cached = this._cache.get(path);
      return { ...cached, scene: cached.scene.clone() };
    }

    return new Promise((resolve, reject) => {
      this.gltfLoader.load(
        path,
        (gltf) => {
          const castShadow    = opts.castShadow    ?? true;
          const receiveShadow = opts.receiveShadow ?? true;

          gltf.scene.traverse((child) => {
            if (child.isMesh) {
              child.castShadow    = castShadow;
              child.receiveShadow = receiveShadow;
            }
          });

          this._cache.set(path, gltf);
          resolve(gltf);
        },
        undefined, // progress handled by manager
        (err) => {
          console.error(`[AssetLoader] Error loading ${path}:`, err);
          reject(err);
        }
      );
    });
  }

  /**
   * Load multiple models in parallel.
   * @param {string[]} filenames
   * @param {Object} [opts] — same options as loadModel
   * @returns {Promise<Map<string, GLTF>>} Map of filename → GLTF
   */
  async loadModels(filenames, opts = {}) {
    /** @type {Map<string, GLTF>} */
    const results = new Map();
    const promises = filenames.map(async (name) => {
      const gltf = await this.loadModel(name, opts);
      results.set(name, gltf);
    });
    await Promise.all(promises);
    return results;
  }

  /**
   * Preload a texture.
   * @param {string} filename — relative to basePath
   * @returns {Promise<THREE.Texture>}
   */
  async loadTexture(filename) {
    const path = this.basePath + filename;
    const loader = new THREE.TextureLoader(this.manager);
    return new Promise((resolve, reject) => {
      loader.load(path, resolve, undefined, reject);
    });
  }

  /**
   * Clear all cached assets.
   */
  clearCache() {
    this._cache.clear();
  }
}

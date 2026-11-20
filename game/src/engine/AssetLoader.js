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

    /** Base path for asset resolution */
    this.basePath = import.meta.env.BASE_URL;
  }

  /**
   * Resolve any asset path to a valid web URL
   * @param {string} rawPath
   * @returns {string}
   */
  resolvePath(rawPath) {
    if (!rawPath) return '/';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) return rawPath;
    const clean = rawPath.replace(/^(\.\.\/)+/, '').replace(/^\.\//, '').replace(/^\/+/, '');
    return `${this.basePath}${clean}`;
  }

  /**
   * Primary loading method used by main.js and all levels.
   * @param {string} path — Path or filename of the GLB model
   * @param {Object} [opts]
   * @param {boolean} [opts.castShadow=true]
   * @param {boolean} [opts.receiveShadow=true]
   * @returns {Promise<GLTF>}
   */
  async load(path, opts = {}) {
    const resolvedUrl = this.resolvePath(path);

    // Return cached model (cloning the scene)
    if (this._cache.has(resolvedUrl)) {
      const cached = this._cache.get(resolvedUrl);
      const clonedScene = cached.scene.clone(true);
      return { ...cached, scene: clonedScene };
    }

    return new Promise((resolve, reject) => {
      this.gltfLoader.load(
        resolvedUrl,
        (gltf) => {
          const castShadow    = opts.castShadow ?? true;
          const receiveShadow = opts.receiveShadow ?? true;

          gltf.scene.traverse((child) => {
            if (child.isMesh) {
              child.castShadow = castShadow;
              child.receiveShadow = receiveShadow;
              const materials = Array.isArray(child.material) ? child.material : [child.material];
              materials.forEach((mat) => {
                if (mat) {
                  mat.side = THREE.DoubleSide;
                  // Prevent pure black reflection when no HDR environment map is present
                  if (mat.metalness > 0.4) {
                    mat.metalness = 0.15;
                  }
                  if (mat.roughness !== undefined) {
                    mat.roughness = Math.max(0.4, Math.min(mat.roughness, 0.95));
                  }
                }
              });
            }
          });

          this._cache.set(resolvedUrl, gltf);
          resolve(gltf);
        },
        undefined,
        (err) => {
          console.error(`[AssetLoader] Error loading ${resolvedUrl}:`, err);
          reject(err);
        }
      );
    });
  }

  /**
   * Alias for load()
   */
  async loadModel(filename, opts = {}) {
    return this.load(filename, opts);
  }

  /**
   * Fit and center a 3D model to a target bounding box size
   * @param {THREE.Object3D} model
   * @param {number} targetHeight
   * @param {boolean} [groundOnZero=true]
   */
  fitToSize(model, targetHeight = 2.0, groundOnZero = true) {
    const box = new THREE.Box3().setFromObject(model);
    const size = new THREE.Vector3();
    box.getSize(size);
    const maxDim = Math.max(size.x, size.y, size.z);
    if (maxDim > 0) {
      const s = targetHeight / maxDim;
      model.scale.multiplyScalar(s);
    }
    const finalBox = new THREE.Box3().setFromObject(model);
    const center = new THREE.Vector3();
    finalBox.getCenter(center);
    model.position.x -= center.x;
    model.position.z -= center.z;
    if (groundOnZero) {
      model.position.y -= finalBox.min.y;
    }
    return model;
  }

  /**
   * Load multiple models in parallel.
   * @param {string[]} filenames
   * @param {Object} [opts]
   * @returns {Promise<Map<string, GLTF>>}
   */
  async loadModels(filenames, opts = {}) {
    const results = new Map();
    const promises = filenames.map(async (name) => {
      const gltf = await this.load(name, opts);
      results.set(name, gltf);
    });
    await Promise.all(promises);
    return results;
  }

  /**
   * Preload a texture.
   * @param {string} filename
   * @returns {Promise<THREE.Texture>}
   */
  async loadTexture(filename) {
    const resolvedUrl = this.resolvePath(filename);
    const loader = new THREE.TextureLoader(this.manager);
    return new Promise((resolve, reject) => {
      loader.load(resolvedUrl, resolve, undefined, reject);
    });
  }

  /**
   * Clear all cached assets.
   */
  clearCache() {
    this._cache.clear();
  }
}

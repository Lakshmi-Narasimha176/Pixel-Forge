/**
 * @fileoverview Renderer — WebGL renderer with horror post-processing.
 *
 * Post-processing pipeline:
 *   1. Render pass (scene → render target)
 *   2. Vignette (darkens edges)
 *   3. Film grain (subtle noise overlay)
 *   4. Desaturation / color grading (muted, cold palette)
 *   5. Chromatic aberration (triggered during scare events)
 *
 * Uses raw WebGL shader passes via Three.js ShaderMaterial + EffectComposer
 * pattern implemented manually to avoid external post-processing deps.
 */

import * as THREE from 'three';

/* ────────────────────────────────────────────────────────
 * Full-screen Quad helper
 * ──────────────────────────────────────────────────────── */

/**
 * Creates an orthographic scene with a full-screen triangle for shader passes.
 * @returns {{ scene: THREE.Scene, camera: THREE.Camera, mesh: THREE.Mesh }}
 */
function createFullscreenQuad(material) {
  const geo = new THREE.PlaneGeometry(2, 2);
  const mesh = new THREE.Mesh(geo, material);
  const scene = new THREE.Scene();
  scene.add(mesh);
  const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  return { scene, camera, mesh };
}

/* ────────────────────────────────────────────────────────
 * Shader sources
 * ──────────────────────────────────────────────────────── */

const PASSTHROUGH_VERT = /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = vec4(position.xy, 0.0, 1.0);
  }
`;

/** Combined post-processing fragment: vignette + grain + desat + chromatic aberration */
const HORROR_POST_FRAG = /* glsl */ `
  precision highp float;

  uniform sampler2D tDiffuse;
  uniform float uTime;
  uniform float uVignetteIntensity;    // 0–1  default 0.45
  uniform float uGrainIntensity;       // 0–1  default 0.08
  uniform float uDesaturation;         // 0–1  default 0.55  (0 = full color, 1 = greyscale)
  uniform float uChromaticAberration;  // 0–1  default 0.0, spikes during scares
  uniform vec2  uResolution;

  varying vec2 vUv;

  /* ---- helpers ---- */

  float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
  }

  void main() {
    vec2 uv = vUv;

    // ── Chromatic Aberration ──
    float caOffset = uChromaticAberration * 0.012;
    vec2 dir = uv - 0.5;
    float r = texture2D(tDiffuse, uv + dir * caOffset).r;
    float g = texture2D(tDiffuse, uv).g;
    float b = texture2D(tDiffuse, uv - dir * caOffset).b;
    vec3 color = vec3(r, g, b);

    // ── Desaturation / Color Grading ──
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(lum), uDesaturation);
    // Cold tint – push blues slightly, pull reds
    color.r *= 0.92;
    color.b *= 1.06;

    // ── Vignette ──
    float dist = length(uv - 0.5);
    float vig = smoothstep(0.4, 1.0, dist) * uVignetteIntensity;
    color *= 1.0 - vig;

    // ── Film Grain ──
    float grain = (rand(uv * uTime * 0.01 + uTime) - 0.5) * uGrainIntensity;
    color += grain;

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
  }
`;

/* ────────────────────────────────────────────────────────
 * HorrorRenderer class
 * ──────────────────────────────────────────────────────── */

export class HorrorRenderer {
  /**
   * @param {HTMLElement} [container=document.body] — DOM element to attach the canvas to
   */
  constructor(container = document.body) {
    /** @type {THREE.WebGLRenderer} */
    this.renderer = new THREE.WebGLRenderer({
      antialias: false,
      powerPreference: 'high-performance',
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 0.6;
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;

    container.appendChild(this.renderer.domElement);

    /** @type {HTMLCanvasElement} */
    this.canvas = this.renderer.domElement;

    // ── Render target for scene pass ──
    this._rt = new THREE.WebGLRenderTarget(
      window.innerWidth * Math.min(window.devicePixelRatio, 2),
      window.innerHeight * Math.min(window.devicePixelRatio, 2),
      { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBAFormat }
    );

    // ── Post-processing material ──
    /** @type {THREE.ShaderMaterial} */
    this._postMaterial = new THREE.ShaderMaterial({
      vertexShader: PASSTHROUGH_VERT,
      fragmentShader: HORROR_POST_FRAG,
      uniforms: {
        tDiffuse:              { value: this._rt.texture },
        uTime:                 { value: 0 },
        uVignetteIntensity:    { value: 0.45 },
        uGrainIntensity:       { value: 0.08 },
        uDesaturation:         { value: 0.55 },
        uChromaticAberration:  { value: 0.0 },
        uResolution:           { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
      },
      depthTest: false,
      depthWrite: false,
    });

    const quad = createFullscreenQuad(this._postMaterial);
    /** @private */ this._quadScene = quad.scene;
    /** @private */ this._quadCamera = quad.camera;

    // ── Chromatic aberration scare state ──
    /** @private */ this._caTarget = 0;
    /** @private */ this._caDecay = 3.0; // per second

    // Resize handler
    window.addEventListener('resize', () => this._onResize());
  }

  /* ── Public API ── */

  /**
   * Render a frame with horror post-processing.
   * @param {THREE.Scene} scene
   * @param {THREE.Camera} camera
   * @param {number} dt — delta time in seconds
   */
  render(scene, camera, dt) {
    const u = this._postMaterial.uniforms;
    u.uTime.value += dt;

    // Decay chromatic aberration
    if (u.uChromaticAberration.value > 0.001) {
      u.uChromaticAberration.value = Math.max(0, u.uChromaticAberration.value - this._caDecay * dt);
    }

    // 1. Render scene to offscreen target
    this.renderer.setRenderTarget(this._rt);
    this.renderer.render(scene, camera);

    // 2. Post-process to screen
    this.renderer.setRenderTarget(null);
    this.renderer.render(this._quadScene, this._quadCamera);
  }

  /**
   * Trigger chromatic aberration scare pulse.
   * @param {number} [intensity=1.0] — 0–1
   */
  triggerScare(intensity = 1.0) {
    this._postMaterial.uniforms.uChromaticAberration.value = Math.min(intensity, 1.0);
  }

  /**
   * Set vignette intensity.
   * @param {number} val — 0–1
   */
  setVignette(val) {
    this._postMaterial.uniforms.uVignetteIntensity.value = val;
  }

  /**
   * Set grain intensity.
   * @param {number} val — 0–1
   */
  setGrain(val) {
    this._postMaterial.uniforms.uGrainIntensity.value = val;
  }

  /**
   * Set desaturation level.
   * @param {number} val — 0 (full color) to 1 (greyscale)
   */
  setDesaturation(val) {
    this._postMaterial.uniforms.uDesaturation.value = val;
  }

  /**
   * @returns {HTMLCanvasElement}
   */
  getDomElement() {
    return this.canvas;
  }

  /** Dispose renderer and free GPU resources. */
  dispose() {
    this._rt.dispose();
    this._postMaterial.dispose();
    this.renderer.dispose();
  }

  /* ── Private ── */

  /** @private */
  _onResize() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    const pr = Math.min(window.devicePixelRatio, 2);

    this.renderer.setSize(w, h);
    this._rt.setSize(w * pr, h * pr);
    this._postMaterial.uniforms.uResolution.value.set(w, h);
  }
}

// psx_effect.gdshader
// PSX-aesthetic screen-space post-processing shader for The Last Revenge.
// Apply to a ColorRect (FullRect) inside a SubViewportContainer.
// Set the shader parameter "screen_texture" to the SubViewport texture.

shader_type canvas_item;

// --- Tunable parameters ---
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Posterization: number of colour steps per channel (lower = fewer colours)
uniform float color_depth : hint_range(2.0, 64.0) = 32.0;

// Scanline opacity (0 = off, 1 = fully black every other line)
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.20;

// Dithering strength (0 = off)
uniform float dither_strength : hint_range(0.0, 0.1) = 0.025;

// Optional: pixel resolution downscale factor (1 = native, 2 = half-res, etc.)
uniform float pixel_scale : hint_range(1.0, 8.0) = 2.0;

// Bayer 4×4 dither matrix (normalized to 0..1)
float bayer4(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    int index = x + y * 4;
    // 4×4 Bayer matrix values / 16
    float m[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    return m[index] / 16.0;
}

void fragment() {
    // --- Pixel art downscale (snap UV to pixel grid) ---
    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    vec2 snapped_uv = floor(UV * screen_size / pixel_scale) * pixel_scale / screen_size;

    // --- Sample scene colour ---
    vec3 col = texture(screen_texture, snapped_uv).rgb;

    // --- Dithering ---
    vec2 pixel_pos = floor(UV * screen_size);
    float dither = (bayer4(pixel_pos) - 0.5) * dither_strength;
    col += vec3(dither);

    // --- Posterization (reduce colour depth) ---
    col = floor(col * color_depth + 0.5) / color_depth;
    col = clamp(col, 0.0, 1.0);

    // --- Scanlines (darken every other pixel row) ---
    float scanline = mod(floor(UV.y * screen_size.y), 2.0);
    col *= mix(1.0, 1.0 - scanline_opacity, scanline);

    COLOR = vec4(col, 1.0);
}

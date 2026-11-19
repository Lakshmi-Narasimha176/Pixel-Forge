shader_type canvas_item;
// Film look over the whole screen: vignette, grain, chromatic aberration, fear desaturation, damage flash.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 1.0;
uniform float grain = 0.06;
uniform float aberration = 0.0025;
uniform float desat = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_color = vec3(0.6, 0.0, 0.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r = length(c);
	float ab = aberration * (0.4 + 2.4 * r * r);
	vec3 col;
	col.r = texture(screen_tex, uv + c * ab).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - c * ab).b;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat);
	col += (hash(uv * vec2(1731.0, 977.0) + fract(TIME) * 91.7) * 2.0 - 1.0) * grain * (1.15 - clamp(l, 0.0, 1.0));
	col *= 1.0 - smoothstep(0.28, 0.92, r * vignette * 1.45);
	col = mix(col, flash_color, flash * (0.35 + 0.65 * smoothstep(0.1, 0.8, r)));
	COLOR = vec4(col, 1.0);
}

shader_type sky;
// Stormy night sky for THE LAST REVENGE: stars, moon disc, lightning flashes, and a dawn blend for the ending.
uniform vec3 top_color : source_color = vec3(0.012, 0.018, 0.045);
uniform vec3 horizon_color : source_color = vec3(0.06, 0.07, 0.11);
uniform vec3 dawn_top : source_color = vec3(0.32, 0.40, 0.62);
uniform vec3 dawn_horizon : source_color = vec3(1.0, 0.62, 0.38);
uniform float storm = 0.0;   // lightning level 0..1
uniform float dawn = 0.0;    // 0 = night, 1 = sunrise

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = clamp(d.y, 0.0, 1.0);
	vec3 night = mix(horizon_color, top_color, pow(up, 0.45));
	vec3 morning = mix(dawn_horizon, dawn_top, pow(up, 0.55));
	vec3 col = mix(night, morning, dawn);

	// Stars fade out with the dawn and with lightning.
	vec3 cell = floor(d * 240.0);
	float star = step(0.9968, hash13(cell)) * smoothstep(0.04, 0.35, d.y);
	float twinkle = 0.6 + 0.4 * sin(TIME * 3.0 + hash13(cell + vec3(1.0)) * 40.0);
	col += vec3(star * twinkle) * (1.0 - dawn) * (1.0 - storm);

	// Moon disc from the first directional light.
	if (LIGHT0_ENABLED) {
		float m = smoothstep(0.9988, 0.9994, dot(d, LIGHT0_DIRECTION));
		col += LIGHT0_COLOR * m * 1.4 * (1.0 - dawn * 0.6);
	}

	// Lightning lights up the clouds.
	col += vec3(0.55, 0.62, 0.9) * storm * (0.5 + 0.5 * up);
	COLOR = col;
}

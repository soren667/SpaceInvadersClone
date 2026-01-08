shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform float scan_line_amount : hint_range(0.0, 1.0) = 0.25;
uniform float warp_amount : hint_range(0.0, 1.0) = 0.01; 
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.25;
uniform float grille_amount : hint_range(0.0, 1.0) = 0.02;
uniform float brightness_boost : hint_range(1.0, 2.0) = 1.05;

void fragment() {
	vec2 uv = SCREEN_UV;

	// derive resolution from viewport (no need to hardcode 320x180)
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;

	// --- subtler warp curve ---
	vec2 d = uv - 0.5;
	float r2 = dot(d, d);                 // 0..~0.5
	float warp = r2 * r2 * warp_amount;   // r^4 curve (much gentler near edges)
	uv += d * warp;

	// clamp uv to avoid weird sampling beyond screen
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// --- scanlines (subtle) ---
	float scan = sin(uv.y * res.y * 3.14159265) * 0.5 + 0.5;
	float scanline = mix(1.0, scan, scan_line_amount * 0.25);

	// --- grille (subtle) ---
	float grille = mod(uv.x * res.x, 3.0) < 1.5 ? 0.98 : 1.02;
	grille = mix(1.0, grille, grille_amount);

	vec3 color = texture(SCREEN_TEXTURE, uv).rgb * scanline * grille;

	// --- vignette (subtle) ---
	vec2 v = uv * (1.0 - uv);
	float vig = v.x * v.y * 15.0;
	float vignette = mix(1.0, vig, vignette_amount * 0.6);

	color *= vignette * brightness_boost;

	COLOR = vec4(color, 1.0);
}


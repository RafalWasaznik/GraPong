shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform int motif = 0;
uniform float czas = 0.0;
uniform vec2 rect_size = vec2(1152.0, 648.0);
uniform vec4 arena_rect = vec4(32.0, 100.0, 1088.0, 520.0);
uniform vec4 accent_a : source_color = vec4(0.08, 0.70, 0.85, 1.0);
uniform vec4 accent_b : source_color = vec4(0.65, 0.14, 0.75, 1.0);
uniform float layout_seed = 1.0;
uniform vec4 variant = vec4(0.5);
uniform float strength = 0.7;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform int quality = 2;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345 + fract(layout_seed * 0.017) * 17.0);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}

float cloud(vec2 p) {
	float phase = fract(layout_seed * 0.0137) * 6.28318;
	vec2 q = p + vec2(sin(p.y * 1.27 + phase), cos(p.x * 1.43 - phase)) * 0.65;
	float n = 0.5 + sin(q.x * 1.7 + sin(q.y * 1.3)) * 0.19;
	n += cos(q.y * 2.1 + cos(q.x * 1.6 + phase)) * 0.16;
	n += sin(q.x * 3.6 + q.y * 2.7 + phase) * 0.07;
	if (quality >= 2) {
		n += sin(q.x * 7.1 - q.y * 4.3 + phase) * 0.035;
		n += cos(q.x * 12.3 + q.y * 9.1) * 0.015;
	}
	return n;
}

float stroke(float distance_to_line, float width, float pixel) {
	return 1.0 - smoothstep(width, width + pixel, distance_to_line);
}

float stars(vec2 p, float density, float layer, float pixel) {
	vec2 field = p * density;
	vec2 id = floor(field);
	vec2 local = fract(field);
	vec2 point = vec2(hash21(id + layer), hash21(id + layer + 23.0)) * 0.7 + 0.15;
	float chance = hash21(id + layer + 53.0);
	float radius = mix(0.45, 1.1, chance) * pixel * density;
	float star = 1.0 - smoothstep(radius * 0.2, radius + pixel * density, length(local - point));
	float twinkle = 0.82 + 0.18 * sin(czas * 0.35 + chance * 37.0);
	return star * step(0.80, chance) * twinkle;
}

vec3 data_stream(vec2 p, vec2 offset, float density, float t, float pixel, vec3 green) {
	vec2 field = p * vec2(density, density * 1.32) + offset;
	vec2 id = floor(field);
	vec2 cell = fract(field);
	float column = hash21(vec2(id.x, 19.0));
	float glyph_id = hash21(id);
	float vertical = stroke(min(abs(cell.x - 0.27), abs(cell.x - 0.73)), 0.025, pixel * density);
	vertical *= step(0.18, cell.y) * (1.0 - step(0.82, cell.y));
	vertical *= step(0.30, hash21(id + vec2(floor(cell.y * 5.0), 8.0)));
	float horizontal = stroke(abs(fract(cell.y * 3.0) - 0.5), 0.065, pixel * density * 3.9);
	horizontal *= step(0.24, cell.x) * (1.0 - step(0.76, cell.x));
	horizontal *= step(0.35, hash21(id + vec2(floor(cell.y * 3.0), 2.0)));
	float glyph = max(vertical, horizontal) * step(0.30, glyph_id);
	float head = fract(t * mix(0.018, 0.045, column) + column);
	float phase = fract(head - (id.y - offset.y) / (density * 1.32));
	float tail = exp(-phase * mix(9.0, 17.0, column));
	float tip = 1.0 - smoothstep(0.0, 0.026, phase);
	return green * glyph * (0.04 + tail * 0.40) + vec3(0.55, 0.94, 0.69) * glyph * tip * 0.20;
}

void fragment() {
	vec2 size = max(rect_size, vec2(1.0));
	float aspect = size.x / size.y;
	float pixel = 1.0 / size.y;
	vec2 uv = UV;
	vec2 p = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	vec4 v = clamp(variant, vec4(0.0), vec4(1.0));
	vec2 seed_offset = vec2(fract(layout_seed * 0.173), fract(layout_seed * 0.317)) * 15.0;
	float t = czas * mix(0.65, 1.0, v.w);
	vec3 a = accent_a.rgb;
	vec3 b = accent_b.rgb;
	vec3 base = vec3(0.012, 0.021, 0.039);
	vec3 detail = vec3(0.0);
	vec3 haze = vec3(0.0);

	if (motif == 0) {
		// An illuminated city edge and broad circuit plates frame the court.
		float side = smoothstep(0.30, 0.85, abs(p.x));
		haze = a * exp(-abs(p.x + aspect * 0.39) * 5.0) * 0.065;
		haze += b * exp(-abs(p.x - aspect * 0.38) * 5.0) * 0.075;
		vec2 panel_p = p * vec2(3.0, 4.0) + seed_offset;
		vec2 id = floor(panel_p);
		vec2 cell = fract(panel_p);
		float panel_id = hash21(id);
		float edge = min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y));
		float outline = stroke(edge, 0.005, pixel * 4.0);
		float diagonal = stroke(abs(cell.x + cell.y - 0.20), 0.008, pixel * 5.0);
		detail += mix(a, b, panel_id) * (outline * 0.075 + diagonal * 0.15);
		float lane = mix(0.24, 0.72, hash21(id + 11.0));
		float trace = stroke(abs(cell.y - lane), 0.004, pixel * 4.0);
		trace *= smoothstep(0.08, 0.10, cell.x) * (1.0 - smoothstep(0.86, 0.88, cell.x));
		float pulse = exp(-abs(cell.x - fract(t * 0.055 + panel_id)) * 28.0);
		detail += a * trace * (0.065 + pulse * 0.22);
		float column = floor(uv.x * 34.0);
		float roof = 0.69 + hash21(vec2(column, 3.0)) * 0.23;
		float building = smoothstep(roof, roof + pixel * 2.0, uv.y);
		float wall_edge = stroke(abs(fract(uv.x * 34.0) - 0.08), 0.018, pixel * 34.0);
		detail += mix(a, b, uv.x) * building * wall_edge * side * 0.22;
		if (quality >= 2) {
			float branch = stroke(abs(cell.x - 0.76), 0.004, pixel * 4.0);
			branch *= step(lane, cell.y) * (1.0 - step(0.88, cell.y));
			float node = 1.0 - smoothstep(0.012, 0.025, length(cell - vec2(0.76, lane)));
			detail += b * (branch * 0.10 + node * 0.22);
			vec2 windows = fract(vec2(uv.x * 170.0, uv.y * 85.0));
			float light = step(0.65, hash21(floor(vec2(uv.x * 170.0, uv.y * 85.0))));
			light *= step(0.35, windows.x) * step(0.55, windows.y);
			detail += a * light * building * side * 0.055;
		}
	} else if (motif == 1) {
		// Continuous screen-space clouds and pixel-sized stars, without textures.
		vec2 nebula_p = p * mix(2.0, 2.8, v.x) + seed_offset;
		nebula_p += vec2(t * 0.004, -t * 0.002);
		vec2 warp = vec2(sin(nebula_p.y * 0.9 + v.z * 6.28), cos(nebula_p.x * 1.1 + v.w * 6.28)) * 0.5;
		float n = cloud(nebula_p + warp * 1.5);
		float n2 = cloud(nebula_p * 1.13 + vec2(8.0, -3.0) - warp);
		float ribbon_distance = (p.y + sin(p.x * 1.7 + v.y * 5.0) * 0.22) * 2.6;
		float ribbon = exp(-ribbon_distance * ribbon_distance);
		float mist = smoothstep(0.21, 0.79, n);
		haze = a * mist * (0.07 + ribbon * 0.16);
		haze += b * smoothstep(0.28, 0.78, n2) * (0.05 + ribbon * 0.18);
		float dust = smoothstep(0.32, 0.64, n2) * (1.0 - smoothstep(0.38, 0.65, n));
		detail += mix(a, b, n2) * dust * ribbon * 0.20;
		vec2 drift = vec2(t * 0.0008, t * 0.00025);
		detail += mix(a, vec3(0.8, 0.85, 1.0), 0.75) * stars(p + drift + seed_offset, 24.0, 1.0, pixel) * 0.43;
		if (quality >= 2) {
			detail += vec3(0.7, 0.76, 0.9) * stars(p + drift * 0.45 - seed_offset, 42.0, 7.0, pixel * 0.65) * 0.19;
		}
		base += vec3(0.003, 0.001, 0.009);
	} else if (motif == 2) {
		float horizon = mix(0.43, 0.52, v.y);
		float sky_glow = exp(-abs(uv.y - horizon) * 6.0);
		haze = mix(a, b, 0.22) * sky_glow * 0.14 + a * exp(-abs(uv.y - 0.88) * 4.0) * 0.025;
		float sky = 1.0 - smoothstep(horizon - 0.08, horizon + 0.02, uv.y);
		base += mix(vec3(0.025, 0.010, 0.055), vec3(0.055, 0.014, 0.045), clamp(uv.y / horizon, 0.0, 1.0)) * sky;
		detail += vec3(0.55, 0.61, 0.85) * stars(p + seed_offset, 18.0, 13.0, pixel * 0.65) * sky * 0.12;
		detail += a * exp(-abs(uv.y - horizon) * 110.0) * 0.16;
		vec2 sun_center = vec2(mix(0.24, 0.76, v.x), horizon - 0.16);
		vec2 sun_p = (uv - sun_center) * vec2(aspect, 1.0);
		float radius = mix(0.105, 0.145, v.z);
		float sun = 1.0 - smoothstep(radius - pixel, radius + pixel, length(sun_p));
		float bands = smoothstep(0.14, 0.24, fract(sun_p.y * 58.0));
		sun *= mix(1.0, bands, smoothstep(-0.04, 0.09, sun_p.y));
		vec3 sunset = mix(vec3(0.95, 0.32, 0.20), b, smoothstep(-radius, radius, sun_p.y));
		detail += sunset * sun * 0.27;
		haze += b * exp(-length(sun_p) * 8.0) * 0.025;
		if (uv.y > horizon) {
			float depth = max(uv.y - horizon, 0.012);
			float grid_x = p.x / depth * mix(1.1, 1.7, v.x);
			float grid_z = 0.33 / depth + t * 0.065;
			float aa_x = max(fwidth(grid_x), 0.001);
			float aa_z = max(fwidth(grid_z), 0.001);
			float line_x = stroke(abs(fract(grid_x + 0.5) - 0.5), 0.009, aa_x);
			float line_z = stroke(abs(fract(grid_z + 0.5) - 0.5), 0.012, aa_z);
			float fade = smoothstep(0.035, 0.18, depth) * (1.0 - smoothstep(0.25, 0.65, max(aa_x, aa_z)));
			detail += mix(b, a, smoothstep(0.0, 0.65, depth)) * max(line_x, line_z) * fade * 0.20;
		}
	} else {
		// Stable glyph shapes with independently paced descending column heads.
		vec2 code_p = (p + vec2(aspect * 0.5, 0.5)) * vec2(34.0, 45.0);
		code_p += seed_offset;
		vec2 id = floor(code_p);
		vec2 cell = fract(code_p);
		float column = hash21(vec2(id.x, 19.0));
		float glyph_id = hash21(id);
		float enabled = step(quality >= 2 ? 0.28 : 0.56, glyph_id);
		float vertical = stroke(min(abs(cell.x - 0.27), abs(cell.x - 0.73)), 0.025, pixel * 34.0);
		vertical *= step(0.18, cell.y) * (1.0 - step(0.82, cell.y));
		float segment = floor(cell.y * 5.0);
		vertical *= step(0.30, hash21(id + vec2(segment, 8.0)));
		float horizontal = stroke(abs(fract(cell.y * 3.0) - 0.5), 0.065, pixel * 135.0);
		horizontal *= step(0.24, cell.x) * (1.0 - step(0.76, cell.x));
		horizontal *= step(0.35, hash21(id + vec2(floor(cell.y * 3.0), 2.0)));
		float glyph = max(vertical, horizontal) * enabled;
		float head = fract(t * mix(0.018, 0.045, column) + column);
		float phase = fract(head - (id.y - seed_offset.y) / 45.0);
		float tail = exp(-phase * mix(9.0, 17.0, column));
		float tip = 1.0 - smoothstep(0.0, 0.026, phase);
		vec3 green = mix(vec3(0.10, 0.62, 0.30), a, 0.20);
		detail += green * glyph * (0.022 + tail * 0.26);
		detail += vec3(0.55, 0.94, 0.69) * glyph * tip * 0.15;
		haze = green * (0.009 + exp(-abs(p.x - sin(column * 5.0) * aspect * 0.45) * 5.0) * 0.012);
		base = vec3(0.009, 0.025, 0.020);
		detail += data_stream(p + vec2(aspect * 0.5, 0.5), seed_offset + 17.0, 23.0, t * 0.62, pixel, green) * 0.45;
		if (quality >= 2) {
			float rail = stroke(abs(cell.x - 0.03), 0.008, pixel * 34.0);
			detail += green * rail * tail * 0.023;
			detail += data_stream(p + vec2(aspect * 0.5, 0.5), seed_offset - 9.0, 54.0, t * 1.45, pixel, green) * 0.24;
		}
	}

	vec2 arena_uv = (uv * size - arena_rect.xy) / max(arena_rect.zw, vec2(1.0));
	vec2 arena_edge = min(arena_uv, vec2(1.0) - arena_uv);
	float inside = smoothstep(-0.025, 0.045, min(arena_edge.x, arena_edge.y));
	float center_distance = length((arena_uv - 0.5) * vec2(1.1, 1.6));
	float quiet_center = mix(0.20, 0.68, smoothstep(0.12, 0.72, center_distance));
	float composition = mix(0.68, quiet_center, inside);
	float vignette = 1.0 - smoothstep(0.35, 1.15, length(p * vec2(0.65, 1.0))) * 0.25;
	vec3 color = base + (haze * mix(0.85, 0.48, inside) + detail * composition) * clamp(strength, 0.0, 1.0);
	color *= vignette;
	color = pow(max(color, vec3(0.0)), vec3(0.76));
	COLOR = vec4(clamp(color, vec3(0.0), vec3(0.28, 0.33, 0.38)), opacity);
}

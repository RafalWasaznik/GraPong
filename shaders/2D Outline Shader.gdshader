shader_type canvas_item;
render_mode unshaded;

uniform int width : hint_range(0, 5, 1) = 1;
uniform vec4 outline_color : source_color = vec4(0.33, 0.85, 0.95, 0.65);
uniform float flickering_speed : hint_range(0.0, 50.0, 1.0) = 0.0;
uniform float minimal_flickering_alpha : hint_range(0.0, 1.0, 0.1) = 0.85;

varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

float alpha_at(vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(TEXTURE, uv).a;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float neighbor_alpha = 0.0;
	for (int x = -5; x <= 5; x++) {
		for (int y = -5; y <= 5; y++) {
			if (abs(x) <= width && abs(y) <= width) {
				neighbor_alpha = max(neighbor_alpha, alpha_at(UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE));
			}
		}
	}
	float pulse = flickering_speed > 0.0 ? mix(minimal_flickering_alpha, 1.0, sin(TIME * flickering_speed) * 0.5 + 0.5) : 1.0;
	float outline_alpha = neighbor_alpha * outline_color.a * pulse * (1.0 - original.a);
	float alpha = original.a + outline_alpha;
	vec3 color = (original.rgb * original.a + outline_color.rgb * outline_alpha) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha) * vertex_tint;
}

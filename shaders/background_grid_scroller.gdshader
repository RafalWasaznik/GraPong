shader_type canvas_item;
render_mode unshaded;

uniform vec4 bg_color : source_color = vec4(0.025, 0.045, 0.075, 1.0);
uniform vec4 line_color : source_color = vec4(0.16, 0.32, 0.40, 0.13);
uniform vec4 glow_color : source_color = vec4(0.12, 0.55, 0.65, 0.10);
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform float grid_size : hint_range(0.01, 0.2) = 0.08;
uniform float line_thickness : hint_range(0.0001, 0.05) = 0.0008;
uniform float scroll_speed : hint_range(0.0, 0.2) = 0.008;
uniform float motion_strength : hint_range(0.0, 0.02) = 0.001;
uniform float motion_speed1 : hint_range(0.0, 0.1) = 0.03;
uniform float motion_speed2 : hint_range(0.0, 0.1) = 0.015;

uniform bool use_custom_time = false;
uniform float animation_time = 0.0;

void fragment() {
	float t = use_custom_time ? animation_time : TIME;
	vec4 modulation = COLOR;
	vec2 uv = UV * vec2(rect_size.x / max(rect_size.y, 1.0), 1.0);
	float wave1 = sin((uv.x + uv.y) * 10.0 + t * motion_speed1);
	float wave2 = sin((uv.x - uv.y) * 50.0 + t * motion_speed2);
	vec2 scrolled = uv + vec2((wave1 + wave2) * 0.5 * motion_strength + t * scroll_speed);
	vec2 cell = abs(fract(scrolled / grid_size + 0.5) - 0.5) * grid_size;
	float distance_to_line = min(cell.x, cell.y);
	float antialias = max(fwidth(distance_to_line), 0.0001);
	float lines = 1.0 - smoothstep(line_thickness, line_thickness + antialias, distance_to_line);
	float vignette = 1.0 - smoothstep(0.12, 0.75, length(UV - vec2(0.5)));
	float pulse = 0.65 + sin(t * 0.4) * 0.15;
	vec3 color = mix(bg_color.rgb, line_color.rgb, lines * line_color.a);
	color += glow_color.rgb * glow_color.a * vignette * pulse;
	COLOR = vec4(color, bg_color.a) * modulation;
}

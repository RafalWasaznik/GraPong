shader_type canvas_item;
render_mode unshaded;

uniform vec4 color1 : source_color = vec4(0.33, 0.85, 0.95, 1.0);
uniform vec4 color2 : source_color = vec4(0.96, 0.99, 1.0, 1.0);
uniform float threshold : hint_range(0.001, 2.0) = 0.4;
uniform float intensity : hint_range(0.0, 2.0) = 0.35;
uniform float opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 glow_color : source_color = vec4(0.25, 0.82, 1.0, 1.0);

void fragment() {
	vec4 pixel_color = COLOR;
	float difference = min(length(pixel_color.rgb - color1.rgb), length(pixel_color.rgb - color2.rgb));
	float selection = 1.0 - smoothstep(threshold * 0.5, threshold, difference);
	vec3 glow = glow_color.rgb * intensity * opacity * selection;
	COLOR = vec4(pixel_color.rgb + glow, pixel_color.a);
}

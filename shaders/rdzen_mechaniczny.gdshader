shader_type canvas_item;
render_mode unshaded;
uniform float faza = 0.0;
uniform vec4 energia : source_color = vec4(0.3, 0.9, 1.0, 1.0);
void fragment() {
	float pas = 0.5 + 0.5 * sin(UV.y * 18.0 - faza * 3.0);
	COLOR = vec4(energia.rgb * (0.7 + 0.3 * pas), energia.a);
}

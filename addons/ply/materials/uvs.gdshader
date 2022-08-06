shader_type spatial;

void fragment() {
	ALBEDO = fract(vec3(UV.x, UV.y, 0.0));
}

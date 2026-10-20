shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.30, 0.65, 0.8, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.25;
uniform float strength : hint_range(0.0, 1.0) = 0.14;

void fragment() {
	float distance_from_center = length(UV - vec2(0.5)) * 2.0;
	float rings = pow(max(0.0, sin(distance_from_center * 45.0 - TIME * speed * 45.0)), 12.0);
	float fade = smoothstep(1.0, 0.1, distance_from_center);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb;
	ALPHA = rings * fade * strength;
}

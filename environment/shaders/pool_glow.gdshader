shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 pool_color : source_color = vec4(0.8, 0.84, 0.67, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	float radius = length(UV - vec2(0.5)) * 2.0;
	float core = exp(-radius * radius * 7.0);
	float soft_edge = 1.0 - smoothstep(0.65, 1.0, radius);
	float shimmer = 0.94 + 0.06 * sin(TIME * 2.7 + UV.x * 19.0 + UV.y * 13.0);
	ALBEDO = pool_color.rgb;
	EMISSION = pool_color.rgb * 1.4;
	ALPHA = core * soft_edge * intensity * shimmer;
}

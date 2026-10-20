shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform sampler2D streaks : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.35, 0.73, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 8.0) = 1.65;
uniform float fall_speed : hint_range(0.0, 5.0) = 0.85;
uniform float opacity : hint_range(0.0, 1.0) = 0.65;

void vertex() {
	VERTEX.x += sin(VERTEX.y * 8.0 + TIME * 3.0) * 0.005;
	VERTEX.z += cos(VERTEX.y * 6.0 + TIME * 2.5) * 0.005;
}

void fragment() {
	float threads = texture(streaks, vec2(UV.x * 2.0, UV.y * 1.6 + TIME * fall_speed)).r;
	float sparkle = texture(streaks, vec2(UV.x * 5.0 + 0.17, UV.y * 4.0 + TIME * fall_speed * 1.45)).r;
	float ends = smoothstep(0.0, 0.025, UV.y) * smoothstep(0.0, 0.06, 1.0 - UV.y);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * brightness;
	ALPHA = (threads * 0.8 + sparkle * 0.24) * opacity * ends;
}

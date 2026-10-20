shader_type spatial;
render_mode cull_disabled;

uniform sampler2D ripple_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 water_color : source_color = vec4(0.30, 0.31, 0.25, 1.0);
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.32;
uniform float flow_speed : hint_range(0.0, 0.1) = 0.012;
uniform float roughness : hint_range(0.0, 1.0) = 0.14;

void fragment() {
	vec2 uv_a = UV * 6.0 + TIME * vec2(flow_speed, flow_speed * 0.35);
	vec2 uv_b = UV * 8.3 + TIME * vec2(-flow_speed * 0.5, flow_speed * 0.65);
	vec3 a = texture(ripple_normal, uv_a).rgb;
	vec3 b = texture(ripple_normal, uv_b).rgb;
	NORMAL_MAP = mix(a, b, 0.45);
	NORMAL_MAP_DEPTH = ripple_strength;
	ALBEDO = water_color.rgb;
	METALLIC = 0.86;
	ROUGHNESS = roughness;
	SPECULAR = 0.85;
}

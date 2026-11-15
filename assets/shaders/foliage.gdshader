shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform float strength = 0.08;
void vertex() {
 vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 float bend = max(VERTEX.y, 0.0);
 VERTEX.x += sin(TIME * 1.3 + world.x * 0.35 + world.z * 0.23) * bend * strength;
 VERTEX.z += cos(TIME * 0.9 + world.z * 0.3) * bend * strength * 0.4;
}
void fragment() {
 vec4 c = texture(albedo_tex, UV) * tint;
 ALBEDO = c.rgb; ROUGHNESS = 0.94;
 ALPHA = c.a; ALPHA_SCISSOR_THRESHOLD = 0.45;
}

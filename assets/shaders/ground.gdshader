shader_type spatial;
uniform sampler2D ground_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D path_tex : source_color, filter_linear_mipmap_anisotropic;
uniform bool forest = false;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 uv = world_pos.xz;
 vec3 soil = texture(ground_tex, uv * 0.18).rgb;
 vec3 broad = texture(ground_tex, uv * 0.037).rgb;
 soil *= mix(vec3(0.82), broad * 0.7 + 0.65, 0.40);
 if (forest) {
  float curve = sin(uv.y * 0.14) * 3.0;
  float path = 1.0 - smoothstep(1.3, 3.0, abs(uv.x - curve));
  vec3 dirt = texture(path_tex, uv * 0.23).rgb * vec3(0.62, 0.57, 0.46);
  soil = mix(soil * vec3(0.70, 0.77, 0.59), dirt, path * 0.85);
 }
 ALBEDO = soil; ROUGHNESS = 1.0; SPECULAR = 0.15;
}

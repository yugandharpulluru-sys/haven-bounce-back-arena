shader_type canvas_item;
void fragment() {
 float left = 1.0 - smoothstep(0.30, 0.76, UV.x);
 float bottom = smoothstep(0.83, 1.0, UV.y);
 COLOR = vec4(vec3(0.025,0.04,0.047), clamp(0.10 + left * 0.81 + bottom * 0.25, 0.0, 0.97));
}

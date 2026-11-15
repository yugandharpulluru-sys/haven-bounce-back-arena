shader_type canvas_item;
void fragment() {
 float left = 1.0 - smoothstep(0.25, 0.82, UV.x);
 float edge = smoothstep(0.5,1.0,abs(UV.y-0.5)*2.0);
 COLOR = vec4(vec3(0.035,0.04,0.045), 0.32 + left * 0.59 + edge * 0.08);
}

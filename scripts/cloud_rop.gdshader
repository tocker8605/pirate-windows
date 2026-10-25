shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	ivec3 destination = ivec3(round(texture(screen_texture, SCREEN_UV).rgb * 255.0));
	ivec3 source = ivec3(round(texture(TEXTURE, UV).rgb * 255.0));
	ivec3 mask = ivec3(round(texture(TEXTURE, UV + vec2(0.5, 0.0)).rgb * 255.0));
	COLOR = vec4(vec3((mask & (~destination)) ^ source) / 255.0, 1.0);
}

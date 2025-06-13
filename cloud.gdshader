shader_type spatial;
//render_mode cull_disabled;

uniform sampler2D noise_1;
uniform sampler2D UVsphere;
uniform sampler2D new_text : repeat_disable;
uniform float uv_thing;
uniform float uv_thing2;
uniform float effect;

void vertex() {
	vec4 new_texture = texture(new_text, vec2(UV.x / uv_thing - uv_thing2, UV.y / uv_thing - uv_thing2));
	vec4 UVsphere_texture = texture(UVsphere, UV);
	vec4 spherical_noise = texture(noise_1, UVsphere_texture.rg + TIME / 100.0);
	vec4 new = spherical_noise * (1.0 - new_texture);
	VERTEX.z = VERTEX.z + new.r * effect;
}

void fragment() {
	vec4 new_texture = texture(new_text, vec2(UV.x / uv_thing - uv_thing2, UV.y / uv_thing - uv_thing2));
	vec4 UVsphere_texture = texture(UVsphere, UV);
	vec4 spherical_noise = texture(noise_1, UVsphere_texture.rg + TIME / 100.0);
	vec4 new = spherical_noise * (1.0 - new_texture);

	//vec4 color = texture(spherical_noise,UV);
	ALBEDO = new.rgb;
	ALPHA = new.r * 1.5;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

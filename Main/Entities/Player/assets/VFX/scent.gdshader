shader_type spatial;
render_mode blend_add, cull_disabled;

uniform sampler2D crack_texture;
uniform sampler2D curve;  // For controlling the height/width distribution
uniform sampler2D curve_domain;  // For controlling the height/width distribution
uniform float fade_height = 1.0;
uniform float width_scale = 1.0;
uniform sampler2D texture_a;
uniform float noise_threshold = 0.5; // Add threshold control
uniform float noise_smoothness = 0.5;
uniform float test = 0.5;
uniform sampler2D albedo_mult;
uniform bool albedo_active;
void fragment() {
	vec4 albedo_mult_tex = texture(albedo_mult, UV);
    // Sample your curve texture to get height variation
	vec4 curve_tex = texture(curve, UV);
	float height_mod = curve_tex.r;
	float thing = smoothstep(curve_tex.r - test, curve_tex.r + test, UV.y);
	vec4 crack = texture(crack_texture, vec2(UV.x * width_scale + TIME / 5.0, UV.y + curve_tex.r));
    // Use it to modify your alpha
	float alpha = smoothstep(height_mod * fade_height, height_mod * fade_height - 0.2, 1.0 - UV.y);
	float noise_mask = smoothstep(noise_threshold - noise_smoothness, noise_threshold + noise_smoothness,crack.r);

	vec4 color = texture(texture_a, vec2(UV.x, UV.y ));
	ALPHA = alpha;
	ALBEDO = crack.xyz;
	if (albedo_active) {
		ALBEDO = crack.xyz + albedo_mult_tex.xyz;
	}
}

void vertex(){
	vec4 curve_tex = texture(curve, UV);
	vec4 crack = texture(crack_texture, vec2(UV.x * width_scale + TIME / 5.0, UV.y + curve_tex.r));
	vec4 cd = texture(curve_domain, UV);
	VERTEX.xyz += cd.xyz;
	VERTEX.z += sin(TIME)/2.0 +0.5;
	NORMAL.xyz = crack.xyz;
	//VERTEX.xz += NORMAL.xz * curve_tex.xz;
}
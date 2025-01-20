shader_type spatial;
render_mode blend_mix, specular_schlick_ggx, depth_prepass_alpha;
uniform sampler2D TXT;
uniform float intensity : hint_range(1.000, 5.000);

void vertex() {
	VERTEX.y += VERTEX.y * texture(TXT, UV + TIME / 4.0).x * intensity;
}
void light() {
    if (ATTENUATION > 0.0) {
        DIFFUSE_LIGHT = vec3(2.0 * texture(TXT, vec2(UV.x + TIME / 4.0, UV.y + TIME  / 2.0)).r, 2.0 * texture(TXT, vec2(UV.x + TIME / 2.0, UV.y + TIME *2.0)).r, 2.0 * texture(TXT, vec2(UV.x + TIME, UV.y + TIME *2.0)).r);
    }
}
void fragment() {
	ALBEDO = texture(TXT, vec2(UV.x + TIME / 8.0, UV.y + TIME  / 4.0)).xyz;
	ALPHA = texture(TXT, vec2(UV.x + TIME / 8.0, UV.y + TIME  / 4.0)).r * 2.0;
	SPECULAR = 2.0;
	METALLIC = 0.3;
	ROUGHNESS = 1.0;
}


//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

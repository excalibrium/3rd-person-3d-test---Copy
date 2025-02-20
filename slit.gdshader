shader_type spatial;
render_mode shadows_disabled, cull_disabled;

uniform sampler2D slit : hint_default_white, filter_linear;
uniform sampler2D color_lookup : source_color,hint_default_white;
uniform float emission_strength : hint_range(0.0, 50.0, 0.1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color_texture = texture(color_lookup, UV);
	vec4 slit_texture = texture(slit, UV);
	ALBEDO = slit_texture.rgb * color_texture.rgb;
	ALPHA = slit_texture.r * color_texture.a;
	EMISSION = color_texture.rgb * emission_strength * slit_texture.r;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

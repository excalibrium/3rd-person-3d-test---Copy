shader_type spatial;
uniform sampler2D texture_albedo : hint_default_white, repeat_disable;
uniform sampler2D texture_gradient : hint_default_white;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0);
uniform float wind_speed = 1.0;
uniform float wind_strength = 0.5;
uniform vec2 wind_direction = vec2(0.1, 0.0);

void vertex() {
    // Extract the vertex position relative to the mesh center
    vec3 vertex_position = VERTEX - vec4(0.0, 0.0, 0.0, 0.1).xyz;

    // Calculate the distance from the vertex to the mesh center
    float distance_from_center = length(vertex_position);

    // Calculate the wind offset and intensity based on the distance from the center
    float wind_offset = distance_from_center / vec4(0.0, 0.0, 0.0, 0.1).w;
    float wind_intensity = 1.0 - wind_offset;

    // Apply the wind movement
    vec3 wind_displacement = vec3(
        wind_direction.x / 1000.0 * wind_offset * wind_speed * wind_strength,
        0.0,
        wind_direction.y / 1000.0 * wind_offset * wind_speed * wind_strength
    );
    VERTEX += wind_displacement;
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	if (tex.a < alpha_scissor_threshold) {
		discard;
	}
	ALBEDO = tex.rbg;

}
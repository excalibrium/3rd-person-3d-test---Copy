shader_type spatial;
render_mode cull_disabled, blend_mix, specular_schlick_ggx, depth_prepass_alpha, diffuse_lambert_wrap;

// Color controls
uniform vec3 top_color: source_color;
uniform vec3 bottom_color: source_color;
uniform vec3 yellow_color: source_color = vec3(1.0, 0.9, 0.2);
uniform float yellow_threshold: hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float yellow_intensity: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float tall_grass_threshold: hint_range(0.0, 1.0, 0.01) = 0.7;

// Global wind parameters (can be shader globals)
global uniform vec3 wind_direction;
global uniform float wind_strength;
global uniform float wind_speed;

// Noise controls
global uniform sampler2D global_noise;
uniform float global_noise_size: hint_range(0.0, 1.0, 0.001) = 0.05;
uniform float global_noise_speed: hint_range(0.0, 1.0, 0.001) = 0.1;
uniform sampler2D simplex_noise;
uniform float simplex_noise_size: hint_range(0.0, 1.0, 0.001) = 0.1;

// Grass shape controls
uniform float grass_height_scale: hint_range(0.1, 5.0, 0.1) = 1.5;
uniform float grass_width_scale: hint_range(-2.0, 4.0, 0.05) = 0.7;
uniform float vertical_displacement_strength: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform sampler2D testure_tester;

// Player interaction
uniform vec3 player_position;
uniform float player_displacement_strength: hint_range(0.0, 1000.0, 0.01) = 0.4;
uniform float player_displacement_size: hint_range(0.0, 5.0, 0.01) = 1.0;

varying float grass_height;

// Utility functions
vec3 rotate_vertex(vec3 vertex, vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    mat3 rot_mat = mat3(
        vec3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s),
        vec3(oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s),
        vec3(oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c)
    );

    return rot_mat * vertex;
}

vec2 sample_noise(sampler2D noise_tex, vec2 pos, float size, float speed) {
    return texture(noise_tex, pos * size + TIME * speed).rg * 2.0 - 1.0;
}

void vertex() {
    // Get world position
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Basic grass shape
    VERTEX.y *= grass_height_scale;
    float width_factor = mix(grass_width_scale, 1.0, UV.y);
    VERTEX.xz *= width_factor;

    // Sample noise for movement
    vec2 noise = sample_noise(global_noise, world_pos.xz, global_noise_size, global_noise_speed * wind_speed);
    float vertical_noise = texture(simplex_noise, world_pos.xz * simplex_noise_size).r * 2.0 - 1.0;

    // Wind rotation
    float height_factor = UV.y;  // More movement at the top
    float rotation_angle = noise.x * wind_strength * height_factor;

    // Apply rotational wind
    vec3 wind_offset = rotate_vertex(
        VERTEX,
        normalize(wind_direction),
        rotation_angle
    );

    // Add noise-based displacement
    wind_offset.xz += noise * wind_strength * (1.0 - UV.y) * grass_height_scale;

    // Vertical displacement
    wind_offset.y *= 1.0 + vertical_noise * vertical_displacement_strength;

    // Player interaction
    float player_height = smoothstep(1.0, 0.0, length(player_position.y - world_pos.y + 0.3));
    vec3 push_direction = vec3(world_pos - player_position) * vec3(1, -0.3, 1);
    float player_position_factor = smoothstep(player_displacement_size, 0.0, length(push_direction));
    vec3 player_push_vector = (vec4(normalize(push_direction), 0.0) * MODEL_MATRIX).xyz;

    // Combine all movements
    VERTEX = wind_offset +
            player_push_vector * (1.0 - UV.y) *
            player_position_factor *
            player_displacement_strength *
            player_height *
            grass_height_scale;

    // Store grass height for fragment shader
    grass_height = (vertical_noise + 1.0) * 0.5;
}

void fragment() {
	vec4 testure = texture(testure_tester, UV);
    // Base color gradient
    vec3 base_color = mix(bottom_color, top_color, 1.0 - UV.y);

    // Yellow coloring for tall grass
    if (grass_height > tall_grass_threshold) {
        float yellow_factor = smoothstep(yellow_threshold, 1.0, 1.0 - UV.y);
        base_color = mix(base_color, yellow_color,
            yellow_factor * yellow_intensity *
            (grass_height - tall_grass_threshold) /
            (1.0 - tall_grass_threshold));
    }
    ALPHA = testure.a;
    ALBEDO = base_color;
    ROUGHNESS = 0.6;
    SPECULAR = 0.0 * (1.0 - UV.y);
    NORMAL_MAP = vec3(0.0, 1.0, 0.0);

}

//void light() {
	//DIFFUSE_LIGHT = vec3(0.5);
    //if (ATTENUATION > 0.25) {
        //DIFFUSE_LIGHT = vec3(0.5);
    //}
//}
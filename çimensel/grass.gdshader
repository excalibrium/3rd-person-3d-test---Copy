shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec3 top_color: source_color;
uniform vec3 bottom_color: source_color;
uniform vec3 yellow_color: source_color = vec3(1.0, 0.9, 0.2);
uniform float yellow_threshold: hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float yellow_intensity: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float tall_grass_threshold: hint_range(0.0, 1.0, 0.01) = 0.7;

uniform float player_displacement_strength: hint_range(0.0, 50.0, 0.01) = 0.4;
uniform float player_displacement_size: hint_range(0.0, 2.0, 0.01) = 1.0;

uniform vec3 wind_direction;
uniform float wind_strength: hint_range(0.0, 10.0, 0.01) = 0.3;
uniform sampler2D global_noise;
uniform float global_noise_size: hint_range(0.0, 1.0, 0.001) = 0.05;
uniform float global_noise_speed: hint_range(0.0, 1.0, 0.001) = 0.1;

uniform vec3 player_position;

uniform float vertical_displacement_strength: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform sampler2D simplex_noise;
uniform float simplex_noise_size: hint_range(0.0, 1.0, 0.001) = 0.1;

uniform float grass_height_scale: hint_range(1.0, 5.0, 0.1) = 1.5;
uniform float grass_width_scale: hint_range(-2.0, 4.0, 0.05) = 0.7;

varying float grass_height;

vec2 global_noise_func(vec2 pos) {
    return texture(global_noise, pos * global_noise_size + TIME * global_noise_speed).rg * 2.0 - 1.0;
}

float simplex_noise_func(vec2 pos) {
    return texture(simplex_noise, pos * simplex_noise_size).r * 2.0 - 1.0;
}

void vertex() {
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Scale height
    VERTEX.y *= grass_height_scale;

    // Scale width (x and z) with gradient towards top
    float width_factor = mix(grass_width_scale, 1.0, UV.y);
    VERTEX.x *= width_factor;
    VERTEX.z *= width_factor;

    // Global noise for horizontal displacement
    vec2 noise = global_noise_func(world_position.xz);
    VERTEX.x += noise.x * wind_strength * (1.0 - UV.y) * grass_height_scale;
    VERTEX.z += noise.y * wind_strength * (1.0 - UV.y) * grass_height_scale;

    // Simplex noise for vertical displacement
    float vertical_noise = simplex_noise_func(world_position.xz);
    VERTEX.y *= 1.0 + vertical_noise * vertical_displacement_strength;

    // Player displacement
    float player_height = smoothstep(1.0, 0.0, length(player_position.y - world_position.y + 0.3));
    vec3 push_direction = vec3(world_position - player_position) * vec3(1, -0.3, 1);
    float player_position_factor = smoothstep(player_displacement_size, 0.0, length(push_direction));

    vec3 player_push_vector = (vec4(normalize(push_direction), 0.0) * MODEL_MATRIX).xyz;

    VERTEX += player_push_vector * (1.0 - UV.y) * player_position_factor * player_displacement_strength * player_height * grass_height_scale;

    // Pass grass height to fragment shader
    grass_height = (vertical_noise + 1.0) * 0.5; // Normalize to 0-1 range
}

void fragment() {
    // Calculate base color gradient
    vec3 base_color = mix(bottom_color, top_color, 1.0 - UV.y);

    // Apply yellow only to tall grass
    if (grass_height > tall_grass_threshold) {
        float yellow_factor = smoothstep(yellow_threshold, 1.0, 1.0 - UV.y);
        base_color = mix(base_color, yellow_color, yellow_factor * yellow_intensity * (grass_height - tall_grass_threshold) / (1.0 - tall_grass_threshold));
    }

    ALBEDO = base_color;
    ROUGHNESS = 0.6;
    SPECULAR *= (0.4 - UV.y);
    NORMAL_MAP = vec3(0, 1, 0);
}
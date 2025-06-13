shader_type spatial;
render_mode cull_disabled, blend_mix, specular_schlick_ggx, depth_prepass_alpha, diffuse_lambert_wrap;

// Color controls
uniform vec3 top_color: source_color;
uniform vec3 bottom_color: source_color;
uniform vec3 yellow_color: source_color = vec3(1.0, 0.9, 0.2);
uniform float yellow_threshold: hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float yellow_intensity: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float tall_grass_threshold: hint_range(0.0, 1.0, 0.01) = 0.7;
uniform vec3 em;

// Global wind parameters (can be shader globals)
global uniform vec3 wind_direction;
global uniform float wind_strength;
global uniform float wind_speed;

// Noise controls (consolidated for performance)
uniform sampler2D global_noise;
uniform float global_noise_size: hint_range(0.0, 1.0, 0.001) = 0.05;
uniform float global_noise_speed: hint_range(0.0, 1.0, 0.001) = 0.1;
uniform sampler2D simplex_noise;
uniform float simplex_noise_size: hint_range(0.0, 1.0, 0.001) = 0.1;

// Grass shape controls
uniform float grass_height_scale: hint_range(0.1, 5.0, 0.1) = 1.5;
uniform float grass_width_scale: hint_range(-2.0, 4.0, 0.05) = 0.7;
uniform float vertical_displacement_strength: hint_range(0.0, 2.0, 0.01) = 0.5;
uniform float height_variation_contrast: hint_range(0.1, 5.0, 0.1) = 2.0;
uniform float height_distribution_sharpness: hint_range(0.1, 5.0, 0.1) = 1.5;
uniform sampler2D testure_tester;

// Normal map controls
uniform float normal_strength: hint_range(0.0, 2.0, 0.01) = 0.5;
uniform float normal_variation: hint_range(0.0, 1.0, 0.01) = 0.2;

// Player interaction
uniform vec3 player_position;
uniform float player_displacement_strength: hint_range(0.0, 1000.0, 0.01) = 0.4;
uniform float player_displacement_size: hint_range(0.0, 5.0, 0.01) = 1.0;

varying float grass_height;
varying vec3 wind_influence;
varying vec2 wind_noise_val;

// Optimized rotation function using a faster approach than full matrix multiplication
vec3 fast_rotate(vec3 vertex, vec3 axis, float angle) {
    // Rodrigues rotation formula - more efficient than full matrix construction
    return vertex * cos(angle) +
           cross(axis, vertex) * sin(angle) +
           axis * dot(axis, vertex) * (1.0 - cos(angle));
}

void vertex() {
    // Get world position (using highp for necessary precision but minimizing extra calculations)
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Sample both noises at once with a single texture fetch when possible
    vec4 noise_samples = texture(global_noise, world_pos.xz * global_noise_size + TIME * global_noise_speed * wind_speed);
    vec2 wind_noise = noise_samples.rg * 2.5 - 1.0;
    wind_noise_val = wind_noise; // Save for fragment shader

    // Sample height noise with a single texture fetch
    float raw_height_noise = texture(simplex_noise, world_pos.xz * simplex_noise_size).r * 2.0 - 1.0;

    // Pre-compute height factors for reuse
    float normalized_noise = (raw_height_noise + 1.0) * 0.5;
    float contrasted = pow(normalized_noise, height_variation_contrast);
    float discrete_heights = pow(contrasted, height_distribution_sharpness);
    float processed_height = mix(normalized_noise, discrete_heights, 0.8);

    // Calculate a height scaling factor that ranges from 0.6 to 1.4
    float height_factor = mix(0.6, 1.4, processed_height);
    float uv_y_inv = 1.0 - UV.y; // Calculate once and reuse

    // Apply basic grass shape with variable height
    vec3 deformed_vertex = VERTEX;
    deformed_vertex.y *= grass_height_scale * height_factor;
    deformed_vertex.xz *= mix(grass_width_scale, 1.0, UV.y);

    // Wind rotation with optimized calculation
    float rotation_angle = wind_noise.x * wind_strength * UV.y;
    vec3 wind_offset = fast_rotate(deformed_vertex, normalize(wind_direction), rotation_angle);

    // Add optimized noise-based displacement
    wind_offset.xz += wind_noise * wind_strength * uv_y_inv * grass_height_scale;

    // Apply vertical displacement more efficiently
    wind_offset.y *= 1.0 + raw_height_noise * vertical_displacement_strength;

    // Store wind influence factor for fragment shader normal calculation
    wind_influence = vec3(
        wind_noise.x * wind_strength * UV.y,
        0.0,
        wind_noise.y * wind_strength * UV.y
    );

    // Player interaction (optimized calculations)
    float y_diff = player_position.y - world_pos.y + 0.3;
    float player_height = smoothstep(1.0, 0.0, abs(y_diff));

    vec3 push_direction = world_pos - player_position;
    push_direction.y *= -0.3;

    float dist_sq = dot(push_direction.xz, push_direction.xz); // Squared distance is faster than length()
    float player_position_factor = smoothstep(player_displacement_size * player_displacement_size, 0.0, dist_sq);

    // Normalize only if necessary (when player is close enough)
    vec3 player_push_vector;
    if (player_position_factor > 0.01) {
        player_push_vector = push_direction / sqrt(dist_sq + push_direction.y * push_direction.y);
        player_push_vector = (vec4(player_push_vector, 0.0) * MODEL_MATRIX).xyz;

        // Apply player displacement
        VERTEX = wind_offset +
                player_push_vector * uv_y_inv *
                player_position_factor *
                player_displacement_strength *
                player_height *
                grass_height_scale;
    } else {
        // Skip player calculations if too far away
        VERTEX = wind_offset;
    }

    // Store grass height for fragment shader
    grass_height = processed_height;
}

void fragment() {
    vec4 tex = texture(testure_tester, UV);

    // Simple color gradient
    vec3 base_color = mix(bottom_color, top_color, 1.0 - UV.y);

    // Yellow coloring for tall grass (only apply if needed)
    if (grass_height > tall_grass_threshold) {
        float height_diff = grass_height - tall_grass_threshold;
        float yellow_factor = smoothstep(yellow_threshold, 1.0, 1.0 - UV.y) *
                             yellow_intensity *
                             height_diff / (1.0 - tall_grass_threshold);
        base_color = mix(base_color, yellow_color, yellow_factor);
    }

    // Generate proper normal map based on blade orientation
    // Start with a default normal pointing upward
    vec3 normal = vec3(0.0, 1.0, 0.0);

    // Modify normal based on UV position on the blade (more bent at top)
    float blade_bend = (1.0 - UV.y) * normal_strength;

    // Add variation based on blade height and noise
    float noise_factor = sin(UV.x * 6.28) * normal_variation;

    // Adjust normal based on wind influence (bend in wind direction)
    normal.x += wind_influence.x * blade_bend;
    normal.z += wind_influence.z * blade_bend;

    // Add some variation to avoid uniform lighting
    normal.x += noise_factor * (1.0 - UV.y);

    // Make sure normal stays normalized
    normal = normalize(normal);

    // Convert to normal map format (from -1,1 to 0,1 range)
    vec3 normal_map = normal * 0.5 + 0.5;

    ALPHA = tex.a;
    ALBEDO = tex.rgb * base_color;
    ROUGHNESS = 0.6;
    SPECULAR = 0.1;
    EMISSION = em / 2.0;
    // Apply the normal map with texture influence
    NORMAL_MAP = normal_map;
}

//void light() {
    //DIFFUSE_LIGHT = vec3(0.5);
    //if (ATTENUATION > 0.99) {
        //DIFFUSE_LIGHT = vec3(0.5);
    //}
//}
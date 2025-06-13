shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;
// Wind control
uniform bool wind_active = true;
global uniform float wind_speed = 1.0;
global uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);  // Global wind direction
global uniform float wind_strength = 1.0;                   // Global wind strength

// Noise control
global uniform sampler2D global_noise : hint_default_white;   // Noise texture for wind variation
uniform float noise_scale = 1.0;                     // Scale of the noise pattern
uniform float rotation_strength = 1.0;               // How much the wind affects rotation

// Branch control
uniform bool is_branch = false;
uniform float alpha_scissor_threshold : hint_range(0, 1) = 0.5;
uniform float threshold_dist_modifier : hint_range(0, 1) = 1.0;

// Material properties
uniform vec4 albedo_color : source_color = vec4(1.0);

uniform sampler2D texture_normal : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_backlight : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 backlight_color : source_color = vec4(1.0);

// Wind parameters
uniform vec3 wind_size = vec3(10.0, 5.0, 2.0);   // Scale of wind effect
uniform vec3 wind_power = vec3(0.1, 0.05, 0.02);  // Strength of wind effect

vec3 rotate_vertex(vec3 vertex, vec3 axis, float angle) {
    // Rotate vertex around axis by angle
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

void vertex() {
    if (wind_active) {
        vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
        vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

        // Transform global wind direction to local space
        vec3 global_wind_direction = normalize(wind_direction);
        vec3 local_wind_direction = normalize((inverse(MODEL_MATRIX) * vec4(global_wind_direction, 0.0)).xyz);

        // Sample wind noise based on world position and time
        vec2 noise_uv = (world_pos.xz / wind_size.x) + (TIME * wind_speed * global_wind_direction.xz);
        vec4 noise = texture(global_noise, noise_uv * noise_scale);

        // Create wind effect based on noise and direction
        vec3 wind_offset = local_wind_direction * noise.r * wind_strength;

        // Height-based movement
        float height_factor = VERTEX.y / wind_size.y;

        // Calculate rotation angle based on noise and wind
        float rotation_angle = noise.g * rotation_strength * wind_strength * height_factor;

        // Apply vertex color modifiers
        float branch_factor = COLOR.z * wind_power.y;  // Blue channel for branch movement
        float flutter_factor = COLOR.x * wind_power.z; // Red channel for flutter
        float time_offset = COLOR.y * 10.0;           // Green channel for timing variation

        // Combine all movements
        vec3 wind_animate = wind_offset * branch_factor * height_factor;

        // Add flutter based on noise
        wind_animate += world_normal * noise.b * flutter_factor;

        // Apply rotation around wind direction
        vec3 rotated_vertex = rotate_vertex(VERTEX + wind_animate, local_wind_direction, rotation_angle);

        // Final position
        VERTEX = rotated_vertex;
    }

    // Transform vertex
    POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
    vec4 albedo = texture(texture_albedo, UV) * albedo_color;
    vec4 normals = texture(texture_normal, UV) * albedo_color;
    ALBEDO = albedo.rgb;
    NORMAL_MAP = normals.rgb;
    NORMAL_MAP_DEPTH = 1.0;
    if (is_branch) {
        ALPHA *= albedo.a;
        ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold * threshold_dist_modifier;
        BACKLIGHT = texture(texture_backlight, UV).rgb * backlight_color.rgb;
    }
}
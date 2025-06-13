shader_type spatial;
render_mode cull_disabled;

// Noise textures
uniform sampler2D small_noise : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D big_noise : source_color, filter_linear_mipmap, repeat_enable;

// UV scaling for different noise frequencies
uniform float small_noise_scale : hint_range(0.1, 10.0) = 4.0;
uniform float big_noise_scale : hint_range(0.1, 10.0) = 1.0;

// Cloud parameters
uniform float cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.1;

// Normal map parameters
uniform float normal_strength : hint_range(0.0, 5.0) = 1.0;
uniform float depth_multiplier : hint_range(0.0, 3.0) = 1.5;

// Animation
uniform float time_scale : hint_range(0.0, 2.0) = 0.2;

vec3 calculate_normal(sampler2D tex, vec2 uv, float scale, float strength) {
    vec2 texel_size = 1.0 / vec2(textureSize(tex, 0));
    
    // Sample neighboring pixels
    float left = texture(tex, uv - vec2(texel_size.x, 0.0) * scale).r;
    float right = texture(tex, uv + vec2(texel_size.x, 0.0) * scale).r;
    float up = texture(tex, uv - vec2(0.0, texel_size.y) * scale).r;
    float down = texture(tex, uv + vec2(0.0, texel_size.y) * scale).r;
    
    // Calculate gradients
    float dx = (right - left) * strength;
    float dy = (down - up) * strength;
    
    // Create normal vector
    vec3 normal = normalize(vec3(dx, dy, 1.0));
    return normal * 0.5 + 0.5; // Convert to 0-1 range
}

void fragment() {
    vec2 animated_uv = UV + vec2(TIME * time_scale * 0.1, TIME * time_scale * 0.05);
    
    // Sample both noise textures
    float small = texture(small_noise, animated_uv * small_noise_scale).r;
    float big = texture(big_noise, animated_uv * big_noise_scale).r;
    
    // Combine noises: big noise controls placement, small noise controls shape
    float combined = small * big;
    
    // Apply cutoff with smooth edges
    float cloud_mask = smoothstep(cutoff - edge_softness, cutoff + edge_softness, combined);
    
    // Create the final cloud value (white = deep, black = shallow)
    float cloud_value = cloud_mask;
    
    // Calculate normal map based on the combined noise
    // Make it deeper (more pronounced) where it's darker
    float depth_factor = cloud_value * depth_multiplier;
    vec3 normal = calculate_normal(small_noise, animated_uv * small_noise_scale, 1.0, normal_strength * depth_factor);
    
    // Output
    ALBEDO = vec3(cloud_value); // Grayscale cloud
    ALPHA = cloud_value; // Black becomes transparent
    NORMAL_MAP = normal;
}
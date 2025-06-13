// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D with water effect added.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Basic material properties
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

// Refraction properties
uniform sampler2D texture_refraction : filter_linear_mipmap, repeat_enable;
uniform float refraction : hint_range(-1.0, 1.0, 0.001);
uniform vec4 refraction_texture_channel;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// UV mapping
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// Water effect parameters
uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float water_speed : hint_range(0.0, 2.0) = 0.1;
uniform float water_noise_strength : hint_range(0.0, 0.2) = 0.05;
uniform vec2 water_direction = vec2(1.0, 1.0);

// Foam parameters
uniform sampler2D foam_noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float foam_amount : hint_range(0.0, 1.0) = 0.5;
uniform float foam_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float foam_speed_multiplier : hint_range(0.01, 2.0) = 1.2;

uniform float water_rotation_angle_degrees : hint_range(0.0, 360.0) = 0.0;

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	float water_rotation_angle = radians(water_rotation_angle_degrees);
	vec2 flow_direction = vec2(cos(water_rotation_angle), sin(water_rotation_angle));
    // Calculate time-based scrolling for water effect
    vec2 water_uv_offset = flow_direction * water_direction * TIME * water_speed;

    // Apply noise to UVs to create water distortion
    vec2 noise_uv = UV + water_uv_offset;
    vec2 noise_value = texture(noise_texture, noise_uv).rg * 2.0 - 1.0;

    // Apply the noise to base UVs with strength control
    vec2 base_uv = UV + noise_value * water_noise_strength;

    // Rest of the material as before
    vec4 albedo_tex = texture(texture_albedo, base_uv);

    // Calculate foam
    // We'll use a different scrolling speed for foam for more interesting effect
    vec2 foam_uv_offset = flow_direction * water_direction * TIME * water_speed * foam_speed_multiplier;
    vec2 foam_uv = UV + foam_uv_offset;

    // Sample foam noise at two different scales for more detailed foam
    float foam_noise1 = texture(foam_noise_texture, foam_uv * 1.0).r;
    float foam_noise2 = texture(foam_noise_texture, foam_uv * 2.5 - vec2(TIME * 0.1, 0.0)).r;

    // Combine noise samples to create more complex pattern
    float foam_mask = (foam_noise1 * 0.7 + foam_noise2 * 0.3);

    // Create foam edges based on noise height
    float foam_edge = smoothstep(foam_cutoff - 0.05, foam_cutoff + 0.05, foam_mask);
    foam_edge *= foam_amount;

    // Add foam to water edges (based on depth)

    float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
    METALLIC = metallic_tex * metallic;
    SPECULAR = specular;

    vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
    float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
    ROUGHNESS = roughness_tex * roughness;

    // Enhanced refraction for water
    vec3 ref_normal = NORMAL + vec3(noise_value * water_noise_strength, 0.0);
    ref_normal = normalize(ref_normal);

	float depth_foam = 1.0 - smoothstep(0.1, 0.4, distance(ref_normal.xy, vec2(0.0)));
    foam_edge = max(foam_edge, depth_foam * foam_amount * 0.5);

    // Mix foam color with water color
    ALBEDO = mix(albedo.rgb * albedo_tex.rgb, foam_color.rgb, foam_edge);
    vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(texture(texture_refraction, base_uv), refraction_texture_channel) * refraction;
    float ref_amount = 1.0 - albedo.a * albedo_tex.a;

    float refraction_depth_tex = textureLod(depth_texture, ref_ofs, 0.0).r;
    vec4 refraction_view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, refraction_depth_tex, 1.0);
    refraction_view_pos.xyz /= refraction_view_pos.w;

    // Calculate foam before applying emission and refraction
    float final_foam_intensity = foam_edge;

    // Apply refraction effect - reduce refraction where foam exists
    float adjusted_ref_amount = ref_amount * (1.0 - final_foam_intensity * 0.7);
    EMISSION += textureLod(screen_texture, mix(SCREEN_UV, ref_ofs, smoothstep(0.0, 1.0, VERTEX.z - refraction_view_pos.z)), ROUGHNESS * 8.0).rgb * adjusted_ref_amount * EXPOSURE;
    ALBEDO *= 1.0 - adjusted_ref_amount;

    // Add slight emission to foam to make it pop
    EMISSION += foam_color.rgb * final_foam_intensity * 0.2;

    // Force transparency on the material (required for refraction)
    ALPHA = 1.0;
}
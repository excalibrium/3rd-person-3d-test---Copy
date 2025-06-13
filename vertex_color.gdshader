shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Textures for material A, B, C, and the transition noise
group_uniforms textures;
uniform sampler2D texture_albedo_a : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm_a : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal_a : hint_roughness_normal, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_albedo_b : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm_b : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal_b : hint_roughness_normal, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_albedo_c : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm_c : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal_c : hint_roughness_normal, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_noise : source_color, filter_linear_mipmap, repeat_enable;

group_uniforms main_settings;
uniform vec4 albedo_a : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 albedo_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 albedo_c : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float normal_scale : hint_range(-16, 16) = 1.0;
uniform float ao_light_affect = 1.0;
uniform float roughness_control : hint_range(0, 2) = 1.0;
uniform float metallic_control : hint_range(0, 2) = 1.0;
uniform sampler2D uv1_scale_texture;
uniform vec3 uv1_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv1_offset;

group_uniforms blend_settings;
uniform float blend_threshold = 0.5;
uniform float blend_noise_intensity = 0.5;
uniform float blend_noise_scale = 2.0;
uniform float blend_softness = 0.5;
uniform vec4 blend_transition_color : source_color = vec4(0.0, 0.0, 0.0, 0.25);

void vertex() {
	vec4 uv1_scale_curve = texture(uv1_scale_texture, UV);
    UV = UV * uv1_scale_curve.xy + uv1_scale_curve.xy;
}

void fragment() {
    vec2 base_uv = UV;
    vec2 noise_uv = UV * blend_noise_scale;

    float mask_a = COLOR.r;
    float mask_b = COLOR.g;
    float mask_c = COLOR.b;

    float noise = texture(texture_noise, noise_uv).r * blend_noise_intensity;
    float threshold = clamp(blend_threshold + noise, 0.0, 1.0);

    float blend_a = smoothstep(threshold - blend_softness, threshold + blend_softness, mask_a);
    float blend_b = smoothstep(threshold - blend_softness, threshold + blend_softness, mask_b);
    float blend_c = smoothstep(threshold - blend_softness, threshold + blend_softness, mask_c);

    float total_blend = blend_a + blend_b + blend_c;
    if (total_blend > 0.0) {
        blend_a /= total_blend;
        blend_b /= total_blend;
        blend_c /= total_blend;
    } else {
        blend_a = 1.0; // Avoid black spots by defaulting to material A
    }

    vec4 albedo_tex_a = texture(texture_albedo_a, base_uv) * albedo_a;
    vec4 albedo_tex_b = texture(texture_albedo_b, base_uv) * albedo_b;
    vec4 albedo_tex_c = texture(texture_albedo_c, base_uv) * albedo_c;

    vec3 albedo_mixed = albedo_tex_a.rgb * blend_a +
                         albedo_tex_b.rgb * blend_b +
                         albedo_tex_c.rgb * blend_c;

    float transition = clamp(1.0 - smoothstep(blend_softness * 0.5, blend_softness * 1.5, abs(mask_a - threshold)), 0.0, 1.0);
    vec3 transition_visual = mix(albedo_mixed.rgb, blend_transition_color.rgb, transition * min(blend_transition_color.a, 0.5));
    ALBEDO = transition_visual;

    vec4 orm_tex_a = texture(texture_orm_a, base_uv);
    vec4 orm_tex_b = texture(texture_orm_b, base_uv);
    vec4 orm_tex_c = texture(texture_orm_c, base_uv);

    ROUGHNESS = (orm_tex_a.g * blend_a +
             orm_tex_b.g * blend_b +
             orm_tex_c.g * blend_c) * roughness_control;

    METALLIC = (orm_tex_a.b * blend_a +
            orm_tex_b.b * blend_b +
            orm_tex_c.b * blend_c) * metallic_control;

    vec3 normal_map_a = texture(texture_normal_a, base_uv).rgb;
    vec3 normal_map_b = texture(texture_normal_b, base_uv).rgb;
    vec3 normal_map_c = texture(texture_normal_c, base_uv).rgb;

    vec3 normal_mixed = normal_map_a * blend_a +
                        normal_map_b * blend_b +
                        normal_map_c * blend_c;

    NORMAL_MAP = normal_mixed;
    NORMAL_MAP_DEPTH = normal_scale;

    AO = orm_tex_a.r * blend_a +
         orm_tex_b.r * blend_b +
         orm_tex_c.r * blend_c;

    AO_LIGHT_AFFECT = ao_light_affect;
}
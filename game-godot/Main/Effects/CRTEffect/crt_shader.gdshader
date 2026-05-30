shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float warp_amount        : hint_range(0.0, 5.0) = 1.0;
uniform float scanline_opacity   : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_width     : hint_range(0.0, 0.5) = 0.25;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity   : hint_range(0.0, 1.0) = 0.5;
uniform float blur_amount        : hint_range(0.0, 1.0) = 0.3;

// --- Warp ---
vec2 warp(vec2 uv, float amount) {
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta, delta);
    return delta * (1.0 + delta2 * amount * 0.1) + 0.5;
}

// --- Screen mask / cutoff ---
float screen_mask(vec2 uv) {
    vec2 edge = smoothstep(0.0, 0.02, uv) * smoothstep(0.0, 0.02, 1.0 - uv);
    return edge.x * edge.y;
}

// --- Scanlines ---
float scanline(vec2 uv, vec2 viewport_size) {
    float line = sin(uv.y * viewport_size.y * PI);
    line = pow(line * 0.5 + 0.5, scanline_width * 10.0);
    return 1.0 - line * scanline_opacity;
}

// --- Vignette ---
float vignette(vec2 uv) {
    uv = uv * (1.0 - uv.yx);
    float vig = pow(uv.x * uv.y * 15.0, vignette_intensity);
    return mix(1.0, vig, vignette_opacity);
}

// --- Blur ---
vec3 blur(vec2 uv, float amount, vec2 viewport_size) {
    vec2 pixel = amount / viewport_size;
    vec3 col = vec3(0.0);
    col += texture(screen_texture, uv + vec2(-2.0, 0.0) * pixel).rgb * 0.06;
    col += texture(screen_texture, uv + vec2(-1.0, 0.0) * pixel).rgb * 0.24;
    col += texture(screen_texture, uv).rgb                             * 0.40;
    col += texture(screen_texture, uv + vec2( 1.0, 0.0) * pixel).rgb * 0.24;
    col += texture(screen_texture, uv + vec2( 2.0, 0.0) * pixel).rgb * 0.06;
    return col;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 viewport_size = vec2(textureSize(screen_texture, 0));

    // 1. Warp
    uv = warp(uv, warp_amount);

    // 2. Cutoff mask
    float mask = screen_mask(uv);

    // 3. Blur (before sampling color)
    vec3 blurred = blur(uv, blur_amount, viewport_size);
    vec4 color = texture(screen_texture, uv);
    color.rgb = mix(color.rgb, blurred, blur_amount);

    // 4. Scanlines
    color.rgb *= scanline(uv, viewport_size);

    // 5. Vignette
    color.rgb *= vignette(uv);

    // 6. Apply mask (black border outside screen)
    COLOR = vec4(color.rgb * mask, 1.0);
}

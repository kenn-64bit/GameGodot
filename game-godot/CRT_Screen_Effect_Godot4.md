# 📺 CRT Screen Effect in Godot 4
**Based on:** [DevPoodle – Making a CRT Shader Effect (YouTube)](https://www.youtube.com/watch?v=E401x98N6iA)  
**Source project:** https://github.com/DevPoodle/yt-examples  
**Engine version:** Godot 4.x (compatible with 4.6.2)  
**Shader type:** `canvas_item` (2D post-processing)

---

## Strict Compliance

This CRT screen effect must overlay main menu, gameplay main levels and win screen, basically the whole game

## Overview

This guide walks through building a full CRT screen shader applied as a **post-processing effect** over your entire game viewport. The shader is attached to a `ColorRect` inside a `CanvasLayer`, so it composites on top of everything else at runtime.

The effect is built in stages:

1. Project settings
2. Post-processing scaffold
3. Screen warping
4. Screen cutoff (black border)
5. Scanlines
6. Vignette
7. Blur

---

---

## Stage 1 — Post-Processing Scaffold

### Scene Setup

```
Root (Node2D or Control)
└── CanvasLayer          ← layer = 128 (renders above everything)
    └── ColorRect        ← full-screen, ShaderMaterial applied here
```

**Steps:**

1. Add a `CanvasLayer` node. Set its **Layer** property to a high value (e.g. `128`) so it sits above all gameplay nodes.
2. Add a `ColorRect` as a child of the `CanvasLayer`.
3. In the `ColorRect`'s **Layout** menu, choose **Full Rect** (or set Anchor Preset to "Full Rect").
4. In the Inspector, set its **Color** to fully transparent (`rgba(0,0,0,0)`).
5. Create a new `ShaderMaterial` on the `ColorRect`, then create a new `Shader` inside it.

### Shader Boilerplate

```glsl
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(screen_texture, uv);
    COLOR = color;
}
```

> `hint_screen_texture` is the Godot 4 way to sample what's already rendered to the screen. `render_mode unshaded` prevents lighting from affecting the overlay.

---

## Stage 2 — Screen Warping

CRT monitors had curved glass. This is simulated by **barrel distortion** — pushing UV coordinates outward from the center.

### Uniforms

```glsl
uniform float warp_amount : hint_range(0.0, 5.0) = 1.0;
```

### Warp Function

```glsl
vec2 warp(vec2 uv, float amount) {
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta, delta);
    float warp_factor = 1.0 + delta2 * amount * 0.1;
    return delta * warp_factor + 0.5;
}
```

### Usage in `fragment()`

```glsl
void fragment() {
    vec2 uv = SCREEN_UV;
    uv = warp(uv, warp_amount);

    vec4 color = texture(screen_texture, uv);
    COLOR = color;
}
```

> Higher `warp_amount` → more curvature. Values of `1.0`–`3.0` look natural. Past `5.0` it becomes fisheye.

---

## Stage 3 — Screen Cutoff (Black Border)

After warping, UVs outside `[0, 1]` sample garbage. Mask those out with a hard black border.

### Mask Function

```glsl
float screen_mask(vec2 uv) {
    vec2 edge = smoothstep(0.0, 0.02, uv) * smoothstep(0.0, 0.02, 1.0 - uv);
    return edge.x * edge.y;
}
```

### Usage in `fragment()`

```glsl
void fragment() {
    vec2 uv = SCREEN_UV;
    uv = warp(uv, warp_amount);

    float mask = screen_mask(uv);
    vec4 color = texture(screen_texture, uv);

    COLOR = vec4(color.rgb * mask, 1.0);
}
```

> `smoothstep(0.0, 0.02, uv)` creates a soft fade at the edges. Adjust `0.02` to control edge softness.

---

## Stage 4 — Scanlines

Scanlines are alternating dark horizontal bands, simulating the electron beam rows of a CRT.

### Uniforms

```glsl
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_width   : hint_range(0.0, 0.5) = 0.25;
```

### Scanline Function

```glsl
float scanline(vec2 uv) {
    // uv.y in screen space, modulated by pixel row
    float line = sin(uv.y * VIEWPORT_SIZE.y * PI);
    line = (line * 0.5 + 0.5);                // remap to [0, 1]
    line = pow(line, scanline_width * 10.0);   // sharpen the bands
    return 1.0 - line * scanline_opacity;
}
```

### Usage in `fragment()`

```glsl
color.rgb *= scanline(uv);
```

> **Tip:** `VIEWPORT_SIZE` gives the actual rendered pixel dimensions. Multiply `uv.y` by this to get per-pixel frequency. Lower `scanline_width` = wider dark bands.

---

## Stage 5 — Vignette

The vignette darkens the corners of the screen, simulating the falloff of a CRT phosphor display.

### Uniforms

```glsl
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity   : hint_range(0.0, 1.0) = 0.5;
```

### Vignette Function

```glsl
float vignette(vec2 uv) {
    uv = uv * (1.0 - uv.yx);          // fold UVs
    float vig = uv.x * uv.y * 15.0;   // scale up
    vig = pow(vig, vignette_intensity);
    return mix(1.0, vig, vignette_opacity);
}
```

### Usage in `fragment()`

```glsl
color.rgb *= vignette(uv);
```

> The `uv * (1.0 - uv.yx)` trick produces a value that's `0` at corners and `1` at center. Raising it to a power controls how sharply it falls off.

---

## Stage 6 — Blur

A subtle Gaussian blur softens the image slightly, mimicking the phosphor glow and imperfect focus of a CRT.

### Uniforms

```glsl
uniform float blur_amount : hint_range(0.0, 1.0) = 0.3;
```

### Blur Function (5-tap horizontal + vertical)

```glsl
vec3 blur(sampler2D tex, vec2 uv, float amount) {
    vec2 pixel = amount / VIEWPORT_SIZE;
    vec3 col = vec3(0.0);
    col += texture(tex, uv + vec2(-2.0, 0.0) * pixel).rgb * 0.06;
    col += texture(tex, uv + vec2(-1.0, 0.0) * pixel).rgb * 0.24;
    col += texture(tex, uv).rgb                             * 0.40;
    col += texture(tex, uv + vec2( 1.0, 0.0) * pixel).rgb * 0.24;
    col += texture(tex, uv + vec2( 2.0, 0.0) * pixel).rgb * 0.06;
    return col;
}
```

### Usage in `fragment()`

```glsl
vec3 blurred = blur(screen_texture, uv, blur_amount);
color.rgb = mix(color.rgb, blurred, blur_amount);
```

> Keep `blur_amount` low (`0.1`–`0.4`). Too much blur removes the retro pixel sharpness. This pass runs after warp but before scanlines/vignette.

---

## Full Shader (Combined)

```glsl
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
float scanline(vec2 uv) {
    float line = sin(uv.y * VIEWPORT_SIZE.y * PI);
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
vec3 blur(vec2 uv, float amount) {
    vec2 pixel = amount / VIEWPORT_SIZE;
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

    // 1. Warp
    uv = warp(uv, warp_amount);

    // 2. Cutoff mask
    float mask = screen_mask(uv);

    // 3. Blur (before sampling color)
    vec3 blurred = blur(uv, blur_amount);
    vec4 color = texture(screen_texture, uv);
    color.rgb = mix(color.rgb, blurred, blur_amount);

    // 4. Scanlines
    color.rgb *= scanline(uv);

    // 5. Vignette
    color.rgb *= vignette(uv);

    // 6. Apply mask (black border outside screen)
    COLOR = vec4(color.rgb * mask, 1.0);
}
```

---

## Recommended Parameter Values

| Parameter | Subtle | Balanced | Heavy |
|---|---|---|---|
| `warp_amount` | 0.5 | 1.5 | 3.0 |
| `scanline_opacity` | 0.2 | 0.5 | 0.8 |
| `scanline_width` | 0.1 | 0.25 | 0.45 |
| `vignette_intensity` | 0.2 | 0.4 | 0.7 |
| `vignette_opacity` | 0.2 | 0.5 | 0.8 |
| `blur_amount` | 0.1 | 0.3 | 0.6 |

---

## Tips & Gotchas for Godot 4.6.2

- **`hint_screen_texture` is required** — in Godot 4, you cannot sample the screen without this hint. `SCREEN_TEXTURE` from Godot 3 no longer works.
- **`VIEWPORT_SIZE` is built-in** — no need to pass it as a uniform; Godot 4 provides it automatically inside shaders.
- **CanvasLayer layer order matters** — set it high enough (e.g. `128`) so it draws after all UI nodes.
- **`render_mode unshaded`** — always include this, otherwise Godot's light system interferes with the color output.
- **Stretch mode** — use `canvas_items` stretch mode, not `viewport`. The `viewport` mode composites differently and can break `hint_screen_texture` sampling.
- **Filter setting** — on the `ColorRect`, set texture filter to **Nearest** if you want a sharp pixel look, or **Linear** for a softer CRT glow.

---

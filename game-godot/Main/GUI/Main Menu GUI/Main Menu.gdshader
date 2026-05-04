shader_type canvas_item;

uniform float speed : hint_range(-1.0, 1.0) = -0.01;
uniform float num_frames = 50.0;

void fragment() {
    // 1. Circle Mask
    float dist = distance(UV, vec2(0.5));
    if (dist > 0.5) {
        discard;
    }

    // 2. The Correct Math
    vec2 uv = UV;
    
    // Scale the X to only show 1/50th of the texture (one planet)
    // Then add the offset for movement
   uv.x = (uv.x + fract(TIME * speed)) / num_frames;

    COLOR = texture(TEXTURE, uv);
}
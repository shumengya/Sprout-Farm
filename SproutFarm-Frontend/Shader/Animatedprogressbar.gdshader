shader_type canvas_item;

uniform float u_aspect; // aspect of the control.

uniform vec4 progress_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 background_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec4 outline_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform float progress = 0.9;

const float corner_radius = 0.2;
const float grain_darkness = 0.01;
const vec4 white_color = vec4(1.0);
const float gradient_length = 0.05;
const float star_size = 20.0; // In pixels.
const float border_width = 0.01;
const float edge_softness = 0.005;
const float border_size = 0.1;

// A Signed Distance Field (SDF) formulas: https://iquilezles.org/articles/distfunctions2d/
float sdBox(in vec2 pos, in vec2 half_size)
{
    vec2 d = abs(pos) - half_size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRoundedBox(in vec2 pos, in vec2 half_size, in float r)
{
    return sdBox(pos , half_size) - r;
}

float sdStar(in vec2 p, in float r)
{
    const float k1x = 0.809016994; // cos(π/ 5) = ¼(√5+1)
    const float k2x = 0.309016994; // sin(π/10) = ¼(√5-1)
    const float k1y = 0.587785252; // sin(π/ 5) = ¼√(10-2√5)
    const float k2y = 0.951056516; // cos(π/10) = ¼√(10+2√5)
    const float k1z = 0.726542528; // tan(π/ 5) = √(5-2√5)
    const vec2  v1  = vec2( k1x,-k1y);
    const vec2  v2  = vec2(-k1x,-k1y);
    const vec2  v3  = vec2( k2x,-k2y);

    p.x = abs(p.x);
    p -= 2.0*max(dot(v1,p),0.0)*v1;
    p -= 2.0*max(dot(v2,p),0.0)*v2;
    p.x = abs(p.x);
    p.y -= r;
    return length(p-v3*clamp(dot(p,v3),0.0,k1z*r))
           * sign(p.y*v3.x-p.x*v3.y);
}

float sdRoundedStar(in vec2 p, in float r, in float corner_r) {
    return sdStar(p, r) - corner_r;
}

void fragment() {
    vec2 aspect = vec2(u_aspect, 1.0);
    vec2 half_size = vec2(0.5, 0.5) * aspect;
    vec2 pos = UV * aspect - half_size;
    float distance = sdRoundedBox(pos, half_size - corner_radius, corner_radius);

    if (UV.x < progress) {
        COLOR = progress_color;

        float position_gradient = UV.x - (progress - gradient_length); // 0.0 -> length
        float normalized_position = clamp(position_gradient / gradient_length, 0.0, 1.0);
        COLOR += white_color * normalized_position * 0.2;

        float shift = TIME * star_size;
        vec2 grid_coord = (FRAGCOORD.xy + vec2(-shift, shift)) / star_size;
        // 36° rotation matrix.
        const mat2 rot36 = mat2(vec2(0.8090, -0.5878), vec2(0.5878, 0.8090));
        grid_coord *= rot36;
        float index_y = floor(grid_coord.y);
        vec2 fraction = fract(grid_coord);
        // Shift X.
        if (mod(index_y, 2.0) == 1.0) {
            fraction.x = fract(grid_coord.x + 0.5);
        }
        vec2 pos = fraction - vec2(0.5, 0.5);
        float distance = sdRoundedStar(pos, 0.4, 0.02);
        if (distance < 0.0) {
            COLOR *= 0.93;
        }
    } else {
        // Grainy checker pattern.
        float grain = mod(floor(FRAGCOORD.x * 0.3) + floor(FRAGCOORD.y * 0.3), 3.0);
        COLOR = background_color - grain * grain_darkness;
    }

    // Border.
    float border_alpha = 1.0 - smoothstep(border_size - edge_softness, border_size, abs(distance));
    COLOR = mix(COLOR, outline_color, border_alpha);

    // Rounded corners.
    float smoothed_alpha = 1.0 - smoothstep(0.0, edge_softness, distance);
    COLOR.a = smoothed_alpha;
}

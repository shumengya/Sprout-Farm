shader_type canvas_item;

uniform float outline_width = 1.0;
uniform vec4 outline_color : source_color;
uniform vec4 texture_region = vec4(0.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 outline_offset = vec2(outline_width) * TEXTURE_PIXEL_SIZE;
	vec4 uv_region = vec4(texture_region.xy * TEXTURE_PIXEL_SIZE, texture_region.zw * TEXTURE_PIXEL_SIZE);
	if (uv_region.zw == vec2(0.0)) {
		uv_region.zw = vec2(1.0);
	}

	float uv_offset;
	float a;
	float max_a = 0.0;

	uv_offset = UV.y - outline_offset.y;
	if (uv_offset > uv_region.y) {
		a = texture(TEXTURE, vec2(UV.x, uv_offset)).a;
		max_a = max(a, max_a);
	}

	uv_offset = UV.y + outline_offset.y;
	if (uv_offset < uv_region.y + uv_region.w) {
		a = texture(TEXTURE, vec2(UV.x, uv_offset)).a;
		max_a = max(a, max_a);
	}

	uv_offset = UV.x - outline_offset.x;
	if (uv_offset > uv_region.x) {
		a = texture(TEXTURE, vec2(uv_offset, UV.y)).a;
		max_a = max(a, max_a);
	}

	uv_offset = UV.x + outline_offset.x;
	if (uv_offset < uv_region.x + uv_region.z) {
		a = texture(TEXTURE, vec2(uv_offset, UV.y)).a;
		max_a = max(a, max_a);
	}

	COLOR = mix(color, outline_color, max_a - color.a);
}

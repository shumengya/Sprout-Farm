shader_type canvas_item;

uniform bool allow_out_of_bounds = true;
uniform float outline_thickness: hint_range(0.0, 16.0, 1.0) = 1.0;
uniform vec4 outline_color: source_color = vec4(1.0);
uniform int quality: hint_range(1, 3, 1) = 2; // 1=低质量但快速, 2=平衡, 3=高质量但慢
uniform bool use_fast_mode = true; // 快速模式，牺牲一点质量换取性能

bool is_inside_usquare(vec2 x) {
	return x == clamp(x, vec2(0.0), vec2(1.0));
}

vec4 blend(vec4 bottom, vec4 top) {
    float alpha = top.a + bottom.a * (1.0 - top.a);
    if (alpha < 0.0001) return vec4(0.0);

    vec3 color = mix(bottom.rgb * bottom.a, top.rgb, top.a) / alpha;
    return vec4(color, alpha);
}

void vertex() {
	if (allow_out_of_bounds) VERTEX += (UV * 2.0 - 1.0) * outline_thickness;
}

void fragment() {
	if (outline_thickness <= 0.0 || outline_color.a <= 0.0) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 uv = UV;
		vec4 texture_color = texture(TEXTURE, UV);

		if (allow_out_of_bounds) {
			vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_thickness * 2.0));
			uv = (uv - texture_pixel_size * outline_thickness) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

			if (is_inside_usquare(uv)) {
				texture_color = texture(TEXTURE, uv);
			} else {
				texture_color = vec4(0.0);
			}
		}

		// 如果当前像素已经有alpha，且不是在边缘，可以跳过复杂计算
		if (texture_color.a > 0.9) {
			COLOR = texture_color;
		} else {
			float alpha = 0.0;

			if (use_fast_mode) {
				// 快速模式：使用较少的采样点
				float step_size = max(1.0, outline_thickness / 4.0);
				int max_samples = 32; // 限制最大采样数
				int sample_count = 0;

				for (float radius = step_size; radius <= outline_thickness && sample_count < max_samples; radius += step_size) {
					// 使用8个方向的采样点
					vec2 directions[8] = {
						vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
						vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707)
					};

					for (int i = 0; i < 8; i++) {
						vec2 sample_uv = uv + directions[i] * radius * TEXTURE_PIXEL_SIZE;
						if (is_inside_usquare(sample_uv)) {
							float sample_alpha = texture(TEXTURE, sample_uv).a;
							alpha = max(alpha, sample_alpha);
							sample_count++;
							if (alpha > 0.99) break; // 早期退出
						}
					}
					if (alpha > 0.99) break; // 早期退出
				}
			} else {
				// 原始高质量模式，但有优化
				int max_thickness = int(min(outline_thickness, float(8 + quality * 4))); // 限制最大厚度

				for (int y = 1; y <= max_thickness; y++) {
					for (int x = 0; x <= y; x++) {
						float dist = length(vec2(float(x), float(y) - 0.5));
						if (dist > outline_thickness) break;

						vec2 offsets[8] = {
							vec2(float(x), float(y)), vec2(float(-x), float(y)),
							vec2(float(x), float(-y)), vec2(float(-x), float(-y)),
							vec2(float(y), float(x)), vec2(float(-y), float(x)),
							vec2(float(y), float(-x)), vec2(float(-y), float(-x))
						};

						for (int i = 0; i < 8; i++) {
							vec2 sample_uv = uv + offsets[i] * TEXTURE_PIXEL_SIZE;
							if (is_inside_usquare(sample_uv)) {
								float sample_alpha = texture(TEXTURE, sample_uv).a;
								alpha = max(alpha, sample_alpha);
								if (alpha > 0.99) break; // 早期退出
							}
						}

						if (alpha > 0.99) break; // 早期退出
					}

					if (alpha > 0.99) break; // 早期退出
				}
			}

			COLOR = blend(vec4(outline_color.rgb, alpha * outline_color.a), texture_color);
		}
	}
}

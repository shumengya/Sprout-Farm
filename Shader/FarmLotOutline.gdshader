shader_type canvas_item;

uniform float outline_thickness: hint_range(0.0, 8.0, 0.5) = 1.0;
uniform vec4 outline_color: source_color = vec4(1.0);
uniform bool high_performance_mode = true; // 高性能模式，减少采样

void vertex() {
	VERTEX += (UV * 2.0 - 1.0) * outline_thickness;
}

void fragment() {
	vec2 uv = UV;
	vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_thickness * 2.0));
	uv = (uv - texture_pixel_size * outline_thickness) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
	
	vec4 texture_color = vec4(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		texture_color = texture(TEXTURE, uv);
	}
	
	// 如果当前像素不透明，直接设置颜色
	if (texture_color.a > 0.5) {
		COLOR = texture_color;
	} else {
		// 需要计算描边
		float outline_alpha = 0.0;
		
		if (high_performance_mode) {
			// 高性能模式：只检查4个主要方向
			vec2 directions[4] = {
				vec2(outline_thickness, 0.0),
				vec2(-outline_thickness, 0.0),
				vec2(0.0, outline_thickness),
				vec2(0.0, -outline_thickness)
			};
			
			for (int i = 0; i < 4; i++) {
				vec2 check_uv = uv + directions[i] * TEXTURE_PIXEL_SIZE;
				if (check_uv.x >= 0.0 && check_uv.x <= 1.0 && check_uv.y >= 0.0 && check_uv.y <= 1.0) {
					float check_alpha = texture(TEXTURE, check_uv).a;
					outline_alpha = max(outline_alpha, check_alpha);
					if (outline_alpha > 0.9) break; // 早期退出
				}
			}
		} else {
			// 标准模式：8方向检查
			vec2 directions[8] = {
				vec2(outline_thickness, 0.0), vec2(-outline_thickness, 0.0),
				vec2(0.0, outline_thickness), vec2(0.0, -outline_thickness),
				vec2(outline_thickness * 0.707, outline_thickness * 0.707),
				vec2(-outline_thickness * 0.707, outline_thickness * 0.707),
				vec2(outline_thickness * 0.707, -outline_thickness * 0.707),
				vec2(-outline_thickness * 0.707, -outline_thickness * 0.707)
			};
			
			for (int i = 0; i < 8; i++) {
				vec2 check_uv = uv + directions[i] * TEXTURE_PIXEL_SIZE;
				if (check_uv.x >= 0.0 && check_uv.x <= 1.0 && check_uv.y >= 0.0 && check_uv.y <= 1.0) {
					float check_alpha = texture(TEXTURE, check_uv).a;
					outline_alpha = max(outline_alpha, check_alpha);
					if (outline_alpha > 0.9) break; // 早期退出
				}
			}
		}
		
		// 混合颜色
		float final_alpha = outline_alpha * outline_color.a;
		COLOR = vec4(outline_color.rgb * final_alpha + texture_color.rgb * texture_color.a, 
					 max(final_alpha, texture_color.a));
	}
} 
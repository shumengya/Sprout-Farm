shader_type canvas_item;

// 摆动参数
uniform float sway_strength : hint_range(0.0, 0.05) = 0.02; // 摆动强度
uniform float sway_speed : hint_range(0.1, 5.0) = 1.0; // 摆动速度
uniform float wind_direction : hint_range(-1.0, 1.0) = 0.0; // 风向偏移
uniform float sway_variation : hint_range(0.0, 2.0) = 0.5; // 摆动变化

// 高度影响参数
uniform float sway_start_height : hint_range(0.0, 1.0) = 0.3; // 开始摆动的高度比例
uniform float height_curve : hint_range(1.0, 4.0) = 2.0; // 高度影响曲线

void fragment() {
    vec2 uv = UV;

    // 计算摆动强度（只有上半部分摆动）
    float height_factor = 0.0;
    if (uv.y < sway_start_height) {
        // 计算从底部到摆动开始位置的渐变
        height_factor = pow((sway_start_height - uv.y) / sway_start_height, height_curve);
    }

    // 创建多层摆动效果
    float time_offset = TIME * sway_speed;

    // 主摆动波
    float main_sway = sin(time_offset + uv.y * 3.14159) * sway_strength;

    // 次级摆动波（频率更高，幅度更小）
    float secondary_sway = sin(time_offset * 2.3 + uv.y * 6.28318) * sway_strength * 0.3;

    // 第三层摆动（更细微的抖动）
    float micro_sway = sin(time_offset * 4.7 + uv.y * 12.56636) * sway_strength * 0.1;

    // 结合所有摆动
    float total_sway = (main_sway + secondary_sway + micro_sway) * height_factor;

    // 添加风向偏移
    total_sway += wind_direction * sway_strength * height_factor * 0.5;

    // 添加摆动变化（随机性）
    float variation = sin(time_offset * 0.37 + uv.x * 6.28318) * sway_variation * 0.01;
    total_sway += variation * height_factor;

    // 应用摆动到UV坐标
    uv.x += total_sway;

    // 边界检查，防止UV超出范围
    if (uv.x < 0.0 || uv.x > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // 透明
    } else {
        COLOR = texture(TEXTURE, uv);
    }
}
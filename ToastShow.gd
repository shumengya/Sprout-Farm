extends PanelContainer

@onready var label = $Label
var display_time = 4.0  # 显示的时间（秒）
var fade_duration = 1.0  # 渐隐时间（秒）

func Toast(text: String, text_color: Color = Color.WHITE):
	label.text = text
	label.modulate = text_color
	show()
	modulate.a = 1  # 确保初始透明度为 1
	await get_tree().create_timer(display_time).timeout  # 等待显示时间
	await fade_out()  # 开始渐隐

func fade_out() -> void:
	var fade_step = 1.0 / (fade_duration / 60)  # 每帧减少的透明度
	while modulate.a > 0:
		modulate.a -= fade_step
		if modulate.a < 0:
			modulate.a = 0
		await get_tree().create_timer(0).timeout  # 等待下一帧
	hide()  # 完全透明时隐藏面板

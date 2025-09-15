extends Node2D
#昼夜循环系统
#时间直接获取现实世界时间
#内容就是直接调节背景图片modulate的亮度HEX 白天最亮为c3c3c3   晚上最暗为131313 然后在这之间变化

# 背景节点引用
@onready var background_node=$'../BackgroundUI/BackgroundSwitcher'

# 白天和夜晚的颜色值
var day_color = Color("#c3c3c3")
var night_color = Color("#131313")


	
func _process(delta: float) -> void:
	if background_node == null:
		return
		
	# 获取当前时间
	var current_time = Time.get_datetime_dict_from_system()
	var hour = current_time.hour
	var minute = current_time.minute
	
	# 将时间转换为小数形式（0-24）
	var time_decimal = hour + minute / 60.0
	
	# 计算亮度插值因子
	var brightness_factor = calculate_brightness_factor(time_decimal)
	
	# 在白天和夜晚颜色之间插值
	var current_color = night_color.lerp(day_color, brightness_factor)
	
	# 应用到背景节点
	background_node.modulate = current_color

# 计算亮度因子（0为夜晚，1为白天）
func calculate_brightness_factor(time: float) -> float:
	# 定义关键时间点
	var sunrise = 6.0    # 日出时间 6:00
	var noon = 12.0      # 正午时间 12:00
	var sunset = 18.0    # 日落时间 18:00
	var midnight = 0.0   # 午夜时间 0:00
	
	if time >= sunrise and time <= noon:
		# 日出到正午：从0.2逐渐变亮到1.0
		return 0.2 + 0.8 * (time - sunrise) / (noon - sunrise)
	elif time > noon and time <= sunset:
		# 正午到日落：从1.0逐渐变暗到0.2
		return 1.0 - 0.8 * (time - noon) / (sunset - noon)
	else:
		# 夜晚时间：保持较暗状态（0.0-0.2之间）
		if time > sunset:
			# 日落后到午夜
			var night_progress = (time - sunset) / (24.0 - sunset)
			return 0.2 - 0.2 * night_progress
		else:
			# 午夜到日出
			var dawn_progress = time / sunrise
			return 0.0 + 0.2 * dawn_progress

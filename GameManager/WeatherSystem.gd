extends Node2D

@onready var cherry_blossom_rain: Node2D = $CherryBlossomRain #栀子花雨
@onready var gardenia_rain: Node2D = $GardeniaRain #樱花雨
@onready var willow_leaf_rain: Node2D = $WillowLeafRain #柳叶雨
@onready var rain: GPUParticles2D = $Rain #下雨
@onready var snow: GPUParticles2D = $Snow #下雪

# 天气系统
# 要显示哪种天气直接调用相应天气的show()然后一并隐藏其他天气hide()

# 动态天气显示控制（可以覆盖全局设置）
var weather_display_enabled: bool = true

# 设置天气的统一方法
func set_weather(weather_type: String):
	# 检查全局设置和动态设置
	if GlobalVariables.DisableWeatherDisplay or not weather_display_enabled:
		hide_all_weather()
		return

	# 先隐藏所有天气效果
	hide_all_weather()
	
	# 根据天气类型显示对应效果
	match weather_type:
		"clear", "stop":
			# 晴天或停止天气 - 所有天气效果都隐藏
			pass
		"rain":
			if rain:
				rain.show()
		"snow":
			if snow:
				snow.show()
		"cherry":
			if cherry_blossom_rain:
				cherry_blossom_rain.show()
		"gardenia":
			if gardenia_rain:
				gardenia_rain.show()
		"willow":
			if willow_leaf_rain:
				willow_leaf_rain.show()
		_:
			print("未知的天气类型: ", weather_type)

# 动态设置天气显示状态
func set_weather_display_enabled(enabled: bool):
	"""动态设置天气显示是否启用"""
	weather_display_enabled = enabled
	if not enabled:
		hide_all_weather()
	print("天气显示已", "启用" if enabled else "禁用")

# 获取当前天气显示状态
func is_weather_display_enabled() -> bool:
	"""获取当前天气显示状态"""
	return weather_display_enabled and not GlobalVariables.DisableWeatherDisplay

# 隐藏所有天气效果
func hide_all_weather():
	if cherry_blossom_rain:
		cherry_blossom_rain.hide()
	if gardenia_rain:
		gardenia_rain.hide()
	if willow_leaf_rain:
		willow_leaf_rain.hide()
	if rain:
		rain.hide()
	if snow:
		snow.hide()

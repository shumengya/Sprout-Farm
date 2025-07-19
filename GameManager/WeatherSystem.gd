extends Node2D

@onready var cherry_blossom_rain: Node2D = $CherryBlossomRain #栀子花雨
@onready var gardenia_rain: Node2D = $GardeniaRain #樱花雨
@onready var willow_leaf_rain: Node2D = $WillowLeafRain #柳叶雨
@onready var rain: GPUParticles2D = $Rain #下雨
@onready var snow: GPUParticles2D = $Snow #下雪

# 天气系统
# 要显示哪种天气直接调用相应天气的show()然后一并隐藏其他天气hide()

# 设置天气的统一方法
func set_weather(weather_type: String):
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

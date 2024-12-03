extends ProgressBar

var target_value: float = 0.0
var animation_speed: float = 2.0

func _ready():
	# 初始化进度条的颜色
	modulate = Color(0.6, 0, 0.0)  # 从红色到绿色的渐变

func _process(delta):
	update_progress_visuals()

func set_target_value(new_value: float):
	value = new_value

func update_progress_visuals():
	# 改变进度条的颜色
	var fill_ratio = value / max_value
	modulate = Color(0.6 - fill_ratio, fill_ratio, 0.0)  # 从红色到绿色的渐变
	#modulate = Color(1.0 - fill_ratio, fill_ratio, 0.0)  # 从红色到绿色的渐变
	#modulate = Color(0.0, 1.0 - fill_ratio, fill_ratio)  # 从蓝色到绿色的渐变
	#modulate = Color(0.0, 1.0 - fill_ratio, fill_ratio * 0.75)  # 从绿色到淡蓝色的渐变

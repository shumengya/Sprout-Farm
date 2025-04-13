extends PanelContainer

@export var display_time = 4.0
@export var fade_duration = 1.0

var label: Label  # 显式声明类型

func _ready():
	# 确保获取Label节点
	label = find_child("Label") as Label
	if not label:
		push_error("找不到Label子节点！请检查场景结构")

func setup(text: String, color: Color, duration: float, fade: float):
	display_time = duration
	fade_duration = fade
	# 确保添加到场景树
	Engine.get_main_loop().root.add_child(self)
	Toast(text, color)

func Toast(text: String, text_color: Color = Color.WHITE):
	if !label:
		return
	
	label.text = text
	label.modulate = text_color
	show()
	modulate.a = 1
	
	await get_tree().create_timer(display_time).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	queue_free()

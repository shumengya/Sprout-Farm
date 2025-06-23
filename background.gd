extends Sprite2D

# 存储背景图片的路径数组
var backgrounds :Array = [  	
	"res://assets/背景图片/背景1.png",
	"res://assets/背景图片/背景2.png",
	"res://assets/背景图片/背景3.png",
	"res://assets/背景图片/背景4.png",
	"res://assets/背景图片/背景5.png",
	"res://assets/背景图片/背景6.png",
	"res://assets/背景图片/背景7.png",
	"res://assets/背景图片/背景8.png",
	"res://assets/背景图片/背景9.png",
	"res://assets/背景图片/背景10.png",
	"res://assets/背景图片/背景11.png",
	"res://assets/背景图片/背景12.png",
	"res://assets/背景图片/背景13.png",
	"res://assets/背景图片/背景14.png",
	"res://assets/背景图片/背景15.png",
	"res://assets/背景图片/背景16.png",
	"res://assets/背景图片/背景17.png",
	"res://assets/背景图片/背景18.png",
	"res://assets/背景图片/背景19.png",
	"res://assets/背景图片/背景20.png",
	"res://assets/背景图片/背景21.png",
	"res://assets/背景图片/背景22.png"
]

# 当前显示的背景索引
var current_index = -1
# 过渡动画的持续时间（秒）
@export var transition_duration: float = 1.5

# 节点引用
@onready var background2: Sprite2D = $Background2
@onready var timer: Timer = $Timer

# 用于持有当前正在运行的Tween的引用，方便在需要时中止它
var current_tween: Tween 

func _ready():
	# 验证背景图片资源
	if not validate_backgrounds():
		return

	# 初始化，直接设置第一张背景，不进行过渡
	current_index = randi() % backgrounds.size()
	self.texture = load(backgrounds[current_index])
	
	# 设置第二个Sprite的初始状态为完全透明
	background2.modulate.a = 0.0

	# 配置计时器
	timer.wait_time = 10.0
	timer.timeout.connect(switch_background) # 直接连接切换函数
	timer.start()

func validate_backgrounds() -> bool:
	var valid_backgrounds = []
	for bg_path in backgrounds:
		if ResourceLoader.exists(bg_path):
			valid_backgrounds.append(bg_path)
		else:
			push_error("背景图片不存在: " + bg_path)
	
	backgrounds = valid_backgrounds
	if backgrounds.is_empty():
		push_error("没有可用的背景图片！")
		return false
	return true

func switch_background():
	if backgrounds.size() <= 1:
		return

	# 1. 选择一张新的、不重复的背景图
	var new_index = randi() % backgrounds.size()
	while new_index == current_index:
		new_index = randi() % backgrounds.size()
	
	current_index = new_index
	var new_texture = load(backgrounds[current_index])
	if new_texture == null:
		push_error("无法加载背景图片: " + backgrounds[current_index])
		return

	# 2. 将新图片设置到上层的Sprite2D (background2)
	background2.texture = new_texture
	
	# 3. 【核心改动】创建并执行Tween动画
	# 如果上一个动画还在运行，先中止它，防止动画重叠或冲突
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	# 直接从节点创建 Tween 对象，无需场景树中有Tween节点
	current_tween = create_tween()
	
	# 设置动画：让 background2 的 modulate.a (透明度) 从 0 (透明) 渐变到 1 (不透明)
	current_tween.tween_property(background2, "modulate:a", 1.0, transition_duration)\
		 .set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		 
	# 4. 动画完成后，通过 .connect() 连接一个回调函数进行状态重置
	current_tween.finished.connect(_on_transition_finished)

# 注意：之前的 _on_timer_timeout 函数的功能已合并到 switch_background
# 所以我们只需要一个动画完成后的回调函数

func _on_transition_finished():
	# 动画结束后，将新背景 "固化" 到主背景上
	self.texture = background2.texture
	# 并将上层背景重置为透明，为下一次过渡做准备
	background2.modulate.a = 0.0
	# 清除引用，虽然不必须，但是个好习惯
	current_tween = null

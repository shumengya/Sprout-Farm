extends Camera2D

# 相机移动速度
@export var move_speed: float = 400.0  # 每秒移动的像素数
@export var zoom_speed: float = 0.02    # 缩放速度
@export var min_zoom: float = 0.7    # 最小缩放值
@export var max_zoom: float = 1.2      # 最大缩放值

# 移动端触摸设置
@export var touch_sensitivity: float = 1.0  # 触摸灵敏度
@export var enable_touch_zoom: bool = true   # 是否启用双指缩放

# 移动边界（可选）
@export var bounds_enabled: bool = false
@export var bounds_min: Vector2 = Vector2(-1000, -1000)
@export var bounds_max: Vector2 = Vector2(1000, 1000)

@export var current_zoom_level: float = 1.0

# 触摸相关变量
var is_dragging: bool = false
var last_touch_position: Vector2
var touch_points: Dictionary = {}  # 存储多点触摸信息
var initial_zoom_distance: float = 0.0

func _ready():
	# 初始化相机
	zoom = Vector2(current_zoom_level, current_zoom_level)
	


func _process(delta):
	#其他地方可通过这个方法来禁用相机功能
	if GlobalVariables.isZoomDisabled == true:
		return
	
	# 处理相机移动
	var input_dir = Vector2.ZERO
	
	# WASD 键移动
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	
	# 归一化移动向量，确保对角线移动不会更快
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# 相机移动
	position += input_dir * move_speed * delta / current_zoom_level
	
	# 如果启用了边界限制，确保相机在边界内
	if bounds_enabled:
		position.x = clamp(position.x, bounds_min.x, bounds_max.x)
		position.y = clamp(position.y, bounds_min.y, bounds_max.y)
	
	# 处理相机缩放KEY_EQUAL
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):  # + 键放大
		zoom_camera(-zoom_speed)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):  # - 键缩小
		zoom_camera(zoom_speed)

# 处理输入事件（包括触摸和鼠标）
func _input(event):
	
	#其他地方可通过这个方法来禁用相机功能
	if GlobalVariables.isZoomDisabled == true:
		return
	
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(zoom_speed)
	
	# 触摸开始
	elif event is InputEventScreenTouch:
		if event.pressed:
			# 记录触摸点
			touch_points[event.index] = event.position
			
			if len(touch_points) == 1:
				# 单指触摸，开始拖动
				is_dragging = true
				last_touch_position = event.position
			elif len(touch_points) == 2 and enable_touch_zoom:
				# 双指触摸，准备缩放
				is_dragging = false
				var touches = touch_points.values()
				initial_zoom_distance = touches[0].distance_to(touches[1])
		else:
			# 触摸结束
			if touch_points.has(event.index):
				touch_points.erase(event.index)
			
			if len(touch_points) == 0:
				is_dragging = false
			elif len(touch_points) == 1:
				# 从双指回到单指，重新开始拖动
				is_dragging = true
				last_touch_position = touch_points.values()[0]
	
	# 触摸拖动
	elif event is InputEventScreenDrag:
		if touch_points.has(event.index):
			touch_points[event.index] = event.position
			
			if len(touch_points) == 1 and is_dragging:
				# 单指拖动，移动相机
				var drag_delta = last_touch_position - event.position
				# 根据当前缩放级别调整移动距离
				position += drag_delta * touch_sensitivity / current_zoom_level
				
				# 应用边界限制
				if bounds_enabled:
					position.x = clamp(position.x, bounds_min.x, bounds_max.x)
					position.y = clamp(position.y, bounds_min.y, bounds_max.y)
				
				last_touch_position = event.position
			
			elif len(touch_points) == 2 and enable_touch_zoom:
				# 双指缩放
				var touches = touch_points.values()
				var current_distance = touches[0].distance_to(touches[1])
				
				if initial_zoom_distance > 0:
					var zoom_factor = current_distance / initial_zoom_distance
					var zoom_change = (zoom_factor - 1.0) * zoom_speed * 10
					zoom_camera(zoom_change)
				
				initial_zoom_distance = current_distance

# 缩放相机
func zoom_camera(zoom_amount):
	current_zoom_level = clamp(current_zoom_level + zoom_amount, min_zoom, max_zoom)
	zoom = Vector2(current_zoom_level, current_zoom_level)

extends Panel

# 游戏常量
const GRID_SIZE = 20
const GRID_WIDTH = 30
const GRID_HEIGHT = 30
const DATA_FILE_PATH = "user://playergamedata.json"

# 方向枚举
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# 食物类型枚举
enum FoodType {
	NORMAL,    # 普通食物 +10分
	GOLDEN,    # 金色食物 +50分
	SPEED,     # 加速食物 +20分，临时加速
	SLOW,      # 减速食物 +30分，临时减速
	BONUS      # 奖励食物 +100分
}

# 游戏变量
var snake_body = []
var snake_direction = Direction.RIGHT
var next_direction = Direction.RIGHT
var food_position = Vector2()
var food_type = FoodType.NORMAL
var score = 0
var best_score = 0
var level = 1
var speed_multiplier = 1.0
var speed_effect_timer = 0.0
var game_over = false
var game_started = false  # 添加游戏开始状态
var obstacles = []
var games_played = 0
var total_food_eaten = 0
var player_data = {}

# 节点引用
@onready var game_area = $GameArea
@onready var score_label = $ScoreLabel
@onready var game_over_label = $GameOverLabel
@onready var game_timer = $GameTimer
@onready var virtual_controls = $VirtualControls

func _ready():
	# 连接定时器信号
	game_timer.timeout.connect(_on_game_timer_timeout)
	
	# 设置游戏区域样式
	game_area.modulate = Color(0.1, 0.1, 0.15, 0.9)
	
	# 连接虚拟按键信号
	setup_virtual_controls()
	
	# 加载玩家数据
	load_player_data()
	
	# 显示游戏开始界面
	show_start_screen()

func init_game():
	# 重置游戏状态
	game_over = false
	game_started = true
	score = 0
	level = 1
	speed_multiplier = 1.0
	speed_effect_timer = 0.0
	snake_direction = Direction.RIGHT
	next_direction = Direction.RIGHT
	games_played += 1
	
	# 初始化蛇身
	snake_body.clear()
	snake_body.append(Vector2(5, 5))
	snake_body.append(Vector2(4, 5))
	snake_body.append(Vector2(3, 5))
	
	# 清空障碍物
	obstacles.clear()
	
	# 生成食物和障碍物
	generate_food()
	generate_obstacles()
	
	# 更新UI
	update_score()
	game_over_label.visible = false
	
	# 设置定时器速度
	game_timer.wait_time = 0.2 / speed_multiplier
	game_timer.start()

func _input(event):
	if event is InputEventKey and event.pressed:
		# 游戏未开始时，按Q键开始游戏
		if not game_started:
			if event.keycode == KEY_Q:
				init_game()
			return
		
		if game_over:
			if event.keycode == KEY_SPACE:
				init_game()
			elif event.keycode == KEY_Q:
				init_game()
			return
		
		# 控制蛇的方向
		match event.keycode:
			KEY_UP, KEY_W:
				change_direction(Direction.UP)
			KEY_DOWN, KEY_S:
				change_direction(Direction.DOWN)
			KEY_LEFT, KEY_A:
				change_direction(Direction.LEFT)
			KEY_RIGHT, KEY_D:
				change_direction(Direction.RIGHT)

func change_direction(new_direction: Direction):
	# 防止蛇反向移动
	match new_direction:
		Direction.UP:
			if snake_direction != Direction.DOWN:
				next_direction = Direction.UP
		Direction.DOWN:
			if snake_direction != Direction.UP:
				next_direction = Direction.DOWN
		Direction.LEFT:
			if snake_direction != Direction.RIGHT:
				next_direction = Direction.LEFT
		Direction.RIGHT:
			if snake_direction != Direction.LEFT:
				next_direction = Direction.RIGHT

func _on_game_timer_timeout():
	if not game_started or game_over:
		return
	
	# 处理速度效果
	if speed_effect_timer > 0:
		speed_effect_timer -= game_timer.wait_time
		if speed_effect_timer <= 0:
			speed_multiplier = 1.0
			game_timer.wait_time = 0.2 / speed_multiplier
	
	# 更新方向
	snake_direction = next_direction
	
	# 移动蛇
	move_snake()
	
	# 检查碰撞
	check_collisions()
	
	# 重绘游戏
	queue_redraw()

func move_snake():
	var head = snake_body[0]
	var new_head = head
	
	# 根据方向计算新的头部位置
	match snake_direction:
		Direction.UP:
			new_head = Vector2(head.x, head.y - 1)
		Direction.DOWN:
			new_head = Vector2(head.x, head.y + 1)
		Direction.LEFT:
			new_head = Vector2(head.x - 1, head.y)
		Direction.RIGHT:
			new_head = Vector2(head.x + 1, head.y)
	
	# 添加新头部
	snake_body.insert(0, new_head)
	
	# 检查是否吃到食物
	if new_head == food_position:
		# 根据食物类型增加分数和效果
		eat_food()
		
		# 生成新食物
		generate_food()
		
		# 检查等级提升
		check_level_up()
	else:
		# 移除尾部
		snake_body.pop_back()

func check_collisions():
	var head = snake_body[0]
	
	# 检查边界碰撞
	if head.x < 0 or head.x >= GRID_WIDTH or head.y < 0 or head.y >= GRID_HEIGHT:
		game_over = true
		show_game_over()
		return
	
	# 检查自身碰撞
	for i in range(1, snake_body.size()):
		if head == snake_body[i]:
			game_over = true
			show_game_over()
			return
	
	# 检查障碍物碰撞
	for obstacle in obstacles:
		if head == obstacle:
			game_over = true
			show_game_over()
			return

func generate_food():
	var attempts = 0
	while attempts < 100:  # 防止无限循环
		food_position = Vector2(
			randi() % GRID_WIDTH,
			randi() % GRID_HEIGHT
		)
		
		# 确保食物不在蛇身上和障碍物上
		var food_blocked = false
		for segment in snake_body:
			if segment == food_position:
				food_blocked = true
				break
		
		if not food_blocked:
			for obstacle in obstacles:
				if obstacle == food_position:
					food_blocked = true
					break
		
		if not food_blocked:
			break
		
		attempts += 1
	
	# 随机生成食物类型
	var rand = randf()
	if rand < 0.6:  # 60% 普通食物
		food_type = FoodType.NORMAL
	elif rand < 0.75:  # 15% 金色食物
		food_type = FoodType.GOLDEN
	elif rand < 0.85:  # 10% 加速食物
		food_type = FoodType.SPEED
	elif rand < 0.95:  # 10% 减速食物
		food_type = FoodType.SLOW
	else:  # 5% 奖励食物
		food_type = FoodType.BONUS

func update_score():
	score_label.text = "🐍 分数: " + str(score) + "\n🏆 最高分: " + str(best_score) + "\n⭐ 等级: " + str(level) + "\n🎮 游戏次数: " + str(games_played)

func show_game_over():
	game_timer.stop()
	game_started = false
	if score > best_score:
		best_score = score
		update_score()
	save_player_data()
	game_over_label.text = "🎮 游戏结束\n🏆 分数: " + str(score) + "\n⭐ 等级: " + str(level) + "\n\n🔄 按Q键或空格重新开始"
	game_over_label.visible = true

func eat_food():
	total_food_eaten += 1
	match food_type:
		FoodType.NORMAL:
			score += 10
		FoodType.GOLDEN:
			score += 50
		FoodType.SPEED:
			score += 20
			speed_multiplier = 1.5
			speed_effect_timer = 5.0
			game_timer.wait_time = 0.2 / speed_multiplier
		FoodType.SLOW:
			score += 30
			speed_multiplier = 0.7
			speed_effect_timer = 5.0
			game_timer.wait_time = 0.2 / speed_multiplier
		FoodType.BONUS:
			score += 100
	update_score()

func check_level_up():
	var new_level = (total_food_eaten / 10) + 1
	if new_level > level:
		level = new_level
		generate_obstacles()  # 每升级增加障碍物

func generate_obstacles():
	# 根据等级生成障碍物
	var obstacle_count = min(level - 1, 10)  # 最多10个障碍物
	obstacles.clear()
	
	for i in range(obstacle_count):
		var attempts = 0
		while attempts < 50:
			var obstacle_pos = Vector2(
				randi() % GRID_WIDTH,
				randi() % GRID_HEIGHT
			)
			
			# 确保障碍物不在蛇身、食物或其他障碍物上
			var blocked = false
			for segment in snake_body:
				if segment == obstacle_pos:
					blocked = true
					break
			
			if not blocked and obstacle_pos == food_position:
				blocked = true
			
			if not blocked:
				for existing_obstacle in obstacles:
					if existing_obstacle == obstacle_pos:
						blocked = true
						break
			
			if not blocked:
				obstacles.append(obstacle_pos)
				break
			
			attempts += 1

func setup_virtual_controls():
	if not virtual_controls:
		return
	
	var up_btn = virtual_controls.get_node("UpButton")
	var down_btn = virtual_controls.get_node("DownButton")
	var left_btn = virtual_controls.get_node("LeftButton")
	var right_btn = virtual_controls.get_node("RightButton")
	var restart_btn = virtual_controls.get_node("RestartButton")
	
	if up_btn:
		up_btn.pressed.connect(_on_virtual_button_pressed.bind(Direction.UP))
	if down_btn:
		down_btn.pressed.connect(_on_virtual_button_pressed.bind(Direction.DOWN))
	if left_btn:
		left_btn.pressed.connect(_on_virtual_button_pressed.bind(Direction.LEFT))
	if right_btn:
		right_btn.pressed.connect(_on_virtual_button_pressed.bind(Direction.RIGHT))
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_button_pressed)

func _on_virtual_button_pressed(direction: Direction):
	if game_started and not game_over:
		change_direction(direction)

func _on_restart_button_pressed():
	if not game_started or game_over:
		init_game()

func load_player_data():
	if FileAccess.file_exists(DATA_FILE_PATH):
		var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				player_data = json.data
				if player_data.has("snake"):
					var game_data = player_data["snake"]
					best_score = game_data.get("best_score", 0)
					games_played = game_data.get("games_played", 0)
					total_food_eaten = game_data.get("total_food_eaten", 0)

func show_start_screen():
	# 重置状态
	game_started = false
	game_over = false
	
	# 初始化蛇身用于显示
	snake_body.clear()
	snake_body.append(Vector2(5, 5))
	snake_body.append(Vector2(4, 5))
	snake_body.append(Vector2(3, 5))
	
	# 清空障碍物
	obstacles.clear()
	
	# 生成初始食物
	food_position = Vector2(10, 10)
	food_type = FoodType.NORMAL
	
	# 显示开始提示
	game_over_label.text = "🐍 贪吃蛇游戏 🐍\n\n🏆 最高分数: " + str(best_score) + "\n🎯 游戏次数: " + str(games_played) + "\n\n🎮 按Q键开始游戏\n\n🎯 操作说明:\n方向键/WASD - 控制方向\n\n🍎 食物类型:\n🔴 普通食物 +10分\n🟡 金色食物 +50分\n🔵 加速食物 +20分\n🟣 减速食物 +30分\n🌈 奖励食物 +100分"
	game_over_label.visible = true
	
	# 停止定时器
	game_timer.stop()
	
	update_score()
	queue_redraw()

func save_player_data():
	if not player_data.has("snake"):
		player_data["snake"] = {}
	
	player_data["snake"]["best_score"] = best_score
	player_data["snake"]["current_score"] = score
	player_data["snake"]["games_played"] = games_played
	player_data["snake"]["total_food_eaten"] = total_food_eaten
	player_data["snake"]["max_level_reached"] = level
	
	# 更新全局数据
	if not player_data.has("global"):
		player_data["global"] = {}
	player_data["global"]["last_played"] = Time.get_datetime_string_from_system()
	
	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data)
		file.store_string(json_string)
		file.close()

func _draw():
	if not game_area:
		return
	
	# 绘制背景渐变
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.05, 0.1, 0.2, 0.95))
	gradient.add_point(0.5, Color(0.1, 0.15, 0.25, 0.9))
	gradient.add_point(1.0, Color(0.15, 0.2, 0.3, 0.95))
	draw_rect(Rect2(Vector2.ZERO, size), gradient.sample(0.5), true)
	
	# 获取游戏区域的位置和大小
	var area_pos = game_area.position
	var area_size = game_area.size
	
	# 绘制游戏区域阴影
	var shadow_offset = Vector2(4, 4)
	var area_rect = Rect2(area_pos + shadow_offset, area_size)
	draw_rect(area_rect, Color(0, 0, 0, 0.3), true)
	
	# 绘制游戏区域背景
	area_rect = Rect2(area_pos, area_size)
	draw_rect(area_rect, Color(0.08, 0.12, 0.18, 0.9), true)
	
	# 计算网格大小
	var cell_width = area_size.x / GRID_WIDTH
	var cell_height = area_size.y / GRID_HEIGHT
	
	# 绘制网格线（淡色）
	for x in range(GRID_WIDTH + 1):
		var start_pos = Vector2(area_pos.x + x * cell_width, area_pos.y)
		var end_pos = Vector2(area_pos.x + x * cell_width, area_pos.y + area_size.y)
		draw_line(start_pos, end_pos, Color(0.3, 0.3, 0.4, 0.3), 1)
	
	for y in range(GRID_HEIGHT + 1):
		var start_pos = Vector2(area_pos.x, area_pos.y + y * cell_height)
		var end_pos = Vector2(area_pos.x + area_size.x, area_pos.y + y * cell_height)
		draw_line(start_pos, end_pos, Color(0.3, 0.3, 0.4, 0.3), 1)
	
	# 绘制障碍物
	for obstacle in obstacles:
		var rect = Rect2(
			area_pos.x + obstacle.x * cell_width,
			area_pos.y + obstacle.y * cell_height,
			cell_width - 2,
			cell_height - 2
		)
		# 绘制立体障碍物效果
		draw_rect(rect, Color(0.4, 0.2, 0.1), true)
		# 高光
		var highlight_rect = Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.3))
		draw_rect(highlight_rect, Color(0.6, 0.4, 0.2, 0.8), true)
	
	# 绘制蛇身
	for i in range(snake_body.size()):
		var segment = snake_body[i]
		var rect = Rect2(
			area_pos.x + segment.x * cell_width,
			area_pos.y + segment.y * cell_height,
			cell_width - 2,
			cell_height - 2
		)
		
		if i == 0:  # 头部
			# 绘制蛇头（圆形，带渐变）
			var center = rect.get_center()
			var radius = min(rect.size.x, rect.size.y) * 0.4
			# 阴影
			draw_circle(center + Vector2(1, 1), radius, Color(0, 0, 0, 0.3))
			# 主体
			draw_circle(center, radius, Color(0.2, 0.8, 0.2))
			# 高光
			draw_circle(center - Vector2(2, 2), radius * 0.6, Color(0.4, 1.0, 0.4, 0.7))
			# 眼睛
			var eye_size = radius * 0.2
			draw_circle(center + Vector2(-eye_size, -eye_size), eye_size * 0.5, Color.BLACK)
			draw_circle(center + Vector2(eye_size, -eye_size), eye_size * 0.5, Color.BLACK)
		else:  # 身体
			# 绘制蛇身（渐变色）
			var body_color = Color.LIME_GREEN.lerp(Color.DARK_GREEN, float(i) / snake_body.size())
			draw_rect(rect, body_color, true)
			# 高光
			var highlight_rect = Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.3))
			draw_rect(highlight_rect, Color(1, 1, 1, 0.3), true)
	
	# 绘制食物
	var food_rect = Rect2(
		area_pos.x + food_position.x * cell_width,
		area_pos.y + food_position.y * cell_height,
		cell_width - 2,
		cell_height - 2
	)
	
	# 根据食物类型绘制不同效果
	var food_center = food_rect.get_center()
	var food_radius = min(food_rect.size.x, food_rect.size.y) * 0.4
	
	match food_type:
		FoodType.NORMAL:
			# 普通红色食物
			draw_circle(food_center + Vector2(1, 1), food_radius, Color(0, 0, 0, 0.3))  # 阴影
			draw_circle(food_center, food_radius, Color.RED)
			draw_circle(food_center - Vector2(1, 1), food_radius * 0.6, Color(1, 0.5, 0.5, 0.8))  # 高光
		FoodType.GOLDEN:
			# 金色食物（闪烁效果）
			var pulse = sin(Time.get_ticks_msec() * 0.008) * 0.2 + 0.8
			draw_circle(food_center + Vector2(1, 1), food_radius, Color(0, 0, 0, 0.3))  # 阴影
			draw_circle(food_center, food_radius, Color.GOLD * pulse)
			draw_circle(food_center - Vector2(1, 1), food_radius * 0.6, Color.YELLOW)  # 高光
		FoodType.SPEED:
			# 蓝色加速食物
			draw_circle(food_center + Vector2(1, 1), food_radius, Color(0, 0, 0, 0.3))  # 阴影
			draw_circle(food_center, food_radius, Color.CYAN)
			draw_circle(food_center - Vector2(1, 1), food_radius * 0.6, Color.LIGHT_BLUE)  # 高光
		FoodType.SLOW:
			# 紫色减速食物
			draw_circle(food_center + Vector2(1, 1), food_radius, Color(0, 0, 0, 0.3))  # 阴影
			draw_circle(food_center, food_radius, Color.PURPLE)
			draw_circle(food_center - Vector2(1, 1), food_radius * 0.6, Color.MAGENTA)  # 高光
		FoodType.BONUS:
			# 彩虹奖励食物（旋转彩虹效果）
			var rainbow_time = Time.get_ticks_msec() * 0.003
			var rainbow_color = Color.from_hsv(fmod(rainbow_time, 1.0), 1.0, 1.0)
			draw_circle(food_center + Vector2(1, 1), food_radius, Color(0, 0, 0, 0.3))  # 阴影
			draw_circle(food_center, food_radius, rainbow_color)
			draw_circle(food_center - Vector2(1, 1), food_radius * 0.6, Color.WHITE)  # 高光


func _on_quit_button_pressed() -> void:
	self.hide()
	get_parent().remove_child(self)
	queue_free()
	pass 

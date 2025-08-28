extends Panel

# 游戏常量
const BOARD_WIDTH = 10
const BOARD_HEIGHT = 20
const CELL_SIZE = 30
const DATA_FILE_PATH = "user://playergamedata.json"

# 特殊方块类型
enum SpecialType {
	NORMAL,
	BOMB,      # 炸弹方块，消除周围方块
	LINE,      # 直线方块，消除整行
	RAINBOW    # 彩虹方块，消除同色方块
}

# 方块类型
enum PieceType {
	I, O, T, S, Z, J, L
}

# 方块形状定义
const PIECE_SHAPES = {
	PieceType.I: [
		[[1, 1, 1, 1]],
		[[1], [1], [1], [1]]
	],
	PieceType.O: [
		[[1, 1], [1, 1]]
	],
	PieceType.T: [
		[[0, 1, 0], [1, 1, 1]],
		[[1, 0], [1, 1], [1, 0]],
		[[1, 1, 1], [0, 1, 0]],
		[[0, 1], [1, 1], [0, 1]]
	],
	PieceType.S: [
		[[0, 1, 1], [1, 1, 0]],
		[[1, 0], [1, 1], [0, 1]]
	],
	PieceType.Z: [
		[[1, 1, 0], [0, 1, 1]],
		[[0, 1], [1, 1], [1, 0]]
	],
	PieceType.J: [
		[[1, 0, 0], [1, 1, 1]],
		[[1, 1], [1, 0], [1, 0]],
		[[1, 1, 1], [0, 0, 1]],
		[[0, 1], [0, 1], [1, 1]]
	],
	PieceType.L: [
		[[0, 0, 1], [1, 1, 1]],
		[[1, 0], [1, 0], [1, 1]],
		[[1, 1, 1], [1, 0, 0]],
		[[1, 1], [0, 1], [0, 1]]
	]
}

# 方块颜色
const PIECE_COLORS = {
	PieceType.I: Color.CYAN,
	PieceType.O: Color.YELLOW,
	PieceType.T: Color.MAGENTA,
	PieceType.S: Color.GREEN,
	PieceType.Z: Color.RED,
	PieceType.J: Color.BLUE,
	PieceType.L: Color.ORANGE
}

# 游戏变量
var board = []
var current_piece = null
var current_piece_pos = Vector2()
var current_piece_rotation = 0
var next_piece_type = PieceType.I
var score = 0
var level = 1
var lines_cleared = 0
var game_over = false
var game_started = false  # 添加游戏开始状态
var drop_time = 1.0
var best_score = 0
var games_played = 0
var total_lines_cleared = 0
var combo_count = 0
var special_pieces = []  # 存储特殊方块位置和类型
var player_data = {}

# 节点引用
@onready var game_area = $GameArea
@onready var next_piece_area = $NextPieceArea
@onready var score_label = $ScoreLabel
@onready var level_label = $LevelLabel
@onready var lines_label = $LinesLabel
@onready var game_over_label = $GameOverLabel
@onready var drop_timer = $DropTimer
@onready var virtual_controls = $VirtualControls

func _ready():
	# 连接定时器信号
	drop_timer.timeout.connect(_on_drop_timer_timeout)
	
	# 设置游戏区域样式
	game_area.modulate = Color(0.08, 0.12, 0.18, 0.9)
	next_piece_area.modulate = Color(0.1, 0.15, 0.25, 0.9)
	
	# 设置虚拟控制
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
	lines_cleared = 0
	drop_time = 1.0
	combo_count = 0
	games_played += 1
	
	# 初始化游戏板
	board.clear()
	special_pieces.clear()
	for y in range(BOARD_HEIGHT):
		var row = []
		for x in range(BOARD_WIDTH):
			row.append(0)
		board.append(row)
	
	# 生成第一个方块
	next_piece_type = randi() % PieceType.size()
	spawn_new_piece()
	
	# 更新UI
	update_ui()
	game_over_label.visible = false
	
	# 启动定时器
	drop_timer.wait_time = drop_time
	drop_timer.start()

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
		
		if not current_piece:
			return
		
		# 控制方块
		match event.keycode:
			KEY_A:
				handle_move_left()
			KEY_D:
				handle_move_right()
			KEY_S:
				handle_move_down()
			KEY_W:
				handle_rotate()
			KEY_SPACE:
				handle_drop()

# 控制函数
func handle_move_left():
	move_piece(-1, 0)

func handle_move_right():
	move_piece(1, 0)

func handle_move_down():
	move_piece(0, 1)

func handle_rotate():
	rotate_piece()

func handle_drop():
	drop_piece()

func handle_restart():
	init_game()

func spawn_new_piece():
	current_piece = {
		"type": next_piece_type,
		"rotation": 0
	}
	current_piece_pos = Vector2(BOARD_WIDTH / 2 - 1, 0)
	current_piece_rotation = 0
	
	# 生成下一个方块
	next_piece_type = randi() % PieceType.size()
	
	# 检查游戏是否结束
	if not can_place_piece(current_piece_pos, current_piece_rotation):
		game_over = true
		show_game_over()

func move_piece(dx: int, dy: int):
	var new_pos = current_piece_pos + Vector2(dx, dy)
	if can_place_piece(new_pos, current_piece_rotation):
		current_piece_pos = new_pos
		queue_redraw()

func rotate_piece():
	var new_rotation = (current_piece_rotation + 1) % get_piece_rotations(current_piece.type)
	if can_place_piece(current_piece_pos, new_rotation):
		current_piece_rotation = new_rotation
		queue_redraw()

func drop_piece():
	while can_place_piece(current_piece_pos + Vector2(0, 1), current_piece_rotation):
		current_piece_pos.y += 1
	place_piece()

func can_place_piece(pos: Vector2, rotation: int) -> bool:
	var shape = get_piece_shape(current_piece.type, rotation)
	for y in range(shape.size()):
		for x in range(shape[y].size()):
			if shape[y][x] == 1:
				var board_x = pos.x + x
				var board_y = pos.y + y
				
				# 检查边界
				if board_x < 0 or board_x >= BOARD_WIDTH or board_y >= BOARD_HEIGHT:
					return false
				
				# 检查碰撞
				if board_y >= 0 and board[board_y][board_x] != 0:
					return false
	return true

func place_piece():
	var shape = get_piece_shape(current_piece.type, current_piece_rotation)
	for y in range(shape.size()):
		for x in range(shape[y].size()):
			if shape[y][x] == 1:
				var board_x = current_piece_pos.x + x
				var board_y = current_piece_pos.y + y
				if board_y >= 0:
					board[board_y][board_x] = current_piece.type + 1
	
	# 检查并清除完整的行
	clear_lines()
	
	# 生成新方块
	spawn_new_piece()
	
	queue_redraw()

func clear_lines():
	var lines_to_clear = []
	
	# 找到完整的行
	for y in range(BOARD_HEIGHT):
		var is_full = true
		for x in range(BOARD_WIDTH):
			if board[y][x] == 0:
				is_full = false
				break
		if is_full:
			lines_to_clear.append(y)
	
	# 处理特殊方块效果
	process_special_pieces(lines_to_clear)
	
	# 清除行并下移
	for line_y in lines_to_clear:
		board.erase(board[line_y])
		var new_row = []
		for x in range(BOARD_WIDTH):
			new_row.append(0)
		board.insert(0, new_row)
	
	# 更新分数和等级
	if lines_to_clear.size() > 0:
		# 连击系统
		combo_count += 1
		var combo_bonus = combo_count * 50
		
		lines_cleared += lines_to_clear.size()
		total_lines_cleared += lines_to_clear.size()
		
		# 计算分数（包含连击奖励）
		var base_score = lines_to_clear.size() * 100 * level
		var line_bonus = 0
		match lines_to_clear.size():
			1: line_bonus = 0
			2: line_bonus = 300
			3: line_bonus = 500
			4: line_bonus = 800  # 俄罗斯方块
		
		score += base_score + line_bonus + combo_bonus
		
		# 每10行提升一个等级，速度递增
		level = lines_cleared / 10 + 1
		drop_time = max(0.05, 1.0 - (level - 1) * 0.08)
		drop_timer.wait_time = drop_time
		
		# 随机生成特殊方块
		if randf() < 0.1 + level * 0.02:  # 等级越高，特殊方块概率越大
			generate_special_piece()
	else:
		# 重置连击
		combo_count = 0
	
	update_ui()

func get_piece_shape(type: PieceType, rotation: int) -> Array:
	return PIECE_SHAPES[type][rotation]

func get_piece_rotations(type: PieceType) -> int:
	return PIECE_SHAPES[type].size()

func update_ui():
	score_label.text = "🏆 分数: " + str(score) + "\n💎 最高: " + str(best_score)
	level_label.text = "⚡ 等级: " + str(level) + "\n🎮 游戏: " + str(games_played)
	lines_label.text = "📊 消除: " + str(lines_cleared) + "\n🔥 连击: " + str(combo_count)

func show_game_over():
	drop_timer.stop()
	game_started = false
	
	# 检查并更新最高分
	if score > best_score:
		best_score = score
	
	# 保存玩家数据
	save_player_data()
	
	# 显示游戏结束信息
	game_over_label.text = "🎮 游戏结束 🎮\n\n🏆 本次分数: " + str(score) + "\n💎 最高分数: " + str(best_score) + "\n📊 消除行数: " + str(lines_cleared) + "\n⚡ 达到等级: " + str(level) + "\n\n🔄 按Q键或空格重新开始"
	game_over_label.visible = true

func _on_drop_timer_timeout():
	if not game_started or game_over or not current_piece:
		return
	
	if can_place_piece(current_piece_pos + Vector2(0, 1), current_piece_rotation):
		current_piece_pos.y += 1
		queue_redraw()
	else:
		place_piece()

# 虚拟控制设置
func setup_virtual_controls():
	if virtual_controls:
		virtual_controls.get_node("LeftButton").pressed.connect(_on_virtual_button_pressed.bind("left"))
		virtual_controls.get_node("RightButton").pressed.connect(_on_virtual_button_pressed.bind("right"))
		virtual_controls.get_node("DownButton").pressed.connect(_on_virtual_button_pressed.bind("down"))
		virtual_controls.get_node("RotateButton").pressed.connect(_on_virtual_button_pressed.bind("rotate"))
		virtual_controls.get_node("DropButton").pressed.connect(_on_virtual_button_pressed.bind("drop"))
		virtual_controls.get_node("RestartButton").pressed.connect(_on_virtual_button_pressed.bind("restart"))

func _on_virtual_button_pressed(action: String):
	if not game_started:
		if action == "restart":
			init_game()
		return
	
	if game_over and action == "restart":
		handle_restart()
		return
	
	if game_over or not current_piece:
		return
	
	match action:
		"left":
			handle_move_left()
		"right":
			handle_move_right()
		"down":
			handle_move_down()
		"rotate":
			handle_rotate()
		"drop":
			handle_drop()

# 特殊方块处理
func process_special_pieces(lines_to_clear: Array):
	# 处理特殊方块效果
	for special in special_pieces:
		var pos = special.position
		var type = special.type
		
		match type:
			SpecialType.BOMB:
				# 炸弹方块：清除周围3x3区域
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var x = pos.x + dx
						var y = pos.y + dy
						if x >= 0 and x < BOARD_WIDTH and y >= 0 and y < BOARD_HEIGHT:
							board[y][x] = 0
			SpecialType.LINE:
				# 直线方块：清除整行
				for x in range(BOARD_WIDTH):
					board[pos.y][x] = 0
			SpecialType.RAINBOW:
				# 彩虹方块：清除同色方块
				var target_color = board[pos.y][pos.x]
				if target_color > 0:
					for y in range(BOARD_HEIGHT):
						for x in range(BOARD_WIDTH):
							if board[y][x] == target_color:
								board[y][x] = 0
	
	# 清空特殊方块列表
	special_pieces.clear()

func generate_special_piece():
	# 在随机位置生成特殊方块
	var x = randi() % BOARD_WIDTH
	var y = randi() % (BOARD_HEIGHT - 5) + 5  # 在下半部分生成
	
	if board[y][x] != 0:  # 只在有方块的位置生成特殊效果
		var special_type = randi() % 3 + 1  # 随机选择特殊类型
		special_pieces.append({
			"position": Vector2(x, y),
			"type": special_type
		})

# 数据存储功能
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
				if player_data.has("tetris"):
					var tetris_data = player_data["tetris"]
					best_score = tetris_data.get("best_score", 0)
					games_played = tetris_data.get("games_played", 0)
					total_lines_cleared = tetris_data.get("total_lines_cleared", 0)

func show_start_screen():
	# 重置状态
	game_started = false
	game_over = false
	current_piece = null
	
	# 显示开始提示
	game_over_label.text = "🎮 俄罗斯方块 🎮\n\n🏆 最高分数: " + str(best_score) + "\n🎯 游戏次数: " + str(games_played) + "\n\n🎮 按Q键开始游戏\n\n🎯 操作说明:\nA/D - 左右移动\nW - 旋转\nS - 快速下落\n空格 - 直接落下"
	game_over_label.visible = true
	
	# 停止定时器
	drop_timer.stop()
	
	# 清空游戏板
	board.clear()
	special_pieces.clear()
	for y in range(BOARD_HEIGHT):
		var row = []
		for x in range(BOARD_WIDTH):
			row.append(0)
		board.append(row)
	
	update_ui()
	queue_redraw()

func save_player_data():
	if not player_data.has("tetris"):
		player_data["tetris"] = {}
	
	player_data["tetris"]["best_score"] = best_score
	player_data["tetris"]["games_played"] = games_played
	player_data["tetris"]["total_lines_cleared"] = total_lines_cleared
	player_data["tetris"]["last_played"] = Time.get_datetime_string_from_system()
	
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
	
	# 获取游戏区域的位置
	var area_pos = game_area.position
	var area_size = Vector2(BOARD_WIDTH * CELL_SIZE, BOARD_HEIGHT * CELL_SIZE)
	
	# 绘制游戏区域阴影
	var shadow_offset = Vector2(4, 4)
	var area_rect = Rect2(area_pos + shadow_offset, area_size)
	draw_rect(area_rect, Color(0, 0, 0, 0.4), true)
	
	# 绘制游戏区域背景
	area_rect = Rect2(area_pos, area_size)
	draw_rect(area_rect, Color(0.08, 0.12, 0.18, 0.9), true)
	
	# 绘制网格线（淡色）
	for x in range(BOARD_WIDTH + 1):
		var start_pos = Vector2(area_pos.x + x * CELL_SIZE, area_pos.y)
		var end_pos = Vector2(area_pos.x + x * CELL_SIZE, area_pos.y + BOARD_HEIGHT * CELL_SIZE)
		draw_line(start_pos, end_pos, Color(0.3, 0.3, 0.4, 0.3), 1)
	
	for y in range(BOARD_HEIGHT + 1):
		var start_pos = Vector2(area_pos.x, area_pos.y + y * CELL_SIZE)
		var end_pos = Vector2(area_pos.x + BOARD_WIDTH * CELL_SIZE, area_pos.y + y * CELL_SIZE)
		draw_line(start_pos, end_pos, Color(0.3, 0.3, 0.4, 0.3), 1)
	
	# 绘制游戏板
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var cell_value = board[y][x]
			if cell_value > 0:
				var rect = Rect2(
					area_pos.x + x * CELL_SIZE,
					area_pos.y + y * CELL_SIZE,
					CELL_SIZE - 2,
					CELL_SIZE - 2
				)
				var color = PIECE_COLORS[cell_value - 1]
				
				# 检查是否为特殊方块
				var is_special = false
				var special_type = SpecialType.NORMAL
				for special in special_pieces:
					if special.position == Vector2(x, y):
						is_special = true
						special_type = special.type
						break
				
				if is_special:
					# 绘制特殊方块效果
					match special_type:
						SpecialType.BOMB:
							# 炸弹方块（红色闪烁）
							var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.3 + 0.7
							draw_rect(rect, Color.RED * pulse, true)
							draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), Color.ORANGE, true)
						SpecialType.LINE:
							# 直线方块（蓝色闪烁）
							var pulse = sin(Time.get_ticks_msec() * 0.008) * 0.3 + 0.7
							draw_rect(rect, Color.CYAN * pulse, true)
							draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), Color.LIGHT_BLUE, true)
						SpecialType.RAINBOW:
							# 彩虹方块（彩虹色）
							var rainbow_time = Time.get_ticks_msec() * 0.003
							var rainbow_color = Color.from_hsv(fmod(rainbow_time, 1.0), 1.0, 1.0)
							draw_rect(rect, rainbow_color, true)
							draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), Color.WHITE, true)
				else:
					# 普通方块（立体效果）
					draw_rect(rect, color, true)
					# 高光
					var highlight_rect = Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.3))
					draw_rect(highlight_rect, Color(1, 1, 1, 0.3), true)
					# 阴影
					var shadow_rect = Rect2(rect.position + Vector2(1, rect.size.y * 0.7), Vector2(rect.size.x - 2, rect.size.y * 0.3))
					draw_rect(shadow_rect, Color(0, 0, 0, 0.2), true)
	
	# 绘制当前方块（带透明度预览）
	if current_piece:
		var shape = get_piece_shape(current_piece.type, current_piece_rotation)
		
		# 绘制投影（显示方块会落在哪里）
		var shadow_pos = current_piece_pos
		while can_place_piece(shadow_pos + Vector2(0, 1), current_piece_rotation):
			shadow_pos.y += 1
		
		for y in range(shape.size()):
			for x in range(shape[y].size()):
				if shape[y][x] == 1:
					var board_x = shadow_pos.x + x
					var board_y = shadow_pos.y + y
					if board_y >= 0 and board_x >= 0 and board_x < BOARD_WIDTH and board_y < BOARD_HEIGHT:
						var rect = Rect2(
							area_pos.x + board_x * CELL_SIZE,
							area_pos.y + board_y * CELL_SIZE,
							CELL_SIZE - 2,
							CELL_SIZE - 2
						)
						var shadow_color = PIECE_COLORS[current_piece.type]
						shadow_color.a = 0.3
						draw_rect(rect, shadow_color, false, 2)
		
		# 绘制当前方块
		for y in range(shape.size()):
			for x in range(shape[y].size()):
				if shape[y][x] == 1:
					var board_x = current_piece_pos.x + x
					var board_y = current_piece_pos.y + y
					if board_y >= 0:
						var rect = Rect2(
							area_pos.x + board_x * CELL_SIZE,
							area_pos.y + board_y * CELL_SIZE,
							CELL_SIZE - 2,
							CELL_SIZE - 2
						)
						var color = PIECE_COLORS[current_piece.type]
						# 立体效果
						draw_rect(rect, color, true)
						# 高光
						var highlight_rect = Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.3))
						draw_rect(highlight_rect, Color(1, 1, 1, 0.4), true)
	
	# 绘制下一个方块预览区域背景
	var next_area_pos = next_piece_area.position
	var next_area_size = next_piece_area.size
	draw_rect(Rect2(next_area_pos + Vector2(2, 2), next_area_size), Color(0, 0, 0, 0.3), true)
	draw_rect(Rect2(next_area_pos, next_area_size), Color(0.1, 0.15, 0.25, 0.9), true)
	
	# 绘制下一个方块预览
	var next_shape = get_piece_shape(next_piece_type, 0)
	for y in range(next_shape.size()):
		for x in range(next_shape[y].size()):
			if next_shape[y][x] == 1:
				var rect = Rect2(
					next_area_pos.x + 20 + x * 20,
					next_area_pos.y + 50 + y * 20,
					18,
					18
				)
				var color = PIECE_COLORS[next_piece_type]
				# 立体效果
				draw_rect(rect, color, true)
				# 高光
				var highlight_rect = Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.3))
				draw_rect(highlight_rect, Color(1, 1, 1, 0.3), true)


func _on_quit_button_pressed() -> void:
	self.hide()
	get_parent().remove_child(self)
	queue_free()
	pass 

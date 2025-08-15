extends Panel

# 游戏常量
const BOARD_WIDTH = 10
const BOARD_HEIGHT = 20
const CELL_SIZE = 30

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
var drop_time = 1.0

# 节点引用
@onready var game_area = $GameArea
@onready var next_piece_area = $NextPieceArea
@onready var score_label = $ScoreLabel
@onready var level_label = $LevelLabel
@onready var lines_label = $LinesLabel
@onready var game_over_label = $GameOverLabel
@onready var drop_timer = $DropTimer

func _ready():
	# 连接定时器信号
	drop_timer.timeout.connect(_on_drop_timer_timeout)
	
	# 设置游戏区域样式
	game_area.modulate = Color(0.1, 0.1, 0.1, 1.0)
	next_piece_area.modulate = Color(0.2, 0.2, 0.2, 1.0)
	
	# 初始化游戏
	init_game()

func init_game():
	# 重置游戏状态
	game_over = false
	score = 0
	level = 1
	lines_cleared = 0
	drop_time = 1.0
	
	# 初始化游戏板
	board.clear()
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
		if game_over:
			if event.keycode == KEY_SPACE:
				init_game()
			return
		
		if not current_piece:
			return
		
		# 控制方块
		match event.keycode:
			KEY_A:
				move_piece(-1, 0)
			KEY_D:
				move_piece(1, 0)
			KEY_S:
				move_piece(0, 1)
			KEY_W:
				rotate_piece()
			KEY_SPACE:
				drop_piece()

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
	
	# 清除行并下移
	for line_y in lines_to_clear:
		board.erase(board[line_y])
		var new_row = []
		for x in range(BOARD_WIDTH):
			new_row.append(0)
		board.insert(0, new_row)
	
	# 更新分数和等级
	if lines_to_clear.size() > 0:
		lines_cleared += lines_to_clear.size()
		score += lines_to_clear.size() * 100 * level
		
		# 每10行提升一个等级
		level = lines_cleared / 10 + 1
		drop_time = max(0.1, 1.0 - (level - 1) * 0.1)
		drop_timer.wait_time = drop_time
		
		update_ui()

func get_piece_shape(type: PieceType, rotation: int) -> Array:
	return PIECE_SHAPES[type][rotation]

func get_piece_rotations(type: PieceType) -> int:
	return PIECE_SHAPES[type].size()

func update_ui():
	score_label.text = "分数: " + str(score)
	level_label.text = "等级: " + str(level)
	lines_label.text = "消除行数: " + str(lines_cleared)

func show_game_over():
	drop_timer.stop()
	game_over_label.visible = true

func _on_drop_timer_timeout():
	if game_over or not current_piece:
		return
	
	if can_place_piece(current_piece_pos + Vector2(0, 1), current_piece_rotation):
		current_piece_pos.y += 1
		queue_redraw()
	else:
		place_piece()

func _draw():
	if not game_area:
		return
	
	# 获取游戏区域的位置
	var area_pos = game_area.position
	
	# 绘制游戏板
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var cell_value = board[y][x]
			if cell_value > 0:
				var rect = Rect2(
					area_pos.x + x * CELL_SIZE,
					area_pos.y + y * CELL_SIZE,
					CELL_SIZE - 1,
					CELL_SIZE - 1
				)
				var color = PIECE_COLORS[cell_value - 1]
				draw_rect(rect, color)
	
	# 绘制当前方块
	if current_piece:
		var shape = get_piece_shape(current_piece.type, current_piece_rotation)
		for y in range(shape.size()):
			for x in range(shape[y].size()):
				if shape[y][x] == 1:
					var board_x = current_piece_pos.x + x
					var board_y = current_piece_pos.y + y
					if board_y >= 0:
						var rect = Rect2(
							area_pos.x + board_x * CELL_SIZE,
							area_pos.y + board_y * CELL_SIZE,
							CELL_SIZE - 1,
							CELL_SIZE - 1
						)
						var color = PIECE_COLORS[current_piece.type]
						draw_rect(rect, color)
	
	# 绘制网格线
	for x in range(BOARD_WIDTH + 1):
		var start_pos = Vector2(area_pos.x + x * CELL_SIZE, area_pos.y)
		var end_pos = Vector2(area_pos.x + x * CELL_SIZE, area_pos.y + BOARD_HEIGHT * CELL_SIZE)
		draw_line(start_pos, end_pos, Color.GRAY, 1)
	
	for y in range(BOARD_HEIGHT + 1):
		var start_pos = Vector2(area_pos.x, area_pos.y + y * CELL_SIZE)
		var end_pos = Vector2(area_pos.x + BOARD_WIDTH * CELL_SIZE, area_pos.y + y * CELL_SIZE)
		draw_line(start_pos, end_pos, Color.GRAY, 1)
	
	# 绘制下一个方块预览
	var next_area_pos = next_piece_area.position
	var next_shape = get_piece_shape(next_piece_type, 0)
	for y in range(next_shape.size()):
		for x in range(next_shape[y].size()):
			if next_shape[y][x] == 1:
				var rect = Rect2(
					next_area_pos.x + 20 + x * 20,
					next_area_pos.y + 50 + y * 20,
					19,
					19
				)
				var color = PIECE_COLORS[next_piece_type]
				draw_rect(rect, color)

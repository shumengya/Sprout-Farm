extends Panel

# 游戏常量
const GRID_SIZE = 4
const CELL_SIZE = 90
const CELL_MARGIN = 10

# 数字颜色配置
const NUMBER_COLORS = {
	0: Color.TRANSPARENT,
	2: Color(0.93, 0.89, 0.85),
	4: Color(0.93, 0.88, 0.78),
	8: Color(0.95, 0.69, 0.47),
	16: Color(0.96, 0.58, 0.39),
	32: Color(0.96, 0.49, 0.37),
	64: Color(0.96, 0.37, 0.23),
	128: Color(0.93, 0.81, 0.45),
	256: Color(0.93, 0.80, 0.38),
	512: Color(0.93, 0.78, 0.31),
	1024: Color(0.93, 0.77, 0.25),
	2048: Color(0.93, 0.76, 0.18)
}

const TEXT_COLORS = {
	2: Color.BLACK,
	4: Color.BLACK,
	8: Color.WHITE,
	16: Color.WHITE,
	32: Color.WHITE,
	64: Color.WHITE,
	128: Color.WHITE,
	256: Color.WHITE,
	512: Color.WHITE,
	1024: Color.WHITE,
	2048: Color.WHITE
}

# 游戏变量
var grid = []
var score = 0
var best_score = 0
var game_over = false
var won = false
var can_continue = true

# 节点引用
@onready var game_board = $GameBoard
@onready var score_label = $ScoreLabel
@onready var best_label = $BestLabel
@onready var game_over_label = $GameOverLabel
@onready var win_label = $WinLabel

func _ready():
	# 设置游戏板样式
	game_board.modulate = Color(0.7, 0.6, 0.5)
	
	# 初始化游戏
	init_game()

func init_game():
	# 重置游戏状态
	game_over = false
	won = false
	can_continue = true
	score = 0
	
	# 初始化网格
	grid.clear()
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(0)
		grid.append(row)
	
	# 添加两个初始数字
	add_random_number()
	add_random_number()
	
	# 更新UI
	update_ui()
	hide_labels()
	
	queue_redraw()

func _input(event):
	if event is InputEventKey and event.pressed:
		if game_over:
			if event.keycode == KEY_R:
				init_game()
			return
		
		if won and not can_continue:
			if event.keycode == KEY_C:
				can_continue = true
				win_label.visible = false
			return
		
		# 移动控制
		var moved = false
		match event.keycode:
			KEY_UP, KEY_W:
				moved = move_up()
			KEY_DOWN, KEY_S:
				moved = move_down()
			KEY_LEFT, KEY_A:
				moved = move_left()
			KEY_RIGHT, KEY_D:
				moved = move_right()
			KEY_R:
				init_game()
				return
		
		if moved:
			add_random_number()
			update_ui()
			check_game_state()
			queue_redraw()

func move_left() -> bool:
	var moved = false
	for y in range(GRID_SIZE):
		var row = grid[y].duplicate()
		var new_row = merge_line(row)
		if new_row != grid[y]:
			moved = true
			grid[y] = new_row
	return moved

func move_right() -> bool:
	var moved = false
	for y in range(GRID_SIZE):
		var row = grid[y].duplicate()
		row.reverse()
		var new_row = merge_line(row)
		new_row.reverse()
		if new_row != grid[y]:
			moved = true
			grid[y] = new_row
	return moved

func move_up() -> bool:
	var moved = false
	for x in range(GRID_SIZE):
		var column = []
		for y in range(GRID_SIZE):
			column.append(grid[y][x])
		
		var new_column = merge_line(column)
		var changed = false
		for y in range(GRID_SIZE):
			if grid[y][x] != new_column[y]:
				changed = true
				grid[y][x] = new_column[y]
		
		if changed:
			moved = true
	return moved

func move_down() -> bool:
	var moved = false
	for x in range(GRID_SIZE):
		var column = []
		for y in range(GRID_SIZE):
			column.append(grid[y][x])
		
		column.reverse()
		var new_column = merge_line(column)
		new_column.reverse()
		
		var changed = false
		for y in range(GRID_SIZE):
			if grid[y][x] != new_column[y]:
				changed = true
				grid[y][x] = new_column[y]
		
		if changed:
			moved = true
	return moved

func merge_line(line: Array) -> Array:
	# 移除零
	var filtered = []
	for num in line:
		if num != 0:
			filtered.append(num)
	
	# 合并相同数字
	var merged = []
	var i = 0
	while i < filtered.size():
		if i < filtered.size() - 1 and filtered[i] == filtered[i + 1]:
			# 合并
			var new_value = filtered[i] * 2
			merged.append(new_value)
			score += new_value
			i += 2
		else:
			merged.append(filtered[i])
			i += 1
	
	# 填充零到指定长度
	while merged.size() < GRID_SIZE:
		merged.append(0)
	
	return merged

func add_random_number():
	var empty_cells = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] == 0:
				empty_cells.append(Vector2(x, y))
	
	if empty_cells.size() > 0:
		var random_cell = empty_cells[randi() % empty_cells.size()]
		var value = 2 if randf() < 0.9 else 4
		grid[random_cell.y][random_cell.x] = value

func check_game_state():
	# 检查是否达到2048
	if not won:
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if grid[y][x] == 2048:
					won = true
					can_continue = false
					win_label.visible = true
					return
	
	# 检查是否游戏结束
	if not can_move():
		game_over = true
		if score > best_score:
			best_score = score
		game_over_label.visible = true

func can_move() -> bool:
	# 检查是否有空格
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] == 0:
				return true
	
	# 检查是否可以合并
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var current = grid[y][x]
			# 检查右边
			if x < GRID_SIZE - 1 and grid[y][x + 1] == current:
				return true
			# 检查下面
			if y < GRID_SIZE - 1 and grid[y + 1][x] == current:
				return true
	
	return false

func update_ui():
	score_label.text = "分数: " + str(score)
	best_label.text = "最高分: " + str(best_score)

func hide_labels():
	game_over_label.visible = false
	win_label.visible = false

func _draw():
	if not game_board:
		return
	
	# 获取游戏板位置
	var board_pos = game_board.position
	
	# 绘制网格背景
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell_x = board_pos.x + x * (CELL_SIZE + CELL_MARGIN) + CELL_MARGIN
			var cell_y = board_pos.y + y * (CELL_SIZE + CELL_MARGIN) + CELL_MARGIN
			var rect = Rect2(cell_x, cell_y, CELL_SIZE, CELL_SIZE)
			
			# 绘制单元格背景
			draw_rect(rect, Color(0.8, 0.7, 0.6), true)
			
			# 绘制数字
			var value = grid[y][x]
			if value > 0:
				# 绘制数字背景
				var bg_color = NUMBER_COLORS.get(value, Color.GOLD)
				draw_rect(rect, bg_color, true)
				
				# 绘制数字文本
				var text = str(value)
				var font_size = 24 if value < 100 else (20 if value < 1000 else 16)
				var text_color = TEXT_COLORS.get(value, Color.WHITE)
				
				# 获取默认字体
				var font = ThemeDB.fallback_font
				
				# 计算文本尺寸
				var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
				
				# 计算文本位置（居中）
				var text_pos = Vector2(
					cell_x + (CELL_SIZE - text_size.x) / 2,
					cell_y + (CELL_SIZE - text_size.y) / 2 + text_size.y
				)
				
				# 绘制文本
				draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

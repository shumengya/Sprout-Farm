extends Panel

# 游戏常量
const CELL_SIZE = 40

# 地图元素
enum CellType {
	EMPTY,    # 空地
	WALL,     # 墙壁
	TARGET,   # 目标点
	BOX,      # 箱子
	PLAYER,   # 玩家
	BOX_ON_TARGET  # 箱子在目标点上
}

# 颜色配置
const CELL_COLORS = {
	CellType.EMPTY: Color.WHITE,
	CellType.WALL: Color.DARK_GRAY,
	CellType.TARGET: Color.LIGHT_BLUE,
	CellType.BOX: Color.SADDLE_BROWN,
	CellType.PLAYER: Color.GREEN,
	CellType.BOX_ON_TARGET: Color.DARK_GREEN
}

# 关卡数据
const LEVELS = [
	# 关卡1 - 简单入门
	[
		"########",
		"#......#",
		"#..##..#",
		"#..#*..#",
		"#..#$..#",
		"#..@...#",
		"#......#",
		"########"
	],
	# 关卡2 - 两个箱子
	[
		"########",
		"#......#",
		"#.*$*..#",
		"#......#",
		"#..$...#",
		"#..@...#",
		"#......#",
		"########"
	],
	# 关卡3 - 稍微复杂
	[
		"##########",
		"#........#",
		"#..####..#",
		"#..*##*..#",
		"#..$$....#",
		"#........#",
		"#...@....#",
		"#........#",
		"##########"
	],
	# 关卡4 - 更复杂的布局
	[
		"############",
		"#..........#",
		"#..######..#",
		"#..*....#..#",
		"#..$....#..#",
		"#.......#..#",
		"#..#....#..#",
		"#..*....#..#",
		"#..$......@#",
		"#..........#",
		"############"
	]
]

# 游戏变量
var current_level = 0
var level_data = []
var player_pos = Vector2()
var moves = 0
var level_completed = false
var map_width = 0
var map_height = 0

# 节点引用
@onready var game_area = $GameArea
@onready var level_label = $LevelLabel
@onready var moves_label = $MovesLabel
@onready var win_label = $WinLabel

func _ready():
	# 设置游戏区域样式
	game_area.modulate = Color(0.9, 0.9, 0.9)
	
	# 初始化游戏
	init_level()

func init_level():
	# 重置游戏状态
	level_completed = false
	moves = 0
	
	# 加载当前关卡
	load_level(current_level)
	
	# 更新UI
	update_ui()
	win_label.visible = false
	
	queue_redraw()

func load_level(level_index: int):
	if level_index >= LEVELS.size():
		level_index = LEVELS.size() - 1
	
	var level_strings = LEVELS[level_index]
	map_height = level_strings.size()
	map_width = level_strings[0].length()
	
	# 初始化关卡数据
	level_data.clear()
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			row.append(CellType.EMPTY)
		level_data.append(row)
	
	# 解析关卡字符串
	for y in range(map_height):
		var line = level_strings[y]
		for x in range(line.length()):
			var char = line[x]
			match char:
				'#':  # 墙壁
					level_data[y][x] = CellType.WALL
				'*':  # 目标点
					level_data[y][x] = CellType.TARGET
				'$':  # 箱子
					level_data[y][x] = CellType.BOX
				'@':  # 玩家
					level_data[y][x] = CellType.PLAYER
					player_pos = Vector2(x, y)
				'+':  # 箱子在目标点上
					level_data[y][x] = CellType.BOX_ON_TARGET
				'.':  # 空地
					level_data[y][x] = CellType.EMPTY

func _input(event):
	if event is InputEventKey and event.pressed:
		if level_completed:
			match event.keycode:
				KEY_N:
					next_level()
				KEY_R:
					init_level()
			return
		
		# 移动控制
		var direction = Vector2.ZERO
		match event.keycode:
			KEY_UP, KEY_W:
				direction = Vector2(0, -1)
			KEY_DOWN, KEY_S:
				direction = Vector2(0, 1)
			KEY_LEFT, KEY_A:
				direction = Vector2(-1, 0)
			KEY_RIGHT, KEY_D:
				direction = Vector2(1, 0)
			KEY_R:
				init_level()
				return
			KEY_P:
				prev_level()
				return
			KEY_N:
				next_level()
				return
		
		if direction != Vector2.ZERO:
			move_player(direction)

func move_player(direction: Vector2):
	var new_pos = player_pos + direction
	
	# 检查边界
	if new_pos.x < 0 or new_pos.x >= map_width or new_pos.y < 0 or new_pos.y >= map_height:
		return
	
	var target_cell = level_data[new_pos.y][new_pos.x]
	
	# 检查是否撞墙
	if target_cell == CellType.WALL:
		return
	
	# 检查是否推箱子
	if target_cell == CellType.BOX or target_cell == CellType.BOX_ON_TARGET:
		var box_new_pos = new_pos + direction
		
		# 检查箱子新位置是否有效
		if box_new_pos.x < 0 or box_new_pos.x >= map_width or box_new_pos.y < 0 or box_new_pos.y >= map_height:
			return
		
		var box_target_cell = level_data[box_new_pos.y][box_new_pos.x]
		
		# 箱子不能推到墙上或其他箱子上
		if box_target_cell == CellType.WALL or box_target_cell == CellType.BOX or box_target_cell == CellType.BOX_ON_TARGET:
			return
		
		# 移动箱子
		var was_on_target = (target_cell == CellType.BOX_ON_TARGET)
		var moving_to_target = (box_target_cell == CellType.TARGET)
		
		# 更新箱子原位置
		if was_on_target:
			level_data[new_pos.y][new_pos.x] = CellType.TARGET
		else:
			level_data[new_pos.y][new_pos.x] = CellType.EMPTY
		
		# 更新箱子新位置
		if moving_to_target:
			level_data[box_new_pos.y][box_new_pos.x] = CellType.BOX_ON_TARGET
		else:
			level_data[box_new_pos.y][box_new_pos.x] = CellType.BOX
	
	# 移动玩家
	# 恢复玩家原位置（检查是否在目标点上）
	var level_strings = LEVELS[current_level]
	if player_pos.y < level_strings.size() and player_pos.x < level_strings[player_pos.y].length():
		var original_char = level_strings[player_pos.y][player_pos.x]
		if original_char == '*':  # 玩家原来在目标点上
			level_data[player_pos.y][player_pos.x] = CellType.TARGET
		else:
			level_data[player_pos.y][player_pos.x] = CellType.EMPTY
	else:
		level_data[player_pos.y][player_pos.x] = CellType.EMPTY
	
	# 更新玩家位置
	player_pos = new_pos
	level_data[player_pos.y][player_pos.x] = CellType.PLAYER
	
	# 增加步数
	moves += 1
	
	# 检查是否过关
	check_win_condition()
	
	# 更新UI和重绘
	update_ui()
	queue_redraw()

func check_win_condition():
	# 检查是否所有箱子都在目标点上
	for y in range(map_height):
		for x in range(map_width):
			if level_data[y][x] == CellType.BOX:
				return  # 还有箱子不在目标点上
	
	# 所有箱子都在目标点上，过关！
	level_completed = true
	win_label.visible = true

func next_level():
	if current_level < LEVELS.size() - 1:
		current_level += 1
		init_level()

func prev_level():
	if current_level > 0:
		current_level -= 1
		init_level()

func update_ui():
	level_label.text = "关卡: " + str(current_level + 1)
	moves_label.text = "步数: " + str(moves)

func _draw():
	if not game_area:
		return
	
	# 获取游戏区域位置
	var area_pos = game_area.position
	
	# 计算起始绘制位置（居中）
	var start_x = area_pos.x + (game_area.size.x - map_width * CELL_SIZE) / 2
	var start_y = area_pos.y + (game_area.size.y - map_height * CELL_SIZE) / 2
	
	# 绘制地图
	for y in range(map_height):
		for x in range(map_width):
			var cell_x = start_x + x * CELL_SIZE
			var cell_y = start_y + y * CELL_SIZE
			var rect = Rect2(cell_x, cell_y, CELL_SIZE, CELL_SIZE)
			
			var cell_type = level_data[y][x]
			var color = CELL_COLORS[cell_type]
			
			# 绘制单元格
			draw_rect(rect, color, true)
			
			# 绘制边框
			draw_rect(rect, Color.BLACK, false, 1)
			
			# 特殊处理：如果是玩家在目标点上，需要先绘制目标点
			if cell_type == CellType.PLAYER:
				# 检查玩家下面是否有目标点（通过检查原始关卡数据）
				var level_strings = LEVELS[current_level]
				if y < level_strings.size() and x < level_strings[y].length():
					var original_char = level_strings[y][x]
					if original_char == '*':  # 玩家在目标点上
						draw_rect(rect, CELL_COLORS[CellType.TARGET], true)
						draw_rect(rect, Color.BLACK, false, 1)
						# 再绘制玩家（半透明）
						var player_color = CELL_COLORS[CellType.PLAYER]
						player_color.a = 0.8
						draw_rect(rect, player_color, true)

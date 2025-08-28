extends Panel

# 游戏常量
const CELL_SIZE = 40
const DATA_FILE_PATH = "user://playergamedata.json"

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
	],
	# 关卡5 - 角落挑战
	[
		"#########",
		"#*......#",
		"#.##....#",
		"#.#$....#",
		"#.#.....#",
		"#.#.....#",
		"#.......#",
		"#......@#",
		"#########"
	],
	# 关卡6 - 多箱子排列
	[
		"##########",
		"#........#",
		"#.*.*.*..#",
		"#........#",
		"#.$.$.$..#",
		"#........#",
		"#....@...#",
		"#........#",
		"##########"
	],
	# 关卡7 - 迷宫式
	[
		"############",
		"#..........#",
		"#.##.##.##.#",
		"#.*#.#*.#*.#",
		"#..#.#..#..#",
		"#.$#.#$.#$.#",
		"#..#.#..#..#",
		"#..#.#..#..#",
		"#..........#",
		"#....@.....#",
		"############"
	],
	# 关卡8 - 紧密配合
	[
		"#########",
		"#.......#",
		"#.##*##.#",
		"#.#$.$#.#",
		"#.#*.*#.#",
		"#.#$.$#.#",
		"#.##*##.#",
		"#...@...#",
		"#########"
	],
	# 关卡9 - 长廊挑战
	[
		"##############",
		"#............#",
		"#.##########.#",
		"#.*........*.#",
		"#.$.......$.#",
		"#............#",
		"#............#",
		"#.$.......$.#",
		"#.*........*.#",
		"#.##########.#",
		"#......@.....#",
		"##############"
	],
	# 关卡10 - 螺旋结构
	[
		"###########",
		"#.........#",
		"#.#######.#",
		"#.#*...#.#",
		"#.#.#$.#.#",
		"#.#.#*.#.#",
		"#.#.#$.#.#",
		"#.#...#.#",
		"#.#####.#",
		"#...@...#",
		"###########"
	],
	# 关卡11 - 对称美学
	[
		"############",
		"#..........#",
		"#.*#....#*.#",
		"#.$#....#$.#",
		"#..#....#..#",
		"#..........#",
		"#..........#",
		"#..#....#..#",
		"#.$#....#$.#",
		"#.*#....#*.#",
		"#.....@....#",
		"############"
	],
	# 关卡12 - 十字路口
	[
		"###########",
		"#.........#",
		"#....#....#",
		"#.*..#..*#",
		"#.$.###.$.#",
		"#...#@#...#",
		"#.$.###.$.#",
		"#.*..#..*#",
		"#....#....#",
		"#.........#",
		"###########"
	],
	# 关卡13 - 复杂迷宫
	[
		"##############",
		"#............#",
		"#.##.####.##.#",
		"#.*#......#*.#",
		"#.$#.####.#$.#",
		"#..#.#..#.#..#",
		"#....#..#....#",
		"#..#.#..#.#..#",
		"#.$#.####.#$.#",
		"#.*#......#*.#",
		"#.##.####.##.#",
		"#......@.....#",
		"##############"
	],
	# 关卡14 - 精密操作
	[
		"##########",
		"#........#",
		"#.######.#",
		"#.#*..*.#",
		"#.#$..$.#",
		"#.#....#.#",
		"#.#$..$.#",
		"#.#*..*.#",
		"#.######.#",
		"#...@....#",
		"##########"
	],
	# 关卡15 - 终极挑战
	[
		"###############",
		"#.............#",
		"#.###.###.###.#",
		"#.*#*.*#*.*#*.#",
		"#.$#$.$#$.$#$.#",
		"#.###.###.###.#",
		"#.............#",
		"#.###.###.###.#",
		"#.$#$.$#$.$#$.#",
		"#.*#*.*#*.*#*.#",
		"#.###.###.###.#",
		"#.......@.....#",
		"###############"
	],
	# 关卡16 - 狭窄通道
	[
		"#############",
		"#...........#",
		"#.#.#.#.#.#.#",
		"#*#*#*#*#*#*#",
		"#$#$#$#$#$#$#",
		"#.#.#.#.#.#.#",
		"#...........#",
		"#.#.#.#.#.#.#",
		"#$#$#$#$#$#$#",
		"#*#*#*#*#*#*#",
		"#.#.#.#.#.#.#",
		"#.....@.....#",
		"#############"
	],
	# 关卡17 - 环形结构
	[
		"##############",
		"#............#",
		"#.##########.#",
		"#.#........#.#",
		"#.#.######.#.#",
		"#.#.#*..*.#.#.#",
		"#.#.#$..$.#.#.#",
		"#.#.#....#.#.#",
		"#.#.######.#.#",
		"#.#........#.#",
		"#.##########.#",
		"#......@.....#",
		"##############"
	],
	# 关卡18 - 多层迷宫
	[
		"################",
		"#..............#",
		"#.############.#",
		"#.#*........*.#.#",
		"#.#$........$.#.#",
		"#.#..########..#.#",
		"#.#..#*....*.#..#.#",
		"#.#..#$....$.#..#.#",
		"#.#..########..#.#",
		"#.#$........$.#.#",
		"#.#*........*.#.#",
		"#.############.#",
		"#........@.....#",
		"################"
	],
	# 关卡19 - 钻石形状
	[
		"#########",
		"#.......#",
		"#...*...#",
		"#..*$*..#",
		"#.*$@$*.#",
		"#..*$*..#",
		"#...*...#",
		"#.......#",
		"#########"
	],
	# 关卡20 - 复杂交叉
	[
		"###############",
		"#.............#",
		"#.#.#.#.#.#.#.#",
		"#*#*#*#*#*#*#*#",
		"#$#$#$#$#$#$#$#",
		"#.#.#.#.#.#.#.#",
		"#.............#",
		"#.#.#.#.#.#.#.#",
		"#$#$#$#$#$#$#$#",
		"#*#*#*#*#*#*#*#",
		"#.#.#.#.#.#.#.#",
		"#.............#",
		"#.#.#.#@#.#.#.#",
		"#.............#",
		"###############"
	],
	# 关卡21 - 螺旋深渊
	[
		"#############",
		"#...........#",
		"#.#########.#",
		"#.#.......#.#",
		"#.#.#####.#.#",
		"#.#.#*..#.#.#",
		"#.#.#$#.#.#.#",
		"#.#.#*#.#.#.#",
		"#.#.#$#.#.#.#",
		"#.#.###.#.#.#",
		"#.#.....#.#.#",
		"#.#######.#.#",
		"#.........#.#",
		"#.....@...#.#",
		"#############"
	],
	# 关卡22 - 双重挑战
	[
		"##############",
		"#............#",
		"#.####..####.#",
		"#.#*.#..#.*#.#",
		"#.#$.#..#.$#.#",
		"#.#..####..#.#",
		"#.#........#.#",
		"#.#........#.#",
		"#.#..####..#.#",
		"#.#$.#..#.$#.#",
		"#.#*.#..#.*#.#",
		"#.####..####.#",
		"#......@.....#",
		"##############"
	],
	# 关卡23 - 星形布局
	[
		"###########",
		"#.........#",
		"#....#....#",
		"#.#.*#*.#.#",
		"#.#$###$#.#",
		"#.*#.@.#*.#",
		"#.#$###$#.#",
		"#.#.*#*.#.#",
		"#....#....#",
		"#.........#",
		"###########"
	],
	# 关卡24 - 终极迷宫
	[
		"################",
		"#..............#",
		"#.############.#",
		"#.#*.........*.#",
		"#.#$#########$#.#",
		"#.#.#*......*.#.#",
		"#.#.#$######$#.#.#",
		"#.#.#.#*..*.#.#.#.#",
		"#.#.#.#$..$.#.#.#.#",
		"#.#.#.######.#.#.#",
		"#.#.#........#.#.#",
		"#.#.##########.#.#",
		"#.#............#.#",
		"#.##############.#",
		"#........@.......#",
		"################"
	],
	# 关卡25 - 大师级挑战
	[
		"#################",
		"#...............#",
		"#.#############.#",
		"#.#*.*.*.*.*.*#.#",
		"#.#$.$.$.$.$.$#.#",
		"#.#.###########.#",
		"#.#.#*.*.*.*.*#.#",
		"#.#.#$.$.$.$.$#.#",
		"#.#.#.#######.#.#",
		"#.#.#.#*.*.*#.#.#",
		"#.#.#.#$.$.$#.#.#",
		"#.#.#.#####.#.#.#",
		"#.#.#.......#.#.#",
		"#.#.#########.#.#",
		"#.#...........#.#",
		"#.#############.#",
		"#.........@.....#",
		"#################"
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
var total_moves = 0
var levels_completed = 0
var best_moves_per_level = {}
var player_data = {}

# 节点引用
@onready var game_area = $GameArea
@onready var level_label = $LevelLabel
@onready var moves_label = $MovesLabel
@onready var win_label = $WinLabel
@onready var stats_label = $StatsLabel
@onready var virtual_controls = $VirtualControls

func _ready():
	# 设置游戏区域样式
	game_area.modulate = Color(0.9, 0.9, 0.9)
	
	# 加载玩家数据
	load_player_data()
	
	# 初始化游戏
	init_level()
	
	# 设置虚拟按键
	setup_virtual_controls()

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
	total_moves += 1
	
	# 检查是否过关
	check_win_condition()
	
	# 更新UI和重绘
	update_ui()
	save_player_data()
	queue_redraw()

func check_win_condition():
	# 检查是否所有箱子都在目标点上
	for y in range(map_height):
		for x in range(map_width):
			if level_data[y][x] == CellType.BOX:
				return  # 还有箱子不在目标点上
	
	# 所有箱子都在目标点上，过关！
	level_completed = true
	levels_completed += 1
	
	# 记录最佳步数
	var level_key = str(current_level + 1)
	if not best_moves_per_level.has(level_key) or moves < best_moves_per_level[level_key]:
		best_moves_per_level[level_key] = moves
	
	win_label.text = "恭喜过关！\n步数: " + str(moves) + "\n最佳: " + str(best_moves_per_level.get(level_key, moves)) + "\n按N进入下一关\n按R重新开始"
	win_label.visible = true

func next_level():
	if current_level < LEVELS.size() - 1:
		current_level += 1
		init_level()
	else:
		win_label.text = "恭喜！你已完成所有关卡！\n总步数: " + str(total_moves) + "\n按R重新开始第一关"

func prev_level():
	if current_level > 0:
		current_level -= 1
		init_level()

func update_ui():
	level_label.text = "关卡: " + str(current_level + 1) + "/" + str(LEVELS.size())
	moves_label.text = "步数: " + str(moves)
	if stats_label:
		stats_label.text = "已完成: " + str(levels_completed) + " | 总步数: " + str(total_moves)

func setup_virtual_controls():
	if not virtual_controls:
		return
	
	# 连接虚拟按键信号
	var up_btn = virtual_controls.get_node("UpButton")
	var down_btn = virtual_controls.get_node("DownButton")
	var left_btn = virtual_controls.get_node("LeftButton")
	var right_btn = virtual_controls.get_node("RightButton")
	var reset_btn = virtual_controls.get_node("ResetButton")
	
	if up_btn:
		up_btn.pressed.connect(_on_virtual_button_pressed.bind(Vector2(0, -1)))
	if down_btn:
		down_btn.pressed.connect(_on_virtual_button_pressed.bind(Vector2(0, 1)))
	if left_btn:
		left_btn.pressed.connect(_on_virtual_button_pressed.bind(Vector2(-1, 0)))
	if right_btn:
		right_btn.pressed.connect(_on_virtual_button_pressed.bind(Vector2(1, 0)))
	if reset_btn:
		reset_btn.pressed.connect(init_level)

func _on_virtual_button_pressed(direction: Vector2):
	if not level_completed:
		move_player(direction)

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
				if player_data.has("pushbox"):
					var game_data = player_data["pushbox"]
					current_level = game_data.get("current_level", 0)
					total_moves = game_data.get("total_moves", 0)
					levels_completed = game_data.get("levels_completed", 0)
					best_moves_per_level = game_data.get("best_moves_per_level", {})

func save_player_data():
	if not player_data.has("pushbox"):
		player_data["pushbox"] = {}
	
	player_data["pushbox"]["current_level"] = current_level
	player_data["pushbox"]["max_level_reached"] = max(current_level, player_data.get("pushbox", {}).get("max_level_reached", 0))
	player_data["pushbox"]["total_moves"] = total_moves
	player_data["pushbox"]["levels_completed"] = levels_completed
	player_data["pushbox"]["best_moves_per_level"] = best_moves_per_level
	
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
	gradient.add_point(0.0, Color(0.15, 0.25, 0.35, 0.9))
	gradient.add_point(1.0, Color(0.1, 0.15, 0.25, 0.95))
	draw_rect(Rect2(Vector2.ZERO, size), gradient.sample(0.5), true)
	
	# 获取游戏区域位置
	var area_pos = game_area.position
	
	# 绘制游戏区域阴影
	var shadow_offset = Vector2(6, 6)
	var area_rect = Rect2(area_pos + shadow_offset, game_area.size)
	draw_rect(area_rect, Color(0, 0, 0, 0.4), true)
	
	# 绘制游戏区域背景
	area_rect = Rect2(area_pos, game_area.size)
	draw_rect(area_rect, Color(0.8, 0.75, 0.7, 0.95), true)
	
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
			
			# 绘制单元格阴影
			draw_rect(rect.grow(1), Color(0, 0, 0, 0.2), true)
			
			# 根据类型绘制不同效果
			match cell_type:
				CellType.EMPTY:
					draw_rect(rect, Color(0.9, 0.85, 0.8, 0.7), true)
				CellType.WALL:
					# 绘制立体墙壁效果
					draw_rect(rect, Color(0.3, 0.3, 0.3), true)
					# 高光
					var highlight_rect = Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.3))
					draw_rect(highlight_rect, Color(0.5, 0.5, 0.5, 0.8), true)
				CellType.TARGET:
					# 绘制目标点（带光晕效果）
					draw_rect(rect, Color(0.6, 0.8, 1.0, 0.8), true)
					# 内圈
					var inner_rect = rect.grow(-8)
					draw_rect(inner_rect, Color(0.4, 0.6, 0.9, 0.9), true)
				CellType.BOX:
					# 绘制立体箱子
					draw_rect(rect, Color(0.7, 0.5, 0.3), true)
					# 高光
					var box_highlight = Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, rect.size.y * 0.3))
					draw_rect(box_highlight, Color(0.9, 0.7, 0.5, 0.8), true)
					# 边框
					draw_rect(rect, Color(0.5, 0.3, 0.1), false, 2)
				CellType.PLAYER:
					# 检查玩家下面是否有目标点
					var level_strings = LEVELS[current_level]
					if y < level_strings.size() and x < level_strings[y].length():
						var original_char = level_strings[y][x]
						if original_char == '*':  # 玩家在目标点上
							# 先绘制目标点
							draw_rect(rect, Color(0.6, 0.8, 1.0, 0.8), true)
							var inner_rect = rect.grow(-8)
							draw_rect(inner_rect, Color(0.4, 0.6, 0.9, 0.9), true)
						else:
							draw_rect(rect, Color(0.9, 0.85, 0.8, 0.7), true)
					else:
						draw_rect(rect, Color(0.9, 0.85, 0.8, 0.7), true)
					
					# 绘制玩家（圆形）
					var center = rect.get_center()
					var radius = min(rect.size.x, rect.size.y) * 0.3
					# 阴影
					draw_circle(center + Vector2(1, 1), radius, Color(0, 0, 0, 0.3))
					# 玩家主体
					draw_circle(center, radius, Color(0.2, 0.8, 0.2))
					# 高光
					draw_circle(center - Vector2(2, 2), radius * 0.5, Color(0.6, 1.0, 0.6, 0.7))
				CellType.BOX_ON_TARGET:
					# 绘制目标点背景
					draw_rect(rect, Color(0.6, 0.8, 1.0, 0.8), true)
					var inner_rect = rect.grow(-8)
					draw_rect(inner_rect, Color(0.4, 0.6, 0.9, 0.9), true)
					
					# 绘制完成的箱子（绿色）
					var box_rect = rect.grow(-4)
					draw_rect(box_rect, Color(0.2, 0.7, 0.2), true)
					# 高光
					var box_highlight = Rect2(box_rect.position + Vector2(2, 2), Vector2(box_rect.size.x - 4, box_rect.size.y * 0.3))
					draw_rect(box_highlight, Color(0.4, 0.9, 0.4, 0.8), true)
					# 边框
					draw_rect(box_rect, Color(0.1, 0.5, 0.1), false, 2)
			
			# 绘制网格线（淡色）
			draw_rect(rect, Color(0.6, 0.6, 0.6, 0.3), false, 1)

#手机端下一关
func _on_next_button_pressed() -> void:
	next_level()
	pass 

#手机端上一关
func _on_last_button_pressed() -> void:
	prev_level()
	pass 

#关闭推箱子游戏界面
func _on_quit_button_pressed() -> void:
	self.hide()
	get_parent().remove_child(self)
	queue_free()
	pass 

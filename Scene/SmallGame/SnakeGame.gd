extends Panel

# 游戏常量
const GRID_SIZE = 20
const GRID_WIDTH = 30
const GRID_HEIGHT = 30

# 方向枚举
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# 游戏变量
var snake_body = []
var snake_direction = Direction.RIGHT
var next_direction = Direction.RIGHT
var food_position = Vector2()
var score = 0
var game_over = false

# 节点引用
@onready var game_area = $GameArea
@onready var score_label = $ScoreLabel
@onready var game_over_label = $GameOverLabel
@onready var game_timer = $GameTimer

func _ready():
	# 连接定时器信号
	game_timer.timeout.connect(_on_game_timer_timeout)
	
	# 设置游戏区域样式
	game_area.modulate = Color(0.2, 0.2, 0.2, 1.0)
	
	# 初始化游戏
	init_game()

func init_game():
	# 重置游戏状态
	game_over = false
	score = 0
	snake_direction = Direction.RIGHT
	next_direction = Direction.RIGHT
	
	# 初始化蛇身
	snake_body.clear()
	snake_body.append(Vector2(5, 5))
	snake_body.append(Vector2(4, 5))
	snake_body.append(Vector2(3, 5))
	
	# 生成食物
	generate_food()
	
	# 更新UI
	update_score()
	game_over_label.visible = false
	
	# 启动定时器
	game_timer.start()

func _input(event):
	if event is InputEventKey and event.pressed:
		if game_over:
			if event.keycode == KEY_SPACE:
				init_game()
			return
		
		# 控制蛇的方向
		match event.keycode:
			KEY_UP, KEY_W:
				if snake_direction != Direction.DOWN:
					next_direction = Direction.UP
			KEY_DOWN, KEY_S:
				if snake_direction != Direction.UP:
					next_direction = Direction.DOWN
			KEY_LEFT, KEY_A:
				if snake_direction != Direction.RIGHT:
					next_direction = Direction.LEFT
			KEY_RIGHT, KEY_D:
				if snake_direction != Direction.LEFT:
					next_direction = Direction.RIGHT

func _on_game_timer_timeout():
	if game_over:
		return
	
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
		# 增加分数
		score += 10
		update_score()
		
		# 生成新食物
		generate_food()
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

func generate_food():
	var attempts = 0
	while attempts < 100:  # 防止无限循环
		food_position = Vector2(
			randi() % GRID_WIDTH,
			randi() % GRID_HEIGHT
		)
		
		# 确保食物不在蛇身上
		var food_on_snake = false
		for segment in snake_body:
			if segment == food_position:
				food_on_snake = true
				break
		
		if not food_on_snake:
			break
		
		attempts += 1

func update_score():
	score_label.text = "分数: " + str(score)

func show_game_over():
	game_timer.stop()
	game_over_label.visible = true

func _draw():
	if not game_area:
		return
	
	# 获取游戏区域的位置和大小
	var area_pos = game_area.position
	var area_size = game_area.size
	
	# 计算网格大小
	var cell_width = area_size.x / GRID_WIDTH
	var cell_height = area_size.y / GRID_HEIGHT
	
	# 绘制蛇身
	for i in range(snake_body.size()):
		var segment = snake_body[i]
		var rect = Rect2(
			area_pos.x + segment.x * cell_width,
			area_pos.y + segment.y * cell_height,
			cell_width - 1,
			cell_height - 1
		)
		
		# 头部用不同颜色
		var color = Color.GREEN if i == 0 else Color.LIME_GREEN
		draw_rect(rect, color)
	
	# 绘制食物
	var food_rect = Rect2(
		area_pos.x + food_position.x * cell_width,
		area_pos.y + food_position.y * cell_height,
		cell_width - 1,
		cell_height - 1
	)
	draw_rect(food_rect, Color.RED)

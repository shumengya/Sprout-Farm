extends Node

# 变量定义
@onready var grid_container = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item = $CropItem
@onready var crop_list = $CropList  # 作物选择的 ItemList

@onready var show_money = $GUI/money  # 显示当前剩余的钱
@onready var show_experience = $GUI/experience  # 显示当前玩家的经验
@onready var show_level = $GUI/level  # 显示当前玩家的等级
@onready var tip = $GUI/tip 	#显示保存相关


@onready var land_panel = $GUI/Land_Panel
@onready var dig_button = $GUI/Land_Panel/VBox/HBox/Dig_button
@onready var crop_grid_container = $ScrollContainer/Crop_GridContainer

@onready var green_bar = $Copy_Nodes/Green				#普通
@onready var white_blue_bar = $Copy_Nodes/White_Blue	#稀有
@onready var orange_bar = $Copy_Nodes/Orange			#优良
@onready var pink_bar = $Copy_Nodes/Pink				#史诗
@onready var black_blue_bar = $Copy_Nodes/Black_Blue	#传奇
@onready var red_bar = $Copy_Nodes/Red					#神圣

#----------------网络联机部分--------------------------
#用户登录账号，用QQ号代替
@onready var username_input = $GUI/LoginPanel/VBox/HBox/username_input
#用户登录密码
@onready var password_input = $GUI/LoginPanel/VBox/HBox2/password_input
#注册账号时二次确认密码
@onready var password_input_2 = $GUI/LoginPanel/VBox/HBox5/password_input2
#登录按钮
@onready var login_button = $GUI/LoginPanel/VBox/HBox4/login_button
#注册按钮
@onready var register_button = $GUI/LoginPanel/VBox/HBox4/register_button
#农场名称
@onready var farmname_input = $GUI/LoginPanel/VBox/HBox3/farmname_input
#登录注册面板
@onready var login_panel = $GUI/LoginPanel
#----------------网络联机部分--------------------------


@onready var http_request = $HTTPRequest

var money: int = 500  # 默认每个人初始为100元
var experience: float = 0.0  # 初始每个玩家的经验为0
var grow_speed: float = 1  # 作物生长速度
var level: int = 1  # 初始玩家等级为1
var farm_lots = []  # 用于保存每个地块的状态

var dig_index = 0
var dig_money = 1000
var climate_death_timer = 0

var blink_speed: float = 1  # 每秒闪烁的次数
var is_blink_on: bool = false  # 是否闪烁状态
var blink_counter: float = 0.0  # 计数器，用于控制闪烁


#农作物种类JSON
var can_planted_crop = {
	#玩家点击空地块时可以种植的作物
	#品质有 普通，优良，稀有，史诗，传奇,品质会影响作物的颜色 
	#耐候性：种植的过程中可能会死亡
	#等级：需要玩家达到相应等级才能种植
	#经验：收获时可以获得的经验,经验到达某一程度，玩家会升等级
	#基础作物
	# 基础作物
	"测试作物": {"花费": 1, "生长时间": 3, "收益": 9999, "品质": "普通", "描述": "测试作物", "耐候性": 10, "等级": 1, "经验": 999},  # 1分钟

	"小麦": {"花费": 120, "生长时间": 120, "收益": 100, "品质": "普通", "描述": "基础作物，品质较低，适合新手种植", "耐候性": 10, "等级": 1, "经验": 10},  # 1分钟
	"稻谷": {"花费": 100, "生长时间": 240, "收益": 120, "品质": "普通", "描述": "适合大规模种植的基础作物", "耐候性": 10, "等级": 1, "经验": 10},  # 2分钟
	"玉米": {"花费": 70, "生长时间": 600, "收益": 90, "品质": "普通", "描述": "营养丰富的优良作物，适合稍有经验的玩家", "耐候性": 15, "等级": 2, "经验": 15},  # 5分钟
	"土豆": {"花费": 75, "生长时间": 360, "收益": 90, "品质": "普通", "描述": "容易种植的耐寒作物", "耐候性": 12, "等级": 1, "经验": 10},  # 3分钟
	"胡萝卜": {"花费": 60, "生长时间": 480, "收益": 80, "品质": "普通", "描述": "适合新手的健康作物", "耐候性": 12, "等级": 1, "经验": 10},  # 4分钟
	# 中级作物
	"草莓": {"花费": 120, "生长时间": 960, "收益": 150, "品质": "优良", "描述": "营养丰富的果实，收益不错", "耐候性": 14, "等级": 2, "经验": 20},  # 8分钟
	"番茄": {"花费": 100, "生长时间": 720, "收益": 130, "品质": "优良", "描述": "常见作物，适合小规模种植", "耐候性": 12, "等级": 2, "经验": 15},  # 6分钟
	"大豆": {"花费": 90, "生长时间": 840, "收益": 110, "品质": "优良", "描述": "富含蛋白质的基础作物", "耐候性": 11, "等级": 2, "经验": 12},  # 7分钟
	# 高级作物
	"蓝莓": {"花费": 150, "生长时间": 1200, "收益": 200, "品质": "稀有", "描述": "较为稀有的作物，市场价值较高", "耐候性": 18, "等级": 3, "经验": 25},  # 10分钟
	"洋葱": {"花费": 85, "生长时间": 600, "收益": 105, "品质": "稀有", "描述": "烹饪常用的作物，适合中级种植", "耐候性": 10, "等级": 2, "经验": 10},  # 5分钟
	"南瓜": {"花费": 180, "生长时间": 1440, "收益": 250, "品质": "稀有", "描述": "秋季收获的高收益作物", "耐候性": 20, "等级": 4, "经验": 30},  # 12分钟
	"葡萄": {"花费": 200, "生长时间": 1200, "收益": 300, "品质": "稀有", "描述": "需要特殊管理的高收益作物", "耐候性": 15, "等级": 4, "经验": 35},  # 10分钟
	"柿子": {"花费": 160, "生长时间": 1080, "收益": 240, "品质": "稀有", "描述": "富含营养的秋季作物", "耐候性": 18, "等级": 3, "经验": 28},  # 9分钟
	"花椰菜": {"花费": 130, "生长时间": 960, "收益": 170, "品质": "稀有", "描述": "耐寒的高品质作物，适合经验丰富的玩家", "耐候性": 17, "等级": 3, "经验": 22},  # 8分钟
	"芦笋": {"花费": 200, "生长时间": 1560, "收益": 280, "品质": "稀有", "描述": "市场需求量高的稀有作物", "耐候性": 15, "等级": 4, "经验": 30},  # 13分钟
	# 史诗作物
	"香草": {"花费": 250, "生长时间": 1800, "收益": 400, "品质": "史诗", "描述": "非常稀有且收益极高的作物", "耐候性": 22, "等级": 5, "经验": 40},  # 15分钟
	"西瓜": {"花费": 240, "生长时间": 2400, "收益": 420, "品质": "史诗", "描述": "夏季丰产的高价值作物", "耐候性": 21, "等级": 5, "经验": 45},  # 20分钟
	"甜菜": {"花费": 220, "生长时间": 2160, "收益": 350, "品质": "史诗", "描述": "营养丰富的根茎作物，收益较高", "耐候性": 20, "等级": 5, "经验": 38},  # 18分钟
	"甘蔗": {"花费": 260, "生长时间": 3000, "收益": 450, "品质": "史诗", "描述": "需要充足水源的高价值作物", "耐候性": 18, "等级": 5, "经验": 50},  # 25分钟
	# 传奇作物
	"龙果": {"花费": 400, "生长时间": 4800, "收益": 600, "品质": "传奇", "描述": "极为稀有的热带作物，产量和价值都极高", "耐候性": 25, "等级": 6, "经验": 60},  # 40分钟
	"松露": {"花费": 500, "生长时间": 7200, "收益": 700, "品质": "传奇", "描述": "极其珍贵的地下作物，市场价格极高", "耐候性": 23, "等级": 7, "经验": 80},  # 60分钟
	"人参": {"花费": 450, "生长时间": 6600, "收益": 650, "品质": "传奇", "描述": "需要耐心等待的珍贵药材", "耐候性": 22, "等级": 6, "经验": 75},  # 55分钟
	"金橘": {"花费": 420, "生长时间": 4800, "收益": 620, "品质": "传奇", "描述": "少见的耐寒果树，市场需求量极大", "耐候性": 26, "等级": 7, "经验": 70}   # 40分钟
	};

var selected_lot_index = -1  # 当前被选择的地块索引
#电脑版本地游戏保存路径
var game_path = "C:/Users/shumengya/Desktop/smyfarm/"
var save_time = 10

# 使用 _process 计时器实现作物生长机制
var update_timer: float = 0.0
var update_interval: float = 1.0  
var start_game = false

var user_name = ""
var user_password = ""
var farmname = ""
var login_data = {}

var data = null

var buttons = []







##方法分类->Godot自带方法和自定义方法
#-------------Godot自带方法-----------------
# 准备阶段
func _ready():
	_update_ui()
	_init_crop_list2()
	Toast.show("快去偷其他人的菜吧！", Color.GREEN,5.0,1.0)
	# 初始化农场地块
	_init_farm_lots(40)
	_update_farm_lots()

	crop_grid_container.hide()

func _physics_process(delta):
	update_timer += delta

	if update_timer >= update_interval:
		update_timer = 0.0  # 重置计时器
		if start_game == true:
			_update_save_time()
			_update_farm_lots()
			pass

		
		for i in range(len(farm_lots)):
			var lot = farm_lots[i]
			if lot["is_planted"]:
				lot["grow_time"] += grow_speed * update_interval
				_update_blinking(lot)

func _on_dig_button_pressed():
	if money < dig_money:
		print("金钱不足，无法开垦" )
		Toast.show("金钱不足，无法开垦", Color.RED)
	else:
		money -= dig_money
		farm_lots[dig_index]["is_diged"] = true
		land_panel.hide()
	_update_ui()
	_update_farm_lots()
	pass 

# 添加按键触发保存和加载的功能
func _input(event):
	if event.is_action_pressed("ui_save"):  # 需要在输入设置中定义这个动作
		_save_game()
	elif event.is_action_pressed("ui_load"):  # 需要在输入设置中定义这个动作
		_load_game()
	
#这里处理登录逻辑，如果用户没有账号，直接注册一个新的
func _on_login_button_pressed():

	user_name = username_input.text.strip_edges()  # 修剪前后的空格
	user_password = password_input.text.strip_edges()
	farmname = farmname_input.text.strip_edges()
	
	login_data = {
		"user_name": user_name,
		"user_password": user_password
	}

	if user_name == "" or user_password == "":
		print("用户名或密码不能为空！")
		return  
	
	send_request("login", HTTPClient.METHOD_POST, login_data)

func _on_register_button_pressed():
	user_name = username_input.text.strip_edges()  
	user_password = password_input.text.strip_edges()
	
	var user_password_2 = password_input_2.text.strip_edges()
	farmname = farmname_input.text.strip_edges()
	#压缩后成一坨大便了
	var	init_player_data = {"experience":0,"farm_lots":[{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":3},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":3},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":3},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":3},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":3},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":false,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":5},{"crop_type":"","grow_time":0,"is_dead":false,"is_diged":true,"is_planted":false,"max_grow_time":5}],"farm_name":farmname,"level":0,"money":1000,"user_name":user_name,"user_password":user_password}

	if user_name == "" or user_password == "":
		print("用户名或密码不能为空！")
		return  
	if farmname == "":
		print("农场名称不能为空！")
		return 
	if user_password != user_password_2:
		print("前后密码不相同！")
		return 
		
	if is_valid_qq_number(user_name) == false:
		return
		
	send_request("register", HTTPClient.METHOD_POST, init_player_data)
	pass 

#-------------Godot自带方法-----------------



#-------------自定义方法-----------------
# 保存玩家数据到node.js后端
func save_game_to_server():
	var player_data = {
		"user_name":user_name,
		"user_password":user_password,
		"farm_name":farmname,
		"money": money,
		"experience": experience,
		"level": level,
		"farm_lots": farm_lots
		}
		
	send_request("save", HTTPClient.METHOD_POST, player_data)
	pass

# 加载玩家数据从node.js后端
func load_game_from_server():
	send_request("login", HTTPClient.METHOD_POST, login_data)
	pass

#更新保存玩家数据的时间倒计时
func _update_save_time():
	tip.text = "游戏自动保存剩余【"+str(save_time)+"】秒"
	save_time -= 1
	if save_time < 0:
		_save_game()
		save_time = 10
		pass
	pass

func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = null
	match crop_quality:
		"普通":
			button = green_bar.duplicate()
		"优良":
			button = white_blue_bar.duplicate()
		"稀有":
			button = orange_bar.duplicate()
		"史诗":
			button = pink_bar.duplicate()
		"传奇":
			button = black_blue_bar.duplicate()

	# 添加按钮事件
	button.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
	button.text = str(crop_name)
	return button

#地块闪烁代码-已废弃
func _update_blinking(lot: Dictionary):
	if lot["grow_time"] >= lot["max_grow_time"]:
		lot["grow_time"] = lot["max_grow_time"]
		blink_counter += blink_speed * update_interval
		is_blink_on = int(blink_counter) % 2 == 0
	else:
		is_blink_on = false
		blink_counter = 0.0

# 写入 TXT 文件	
func write_txt_file(file_path: String, text: String, append: bool = false) -> void:
	var file
	if append == true:
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)  # 追加模式
		if file:
			file.seek_end()  # 移动光标到文件末尾
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)  # 覆盖模式
	if file:
		file.store_string(text)
		file.close()
		Toast.show("游戏已保存！", Color.GREEN)
	else:
		print("写入文件时打开失败: ", file_path)
		Toast.show("写入文件时打开失败！", Color.RED)
		
# 读取 TXT 文件
func read_txt_file(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		return text
	else:
		print("打开文件失败: ", file_path)
		return "false"
		
#生成随机数-用于作物随机死亡
func random_probability(probability: float) -> bool:
	# 确保传入的概率值在 0 到 1 之间
	if probability*0.001 < 0.0 or probability*0.001 > 1.0:
		print("概率值必须在 0 和 1 之间")
		return false
	
	# 生成一个 0 到 1 之间的随机数
	var random_value = randf()
	
	# 如果随机数小于等于概率值，则返回 true
	return random_value <= (probability*0.001)

# 保存游戏数据
func _save_game():
	## 创建一个字典来保存游戏状态
	#var save_data = {
		#"user_name":username_input.text,
		#"user_password":password_input.text,
		#"farm_name":farmname_input.text,
		#"money": money,
		#"experience": experience,
		#"level": level,
		#"farm_lots": farm_lots
		#}
	#write_txt_file(game_path+username_input.text+".txt", str(save_data), false)
	## 将字典写入文件
	save_game_to_server()

# 加载游戏数据
func _load_game():
	
	## 从本地读取字典
	#var save_data = JSON.parse_string(read_txt_file(game_path+username_input.text+".txt"))
	#money = save_data["money"]
	#experience = save_data["experience"]
	#level = save_data["level"]
	#farm_lots = save_data["farm_lots"]

	load_game_from_server()

	Toast.show("游戏已加载！", Color.GREEN)
	_update_ui()
	_update_farm_lots()
	_init_crop_list2()

# 初始化农场地块
func _init_farm_lots(num_lots):
	for i in range(num_lots):
		farm_lots.append({
			"is_diged": false,		# 是否开垦	
			"is_planted": false,    # 是否种植
			"is_dead": false,    	# 是否作物已死亡
			"crop_type": "",        # 作物类型
			"grow_time": 0,         # 生长时间
			"max_grow_time": 5      # 作物需要的最大生长时间（假设5秒成熟）

		})

# 初始化作物选择列表
func _init_crop_list2():
	# 清空已有的作物按钮
	for child in crop_grid_container.get_children():
		child.queue_free()
	
	# 遍历可种植的作物
	for crop_name in can_planted_crop:
		var crop = can_planted_crop[crop_name]
		
		# 只显示当前等级可以种植的作物
		if crop["等级"] <= level:
			var level_btn = _create_crop_button(crop_name, crop["品质"])
			crop_grid_container.add_child(level_btn)

# 更新农场地块状态到 GridContainer
func _update_farm_lots():  # 每一秒更新一次状态
	# 清空当前显示的地块
	for child in grid_container.get_children():
		child.queue_free()

	var digged_count = 0  # 统计已开垦地块的数量

	for i in range(len(farm_lots)):
		var lot = farm_lots[i]
		var button = crop_item.duplicate()
		var label = button.get_node("Label")
		var progressbar = button.get_node("ProgressBar")

		if lot["is_diged"]:
			digged_count += 1  # 增加已开垦地块计数
			if lot["is_planted"]:
				# 寒冷环境配置，作物随机概率死亡
				climate_death_timer += 1
				if climate_death_timer >= 60:
					if random_probability(can_planted_crop[lot["crop_type"]]["耐候性"]):
						lot["is_dead"] = true
					climate_death_timer = 0

				# 如果作物已死亡
				if lot["is_dead"]:
					print("[" + farm_lots[i]["crop_type"] + "]" + "已死亡！")
					label.modulate = Color.NAVY_BLUE
					label.text = "[" + farm_lots[i]["crop_type"] + "已死亡" + "]"
				else:
					# 正常生长逻辑
					var crop_name = lot["crop_type"]
					label.text = "[" + can_planted_crop[crop_name]["品质"] + "-" + lot["crop_type"] + "]"
					# 根据品质显示颜色
					match can_planted_crop[crop_name]["品质"]:
						"普通":
							label.modulate = Color.GAINSBORO
						"优良":
							label.modulate = Color.DODGER_BLUE
						"稀有":
							label.modulate = Color.PURPLE
						"史诗":
							label.modulate = Color.YELLOW
						"传奇":
							label.modulate = Color.ORANGE_RED

					progressbar.show()
					progressbar.max_value = int(lot["max_grow_time"])
					progressbar.set_target_value(int(lot["grow_time"]))
			else:
				# 已开垦但未种植的地块显示为空地
				label.modulate = Color.GREEN
				label.text = "[" + "空地" + "]"
				progressbar.hide()
		else:
			# 未开垦的地块
			label.modulate = Color.WEB_GRAY
			label.text = "[" + "未开垦" + "]"
			progressbar.hide()

		# 连接按钮点击事件
		button.connect("pressed", Callable(self, "_on_item_selected").bind(i))
		grid_container.add_child(button)

	# 根据已开垦地块数量更新 dig_money
	dig_money = digged_count * 1000
	dig_button.text = "开垦" + "[" + str(dig_money) + "]"


# 更新玩家信息显示
func _update_ui():
	show_money.text = "当前金钱：" + str(money) + " 元"
	show_money.modulate = Color.ORANGE
	show_experience.text = "当前经验：" + str(experience) + " 点"
	show_experience.modulate = Color.GREEN
	show_level.text = "当前等级：" + str(level) + " 级"
	show_level.modulate = Color.DODGER_BLUE

# 处理地块点击事件
func _on_item_selected(index):
	var lot = farm_lots[index]
	if lot["is_diged"]:
		if lot["is_planted"]:
			if lot["is_dead"]:
				print(lot["crop_type"]+"已被铲除")
				root_out_crop(index)
				pass
			else:
				_harvest_crop(index)
				pass
			pass
		else:
			# 记录选中的地块索引，显示作物选择列表
			selected_lot_index = index
			double_click_close(crop_grid_container)
			pass		
		pass
	else :
		double_click_close(land_panel)
		dig_index = index
		pass

#双击切换UI事件-比如按一下打开再按一下关闭
func double_click_close(node):
	if node.visible == false:
		node.show()
		pass
	else :
		node.hide()
		pass
	pass

# 处理作物选择事件
func _on_crop_selected(crop_index):
	print(crop_index)
	#var crop_name = crop_list.get_item_text(crop_index).split(" (")[0]
	var crop_name = crop_index
	
	if selected_lot_index != -1:
		_plant_crop(selected_lot_index, crop_name)
		selected_lot_index = -1
		
		#crop_list.hide()  # 种植完成后隐藏作物选择列表
		crop_grid_container.hide()

# 种植作物
func _plant_crop(index, crop_name):
	var crop = can_planted_crop[crop_name]
	if money < crop["花费"]:
		print("金钱不足，无法种植 " + crop_name)
		Toast.show("金钱不足，无法种植 " + crop_name, Color.RED)
		return

	money -= crop["花费"]
	farm_lots[index]["is_planted"] = true
	farm_lots[index]["crop_type"] = crop_name
	farm_lots[index]["grow_time"] = 0
	farm_lots[index]["max_grow_time"] = crop["生长时间"]

	print("在地块[[" + str(index) + "]种植了[" + crop_name + "]")
	Toast.show("在地块[[" + str(index) + "]种植了[" + crop_name + "]", Color.GREEN)
	Toast.show(
	"名称:"+crop_name+"\n"+
	"花费:"+str(crop["花费"])+"\n"+
	"成熟时间:"+str(crop["生长时间"])+"\n"+
	"收益:"+str(crop["收益"])+"\n"+
	"品质:"+str(crop["品质"])+"\n"+
	"描述:"+str(crop["描述"])+"\n"+
	"耐候性:"+str(crop["耐候性"])+"\n"+
	"种植等级:"+str(crop["等级"])+"\n"+
	"获得经验:"+str(crop["经验"])+"\n"
	, Color.ORANGE)

	_update_ui()
	_update_farm_lots()

# 收获作物
func _harvest_crop(index):
	var lot = farm_lots[index]
	if lot["grow_time"] >= lot["max_grow_time"]:
		var crop = can_planted_crop[lot["crop_type"]]
		money += crop["收益"]+crop["花费"]
		experience += crop["经验"]
		Toast.show("从地块[" + str(index) + "]收获了[" + lot["crop_type"] + "]作物", Color.YELLOW)
		print("从地块[" + str(index) + "]收获了[" + lot["crop_type"] + "]作物")

		lot["is_planted"] = false
		lot["crop_type"] = ""
		lot["grow_time"] = 0

		_check_level_up()
		_update_ui()
		_update_farm_lots()
	else:
		print("作物还未成熟")
		Toast.show("作物还未成熟", Color.RED)

#铲除作物-好像还未实现这个功能
func root_out_crop(index):
	var lot = farm_lots[index]
	lot["is_planted"] = false
	lot["grow_time"] = 0
	Toast.show("从地块[" + str(index) + "]铲除了[" + lot["crop_type"] + "]作物", Color.YELLOW)
	lot["crop_type"] = ""
	_check_level_up()
	_update_ui()
	_update_farm_lots()
	pass

# 检查玩家是否可以升级
func _check_level_up():
	var level_up_experience = 100 * level
	if experience >= level_up_experience:
		level += 1
		experience -= level_up_experience
		print("恭喜！你升到了等级 ", level)
		Toast.show("恭喜！你升到了" + str(level) + "级 ", Color.SKY_BLUE)
		_init_crop_list2()

#-------------http传输的两个关键方法-----------------
func send_request(endpoint: String, method: int, data: Dictionary = {}):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed)

	var json_body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var error = http_request.request("http://localhost:3000/" + endpoint, headers, method, json_body)
	if error != OK:
		push_error("请求失败: %s" % str(error))
	else:
		#print("请求已发送: ", endpoint, json_body)
		pass
func _on_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	#print("返回 code: %d" % response_code)
	#print("返回 body: %s" % response_text)
	
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result == OK:
		var parsed_data = json.get_data()
		data = parsed_data  # 将解析后的数据赋值给 data
		#print("解析成功: ", data)
		
		if data["message"] == "登录成功":
			print("登录成功")
			if data.has("data"):
				var user_data = data["data"]
				#print("用户数据: ", user_data)
				experience = user_data.get("experience", 0)
				farm_lots = user_data.get("farm_lots", [])
				level = user_data.get("level", 1)
				money = user_data.get("money", 0)
				farmname_input.text = user_data.get("farm_name", 0)
				start_game = true
				login_panel.hide()
				# 确保在更新数据后调用 UI 更新函数
				_update_ui()
				_update_farm_lots()
				
				
		elif data["message"] == "密码错误":
			printerr("密码错误")
			pass
		elif data["message"] == "服务器错误":
			if data.has("error"):
				printerr("服务器错误"+str(data["error"]))
			pass
		elif data["message"] == "用户不存在":
			printerr("用户不存在")
		elif data["message"] == "注册成功":
			print("注册成功")
			{"user_name": user_name,"user_password": user_password}
			send_request("login", HTTPClient.METHOD_POST, {"user_name": user_name,"user_password": user_password})
		elif data["message"] == "用户名已存在":
			printerr("用户名已存在")
			


	else:
		print("JSON 解析错误: ", json.get_error_message())
#-------------http传输的两个关键方法-----------------

#是否为有效QQ号
func is_valid_qq_number(qq_number: String) -> bool:
	# QQ号的标准格式是5到12位的数字
	var qq_regex = RegEx.new()
	var pattern = r"^\d{5,12}$"
	
	var error = qq_regex.compile(pattern)
	if error != OK:
		print("格式错误，请输入正确的QQ号码！")
		return false

	return qq_regex.search(qq_number) != null

#-------------自定义方法-----------------

extends Node

# 变量定义
@onready var grid_container = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item = $CropItem
@onready var crop_list = $CropList  # 作物选择的 ItemList
@onready var show_money = $money  # 显示当前剩余的钱
@onready var show_experience = $experience  # 显示当前玩家的经验
@onready var show_level = $level  # 显示当前玩家的等级
@onready var toast = $ToastShow
@onready var toast2 = $ToastShow2
@onready var land_panel = $Land_Panel
@onready var dig_button = $Land_Panel/VBox/HBox/Dig_button
@onready var crop_grid_container = $ScrollContainer/Crop_GridContainer

@onready var green_bar = $Copy_Nodes/Green				#普通
@onready var white_blue_bar = $Copy_Nodes/White_Blue	#稀有
@onready var orange_bar = $Copy_Nodes/Orange			#优良
@onready var pink_bar = $Copy_Nodes/Pink				#史诗
@onready var black_blue_bar = $Copy_Nodes/Black_Blue	#传奇
@onready var red_bar = $Copy_Nodes/Red					#神圣

#----------------网络联机部分--------------------------
#用户登录账号，用QQ号代替
@onready var username_input = $LoginPanel/username_input
#用户登录密码
@onready var password_input = $LoginPanel/password_input
#登录按钮
@onready var login_button = $LoginPanel/login_button
#----------------网络联机部分--------------------------
@onready var tip = $tip

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
#电脑版路径（Windows或者Linux）
#var game_path = "C:/Users/shumengya/Desktop/smyfarm/save.txt"
#
var game_path = "/storage/emulated/0/萌芽农场/保存.txt"

var save_time = 10
var farm_thread: Thread
# 准备阶段
func _ready():
	
	farm_thread = Thread.new()
	# 使用 Callable 创建可调用对象，指向当前对象的 _thread_update_farm_lots 方法
	var callable = Callable(self, "_thread_update_farm_lots")
	# 启动线程
	var error = farm_thread.start(callable)
	if error != OK:
		print("Failed to start thread: ", error)
	
	OS.request_permissions()
	toast.Toast("快去偷其他人的菜吧！", Color.GREEN)
	# 初始化农场地块
	_init_farm_lots(40)
	_update_farm_lots()

	

	# 连接点击事件
	#crop_list.connect("item_selected", Callable(self, "_on_crop_selected"))
	# 初始隐藏作物选择列表
	#crop_list.hide()
	crop_grid_container.hide()

	# 更新初始显示
	_update_ui()

	# 初始化作物选择列表
	_init_crop_list2()
	
	_load_game()

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
# 初始化作物选择列表
func _init_crop_list():
	crop_list.clear()
	for crop_name in can_planted_crop:
		var crop = can_planted_crop[crop_name]
		if crop["等级"] <= level:  # 只显示当前等级可以种植的作物
			
			# 添加作物项
			crop_list.add_item(crop_name)

			# 随机生成颜色
			#var random_color = Color(randf(), randf(), randf())
			# 设置作物项的自定义背景颜色
			var item_index = crop_list.get_item_count() - 1  # 获取当前项的索引
			#crop_list.set_item_custom_bg_color(item_index, random_color)
			
			if crop["品质"] == "普通":
				crop_list.set_item_custom_bg_color(item_index, Color.GAINSBORO)
				pass
			elif crop["品质"] == "优良":
				crop_list.set_item_custom_bg_color(item_index, Color.DODGER_BLUE)
				pass
			elif crop["品质"] == "稀有":
				crop_list.set_item_custom_bg_color(item_index,Color.PURPLE )
				pass
			elif crop["品质"] == "史诗":
				crop_list.set_item_custom_bg_color(item_index,Color.YELLOW )
				pass
			elif crop["品质"] == "传奇":
				crop_list.set_item_custom_bg_color(item_index, Color.ORANGE_RED)
				pass
			
			# 如果需要设置文本颜色，可以使用下面的代码（可选）
			# crop_list.set_item_custom_color(item_index, Color.WHITE)  # 设置文本颜色


# 初始化作物选择列表
func _init_crop_list2():
	for child in crop_grid_container.get_children():
		child.queue_free()
	for crop_name in can_planted_crop:
		var crop = can_planted_crop[crop_name]

		var level_btn = null

		var level6_btn = red_bar.duplicate()
		
		if crop["等级"] <= level:  # 只显示当前等级可以种植的作物
			

			if crop["品质"] == "普通":
				level_btn = green_bar.duplicate()
				level_btn.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
				level_btn.text = str(crop_name)
				crop_grid_container.add_child(level_btn)
				pass
			elif crop["品质"] == "优良":
				level_btn = white_blue_bar.duplicate()
				level_btn.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
				level_btn.text = str(crop_name)
				crop_grid_container.add_child(level_btn)
				pass
			elif crop["品质"] == "稀有":
				level_btn = orange_bar.duplicate()
				level_btn.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
				level_btn.text = str(crop_name)
				crop_grid_container.add_child(level_btn)
				pass
			elif crop["品质"] == "史诗":
				level_btn = pink_bar.duplicate()
				level_btn.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
				level_btn.text = str(crop_name)
				crop_grid_container.add_child(level_btn)
				pass
			elif crop["品质"] == "传奇":
				level_btn = black_blue_bar.duplicate()
				level_btn.connect("pressed", Callable(self, "_on_crop_selected").bind(crop_name))
				level_btn.text = str(crop_name)
				crop_grid_container.add_child(level_btn)
				pass
			
			# 如果需要设置文本颜色，可以使用下面的代码（可选）
			# crop_list.set_item_custom_color(item_index, Color.WHITE)  # 设置文本颜色


	pass


# 更新农场地块状态到 GridContainer
func _update_farm_lots(): #每一秒更新一次状态
	for child in grid_container.get_children():
		child.queue_free()

	for j in 5:
		if farm_lots[j]["is_diged"] == false:
			farm_lots[j]["is_diged"] = true
			pass
		pass

	for i in range(len(farm_lots)):
		
		var lot = farm_lots[i]
		var button = crop_item.duplicate()
		var label = button.get_node("Label")
		var progressbar = button.get_node("ProgressBar")
		pass
		
		
		
		if lot["is_diged"] == true:
			dig_money = (i+1) * 1000
			dig_button.text = "开垦"+"["+str(dig_money)+"]"
			if lot["is_planted"] == true:
				
				#寒冷环境配置，作物随机概率死亡
				climate_death_timer += 1
				if climate_death_timer >= 60 :
					if random_probability(can_planted_crop[lot["crop_type"]]["耐候性"]):
						lot["is_dead"] = true
						pass
					climate_death_timer = 0

					pass

				#如果作物已死亡！
				if lot["is_dead"] == true:
					print("["+farm_lots[i]["crop_type"]+"]"+"已死亡！")
					label.modulate = Color.NAVY_BLUE
					label.text = "["+farm_lots[i]["crop_type"]+"已死亡"+"]"

					pass
				#否者作物正常生长
				else: 
					#label.text = lot["crop_type"] + " (" + str(int(lot["grow_time"])) + "/" + str(int(lot["max_grow_time"])) + ")"
					var crop_name = lot["crop_type"]
					label.text = "["+can_planted_crop[crop_name]["品质"]+"-"+lot["crop_type"]+"]" 

					#根据品质显示颜色
					if(can_planted_crop[crop_name]["品质"]=="普通"):
						label.modulate = Color.GAINSBORO
						pass
					elif (can_planted_crop[crop_name]["品质"]=="优良"):
						label.modulate = Color.DODGER_BLUE
						pass
					elif (can_planted_crop[crop_name]["品质"]=="稀有"):
						label.modulate = Color.PURPLE
						pass
					elif (can_planted_crop[crop_name]["品质"]=="史诗"):
						label.modulate = Color.YELLOW
						pass
					elif (can_planted_crop[crop_name]["品质"]=="传奇"):
						label.modulate = Color.ORANGE_RED
						pass
				
					progressbar.show()
					progressbar.max_value = int(lot["max_grow_time"])
					progressbar.set_target_value( int(lot["grow_time"]) )
					#if is_blink_on:
						#label.modulate = Color.YELLOW
					#else:
						#label.modulate = Color.ORANGE
					pass
				pass
				

			else:
				#土地开垦后没有作物则显示为空地
				label.modulate =Color.GREEN
				label.text = "["+"空地"+"]"
				progressbar.hide()
				#label.modulate = Color.WHITE
				pass
			pass
		else :
			#土地没有开垦则显示未开垦
			label.modulate =Color.WEB_GRAY
			label.text = "["+"未开垦"+"]"
			progressbar.hide()
			#label.modulate = Color.WHITE
			pass
		
		# 设置最小尺寸
		#button.custom_minimum_size = Vector2(100, 100)
		


		button.connect("pressed", Callable(self, "_on_item_selected").bind(i))
		grid_container.add_child(button)

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
				#label.modulate = Color.NAVY_BLUE
				#label.text = "["+lot["crop_type"]+"已死亡"+"]"
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
		toast.Toast("金钱不足，无法种植 " + crop_name, Color.RED)
		return

	money -= crop["花费"]
	farm_lots[index]["is_planted"] = true
	farm_lots[index]["crop_type"] = crop_name
	farm_lots[index]["grow_time"] = 0
	farm_lots[index]["max_grow_time"] = crop["生长时间"]

	print("在地块[[" + str(index) + "]种植了[" + crop_name + "]")
	toast.Toast("在地块[[" + str(index) + "]种植了[" + crop_name + "]", Color.GREEN)
	toast2.Toast(
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

#OS

# 收获作物
func _harvest_crop(index):
	var lot = farm_lots[index]
	if lot["grow_time"] >= lot["max_grow_time"]:
		var crop = can_planted_crop[lot["crop_type"]]
		money += crop["收益"]+crop["花费"]
		experience += crop["经验"]
		toast.Toast("从地块[" + str(index) + "]收获了[" + lot["crop_type"] + "]作物", Color.YELLOW)
		print("从地块[" + str(index) + "]收获了[" + lot["crop_type"] + "]作物")

		lot["is_planted"] = false
		lot["crop_type"] = ""
		lot["grow_time"] = 0

		_check_level_up()
		_update_ui()
		_update_farm_lots()
	else:
		print("作物还未成熟")
		toast.Toast("作物还未成熟", Color.RED)
		
func root_out_crop(index):
	var lot = farm_lots[index]
	lot["is_planted"] = false
	lot["grow_time"] = 0
	toast.Toast("从地块[" + str(index) + "]铲除了[" + lot["crop_type"] + "]作物", Color.YELLOW)
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
		toast.Toast("恭喜！你升到了" + str(level) + "级 ", Color.SKY_BLUE)
		_init_crop_list2()

# 使用 _process 实现作物生长机制
var update_timer: float = 0.0
var update_interval: float = 0.5

func _physics_process(delta):
	update_timer += delta
	
	#当作物成熟后（一个一秒钟计时器）
	if update_timer >= update_interval:
		tip.text = "游戏自动保存剩余【"+str(save_time)+"】秒"
		save_time -= 1
		if save_time < 0:
			_save_game()
			save_time = 10
			pass
		
		for i in range(len(farm_lots)):
			var lot = farm_lots[i]
			if lot["is_planted"]:
				lot["grow_time"] += grow_speed * update_interval
				if lot["grow_time"] >= lot["max_grow_time"]:
					lot["grow_time"] = lot["max_grow_time"]
					
					blink_counter += blink_speed * update_interval
					is_blink_on = int(blink_counter) % 2 == 0
				else:
					is_blink_on = false
					blink_counter = 0.0

		#_update_farm_lots()  # 更新地块信息
		update_timer = 0.0  # 重置计时器


func _on_dig_button_pressed():
	if money < dig_money:
		print("金钱不足，无法开垦" )
		toast.Toast("金钱不足，无法开垦", Color.RED)
	else:
		money -= dig_money
		farm_lots[dig_index]["is_diged"] = true
		land_panel.hide()
	_update_ui()
	_update_farm_lots()
	pass 



# 保存游戏数据
func _save_game():
	# 创建一个字典来保存游戏状态
	var save_data = {
		"money": money,
		"experience": experience,
		"level": level,
		"farm_lots": farm_lots
		}
	write_txt_file(game_path, str(save_data), false)
	# 将字典写入文件


# 加载游戏数据
func _load_game():
	pass
		## 读取字典
		#var save_data = JSON.parse_string(read_txt_file(game_path))
		##print(read_json_file("C:/Users/shumengya/Desktop/smyfarm/save.txt"))
		#
		#money = save_data["money"]
		#experience = save_data["experience"]
		#level = save_data["level"]
		#farm_lots = save_data["farm_lots"]
		##file.close()
		#toast.Toast("游戏已加载！", Color.GREEN)
		#_update_ui()
		#_update_farm_lots()
		#_init_crop_list2()

# 添加按键触发保存和加载的功能
func _input(event):
	if event.is_action_pressed("ui_save"):  # 需要在输入设置中定义这个动作
		_save_game()
	elif event.is_action_pressed("ui_load"):  # 需要在输入设置中定义这个动作
		_load_game()
	
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
		toast.Toast("游戏已保存！", Color.GREEN)
	else:
		print("写入文件时打开失败: ", file_path)
		toast.Toast("写入文件时打开失败！", Color.RED)
		
# 读取 TXT 文件
func read_txt_file(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		return text
	else:
		print("打开文件失败: ", file_path)
		return ""
		

func random_probability(probability: float) -> bool:
	# 确保传入的概率值在 0 到 1 之间
	if probability*0.001 < 0.0 or probability*0.001 > 1.0:
		print("概率值必须在 0 和 1 之间")
		return false
	
	# 生成一个 0 到 1 之间的随机数
	var random_value = randf()
	
	# 如果随机数小于等于概率值，则返回 true
	return random_value <= (probability*0.001)


#这里处理登录逻辑，如果用户没有账号，直接注册一个新的json文件
func _on_login_button_pressed():
	var user_name = username_input.text
	var user_password = password_input.text
	if(username_input == " " or password_input == " "):
		print("用户名或密码不能为空！")
		pass
	else :
		#这里处理登录逻辑
		pass
	pass


# 在线程中执行的函数
func _thread_update_farm_lots(data):
	while true:
		_update_farm_lots()  # 更新地块信息
		

 
		# 控制更新频率
		OS.delay_msec(1000)

extends Node

# 变量定义
@onready var grid_container : GridContainer = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item : Button = $CopyNodes/CropItem


@onready var show_money : Label =   $UI/GUI/HBox/money				# 显示当前剩余的钱
@onready var show_experience : Label = $UI/GUI/HBox/experience  	# 显示当前玩家的经验
@onready var show_level : Label =   $UI/GUI/HBox/level				# 显示当前玩家的等级
@onready var show_tip : Label =  $UI/GUI/HBox/tip					# 显示小提示
@onready var show_player_name : Label =  $UI/GUI/HBox2/player_name	# 显示玩家昵称
@onready var show_farm_name : Label = $UI/GUI/HBox2/farm_name		# 显示农场名称
@onready var show_status_label : Label = $UI/GUI/HBox2/StatusLabel	# 显示与服务器连接状态
@onready var network_status_label :Label = get_node("/root/main/UI/TCPNetworkManager/StatusLabel")
@onready var return_my_farm_button: Button = $UI/GUI/VBox/ReturnMyFarmButton


@onready var crop_grid_container : GridContainer = $UI/CropStorePanel/ScrollContainer/Crop_Grid #种子商店格子
@onready var player_bag_grid_container : GridContainer = $UI/PlayerBagPanel/ScrollContainer/Bag_Grid #玩家背包格子

#作物品质按钮
@onready var green_bar : Button = $CopyNodes/GreenCrop				#普通
@onready var white_blue_bar : Button = $CopyNodes/WhiteBlueCrop		#稀有
@onready var orange_bar : Button = $CopyNodes/OrangeCrop			#优良
@onready var pink_bar : Button = $CopyNodes/PinkCrop				#史诗
@onready var black_blue_bar : Button = $CopyNodes/BlackBlueCrop		#传奇
@onready var red_bar : Button = $CopyNodes/RedCrop					#神圣

#各种面板
@onready var land_panel : Panel = $UI/LandPanel#地块面板
@onready var login_panel : PanelContainer = $UI/LoginPanel#登录注册面板
@onready var crop_store_panel : Panel = $UI/CropStorePanel#种子商店面板
@onready var player_bag_panel : Panel = $UI/PlayerBagPanel#玩家背包面板
@onready var network_manager : Panel = $UI/TCPNetworkManager#网络管理器
@onready var player_ranking_panel : Panel = $UI/PlayerRankingPanel#玩家排行榜面板



var money: int = 500  # 默认每个人初始为100元
var experience: float = 0.0  # 初始每个玩家的经验为0
var grow_speed: float = 1  # 作物生长速度
var level: int = 1  # 初始玩家等级为1
var dig_money : int = 1000 #开垦费用


#临时变量
var user_name : String = ""
var user_password : String = ""
var login_data : Dictionary = {}
var data : Dictionary = {}
var buttons : Array = []
# 使用 _process 计时器实现作物生长机制
var update_timer: float = 0.0
var update_interval: float = 1.0  
var start_game : bool = false
# 玩家背包数据
var player_bag : Array = []  
#农作物种类JSON
var can_planted_crop : Dictionary = {}
# 当前被选择的地块索引
var selected_lot_index : int = -1  
var farm_lots : Array = []  # 用于保存每个地块的状态
var dig_index : int = 0
var climate_death_timer : int = 0

# 访问模式相关变量
var is_visiting_mode : bool = false  # 是否处于访问模式
var original_player_data : Dictionary = {}  # 保存原始玩家数据
var visited_player_data : Dictionary = {}  # 被访问玩家的数据

# 作物图片缓存
var crop_textures_cache : Dictionary = {}  # 缓存已加载的作物图片
var crop_frame_counts : Dictionary = {}  # 记录每种作物的帧数

const client_version :String = "1.0.1" #记录客户端版本



# 准备阶段
func _ready():
	print("萌芽农场客户端 v" + client_version + " 启动")
	_update_ui()
	_create_farm_buttons() # 创建地块按钮
	_update_farm_lots_state() # 初始更新地块状态
	
	# 预加载默认作物图片
	_preload_common_crop_textures()
	
	# 先尝试加载本地数据进行快速初始化
	_load_local_crop_data()
	
	# 初始化玩家背包UI
	player_bag_panel.init_player_bag()
	# 初始化商店
	crop_store_panel.init_store()
	
	# 隐藏面板
	crop_store_panel.hide()
	player_bag_panel.hide()
	
	# 启动后稍等片刻尝试从服务器获取最新数据
	await get_tree().create_timer(0.5).timeout
	_try_load_from_server()

#每时每刻都更新
func _physics_process(delta):
	#1秒计时器
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0  # 重置计时器
		
		#同步网络管理器的状态
		show_status_label.text = "服务器状态："+network_status_label.text
		show_status_label.modulate = network_status_label.modulate
		
		if start_game == true:
			_update_farm_lots_state() # 更新地块状态，不重新创建UI
			
			#访客模式处理
			if is_visiting_mode:
				return_my_farm_button.show()
				pass
			else:
				return_my_farm_button.hide()
				pass
			pass

func _on_open_store_button_pressed():
	# 如果处于访问模式，不允许打开商店
	if is_visiting_mode:
		Toast.show("访问模式下无法使用商店", Color.ORANGE)
		return
	
	# 确保商店面板已初始化
	crop_store_panel.init_store()
	# 显示商店面板
	crop_store_panel.show()
	# 确保在最前面显示
	crop_store_panel.move_to_front() 
	pass

func _on_player_ranking_button_pressed() -> void:
	player_ranking_panel.show()
	pass 
	
func _on_return_my_farm_button_pressed() -> void:
	# 如果当前处于访问模式，返回自己的农场
	if is_visiting_mode:
		return_to_my_farm()
	else:
		# 如果不在访问模式，这个按钮可能用于其他功能或者不做任何操作
		print("当前已在自己的农场")





# 处理服务器作物更新消息
func _handle_crop_update(update_data):
	# 检查是否是访问模式的更新
	var is_visiting_update = update_data.get("is_visiting", false)
	
	if is_visiting_update and is_visiting_mode:
		# 访问模式下的更新，更新被访问玩家的农场数据
		farm_lots = update_data["farm_lots"]
	elif not is_visiting_update and not is_visiting_mode:
		# 正常模式下的更新，更新自己的农场数据
		farm_lots = update_data["farm_lots"]
	else:
		# 状态不匹配，忽略更新
		print("忽略不匹配的作物更新，当前访问模式：", is_visiting_mode, "，更新类型：", is_visiting_update)
		return
	
	# 更新UI显示
	_update_farm_lots_state()


# 处理玩家动作到服务端响应消息
func _handle_action_response(response_data):
	var action_type = response_data.get("action_type", "")
	var success = response_data.get("success", false)
	var message = response_data.get("message", "")
	var updated_data = response_data.get("updated_data", {})
	
	match action_type:
		"harvest_crop":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("experience"):
					experience = updated_data["experience"]
				if updated_data.has("level"):
					level = updated_data["level"]
				
				# 更新UI
				_update_ui()
				Toast.show(message, Color.GREEN)
			else:
				Toast.show(message, Color.RED)
				
		"plant_crop":
			if success:
				# 更新玩家背包
				if updated_data.has("player_bag"):
					player_bag = updated_data["player_bag"]
				
				# 更新玩家背包UI
				player_bag_panel.update_player_bag_ui()
				Toast.show(message, Color.GREEN)
			else:
				Toast.show(message, Color.RED)
				
		"buy_seed":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("player_bag"):
					player_bag = updated_data["player_bag"]
				
				# 更新UI
				_update_ui()
				player_bag_panel.update_player_bag_ui()
				Toast.show(message, Color.GREEN)
			else:
				Toast.show(message, Color.RED)

		"dig_ground":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("farm_lots"):
					farm_lots = updated_data["farm_lots"]
				
				# 更新UI
				_update_ui()
				_update_farm_lots_state()
				Toast.show(message, Color.GREEN)
			else:
				Toast.show(message, Color.RED)
				
		"remove_crop":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("farm_lots"):
					farm_lots = updated_data["farm_lots"]
				
				# 更新UI
				_update_ui()
				_update_farm_lots_state()
				Toast.show(message, Color.GREEN)
			else:
				Toast.show(message, Color.RED)

		"water_crop":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("farm_lots"):
					farm_lots = updated_data["farm_lots"]
				
				# 更新UI
				_update_ui()
				_update_farm_lots_state()
				Toast.show(message, Color.CYAN)
			else:
				Toast.show(message, Color.RED)
				
		"fertilize_crop":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("farm_lots"):
					farm_lots = updated_data["farm_lots"]
				
				# 更新UI
				_update_ui()
				_update_farm_lots_state()
				Toast.show(message, Color.PURPLE)
			else:
				Toast.show(message, Color.RED)
				
		"upgrade_land":
			if success:
				# 更新玩家数据
				if updated_data.has("money"):
					money = updated_data["money"]
				if updated_data.has("farm_lots"):
					farm_lots = updated_data["farm_lots"]
				
				# 更新UI
				_update_ui()
				_update_farm_lots_state()
				Toast.show(message, Color.GOLD)
			else:
				Toast.show(message, Color.RED)

# 处理玩家排行榜响应
func _handle_player_rankings_response(data):
	player_ranking_panel.handle_player_rankings_response(data)

# 处理玩家游玩时间响应
func _handle_play_time_response(data):
	player_ranking_panel.handle_play_time_response(data)

# 处理访问玩家响应
func _handle_visit_player_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var target_player_data = data.get("player_data", {})
		
		# 保存当前玩家数据
		if not is_visiting_mode:
			original_player_data = {
				"user_name": user_name,
				"player_name": show_player_name.text.replace("玩家昵称：", ""),
				"farm_name": show_farm_name.text.replace("农场名称：", ""),
				"level": level,
				"money": money,
				"experience": experience,
				"farm_lots": farm_lots.duplicate(true),
				"player_bag": player_bag.duplicate(true)
			}
		
		# 切换到访问模式
		is_visiting_mode = true
		visited_player_data = target_player_data
		
		# 更新显示数据
		money = target_player_data.get("money", 0)
		experience = target_player_data.get("experience", 0)
		level = target_player_data.get("level", 1)
		farm_lots = target_player_data.get("farm_lots", [])
		player_bag = target_player_data.get("player_bag", [])
		
		# 更新UI显示
		show_player_name.text = "玩家昵称：" + target_player_data.get("player_name", "未知")
		show_farm_name.text = "农场名称：" + target_player_data.get("farm_name", "未知农场")
		show_tip.text = "访问模式"
		show_tip.modulate = Color.ORANGE
		
		_update_ui()
		
		# 重新创建地块按钮以显示被访问玩家的农场
		_create_farm_buttons()
		_update_farm_lots_state()
		
		# 更新背包UI
		if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
			player_bag_panel.update_player_bag_ui()
		
		# 隐藏排行榜面板
		if player_ranking_panel:
			player_ranking_panel.hide()
		
		Toast.show("正在访问 " + target_player_data.get("player_name", "未知") + " 的农场", Color.CYAN)
		print("成功进入访问模式，访问玩家：", target_player_data.get("player_name", "未知"))
	else:
		Toast.show("访问失败：" + message, Color.RED)
		print("访问玩家失败：", message)

# 处理返回自己农场响应
func _handle_return_my_farm_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var player_data = data.get("player_data", {})
		
		# 恢复玩家数据
		money = player_data.get("money", 500)
		experience = player_data.get("experience", 0)
		level = player_data.get("level", 1)
		farm_lots = player_data.get("farm_lots", [])
		player_bag = player_data.get("player_bag", [])
		
		# 恢复UI显示
		show_player_name.text = "玩家昵称：" + player_data.get("player_name", "未知")
		show_farm_name.text = "农场名称：" + player_data.get("farm_name", "我的农场")
		show_tip.text = "欢迎回到自己的农场"
		show_tip.modulate = Color.WHITE
		
		# 退出访问模式
		is_visiting_mode = false
		visited_player_data.clear()
		original_player_data.clear()
		
		# 更新UI
		_update_ui()
		
		# 重新创建地块按钮以显示自己的农场
		_create_farm_buttons()
		_update_farm_lots_state()
		
		# 更新背包UI
		if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
			player_bag_panel.update_player_bag_ui()
		
		Toast.show("已返回自己的农场", Color.GREEN)
		print("成功返回自己的农场")
	else:
		Toast.show("返回农场失败：" + message, Color.RED)
		print("返回农场失败：", message)




#创建作物按钮
func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = null
	match crop_quality:
		"普通":
			button = green_bar.duplicate()
		"优良":
			button = orange_bar.duplicate()
		"稀有":
			button = white_blue_bar.duplicate()
		"史诗":
			button = pink_bar.duplicate()
		"传奇":
			button = black_blue_bar.duplicate()
		_:  # 默认情况
			button = green_bar.duplicate()

	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本
	button.text = str(crop_quality + "-" + crop_name)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = crop_quality
	
	return button



# 初始化农场地块按钮 - 只在游戏开始时调用一次
func _create_farm_buttons():
	# 清空当前显示的地块
	for child in grid_container.get_children():
		child.queue_free()
		
	# 创建所有地块按钮
	for i in range(len(farm_lots)):
		var button = crop_item.duplicate()
		button.name = "FarmLot_" + str(i)
		
		# 根据是否处于访问模式连接不同的事件
		if is_visiting_mode:
			# 访问模式下，点击地块只显示提示信息
			button.connect("pressed", Callable(self, "_on_visit_item_selected").bind(i))
		else:
			# 正常模式下，连接正常的地块操作
			button.connect("pressed", Callable(self, "_on_item_selected").bind(i))
		
		grid_container.add_child(button)


# 更新农场地块状态到 GridContainer 更新现有按钮的状态
func _update_farm_lots_state():
	var digged_count = 0  # 统计已开垦地块的数量

	for i in range(len(farm_lots)):
		if i >= grid_container.get_child_count():
			break # 防止越界
			
		var lot = farm_lots[i]
		var button = grid_container.get_child(i)
		var label = button.get_node("crop_name")
		var status_label = button.get_node("status_label")
		var progressbar = button.get_node("ProgressBar")

		# 更新作物图片
		_update_lot_crop_sprite(button, lot)

		if lot["is_diged"]:
			digged_count += 1  # 增加已开垦地块计数
			if lot["is_planted"]:
				# 如果作物已死亡
				if lot["is_dead"]:
					label.modulate = Color.NAVY_BLUE
					label.text = "[" + farm_lots[i]["crop_type"] + "已死亡" + "]"
				else:
					# 正常生长逻辑
					var crop_name = lot["crop_type"]
					label.text = "[" + can_planted_crop[crop_name]["品质"] + "-" + lot["crop_type"] +"]"
					var status_text = ""
					# 添加状态标识
					var status_indicators = []
					if lot.get("已浇水", false):
						status_indicators.append("已浇水")#💧
					if lot.get("已施肥", false):
						status_indicators.append("已施肥")#🌱
					if lot.get("土地等级", 0) >= 1:
						status_indicators.append("等级:1")#⭐
					
					if status_indicators.size() > 0:
						status_text += " " + " ".join(status_indicators)
					status_label.text = status_text
					
					# 根据品质显示颜色
					match can_planted_crop[crop_name]["品质"]:
						"普通":
							label.modulate = Color.HONEYDEW#白色
						"优良":
							label.modulate = Color.DODGER_BLUE#深蓝色
						"稀有":
							label.modulate = Color.HOT_PINK#品红色
						"史诗":
							label.modulate = Color.YELLOW#黄色
						"传奇":
							label.modulate = Color.ORANGE_RED#红色

					progressbar.show()
					progressbar.max_value = int(lot["max_grow_time"])
					progressbar.value = int(lot["grow_time"]) # 直接设置值，不使用动画
			else:
				# 已开垦但未种植的地块显示为空地
				var land_text = "[空地"
				if lot.get("土地等级", 0) >= 1:
					status_label.text = "等级:1"
				land_text += "]"
				
				label.modulate = Color.GREEN#绿色
				label.text = land_text
				progressbar.hide()

		else:
			# 未开垦的地块
			label.modulate = Color.WEB_GRAY#深褐色
			label.text = "[" + "未开垦" + "]"
			progressbar.hide()

	# 根据已开垦地块数量更新 dig_money
	dig_money = digged_count * 1000


# 仅在加载游戏或特定情况下完全刷新地块 - 用于与服务器同步时
func _refresh_farm_lots():
	_create_farm_buttons()
	_update_farm_lots_state()


# 更新玩家信息显示
func _update_ui():
	show_money.text = "当前金钱：" + str(money) + " 元"
	show_experience.text = "当前经验：" + str(experience) + " 点"
	show_level.text = "当前等级：" + str(level) + " 级"


# 处理地块点击事件
func _on_item_selected(index):
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法操作地块", Color.ORANGE)
		return
	
	land_panel.show()
	land_panel.selected_lot_index = index
	selected_lot_index = index
	# 更新按钮文本
	if land_panel.has_method("_update_button_texts"):
		land_panel._update_button_texts()

# 处理访问模式下的地块点击事件
func _on_visit_item_selected(index):
	# 显示被访问玩家的地块信息
	var lot = farm_lots[index]
	var info_text = ""
	
	if lot["is_diged"]:
		if lot["is_planted"]:
			if lot["is_dead"]:
				info_text = "地块 " + str(index + 1) + ": " + lot["crop_type"] + " (已死亡)"
			else:
				var crop_name = lot["crop_type"]
				var progress = float(lot["grow_time"]) / float(lot["max_grow_time"]) * 100.0
				var quality = "未知品质"
				
				# 获取作物品质
				if can_planted_crop.has(crop_name):
					quality = can_planted_crop[crop_name]["品质"]
				
				if lot["grow_time"] >= lot["max_grow_time"]:
					info_text = "地块 " + str(index + 1) + ": " + quality + "-" + crop_name + " (已成熟)"
				else:
					info_text = "地块 " + str(index + 1) + ": " + quality + "-" + crop_name + " (成熟度: " + str(int(progress)) + "%)"
		else:
			info_text = "地块 " + str(index + 1) + ": 空地 (已开垦)"
	else:
		info_text = "地块 " + str(index + 1) + ": 未开垦"
	
	Toast.show(info_text, Color.CYAN)
	print("查看地块信息: ", info_text)


# 收获作物
func _harvest_crop(index):
	var lot = farm_lots[index]
	if lot["grow_time"] >= lot["max_grow_time"]:
		# 发送收获请求到服务器
		if network_manager and network_manager.sendHarvestCrop(index):
			pass
	else:
		#print("作物还未成熟")
		Toast.show("作物还未成熟", Color.RED)





# 检查玩家是否可以升级
func _check_level_up():
	var level_up_experience = 100 * level
	if experience >= level_up_experience:
		level += 1
		experience -= level_up_experience
		#print("恭喜！你升到了等级 ", level)
		Toast.show("恭喜！你升到了" + str(level) + "级 ", Color.SKY_BLUE)
		crop_store_panel.init_store()


# 返回自己的农场
func return_to_my_farm():
	if not is_visiting_mode:
		return
	
	# 发送返回自己农场的请求到服务器
	if network_manager and network_manager.has_method("sendReturnMyFarm"):
		var success = network_manager.sendReturnMyFarm()
		if success:
			Toast.show("正在返回自己的农场...", Color.YELLOW)
			print("已发送返回自己农场的请求")
		else:
			Toast.show("网络未连接，无法返回农场", Color.RED)
			print("发送返回农场请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

# 从服务器获取作物数据
func _load_crop_data():
	var network_manager = get_node("/root/main/UI/TCPNerworkManager")
	if network_manager and network_manager.is_connected_to_server():
		# 从服务器请求作物数据
		print("正在从服务器获取作物数据...")
		network_manager.sendGetCropData()
	else:
		# 如果无法连接服务器，尝试加载本地数据
		print("无法连接服务器，尝试加载本地作物数据...")
		_load_local_crop_data()

# 尝试从服务器加载最新数据
func _try_load_from_server():

	if network_manager and network_manager.is_connected_to_server():
		# 从服务器请求最新作物数据
		print("尝试从服务器获取最新作物数据...")
		network_manager.sendGetCropData()
	else:
		print("服务器未连接，使用当前作物数据")

# 处理服务器作物数据响应
func _handle_crop_data_response(response_data):
	var success = response_data.get("success", false)
	
	if success:
		var crop_data = response_data.get("crop_data", {})
		if crop_data:
			# 保存到本地文件
			_save_crop_data_to_local(crop_data)
			# 设置全局变量
			can_planted_crop = crop_data
			print("作物数据已从服务器更新")
			
			# 重新初始化商店和背包UI，因为现在有了作物数据
			_refresh_ui_after_crop_data_loaded()
		else:
			print("服务器返回的作物数据为空")
			_load_local_crop_data()
	else:
		var message = response_data.get("message", "未知错误")
		print("从服务器获取作物数据失败：", message)
		_load_local_crop_data()

# 从本地文件加载作物数据（备用方案）
func _load_local_crop_data():
	# 优先尝试加载用户目录下的缓存文件
	var file = FileAccess.open("user://crop_data.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			can_planted_crop = json.get_data()
			print("已加载本地缓存的作物数据")
			_refresh_ui_after_crop_data_loaded()
			return
		else:
			print("本地缓存作物数据JSON解析错误：", json.get_error_message())
	
	# 如果缓存文件不存在或解析失败，加载默认数据
	file = FileAccess.open("res://Data/crop_data.json", FileAccess.READ)
	if not file:
		print("无法读取默认作物数据文件！")
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("默认作物数据JSON解析错误：", json.get_error_message())
		return
		
	can_planted_crop = json.get_data()
	print("已加载默认作物数据")
	_refresh_ui_after_crop_data_loaded()

# 作物数据加载后刷新UI
func _refresh_ui_after_crop_data_loaded():
	# 重新初始化商店和背包UI，因为现在有了作物数据
	if crop_store_panel and crop_store_panel.has_method("init_store"):
		crop_store_panel.init_store()
		print("商店已根据作物数据重新初始化")
	
	if player_bag_panel and player_bag_panel.has_method("init_player_bag"):
		player_bag_panel.init_player_bag()
		print("背包已根据作物数据重新初始化")

# 保存作物数据到本地文件
func _save_crop_data_to_local(crop_data):
	var file = FileAccess.open("user://crop_data.json", FileAccess.WRITE)
	if not file:
		print("无法创建本地作物数据缓存文件！")
		return
		
	var json_string = JSON.stringify(crop_data, "\t")
	file.store_string(json_string)
	file.close()
	print("作物数据已保存到本地缓存")

# 加载作物图片序列帧
func _load_crop_textures(crop_name: String) -> Array:
	"""
	加载指定作物的所有序列帧图片
	返回图片数组，如果作物不存在则返回默认图片
	"""
	if crop_textures_cache.has(crop_name):
		return crop_textures_cache[crop_name]
	
	var textures = []
	var crop_path = "res://assets/作物/" + crop_name + "/"
	var default_path = "res://assets/作物/默认/"
	
	# 检查作物文件夹是否存在
	if DirAccess.dir_exists_absolute(crop_path):
		# 尝试加载作物的序列帧（从0开始）
		var frame_index = 0
		while true:
			var texture_path = crop_path + str(frame_index) + ".png"
			if ResourceLoader.exists(texture_path):
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
					frame_index += 1
				else:
					break
			else:
				break
		
		if textures.size() > 0:
			print("成功加载作物 ", crop_name, " 的 ", textures.size(), " 帧图片")
		else:
			print("作物 ", crop_name, " 文件夹存在但没有找到有效图片，使用默认图片")
			textures = _load_default_textures()
	else:
		print("作物 ", crop_name, " 的文件夹不存在，使用默认图片")
		textures = _load_default_textures()
	
	# 缓存结果
	crop_textures_cache[crop_name] = textures
	crop_frame_counts[crop_name] = textures.size()
	
	return textures

# 加载默认图片
func _load_default_textures() -> Array:
	"""
	加载默认作物图片
	"""
	if crop_textures_cache.has("默认"):
		return crop_textures_cache["默认"]
	
	var textures = []
	var default_path = "res://assets/作物/默认/"
	
	# 尝试加载默认图片序列帧
	var frame_index = 0
	while true:
		var texture_path = default_path + str(frame_index) + ".png"
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture:
				textures.append(texture)
				frame_index += 1
			else:
				break
		else:
			break
	
	# 如果没有找到序列帧，尝试加载单个默认图片
	if textures.size() == 0:
		var single_texture_path = default_path + "0.png"
		if ResourceLoader.exists(single_texture_path):
			var texture = load(single_texture_path)
			if texture:
				textures.append(texture)
	
	# 缓存默认图片
	crop_textures_cache["默认"] = textures
	crop_frame_counts["默认"] = textures.size()
	
	print("加载了 ", textures.size(), " 个默认作物图片")
	return textures

# 根据生长进度获取对应的作物图片
func _get_crop_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
	"""
	根据作物名称和生长进度获取对应的图片
	progress: 0.0 到 1.0 的生长进度
	"""
	var textures = _load_crop_textures(crop_name)
	
	if textures.size() == 0:
		return null
	
	if textures.size() == 1:
		return textures[0]
	
	# 根据进度计算应该显示的帧
	var frame_index = int(progress * (textures.size() - 1))
	frame_index = clamp(frame_index, 0, textures.size() - 1)
	
	return textures[frame_index]

# 更新地块的作物图片
func _update_lot_crop_sprite(button: Button, lot_data: Dictionary):
	"""
	更新单个地块按钮的作物图片
	"""
	var crop_sprite = button.get_node("crop_sprite")
	
	if not lot_data["is_diged"]:
		# 未开垦的地块，隐藏作物图片
		crop_sprite.visible = false
		return
	
	if not lot_data["is_planted"] or lot_data["crop_type"] == "":
		# 空地，隐藏作物图片
		crop_sprite.visible = false
		return
	
	# 有作物的地块
	crop_sprite.visible = true
	
	var crop_name = lot_data["crop_type"]
	var grow_time = float(lot_data["grow_time"])
	var max_grow_time = float(lot_data["max_grow_time"])
	var is_dead = lot_data.get("is_dead", false)
	
	# 计算生长进度
	var progress = 0.0
	if max_grow_time > 0:
		progress = grow_time / max_grow_time
		progress = clamp(progress, 0.0, 1.0)
	
	# 如果作物死亡，显示最后一帧并调整颜色
	if is_dead:
		var texture = _get_crop_texture_by_progress(crop_name, 1.0)  # 使用最后一帧
		if texture:
			crop_sprite.texture = texture
			crop_sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)  # 变暗表示死亡
		else:
			crop_sprite.visible = false
	else:
		# 正常作物，恢复正常颜色
		crop_sprite.modulate = Color.WHITE
		
		# 获取对应的图片
		var texture = _get_crop_texture_by_progress(crop_name, progress)
		
		if texture:
			crop_sprite.texture = texture
		else:
			print("无法获取作物 ", crop_name, " 的图片")
			crop_sprite.visible = false

# 预加载常用作物图片
func _preload_common_crop_textures():
	"""
	预加载一些常用的作物图片，提高游戏性能
	"""
	print("开始预加载作物图片...")
	
	# 首先加载默认图片
	_load_default_textures()
	
	# 预加载一些常见作物（可以根据实际情况调整）
	var common_crops = ["草莓", "胡萝卜", "土豆", "玉米", "小麦", "番茄"]
	
	for crop_name in common_crops:
		_load_crop_textures(crop_name)
	
	print("作物图片预加载完成，已缓存 ", crop_textures_cache.size(), " 种作物")

# 清理作物图片缓存
func _clear_crop_textures_cache():
	"""
	清理作物图片缓存，释放内存
	"""
	crop_textures_cache.clear()
	crop_frame_counts.clear()
	print("作物图片缓存已清理")

# 获取作物图片缓存信息
func _get_crop_cache_info() -> String:
	"""
	获取当前作物图片缓存的信息
	"""
	var info = "作物图片缓存信息:\n"
	for crop_name in crop_textures_cache.keys():
		var frame_count = crop_frame_counts.get(crop_name, 0)
		info += "- " + crop_name + ": " + str(frame_count) + " 帧\n"
	return info

# 调试：打印作物图片缓存信息
func _debug_print_crop_cache():
	"""
	调试用：打印当前作物图片缓存信息
	"""
	print(_get_crop_cache_info())

# 调试：强制刷新所有地块的作物图片
func _debug_refresh_all_crop_sprites():
	"""
	调试用：强制刷新所有地块的作物图片
	"""
	print("强制刷新所有地块的作物图片...")
	for i in range(len(farm_lots)):
		if i >= grid_container.get_child_count():
			break
		var button = grid_container.get_child(i)
		var lot = farm_lots[i]
		_update_lot_crop_sprite(button, lot)
	print("作物图片刷新完成")

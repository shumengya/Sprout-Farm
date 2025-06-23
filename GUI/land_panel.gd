extends Panel

#获取玩家要操作的地块序号
var selected_lot_index = 0

#预添加常用的面板
@onready var main_game = get_node("/root/main")
@onready var land_panel = get_node("/root/main/UI/LandPanel")
@onready var crop_store_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var player_ranking_panel = get_node("/root/main/UI/PlayerRankingPanel")
@onready var player_bag_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var network_manager = get_node("/root/main/UI/TCPNetworkManager")

@onready var quit_button :Button = $Quit_Button
@onready var dig_button: Button = $Grid/Dig_Button
@onready var water_button: Button = $Grid/Water_Button
@onready var fertilize_button: Button = $Grid/Fertilize_Button
@onready var upgrade_button: Button = $Grid/Upgrade_Button
@onready var plant_button: Button = $Grid/Plant_Button
@onready var remove_button: Button = $Grid/Remove_Button
@onready var harvest_button: Button = $Grid/Harvest_Button


func _ready():
	self.hide()
	quit_button.pressed.connect(self._on_quit_button_pressed)
	dig_button.pressed.connect(self._on_dig_button_pressed)
	water_button.pressed.connect(self._on_water_button_pressed)
	fertilize_button.pressed.connect(self._on_fertilize_button_pressed)
	upgrade_button.pressed.connect(self._on_upgrade_button_pressed)
	plant_button.pressed.connect(self._on_plant_button_pressed)
	remove_button.pressed.connect(self._on_remove_button_pressed)
	harvest_button.pressed.connect(self._on_harvest_button_pressed)
	
	# 显示浇水、施肥、升级按钮
	water_button.visible = true
	fertilize_button.visible = true
	upgrade_button.visible = true
	
	_update_button_texts()

# 显示面板时更新按钮状态
func show_panel():
	self.show()
	_update_button_texts()
	_update_button_availability()

# 更新按钮可用性
func _update_button_availability():
	if main_game.is_visiting_mode:
		# 访问模式下禁用一些按钮
		dig_button.hide()
		remove_button.hide()
		upgrade_button.hide()
		plant_button.hide()
		
		# 启用允许的按钮
		water_button.show()
		fertilize_button.show()
		harvest_button.show()
	else:
		# 自己农场模式下启用所有按钮
		dig_button.show()
		remove_button.show()
		upgrade_button.show()
		plant_button.show()
		water_button.show()
		fertilize_button.show()
		harvest_button.show()

# 更新按钮文本
func _update_button_texts():
	# 根据是否访问模式显示不同的按钮文本
	if main_game.is_visiting_mode:
		water_button.text = "帮助浇水"+"\n￥50"
		fertilize_button.text = "帮助施肥"+"\n￥150"
		harvest_button.text = "偷菜"
	else:
		dig_button.text = "开垦"+"\n￥"+str(main_game.dig_money)
		remove_button.text = "铲除"+"\n￥500"
		water_button.text = "浇水"+"\n￥50"
		fertilize_button.text = "施肥"+"\n￥150"
		
		# 升级按钮动态显示
		_update_upgrade_button_text()
		
		harvest_button.text = "收获"

# 更新升级按钮文本
func _update_upgrade_button_text():
	if not main_game or not main_game.farm_lots:
		upgrade_button.text = "升级\n￥1000"
		return
		
	if selected_lot_index >= 0 and selected_lot_index < main_game.farm_lots.size():
		var lot = main_game.farm_lots[selected_lot_index]
		var current_level = int(lot.get("土地等级", 0))  # 确保是整数
		
		var upgrade_config = {
			0: {"cost": 1000, "name": "黄土地"},
			1: {"cost": 2000, "name": "红土地"},
			2: {"cost": 4000, "name": "紫土地"},
			3: {"cost": 8000, "name": "黑土地"}
		}
		
		if current_level >= 4:
			upgrade_button.text = "已满级"
		elif upgrade_config.has(current_level):
			var config = upgrade_config[current_level]
			upgrade_button.text = "升级到\n" + config["name"] + "\n￥" + str(config["cost"])
		else:
			upgrade_button.text = "等级异常\n" + str(current_level)
	else:
		upgrade_button.text = "选择地块"

#开垦
func _on_dig_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法开垦土地", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查玩家金钱是否足够
	var dig_cost = main_game.dig_money
	if main_game.money < dig_cost:
		Toast.show("金钱不足，开垦土地需要 " + str(dig_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块是否已经开垦
	var lot = main_game.farm_lots[selected_lot_index]
	if lot.get("is_diged", false):
		Toast.show("此地块已经开垦过了", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送开垦土地请求到服务器
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendDigGround(selected_lot_index):
			self.hide()
		else:
			Toast.show("发送开垦请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法开垦土地", Color.RED, 2.0, 1.0)
		self.hide()

#浇水
func _on_water_button_pressed():
	# 检查玩家金钱是否足够（无论是否访问模式都检查自己的钱）
	var water_cost = 50
	var my_money = main_game.money
	
	# 如果是访问模式，需要检查自己的原始金钱数据
	if main_game.is_visiting_mode:
		my_money = main_game.original_player_data.get("money", 0)
	
	if my_money < water_cost:
		var action_text = "帮助浇水" if main_game.is_visiting_mode else "浇水"
		Toast.show("金钱不足，" + action_text + "需要 " + str(water_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块状态
	var lot = main_game.farm_lots[selected_lot_index]
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查作物是否已死亡
	if lot.get("is_dead", false):
		Toast.show("死亡的作物无法浇水", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查是否已经成熟
	if lot.get("grow_time", 0) >= lot.get("max_grow_time", 1):
		Toast.show("作物已经成熟，无需浇水", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查是否已经浇过水
	var current_time = Time.get_unix_time_from_system()
	var last_water_time = lot.get("浇水时间", 0)
	var water_cooldown = 3600  # 1小时冷却时间
	
	if current_time - last_water_time < water_cooldown:
		var remaining_time = water_cooldown - (current_time - last_water_time)
		var remaining_minutes = int(remaining_time / 60)
		var remaining_seconds = int(remaining_time) % 60
		Toast.show("浇水冷却中，还需等待 " + str(remaining_minutes) + " 分钟 " + str(remaining_seconds) + " 秒", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送浇水请求到服务器
	var target_username = ""
	if main_game.is_visiting_mode:
		target_username = main_game.visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendWaterCrop(selected_lot_index, target_username):
			self.hide()
		else:
			Toast.show("发送浇水请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		var action_text = "帮助浇水" if main_game.is_visiting_mode else "浇水"
		Toast.show("网络未连接，无法" + action_text, Color.RED, 2.0, 1.0)
		self.hide()

#施肥
func _on_fertilize_button_pressed():
	# 检查玩家金钱是否足够（无论是否访问模式都检查自己的钱）
	var fertilize_cost = 150
	var my_money = main_game.money
	
	# 如果是访问模式，需要检查自己的原始金钱数据
	if main_game.is_visiting_mode:
		my_money = main_game.original_player_data.get("money", 0)
	
	if my_money < fertilize_cost:
		var action_text = "帮助施肥" if main_game.is_visiting_mode else "施肥"
		Toast.show("金钱不足，" + action_text + "需要 " + str(fertilize_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块状态
	var lot = main_game.farm_lots[selected_lot_index]
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查作物是否已死亡
	if lot.get("is_dead", false):
		Toast.show("死亡的作物无法施肥", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查是否已经成熟
	if lot.get("grow_time", 0) >= lot.get("max_grow_time", 1):
		Toast.show("作物已经成熟，无需施肥", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查是否已经施过肥
	if lot.get("已施肥", false):
		Toast.show("此作物已经施过肥了", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送施肥请求到服务器
	var target_username = ""
	if main_game.is_visiting_mode:
		target_username = main_game.visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendFertilizeCrop(selected_lot_index, target_username):
			self.hide()
		else:
			Toast.show("发送施肥请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		var action_text = "帮助施肥" if main_game.is_visiting_mode else "施肥"
		Toast.show("网络未连接，无法" + action_text, Color.RED, 2.0, 1.0)
		self.hide()

#升级
func _on_upgrade_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法升级", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块索引是否有效
	if selected_lot_index < 0 or selected_lot_index >= main_game.farm_lots.size():
		Toast.show("无效的地块选择", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 获取地块数据
	var lot = main_game.farm_lots[selected_lot_index]
	
	# 检查地块是否已开垦
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 获取当前土地等级和升级配置
	var current_level = int(lot.get("土地等级", 0))  # 确保是整数
	print("当前选择地块索引: ", selected_lot_index)
	print("当前土地等级: ", current_level, " (类型: ", typeof(current_level), ")")
	
	var upgrade_config = {
		0: {"cost": 1000, "name": "黄土地", "speed": "2倍"},
		1: {"cost": 2000, "name": "红土地", "speed": "4倍"},
		2: {"cost": 4000, "name": "紫土地", "speed": "6倍"},
		3: {"cost": 8000, "name": "黑土地", "speed": "10倍"}
	}
	
	# 检查是否已达到最高等级
	if current_level >= 4:
		Toast.show("此土地已达到最高等级（黑土地）", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查土地等级是否有效
	if not upgrade_config.has(current_level):
		Toast.show("土地等级数据异常，当前等级: " + str(current_level), Color.RED, 2.0, 1.0)
		print("土地等级异常，当前等级: ", current_level, "，可用等级: ", upgrade_config.keys())
		self.hide()
		return
	
	var config = upgrade_config[current_level]
	var upgrade_cost = config["cost"]
	var next_name = config["name"]
	var speed_info = config["speed"]
	
	# 检查玩家金钱是否足够
	if main_game.money < upgrade_cost:
		Toast.show("金钱不足，升级到" + next_name + "需要 " + str(upgrade_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 发送升级请求到服务器
	if network_manager and network_manager.is_connected_to_server():
		print("发送升级请求，地块索引: ", selected_lot_index, "，当前等级: ", current_level)
		if network_manager.sendUpgradeLand(selected_lot_index):
			self.hide()
		else:
			Toast.show("发送升级请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法升级土地", Color.RED, 2.0, 1.0)
		self.hide()

#种植
func _on_plant_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法种植", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	player_bag_panel.show()
	self.hide()
	pass
#铲除
func _on_remove_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法铲除作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查玩家金钱是否足够
	var removal_cost = 500
	if main_game.money < removal_cost:
		Toast.show("金钱不足，铲除作物需要 " + str(removal_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块是否有作物
	var lot = main_game.farm_lots[selected_lot_index]
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送铲除作物请求到服务器
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendRemoveCrop(selected_lot_index):
			self.hide()
		else:
			Toast.show("发送铲除请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法铲除作物", Color.RED, 2.0, 1.0)
		self.hide()
	pass

#收获
func _on_harvest_button_pressed():
	# 检查地块状态
	var lot = main_game.farm_lots[selected_lot_index]
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查作物是否成熟
	if lot.get("grow_time", 0) < lot.get("max_grow_time", 1) and not lot.get("is_dead", false):
		Toast.show("作物尚未成熟", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送收获请求到服务器
	var target_username = ""
	if main_game.is_visiting_mode:
		target_username = main_game.visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendHarvestCrop(selected_lot_index, target_username):
			self.hide()
		else:
			Toast.show("发送收获请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		var action_text = "偷菜" if main_game.is_visiting_mode else "收获"
		Toast.show("网络未连接，无法" + action_text, Color.RED, 2.0, 1.0)
		self.hide()
	pass

#退出
func _on_quit_button_pressed():
	self.hide()
	pass
	
	
	
	
	
	
	
	
	
	

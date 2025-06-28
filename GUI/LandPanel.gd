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
@onready var dig_button: Button = $Grid/Dig_Button					#开垦
@onready var water_button: Button = $Grid/Water_Button				#浇水
@onready var fertilize_button: Button = $Grid/Fertilize_Button		#施肥
@onready var upgrade_button: Button = $Grid/Upgrade_Button			#升级
@onready var plant_button: Button = $Grid/Plant_Button				#种植
@onready var remove_button: Button = $Grid/Remove_Button			#铲除
@onready var harvest_button: Button = $Grid/Harvest_Button			#收获
@onready var kill_insect_button: Button = $Grid/KillInsect_Button	#杀虫



#下面这些来实时获取被点击地块的作物情况
@onready var crop_texture_rect: TextureRect = $TextureRect 	#这个显示作物当前图片
@onready var progress_bar: ProgressBar = $VBox/ProgressBar			#显示作物当前生长进度
@onready var cost: Label = $VBox/HBox1/cost							#显示花费
@onready var earn: Label = $VBox/HBox1/earn							#显示收益
@onready var growthtime: Label = $VBox/HBox1/growthtime				#生长时间
@onready var experience: Label = $VBox/HBox1/experience				#收获经验
@onready var canbuy: Label = $VBox/HBox2/canbuy						#能否购买
@onready var quality: Label = $VBox/HBox2/quality					#作物品质
@onready var weatherability: Label = $VBox/HBox2/weatherability		#耐候性
@onready var level: Label = $VBox/HBox2/level						#种植等级
@onready var description: Label = $VBox/HBox3/description			#描述

#没有作物直接一键隐藏这个
@onready var v_box: VBoxContainer = $VBox







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
	_update_crop_info()

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


#=====================================土地面板功能处理=========================================
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
#=====================================土地面板功能处理=========================================


#关闭土地面板按钮
func _on_quit_button_pressed():
	self.hide()
	pass

# 更新作物信息显示
func _update_crop_info():
	print("调试：_update_crop_info 被调用，selected_lot_index = ", selected_lot_index)
	
	if not main_game or not main_game.farm_lots:
		print("调试：main_game 或 farm_lots 不存在")
		v_box.hide()
		crop_texture_rect.hide()
		return
		
	if selected_lot_index < 0 or selected_lot_index >= main_game.farm_lots.size():
		print("调试：selected_lot_index 无效: ", selected_lot_index, " / ", main_game.farm_lots.size())
		v_box.hide()
		crop_texture_rect.hide()
		return
	
	var lot = main_game.farm_lots[selected_lot_index]
	print("调试：地块数据: ", lot)
	
	# 检查地块是否有作物
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		print("调试：地块没有作物")
		v_box.hide()
		crop_texture_rect.hide()
		# 清除所有显示内容
		crop_texture_rect.texture = null
		progress_bar.value = 0
		cost.text = ""
		earn.text = ""
		growthtime.text = ""
		experience.text = ""
		canbuy.text = ""
		quality.text = ""
		weatherability.text = ""
		level.text = ""
		description.text = ""
		return
	
	# 获取作物类型
	var crop_type = lot.get("crop_type", "")
	print("调试：作物类型: ", crop_type)
	
	# 从网络管理器获取作物数据
	var crop_data = null
	if network_manager and network_manager.has_method("get_crop_data"):
		crop_data = network_manager.get_crop_data()
	
	# 如果没有作物数据，尝试从主游戏获取
	if not crop_data and main_game and main_game.has_method("get_crop_data"):
		crop_data = main_game.get_crop_data()
	
	# 如果仍然没有作物数据，隐藏信息面板
	if not crop_data or not crop_data.has(crop_type):
		print("调试：没有作物数据或作物类型不存在: ", crop_type)
		v_box.hide()
		crop_texture_rect.hide()
		return
	
	print("调试：找到作物数据，开始显示作物信息")
	
	# 显示作物信息面板
	v_box.show()
	crop_texture_rect.show()
	
	# 获取作物信息
	var crop_info = crop_data[crop_type]
	print("调试：作物信息: ", crop_info)
	
	# 更新作物图片
	var crop_texture_path = "res://assets/作物/" + crop_type + "/0.webp"
	if ResourceLoader.exists(crop_texture_path):
		var texture = load(crop_texture_path)
		crop_texture_rect.texture = texture
	else:
		# 如果没有序列帧，尝试加载单个图片
		crop_texture_path = "res://assets/作物/" + crop_type + ".webp"
		if ResourceLoader.exists(crop_texture_path):
			var texture = load(crop_texture_path)
			crop_texture_rect.texture = texture
		else:
			# 加载默认图片
			crop_texture_path = "res://assets/作物/默认/0.webp"
			if ResourceLoader.exists(crop_texture_path):
				var texture = load(crop_texture_path)
				crop_texture_rect.texture = texture
			else:
				crop_texture_rect.texture = null
	
	# 更新进度条
	var grow_time = lot.get("grow_time", 0)
	var max_grow_time = lot.get("max_grow_time", 1)
	var progress = float(grow_time) / float(max_grow_time) * 100.0
	progress_bar.value = min(progress, 100.0)
	
	# 更新作物信息标签
	cost.text = "花费: ￥" + str(crop_info.get("花费", 0))
	earn.text = "收益: ￥" + str(crop_info.get("收益", 0))
	
	# 格式化生长时间
	var growth_seconds = crop_info.get("生长时间", 0)
	var growth_time_text = _format_time_seconds(growth_seconds)
	growthtime.text = "生长时间: " + growth_time_text
	
	experience.text = "经验: " + str(crop_info.get("经验", 0))
	canbuy.text = "可购买: " + ("是" if crop_info.get("能否购买", false) else "否")
	quality.text = "品质: " + str(crop_info.get("品质", "普通"))
	weatherability.text = "耐候性: " + str(crop_info.get("耐候性", 0))
	level.text = "等级要求: " + str(crop_info.get("等级", 1))
	
	# 检查是否为杂草，显示特殊描述并控制收获按钮
	var is_weed = crop_info.get("是否杂草", false)
	if is_weed:
		description.text = "描述: " + str(crop_info.get("描述", "无描述")) + " [杂草不能收获，只能铲除]"
		# 隐藏收获按钮（杂草不能收获）
		harvest_button.hide()
	else:
		description.text = "描述: " + str(crop_info.get("描述", "无描述"))
		# 显示收获按钮并设置正常文本
		harvest_button.show()
		if main_game.is_visiting_mode:
			harvest_button.text = "偷菜"
		else:
			harvest_button.text = "收获"

# 格式化时间（秒转换为时分秒）
func _format_time_seconds(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return str(hours) + "时" + str(minutes) + "分" + str(secs) + "秒"
	elif minutes > 0:
		return str(minutes) + "分" + str(secs) + "秒"
	else:
		return str(secs) + "秒"
	
	
	
	
	
	
	
	
	
	

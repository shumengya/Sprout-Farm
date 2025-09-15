extends Panel

#获取玩家要操作的地块序号
var selected_lot_index = 0

#预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../../BigPanel/LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../../BigPanel/DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../../BigPanel/ItemStorePanel'
@onready var item_bag_panel: Panel = $'../../BigPanel/ItemBagPanel'
@onready var player_bag_panel: Panel = $'../../BigPanel/PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../../BigPanel/CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../../BigPanel/CropStorePanel'
@onready var player_ranking_panel: Panel = $'../../BigPanel/PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../../BigPanel/LoginPanel'


#土地面板功能
@onready var quit_button :Button = $Quit_Button
@onready var dig_button: Button = $GroundFunctionGrid/Dig_Button
@onready var plant_button: Button = $GroundFunctionGrid/Plant_Button
@onready var harvest_button: Button = $GroundFunctionGrid/Harvest_Button
@onready var upgrade_button: Button = $GroundFunctionGrid/Upgrade_Button

#展示被点击土地上的作物信息，如果没有作物就隐藏crop_inform_v_box
@onready var crop_inform_v_box: VBoxContainer = $InformVBox/CropInformVBox 	
@onready var progress_bar: ProgressBar = $InformVBox/CropInformVBox/ProgressBar		#作物生长进度
@onready var cost: Label = $InformVBox/CropInformVBox/HBox1/cost						#作物购买花费
@onready var earn: Label = $InformVBox/CropInformVBox/HBox1/earn						#作物收益
@onready var growthtime: Label = $InformVBox/CropInformVBox/HBox1/growthtime			#作物生长时间精确到天时分秒
@onready var experience: Label = $InformVBox/CropInformVBox/HBox1/experience			#作物收获经验
@onready var canbuy: Label = $InformVBox/CropInformVBox/HBox2/canbuy					#作物能否在商店购买
@onready var quality: Label = $InformVBox/CropInformVBox/HBox2/quality					#作物品质
@onready var weatherability: Label = $InformVBox/CropInformVBox/HBox2/weatherability	#作物耐候性
@onready var level: Label = $InformVBox/CropInformVBox/HBox2/level						#作物等级
@onready var description: Label = $InformVBox/CropInformVBox/HBox3/description			#作物描述
@onready var crop_texture_rect: TextureRect = $CropImageVBox/CropTextureRect							#作物当前图片

#展示被点击土地的地块信息
@onready var ground_level: Label = $InformVBox/GroundInformVBox/GroundLevel			#土地等级
@onready var ground_function: Label = $InformVBox/GroundInformVBox/GroundFunction		#土地功能 





func _ready():
	self.hide()
	dig_button.pressed.connect(self._on_dig_button_pressed)
	upgrade_button.pressed.connect(self._on_upgrade_button_pressed)
	plant_button.pressed.connect(self._on_plant_button_pressed)
	harvest_button.pressed.connect(self._on_harvest_button_pressed)
	
	upgrade_button.visible = true
	
	_update_button_texts()

# 显示面板时更新按钮状态
func show_panel():
	self.show()
	_update_button_texts()
	_update_button_availability()
	_update_panel_information()  # 添加更新面板信息

# 更新按钮可用性
func _update_button_availability():
	if main_game.is_visiting_mode:
		# 访问模式下禁用一些按钮
		dig_button.hide()
		upgrade_button.hide()
		plant_button.hide()
		
		# 启用允许的按钮
		harvest_button.show()
	else:
		# 自己农场模式下启用所有按钮
		dig_button.show()
		upgrade_button.show()
		plant_button.show()
		harvest_button.show()

# 更新按钮文本
func _update_button_texts():
	# 根据是否访问模式显示不同的按钮文本
	if main_game.is_visiting_mode:
		harvest_button.text = "偷菜"
	else:
		dig_button.text = "开垦"+"\n￥"+str(main_game.dig_money)
		
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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		if tcp_network_manager_panel.sendDigGround(selected_lot_index):
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
		my_money = main_game.original_player_data.get("钱币", 0)
	
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
		target_username = main_game.visited_player_data.get("玩家账号", "")
	
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		if tcp_network_manager_panel.sendWaterCrop(selected_lot_index, target_username):
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
		my_money = main_game.original_player_data.get("钱币", 0)
	
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
		target_username = main_game.visited_player_data.get("玩家账号", "")
	
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		if tcp_network_manager_panel.sendFertilizeCrop(selected_lot_index, target_username):
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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		print("发送升级请求，地块索引: ", selected_lot_index, "，当前等级: ", current_level)
		if tcp_network_manager_panel.sendUpgradeLand(selected_lot_index):
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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		if tcp_network_manager_panel.sendRemoveCrop(selected_lot_index):
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
		target_username = main_game.visited_player_data.get("玩家账号", "")
	
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		if tcp_network_manager_panel.sendHarvestCrop(selected_lot_index, target_username):
			self.hide()
		else:
			Toast.show("发送收获请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		var action_text = "偷菜" if main_game.is_visiting_mode else "收获"
		Toast.show("网络未连接，无法" + action_text, Color.RED, 2.0, 1.0)
		self.hide()
	pass



#===================面板通用函数==========================
#退出
func _on_quit_button_pressed():
	self.hide()
	pass
	
#刷新面板信息
func _on_refresh_button_pressed() -> void:
	_update_panel_information()
	Toast.show("面板信息已刷新", Color.GREEN, 1.5, 1.0)
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
	
#===================面板通用函数==========================

# 更新面板信息显示
func _update_panel_information():
	if selected_lot_index < 0 or selected_lot_index >= main_game.farm_lots.size():
		print("无效的地块索引：", selected_lot_index)
		return
	
	var lot = main_game.farm_lots[selected_lot_index]
	
	# 更新土地信息
	_update_ground_information(lot)
	
	# 检查是否有作物
	if lot.get("is_planted", false) and lot.get("crop_type", "") != "":
		# 有作物，显示作物信息
		crop_inform_v_box.show()
		_update_crop_information(lot)
		_update_crop_texture(lot)
	else:
		# 没有作物，隐藏作物信息框
		crop_inform_v_box.hide()
		crop_texture_rect.hide()

# 更新作物信息
func _update_crop_information(lot: Dictionary):
	var crop_name = lot.get("crop_type", "")
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	var is_dead = lot.get("is_dead", false)
	var is_watered = lot.get("已浇水", false)
	var is_fertilized = lot.get("已施肥", false)
	
	# 从作物数据中获取详细信息
	if main_game.can_planted_crop.has(crop_name):
		var crop_data = main_game.can_planted_crop[crop_name]
		
		# 更新作物基本信息
		cost.text = "花费：" + str(crop_data.get("花费", 0)) + "元"
		earn.text = "收益：" + str(crop_data.get("收益", 0)) + "元"
		experience.text = "经验：" + str(crop_data.get("经验", 0)) + "点"
		quality.text = "品质：" + str(crop_data.get("品质", "未知"))
		weatherability.text = "耐候性：" + str(crop_data.get("耐候性", 0))
		level.text = "等级：" + str(crop_data.get("等级", 1))
		description.text = "描述：" + str(crop_data.get("描述", "无描述"))
		
		# 更新生长时间显示
		var total_seconds = int(crop_data.get("生长时间", 0))
		var time_str = _format_time_display(total_seconds)
		growthtime.text = "生长时间：" + time_str
		
		# 更新能否购买
		var can_buy = crop_data.get("能否购买", false)
		canbuy.text = "可购买：" + ("是" if can_buy else "否")
	else:
		# 作物数据不存在，显示基本信息
		cost.text = "花费：未知"
		earn.text = "收益：未知"
		experience.text = "经验：未知"
		quality.text = "品质：未知"
		weatherability.text = "耐候性：未知"
		level.text = "等级：未知"
		description.text = "描述：作物数据未找到"
		growthtime.text = "生长时间：未知"
		canbuy.text = "可购买：未知"
	
	# 更新生长进度条
	if is_dead:
		progress_bar.value = 0
		progress_bar.modulate = Color.RED
		progress_bar.show()
	elif max_grow_time > 0:
		var progress = clamp(grow_time / max_grow_time, 0.0, 1.0) * 100
		progress_bar.value = progress
		
		# 根据生长状态设置进度条颜色
		if progress >= 100:
			progress_bar.modulate = Color.GREEN  # 成熟
		elif is_fertilized:
			progress_bar.modulate = Color.YELLOW  # 已施肥
		elif is_watered:
			progress_bar.modulate = Color.CYAN  # 已浇水
		else:
			progress_bar.modulate = Color.WHITE  # 正常生长
		
		progress_bar.show()
	else:
		progress_bar.hide()

# 更新作物图片
func _update_crop_texture(lot: Dictionary):
	var crop_name = lot.get("crop_type", "")
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	var is_dead = lot.get("is_dead", false)
	
	if crop_name == "":
		crop_texture_rect.hide()
		return
	
	crop_texture_rect.show()
	
	# 如果作物已死亡，显示死亡状态
	if is_dead:
		crop_texture_rect.modulate = Color.GRAY
		# 可以在这里设置死亡图片，暂时使用灰色调
	else:
		crop_texture_rect.modulate = Color.WHITE
		
		# 计算生长进度
		var progress = 0.0
		if max_grow_time > 0:
			progress = clamp(grow_time / max_grow_time, 0.0, 1.0)
		
		# 获取对应的作物图片
		var texture: Texture2D = null
		if main_game.crop_texture_manager:
			texture = main_game.crop_texture_manager.get_texture_by_progress(crop_name, progress)
		
		if texture:
			crop_texture_rect.texture = texture
		else:
			# 如果没有找到图片，尝试加载默认图片
			var default_path = "res://assets/作物/默认/0.webp"
			if ResourceLoader.exists(default_path):
				crop_texture_rect.texture = load(default_path)
			else:
				crop_texture_rect.hide()

# 更新土地信息
func _update_ground_information(lot: Dictionary):
	var land_level = int(lot.get("土地等级", 0))
	var is_diged = lot.get("is_diged", false)
	
	# 土地等级配置
	var level_config = {
		0: {"name": "普通土地", "color": Color.WHITE, "speed": "1倍"},
		1: {"name": "黄土地", "color": Color(1.0, 1.0, 0.0), "speed": "2倍"},
		2: {"name": "红土地", "color": Color(1.0, 0.41, 0.0), "speed": "4倍"},
		3: {"name": "紫土地", "color": Color(0.55, 0.29, 0.97), "speed": "6倍"},
		4: {"name": "黑土地", "color": Color(0.33, 0.4, 0.59), "speed": "10倍"}
	}
	
	if is_diged:
		if level_config.has(land_level):
			var config = level_config[land_level]
			ground_level.text = "土地等级：" + config["name"] + " (Lv." + str(land_level) + ")"
			ground_function.text = "生长速度：" + config["speed"]
			ground_level.modulate = config["color"]
		else:
			ground_level.text = "土地等级：未知等级 (Lv." + str(land_level) + ")"
			ground_function.text = "生长速度：未知"
			ground_level.modulate = Color.WHITE
	else:
		ground_level.text = "土地状态：未开垦"
		ground_function.text = "功能：需要开垦后才能使用"
		ground_level.modulate = Color.GRAY

# 格式化时间显示
func _format_time_display(total_seconds: int) -> String:
	var time_str = ""
	
	# 定义时间单位换算
	var SECONDS_PER_MINUTE = 60
	var SECONDS_PER_HOUR = 3600
	var SECONDS_PER_DAY = 86400
	
	# 计算各时间单位
	var days = total_seconds / SECONDS_PER_DAY
	total_seconds %= SECONDS_PER_DAY
	
	var hours = total_seconds / SECONDS_PER_HOUR
	total_seconds %= SECONDS_PER_HOUR
	
	var minutes = total_seconds / SECONDS_PER_MINUTE
	var seconds = total_seconds % SECONDS_PER_MINUTE
	
	# 构建时间字符串（只显示有值的单位）
	if days > 0:
		time_str += str(days) + "天"
	if hours > 0:
		time_str += str(hours) + "小时"
	if minutes > 0:
		time_str += str(minutes) + "分钟"
	if seconds > 0:
		time_str += str(seconds) + "秒"
	
	return time_str if time_str != "" else "0秒"

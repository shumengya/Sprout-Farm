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

# 更新按钮文本
func _update_button_texts():
	dig_button.text = "开垦"+"\n￥"+str(main_game.dig_money)
	remove_button.text = "铲除"+"\n￥500"
	water_button.text = "浇水"+"\n￥50"
	fertilize_button.text = "施肥"+"\n￥150"
	upgrade_button.text = "升级"+"\n￥1000"

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
			Toast.show("正在开垦土地...", Color.YELLOW, 1.5, 1.0)
			self.hide()
		else:
			Toast.show("发送开垦请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法开垦土地", Color.RED, 2.0, 1.0)
		self.hide()
#浇水
func _on_water_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法浇水", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查玩家金钱是否足够
	var water_cost = 50
	if main_game.money < water_cost:
		Toast.show("金钱不足，浇水需要 " + str(water_cost) + " 金钱", Color.RED, 2.0, 1.0)
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
	if lot.get("已浇水", false):
		Toast.show("今天已经浇过水了", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送浇水请求到服务器
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendWaterCrop(selected_lot_index):
			Toast.show("正在浇水...", Color.YELLOW, 1.5, 1.0)
			self.hide()
		else:
			Toast.show("发送浇水请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法浇水", Color.RED, 2.0, 1.0)
		self.hide()
#施肥
func _on_fertilize_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法施肥", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查玩家金钱是否足够
	var fertilize_cost = 150
	if main_game.money < fertilize_cost:
		Toast.show("金钱不足，施肥需要 " + str(fertilize_cost) + " 金钱", Color.RED, 2.0, 1.0)
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
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendFertilizeCrop(selected_lot_index):
			Toast.show("正在施肥...", Color.YELLOW, 1.5, 1.0)
			self.hide()
		else:
			Toast.show("发送施肥请求失败", Color.RED, 2.0, 1.0)
			self.hide()
	else:
		Toast.show("网络未连接，无法施肥", Color.RED, 2.0, 1.0)
		self.hide()
#升级
func _on_upgrade_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法升级", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查玩家金钱是否足够
	var upgrade_cost = 1000
	if main_game.money < upgrade_cost:
		Toast.show("金钱不足，升级土地需要 " + str(upgrade_cost) + " 金钱", Color.RED, 2.0, 1.0)
		self.hide()
		return
	
	# 检查地块是否已开垦
	var lot = main_game.farm_lots[selected_lot_index]
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 检查土地是否已经升级
	var current_level = lot.get("土地等级", 0)
	if current_level >= 1:
		Toast.show("此土地已经升级过了", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	# 发送升级请求到服务器
	if network_manager and network_manager.is_connected_to_server():
		if network_manager.sendUpgradeLand(selected_lot_index):
			Toast.show("正在升级土地...", Color.YELLOW, 1.5, 1.0)
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
			Toast.show("正在铲除作物...", Color.YELLOW, 1.5, 1.0)
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
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法收获作物", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	main_game._harvest_crop(selected_lot_index)
	self.hide()
	pass
#退出
func _on_quit_button_pressed():
	self.hide()
	pass
	
	
	
	
	
	
	
	
	
	

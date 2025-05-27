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
	dig_button.text = "开垦"+"\n花费："+str(main_game.dig_money)

#开垦
func _on_dig_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法开垦土地", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	dig_button.text = "开垦"+"\n花费："+str(main_game.dig_money)
	
	if network_manager and network_manager.is_connected_to_server():
		# 使用服务器API来开垦土地
		if network_manager.sendDigGround(selected_lot_index):
			self.hide()
#浇水
func _on_water_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法浇水", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	self.hide()
	pass
#施肥
func _on_fertilize_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法施肥", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	self.hide()
	pass
#升级
func _on_upgrade_button_pressed():
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法升级", Color.ORANGE, 2.0, 1.0)
		self.hide()
		return
	
	self.hide()
	pass
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
	
	main_game.root_out_crop(selected_lot_index)
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
	
	
	
	
	
	
	
	
	
	

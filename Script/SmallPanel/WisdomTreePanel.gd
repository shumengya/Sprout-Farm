extends Panel

@onready var water_button: Button = $HBox/WaterButton #给智慧树浇水
@onready var fertilize_button: Button = $HBox/FertilizeButton #给智慧树施肥
@onready var play_music_button: Button = $HBox/PlayMusicButton #给智慧树放音乐
@onready var kill_bug_button: Button = $HBox/KillBugButton #给智慧树杀虫
@onready var kill_grass_button: Button = $HBox/KillGrassButton #给智慧树除草
@onready var revive_button: Button = $HBox/ReviveButton #智慧树死亡后需点击此处复活花费1000元

@onready var talk_input: LineEdit = $VBox/HBox/TalkInput #输入要发送给陌生人的一句话
@onready var send_button: Button = $VBox/HBox/SendButton #发送按钮

@onready var level: Label = $Grid/Level #玩家智慧树等级 
@onready var health: Label = $Grid/Health #玩家智慧树生命值
@onready var experience: Label = $Grid/Experience #玩家智慧树经验值
@onready var height: Label = $Grid/Height #玩家智慧树高度

@onready var quit_button: Button = $QuitButton #退出按钮

@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel' #客户端与服务端通信核心
@onready var login_panel: PanelContainer = $'../../BigPanel/LoginPanel' #登录时要加载玩家智慧树状态

@onready var accept_dialog: AcceptDialog = $'../../DiaLog/AcceptDialog'

# 主游戏节点引用
@onready var main_game = get_node("/root/main")

# 智慧树配置数据
var wisdom_tree_config = {
	"智慧树显示的话": "",
	"等级": 1,
	"当前经验值": 0,
	"最大经验值": 100,
	"当前生命值": 100,
	"最大生命值": 100,
	"高度": 20
}

# 智慧树升级经验计算函数（使用动态公式）
func calculate_wisdom_tree_max_exp(level):
	if level <= 1:
		return 100
	# 使用指数增长公式：基础经验 * (等级^1.5) * 1.2
	var base_exp = 50
	var exp_multiplier = 1.2
	var level_factor = pow(level, 1.5)
	var max_exp = int(base_exp * level_factor * exp_multiplier)
	return max_exp


# 确保智慧树配置格式正确，兼容旧格式
func _ensure_config_format():
	# 如果是旧格式，转换为新格式
	if wisdom_tree_config.has("生命值") and not wisdom_tree_config.has("当前生命值"):
		var old_health = wisdom_tree_config.get("生命值", 100)
		wisdom_tree_config["当前生命值"] = old_health
		wisdom_tree_config["最大生命值"] = 100
		wisdom_tree_config.erase("生命值")
	
	if wisdom_tree_config.has("经验") and not wisdom_tree_config.has("当前经验值"):
		var old_exp = wisdom_tree_config.get("经验", 0)
		wisdom_tree_config["当前经验值"] = old_exp
		var level = wisdom_tree_config.get("等级", 1)
		wisdom_tree_config["最大经验值"] = calculate_wisdom_tree_max_exp(level)
		wisdom_tree_config.erase("经验")
	
	# 确保所有必需字段存在
	if not wisdom_tree_config.has("当前生命值"):
		wisdom_tree_config["当前生命值"] = 100
	if not wisdom_tree_config.has("最大生命值"):
		wisdom_tree_config["最大生命值"] = 100
	if not wisdom_tree_config.has("当前经验值"):
		wisdom_tree_config["当前经验值"] = 0
	if not wisdom_tree_config.has("最大经验值"):
		var level = wisdom_tree_config.get("等级", 1)
		wisdom_tree_config["最大经验值"] = calculate_wisdom_tree_max_exp(level)
	if not wisdom_tree_config.has("等级"):
		wisdom_tree_config["等级"] = 1
	if not wisdom_tree_config.has("高度"):
		wisdom_tree_config["高度"] = 20
	if not wisdom_tree_config.has("智慧树显示的话"):
		wisdom_tree_config["智慧树显示的话"] = ""

func _ready() -> void:
	self.hide()
	
	# 连接按钮信号
	water_button.pressed.connect(_on_water_button_pressed)
	fertilize_button.pressed.connect(_on_fertilize_button_pressed)
	play_music_button.pressed.connect(_on_play_music_button_pressed)
	kill_bug_button.pressed.connect(_on_kill_bug_button_pressed)
	kill_grass_button.pressed.connect(_on_kill_grass_button_pressed)
	revive_button.pressed.connect(_on_revive_button_pressed)
	send_button.pressed.connect(_on_send_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	visibility_changed.connect(_on_visibility_changed)
	
	# 加载智慧树数据
	load_wisdom_tree_data()
	
	# 更新UI显示
	update_ui()

# 加载智慧树数据
func load_wisdom_tree_data():
	if main_game and main_game.login_data.has("智慧树配置"):
		wisdom_tree_config = main_game.login_data["智慧树配置"]


# 更新UI显示
func update_ui():
	# 确保配置数据格式正确，兼容旧格式
	_ensure_config_format()
	
	level.text = "等级: " + str(wisdom_tree_config["等级"])
	var current_health = wisdom_tree_config["当前生命值"]
	var max_health = wisdom_tree_config["最大生命值"]
	health.text = "生命值: " + str(current_health) + "/" + str(max_health)
	var current_exp = wisdom_tree_config["当前经验值"]
	var max_exp = wisdom_tree_config["最大经验值"]
	experience.text = "经验: " + str(current_exp) + "/" + str(max_exp)
	height.text = "高度: " + str(wisdom_tree_config["高度"]) + "cm"
	
	
	# 根据生命值设置颜色
	if current_health <= 0:
		health.modulate = Color.RED
		revive_button.show()
		# 智慧树死亡时禁用其他按钮
		_set_buttons_enabled(false)
	elif current_health <= max_health * 0.3:  # 生命值低于30%
		health.modulate = Color.ORANGE
		revive_button.hide()
	else:
		health.modulate = Color.GREEN
		revive_button.hide()
	
	talk_input.editable = true
	talk_input.placeholder_text = "在这里输入(*´∀ ˋ*)"
	send_button.disabled = false
	send_button.text = "发送"

# 获取下一等级需要的经验
func get_next_level_experience() -> int:
	var current_level = wisdom_tree_config["等级"]
	if current_level >= 20:
		return 99999  # 最大等级
	return calculate_wisdom_tree_max_exp(current_level + 1)

# 设置按钮启用状态
func _set_buttons_enabled(enabled: bool):
	water_button.disabled = !enabled
	fertilize_button.disabled = !enabled
	play_music_button.disabled = !enabled
	kill_bug_button.disabled = !enabled
	kill_grass_button.disabled = !enabled
	send_button.disabled = !enabled

# 显示操作确认弹窗
func show_operation_confirm(operation_type: String, cost: int, description: String):
	if accept_dialog:
		accept_dialog.set_dialog_title("确认操作")
		accept_dialog.set_dialog_content("确定要" + description + "吗？\n费用：" + str(cost) + "金币")
		accept_dialog.show()
		
		# 连接确认信号
		if not accept_dialog.confirmed.is_connected(_on_operation_confirmed):
			accept_dialog.confirmed.connect(_on_operation_confirmed.bind(operation_type))
		else:
			# 断开之前的连接，重新连接
			accept_dialog.confirmed.disconnect(_on_operation_confirmed)
			accept_dialog.confirmed.connect(_on_operation_confirmed.bind(operation_type))

# 操作确认回调
func _on_operation_confirmed(operation_type: String):
	# 发送操作请求到服务器
	tcp_network_manager_panel.send_wisdom_tree_operation(operation_type)

# 浇水按钮
func _on_water_button_pressed():
	show_operation_confirm("water", 100, "给智慧树浇水")

# 施肥按钮
func _on_fertilize_button_pressed():
	show_operation_confirm("fertilize", 200, "给智慧树施肥")

# 除草按钮
func _on_kill_grass_button_pressed():
	show_operation_confirm("kill_grass", 150, "给智慧树除草")

# 杀虫按钮
func _on_kill_bug_button_pressed():
	show_operation_confirm("kill_bug", 150, "给智慧树杀虫")

# 放音乐按钮
func _on_play_music_button_pressed():
	show_operation_confirm("play_music", 100, "给智慧树放音乐")

# 复活按钮
func _on_revive_button_pressed():
	show_operation_confirm("revive", 1000, "复活智慧树")

# 发送消息按钮
func _on_send_button_pressed():
	
	var message = talk_input.text.strip_edges()
	if message.is_empty():
		Toast.show("请输入要发送的消息！", Color.YELLOW)
		return
	
	if message.length() > 50:
		Toast.show("消息长度不能超过50个字符！", Color.RED)
		return
	
	# 发送消息到服务器
	tcp_network_manager_panel.send_wisdom_tree_message(message)
	
	# 清空输入框
	talk_input.text = ""

# 退出按钮
func _on_quit_button_pressed():
	self.hide()

# 处理智慧树操作响应
func handle_wisdom_tree_operation_response(success: bool, message: String, operation_type: String, updated_data: Dictionary):
	if success:
		# 更新智慧树配置
		if updated_data.has("智慧树配置"):
			wisdom_tree_config = updated_data["智慧树配置"]
			# 同步更新MainGame中的智慧树配置
			if main_game and main_game.login_data:
				main_game.login_data["智慧树配置"] = wisdom_tree_config
		
		# 更新玩家数据
		if updated_data.has("钱币"):
			main_game.money = updated_data["钱币"]
			main_game._update_ui()
		
		# 更新智慧树设置面板UI
		update_ui()
		
		# 同步更新MainGame中的智慧树显示
		if main_game.has_method("update_wisdom_tree_display"):
			main_game.update_wisdom_tree_display()
		
		# 根据操作类型显示不同的提示
		match operation_type:
			"water":
				Toast.show("浇水成功！" + message, Color.CYAN)
			"fertilize":
				Toast.show("施肥成功！" + message, Color.PURPLE)
			"kill_grass":
				Toast.show("除草成功！" + message, Color.GREEN)
			"kill_bug":
				Toast.show("杀虫成功！" + message, Color.GREEN)
			"play_music":
				Toast.show("放音乐成功！" + message, Color.MAGENTA)
				# 放音乐时可能获得随机消息，需要特殊处理
				if updated_data.has("random_message"):
					var random_message = updated_data["random_message"]
					if random_message != "":
						# 更新智慧树显示的话
						wisdom_tree_config["智慧树显示的话"] = random_message
						if main_game and main_game.login_data:
							main_game.login_data["智慧树配置"]["智慧树显示的话"] = random_message
						# 再次更新MainGame显示
						if main_game.has_method("update_wisdom_tree_display"):
							main_game.update_wisdom_tree_display()
			"revive":
				Toast.show("智慧树复活成功！", Color.GOLD)
			"get_random_message":
				# 获取随机消息操作
				if updated_data.has("random_message"):
					var random_message = updated_data["random_message"]
					if random_message != "":
						# 更新智慧树显示的话
						wisdom_tree_config["智慧树显示的话"] = random_message
						if main_game and main_game.login_data:
							main_game.login_data["智慧树配置"]["智慧树显示的话"] = random_message
						# 更新MainGame显示
						if main_game.has_method("update_wisdom_tree_display"):
							main_game.update_wisdom_tree_display()
				Toast.show("获得了新的智慧树消息！", Color.MAGENTA)
	else:
		Toast.show(message, Color.RED)

# 处理智慧树消息发送响应
func handle_wisdom_tree_message_response(success: bool, message: String, updated_data: Dictionary = {}):
	if success:
		# 更新玩家金钱
		if updated_data.has("钱币"):
			main_game.money = updated_data["钱币"]
			main_game._update_ui()
		
		Toast.show("消息发送成功！", Color.GREEN)
	else:
		Toast.show(message, Color.RED)


# 面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板打开时主动请求最新的智慧树配置
		if tcp_network_manager_panel and tcp_network_manager_panel.has_method("send_get_wisdom_tree_config"):
			tcp_network_manager_panel.send_get_wisdom_tree_config()
		load_wisdom_tree_data()
		update_ui()
	else:
		GlobalVariables.isZoomDisabled = false

extends Panel

@onready var scare_crow_1: Button = $BuyScareCrowHbox/ScareCrow1 #稻草人类型1
@onready var scare_crow_2: Button = $BuyScareCrowHbox/ScareCrow2 #稻草人类型2
@onready var scare_crow_3: Button = $BuyScareCrowHbox/ScareCrow3 #稻草人类型3
@onready var scare_crow_input: LineEdit = $HBox/ScareCrowInput  #稻草人的昵称
@onready var scare_crow_name_color_input: ColorPickerButton = $HBox/ScareCrowNameColorInput #稻草人昵称的颜色
@onready var talk_1: LineEdit = $ScareCrowTalksGrid/Talk1 #稻草人展示的第一句话
@onready var talk_2: LineEdit = $ScareCrowTalksGrid/Talk2 #稻草人展示的第二句话
@onready var talk_3: LineEdit = $ScareCrowTalksGrid/Talk3 #稻草人展示的第三句话 
@onready var talk_4: LineEdit = $ScareCrowTalksGrid/Talk4 #稻草人展示的第四句话
@onready var quit_button: Button = $QuitButton #关闭面板按钮 
@onready var sure_button: Button = $HBox2/SureButton #确认修改按钮

@onready var color_picker_button_1: ColorPickerButton = $ScareCrowTalksColorGrid/ColorPickerButton1 #第一句话颜色
@onready var color_picker_button_2: ColorPickerButton = $ScareCrowTalksColorGrid/ColorPickerButton2 #第二句话颜色
@onready var color_picker_button_3: ColorPickerButton = $ScareCrowTalksColorGrid/ColorPickerButton3 #第三句话颜色
@onready var color_picker_button_4: ColorPickerButton = $ScareCrowTalksColorGrid/ColorPickerButton4 #第四句话颜色

# 引用主游戏和网络管理器
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'


# 稻草人配置数据
var scare_crow_config = {}
var player_scare_crow_config = {}

# 稻草人按钮数组
var scare_crow_buttons = []

func _ready():
	# 初始化按钮数组
	scare_crow_buttons = [scare_crow_1, scare_crow_2, scare_crow_3]
	
	# 连接信号
	scare_crow_1.pressed.connect(_on_scare_crow_1_pressed)
	scare_crow_2.pressed.connect(_on_scare_crow_2_pressed)
	scare_crow_3.pressed.connect(_on_scare_crow_3_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	sure_button.pressed.connect(_on_sure_button_pressed)
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	# 加载稻草人配置
	load_scare_crow_config()
	
	# 初始化UI
	update_ui()

# 加载稻草人配置
func load_scare_crow_config():
	var file = FileAccess.open("res://Server/config/scare_crow_config.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			scare_crow_config = json.get_data()
			print("稻草人配置加载成功")
		else:
			print("稻草人配置JSON解析失败")
	else:
		print("无法读取稻草人配置文件")

# 更新UI显示
func update_ui():
	if not scare_crow_config.has("稻草人类型"):
		return
		
	# 更新稻草人按钮
	var scare_crow_types = scare_crow_config["稻草人类型"]
	var type_names = ["稻草人1", "稻草人2", "稻草人3"]
	
	for i in range(min(3, scare_crow_buttons.size())):
		var button = scare_crow_buttons[i]
		var type_name = type_names[i]
		
		if scare_crow_types.has(type_name):
			var price = scare_crow_types[type_name]["价格"]
			var is_owned = player_scare_crow_config.get("已拥有稻草人类型", []).has(type_name)
			
			if is_owned:
				button.text = type_name + " (已拥有)"
				button.disabled = false
				button.modulate = Color.GREEN
			else:
				button.text = type_name + " (" + str(price) + "金币)"
				button.disabled = false
				button.modulate = Color.WHITE
		else:
			button.text = "未知类型"
			button.disabled = true
	
	# 更新当前稻草人配置
	if player_scare_crow_config.has("稻草人昵称"):
		scare_crow_input.text = player_scare_crow_config["稻草人昵称"]
	
	# 更新昵称颜色
	if player_scare_crow_config.has("稻草人昵称颜色"):
		scare_crow_name_color_input.color = Color(player_scare_crow_config["稻草人昵称颜色"])
	
	if player_scare_crow_config.has("稻草人说的话"):
		var talks = player_scare_crow_config["稻草人说的话"]
		if talks.has("第一句话"):
			talk_1.text = talks["第一句话"]["内容"]
			color_picker_button_1.color = Color(talks["第一句话"]["颜色"])
		if talks.has("第二句话"):
			talk_2.text = talks["第二句话"]["内容"]
			color_picker_button_2.color = Color(talks["第二句话"]["颜色"])
		if talks.has("第三句话"):
			talk_3.text = talks["第三句话"]["内容"]
			color_picker_button_3.color = Color(talks["第三句话"]["颜色"])
		if talks.has("第四句话"):
			talk_4.text = talks["第四句话"]["内容"]
			color_picker_button_4.color = Color(talks["第四句话"]["颜色"])

# 设置玩家稻草人配置
func set_player_scare_crow_config(config: Dictionary):
	player_scare_crow_config = config
	update_ui()

# 购买/选择稻草人1
func _on_scare_crow_1_pressed():
	handle_scare_crow_selection("稻草人1")

# 购买/选择稻草人2
func _on_scare_crow_2_pressed():
	handle_scare_crow_selection("稻草人2")

# 购买/选择稻草人3
func _on_scare_crow_3_pressed():
	handle_scare_crow_selection("稻草人3")

# 处理稻草人选择
func handle_scare_crow_selection(type_name: String):
	var owned_types = player_scare_crow_config.get("已拥有稻草人类型", [])
	
	if owned_types.has(type_name):
		# 已拥有，选择为当前展示类型
		# 发送修改请求到服务器保存展示类型
		var config_data = {
			"稻草人展示类型": type_name
		}
		
		# 发送修改请求（不需要费用，只是切换展示类型）
		tcp_network_manager_panel.send_modify_scare_crow_config(config_data, 0)
		
		Toast.show("正在切换到" + type_name + "...", Color.CYAN)
	else:
		# 未拥有，购买
		var price = scare_crow_config["稻草人类型"][type_name]["价格"]
		if main_game.money >= price:
			# 发送购买请求
			tcp_network_manager_panel.send_buy_scare_crow(type_name, price)
		else:
			Toast.show("金币不足，需要" + str(price) + "金币", Color.RED)

# 确认修改按钮
func _on_sure_button_pressed():
	# 检查网络连接
	if not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接到服务器", Color.RED)
		return
	
	# 获取修改费用
	var modify_cost = scare_crow_config.get("修改稻草人配置花费", 300)
	
	# 检查金币是否足够
	if main_game.money < modify_cost:
		Toast.show("金币不足，修改配置需要" + str(modify_cost) + "金币", Color.RED)
		return
	
	# 准备配置数据
	var config_data = {
		"稻草人昵称": scare_crow_input.text,
		"稻草人昵称颜色": scare_crow_name_color_input.color.to_html(),
		"稻草人说的话": {
			"第一句话": {
				"内容": talk_1.text,
				"颜色": color_picker_button_1.color.to_html()
			},
			"第二句话": {
				"内容": talk_2.text,
				"颜色": color_picker_button_2.color.to_html()
			},
			"第三句话": {
				"内容": talk_3.text,
				"颜色": color_picker_button_3.color.to_html()
			},
			"第四句话": {
				"内容": talk_4.text,
				"颜色": color_picker_button_4.color.to_html()
			}
		}
	}
	
	# 发送修改请求
	tcp_network_manager_panel.send_modify_scare_crow_config(config_data, modify_cost)

# 关闭面板按钮
func _on_quit_button_pressed():
	hide()

# 处理购买稻草人响应
func handle_buy_scare_crow_response(success: bool, message: String, updated_data: Dictionary):
	if success:
		Toast.show(message, Color.GREEN)
		
		# 更新玩家数据
		if updated_data.has("money"):
			main_game.money = updated_data["money"]
		if updated_data.has("稻草人配置"):
			player_scare_crow_config = updated_data["稻草人配置"]
		
		# 更新UI
		main_game._update_ui()
		update_ui()
		
		# 更新主游戏中的稻草人显示
		if main_game.has_method("update_scare_crow_display"):
			main_game.update_scare_crow_display()
	else:
		Toast.show(message, Color.RED)

# 处理修改稻草人配置响应
func handle_modify_scare_crow_config_response(success: bool, message: String, updated_data: Dictionary):
	if success:
		Toast.show(message, Color.GREEN)
		
		# 更新玩家数据
		if updated_data.has("money"):
			main_game.money = updated_data["money"]
		if updated_data.has("稻草人配置"):
			player_scare_crow_config = updated_data["稻草人配置"]
		
		# 更新UI
		main_game._update_ui()
		update_ui()
		
		# 更新主游戏中的稻草人显示
		if main_game.has_method("update_scare_crow_display"):
			main_game.update_scare_crow_display()
	else:
		Toast.show(message, Color.RED)

# 面板显示时的处理
func _on_visibility_changed():
	if visible:
		# 请求最新的稻草人配置
		if tcp_network_manager_panel.is_connected_to_server():
			tcp_network_manager_panel.send_get_scare_crow_config()
		
		GlobalVariables.isZoomDisabled = true
	else:
		GlobalVariables.isZoomDisabled = false

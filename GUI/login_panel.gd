#玩家登录注册面板
extends PanelContainer

#玩家登录账号，用QQ号代替
@onready var username_input : LineEdit = $VBox/UserName/username_input
#用户登录密码
@onready var password_input : LineEdit = $VBox/Password1/password_input
#登录按钮
@onready var login_button : Button = $VBox/LoginRegister/login_button

#下面是注册相关的
#注册按钮
@onready var register_button : Button = $VBox/LoginRegister/register_button
#注册账号时二次确认密码
@onready var password_input_2 : LineEdit = $VBox/Password2/password_input2
#农场名称
@onready var farmname_input : LineEdit = $VBox/FarmName/farmname_input
#玩家昵称
@onready var playername_input :LineEdit = $VBox/PlayerName/playername_input
#邮箱验证码
@onready var verificationcode_input :LineEdit = $VBox/VerificationCode/verificationcode_input
#发送验证码按钮
@onready var send_button :Button = $VBox/VerificationCode/SendButton
#状态提示标签
@onready var status_label : Label = $VBox/status_label

# 记住密码选项（如果UI中有CheckBox的话）
var remember_password : bool = true  # 默认记住密码

# 引用主场景和全局函数
@onready var main_game = get_node("/root/main")
@onready var land_panel = get_node("/root/main/UI/LandPanel")
@onready var crop_store_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var player_ranking_panel = get_node("/root/main/UI/PlayerRankingPanel")
@onready var player_bag_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var tcp_network_manager = get_node("/root/main/UI/TCPNetworkManager")

# 准备函数
func _ready():
	
	# 连接按钮信号
	login_button.pressed.connect(self._on_login_button_pressed)
	register_button.pressed.connect(self._on_register_button_pressed)
	send_button.pressed.connect(self._on_send_button_pressed)
	
	# 加载保存的登录信息
	_load_login_info()

# 处理登录按钮点击
func _on_login_button_pressed():
	var user_name = username_input.text.strip_edges()  # 修剪前后的空格
	var user_password = password_input.text.strip_edges()
	var farmname = farmname_input.text.strip_edges()
	
	if user_name == "" or user_password == "":
		status_label.text = "用户名或密码不能为空！"
		status_label.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager.client.is_client_connected():
		status_label.text = "未连接到服务器，正在尝试连接..."
		status_label.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager._on_connection_button_pressed()
		await get_tree().create_timer(1.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager.client.is_client_connected():
			status_label.text = "连接服务器失败，请检查网络设置！"
			status_label.modulate = Color.RED
			return
	
	# 禁用按钮，防止重复点击
	login_button.disabled = true
	
	status_label.text = "正在登录，请稍候..."
	status_label.modulate = Color.YELLOW
	
	# 如果启用了记住密码，保存登录信息
	if remember_password:
		_save_login_info(user_name, user_password)
	
	tcp_network_manager.sendLoginInfo(user_name, user_password)

	# 更新主游戏数据
	main_game.user_name = user_name
	main_game.user_password = user_password
	main_game.farmname = farmname
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if login_button.disabled:
		login_button.disabled = false
		status_label.text = "登录超时，请重试！"
		status_label.modulate = Color.RED

# 处理验证码发送按钮点击
func _on_send_button_pressed():
	var user_name = username_input.text.strip_edges()
	
	if user_name == "":
		status_label.text = "请输入QQ号以接收验证码！"
		status_label.modulate = Color.RED
		return
		
	if !is_valid_qq_number(user_name):
		status_label.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager.client.is_client_connected():
		status_label.text = "未连接到服务器，正在尝试连接..."
		status_label.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager._on_connection_button_pressed()
		await get_tree().create_timer(1.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager.client.is_client_connected():
			status_label.text = "连接服务器失败，请检查网络设置！"
			status_label.modulate = Color.RED
			return
	
	# 禁用按钮，防止重复点击
	send_button.disabled = true
	
	status_label.text = "正在发送验证码，请稍候..."
	status_label.modulate = Color.YELLOW
	
	# 发送验证码请求
	tcp_network_manager.sendVerificationCodeRequest(user_name)
	
	# 60秒后重新启用按钮（或收到响应后提前启用）
	var timer = 60
	while timer > 0 and send_button.disabled:
		send_button.text = "重新发送(%d)" % timer
		await get_tree().create_timer(1.0).timeout
		timer -= 1
	
	if send_button.disabled:
		send_button.disabled = false
		send_button.text = "发送验证码"
		
		if status_label.text == "正在发送验证码，请稍候...":
			status_label.text = "验证码发送超时，请重试！"
			status_label.modulate = Color.RED

# 处理注册按钮点击
func _on_register_button_pressed():
	var user_name = username_input.text.strip_edges()
	var user_password = password_input.text.strip_edges()
	var user_password_2 = password_input_2.text.strip_edges()
	var farmname = farmname_input.text.strip_edges()
	var player_name = playername_input.text.strip_edges()
	var verification_code = verificationcode_input.text.strip_edges()
	
	if user_name == "" or user_password == "":
		status_label.text = "用户名或密码不能为空！"
		status_label.modulate = Color.RED
		return
	if farmname == "":
		status_label.text = "农场名称不能为空！"
		status_label.modulate = Color.RED
		return 
	if user_password != user_password_2:
		status_label.text = "两次输入的密码不一致！"
		status_label.modulate = Color.RED
		return 
		
	if !is_valid_qq_number(user_name):
		status_label.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label.modulate = Color.RED
		return
		
	if verification_code == "":
		status_label.text = "请输入验证码！"
		status_label.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager.client.is_client_connected():
		status_label.text = "未连接到服务器，正在尝试连接..."
		status_label.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager._on_connection_button_pressed()
		await get_tree().create_timer(1.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager.client.is_client_connected():
			status_label.text = "连接服务器失败，请检查网络设置！"
			status_label.modulate = Color.RED
			return
	
	# 禁用按钮，防止重复点击
	register_button.disabled = true
	
	status_label.text = "正在注册，请稍候..."
	status_label.modulate = Color.YELLOW
	
	# 发送注册请求
	tcp_network_manager.sendRegisterInfo(user_name, user_password, farmname, player_name, verification_code)
	
	# 更新主游戏数据
	main_game.user_name = user_name
	main_game.user_password = user_password
	main_game.farmname = farmname
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if register_button.disabled:
		register_button.disabled = false
		status_label.text = "注册超时，请重试！"
		status_label.modulate = Color.RED

# 处理验证码发送响应
func _on_verification_code_response(success: bool, message: String):
	if success:
		status_label.text = message
		status_label.modulate = Color.GREEN
	else:
		status_label.text = message
		status_label.modulate = Color.RED
		send_button.disabled = false
		send_button.text = "发送验证码"

# 处理验证码验证响应
func _on_verify_code_response(success: bool, message: String):
	if success:
		status_label.text = message
		status_label.modulate = Color.GREEN
	else:
		status_label.text = message
		status_label.modulate = Color.RED

# 验证QQ号是否有效
func is_valid_qq_number(qq_number: String) -> bool:
	# QQ号的标准格式是5到12位的数字
	var qq_regex = RegEx.new()
	var pattern = r"^\d{5,12}$"
	
	var error = qq_regex.compile(pattern)
	if error != OK:
		status_label.text = "QQ号验证失败部错误"
		status_label.modulate = Color.RED
		return false

	return qq_regex.search(qq_number) != null

# 处理登录响应
func _on_login_response_received(success: bool, message: String, user_data: Dictionary):
	# 启用按钮
	login_button.disabled = false
	
	if success:
		status_label.text = "登录成功！正在加载游戏..."
		status_label.modulate = Color.GREEN
		
		# 更新主游戏数据
		main_game.experience = user_data.get("experience", 0)
		main_game.farm_lots = user_data.get("farm_lots", [])
		main_game.level = user_data.get("level", 1)
		main_game.money = user_data.get("money", 0)
		main_game.farmname = user_data.get("farm_name", "")
		farmname_input.text = user_data.get("farm_name", "")
		
		# 加载玩家背包数据
		if user_data.has("player_bag"):
			main_game.player_bag = user_data.get("player_bag", [])
		else:
			main_game.player_bag = []
		
		main_game.start_game = true
		self.hide()
		
		# 确保在更新数据后调用主游戏的 UI 更新函数
		main_game._update_ui()
		main_game._refresh_farm_lots()
		player_bag_panel.update_player_bag_ui()
	else:
		status_label.text = "登录失败：" + message
		status_label.modulate = Color.RED
		
		# 如果登录失败且是密码错误，可以选择清除保存的信息
		if "密码" in message or "password" in message.to_lower():
			print("登录失败，可能是密码错误。如需清除保存的登录信息，请调用_clear_login_info()")

# 处理注册响应
func _on_register_response_received(success: bool, message: String):
	# 启用按钮
	register_button.disabled = false
	
	if success:
		status_label.text = "注册成功！请登录游戏"
		status_label.modulate = Color.GREEN
		
		# 注册成功后，如果启用了记住密码，保存登录信息
		if remember_password:
			var user_name = username_input.text.strip_edges()
			var user_password = password_input.text.strip_edges()
			_save_login_info(user_name, user_password)
		
		# 清除注册相关的输入框
		password_input_2.text = ""
		verificationcode_input.text = ""
	else:
		status_label.text = "注册失败：" + message
		status_label.modulate = Color.RED

# 保存登录信息到JSON文件
func _save_login_info(user_name: String, password: String):
	var login_data = {
		"user_name": user_name,
		"password": password
	}
	
	var file = FileAccess.open("user://login.json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(login_data, "\t")
		file.store_string(json_string)
		file.close()
		print("登录信息已保存")
	else:
		print("无法保存登录信息")

# 从JSON文件加载登录信息
func _load_login_info():
	var file = FileAccess.open("user://login.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var login_data = json.get_data()
			if login_data.has("user_name") and login_data.has("password"):
				var saved_username = login_data.get("user_name", "")
				var saved_password = login_data.get("password", "")
				
				if saved_username != "" and saved_password != "":
					username_input.text = saved_username
					password_input.text = saved_password
					status_label.text = "已加载保存的登录信息"
					status_label.modulate = Color.CYAN
					print("登录信息已加载：用户名 =", saved_username)
				else:
					status_label.text = "欢迎使用萌芽农场"
					status_label.modulate = Color.WHITE
					print("没有有效的保存登录信息")
			else:
				print("登录信息格式错误")
		else:
			print("登录信息JSON解析错误：", json.get_error_message())
	else:
		# 创建默认的登录信息文件
		_save_login_info("", "")
		status_label.text = "欢迎使用萌芽农场"
		status_label.modulate = Color.WHITE
		print("没有找到保存的登录信息，已创建默认文件")

# 清除保存的登录信息
func _clear_login_info():
	var file = FileAccess.open("user://login.json", FileAccess.WRITE)
	if file:
		var empty_data = {
			"user_name": "",
			"password": ""
		}
		var json_string = JSON.stringify(empty_data, "\t")
		file.store_string(json_string)
		file.close()
		print("登录信息已清除")
	else:
		print("无法清除登录信息")

# 切换记住密码选项
func toggle_remember_password():
	remember_password = !remember_password
	print("记住密码选项：", "开启" if remember_password else "关闭")
	
	# 如果关闭了记住密码，清除已保存的信息
	if not remember_password:
		_clear_login_info()

# 检查是否有保存的登录信息
func has_saved_login_info() -> bool:
	var file = FileAccess.open("user://login.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var login_data = json.get_data()
			var user_name = login_data.get("user_name", "")
			var password = login_data.get("password", "")
			return user_name != "" and password != ""
	
	return false

# 快捷登录（使用保存的登录信息）
func quick_login():
	if has_saved_login_info():
		var user_name = username_input.text.strip_edges()
		var user_password = password_input.text.strip_edges()
		
		if user_name != "" and user_password != "":
			print("执行快捷登录...")
			_on_login_button_pressed()
		else:
			status_label.text = "保存的登录信息不完整"
			status_label.modulate = Color.ORANGE
	else:
		status_label.text = "没有保存的登录信息"
		status_label.modulate = Color.ORANGE

# 获取保存的用户名（用于调试或显示）
func get_saved_username() -> String:
	var file = FileAccess.open("user://login.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var login_data = json.get_data()
			return login_data.get("user_name", "")
	
	return ""

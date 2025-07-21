#玩家登录注册面板
extends PanelContainer

#默认显示登录面板（登录面板可以进入注册面板和忘记密码面板）
@onready var login_v_box: VBoxContainer = $LoginVBox #显示或隐藏登录面板
@onready var user_name: HBoxContainer = $LoginVBox/UserName #玩家账号
@onready var password: HBoxContainer = $LoginVBox/Password #玩家密码
@onready var login_button: Button = $LoginVBox/LoginButton #登录按钮
@onready var register_button: Button = $LoginVBox/RegisterButton #注册按钮，点击后隐藏登录面板显示注册面板
@onready var forget_passwd_button: Button = $LoginVBox/ForgetPasswdButton #忘记密码按钮，点击后隐藏登录面板显示忘记密码面板
@onready var status_label: Label = $LoginVBox/status_label #登录状态

# 登录面板输入框
@onready var username_input: LineEdit = $LoginVBox/UserName/username_input
@onready var password_input: LineEdit = $LoginVBox/Password/password_input

#注册面板，注册成功跳转回登录面板
@onready var register_vbox: VBoxContainer = $RegisterVbox #显示或隐藏注册面板
@onready var register_user_name: HBoxContainer = $RegisterVbox/RegisterUserName #注册玩家账号
@onready var password_1: HBoxContainer = $RegisterVbox/Password1 #注册密码
@onready var password_2: HBoxContainer = $RegisterVbox/Password2 #二次确认密码
@onready var player_name: HBoxContainer = $RegisterVbox/PlayerName #注册玩家昵称
@onready var farm_name: HBoxContainer = $RegisterVbox/FarmName #注册玩家农场名称
@onready var verification_code: HBoxContainer = $RegisterVbox/VerificationCode #注册所需验证码
@onready var register_button_2: Button = $RegisterVbox/RegisterButton2 #注册按钮
@onready var status_label_2: Label = $RegisterVbox/status_label2 #注册状态

# 注册面板输入框
@onready var register_username_input: LineEdit = $RegisterVbox/RegisterUserName/username_input
@onready var password_input_1: LineEdit = $RegisterVbox/Password1/password_input
@onready var password_input_2: LineEdit = $RegisterVbox/Password2/password_input2
@onready var playername_input: LineEdit = $RegisterVbox/PlayerName/playername_input
@onready var farmname_input: LineEdit = $RegisterVbox/FarmName/farmname_input
@onready var verificationcode_input: LineEdit = $RegisterVbox/VerificationCode/verificationcode_input
@onready var send_button: Button = $RegisterVbox/VerificationCode/SendButton

#忘记密码面板，设置新密码成功后同样跳转到登录面板
@onready var forget_password_vbox: VBoxContainer = $ForgetPasswordVbox #显示或隐藏忘记密码面板
@onready var forget_password_user_name: HBoxContainer = $ForgetPasswordVbox/ForgetPasswordUserName #忘记密码的玩家账号
@onready var new_password: HBoxContainer = $ForgetPasswordVbox/NewPassword #设置该账号新的密码
@onready var verification_code_2: HBoxContainer = $ForgetPasswordVbox/VerificationCode2 #忘记密码所需验证码
@onready var forget_password_button: Button = $ForgetPasswordVbox/ForgetPasswordButton #设置新密码确认按钮
@onready var status_label_3: Label = $ForgetPasswordVbox/status_label3 #设置新密码状态

# 忘记密码面板输入框
@onready var forget_username_input: LineEdit = $ForgetPasswordVbox/ForgetPasswordUserName/username_input
@onready var new_password_input: LineEdit = $ForgetPasswordVbox/NewPassword/password_input
@onready var forget_verificationcode_input: LineEdit = $ForgetPasswordVbox/VerificationCode2/verificationcode_input
@onready var forget_send_button: Button = $ForgetPasswordVbox/VerificationCode2/SendButton


# 记住密码选项
var remember_password : bool = true  # 默认记住密码

# 引用主场景和全局函数
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var pet_bag_panel: Panel = $'../PetBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'


# 准备函数
func _ready():
	self.show()
	
	# 初始状态：只显示登录面板，隐藏注册和忘记密码面板
	login_v_box.show()
	register_vbox.hide()
	forget_password_vbox.hide()
	
	# 连接按钮信号
	login_button.pressed.connect(self._on_login_button_pressed)
	register_button.pressed.connect(self._on_show_register_panel)
	forget_passwd_button.pressed.connect(self._on_forget_password_button_pressed)
	register_button_2.pressed.connect(self._on_register_button_2_pressed)
	forget_password_button.pressed.connect(self._on_forget_password_confirm_pressed)
	send_button.pressed.connect(self._on_send_button_pressed)
	forget_send_button.pressed.connect(self._on_forget_send_button_pressed)
	
	# 加载保存的登录信息
	_load_login_info()
	
	# 显示客户端版本号
	_display_version_info()

# 面板切换函数
func _on_show_register_panel():
	"""切换到注册面板"""
	login_v_box.hide()
	register_vbox.show()
	forget_password_vbox.hide()
	status_label_2.text = "请填写注册信息"
	status_label_2.modulate = Color.WHITE

func _on_forget_password_button_pressed():
	"""切换到忘记密码面板"""
	login_v_box.hide()
	register_vbox.hide()
	forget_password_vbox.show()
	status_label_3.text = "请输入账号和新密码"
	status_label_3.modulate = Color.WHITE

# 处理登录按钮点击
func _on_login_button_pressed():
	password_2.hide()
	verification_code.hide()
	player_name.hide()
	farm_name.hide()
	
	
	
	var user_name = username_input.text.strip_edges()  # 修剪前后的空格
	var user_password = password_input.text.strip_edges()
	var farmname = farmname_input.text.strip_edges()
	
	if user_name == "" or user_password == "":
		status_label.text = "用户名或密码不能为空！"
		status_label.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager_panel.client.is_client_connected():
		status_label.text = "未连接到服务器，正在尝试连接..."
		status_label.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager_panel.client.is_client_connected():
			status_label.text = "连接服务器失败，正在尝试其他服务器..."
			status_label.modulate = Color.YELLOW
			# 等待自动服务器切换完成
			await get_tree().create_timer(3.0).timeout
			
	
	# 禁用按钮，防止重复点击
	login_button.disabled = true
	
	status_label.text = "正在登录，请稍候..."
	status_label.modulate = Color.YELLOW
	
	# 如果启用了记住密码，保存登录信息
	if remember_password:
		_save_login_info(user_name, user_password)
	
	tcp_network_manager_panel.sendLoginInfo(user_name, user_password)

	# 更新主游戏数据
	main_game.user_name = user_name
	main_game.user_password = user_password
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if login_button.disabled:
		login_button.disabled = false
		status_label.text = "登录超时，请重试！"
		status_label.modulate = Color.RED

# 处理验证码发送按钮点击
func _on_send_button_pressed():
	var user_name = register_username_input.text.strip_edges()
	
	if user_name == "":
		status_label_2.text = "请输入QQ号以接收验证码！"
		status_label_2.modulate = Color.RED
		return
		
	if !is_valid_qq_number(user_name):
		status_label_2.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label_2.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager_panel.client.is_client_connected():
		status_label_2.text = "未连接到服务器，正在尝试连接..."
		status_label_2.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager_panel.client.is_client_connected():
			status_label_2.text = "连接服务器失败，正在尝试其他服务器..."
			status_label_2.modulate = Color.YELLOW
			# 等待自动服务器切换完成
			await get_tree().create_timer(3.0).timeout
			
	
	# 禁用按钮，防止重复点击
	send_button.disabled = true
	
	status_label_2.text = "正在发送验证码，请稍候..."
	status_label_2.modulate = Color.YELLOW
	
	# 发送验证码请求
	tcp_network_manager_panel.sendVerificationCodeRequest(user_name)
	
	# 60秒后重新启用按钮（或收到响应后提前启用）
	var timer = 60
	while timer > 0 and send_button.disabled:
		send_button.text = "重新发送(%d)" % timer
		await get_tree().create_timer(1.0).timeout
		timer -= 1
	
	if send_button.disabled:
		send_button.disabled = false
		send_button.text = "发送验证码"
		
		if status_label_2.text == "正在发送验证码，请稍候...":
			status_label_2.text = "验证码发送超时，请重试！"
			status_label_2.modulate = Color.RED

# 处理注册按钮点击
func _on_register_button_2_pressed():
	var user_name = register_username_input.text.strip_edges()
	var user_password = password_input_1.text.strip_edges()
	var user_password_2 = password_input_2.text.strip_edges()
	var farmname = farmname_input.text.strip_edges()
	var player_name = playername_input.text.strip_edges()
	var verification_code = verificationcode_input.text.strip_edges()
	
	# 检查密码格式（只允许数字和字母）
	if not is_valid_password(user_password):
		status_label_2.text = "密码只能包含数字和字母！"
		status_label_2.modulate = Color.RED
		return
	
	if user_name == "" or user_password == "":
		status_label_2.text = "用户名或密码不能为空！"
		status_label_2.modulate = Color.RED
		return
	if farmname == "":
		status_label_2.text = "农场名称不能为空！"
		status_label_2.modulate = Color.RED
		return 
	if user_password != user_password_2:
		status_label_2.text = "两次输入的密码不一致！"
		status_label_2.modulate = Color.RED
		return 
		
	if !is_valid_qq_number(user_name):
		status_label_2.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label_2.modulate = Color.RED
		return
		
	if verification_code == "":
		status_label_2.text = "请输入验证码！"
		status_label_2.modulate = Color.RED
		return
		
			# 检查网络连接状态
	if !tcp_network_manager_panel.client.is_client_connected():
		status_label_2.text = "未连接到服务器，正在尝试连接..."
		status_label_2.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager_panel.client.is_client_connected():
			status_label_2.text = "连接服务器失败，正在尝试其他服务器..."
			status_label_2.modulate = Color.YELLOW
			# 等待自动服务器切换完成
			await get_tree().create_timer(3.0).timeout
			
	
	# 禁用按钮，防止重复点击
	register_button_2.disabled = true
	
	status_label_2.text = "正在注册，请稍候..."
	status_label_2.modulate = Color.YELLOW
	
		# 发送注册请求
	tcp_network_manager_panel.sendRegisterInfo(user_name, user_password, farmname, player_name, verification_code)

	# 更新主游戏数据
	main_game.user_name = user_name
	main_game.user_password = user_password
	# farmname 直接在注册成功后通过UI更新，这里不需要设置
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if register_button_2.disabled:
		register_button_2.disabled = false
		status_label_2.text = "注册超时，请重试！"
		status_label_2.modulate = Color.RED

# 忘记密码发送验证码按钮处理
func _on_forget_send_button_pressed():
	var user_name = forget_username_input.text.strip_edges()
	
	if user_name == "":
		status_label_3.text = "请输入QQ号以接收验证码！"
		status_label_3.modulate = Color.RED
		return
		
	if !is_valid_qq_number(user_name):
		status_label_3.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label_3.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager_panel.client.is_client_connected():
		status_label_3.text = "未连接到服务器，正在尝试连接..."
		status_label_3.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager_panel.client.is_client_connected():
			status_label_3.text = "连接服务器失败，正在尝试其他服务器..."
			status_label_3.modulate = Color.YELLOW
			# 等待自动服务器切换完成
			await get_tree().create_timer(3.0).timeout
	
	# 禁用按钮，防止重复点击
	forget_send_button.disabled = true
	
	status_label_3.text = "正在发送验证码，请稍候..."
	status_label_3.modulate = Color.YELLOW
	
	# 发送验证码请求（用于忘记密码）
	tcp_network_manager_panel.sendForgetPasswordVerificationCode(user_name)
	
	# 60秒后重新启用按钮
	var timer = 60
	while timer > 0 and forget_send_button.disabled:
		forget_send_button.text = "重新发送(%d)" % timer
		await get_tree().create_timer(1.0).timeout
		timer -= 1
	
	if forget_send_button.disabled:
		forget_send_button.disabled = false
		forget_send_button.text = "发送验证码"
		
		if status_label_3.text == "正在发送验证码，请稍候...":
			status_label_3.text = "验证码发送超时，请重试！"
			status_label_3.modulate = Color.RED

# 忘记密码确认按钮处理
func _on_forget_password_confirm_pressed():
	var user_name = forget_username_input.text.strip_edges()
	var new_password = new_password_input.text.strip_edges()
	var verification_code = forget_verificationcode_input.text.strip_edges()
	
	# 检查密码格式（只允许数字和字母）
	if not is_valid_password(new_password):
		status_label_3.text = "密码只能包含数字和字母！"
		status_label_3.modulate = Color.RED
		return
	
	if user_name == "" or new_password == "":
		status_label_3.text = "用户名或新密码不能为空！"
		status_label_3.modulate = Color.RED
		return
		
	if !is_valid_qq_number(user_name):
		status_label_3.text = "请输入正确的QQ号码（5-12位数字）！"
		status_label_3.modulate = Color.RED
		return
		
	if verification_code == "":
		status_label_3.text = "请输入验证码！"
		status_label_3.modulate = Color.RED
		return
	
	# 检查网络连接状态
	if !tcp_network_manager_panel.client.is_client_connected():
		status_label_3.text = "未连接到服务器，正在尝试连接..."
		status_label_3.modulate = Color.YELLOW
		# 尝试自动连接到服务器
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		# 再次检查连接状态
		if !tcp_network_manager_panel.client.is_client_connected():
			status_label_3.text = "连接服务器失败，正在尝试其他服务器..."
			status_label_3.modulate = Color.YELLOW
			# 等待自动服务器切换完成
			await get_tree().create_timer(3.0).timeout
	
	# 禁用按钮，防止重复点击
	forget_password_button.disabled = true
	
	status_label_3.text = "正在重置密码，请稍候..."
	status_label_3.modulate = Color.YELLOW
	
	# 发送忘记密码请求
	tcp_network_manager_panel.sendForgetPasswordRequest(user_name, new_password, verification_code)
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if forget_password_button.disabled:
		forget_password_button.disabled = false
		status_label_3.text = "重置密码超时，请重试！"
		status_label_3.modulate = Color.RED

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

# 添加密码验证函数
func is_valid_password(password: String) -> bool:
	# 使用正则表达式检查是否只包含数字和字母
	var pattern = r"^[a-zA-Z0-9]+$"
	return password.match(pattern) != null

# 处理登录响应
func _on_login_response_received(success: bool, message: String, user_data: Dictionary):
	# 启用按钮
	login_button.disabled = false
	
	if success:
		status_label.text = "登录成功！正在加载游戏..."
		status_label.modulate = Color.GREEN
		
		# 保存登录数据到主游戏
		main_game.login_data = user_data.duplicate()
		
		# 保存剩余点赞次数
		main_game.remaining_likes = user_data.get("今日剩余点赞次数", 10)
		
		# 更新主游戏数据
		main_game.experience = user_data.get("experience", 0)
		main_game.farm_lots = user_data.get("farm_lots", [])
		main_game.level = user_data.get("level", 1)
		main_game.money = user_data.get("money", 0)
		main_game.stamina = user_data.get("体力值", 20)
		main_game.show_farm_name.text = "农场名称："+user_data.get("farm_name", "")
		main_game.show_player_name.text = "玩家昵称："+user_data.get("player_name", "")
		farmname_input.text = user_data.get("farm_name", "")
		
		# 加载玩家背包数据
		if user_data.has("player_bag"):
			main_game.player_bag = user_data.get("player_bag", [])
		else:
			main_game.player_bag = []
		
		# 加载作物仓库数据
		if user_data.has("作物仓库"):
			main_game.crop_warehouse = user_data.get("作物仓库", [])
		else:
			main_game.crop_warehouse = []
		
		# 加载道具背包数据
		if user_data.has("道具背包"):
			main_game.item_bag = user_data.get("道具背包", [])
		else:
			main_game.item_bag = []
		
		# 加载宠物背包数据
		if user_data.has("宠物背包"):
			main_game.pet_bag = user_data.get("宠物背包", [])
		else:
			main_game.pet_bag = []
		
		# 加载巡逻宠物数据
		if user_data.has("巡逻宠物"):
			main_game.patrol_pets = user_data.get("巡逻宠物", [])
		else:
			main_game.patrol_pets = []
		
		main_game.start_game = true
		self.hide()
		
		# 确保在更新数据后调用主游戏的 UI 更新函数
		main_game._update_ui()
		main_game._refresh_farm_lots()

		player_bag_panel.update_player_bag_ui()
		# 更新作物仓库和道具背包UI
		crop_warehouse_panel.update_crop_warehouse_ui()
		item_bag_panel.update_item_bag_ui()
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
		# 初始化巡逻宠物
		if main_game.has_method("init_patrol_pets"):
			main_game.init_patrol_pets()
		
		# 调用主游戏的登录成功处理函数
		main_game.handle_login_success(user_data)
		
		# 初始化游戏设置
		if main_game.game_setting_panel and main_game.game_setting_panel.has_method("refresh_settings"):
			main_game.game_setting_panel.refresh_settings()
	else:
		status_label.text = "登录失败：" + message
		status_label.modulate = Color.RED
		
		# 如果登录失败且是密码错误，可以选择清除保存的信息
		if "密码" in message or "password" in message.to_lower():
			print("登录失败，可能是密码错误。如需清除保存的登录信息，请调用_clear_login_info()")

# 处理注册响应
func _on_register_response_received(success: bool, message: String):
	# 启用按钮
	register_button_2.disabled = false
	
	if success:
		status_label_2.text = "注册成功！请登录游戏"
		status_label_2.modulate = Color.GREEN
		
		# 注册成功后，如果启用了记住密码，保存登录信息
		if remember_password:
			var user_name = register_username_input.text.strip_edges()
			var user_password = password_input_1.text.strip_edges()
			_save_login_info(user_name, user_password)
		
		# 清除注册相关的输入框
		password_input_2.text = ""
		verificationcode_input.text = ""
		
		# 切换回登录面板
		register_vbox.hide()
		forget_password_vbox.hide()
		login_v_box.show()
		
		# 如果记住密码，自动填充登录信息
		if remember_password:
			username_input.text = register_username_input.text
			password_input.text = password_input_1.text
	else:
		status_label_2.text = "注册失败：" + message
		status_label_2.modulate = Color.RED

# 处理忘记密码响应
func _on_forget_password_response_received(success: bool, message: String):
	# 启用按钮
	forget_password_button.disabled = false
	
	if success:
		status_label_3.text = "密码重置成功！请使用新密码登录"
		status_label_3.modulate = Color.GREEN
		
		# 保存新的登录信息
		if remember_password:
			var user_name = forget_username_input.text.strip_edges()
			var new_password = new_password_input.text.strip_edges()
			_save_login_info(user_name, new_password)
		
		# 清除输入框
		forget_verificationcode_input.text = ""
		
		# 切换回登录面板并自动填充账号信息
		forget_password_vbox.hide()
		register_vbox.hide()
		login_v_box.show()
		
		# 自动填充登录信息
		username_input.text = forget_username_input.text
		password_input.text = new_password_input.text
		
		status_label.text = "密码已重置，请登录"
		status_label.modulate = Color.GREEN
	else:
		status_label_3.text = "密码重置失败：" + message
		status_label_3.modulate = Color.RED

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

# 显示版本信息
func _display_version_info():
	# 在状态标签中显示客户端版本信息
	if status_label.text == "欢迎使用萌芽农场" or status_label.text == "连接状态":
		status_label.text = "萌芽农场 v" + main_game.client_version + " - 欢迎使用"
		status_label.modulate = Color.CYAN


#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

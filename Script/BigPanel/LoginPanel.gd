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
	var user_name = username_input.text.strip_edges()
	var user_password = password_input.text.strip_edges()
	
	# 验证输入
	if not _validate_login_input(user_name, user_password, status_label):
		return
	
	# 检查网络连接
	if not await _ensure_network_connection(status_label):
		return
			
	
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
	
	# 验证输入
	if not _validate_qq_input(user_name, status_label_2):
		return
	
	# 检查网络连接
	if not await _ensure_network_connection(status_label_2):
		return
			
	
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
	var password_confirm = password_input_2.text.strip_edges()
	var player_name = playername_input.text.strip_edges()
	var farm_name = farmname_input.text.strip_edges()
	var verification_code = verificationcode_input.text.strip_edges()
	
	# 验证输入
	if not _validate_register_input(user_name, user_password, password_confirm, player_name, farm_name, verification_code, status_label_2):
		return
	
	# 检查网络连接
	if not await _ensure_network_connection(status_label_2):
		return
	
	# 禁用按钮，防止重复点击
	register_button_2.disabled = true
	
	status_label_2.text = "正在注册，请稍候..."
	status_label_2.modulate = Color.YELLOW
	
	# 发送注册请求
	tcp_network_manager_panel.sendRegisterInfo(user_name, user_password, player_name, farm_name, verification_code)
	
	# 5秒后重新启用按钮（如果没有收到响应）
	await get_tree().create_timer(5.0).timeout
	if register_button_2.disabled:
		register_button_2.disabled = false
		status_label_2.text = "注册超时，请重试！"
		status_label_2.modulate = Color.RED

# 忘记密码发送验证码按钮处理
func _on_forget_send_button_pressed():
	var user_name = forget_username_input.text.strip_edges()
	
	# 验证输入
	if not _validate_qq_input(user_name, status_label_3):
		return
	
	# 检查网络连接
	if not await _ensure_network_connection(status_label_3):
		return
	
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
	
	# 验证输入
	if not _validate_forget_password_input(user_name, new_password, verification_code, status_label_3):
		return
	
	# 检查网络连接
	if not await _ensure_network_connection(status_label_3):
		return
	
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
	_set_status(status_label, message, Color.GREEN if success else Color.RED)
	if not success:
		send_button.disabled = false
		send_button.text = "发送验证码"

# 处理验证码验证响应
func _on_verify_code_response(success: bool, message: String):
	_set_status(status_label, message, Color.GREEN if success else Color.RED)

# 输入验证函数
func is_valid_qq_number(qq_number: String) -> bool:
	var qq_regex = RegEx.new()
	if qq_regex.compile(r"^\d{5,12}$") != OK:
		return false
	return qq_regex.search(qq_number) != null

func is_valid_password(password: String) -> bool:
	return password.match(r"^[a-zA-Z0-9]+$") != null

# 处理登录响应
func _on_login_response_received(success: bool, message: String, user_data: Dictionary):
	login_button.disabled = false
	
	if success:
		_set_status(status_label, "登录成功！正在加载游戏...", Color.GREEN)
		_handle_login_success(user_data)
	else:
		_set_status(status_label, "登录失败：" + message, Color.RED)
		if "密码" in message or "password" in message.to_lower():
			print("登录失败，可能是密码错误。如需清除保存的登录信息，请调用_clear_login_info()")

# 处理注册响应
func _on_register_response_received(success: bool, message: String):
	register_button_2.disabled = false
	
	if success:
		_set_status(status_label_2, "注册成功！请登录游戏", Color.GREEN)
		_handle_register_success()
	else:
		_set_status(status_label_2, "注册失败：" + message, Color.RED)

# 处理忘记密码响应
func _on_forget_password_response_received(success: bool, message: String):
	forget_password_button.disabled = false
	
	if success:
		_set_status(status_label_3, "密码重置成功！请使用新密码登录", Color.GREEN)
		_handle_forget_password_success()
	else:
		_set_status(status_label_3, "密码重置失败：" + message, Color.RED)

# 登录信息文件操作
func _save_login_info(user_name: String, password: String):
	_write_login_file({"玩家账号": user_name, "password": password})
	print("登录信息已保存" if user_name != "" else "登录信息已清除")

func _load_login_info():
	var login_data = _read_login_file()
	if login_data:
		var saved_username = login_data.get("玩家账号", "")
		var saved_password = login_data.get("password", "")
		
		if saved_username != "" and saved_password != "":
			username_input.text = saved_username
			password_input.text = saved_password
			_set_status(status_label, "已加载保存的登录信息", Color.CYAN)
			print("登录信息已加载：用户名 =", saved_username)
			return
	
	_set_status(status_label, "欢迎使用萌芽农场", Color.WHITE)
	print("没有有效的保存登录信息")

func _clear_login_info():
	_save_login_info("", "")

func _write_login_file(data: Dictionary):
	var file = FileAccess.open("user://login.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _read_login_file() -> Dictionary:
	var file = FileAccess.open("user://login.json", FileAccess.READ)
	if not file:
		_write_login_file({"玩家账号": "", "password": ""})
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) == OK:
		return json.get_data()
	return {}

# 记住密码和快捷登录功能
func toggle_remember_password():
	remember_password = !remember_password
	print("记住密码选项：", "开启" if remember_password else "关闭")
	if not remember_password:
		_clear_login_info()

func has_saved_login_info() -> bool:
	var login_data = _read_login_file()
	return login_data.get("玩家账号", "") != "" and login_data.get("password", "") != ""

func quick_login():
	if has_saved_login_info():
		var user_name = username_input.text.strip_edges()
		var user_password = password_input.text.strip_edges()
		
		if user_name != "" and user_password != "":
			print("执行快捷登录...")
			_on_login_button_pressed()
		else:
			_set_status(status_label, "保存的登录信息不完整", Color.ORANGE)
	else:
		_set_status(status_label, "没有保存的登录信息", Color.ORANGE)

func get_saved_username() -> String:
	return _read_login_file().get("玩家账号", "")

# 显示版本信息
func _display_version_info():
	if status_label.text in ["欢迎使用萌芽农场", "连接状态"]:
		_set_status(status_label, "萌芽农场 v" + main_game.client_version + " - 欢迎使用", Color.CYAN)


# 登录成功处理
func _handle_login_success(user_data: Dictionary):
	# 保存登录数据到主游戏
	main_game.login_data = user_data.duplicate()
	main_game.remaining_likes = user_data.get("点赞系统", {}).get("今日剩余点赞次数", 10)
	
	# 更新主游戏数据
	main_game.experience = user_data.get("经验值", 0)
	main_game.farm_lots = user_data.get("农场土地", [])
	main_game.level = user_data.get("等级", 1)
	main_game.money = user_data.get("钱币", 0)
	main_game.stamina = user_data.get("体力值", 20)
	main_game.show_farm_name.text = "农场名称：" + user_data.get("农场名称", "")
	main_game.show_player_name.text = "玩家昵称：" + user_data.get("玩家昵称", "")
	farmname_input.text = user_data.get("农场名称", "")
	
	# 加载各种背包数据
	main_game.player_bag = user_data.get("种子仓库", [])
	main_game.crop_warehouse = user_data.get("作物仓库", [])
	main_game.item_bag = user_data.get("道具背包", [])
	main_game.pet_bag = user_data.get("宠物背包", [])
	main_game.patrol_pets = user_data.get("巡逻宠物", [])
	
	# 启动游戏并隐藏登录面板
	main_game.start_game = true
	self.hide()
	
	# 更新UI
	main_game._update_ui()
	main_game._refresh_farm_lots()
	player_bag_panel.update_player_bag_ui()
	crop_warehouse_panel.update_crop_warehouse_ui()
	item_bag_panel.update_item_bag_ui()
	
	if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
		pet_bag_panel.update_pet_bag_ui()
	if main_game.has_method("init_patrol_pets"):
		main_game.init_patrol_pets()
	
	main_game.handle_login_success(user_data)
	
	if main_game.game_setting_panel and main_game.game_setting_panel.has_method("refresh_settings"):
		main_game.game_setting_panel.refresh_settings()

# 注册成功处理
func _handle_register_success():
	if remember_password:
		var user_name = register_username_input.text.strip_edges()
		var user_password = password_input_1.text.strip_edges()
		_save_login_info(user_name, user_password)
	
	# 清除注册相关的输入框
	password_input_2.text = ""
	verificationcode_input.text = ""
	
	# 切换回登录面板
	_switch_to_login_panel()
	
	# 如果记住密码，自动填充登录信息
	if remember_password:
		username_input.text = register_username_input.text
		password_input.text = password_input_1.text

# 忘记密码成功处理
func _handle_forget_password_success():
	if remember_password:
		var user_name = forget_username_input.text.strip_edges()
		var new_password = new_password_input.text.strip_edges()
		_save_login_info(user_name, new_password)
	
	# 清除输入框
	forget_verificationcode_input.text = ""
	
	# 切换回登录面板并自动填充账号信息
	_switch_to_login_panel()
	username_input.text = forget_username_input.text
	password_input.text = new_password_input.text
	_set_status(status_label, "密码已重置，请登录", Color.GREEN)

# 切换到登录面板
func _switch_to_login_panel():
	register_vbox.hide()
	forget_password_vbox.hide()
	login_v_box.show()

# 公共验证函数
func _validate_login_input(user_name: String, password: String, label: Label) -> bool:
	if user_name.is_empty() or password.is_empty():
		_set_status(label, "用户名或密码不能为空！", Color.RED)
		return false
	return true

func _validate_register_input(user_name: String, password: String, password_confirm: String, player_name: String, farm_name: String, verification_code: String, label: Label) -> bool:
	if user_name.is_empty() or password.is_empty() or password_confirm.is_empty() or player_name.is_empty() or farm_name.is_empty():
		_set_status(label, "所有字段都不能为空！", Color.RED)
		return false
	if password != password_confirm:
		_set_status(label, "两次输入的密码不一致！", Color.RED)
		return false
	if not is_valid_qq_number(user_name):
		_set_status(label, "请输入有效的QQ号（5-12位数字）！", Color.RED)
		return false
	if not is_valid_password(password):
		_set_status(label, "密码只能包含数字和字母！", Color.RED)
		return false
	if verification_code.is_empty():
		_set_status(label, "验证码不能为空！", Color.RED)
		return false
	return true

func _validate_qq_input(user_name: String, label: Label) -> bool:
	if user_name.is_empty():
		_set_status(label, "请输入QQ号以接收验证码！", Color.RED)
		return false
	if not is_valid_qq_number(user_name):
		_set_status(label, "请输入正确的QQ号码（5-12位数字）！", Color.RED)
		return false
	return true

func _validate_forget_password_input(user_name: String, new_password: String, verification_code: String, label: Label) -> bool:
	if user_name.is_empty() or new_password.is_empty():
		_set_status(label, "用户名或新密码不能为空！", Color.RED)
		return false
	if not is_valid_qq_number(user_name):
		_set_status(label, "请输入正确的QQ号码（5-12位数字）！", Color.RED)
		return false
	if not is_valid_password(new_password):
		_set_status(label, "密码只能包含数字和字母！", Color.RED)
		return false
	if verification_code.is_empty():
		_set_status(label, "请输入验证码！", Color.RED)
		return false
	return true

# 公共网络连接检查函数
func _ensure_network_connection(label: Label) -> bool:
	if not tcp_network_manager_panel.client.is_client_connected():
		_set_status(label, "未连接到服务器，正在尝试连接...", Color.YELLOW)
		tcp_network_manager_panel.connect_to_current_server()
		await get_tree().create_timer(2.0).timeout
		
		if not tcp_network_manager_panel.client.is_client_connected():
			_set_status(label, "连接服务器失败，正在尝试其他服务器...", Color.YELLOW)
			await get_tree().create_timer(3.0).timeout
			return false
	return true

# 公共状态设置函数
func _set_status(label: Label, text: String, color: Color):
	label.text = text
	label.modulate = color

#面板显示与隐藏切换处理
func _on_visibility_changed():
	GlobalVariables.isZoomDisabled = visible

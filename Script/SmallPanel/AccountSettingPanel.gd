extends Panel

@onready var user_name_input: Label = $VBox1/Grid/User_Name_Input			#用户名/账号名
@onready var user_password_input: LineEdit = $VBox1/Grid/User_Password_Input#账号密码
@onready var player_name_input: LineEdit = $VBox1/Grid/Player_Name_Input	#玩家昵称
@onready var farm_name_input: LineEdit = $VBox1/Grid/Farm_Name_Input		#农场名称
@onready var personal_profile_input: LineEdit = $VBox1/Grid/Personal_Profile_Input#个人简介

@onready var remove_account_btn: Button = $VBox1/HBox2/Remove_Account_Btn	#删除账号按钮
@onready var confirm_btn: Button = $VBox1/HBox2/Confirm_Btn					#修改账号信息按钮

@onready var quit_button: Button = $QuitButton		#关闭玩家信息面板按钮
@onready var refresh_button: Button = $RefreshButton#刷新玩家信息按钮

#预添加常用的面板和组件
@onready var main_game = get_node("/root/main")

@onready var accept_dialog: AcceptDialog = $'../../DiaLog/AcceptDialog'
@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'

# 存储待执行的操作类型
var pending_action = ""

func _ready() -> void:
	# 连接按钮信号
	quit_button.pressed.connect(_on_quit_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	confirm_btn.pressed.connect(_on_confirm_btn_pressed)
	remove_account_btn.pressed.connect(_on_remove_account_btn_pressed)
	
	# 初始显示界面数据
	_refresh_player_info()
	
	# 如果有网络连接，自动请求最新数据（延迟一秒等待初始化完成）
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("is_connected_to_server") and tcp_network_manager_panel.is_connected_to_server():
		await get_tree().create_timer(1.0).timeout
		_request_player_info_from_server()


func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass


#关闭玩家信息面板按钮点击
func _on_quit_button_pressed() -> void:
	self.hide()

#刷新玩家信息按钮点击
func _on_refresh_button_pressed() -> void:
	# 向服务器请求最新的玩家数据
	_request_player_info_from_server()

#向服务器请求玩家信息
func _request_player_info_from_server():
	if not tcp_network_manager_panel:
		_show_message("网络管理器不可用", Color.RED)
		return
	
	if not tcp_network_manager_panel.is_connected_to_server():
		_show_message("未连接到服务器", Color.RED)
		return
	
	# 发送刷新请求到服务器
	var message = {
		"type": "refresh_player_info"
	}
	
	var success = tcp_network_manager_panel.send_message(message)
	if success:
		_show_message("正在刷新玩家信息...", Color.YELLOW)
	else:
		_show_message("发送刷新请求失败", Color.RED)

#确认修改按钮点击
func _on_confirm_btn_pressed() -> void:
	# 显示二次确认对话框
	pending_action = "modify_account"
	if accept_dialog:
		accept_dialog.dialog_text = "确认要修改账号信息吗？这些更改将立即生效。"
		accept_dialog.title = "确认修改"
		accept_dialog.show()
		# 连接确认信号
		if not accept_dialog.confirmed.is_connected(_on_accept_dialog_confirmed):
			accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)

#删除账号按钮点击
func _on_remove_account_btn_pressed() -> void:
	# 显示二次确认对话框
	pending_action = "delete_account"
	if accept_dialog:
		accept_dialog.dialog_text = "警告：删除账号将永久移除您的所有数据，包括农场、作物、背包等所有内容。\n此操作无法撤销，确认要删除账号吗？"
		accept_dialog.title = "删除账号确认"
		accept_dialog.show()
		# 连接确认信号
		if not accept_dialog.confirmed.is_connected(_on_accept_dialog_confirmed):
			accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)

#确认对话框的确认按钮被点击
func _on_accept_dialog_confirmed() -> void:
	match pending_action:
		"modify_account":
			_modify_account_info()
		"delete_account":
			_delete_account()
	
	# 重置待执行操作
	pending_action = ""
	
	# 断开信号连接
	if accept_dialog and accept_dialog.confirmed.is_connected(_on_accept_dialog_confirmed):
		accept_dialog.confirmed.disconnect(_on_accept_dialog_confirmed)

#修改账号信息
func _modify_account_info():
	if not tcp_network_manager_panel:
		_show_message("网络管理器不可用", Color.RED)
		return
	
	if not tcp_network_manager_panel.is_connected_to_server():
		_show_message("未连接到服务器", Color.RED)
		return
	
	# 获取输入的信息
	var new_password = user_password_input.text.strip_edges()
	var new_player_name = player_name_input.text.strip_edges()
	var new_farm_name = farm_name_input.text.strip_edges()
	var new_personal_profile = personal_profile_input.text.strip_edges()
	
	# 验证输入
	if new_password == "":
		_show_message("密码不能为空", Color.RED)
		return
	
	if new_player_name == "":
		_show_message("玩家昵称不能为空", Color.RED)
		return
	
	if new_farm_name == "":
		_show_message("农场名称不能为空", Color.RED)
		return
	
	# 发送修改请求到服务器
	var message = {
		"type": "modify_account_info",
		"new_password": new_password,
		"new_player_name": new_player_name,
		"new_farm_name": new_farm_name,
		"new_personal_profile": new_personal_profile
	}
	
	var success = tcp_network_manager_panel.send_message(message)
	if success:
		_show_message("正在更新账号信息...", Color.YELLOW)
	else:
		_show_message("发送修改请求失败", Color.RED)

#删除账号
func _delete_account():
	if not tcp_network_manager_panel:
		_show_message("网络管理器不可用", Color.RED)
		return
	
	if not tcp_network_manager_panel.is_connected_to_server():
		_show_message("未连接到服务器", Color.RED)
		return
	
	# 发送删除账号请求到服务器
	var message = {
		"type": "delete_account"
	}
	
	var success =tcp_network_manager_panel.send_message(message)
	if success:
		_show_message("正在删除账号...", Color.YELLOW)
	else:
		_show_message("发送删除请求失败", Color.RED)

#刷新玩家信息显示（从本地数据）
func _refresh_player_info():
	# 从主游戏获取当前玩家信息
	user_name_input.text = main_game.user_name if main_game.user_name != "" else "未知"
	user_password_input.text = main_game.user_password if main_game.user_password != "" else ""
	
	# 优先从 login_data 获取数据，如果没有则从 data 获取
	var player_data = main_game.login_data if main_game.login_data.size() > 0 else main_game.data
	
	player_name_input.text = player_data.get("player_name", "")
	farm_name_input.text = player_data.get("farm_name", "")
	personal_profile_input.text = player_data.get("个人简介", "")
	

#显示消息提示
func _show_message(message: String, color: Color):
	if main_game and main_game.has_method("show_message"):
		main_game.show_message(message, color)
	else:
		pass

#处理服务器响应
func handle_account_response(response_data: Dictionary):
	var message_type = response_data.get("type", "")
	var success = response_data.get("success", false)
	var message = response_data.get("message", "")
	
	match message_type:
		"modify_account_info_response":
			if success:
				_show_message(message, Color.GREEN)
				# 更新本地数据
				if response_data.has("updated_data"):
					var updated_data = response_data["updated_data"]
					if main_game:
						if updated_data.has("player_name"):
							main_game.data["player_name"] = updated_data["player_name"]
						if updated_data.has("farm_name"):
							main_game.data["farm_name"] = updated_data["farm_name"]
						if updated_data.has("个人简介"):
							main_game.data["个人简介"] = updated_data["个人简介"]
						if updated_data.has("user_password"):
							main_game.user_password = updated_data["user_password"]
				
				# 刷新显示
				_refresh_player_info()
			else:
				_show_message(message, Color.RED)
		
		"delete_account_response":
			if success:
				_show_message(message, Color.GREEN)
				# 等待2秒后返回主菜单
				await get_tree().create_timer(2.0).timeout
				get_tree().change_scene_to_file("res://GUI/MainMenuPanel.tscn")
			else:
				_show_message(message, Color.RED)
		
		"refresh_player_info_response":
			if success:
				# 主游戏已经更新了数据，直接刷新显示即可
				_refresh_player_info()
				_show_message("玩家信息已刷新", Color.GREEN)
			else:
				_show_message(message if message != "" else "刷新失败", Color.RED)

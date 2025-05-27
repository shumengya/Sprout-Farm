extends Panel

# TCP客户端演示
# 这个脚本展示如何在UI中使用TCPClient类

# UI组件引用
@onready var status_label = $StatusLabel
@onready var message_input = $MessageInput
@onready var send_button = $SendButton
@onready var response_label = $Scroll/ResponseLabel
@onready var connection_button = $ConnectionButton
@onready var login_panel = $"/root/main/UI/LoginPanel"
@onready var main_game = get_node("/root/main")

# TCP客户端
var client: TCPClient = TCPClient.new()

# 服务器配置 - 支持多个服务器地址
var server_configs = [
	#{"host": "127.0.0.1", "port": 4040, "name": "本地服务器"},
	#{"host": "192.168.1.110", "port": 4040, "name": "局域网服务器"},
	{"host": "47.108.90.0", "port": 4040, "name": "公网服务器"}#成都内网穿透
]

var current_server_index = 0
var auto_retry = true
var retry_delay = 3.0

func _ready():
	# 创建TCP客户端实例
	self.add_child(client)
	
	# 连接信号
	client.connected_to_server.connect(_on_connected)
	client.connection_failed.connect(_on_connection_failed)
	client.connection_closed.connect(_on_connection_closed)
	client.data_received.connect(_on_data_received)
	
	# 连接按钮事件
	connection_button.pressed.connect(_on_connection_button_pressed)
	send_button.pressed.connect(_on_send_button_pressed)
	
	# 初始设置
	status_label.text = "未连接"
	response_label.text = "等待响应..."
	connection_button.text = "连接"

func _on_connected():
	status_label.text = "已连接"
	status_label.modulate = Color.GREEN
	connection_button.text = "断开"
	
	# 发送连接成功消息
	client.send_data({
		"type": "greeting", 
		"content": "你好，服务器！"
	})
	
	# 连接成功后立即请求作物数据
	print("连接成功，正在请求最新作物数据...")
	sendGetCropData()

func _on_connection_failed():
	status_label.text = "连接失败"
	status_label.modulate = Color.RED
	connection_button.text = "连接"
	
	# 自动尝试下一个服务器
	if auto_retry:
		try_next_server()

func _on_connection_closed():
	status_label.text = "连接断开"
	status_label.modulate = Color.RED
	connection_button.text = "连接"
	
	# 自动重连当前服务器
	if auto_retry:
		var timer = get_tree().create_timer(retry_delay)
		await timer.timeout
		if not client.is_client_connected():
			_on_connection_button_pressed()

func _on_data_received(data):
	# 根据数据类型处理数据
	response_label.text = "收到: %s" % JSON.stringify(data)
	match typeof(data):

		TYPE_DICTIONARY:
			# 处理JSON对象
			var message_type = data.get("type", "")
			
			match message_type:
				"ping":	
					return
				"response":
					# 显示服务器响应
					if data.has("original"):
						var original = data.get("original", {})
					return
				"login_response":
					# 处理登录响应
					var status = data.get("status", "")
					var message = data.get("message", "")
					var player_data = data.get("player_data", {})
					if login_panel:
						# 调用登录面板的响应处理方法
						login_panel._on_login_response_received(status == "success", message, player_data)
				"register_response":
					# 处理注册响应
					var status = data.get("status", "")
					var message = data.get("message", "")
					if login_panel:
						# 调用登录面板的响应处理方法
						login_panel._on_register_response_received(status == "success", message)
				"verification_code_response":
					# 处理验证码发送响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					if login_panel:
						# 调用登录面板的验证码响应处理方法
						login_panel._on_verification_code_response(success, message)
				"verify_code_response":
					# 处理验证码验证响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					if login_panel:
						# 调用登录面板的验证码验证响应处理方法
						login_panel._on_verify_code_response(success, message)
				"crop_update":
					# 处理作物生长更新
					if main_game:
						main_game._handle_crop_update(data)
				"action_response":
					# 处理玩家动作响应
					if main_game:
						main_game._handle_action_response(data)
				"play_time_response":
					# 处理玩家游玩时间响应
					if main_game and main_game.has_method("_handle_play_time_response"):
						main_game._handle_play_time_response(data)
				"player_rankings_response":
					# 处理玩家排行榜响应
					if main_game and main_game.has_method("_handle_player_rankings_response"):
						main_game._handle_player_rankings_response(data)
				"crop_data_response":
					# 处理作物数据响应
					if main_game and main_game.has_method("_handle_crop_data_response"):
						main_game._handle_crop_data_response(data)
				"visit_player_response":
					# 处理访问玩家响应
					if main_game and main_game.has_method("_handle_visit_player_response"):
						main_game._handle_visit_player_response(data)
				"return_my_farm_response":
					# 处理返回自己农场响应
					if main_game and main_game.has_method("_handle_return_my_farm_response"):
						main_game._handle_return_my_farm_response(data)
				_:
					# 显示其他类型的消息
					return
		_:
			# 处理非JSON数据
			return

func _on_connection_button_pressed():
	if client.is_client_connected():
		# 断开连接
		client.disconnect_from_server()
	else:
		# 连接服务器
		status_label.text = "正在连接..."
		client.connect_to_server(server_configs[current_server_index]["host"], server_configs[current_server_index]["port"])

func _on_send_button_pressed():
	if not client.is_client_connected():
		status_label.text = "未连接，无法发送"
		return
	
	# 获取输入文本
	var text = message_input.text.strip_edges()
	if text.is_empty():
		return
	
	# 发送消息
	client.send_data({
		"type": "message",
		"content": text,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# 清空输入
	message_input.text = "" 

#发送登录信息
func sendLoginInfo(username, password):
	client.send_data({
		"type": "login",
		"username": username,
		"password": password
	})

#发送注册信息
func sendRegisterInfo(username, password, farmname, player_name="", verification_code=""):
	client.send_data({
		"type": "register",
		"username": username,
		"password": password,
		"farm_name": farmname,
		"player_name": player_name,
		"verification_code": verification_code
	})

#发送收获作物信息
func sendHarvestCrop(lot_index):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "harvest_crop",
		"lot_index": lot_index,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送种植作物信息
func sendPlantCrop(lot_index, crop_name):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "plant_crop",
		"lot_index": lot_index,
		"crop_name": crop_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送开垦土地信息
func sendDigGround(lot_index):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "dig_ground",
		"lot_index": lot_index,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买种子信息
func sendBuySeed(crop_name):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_seed",
		"crop_name": crop_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取游玩时间请求
func sendGetPlayTime():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_play_time"
	})
	return true

#发送更新游玩时间请求
func sendUpdatePlayTime():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "update_play_time"
	})
	return true

#发送获取玩家排行榜请求
func sendGetPlayerRankings():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_player_rankings"
	})
	return true

#发送验证码请求
func sendVerificationCodeRequest(qq_number):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_verification_code",
		"qq_number": qq_number,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送验证码验证
func sendVerifyCode(qq_number, code):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "verify_code",
		"qq_number": qq_number,
		"code": code,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取作物数据请求
func sendGetCropData():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_crop_data"
	})
	return true

#发送访问玩家请求
func sendVisitPlayer(target_username):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "visit_player",
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送返回自己农场请求
func sendReturnMyFarm():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "return_my_farm",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#检查是否连接到服务器
func is_connected_to_server():
	return client.is_client_connected()

# 尝试连接下一个服务器
func try_next_server():
	current_server_index = (current_server_index + 1) % server_configs.size()
	var config = server_configs[current_server_index]
	
	status_label.text = "尝试连接 " + config["name"]
	print("尝试连接服务器: ", config["name"], " (", config["host"], ":", config["port"], ")")
	
	var timer = get_tree().create_timer(retry_delay)
	await timer.timeout
	
	if not client.is_client_connected():
		client.connect_to_server(config["host"], config["port"])

# 检查网络连接状态
func check_network_status():
	# 检查设备是否有网络连接
	if OS.get_name() == "Android":
		# 在Android上检查网络状态
		status_label.text = "检查网络状态..."
		
	# 尝试连接到当前配置的服务器
	if not client.is_client_connected():
		_on_connection_button_pressed()

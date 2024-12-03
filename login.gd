extends Node

var http_request: HTTPRequest
var farm_lots = []

@onready var harvest = $harvest
@onready var label1 = $Label
@onready var username_input = $Panel/username_input
@onready var password_input = $Panel/password_input
@onready var login_button = $Panel/login_button
@onready var panel = $Panel
@onready var item_list = $item_list #ItemList

func _ready():
	# 创建 HTTPRequest 节点
	http_request = HTTPRequest.new()
	add_child(http_request)
	# 连接信号
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))	
	# 连接登录按钮点击事件
	login_button.connect("pressed", Callable(self, "_on_login_button_pressed"))

# 登录按钮按下事件
func _on_login_button_pressed():
	# 隐藏面板（只有在输入后才进行隐藏）
	panel.hide()

	# 获取用户名和密码输入
	var username = username_input.text  # 直接获取输入
	var password = password_input.text  # 直接获取输入

	# 打印调试信息
	print("Username entered: ", username)
	print("Password entered: ", password)
	
	# 检查用户名和密码是否为空
	if username == "" or password == "":
		print("用户名和密码不能为空")
		panel.show()  # 如果输入为空，显示面板
		return
	
	# 构建登录请求的 URL 和参数
	var url = "https://api.shumengya.top/smyfarm/login.php"
	var body = {
		"username": username,
		"password": password
	}
	
	# 发送 POST 请求进行登录
	var err = http_request.request(url, [], HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		print("Error making HTTP POST request: ", err)

# 请求完成后的回调函数
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result != OK:
			print("Error parsing JSON: ", json.get_error_message())
			return
		
		var json_data = json.data
		
		if json_data.has("error"):
			print("Error: " + str(json_data["error"]))
			panel.show()  # 如果登录失败，显示面板，允许重新输入
		elif json_data.has("message"):
			print(json_data["message"])
			
			# 处理登录成功
			if json_data.has("data"):
				var player_data = json_data["data"]
				print("欢迎, " + player_data["username"])
				
				# 加载玩家数据，进入游戏逻辑
				_load_player_data(player_data)
	else:
		print("HTTP Request failed with response code: " + str(response_code))
		panel.show()  # 请求失败，重新显示面板

# 加载玩家数据
func _load_player_data(player_data):
	# 根据返回的 player_data 初始化玩家的农场状态等
	pass
	

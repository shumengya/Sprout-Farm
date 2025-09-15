extends Panel
@onready var message_contents: RichTextLabel = $MessageContents #显示历史消息
@onready var input_message: LineEdit = $HBox/InputMessage #输入要发送的消息 
@onready var send_message_button: Button = $HBox/SendMessageButton #发送消息按钮
@onready var quit_button: Button = $QuitButton
@onready var watch_more_button: Button = $WatchMoreButton

# 获取主游戏和网络管理器的引用
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel = get_node("/root/main/UI/BigPanel/TCPNetworkManagerPanel")

# 消息历史记录
var message_history: Array = []
var max_message_history: int = 100  # 最大消息历史记录数量

# 历史消息加载状态
var current_load_days: int = 3  # 当前加载的天数
var max_load_days: int = 30     # 最大加载30天的历史

func _ready() -> void:
	# 连接按钮信号
	quit_button.pressed.connect(on_quit_button_pressed)
	send_message_button.pressed.connect(on_send_message_button_pressed)
	watch_more_button.pressed.connect(on_watch_more_button_pressed)
	
	# 连接输入框回车信号
	input_message.text_submitted.connect(on_input_message_submitted)
	
	# 连接面板显示隐藏信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 初始化消息显示
	message_contents.bbcode_enabled = true
	message_contents.scroll_following = true
	
	# 隐藏面板
	self.hide()

# 退出按钮点击事件
func on_quit_button_pressed():
	self.hide()

# 发送消息按钮点击事件
func on_send_message_button_pressed():
	send_broadcast_message()

# 查看更多消息按钮点击事件
func on_watch_more_button_pressed():
	load_more_history()

# 输入框回车事件
func on_input_message_submitted(text: String):
	send_broadcast_message()

# 发送全服大喇叭消息
func send_broadcast_message():
	var message_text = input_message.text.strip_edges()
	
	# 检查消息是否为空
	if message_text.is_empty():
		Toast.show("消息不能为空", Color.RED, 2.0, 1.0)
		return
	
	# 检查消息长度
	if message_text.length() > 200:
		Toast.show("消息长度不能超过200字符", Color.RED, 2.0, 1.0)
		return
	
	# 检查网络连接
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接服务器，无法发送消息", Color.RED, 2.0, 1.0)
		return
	
	# 发送消息到服务器
	var success = tcp_network_manager_panel.send_message({
		"type": "global_broadcast",
		"content": message_text,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if success:
		# 清空输入框
		input_message.text = ""
		Toast.show("消息发送成功", Color.GREEN, 2.0, 1.0)
	else:
		Toast.show("消息发送失败", Color.RED, 2.0, 1.0)

# 统一的消息处理函数
func _add_message_to_history(data: Dictionary):
	var username = data.get("username", "匿名")
	var player_name = data.get("玩家昵称", "")
	var content = data.get("content", "")
	var timestamp = data.get("timestamp", Time.get_unix_time_from_system())
	
	# 如果有玩家昵称，优先显示昵称
	var display_name = player_name if player_name != "" else username
	
	# 格式化时间 - 确保timestamp是整数类型
	var timestamp_int = int(timestamp) if typeof(timestamp) == TYPE_STRING else timestamp
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp_int)
	var time_str = "%04d年%02d月%02d日 %02d:%02d:%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second]
	
	# 创建消息记录
	var message_record = {
		"username": username,
		"玩家昵称": player_name,
		"content": content,
		"timestamp": timestamp,
		"time_str": time_str,
		"display_name": display_name
	}
	
	message_history.append(message_record)

# 接收全服大喇叭消息
func receive_broadcast_message(data: Dictionary):
	# 使用统一的处理函数
	_add_message_to_history(data)
	
	# 保持消息历史记录在限制范围内
	if message_history.size() > max_message_history:
		message_history.pop_front()
	
	# 如果面板当前可见，立即更新显示
	if visible:
		update_message_display()
	
	# 保存到本地
	save_chat_history()

# 更新消息显示
func update_message_display():
	var display_text = ""
	
	for message in message_history:
		var username = message.get("username", "匿名")
		var display_name = message.get("display_name", username)
		var content = message.get("content", "")
		var time_str = message.get("time_str", "") + "："
		
		# 使用BBCode格式化消息
		var formatted_message = "[color=#FFD700][b]%s[/b][/color] [color=#87CEEB](%s)[/color] [color=#FFA500]%s[/color][color=#FFFFFF]%s[/color]\n\n" % [
			display_name, username, time_str, content
		]
		
		display_text += formatted_message
	
	# 更新显示
	message_contents.text = display_text
	
	# 滚动到底部
	call_deferred("scroll_to_bottom")

# 滚动到底部
func scroll_to_bottom():
	if message_contents.get_v_scroll_bar():
		message_contents.get_v_scroll_bar().value = message_contents.get_v_scroll_bar().max_value

# 加载聊天历史记录
func load_chat_history():
	# 请求服务器加载最近3天的历史消息
	request_history_from_server(current_load_days)

# 从服务器请求历史消息
func request_history_from_server(days: int):
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		# 如果没有连接服务器，从本地文件加载
		load_local_chat_history()
		return
	
	# 向服务器请求历史消息
	var success = tcp_network_manager_panel.send_message({
		"type": "request_broadcast_history",
		"days": days,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if not success:
		Toast.show("请求历史消息失败", Color.RED, 2.0, 1.0)
		load_local_chat_history()

# 从本地文件加载历史消息
func load_local_chat_history():
	var file_path = "user://chat_history.json"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var data = json.data
				if data is Array:
					message_history = data
					# 按时间戳排序消息历史（从旧到新）
					message_history.sort_custom(func(a, b): return a.get("timestamp", 0) < b.get("timestamp", 0))
					update_message_display()

# 加载更多历史消息
func load_more_history():
	if current_load_days >= max_load_days:
		Toast.show("已经加载了最多30天的历史消息", Color.YELLOW, 2.0, 1.0)
		return
	
	# 增加加载天数
	current_load_days += 7  # 每次多加载7天
	if current_load_days > max_load_days:
		current_load_days = max_load_days
	
	# 请求更多历史消息
	request_history_from_server(current_load_days)
	Toast.show("正在加载更多历史消息...", Color.YELLOW, 2.0, 1.0)

# 接收服务器返回的历史消息
func receive_history_messages(data: Dictionary):
	var messages = data.get("messages", [])
	print("大喇叭面板收到历史消息: ", messages.size(), " 条")
	
	if messages.size() > 0:
		# 清空当前历史记录，重新加载
		message_history.clear()
		
		# 处理每条消息
		for msg in messages:
			_add_message_to_history(msg)
		
		# 按时间戳排序
		message_history.sort_custom(func(a, b): return a.get("timestamp", 0) < b.get("timestamp", 0))
		
		# 保持消息历史记录在限制范围内
		if message_history.size() > max_message_history:
			message_history = message_history.slice(-max_message_history)
		
		# 更新显示
		update_message_display()
		
		# 保存到本地
		save_chat_history()
		
		Toast.show("历史消息加载完成，共%d条消息" % messages.size(), Color.GREEN, 2.0, 1.0)
	else:
		Toast.show("没有找到历史消息", Color.YELLOW, 2.0, 1.0)

# 保存聊天历史记录
func save_chat_history():
	var file_path = "user://chat_history.json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		var json_string = JSON.stringify(message_history)
		file.store_string(json_string)
		file.close()

# 面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时，重新加载历史消息
		current_load_days = 3  # 重置为3天
		load_chat_history()
		# 滚动到底部
		call_deferred("scroll_to_bottom")
	else:
		GlobalVariables.isZoomDisabled = false
		# 面板隐藏时，保存聊天历史
		save_chat_history()

# 清空消息历史
func clear_message_history():
	message_history.clear()
	update_message_display()
	save_chat_history()
	Toast.show("消息历史已清空", Color.YELLOW, 2.0, 1.0)

# 获取最新消息用于主界面显示
func get_latest_message() -> String:
	print("get_latest_message 被调用，消息历史大小: ", message_history.size())
	if message_history.size() > 0:
		# 确保消息按时间排序
		message_history.sort_custom(func(a, b): return a.get("timestamp", 0) < b.get("timestamp", 0))
		var latest = message_history[-1]
		var result = latest.get("display_name", "匿名") + ": " + latest.get("content", "")
		print("返回最新消息: ", result)
		return result
	print("没有消息历史，返回'暂无消息'")
	return "暂无消息"

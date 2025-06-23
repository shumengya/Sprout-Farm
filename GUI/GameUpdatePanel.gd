extends Panel

@onready var contents: RichTextLabel = $Scroll/Contents		#更新内容
@onready var refresh_button: Button = $RefreshButton		#刷新按钮

# HTTP请求节点
var http_request: HTTPRequest

# API配置
const API_URL = "http://47.108.90.0:5003/api/game/mengyafarm/updates"

func _ready() -> void:
	self.hide()
	
	# 创建HTTPRequest节点
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 连接HTTP请求完成信号
	http_request.request_completed.connect(_on_request_completed)
	
	# 连接刷新按钮信号
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	
	# 初始加载更新数据
	load_updates()

func _on_quit_button_pressed() -> void:
	HidePanel()

func _on_refresh_button_pressed() -> void:
	load_updates()

func load_updates() -> void:
	# 禁用刷新按钮，防止重复请求
	refresh_button.disabled = true
	refresh_button.text = "刷新中..."
	
	# 显示加载中
	contents.text = "[center][color=yellow]正在加载更新信息...[/color][/center]"
	
	# 发起HTTP请求
	var error = http_request.request(API_URL)
	if error != OK:
		_show_error("网络请求失败，错误代码: " + str(error))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# 恢复刷新按钮
	refresh_button.disabled = false
	refresh_button.text = "刷新"
	
	# 检查请求结果
	if result != HTTPRequest.RESULT_SUCCESS:
		_show_error("网络连接失败")
		return
	
	if response_code != 200:
		_show_error("服务器响应错误 (HTTP " + str(response_code) + ")")
		return
	
	# 解析JSON数据
	var json_text = body.get_string_from_utf8()
	if json_text.is_empty():
		_show_error("服务器返回空数据")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		_show_error("数据解析失败")
		return
	
	var data = json.data
	if not data.has("updates"):
		_show_error("数据格式错误")
		return
	
	# 显示更新内容
	display_updates(data.updates)

func _show_error(error_message: String) -> void:
	refresh_button.disabled = false
	refresh_button.text = "刷新"
	contents.text = "[center][color=red]" + error_message + "\n\n请检查网络连接或稍后重试[/color][/center]"

func display_updates(updates: Array) -> void:
	if updates.is_empty():
		contents.text = "[center][color=gray]暂无更新信息[/color][/center]"
		return
	
	var update_text = ""
	
	for i in range(updates.size()):
		var update = updates[i]
		
		# 检查必要字段
		if not update.has("title") or not update.has("version") or not update.has("content"):
			continue
		
		# 更新标题
		update_text += "[color=cyan][font_size=22][b]" + str(update.title) + "[/b][/font_size][/color]\n"
		
		# 版本和时间信息
		update_text += "[color=green]版本: " + str(update.version) + "[/color]"
		
		if update.has("timestamp"):
			var formatted_time = _format_time(str(update.timestamp))
			update_text += "  [color=gray]时间: " + formatted_time + "[/color]"
		
		if update.has("game_name"):
			update_text += "  [color=gray]游戏: " + str(update.game_name) + "[/color]"
		
		update_text += "\n\n"
		
		# 更新内容
		var content = str(update.content)
		# 处理换行符
		content = content.replace("\\r\\n", "\n").replace("\\n", "\n")
		# 高亮特殊符号
		content = content.replace("✓", "[color=green]✓[/color]")
		content = content.replace("修复：", "[color=yellow]修复：[/color]")
		content = content.replace("添加", "[color=cyan]添加[/color]")
		content = content.replace("修改", "[color=orange]修改[/color]")
		
		update_text += "[color=white]" + content + "[/color]\n"
		
		# 添加分隔线（除了最后一个更新）
		if i < updates.size() - 1:
			update_text += "\n[color=gray]" + "─".repeat(60) + "[/color]\n\n"
	
	contents.text = update_text

# 简单的时间格式化
func _format_time(timestamp: String) -> String:
	var parts = timestamp.split(" ")
	if parts.size() >= 2:
		var date_parts = parts[0].split("-")
		var time_parts = parts[1].split(":")
		
		if date_parts.size() >= 3 and time_parts.size() >= 2:
			return date_parts[1] + "月" + date_parts[2] + "日 " + time_parts[0] + ":" + time_parts[1]
	
	return timestamp

# 显示面板时自动刷新
func ShowPanel() -> void:
	self.show()
	load_updates()

# 隐藏面板时取消正在进行的请求
func HidePanel() -> void:
	self.hide()
	if http_request and http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()
	
	# 恢复按钮状态
	if refresh_button:
		refresh_button.disabled = false
		refresh_button.text = "刷新"
	
	

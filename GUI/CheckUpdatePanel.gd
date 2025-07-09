extends Control

# 简化版更新检测器
# 适用于萌芽农场游戏

# 配置
const GAME_ID = "mengyafarm"
const SERVER_URL = "http://47.108.90.0:5000"
const CURRENT_VERSION = GlobalVariables.client_version

# 更新信息
var has_update = false
var latest_version = ""

func _ready():
	# 初始化时隐藏面板
	self.hide()
	
	# 游戏启动时自动检查更新
	call_deferred("check_for_updates")

func check_for_updates():
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 连接请求完成信号
	http_request.request_completed.connect(_on_update_check_completed)
	
	# 发送请求
	var url = SERVER_URL + "/api/simple/check-version/" + GAME_ID + "?current_version=" + CURRENT_VERSION
	var error = http_request.request(url)
	
	if error != OK:
		print("网络请求失败: ", error)

func _on_update_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		print("服务器响应错误: ", response_code)
		return
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("解析响应失败")
		return
	
	var data = json.data
	
	if "error" in data:
		print("服务器错误: ", data.error)
		return
	
	# 检查是否有更新
	has_update = data.get("has_update", false)
	latest_version = data.get("latest_version", "")
	
	if has_update:
		print("发现新版本: ", latest_version)
		show_update_panel()
	else:
		print("已是最新版本")

func show_update_panel():
	"""显示更新面板"""
	self.show()  # 直接显示当前面板

func download_update():
	"""下载更新"""
	var platform = get_platform_name()
	var download_url = SERVER_URL + "/download/" + GAME_ID + "/" + platform.to_lower()
	
	print("下载链接: ", download_url)
	
	# 打开下载页面
	var error = OS.shell_open(download_url)
	if error != OK:
		# 复制到剪贴板作为备选方案
		DisplayServer.clipboard_set(download_url)
		show_message("无法打开浏览器，下载链接已复制到剪贴板")

func get_platform_name() -> String:
	"""获取平台名称"""
	var os_name = OS.get_name()
	match os_name:
		"Windows":
			return "Windows"
		"Android":
			return "Android"
		"macOS":
			return "macOS"
		"Linux":
			return "Linux"
		_:
			return "Windows"

func show_message(text: String):
	"""显示消息提示"""
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = text
	dialog.popup_centered()
	
	# 3秒后自动关闭
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(dialog):
		dialog.queue_free()

# 手动检查更新的公共方法
func manual_check_update():
	"""手动检查更新"""
	check_for_updates()

# 直接跳转到相应平台下载链接
func _on_download_button_pressed() -> void:
	"""下载按钮点击事件"""
	if not has_update:
		show_message("当前已是最新版本")
		return
	
	var platform = get_platform_name()
	var download_url = SERVER_URL + "/download/" + GAME_ID + "/" + platform.to_lower()
	
	print("下载链接: ", download_url)
	
	# 打开下载页面
	var error = OS.shell_open(download_url)
	if error != OK:
		# 复制到剪贴板作为备选方案
		DisplayServer.clipboard_set(download_url)
		show_message("无法打开浏览器，下载链接已复制到剪贴板")
	else:
		show_message("正在打开下载页面...")
		# 可选：隐藏更新面板
		self.hide()

# 关闭更新面板
func _on_close_button_pressed() -> void:
	"""关闭按钮点击事件"""
	self.hide()

# 稍后提醒按钮
func _on_later_button_pressed() -> void:
	"""稍后提醒按钮点击事件"""
	print("用户选择稍后更新")
	self.hide()

# 检查更新按钮
func _on_check_update_button_pressed() -> void:
	"""检查更新按钮点击事件"""
	check_for_updates()

# 获取更新信息的公共方法
func get_update_info() -> Dictionary:
	"""获取更新信息"""
	return {
		"has_update": has_update,
		"current_version": CURRENT_VERSION,
		"latest_version": latest_version,
		"game_id": GAME_ID
	}

# 获取当前版本
func get_current_version() -> String:
	"""获取当前版本"""
	return CURRENT_VERSION

# 获取最新版本
func get_latest_version() -> String:
	"""获取最新版本"""
	return latest_version

# 是否有更新
func is_update_available() -> bool:
	"""是否有更新可用"""
	return has_update 

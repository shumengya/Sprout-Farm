extends Panel
#游戏设置面板

# UI组件引用
@onready var background_music_h_slider: HSlider = $Scroll/Panel/BackgroundMusicHSlider
@onready var weather_system_check: CheckButton = $Scroll/Panel/WeatherSystemCheck
@onready var quit_button: Button = $QuitButton
@onready var sure_button: Button = $SureButton
@onready var refresh_button: Button = $RefreshButton

# 引用主游戏和其他组件
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel: Panel = get_node("/root/main/UI/BigPanel/TCPNetworkManagerPanel")

# 游戏设置数据
var game_settings: Dictionary = {
	"背景音乐音量": 1.0,
	"天气显示": true
}

# 临时设置数据（用户修改但未确认的设置）
var temp_settings: Dictionary = {}

func _ready() -> void:
	self.hide()
	
	# 连接信号
	quit_button.pressed.connect(_on_quit_button_pressed)
	sure_button.pressed.connect(_on_sure_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	
	# 设置音量滑块范围为0-1
	background_music_h_slider.min_value = 0.0
	background_music_h_slider.max_value = 1.0
	background_music_h_slider.step = 0.01
	background_music_h_slider.value_changed.connect(_on_background_music_h_slider_value_changed)
	weather_system_check.toggled.connect(_on_weather_system_check_toggled)
	
	# 初始化设置值
	_load_settings_from_global()
	
	# 当面板可见性改变时
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	"""面板可见性改变时的处理"""
	if visible:
		# 面板显示时，刷新设置值
		_load_settings_from_global()
		_update_ui_from_settings()
		
		# 禁用缩放功能
		GlobalVariables.isZoomDisabled = true
	else:
		# 面板隐藏时，恢复缩放功能
		GlobalVariables.isZoomDisabled = false

func _load_settings_from_global():
	"""从全局变量和玩家数据加载设置"""
	# 从GlobalVariables加载默认设置
	game_settings["背景音乐音量"] = GlobalVariables.BackgroundMusicVolume
	game_settings["天气显示"] = not GlobalVariables.DisableWeatherDisplay
	
	# 如果主游戏已登录，尝试从玩家数据加载设置
	if main_game and main_game.login_data and main_game.login_data.has("游戏设置"):
		var player_settings = main_game.login_data["游戏设置"]
		if player_settings.has("背景音乐音量"):
			game_settings["背景音乐音量"] = player_settings["背景音乐音量"]
		if player_settings.has("天气显示"):
			game_settings["天气显示"] = player_settings["天气显示"]
	
	# 初始化临时设置
	temp_settings = game_settings.duplicate()

func _update_ui_from_settings():
	"""根据设置数据更新UI"""
	# 更新音量滑块
	background_music_h_slider.value = temp_settings["背景音乐音量"]
	
	# 更新天气显示复选框（注意：复选框表示"关闭天气显示"）
	weather_system_check.button_pressed = not temp_settings["天气显示"]

func _apply_settings_immediately():
	"""立即应用设置（不保存到服务端）"""
	# 应用背景音乐音量设置
	_apply_music_volume_setting()
	
	# 应用天气显示设置
	_apply_weather_display_setting()

func _save_settings_to_server():
	"""保存设置到服务端"""
	# 更新正式设置
	game_settings = temp_settings.duplicate()
	
	# 应用设置
	_apply_settings_immediately()
	
	# 如果已登录，保存到玩家数据并同步到服务端
	if main_game and main_game.login_data:
		main_game.login_data["游戏设置"] = game_settings.duplicate()
		
		# 发送设置到服务端保存
		if tcp_network_manager_panel and tcp_network_manager_panel.has_method("is_connected_to_server") and tcp_network_manager_panel.is_connected_to_server():
			_send_settings_to_server()

func _apply_music_volume_setting():
	"""应用背景音乐音量设置"""
	var bgm_player = main_game.get_node_or_null("GameBGMPlayer")
	if bgm_player and bgm_player.has_method("set_volume"):
		bgm_player.set_volume(temp_settings["背景音乐音量"])

func _apply_weather_display_setting():
	"""应用天气显示设置"""
	var weather_system = main_game.get_node_or_null("WeatherSystem")
	if weather_system and weather_system.has_method("set_weather_display_enabled"):
		weather_system.set_weather_display_enabled(temp_settings["天气显示"])

func _send_settings_to_server():
	"""发送设置到服务端保存"""
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("send_message"):
		var message = {
			"type": "save_game_settings",
			"settings": game_settings,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		if tcp_network_manager_panel.send_message(message):
			print("游戏设置已发送到服务端保存")
		else:
			print("发送游戏设置到服务端失败")

func _on_quit_button_pressed() -> void:
	"""关闭设置面板"""
	self.hide()

func _on_background_music_h_slider_value_changed(value: float) -> void:
	"""背景音乐音量滑块值改变"""
	temp_settings["背景音乐音量"] = value
	# 立即应用音量设置（不保存到服务端）
	_apply_music_volume_setting()
	
	# 显示当前音量百分比
	var volume_percent = int(value * 100)

func _on_weather_system_check_toggled(toggled_on: bool) -> void:
	"""天气系统复选框切换"""
	# 复选框表示"关闭天气显示"，所以需要取反
	temp_settings["天气显示"] = not toggled_on
	# 立即应用天气设置（不保存到服务端）
	_apply_weather_display_setting()
	
	# 显示提示
	var status_text = "已开启" if temp_settings["天气显示"] else "已关闭"
	Toast.show("天气显示" + status_text, Color.YELLOW)

#确认修改设置按钮，点击这个才会发送数据到服务端
func _on_sure_button_pressed() -> void:
	"""确认修改设置"""
	_save_settings_to_server()
	Toast.show("设置已保存！", Color.GREEN)

#刷新设置面板，从服务端加载游戏设置数据
func _on_refresh_button_pressed() -> void:
	"""刷新设置"""
	_load_settings_from_global()
	_update_ui_from_settings()
	_apply_settings_immediately()
	Toast.show("设置已刷新！", Color.CYAN)

# 移除原来的自动保存方法，避免循环调用
func _on_background_music_h_slider_drag_ended(value_changed: bool) -> void:
	"""背景音乐音量滑块拖拽结束（保留以兼容场景连接）"""
	# 不再自动保存，只显示提示
	if value_changed:
		var volume_percent = int(background_music_h_slider.value * 100)
		
# 公共方法，供外部调用
func refresh_settings():
	"""刷新设置（从服务端或本地重新加载）"""
	_load_settings_from_global()
	_update_ui_from_settings()
	_apply_settings_immediately()

func get_current_settings() -> Dictionary:
	"""获取当前设置"""
	return game_settings.duplicate()

func apply_settings_from_server(server_settings: Dictionary):
	"""应用从服务端接收到的设置（避免循环调用）"""
	if server_settings.has("背景音乐音量"):
		game_settings["背景音乐音量"] = server_settings["背景音乐音量"]
		temp_settings["背景音乐音量"] = server_settings["背景音乐音量"]
	if server_settings.has("天气显示"):
		game_settings["天气显示"] = server_settings["天气显示"]
		temp_settings["天气显示"] = server_settings["天气显示"]
	
	# 只更新UI，不再触发保存
	if visible:
		_update_ui_from_settings()
	_apply_settings_immediately()
	
	print("已应用来自服务端的游戏设置")

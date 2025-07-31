extends PanelContainer

@onready var start_button: Button = $VBox/StartButton #开始占卜
@onready var quit_button: Button = $VBox/QuitButton #关闭面板 
@onready var contents: RichTextLabel = $VBox/Scroll/Contents #显示占卜内容 用bbcode美化一下

@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'

# 占卜状态
var is_divining: bool = false
var today_divination_data: Dictionary = {}

func _ready() -> void:
	self.hide()
	visibility_changed.connect(_on_visibility_changed)
	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

#关闭面板
func _on_quit_button_pressed() -> void:
	self.hide()

#开始占卜
func _on_start_button_pressed() -> void:
	if is_divining:
		return
	
	# 检查今日是否已经占卜过
	var today_date = Time.get_date_string_from_system()
	if today_divination_data.get("占卜日期", "") == today_date:
		Toast.show("今日已经占卜过了，明日再来吧！", Color.ORANGE)
		return
	
	# 开始占卜
	is_divining = true
	start_button.disabled = true
	start_button.text = "占卜中..."
	
	# 显示占卜进行中的内容
	contents.text = "[center][color=gold]正在为您占卜中...[/color]\n\n[color=cyan]天机不可泄露，请稍候...[/color][/center]"
	
	# 3秒后显示占卜结果
	await get_tree().create_timer(3.0).timeout
	
	# 发送占卜请求到服务器
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendDivinationRequest"):
		tcp_network_manager_panel.sendDivinationRequest()
	else:
		Toast.show("网络连接异常，无法进行占卜", Color.RED)
		_reset_divination_state()

# 处理占卜响应
func handle_divination_response(success: bool, message: String, divination_data: Dictionary = {}):
	if success:
		# 更新本地占卜数据
		today_divination_data = divination_data.get("今日占卜对象", {})
		
		# 显示占卜结果
		_display_divination_result(today_divination_data)
		
		Toast.show("占卜完成！", Color.GREEN)
	else:
		contents.text = "[center][color=red]占卜失败：" + message + "[/color][/center]"
		Toast.show(message, Color.RED)
	
	_reset_divination_state()

# 显示占卜结果
func _display_divination_result(divination_data: Dictionary):
	var divination_date = divination_data.get("占卜日期", "")
	var divination_result = divination_data.get("占卜结果", "")
	var divination_level = divination_data.get("占卜等级", "")
	var divination_hexagram = divination_data.get("卦象", "")
	var divination_advice = divination_data.get("建议", "")
	
	var result_text = "[center][color=gold]═══ 今日占卜结果 ═══[/color]\n\n"
	result_text += "[color=cyan]占卜日期：[/color]" + divination_date + "\n\n"
	result_text += "[color=yellow]占卜等级：[/color]" + divination_level + "\n\n"
	result_text += "[color=purple]卦象：[/color]" + divination_hexagram + "\n\n"
	result_text += "[color=blue]占卜结果：[/color]\n" + divination_result + "\n\n"
	result_text += "[color=green]建议：[/color]\n" + divination_advice + "\n\n"
	result_text += "[color=gold]═══════════════[/color][/center]"
	
	contents.text = result_text

# 重置占卜状态
func _reset_divination_state():
	is_divining = false
	start_button.disabled = false
	start_button.text = "开始占卜"

# 面板显示时的处理
func _on_visibility_changed():
	if visible:
		# 面板显示时自动刷新数据
		_refresh_divination_data()
		GlobalVariables.isZoomDisabled = true
	else:
		GlobalVariables.isZoomDisabled = false

# 刷新占卜数据
func _refresh_divination_data():
	# 从主游戏获取占卜数据
	var main_game = get_node("/root/main")
	if main_game and main_game.has_method("get_player_divination_data"):
		today_divination_data = main_game.get_player_divination_data()
		
		# 检查今日是否已经占卜过
		var today_date = Time.get_date_string_from_system()
		if today_divination_data.get("占卜日期", "") == today_date:
			# 显示今日占卜结果
			_display_divination_result(today_divination_data)
			start_button.text = "今日已占卜"
			start_button.disabled = true
		else:
			# 显示默认内容
			contents.text = "[center][color=gold]═══ 今日占卜 ═══[/color]\n\n[color=cyan]点击下方按钮开始今日占卜\n\n占卜将为您揭示今日运势\n结合易经八卦为您指点迷津[/color]\n\n[color=orange]每日仅可占卜一次[/color][/center]"
			start_button.text = "开始占卜"
			start_button.disabled = false
	else:
		# 显示默认内容
		contents.text = "[center][color=gold]═══ 今日占卜 ═══[/color]\n\n[color=cyan]点击下方按钮开始今日占卜\n\n占卜将为您揭示今日运势\n结合易经八卦为您指点迷津[/color]\n\n[color=orange]每日仅可占卜一次[/color][/center]"

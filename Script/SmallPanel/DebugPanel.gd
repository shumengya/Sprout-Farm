extends Panel

## 调试面板 - 显示资源加载和设备性能信息
## 特别用于在移动设备上调试资源加载问题

@onready var debug_rich_text: RichTextLabel = $DebugRichText
@onready var copy_button: Button = null  # 复制按钮引用

# 调试信息管理
var debug_messages: Array = []
var max_debug_messages: int = 50  # 最大保留消息数量
var update_timer: float = 0.0
var update_interval: float = 1.0  # 每秒更新一次

# 性能监控数据
var performance_data: Dictionary = {
	"cpu_usage": 0.0,
	"memory_usage": 0,
	"memory_peak": 0,
	"fps": 0.0,
	"loading_progress": 0,
	"loaded_textures": 0,
	"failed_textures": 0,
	"current_loading_item": "",
	"device_info": {}
}

# 主游戏引用
var main_game = null

func _ready():
	print("[DebugPanel] 调试面板已初始化")
	# 获取主游戏引用
	main_game = get_node("/root/main")
	
	# 创建复制按钮
	_create_copy_button()
	
	# 初始化设备信息
	_collect_device_info()
	
	# 添加初始消息
	add_debug_message("调试面板已启动", Color.GREEN)
	add_debug_message("设备: " + OS.get_name(), Color.CYAN)
	add_debug_message("CPU核心: " + str(OS.get_processor_count()), Color.CYAN)

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_performance_data()
		_check_performance_warnings()
		_update_debug_display()

## 检查性能警告
func _check_performance_warnings():
	# 内存警告
	var memory_mb = performance_data["memory_usage"] / (1024 * 1024)
	if memory_mb > 800:
		report_memory_warning(memory_mb)
	
	# FPS警告
	if performance_data["fps"] < 20 and performance_data["fps"] > 0:
		report_performance_warning(performance_data["fps"])
	
	# 加载失败警告
	if performance_data["failed_textures"] > 10:
		add_debug_message("⚠ 大量纹理加载失败: %d 个" % performance_data["failed_textures"], Color.RED)

## 收集设备基本信息
func _collect_device_info():
	performance_data["device_info"] = {
		"platform": OS.get_name(),
		"processor_count": OS.get_processor_count(),
		"processor_name": OS.get_processor_name(),
		"memory_total": OS.get_static_memory_usage(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_name": RenderingServer.get_video_adapter_name(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_dpi": DisplayServer.screen_get_dpi()
	}

## 更新性能数据
func _update_performance_data():
	# CPU使用率（通过帧时间估算）
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS)
	performance_data["cpu_usage"] = min(frame_time * 100.0, 100.0)
	
	# 内存使用情况
	var current_memory = OS.get_static_memory_usage()
	performance_data["memory_usage"] = current_memory
	if current_memory > performance_data["memory_peak"]:
		performance_data["memory_peak"] = current_memory
	
	# FPS
	performance_data["fps"] = Engine.get_frames_per_second()
	
	# 从主游戏获取加载信息
	if main_game and main_game.crop_texture_manager:
		var manager = main_game.crop_texture_manager
		# 计算所有加载的纹理数量（新的三阶段系统）
		var total_textures = 0
		for crop_name in manager.texture_cache.keys():
			total_textures += manager.texture_cache[crop_name].size()
		total_textures += manager.default_textures.size()
		performance_data["loaded_textures"] = total_textures
		performance_data["failed_textures"] = manager.failed_resources.size()
		
		# 加载进度
		if manager.is_loading:
			var total = manager.total_crops * 2  # 序列帧 + 成熟图片
			var loaded = manager.loaded_crops
			performance_data["loading_progress"] = int((float(loaded) / float(total)) * 100) if total > 0 else 0
		else:
			performance_data["loading_progress"] = 100

## 更新调试显示
func _update_debug_display():
	if not debug_rich_text:
		return
	
	var text = ""
	
	# 为复制按钮留出空间，添加一些空行
	text += "\n\n"
	
	# 快速摘要（最重要的信息）
	text += "[color=yellow][b]=== 快速摘要 ===[/b][/color]\n"
	var summary_memory_mb = performance_data["memory_usage"] / (1024 * 1024)
	var status_color = "green"
	if performance_data["failed_textures"] > 0 or summary_memory_mb > 500 or performance_data["fps"] < 30:
		status_color = "red"
	elif performance_data["loading_progress"] < 100:
		status_color = "yellow"
	
	text += "[color=" + status_color + "]状态: "
	if performance_data["loading_progress"] < 100:
		text += "加载中 " + str(performance_data["loading_progress"]) + "%"
	elif performance_data["failed_textures"] > 0:
		text += "有 " + str(performance_data["failed_textures"]) + " 个资源加载失败"
	else:
		text += "正常运行"
	text += "[/color]\n"
	
	text += "[color=cyan]内存: %.1fMB | FPS: %d | 纹理: %d[/color]\n\n" % [summary_memory_mb, performance_data["fps"], performance_data["loaded_textures"]]
	
	# 设备信息标题
	text += "[color=yellow][b]=== 设备信息 ===[/b][/color]\n"
	var device = performance_data["device_info"]
	text += "[color=cyan]平台:[/color] " + str(device.get("platform", "未知")) + "\n"
	text += "[color=cyan]CPU:[/color] " + str(device.get("processor_name", "未知")) + " (" + str(device.get("processor_count", 0)) + "核)\n"
	text += "[color=cyan]GPU:[/color] " + str(device.get("gpu_name", "未知")) + "\n"
	text += "[color=cyan]屏幕:[/color] " + str(device.get("screen_size", Vector2.ZERO)) + " DPI:" + str(device.get("screen_dpi", 0)) + "\n"
	
	# 性能监控标题
	text += "\n[color=yellow][b]=== 性能监控 ===[/b][/color]\n"
	
	# CPU使用率（颜色编码）
	var cpu_color = "green"
	if performance_data["cpu_usage"] > 70:
		cpu_color = "red"
	elif performance_data["cpu_usage"] > 50:
		cpu_color = "yellow"
	text += "[color=cyan]CPU使用率:[/color] [color=" + cpu_color + "]" + "%.1f%%" % performance_data["cpu_usage"] + "[/color]\n"
	
	# 内存使用情况（颜色编码）
	var memory_mb = performance_data["memory_usage"] / (1024 * 1024)
	var memory_peak_mb = performance_data["memory_peak"] / (1024 * 1024)
	var memory_color = "green"
	if memory_mb > 800:
		memory_color = "red"
	elif memory_mb > 500:
		memory_color = "yellow"
	text += "[color=cyan]内存使用:[/color] [color=" + memory_color + "]%.1fMB[/color] (峰值: %.1fMB)\n" % [memory_mb, memory_peak_mb]
	
	# FPS（颜色编码）
	var fps_color = "green"
	if performance_data["fps"] < 30:
		fps_color = "red"
	elif performance_data["fps"] < 50:
		fps_color = "yellow"
	text += "[color=cyan]FPS:[/color] [color=" + fps_color + "]" + str(performance_data["fps"]) + "[/color]\n"
	
	# 资源加载状态标题
	text += "\n[color=yellow][b]=== 资源加载状态 ===[/b][/color]\n"
	
	# 加载进度（颜色编码）
	var progress_color = "yellow"
	if performance_data["loading_progress"] >= 100:
		progress_color = "green"
	elif performance_data["loading_progress"] < 50:
		progress_color = "red"
	text += "[color=cyan]加载进度:[/color] [color=" + progress_color + "]" + str(performance_data["loading_progress"]) + "%[/color]\n"
	
	# 纹理统计
	text += "[color=cyan]已加载纹理:[/color] " + str(performance_data["loaded_textures"]) + "\n"
	
	# 失败纹理（突出显示）
	if performance_data["failed_textures"] > 0:
		text += "[color=cyan]失败纹理:[/color] [color=red]" + str(performance_data["failed_textures"]) + "[/color]\n"
	else:
		text += "[color=cyan]失败纹理:[/color] [color=green]0[/color]\n"
	
	# 当前加载项目
	if performance_data["current_loading_item"] != "":
		text += "[color=cyan]当前加载:[/color] " + performance_data["current_loading_item"] + "\n"
	
	# 线程信息
	if main_game and main_game.crop_texture_manager:
		var manager = main_game.crop_texture_manager
		text += "[color=cyan]工作线程:[/color] " + str(manager.max_threads) + "\n"
		if manager.is_loading:
			text += "[color=cyan]队列任务:[/color] " + str(manager.loading_queue.size()) + "\n"
	
	# 调试消息标题
	text += "\n[color=yellow][b]=== 调试日志 ===[/b][/color]\n"
	
	# 显示最近的调试消息
	var recent_messages = debug_messages.slice(-15)  # 显示最近15条消息
	for message in recent_messages:
		text += message + "\n"
	
	# 更新显示
	debug_rich_text.text = text
	
	# 自动滚动到底部
	debug_rich_text.scroll_to_line(debug_rich_text.get_line_count())

## 添加调试消息
func add_debug_message(message: String, color: Color = Color.WHITE):
	var timestamp = Time.get_datetime_string_from_system()
	var time_parts = timestamp.split(" ")
	var time_str = ""
	
	# 安全地获取时间部分
	if time_parts.size() >= 2:
		time_str = time_parts[1].substr(0, 8)  # 只要时间部分
	else:
		# 如果分割失败，使用当前时间
		var time_dict = Time.get_time_dict_from_system()
		time_str = "%02d:%02d:%02d" % [time_dict.hour, time_dict.minute, time_dict.second]
	
	var color_name = _color_to_name(color)
	var formatted_message = "[color=gray]%s[/color] [color=%s]%s[/color]" % [time_str, color_name, message]
	
	debug_messages.append(formatted_message)
	
	# 限制消息数量
	if debug_messages.size() > max_debug_messages:
		debug_messages = debug_messages.slice(-max_debug_messages)
	
	# 同时输出到控制台
	print("[DebugPanel] " + message)

## 颜色转换为名称
func _color_to_name(color: Color) -> String:
	if color == Color.RED:
		return "red"
	elif color == Color.GREEN:
		return "green"
	elif color == Color.BLUE:
		return "blue"
	elif color == Color.YELLOW:
		return "yellow"
	elif color == Color.CYAN:
		return "cyan"
	elif color == Color.MAGENTA:
		return "magenta"
	elif color == Color.ORANGE:
		return "orange"
	elif color == Color.PINK:
		return "pink"
	else:
		return "white"

## 设置当前加载项目
func set_current_loading_item(item_name: String):
	performance_data["current_loading_item"] = item_name
	if item_name != "":
		add_debug_message("正在加载: " + item_name, Color.CYAN)

## 报告加载成功
func report_loading_success(item_name: String):
	add_debug_message("✓ 加载成功: " + item_name, Color.GREEN)

## 报告加载失败
func report_loading_failure(item_name: String, reason: String = ""):
	var message = "✗ 加载失败: " + item_name
	if reason != "":
		message += " (" + reason + ")"
	add_debug_message(message, Color.RED)

## 报告内存警告
func report_memory_warning(memory_mb: float):
	add_debug_message("⚠ 内存使用过高: %.1fMB" % memory_mb, Color.ORANGE)

## 报告性能警告
func report_performance_warning(fps: float):
	add_debug_message("⚠ 性能下降: FPS=" + str(fps), Color.ORANGE)

## 清理调试信息
func clear_debug_log():
	debug_messages.clear()
	add_debug_message("调试日志已清理", Color.YELLOW)

## 导出调试信息到文件
func export_debug_log():
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "debug_log_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var file_path = OS.get_user_data_dir() + "/" + filename
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string("=== 萌芽农场调试日志 ===\n\n")
		file.store_string("设备信息:\n")
		for key in performance_data["device_info"]:
			file.store_string("  %s: %s\n" % [key, str(performance_data["device_info"][key])])
		
		file.store_string("\n性能数据:\n")
		file.store_string("  CPU使用率: %.1f%%\n" % performance_data["cpu_usage"])
		file.store_string("  内存使用: %.1fMB\n" % (performance_data["memory_usage"] / (1024 * 1024)))
		file.store_string("  FPS: %d\n" % performance_data["fps"])
		file.store_string("  已加载纹理: %d\n" % performance_data["loaded_textures"])
		file.store_string("  失败纹理: %d\n" % performance_data["failed_textures"])
		
		file.store_string("\n调试日志:\n")
		for message in debug_messages:
			# 移除BBCode标签
			var clean_message = message.replace("[color=gray]", "").replace("[/color]", "")
			clean_message = clean_message.replace("[color=red]", "").replace("[color=green]", "")
			clean_message = clean_message.replace("[color=cyan]", "").replace("[color=yellow]", "")
			clean_message = clean_message.replace("[color=orange]", "")
			file.store_string(clean_message + "\n")
		
		file.close()
		add_debug_message("调试日志已导出到: " + filename, Color.GREEN)
		return file_path
	else:
		add_debug_message("导出调试日志失败", Color.RED)
		return ""

## 创建复制按钮
func _create_copy_button():
	# 复制按钮
	copy_button = Button.new()
	copy_button.text = "复制调试信息"
	copy_button.size = Vector2(140, 35)
	copy_button.position = Vector2(10, 10)  # 左上角位置
	
	# 设置按钮样式
	copy_button.modulate = Color(1.0, 0.8, 0.6, 0.9)  # 淡橙色
	
	# 连接点击信号
	copy_button.pressed.connect(_on_copy_button_pressed)
	
	# 添加到面板
	add_child(copy_button)
	
	# 清理日志按钮
	var clear_button = Button.new()
	clear_button.text = "清理日志"
	clear_button.size = Vector2(100, 35)
	clear_button.position = Vector2(160, 10)  # 复制按钮右边
	
	# 设置按钮样式
	clear_button.modulate = Color(1.0, 0.6, 0.6, 0.9)  # 淡红色
	
	# 连接点击信号
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	# 添加到面板
	add_child(clear_button)
	
	print("[DebugPanel] 复制和清理按钮已创建")

## 清理按钮点击处理
func _on_clear_button_pressed():
	clear_debug_log()
	print("[DebugPanel] 调试日志已清理")

## 复制按钮点击处理
func _on_copy_button_pressed():
	var debug_text = _generate_debug_text_for_copy()
	DisplayServer.clipboard_set(debug_text)
	add_debug_message("调试信息已复制到剪贴板", Color.GREEN)
	print("[DebugPanel] 调试信息已复制到剪贴板")

## 生成用于复制的调试文本（纯文本格式）
func _generate_debug_text_for_copy() -> String:
	var text = "=== 萌芽农场调试信息 ===\n\n"
	
	# 设备信息
	text += "=== 设备信息 ===\n"
	var device = performance_data["device_info"]
	text += "平台: " + str(device.get("platform", "未知")) + "\n"
	text += "CPU: " + str(device.get("processor_name", "未知")) + " (" + str(device.get("processor_count", 0)) + "核)\n"
	text += "GPU: " + str(device.get("gpu_name", "未知")) + "\n"
	text += "屏幕: " + str(device.get("screen_size", Vector2.ZERO)) + " DPI:" + str(device.get("screen_dpi", 0)) + "\n"
	
	# 性能监控
	text += "\n=== 性能监控 ===\n"
	text += "CPU使用率: %.1f%%\n" % performance_data["cpu_usage"]
	var memory_mb = performance_data["memory_usage"] / (1024 * 1024)
	var memory_peak_mb = performance_data["memory_peak"] / (1024 * 1024)
	text += "内存使用: %.1fMB (峰值: %.1fMB)\n" % [memory_mb, memory_peak_mb]
	text += "FPS: %d\n" % performance_data["fps"]
	
	# 资源加载状态
	text += "\n=== 资源加载状态 ===\n"
	text += "加载进度: %d%%\n" % performance_data["loading_progress"]
	text += "已加载纹理: %d\n" % performance_data["loaded_textures"]
	text += "失败纹理: %d\n" % performance_data["failed_textures"]
	
	if performance_data["current_loading_item"] != "":
		text += "当前加载: " + performance_data["current_loading_item"] + "\n"
	
	# 线程信息
	if main_game and main_game.crop_texture_manager:
		var manager = main_game.crop_texture_manager
		text += "工作线程: %d\n" % manager.max_threads
		if manager.is_loading:
			text += "队列任务: %d\n" % manager.loading_queue.size()
	
	# 调试日志
	text += "\n=== 调试日志 ===\n"
	for message in debug_messages:
		# 移除BBCode标签
		var clean_message = _remove_bbcode_tags(message)
		text += clean_message + "\n"
	
	return text

## 移除BBCode标签
func _remove_bbcode_tags(text: String) -> String:
	var clean_text = text
	
	# 移除所有颜色标签
	var color_regex = RegEx.new()
	color_regex.compile("\\[color=[^\\]]*\\]|\\[/color\\]")
	clean_text = color_regex.sub(clean_text, "", true)
	
	# 移除粗体标签
	clean_text = clean_text.replace("[b]", "").replace("[/b]", "")
	
	return clean_text

## 获取当前性能摘要
func get_performance_summary() -> String:
	return "CPU:%.1f%% 内存:%.1fMB FPS:%d 纹理:%d/%d" % [
		performance_data["cpu_usage"],
		performance_data["memory_usage"] / (1024 * 1024),
		performance_data["fps"],
		performance_data["loaded_textures"],
		performance_data["failed_textures"]
	]


func _on_quit_button_pressed() -> void:
	self.hide()
	pass 

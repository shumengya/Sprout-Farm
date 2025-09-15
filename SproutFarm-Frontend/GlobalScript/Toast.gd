# Toast.gd - 合并的Toast系统
extends Node

# Toast节点缓存
var toast_container: Control

func _ready():
	# 延迟创建Toast容器，避免在节点初始化期间添加子节点的冲突
	setup_toast_container.call_deferred()

func setup_toast_container():
	# 防止重复创建
	if toast_container and is_instance_valid(toast_container):
		return
	
	# 创建一个CanvasLayer来确保Toast始终在最顶层
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ToastCanvasLayer"
	canvas_layer.layer = 100  # 设置一个很高的层级值
	
	# 创建一个容器来放置所有Toast
	toast_container = Control.new()
	toast_container.name = "ToastContainer"
	toast_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 将容器添加到CanvasLayer中
	canvas_layer.add_child(toast_container)
	
	# 尝试添加到main/UI节点，如果失败则添加到根节点
	var ui_node = get_node_or_null("/root/main/UI")
	if ui_node:
		ui_node.add_child.call_deferred(canvas_layer)
		print("Toast容器已添加到 main/UI 节点")
	else:
		# 如果没有UI节点，直接添加到根节点
		get_tree().root.add_child.call_deferred(canvas_layer)
		print("Toast容器已添加到根节点")


func show(text: String, 
		color: Color = Color.WHITE,
		duration: float = 2.0,
		fade_duration: float = 0.5) -> void:
	
	# 确保容器存在且有效
	if not toast_container or not is_instance_valid(toast_container) or not toast_container.get_parent():
		setup_toast_container.call_deferred()
		# 等待容器设置完成
		await get_tree().process_frame
		await get_tree().process_frame  # 额外等待一帧确保完成
	
	# 再次检查容器是否有效
	if not toast_container or not is_instance_valid(toast_container):
		print("警告：Toast容器初始化失败，无法显示Toast")
		return
	
	# 创建Toast UI
	var toast_panel = create_toast_ui(text, color)
	toast_container.add_child(toast_panel)
	
	# 显示动画和自动消失
	show_toast_animation(toast_panel, duration, fade_duration)

func create_toast_ui(text: String, color: Color) -> PanelContainer:
	# 创建主容器
	var panel = PanelContainer.new()
	panel.name = "Toast_" + str(Time.get_ticks_msec())
	
	# 设置样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)  # 半透明黑色背景
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.content_margin_top = 12
	style_box.content_margin_bottom = 12
	style_box.content_margin_left = 16
	style_box.content_margin_right = 16
	panel.add_theme_stylebox_override("panel", style_box)
	
	# 创建文本标签
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置字体大小
	label.add_theme_font_size_override("font_size", 16)
	
	panel.add_child(label)
	
	# 定位Toast（屏幕中央偏下）
	position_toast(panel)
	
	return panel

func position_toast(toast_panel: PanelContainer):
	# 设置位置为屏幕中央偏下
	toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	toast_panel.position.y += 100  # 向下偏移
	
	# 调整现有Toast的位置，避免重叠
	var existing_toasts = []
	for child in toast_container.get_children():
		if child != toast_panel and child is PanelContainer:
			existing_toasts.append(child)
	
	# 向上堆叠
	for i in range(existing_toasts.size()):
		var existing_toast = existing_toasts[existing_toasts.size() - 1 - i]
		var tween = create_tween()
		tween.tween_property(existing_toast, "position:y", 
			existing_toast.position.y - 60, 0.3)

func show_toast_animation(toast_panel: PanelContainer, duration: float, fade_duration: float):
	# 初始状态：完全透明并稍微向上
	toast_panel.modulate.a = 0.0
	toast_panel.position.y += 20
	
	# 淡入动画
	var fade_in_tween = create_tween()
	fade_in_tween.parallel().tween_property(toast_panel, "modulate:a", 1.0, 0.3)
	fade_in_tween.parallel().tween_property(toast_panel, "position:y", 
		toast_panel.position.y - 20, 0.3)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	
	# 等待显示时间
	await get_tree().create_timer(duration).timeout
	
	# 淡出动画
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(toast_panel, "modulate:a", 0.0, fade_duration)
	await fade_out_tween.finished
	
	# 移除节点
	toast_panel.queue_free()

# 便捷方法
func show_success(text: String, duration: float = 2.0):
	show(text, Color.GREEN, duration)

func show_error(text: String, duration: float = 3.0):
	show(text, Color.RED, duration)

func show_warning(text: String, duration: float = 2.5):
	show(text, Color.YELLOW, duration)

func show_info(text: String, duration: float = 2.0):
	show(text, Color.CYAN, duration)

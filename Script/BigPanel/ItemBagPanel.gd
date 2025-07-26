extends Panel
# 这是道具背包面板，用来显示玩家获得的道具

# 道具背包格子容器
@onready var bag_grid: GridContainer = $ScrollContainer/Bag_Grid
@onready var quit_button : Button = $QuitButton
@onready var refresh_button : Button = $RefreshButton

# 预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'


# 道具使用状态
var selected_item_name: String = ""
var selected_item_button: Button = null
var is_item_selected: bool = false

# 宠物使用道具模式
var is_pet_item_mode: bool = false
var current_pet_data: Dictionary = {}

# 准备函数
func _ready():
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	# 隐藏面板（初始默认隐藏）
	self.hide()


# 异步更新道具背包UI
func _update_item_bag_ui_async():
	# 清空道具背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	# 等待一帧确保子节点被清理
	await get_tree().process_frame
	
	# 为背包中的每个道具创建按钮
	for item_data in main_game.item_bag:
		var item_name = item_data["name"]
		var item_count = item_data["count"]
		
		# 创建道具按钮
		var button = _create_item_button(item_name)
		
		# 更新按钮文本显示数量
		button.text = str(item_name + "\n数量：" + str(item_count))
		
		# 根据是否处于访问模式连接不同的事件
		if main_game.is_visiting_mode:
			# 访问模式下，点击道具只显示信息，不能使用
			button.pressed.connect(func(): _on_visit_item_selected(item_name, item_count))
		else:
			# 正常模式下，连接道具选择事件
			button.pressed.connect(func(): _on_item_selected(item_name, item_count, button))
		
		bag_grid.add_child(button)

# 初始化道具背包
func init_item_bag():
	# 清空道具背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	# 显示背包中的道具
	update_item_bag_ui()

# 更新道具背包UI（同步版本，用于刷新按钮）
func update_item_bag_ui():
	# 清空道具背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	# 获取过滤后的道具列表
	var filtered_items = _get_filtered_items()
	
	# 为背包中的每个道具创建按钮
	for item_data in filtered_items:
		var item_name = item_data["name"]
		var item_count = item_data["count"]
		
		# 创建道具按钮
		var button = _create_item_button(item_name)
		
		# 更新按钮文本显示数量
		button.text = str(item_name + "\n数量：" + str(item_count))
		
		# 根据模式连接不同的事件
		if main_game.is_visiting_mode:
			# 访问模式下，点击道具只显示信息，不能使用
			button.pressed.connect(func(): _on_visit_item_selected(item_name, item_count))
		elif is_pet_item_mode:
			# 宠物使用道具模式下，连接宠物道具选择事件
			button.pressed.connect(func(): _on_pet_item_selected(item_name, item_count))
		else:
			# 正常模式下，连接道具选择事件
			button.pressed.connect(func(): _on_item_selected(item_name, item_count, button))
		
		bag_grid.add_child(button)

# 创建道具按钮
func _create_item_button(item_name: String) -> Button:
	# 使用绿色按钮作为道具按钮的默认样式
	var button = main_game.item_button.duplicate()
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本
	button.text = item_name
	
	# 添加工具提示，从item_config.json获取道具信息
	var item_config = _load_item_config()
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		var description = item_info.get("描述", "暂无描述")
		var cost = item_info.get("花费", 0)
		
		button.tooltip_text = str(
			"道具: " + item_name + "\n" +
			"价格: " + str(cost) + "元\n" +
			"描述: " + description + "\n" +
			"点击选择道具，然后对地块使用"
		)
	else:
		button.tooltip_text = str("道具: " + item_name + "\n描述: 暂无信息")
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = "道具"
		button.get_node("Title").modulate = Color.CYAN  # 道具标题使用青色
	
	# 更新按钮的道具图片
	_update_button_item_image(button, item_name)
	
	return button

# 从主游戏脚本获取道具配置数据
func _load_item_config() -> Dictionary:
	# 从主游戏脚本的全局变量获取道具配置数据
	if main_game.item_config_data.size() > 0:
		return main_game.item_config_data
	else:
		print("道具背包：主游戏脚本中没有道具配置数据")
		return {}

# 设置宠物使用道具模式
func set_pet_item_mode(enabled: bool, pet_data: Dictionary = {}):
	is_pet_item_mode = enabled
	current_pet_data = pet_data
	
	# 刷新UI以应用新的模式
	update_item_bag_ui()

# 获取过滤后的道具列表
func _get_filtered_items() -> Array:
	var filtered_items = []
	
	for item_data in main_game.item_bag:
		var item_name = item_data["name"]
		
		# 如果是宠物使用道具模式，只显示宠物道具
		if is_pet_item_mode:
			if _is_pet_item(item_name):
				filtered_items.append(item_data)
		else:
			# 正常模式显示所有道具
			filtered_items.append(item_data)
	
	return filtered_items

# 检查是否为宠物道具
func _is_pet_item(item_name: String) -> bool:
	var item_config = _load_item_config()
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		var item_type = item_info.get("类型", "")
		return item_type == "宠物道具"
	return false


# 正常模式下的道具点击处理 - 选择道具
func _on_item_selected(item_name: String, item_count: int, button: Button):
	# 检查道具是否可以使用
	if not _is_item_usable(item_name):
		# 显示道具信息
		_show_item_info(item_name, item_count)
		return
	
	# 检查是否为农场道具（直接使用类型）
	if _is_farm_item(item_name):
		# 农场道具直接使用，显示确认对话框
		_show_farm_item_confirmation_dialog(item_name, item_count)
		return
	
	# 取消之前选择的道具
	if selected_item_button and selected_item_button != button:
		_deselect_item()
	
	if selected_item_name == item_name:
		# 如果点击的是已选择的道具，取消选择
		_deselect_item()
		Toast.show("已取消选择道具", Color.YELLOW, 2.0, 1.0)
	else:
		# 选择新道具
		_select_item(item_name, button)
		#点击后关闭玩家道具面板
		_on_quit_button_pressed()
		Toast.show("已选择 " + item_name + "，点击地块使用道具", Color.CYAN, 3.0, 1.0)

# 选择道具
func _select_item(item_name: String, button: Button):
	selected_item_name = item_name
	selected_item_button = button
	is_item_selected = true
	
	# 设置全局选择状态
	main_game.selected_item_name = item_name
	main_game.is_item_selected = true
	
	# 更改按钮样式表示选中
	if button.has_node("Title"):
		button.get_node("Title").modulate = Color.YELLOW  # 选中时使用黄色

# 取消选择道具
func _deselect_item():
	selected_item_name = ""
	is_item_selected = false
	
	# 清除全局选择状态
	main_game.selected_item_name = ""
	main_game.is_item_selected = false
	
	# 恢复按钮样式
	if selected_item_button and selected_item_button.has_node("Title"):
		selected_item_button.get_node("Title").modulate = Color.CYAN
	
	selected_item_button = null

# 检查道具是否可以使用
func _is_item_usable(item_name: String) -> bool:
	# 根据道具类型判断是否可以使用
	match item_name:
		"农家肥", "金坷垃", "生长素":
			return true  # 施肥道具
		"水壶", "水桶":
			return true  # 浇水道具
		"铲子","除草剂":
			return true  # 铲除道具
		"精准采集锄", "时运锄":
			return true  # 采集道具
		"小额经验卡", "小额金币卡":
			return true  # 农场道具（直接使用）
		"杀虫剂":
			return false  # 其他道具（暂不实现）
		_:
			return false

# 检查道具是否为农场道具（直接使用类型）
func _is_farm_item(item_name: String) -> bool:
	var item_config = _load_item_config()
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		var item_type = item_info.get("类型", "")
		return item_type == "农场道具"
	return false

# 显示道具信息
func _show_item_info(item_name: String, item_count: int):
	var info_text = ""
	
	var item_config = _load_item_config()
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		var description = item_info.get("描述", "暂无描述")
		var cost = item_info.get("花费", 0)
		
		info_text = item_name + " (数量: " + str(item_count) + ")\n"
		info_text += "价格: " + str(cost) + "元\n"
		info_text += "描述: " + description
		
		if not _is_item_usable(item_name):
			pass
	else:
		info_text = item_name + " (数量: " + str(item_count) + ")\n描述: 暂无信息"
	
	Toast.show(info_text, Color.CYAN, 3.0, 1.0)

# 访问模式下的道具点击处理
func _on_visit_item_selected(item_name: String, item_count: int):
	# 显示道具信息
	_show_item_info(item_name, item_count)

# 宠物使用道具模式下的道具选择处理
func _on_pet_item_selected(item_name: String, item_count: int):
	# 显示确认对话框
	_show_pet_item_confirmation_dialog(item_name, item_count)

# 显示农场道具确认对话框
func _show_farm_item_confirmation_dialog(item_name: String, item_count: int):
	# 获取道具信息
	var item_config = _load_item_config()
	var item_description = "未知效果"
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		item_description = item_info.get("描述", "未知效果")
	
	var confirmation_text = str(
		"确定要使用道具 " + item_name + " 吗？\n\n" +
		"道具效果：" + item_description + "\n\n" +
		"使用后道具数量将减少1个"
	)
	
	# 使用自定义的AcceptDialog
	var dialog = preload("res://Script/Dialog/AcceptDialog.gd").new()
	
	# 添加到场景（这会触发_ready函数）
	add_child(dialog)
	
	# 在_ready执行后设置内容
	dialog.set_dialog_title("确认使用道具")
	dialog.set_dialog_content(confirmation_text)
	dialog.set_ok_text("确认使用")
	dialog.set_cancel_text("取消")
	
	# 连接信号
	dialog.confirmed.connect(_on_confirm_farm_item_use.bind(item_name, dialog))
	dialog.canceled.connect(_on_cancel_farm_item_use.bind(dialog))
	
	# 显示对话框
	dialog.popup_centered()

# 确认使用农场道具
func _on_confirm_farm_item_use(item_name: String, dialog: AcceptDialog):
	_send_farm_item_use_request(item_name)
	dialog.queue_free()
	self.hide()

# 取消使用农场道具
func _on_cancel_farm_item_use(dialog: AcceptDialog):
	dialog.queue_free()

# 发送农场道具使用请求
func _send_farm_item_use_request(item_name: String):
	var message = {
		"type": "use_farm_item",
		"item_name": item_name
	}
	
	# 发送请求
	tcp_network_manager_panel.send_message(message)
	
	#Toast.show("正在使用道具...", Color.BLUE, 2.0, 1.0)

# 显示宠物使用道具确认对话框
func _show_pet_item_confirmation_dialog(item_name: String, item_count: int):
	if current_pet_data.is_empty():
		Toast.show("宠物数据丢失，请重新选择宠物", Color.RED, 2.0, 1.0)
		return
	
	var pet_name = current_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
	var pet_id = current_pet_data.get("基本信息", {}).get("宠物ID", "")
	
	# 获取道具信息
	var item_config = _load_item_config()
	var item_description = "未知效果"
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		item_description = item_info.get("描述", "未知效果")
	
	var confirmation_text = str(
		"确定要对宠物 " + pet_name + " 使用道具 " + item_name + " 吗？\n\n" +
		"道具效果：" + item_description + "\n\n" +
		"使用后道具数量将减少1个"
	)
	
	# 使用自定义的AcceptDialog
	var dialog = preload("res://Script/Dialog/AcceptDialog.gd").new()
	
	# 添加到场景（这会触发_ready函数）
	add_child(dialog)
	
	# 在_ready执行后设置内容
	dialog.set_dialog_title("确认使用道具")
	dialog.set_dialog_content(confirmation_text)
	dialog.set_ok_text("确认使用")
	dialog.set_cancel_text("取消")
	
	# 连接信号
	dialog.confirmed.connect(_on_confirm_pet_item_use.bind(item_name, pet_id, dialog))
	dialog.canceled.connect(_on_cancel_pet_item_use.bind(dialog))
	
	# 显示对话框
	dialog.popup_centered()

# 确认使用宠物道具
func _on_confirm_pet_item_use(item_name: String, pet_id: String, dialog: AcceptDialog):
	_send_pet_item_use_request(item_name, pet_id)
	dialog.queue_free()
	self.hide()

# 取消使用宠物道具
func _on_cancel_pet_item_use(dialog: AcceptDialog):
	dialog.queue_free()
	self.hide()

# 发送宠物使用道具请求
func _send_pet_item_use_request(item_name: String, pet_id: String):
	var message = {
		"type": "use_pet_item",
		"item_name": item_name,
		"pet_id": pet_id
	}
	
	# 发送请求
	tcp_network_manager_panel.send_message(message)
	
	# 退出宠物使用道具模式
	_exit_pet_item_mode()
	
	#Toast.show("正在使用道具...", Color.BLUE, 2.0, 1.0)

# 退出宠物使用道具模式
func _exit_pet_item_mode():
	is_pet_item_mode = false
	current_pet_data = {}
	# 刷新UI
	update_item_bag_ui()

# 更新按钮的道具图片
func _update_button_item_image(button: Button, item_name: String):
	# 检查按钮是否有CropImage节点
	var item_image = button.get_node_or_null("CropImage")
	if not item_image:
		return
	
	# 从配置文件获取道具图片路径
	var item_config = _load_item_config()
	var texture = null
	
	if item_config and item_config.has(item_name):
		var item_info = item_config[item_name]
		var image_path = item_info.get("道具图片", "")
		
		if image_path != "" and ResourceLoader.exists(image_path):
			# 尝试加载道具图片
			texture = load(image_path)
			if texture:
				pass
			else:
				print("加载道具图片失败：", item_name, " -> ", image_path)
		else:
			print("道具图片路径无效或不存在：", item_name, " -> ", image_path)
	
	# 如果没有找到道具图片，尝试使用默认道具图片
	if not texture:
		var default_item_path = "res://assets/道具图片/默认道具.webp"
		if ResourceLoader.exists(default_item_path):
			texture = load(default_item_path)
			if texture:
				print("使用默认道具图片：", item_name)
	
	# 设置图片
	if texture:
		# CropImage是Sprite2D，直接设置texture属性
		item_image.texture = texture
		item_image.visible = true
	else:
		# 如果没有图片，隐藏图片节点
		item_image.visible = false

#=========================面板通用处理=========================
# 关闭道具背包面板
func _on_quit_button_pressed() -> void:
	# 如果是宠物使用道具模式，退出该模式
	if is_pet_item_mode:
		_exit_pet_item_mode()
	
	self.hide()

#手动刷新道具背包面板
func _on_refresh_button_pressed() -> void:
	# 刷新道具背包UI
	update_item_bag_ui()
	#Toast.show("道具背包已刷新", Color.GREEN, 2.0, 1.0)
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		update_item_bag_ui()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=========================面板通用处理=========================

# 获取当前选择的道具名称
func get_selected_item_name() -> String:
	return selected_item_name

# 检查是否有道具被选择
func is_item_currently_selected() -> bool:
	return is_item_selected 

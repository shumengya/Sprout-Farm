extends Panel
# 这是道具背包面板，用来显示玩家获得的道具

# 道具背包格子容器
@onready var bag_grid: GridContainer = $ScrollContainer/Bag_Grid
@onready var quit_button : Button = $QuitButton

# 预添加常用的面板
@onready var main_game = get_node("/root/main")
@onready var network_manager = get_node("/root/main/UI/TCPNetworkManager")

# 道具使用状态
var selected_item_name: String = ""
var selected_item_button: Button = null
var is_item_selected: bool = false

# 准备函数
func _ready():
	# 隐藏面板（初始默认隐藏）
	self.hide()

# 初始化道具背包
func init_item_bag():
	# 清空道具背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	# 显示背包中的道具
	update_item_bag_ui()

# 更新道具背包UI
func update_item_bag_ui():
	# 清空道具背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	print("更新道具背包UI，背包中道具数量：", main_game.item_bag.size())
	
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

# 加载道具配置数据
func _load_item_config() -> Dictionary:
	# 从item_config.json加载道具配置数据
	var file = FileAccess.open("res://Server/config/item_config.json", FileAccess.READ)
	if not file:
		print("无法读取道具配置文件！")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("道具配置JSON解析错误：", json.get_error_message())
		return {}
	
	return json.get_data()

# 正常模式下的道具点击处理 - 选择道具
func _on_item_selected(item_name: String, item_count: int, button: Button):
	# 检查道具是否可以使用
	if not _is_item_usable(item_name):
		# 显示道具信息
		_show_item_info(item_name, item_count)
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
		"铲子":
			return true  # 铲除道具
		"除草剂":
			return true  # 除草道具
		"精准采集锄", "时运锄":
			return true  # 采集道具
		"杀虫剂":
			return false  # 其他道具（暂不实现）
		_:
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
			info_text += "\n注意: 此道具功能暂未实现"
	else:
		info_text = item_name + " (数量: " + str(item_count) + ")\n描述: 暂无信息"
	
	Toast.show(info_text, Color.CYAN, 3.0, 1.0)

# 访问模式下的道具点击处理
func _on_visit_item_selected(item_name: String, item_count: int):
	# 显示道具信息
	_show_item_info(item_name, item_count)

# 更新按钮的道具图片
func _update_button_item_image(button: Button, item_name: String):
	# 检查按钮是否有CropImage节点
	var item_image = button.get_node_or_null("CropImage")
	if not item_image:
		print("道具背包按钮没有找到CropImage节点：", button.name)
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
				print("成功加载道具图片：", item_name, " -> ", image_path)
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
		print("道具背包更新道具图片：", item_name)
	else:
		# 如果没有图片，隐藏图片节点
		item_image.visible = false
		print("道具背包无法获取道具图片：", item_name)

#=========================面板通用处理=========================
# 关闭道具背包面板
func _on_quit_button_pressed() -> void:
	# 打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	self.hide()

#手动刷新道具背包面板
func _on_refresh_button_pressed() -> void:
	# 刷新道具背包UI
	update_item_bag_ui()
	Toast.show("道具背包已刷新", Color.GREEN, 2.0, 1.0)
#=========================面板通用处理=========================

# 获取当前选择的道具名称
func get_selected_item_name() -> String:
	return selected_item_name

# 检查是否有道具被选择
func is_item_currently_selected() -> bool:
	return is_item_selected 

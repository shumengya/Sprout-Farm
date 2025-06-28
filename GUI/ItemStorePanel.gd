extends Panel
# 这是道具商店面板，用来展示各种道具

# 道具商店格子容器
@onready var store_grid: GridContainer = $ScrollContainer/Store_Grid
@onready var quit_button : Button = $QuitButton

# 预添加常用的面板
@onready var main_game = get_node("/root/main")
@onready var network_manager = get_node("/root/main/UI/TCPNetworkManager")

# 道具配置数据
var item_config : Dictionary = {}

# 准备函数
func _ready():
	# 连接关闭按钮信号
	quit_button.pressed.connect(self._on_quit_button_pressed)
	
	# 隐藏面板（初始默认隐藏）
	self.hide()

# 初始化道具商店
func init_item_store():
	# 加载道具配置数据
	_load_item_config()
	
	# 清空道具商店格子
	for child in store_grid.get_children():
		child.queue_free()
	
	# 显示商店中的道具
	update_item_store_ui()

# 更新道具商店UI
func update_item_store_ui():
	# 清空道具商店格子
	for child in store_grid.get_children():
		child.queue_free()
	
	print("更新道具商店UI，道具种类：", item_config.size())
	
	# 为每个道具配置创建按钮
	for item_name in item_config.keys():
		var item_info = item_config[item_name]
		var item_cost = item_info.get("花费", 0)
		var item_desc = item_info.get("描述", "暂无描述")
		
		# 创建道具按钮
		var button = _create_item_button(item_name, item_cost, item_desc)
		
		# 更新按钮文本显示价格
		button.text = str(item_name + "\n价格：" + str(item_cost) + "元")
		
		# 连接购买点击事件
		button.pressed.connect(func(): _on_store_item_selected(item_name, item_cost, item_desc))
		
		store_grid.add_child(button)

# 创建道具按钮
func _create_item_button(item_name: String, item_cost: int, item_desc: String) -> Button:
	# 使用橙色按钮作为道具商店按钮的样式
	var button = main_game.item_button.duplicate()
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本
	button.text = item_name
	
	# 添加工具提示
	button.tooltip_text = str(
		"道具: " + item_name + "\n" +
		"价格: " + str(item_cost) + "元\n" +
		"描述: " + item_desc + "\n" +
		"点击购买道具"
	)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = "商店"
		button.get_node("Title").modulate = Color.GOLD  # 商店标题使用金色
	
	# 更新按钮的道具图片
	_update_button_item_image(button, item_name)
	
	return button

# 加载道具配置数据
func _load_item_config():
	# 从item_config.json加载道具配置数据
	var file = FileAccess.open("res://Server/config/item_config.json", FileAccess.READ)
	if not file:
		print("无法读取道具配置文件！")
		item_config = {}
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("道具配置JSON解析错误：", json.get_error_message())
		item_config = {}
		return
	
	item_config = json.get_data()
	print("成功加载道具配置，道具种类：", item_config.size())

# 商店道具点击处理 - 购买道具
func _on_store_item_selected(item_name: String, item_cost: int, item_desc: String):
	# 检查玩家金钱是否足够
	if main_game.money < item_cost:
		Toast.show("金钱不足！需要 " + str(item_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		return
	
	# 显示购买确认对话框
	_show_buy_confirmation_dialog(item_name, item_cost, item_desc)

# 显示购买确认对话框
func _show_buy_confirmation_dialog(item_name: String, item_cost: int, item_desc: String):
	# 创建确认对话框
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = str(
		"确认购买道具？\n\n" +
		"道具名称: " + item_name + "\n" +
		"购买价格: " + str(item_cost) + " 元\n" +
		"道具描述: " + item_desc + "\n\n" +
		"当前金钱: " + str(main_game.money) + " 元\n" +
		"购买后余额: " + str(main_game.money - item_cost) + " 元"
	)
	confirm_dialog.title = "购买道具确认"
	confirm_dialog.ok_button_text = "确认购买"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_buy_item.bind(item_name, item_cost, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_buy_item.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认购买道具
func _on_confirm_buy_item(item_name: String, item_cost: int, dialog: AcceptDialog):
	if network_manager and network_manager.has_method("sendBuyItem"):
		if network_manager.sendBuyItem(item_name, item_cost):
			Toast.show("正在购买 " + item_name + "...", Color.YELLOW, 2.0, 1.0)
		else:
			Toast.show("发送购买请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络管理器不可用", Color.RED, 2.0, 1.0)
	
	# 清理对话框
	if dialog:
		dialog.queue_free()

# 取消购买道具
func _on_cancel_buy_item(dialog: AcceptDialog):
	if dialog:
		dialog.queue_free()

# 更新按钮的道具图片
func _update_button_item_image(button: Button, item_name: String):
	# 检查按钮是否有CropImage节点
	var item_image = button.get_node_or_null("CropImage")
	if not item_image:
		print("道具商店按钮没有找到CropImage节点：", button.name)
		return
	
	# 从配置文件获取道具图片路径
	var texture = null
	
	if item_config.has(item_name):
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
		print("道具商店更新道具图片：", item_name)
	else:
		# 如果没有图片，隐藏图片节点
		item_image.visible = false
		print("道具商店无法获取道具图片：", item_name)


#=========================面板通用处理=========================
#手动刷新道具商店面板
func _on_refresh_button_pressed() -> void:
	# 重新初始化道具商店
	init_item_store()
	Toast.show("道具商店已刷新", Color.GREEN, 2.0, 1.0)

# 关闭道具商店面板
func _on_quit_button_pressed() -> void:
	# 打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	self.hide()
	pass 

#=========================面板通用处理=========================

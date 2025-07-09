extends Panel
# 这是道具商店面板，用来展示各种道具

# 道具商店格子容器
@onready var store_grid: GridContainer = $ScrollContainer/Store_Grid
@onready var quit_button : Button = $QuitButton
@onready var refresh_button : Button = $RefreshButton

# 预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var batch_buy_popup: PanelContainer = $'../../DiaLog/BatchBuyPopup'


# 道具配置数据
var item_config : Dictionary = {}

# 准备函数
func _ready():
	# 连接关闭按钮信号
	quit_button.pressed.connect(self._on_quit_button_pressed)
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 隐藏面板（初始默认隐藏）
	self.hide()

# 初始化道具商店
func init_item_store():
	# 从主游戏脚本获取道具配置数据
	_load_item_config_from_main()
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

# 从主游戏脚本获取道具配置数据
func _load_item_config_from_main():
	# 从主游戏脚本的全局变量获取道具配置数据
	if main_game.item_config_data.size() > 0:
		item_config = main_game.item_config_data
		print("道具商店：从主游戏脚本获取道具配置数据，道具种类：", item_config.size())
	else:
		print("道具商店：主游戏脚本中没有道具配置数据，使用空配置")
		item_config = {}


# 商店道具点击处理 - 购买道具
func _on_store_item_selected(item_name: String, item_cost: int, item_desc: String):
	# 检查玩家金钱是否足够（至少能买1个）
	if main_game.money < item_cost:
		Toast.show("金钱不足！需要 " + str(item_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		return
	
	# 显示批量购买弹窗
	if batch_buy_popup:
		batch_buy_popup.show_buy_popup(
			item_name, 
			item_cost, 
			item_desc, 
			"item", 
			_on_confirm_buy_item,
			_on_cancel_buy_item
		)
	else:
		print("批量购买弹窗未找到")

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

# 确认购买道具（批量购买版本）
func _on_confirm_buy_item(item_name: String, unit_cost: int, quantity: int, buy_type: String):
	var total_cost = unit_cost * quantity
	
	# 再次检查金钱是否足够
	if main_game.money < total_cost:
		Toast.show("金钱不足！需要 " + str(total_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		return
	
	# 发送批量购买请求到服务器
	_send_batch_buy_item_request(item_name, unit_cost, quantity)

# 取消购买道具（批量购买版本）
func _on_cancel_buy_item():
	print("取消购买道具")

# 发送批量购买道具请求
func _send_batch_buy_item_request(item_name: String, unit_cost: int, quantity: int):
	# 发送批量购买请求到服务器
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendBuyItem"):
		if tcp_network_manager_panel.sendBuyItem(item_name, unit_cost, quantity):
			# 服务器会处理批量购买逻辑，客户端等待响应
			print("已发送批量购买道具请求：", item_name, " 数量：", quantity)
		else:
			Toast.show("购买请求发送失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络管理器不可用", Color.RED, 2.0, 1.0)

# 将道具添加到道具背包（客户端同步）
func _add_item_to_bag(item_name: String):
	# 确保道具背包存在
	if "道具背包" not in main_game:
		main_game["道具背包"] = []
	
	# 查找是否已存在该道具
	var found = false
	for item in main_game["道具背包"]:
		if item.get("name") == item_name:
			item["count"] += 1
			found = true
			break
	
	# 如果不存在，添加新道具
	if not found:
		main_game["道具背包"].append({
			"name": item_name,
			"count": 1
		})

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
	self.hide()
	pass 


#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时自动刷新数据
		init_item_store()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=========================面板通用处理=========================

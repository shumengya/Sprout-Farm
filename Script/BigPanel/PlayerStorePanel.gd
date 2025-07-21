extends Panel
#玩家小卖部（目前可以卖道具，种子，成熟作物）
#初始玩家有10个格子
#然后玩家额外购买格子需要1000元，多加一个格子加500元，最多40个格子，格子满了不能再放了
#玩家自己点击自己的摊位（商品格子）显示弹窗是否要取消放置商品 
#别人拜访玩家打开小卖部点击被拜访玩家的摊位显示批量购买弹窗
@onready var quit_button: Button = $QuitButton #关闭玩家小卖部面板
@onready var refresh_button: Button = $RefreshButton #刷新小卖部按钮
@onready var store_grid: GridContainer = $ScrollContainer/Store_Grid #小卖部商品格子
@onready var buy_product_booth_button: Button = $BuyProductBoothButton #购买格子按钮

# 获取主游戏引用
@onready var main_game = get_node("/root/main")

# 当前小卖部数据
var player_store_data: Array = []
var max_store_slots: int = 10  # 默认10个格子

func _ready():
	# 连接按钮信号
	quit_button.pressed.connect(_on_quit_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	buy_product_booth_button.pressed.connect(_on_buy_product_booth_button_pressed)
	
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 默认隐藏面板
	self.hide()

#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时更新小卖部数据
		update_player_store_ui()
	else:
		GlobalVariables.isZoomDisabled = false

# 初始化玩家小卖部
func init_player_store():
	update_player_store_ui()

# 更新小卖部UI
func update_player_store_ui():
	# 清空商品格子
	for child in store_grid.get_children():
		child.queue_free()
	
	# 获取小卖部数据
	if main_game.is_visiting_mode:
		# 访问模式：显示被访问玩家的小卖部
		player_store_data = main_game.visited_player_data.get("玩家小卖部", [])
		max_store_slots = main_game.visited_player_data.get("小卖部格子数", 10)
		buy_product_booth_button.hide()  # 访问模式下隐藏购买格子按钮
	else:
		# 正常模式：显示自己的小卖部
		player_store_data = main_game.login_data.get("玩家小卖部", [])
		max_store_slots = main_game.login_data.get("小卖部格子数", 10)
		buy_product_booth_button.show()  # 正常模式下显示购买格子按钮
	
	# 创建商品按钮
	_create_store_buttons()
	
	# 更新购买格子按钮文本
	_update_buy_booth_button()

# 创建小卖部商品按钮
func _create_store_buttons():
	# 为每个格子创建按钮
	for i in range(max_store_slots):
		var button = _create_store_slot_button(i)
		store_grid.add_child(button)

# 创建单个商品格子按钮
func _create_store_slot_button(slot_index: int) -> Button:
	var button = main_game.item_button.duplicate()
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 检查该格子是否有商品
	var product_data = null
	if slot_index < player_store_data.size():
		product_data = player_store_data[slot_index]
	
	if product_data:
		# 有商品的格子
		var product_name = product_data.get("商品名称", "未知商品")
		var product_price = product_data.get("商品价格", 0)
		var product_count = product_data.get("商品数量", 0)
		var product_type = product_data.get("商品类型", "作物")
		
		# 设置按钮文本
		button.text = str(product_name + "\n" + str(product_price) + "元/个\n库存:" + str(product_count))
		
		# 更新商品图片
		_update_button_product_image(button, product_name, product_type)
		
		# 设置工具提示
		button.tooltip_text = str(
			"商品: " + product_name + "\n" +
			"类型: " + product_type + "\n" +
			"单价: " + str(product_price) + " 元\n" +
			"库存: " + str(product_count) + " 个"
		)
		
		# 连接点击事件
		if main_game.is_visiting_mode:
			# 访问模式：显示购买弹窗
			button.pressed.connect(func(): _on_product_buy_selected(product_data, slot_index))
		else:
			# 自己的小卖部：显示移除商品弹窗
			button.pressed.connect(func(): _on_product_manage_selected(product_data, slot_index))
	else:
		# 空格子
		button.text = "空闲格子\n\n点击添加商品"
		
		# 设置为灰色样式
		if button.has_node("Title"):
			button.get_node("Title").modulate = Color.GRAY
		
		# 只有在非访问模式下才允许点击空格子
		if not main_game.is_visiting_mode:
			button.pressed.connect(func(): _on_empty_slot_selected(slot_index))
		else:
			button.disabled = true
	
	return button

# 更新商品图片
func _update_button_product_image(button: Button, product_name: String, product_type: String):
	var crop_image = button.get_node_or_null("CropImage")
	if not crop_image:
		return
	
	var texture = null
	
	if product_type == "作物":
		# 作物商品：加载收获物图片
		texture = _get_crop_harvest_texture(product_name)
	# 未来可以添加其他类型的商品图片加载
	
	if texture:
		crop_image.texture = texture
		crop_image.visible = true
	else:
		crop_image.visible = false

# 获取作物的收获物图片
func _get_crop_harvest_texture(crop_name: String) -> Texture2D:
	var crop_path = "res://assets/作物/" + crop_name + "/"
	var harvest_texture_path = crop_path + "收获物.webp"
	
	if ResourceLoader.exists(harvest_texture_path):
		var texture = load(harvest_texture_path)
		if texture:
			return texture
	
	# 如果没有找到，使用默认的收获物图片
	var default_harvest_path = "res://assets/作物/默认/收获物.webp"
	if ResourceLoader.exists(default_harvest_path):
		var texture = load(default_harvest_path)
		if texture:
			return texture
	
	return null

# 访问模式：点击商品购买
func _on_product_buy_selected(product_data: Dictionary, slot_index: int):
	var product_name = product_data.get("商品名称", "未知商品")
	var product_price = product_data.get("商品价格", 0)
	var product_count = product_data.get("商品数量", 0)
	var product_type = product_data.get("商品类型", "作物")
	
	# 检查商品是否还有库存
	if product_count <= 0:
		Toast.show("该商品已售罄", Color.RED, 2.0, 1.0)
		return
	
	# 获取批量购买弹窗
	var batch_buy_popup = get_node_or_null("/root/main/UI/DiaLog/BatchBuyPopup")
	if batch_buy_popup and batch_buy_popup.has_method("show_buy_popup"):
		# 显示批量购买弹窗
		batch_buy_popup.show_buy_popup(
			product_name,
			product_price,
			"玩家小卖部商品",
			"store_product",  # 特殊类型标识
			_on_confirm_buy_store_product,
			_on_cancel_buy_store_product
		)
		
		# 临时保存购买信息
		batch_buy_popup.set_meta("store_slot_index", slot_index)
		batch_buy_popup.set_meta("store_product_data", product_data)
	else:
		Toast.show("购买功能暂未实现", Color.RED, 2.0, 1.0)

# 确认购买小卖部商品
func _on_confirm_buy_store_product(product_name: String, unit_price: int, quantity: int, buy_type: String):
	var slot_index = get_node("/root/main/UI/DiaLog/BatchBuyPopup").get_meta("store_slot_index", -1)
	var product_data = get_node("/root/main/UI/DiaLog/BatchBuyPopup").get_meta("store_product_data", {})
	
	if slot_index == -1 or product_data.is_empty():
		Toast.show("购买信息错误", Color.RED, 2.0, 1.0)
		return
	
	# 发送购买请求到服务器
	var tcp_network_manager = get_node_or_null("/root/main/UI/BigPanel/TCPNetworkManagerPanel")
	if tcp_network_manager and tcp_network_manager.has_method("send_message"):
		var visited_player_name = main_game.visited_player_data.get("玩家昵称", "")
		var message = {
			"type": "buy_store_product",
			"seller_username": main_game.visited_player_data.get("username", ""),
			"slot_index": slot_index,
			"product_name": product_name,
			"unit_price": unit_price,
			"quantity": quantity
		}
		tcp_network_manager.send_message(message)
		
		Toast.show("购买请求已发送", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("网络连接异常，无法购买", Color.RED, 2.0, 1.0)

# 取消购买小卖部商品
func _on_cancel_buy_store_product():
	# 不需要做任何事情，弹窗会自动关闭
	pass

# 自己的小卖部：点击商品管理
func _on_product_manage_selected(product_data: Dictionary, slot_index: int):
	var product_name = product_data.get("商品名称", "未知商品")
	var product_count = product_data.get("商品数量", 0)
	
	# 显示管理确认对话框
	_show_product_manage_dialog(product_name, product_count, slot_index)

# 显示商品管理对话框
func _show_product_manage_dialog(product_name: String, product_count: int, slot_index: int):
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = str(
		"商品管理\n\n" +
		"商品：" + product_name + "\n" +
		"库存：" + str(product_count) + " 个\n\n" +
		"确认要下架这个商品吗？\n" +
		"商品将返回到您的仓库中。"
	)
	confirm_dialog.title = "商品管理"
	confirm_dialog.ok_button_text = "下架商品"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_remove_product.bind(slot_index, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_remove_product.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认下架商品
func _on_confirm_remove_product(slot_index: int, dialog: AcceptDialog):
	# 发送下架商品请求到服务器
	var tcp_network_manager = get_node_or_null("/root/main/UI/BigPanel/TCPNetworkManagerPanel")
	if tcp_network_manager and tcp_network_manager.has_method("send_message"):
		var message = {
			"type": "remove_store_product",
			"slot_index": slot_index
		}
		tcp_network_manager.send_message(message)
		
		Toast.show("下架请求已发送", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("网络连接异常，无法下架", Color.RED, 2.0, 1.0)
	
	dialog.queue_free()

# 取消下架商品
func _on_cancel_remove_product(dialog: AcceptDialog):
	dialog.queue_free()

# 点击空格子
func _on_empty_slot_selected(slot_index: int):
	Toast.show("请从作物仓库选择商品添加到小卖部", Color.CYAN, 3.0, 1.0)

# 更新购买格子按钮
func _update_buy_booth_button():
	if main_game.is_visiting_mode:
		return
	
	var next_slot_cost = 1000 + (max_store_slots - 10) * 500
	if max_store_slots >= 40:
		buy_product_booth_button.text = "格子已满(40/40)"
		buy_product_booth_button.disabled = true
	else:
		buy_product_booth_button.text = str("购买格子(+" + str(next_slot_cost) + "元)")
		buy_product_booth_button.disabled = false

# 购买格子按钮处理
func _on_buy_product_booth_button_pressed():
	if main_game.is_visiting_mode:
		return
	
	if max_store_slots >= 40:
		Toast.show("格子数量已达上限", Color.RED, 2.0, 1.0)
		return
	
	var next_slot_cost = 1000 + (max_store_slots - 10) * 500
	
	if main_game.money < next_slot_cost:
		Toast.show("金钱不足，需要 " + str(next_slot_cost) + " 元", Color.RED, 2.0, 1.0)
		return
	
	# 显示购买确认对话框
	_show_buy_booth_dialog(next_slot_cost)

# 显示购买格子确认对话框
func _show_buy_booth_dialog(cost: int):
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = str(
		"购买小卖部格子\n\n" +
		"费用：" + str(cost) + " 元\n" +
		"当前格子数：" + str(max_store_slots) + "\n" +
		"购买后格子数：" + str(max_store_slots + 1) + "\n\n" +
		"确认购买吗？"
	)
	confirm_dialog.title = "购买格子"
	confirm_dialog.ok_button_text = "确认购买"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_buy_booth.bind(cost, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_buy_booth.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认购买格子
func _on_confirm_buy_booth(cost: int, dialog: AcceptDialog):
	# 发送购买格子请求到服务器
	var tcp_network_manager = get_node_or_null("/root/main/UI/BigPanel/TCPNetworkManagerPanel")
	if tcp_network_manager and tcp_network_manager.has_method("send_message"):
		var message = {
			"type": "buy_store_booth",
			"cost": cost
		}
		tcp_network_manager.send_message(message)
		
		Toast.show("购买请求已发送", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("网络连接异常，无法购买", Color.RED, 2.0, 1.0)
	
	dialog.queue_free()

# 取消购买格子
func _on_cancel_buy_booth(dialog: AcceptDialog):
	dialog.queue_free()

# 关闭面板
func _on_quit_button_pressed():
	self.hide()

# 刷新小卖部
func _on_refresh_button_pressed():
	update_player_store_ui()
	Toast.show("小卖部已刷新", Color.GREEN, 2.0, 1.0)

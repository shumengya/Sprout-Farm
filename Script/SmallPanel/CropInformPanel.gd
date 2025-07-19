extends Panel

@onready var quit_button: Button = $QuitButton #关闭作物信息面板
@onready var crop_image: TextureRect = $VBox/CropImage #显示作物图片
@onready var crop_name: Label = $VBox/CropName #作物名称
@onready var crop_description: Label = $VBox/CropDescription #作物介绍
@onready var crop_price: Label = $VBox/CropPrice #作物价格
@onready var crop_quality: Label = $VBox/CropQuality #作物品质
@onready var sale_product: Button = $VBox/HBox/SaleProduct #直接出售
@onready var add_to_store: Button = $VBox/HBox/AddToStore #添加到小卖部

@onready var add_product_to_store_popup: PanelContainer = $'../../DiaLog/AddProductToStorePopup'



# 当前显示的作物信息
var current_crop_name: String = ""
var current_crop_count: int = 0

# 获取主游戏引用
@onready var main_game = get_node("/root/main")

func _ready():
	# 连接按钮信号
	quit_button.pressed.connect(_on_quit_button_pressed)
	sale_product.pressed.connect(_on_sale_product_pressed)
	add_to_store.pressed.connect(_on_add_to_store_pressed)
	
	# 默认隐藏面板
	self.hide()

# 显示作物信息
func show_crop_info(crop_name: String, crop_count: int):
	current_crop_name = crop_name
	current_crop_count = crop_count
	
	# 更新作物信息显示
	_update_crop_display()
	
	# 显示面板
	self.show()
	self.move_to_front()

# 更新作物信息显示
func _update_crop_display():
	if not main_game.can_planted_crop.has(current_crop_name):
		crop_name.text = "作物名称：" + current_crop_name
		crop_description.text = "描述：未知作物"
		crop_price.text = "收购价：未知"
		crop_quality.text = "品质：未知"
		return
	
	var crop_data = main_game.can_planted_crop[current_crop_name]
	
	# 获取显示名称
	var display_name = current_crop_name
	var mature_name = crop_data.get("成熟物名称")
	if mature_name != null and mature_name != "":
		display_name = mature_name
	else:
		display_name = crop_data.get("作物名称", current_crop_name)
	
	# 更新文本显示
	crop_name.text = "作物名称：" + display_name + " (数量: " + str(current_crop_count) + ")"
	crop_description.text = "描述：" + crop_data.get("描述", "美味的作物")
	
	# 计算出售价格（基于收益）
	var sell_price = crop_data.get("收益", 0)
	crop_price.text = "收购价：" + str(sell_price) + " 元/个"
	
	var quality = crop_data.get("品质", "普通")
	crop_quality.text = "品质：" + quality
	
	# 更新作物图片
	_update_crop_image()

# 更新作物图片
func _update_crop_image():
	var texture = _get_crop_harvest_texture(current_crop_name)
	if texture:
		crop_image.texture = texture
	else:
		# 使用默认图片
		var default_texture = _get_crop_harvest_texture("默认")
		if default_texture:
			crop_image.texture = default_texture

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

# 关闭面板
func _on_quit_button_pressed():
	self.hide()

# 直接出售按钮处理
func _on_sale_product_pressed():
	# 检查是否在访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法出售作物", Color.ORANGE, 2.0, 1.0)
		return
	
	# 获取批量出售弹窗
	var batch_sell_popup = get_node_or_null("/root/main/UI/DiaLog/BatchSellPopup")
	if batch_sell_popup and batch_sell_popup.has_method("show_sell_popup"):
		# 获取作物数据以传递给出售弹窗
		var crop_data = main_game.can_planted_crop.get(current_crop_name, {})
		var sell_price = crop_data.get("收益", 0)
		var description = crop_data.get("描述", "美味的作物")
		
		# 显示批量出售弹窗
		batch_sell_popup.show_sell_popup(
			current_crop_name,
			current_crop_count,
			sell_price,
			description,
			_on_confirm_sell_crop,
			_on_cancel_sell_crop
		)
	else:
		Toast.show("批量出售功能暂未实现", Color.RED, 2.0, 1.0)
		print("错误：找不到BatchSellPopup或相关方法")

# 确认出售作物回调
func _on_confirm_sell_crop(crop_name: String, sell_count: int, unit_price: int):
	# 发送出售请求到服务器
	var tcp_network_manager = get_node_or_null("/root/main/UI/BigPanel/TCPNetworkManagerPanel")
	if tcp_network_manager and tcp_network_manager.has_method("send_message"):
		var message = {
			"type": "sell_crop",
			"crop_name": crop_name,
			"sell_count": sell_count,
			"unit_price": unit_price
		}
		tcp_network_manager.send_message(message)
		
		# 关闭作物信息面板
		self.hide()
		
		Toast.show("出售请求已发送", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("网络连接异常，无法出售", Color.RED, 2.0, 1.0)

# 取消出售作物回调
func _on_cancel_sell_crop():
	# 不需要做任何事情，弹窗会自动关闭
	pass

# 添加到小卖部按钮处理
func _on_add_to_store_pressed():
	# 检查是否在访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法操作小卖部", Color.ORANGE, 2.0, 1.0)
		return
	
	# 获取添加商品到小卖部的弹窗

	if add_product_to_store_popup and add_product_to_store_popup.has_method("show_add_product_popup"):
		# 获取作物数据以传递给弹窗
		var crop_data = main_game.can_planted_crop.get(current_crop_name, {})
		var sell_price = crop_data.get("收益", 0)
		var description = crop_data.get("描述", "美味的作物")
		
		# 显示添加商品弹窗
		add_product_to_store_popup.show_add_product_popup(
			current_crop_name,
			current_crop_count,
			sell_price,
			description,
			_on_confirm_add_to_store,
			_on_cancel_add_to_store
		)
	else:
		Toast.show("添加商品功能暂未实现", Color.RED, 2.0, 1.0)
		print("错误：找不到AddProduct2StorePopup或相关方法")

# 确认添加到小卖部回调
func _on_confirm_add_to_store(crop_name: String, add_count: int, unit_price: int):
	# 发送添加商品到小卖部的请求到服务器
	var tcp_network_manager = get_node_or_null("/root/main/UI/BigPanel/TCPNetworkManagerPanel")
	if tcp_network_manager and tcp_network_manager.has_method("send_message"):
		var message = {
			"type": "add_product_to_store",
			"product_type": "作物",
			"product_name": crop_name,
			"product_count": add_count,
			"product_price": unit_price
		}
		tcp_network_manager.send_message(message)
		
		# 关闭作物信息面板
		self.hide()
		
		Toast.show("添加商品请求已发送", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("网络连接异常，无法添加商品", Color.RED, 2.0, 1.0)

# 取消添加到小卖部回调
func _on_cancel_add_to_store():
	# 不需要做任何事情，弹窗会自动关闭
	pass

extends PanelContainer
#用于添加商品到玩家小卖部的弹窗
@onready var title: Label = $VBox/Title #弹窗标题
@onready var contents: Label = $VBox/Contents #这里显示弹窗内容
@onready var sell_num_input: LineEdit = $VBox/SellNumInput #这里输入需要放入小卖部的商品数量
@onready var sell_price_input: LineEdit = $VBox/SellPriceInput #这里输入每件商品的价格
@onready var sure_button: Button = $VBox/HBox/SureButton #确定放入按钮
@onready var cancel_button: Button = $VBox/HBox/CancelButton #取消按钮

# 当前要添加的商品信息
var current_product_name: String = ""
var current_max_count: int = 0
var current_suggested_price: int = 0
var current_product_desc: String = ""

# 回调函数，用于处理确认添加
var confirm_callback: Callable
var cancel_callback: Callable

func _ready():
	# 连接按钮信号
	sure_button.pressed.connect(_on_sure_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 设置输入框的默认值和限制
	sell_num_input.text = "1"
	sell_num_input.placeholder_text = "请输入数量"
	sell_price_input.placeholder_text = "请输入单价"
	
	# 只允许输入数字
	sell_num_input.text_changed.connect(_on_sell_num_changed)
	sell_price_input.text_changed.connect(_on_sell_price_changed)
	
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 默认隐藏弹窗
	self.hide()

#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

# 显示添加商品弹窗
func show_add_product_popup(product_name: String, max_count: int, suggested_price: int, product_desc: String, on_confirm: Callable, on_cancel: Callable = Callable()):
	current_product_name = product_name
	current_max_count = max_count
	current_suggested_price = suggested_price
	current_product_desc = product_desc
	confirm_callback = on_confirm
	cancel_callback = on_cancel
	
	# 设置弹窗内容
	title.text = "添加商品到小卖部"
	
	contents.text = str(
		"商品名称: " + product_name + "\n" +
		"可用数量: " + str(max_count) + " 个\n" +
		"建议价格: " + str(suggested_price) + " 元/个\n" +
		"描述: " + product_desc + "\n\n" +
		"请设置出售数量和价格:"
	)
	
	# 设置默认值
	sell_num_input.text = "1"
	sell_price_input.text = str(suggested_price)
	
	# 显示弹窗并居中
	self.show()
	self.move_to_front()

# 处理数量输入变化
func _on_sell_num_changed(new_text: String):
	# 只允许输入数字
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_int():
			filtered_text += char
	
	# 检查是否超过最大值并自动修正
	if not filtered_text.is_empty():
		var quantity = filtered_text.to_int()
		if quantity > current_max_count:
			filtered_text = str(current_max_count)
	
	if filtered_text != new_text:
		sell_num_input.text = filtered_text
		sell_num_input.caret_column = filtered_text.length()
	
	# 更新预览信息
	_update_preview_info()

# 处理价格输入变化
func _on_sell_price_changed(new_text: String):
	# 只允许输入数字
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_int():
			filtered_text += char
	
	# 检查是否超过最大值并自动修正
	if not filtered_text.is_empty():
		var price = filtered_text.to_int()
		if price > 999999999:
			filtered_text = "999999999"
	
	if filtered_text != new_text:
		sell_price_input.text = filtered_text
		sell_price_input.caret_column = filtered_text.length()
	
	# 更新预览信息
	_update_preview_info()

# 更新预览信息
func _update_preview_info():
	var quantity = get_sell_quantity()
	var unit_price = get_sell_price()
	var total_value = quantity * unit_price
	
	# 检查数量是否超过最大可用数量
	var quantity_status = ""
	if quantity > current_max_count:
		quantity_status = " (超出库存！)"
	
	# 检查价格是否合理
	var price_status = ""
	if unit_price <= 0:
		price_status = " (价格无效！)"
	elif unit_price < current_suggested_price * 0.5:
		price_status = " (价格偏低)"
	elif unit_price > current_suggested_price * 2:
		price_status = " (价格偏高)"
	
	var preview_info = "\n上架数量: " + str(quantity) + " 个" + quantity_status + "\n单价: " + str(unit_price) + " 元/个" + price_status + "\n总价值: " + str(total_value) + " 元"
	
	# 更新内容显示
	var base_content = str(
		"商品名称: " + current_product_name + "\n" +
		"可用数量: " + str(current_max_count) + " 个\n" +
		"建议价格: " + str(current_suggested_price) + " 元/个\n" +
		"描述: " + current_product_desc + "\n\n" +
		"请设置出售数量和价格:"
	)
	
	contents.text = base_content + preview_info

# 获取出售数量
func get_sell_quantity() -> int:
	var text = sell_num_input.text.strip_edges()
	if text.is_empty():
		return 1
	
	var quantity = text.to_int()
	quantity = max(1, quantity) # 至少出售1个
	quantity = min(quantity, current_max_count) # 不超过最大值
	return quantity

# 获取出售价格
func get_sell_price() -> int:
	var text = sell_price_input.text.strip_edges()
	if text.is_empty():
		return current_suggested_price
	
	var price = text.to_int()
	price = max(1, price) # 至少1元
	price = min(price, 999999999) # 不超过最大值
	return price

# 确认添加按钮处理
func _on_sure_button_pressed():
	var quantity = get_sell_quantity()
	var unit_price = get_sell_price()
	
	if quantity <= 0:
		_show_error("数量必须大于0")
		return
	
	if quantity > current_max_count:
		_show_error("数量不能超过库存数量(" + str(current_max_count) + ")")
		return
	
	if unit_price <= 0:
		_show_error("价格必须大于0")
		return
	
	# 调用确认回调函数
	if confirm_callback.is_valid():
		confirm_callback.call(current_product_name, quantity, unit_price)
	
	# 隐藏弹窗
	self.hide()

# 取消添加按钮处理
func _on_cancel_button_pressed():
	# 调用取消回调函数
	if cancel_callback.is_valid():
		cancel_callback.call()
	
	# 隐藏弹窗
	self.hide()

# 显示错误信息
func _show_error(message: String):
	# 显示Toast错误提示
	if has_node("/root/Toast"):
		get_node("/root/Toast").show(message, Color.RED, 2.0, 1.0)
	else:
		print("添加商品弹窗错误: " + message)

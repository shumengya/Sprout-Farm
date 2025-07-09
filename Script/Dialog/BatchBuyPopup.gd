extends PanelContainer
#这是批量购买弹窗
@onready var title: Label = $VBox/Title #弹窗标题
@onready var contents: Label = $VBox/Contents #弹窗内容
@onready var buy_num_edit: LineEdit = $VBox/BuyNumEdit #购买数量
@onready var sure_button: Button = $VBox/HBox/SureButton #确认购买
@onready var cancel_button: Button = $VBox/HBox/CancelButton #取消购买

# 当前购买的商品信息
var current_item_name: String = ""
var current_item_cost: int = 0
var current_item_desc: String = ""
var current_buy_type: String = "" # "seed" 或 "item"

# 回调函数，用于处理确认购买
var confirm_callback: Callable
var cancel_callback: Callable

func _ready():
	# 连接按钮信号
	sure_button.pressed.connect(_on_sure_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 设置数量输入框的默认值和限制
	buy_num_edit.text = "1"
	buy_num_edit.placeholder_text = "请输入购买数量"
	
	# 只允许输入数字
	buy_num_edit.text_changed.connect(_on_buy_num_changed)
	
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

# 显示批量购买弹窗
func show_buy_popup(item_name: String, item_cost: int, item_desc: String, buy_type: String, on_confirm: Callable, on_cancel: Callable = Callable()):
	current_item_name = item_name
	current_item_cost = item_cost
	current_item_desc = item_desc
	current_buy_type = buy_type
	confirm_callback = on_confirm
	cancel_callback = on_cancel
	
	# 设置弹窗内容
	if buy_type == "seed":
		title.text = "批量购买种子"
	else:
		title.text = "批量购买道具"
	
	contents.text = str(
		"商品名称: " + item_name + "\n" +
		"单价: " + str(item_cost) + " 元\n" +
		"描述: " + item_desc + "\n\n" +
		"请输入购买数量:"
	)
	
	# 重置购买数量为1
	buy_num_edit.text = "1"
	
	# 显示弹窗并居中
	self.show()


# 处理数量输入变化
func _on_buy_num_changed(new_text: String):
	# 只允许输入数字
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_int():
			filtered_text += char
	
	if filtered_text != new_text:
		buy_num_edit.text = filtered_text
		buy_num_edit.caret_column = filtered_text.length()
	
	# 更新总价显示
	_update_total_cost()

# 更新总价显示
func _update_total_cost():
	var quantity = get_buy_quantity()
	var total_cost = quantity * current_item_cost
	
	var cost_info = "\n总价: " + str(total_cost) + " 元"
	
	# 更新内容显示
	var base_content = str(
		"商品名称: " + current_item_name + "\n" +
		"单价: " + str(current_item_cost) + " 元\n" +
		"描述: " + current_item_desc + "\n\n" +
		"请输入购买数量:"
	)
	
	contents.text = base_content + cost_info

# 获取购买数量
func get_buy_quantity() -> int:
	var text = buy_num_edit.text.strip_edges()
	if text.is_empty():
		return 1
	
	var quantity = text.to_int()
	return max(1, quantity) # 至少购买1个

# 确认购买按钮处理
func _on_sure_button_pressed():
	var quantity = get_buy_quantity()
	
	if quantity <= 0:
		_show_error("购买数量必须大于0")
		return
	
	# 调用确认回调函数
	if confirm_callback.is_valid():
		confirm_callback.call(current_item_name, current_item_cost, quantity, current_buy_type)
	
	# 隐藏弹窗
	self.hide()

# 取消购买按钮处理
func _on_cancel_button_pressed():
	# 调用取消回调函数
	if cancel_callback.is_valid():
		cancel_callback.call()
	
	# 隐藏弹窗
	self.hide()

# 显示错误信息
func _show_error(message: String):
	# 这里可以显示Toast或者其他错误提示
	if has_node("/root/Toast"):
		get_node("/root/Toast").show(message, Color.RED, 2.0, 1.0)
	else:
		print("批量购买弹窗错误: " + message)

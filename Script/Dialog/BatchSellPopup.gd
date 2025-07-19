extends PanelContainer
#用于作物批量出售作物弹窗
@onready var title: Label = $VBox/Title #弹窗标题
@onready var contents: Label = $VBox/Contents #这里显示弹窗内容
@onready var sell_num_edit: LineEdit = $VBox/SellNumEdit #出售作物数量
@onready var sure_button: Button = $VBox/HBox/SureButton #确定按钮
@onready var cancel_button: Button = $VBox/HBox/CancelButton #取消按钮 

# 当前出售的作物信息
var current_crop_name: String = ""
var current_max_count: int = 0
var current_unit_price: int = 0
var current_crop_desc: String = ""

# 回调函数，用于处理确认出售
var confirm_callback: Callable
var cancel_callback: Callable

func _ready():
	# 连接按钮信号
	sure_button.pressed.connect(_on_sure_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 设置数量输入框的默认值和限制
	sell_num_edit.text = "1"
	sell_num_edit.placeholder_text = "请输入出售数量"
	
	# 只允许输入数字
	sell_num_edit.text_changed.connect(_on_sell_num_changed)
	
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

# 显示批量出售弹窗
func show_sell_popup(crop_name: String, max_count: int, unit_price: int, crop_desc: String, on_confirm: Callable, on_cancel: Callable = Callable()):
	current_crop_name = crop_name
	current_max_count = max_count
	current_unit_price = unit_price
	current_crop_desc = crop_desc
	confirm_callback = on_confirm
	cancel_callback = on_cancel
	
	# 设置弹窗内容
	title.text = "批量出售作物"
	
	contents.text = str(
		"作物名称: " + crop_name + "\n" +
		"单价: " + str(unit_price) + " 元/个\n" +
		"可出售数量: " + str(max_count) + " 个\n" +
		"描述: " + crop_desc + "\n\n" +
		"请输入出售数量:"
	)
	
	# 重置出售数量为1
	sell_num_edit.text = "1"
	
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
	
	if filtered_text != new_text:
		sell_num_edit.text = filtered_text
		sell_num_edit.caret_column = filtered_text.length()
	
	# 更新总价显示
	_update_total_income()

# 更新总收入显示
func _update_total_income():
	var quantity = get_sell_quantity()
	var total_income = quantity * current_unit_price
	
	# 检查数量是否超过最大可售数量
	var quantity_status = ""
	if quantity > current_max_count:
		quantity_status = " (超出库存！)"
	
	var income_info = "\n出售数量: " + str(quantity) + " 个" + quantity_status + "\n总收入: " + str(total_income) + " 元"
	
	# 更新内容显示
	var base_content = str(
		"作物名称: " + current_crop_name + "\n" +
		"单价: " + str(current_unit_price) + " 元/个\n" +
		"可出售数量: " + str(current_max_count) + " 个\n" +
		"描述: " + current_crop_desc + "\n\n" +
		"请输入出售数量:"
	)
	
	contents.text = base_content + income_info

# 获取出售数量
func get_sell_quantity() -> int:
	var text = sell_num_edit.text.strip_edges()
	if text.is_empty():
		return 1
	
	var quantity = text.to_int()
	return max(1, quantity) # 至少出售1个

# 确认出售按钮处理
func _on_sure_button_pressed():
	var quantity = get_sell_quantity()
	
	if quantity <= 0:
		_show_error("出售数量必须大于0")
		return
	
	if quantity > current_max_count:
		_show_error("出售数量不能超过库存数量(" + str(current_max_count) + ")")
		return
	
	# 调用确认回调函数
	if confirm_callback.is_valid():
		confirm_callback.call(current_crop_name, quantity, current_unit_price)
	
	# 隐藏弹窗
	self.hide()

# 取消出售按钮处理
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
		print("批量出售弹窗错误: " + message) 

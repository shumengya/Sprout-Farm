extends AcceptDialog

@export var dialog_min_size := Vector2(400, 200)
@export var ok_text := "确认"
@export var cancel_text := "取消"

func _ready() -> void:
	# 设置弹窗最小尺寸
	self.set("rect_min_size", dialog_min_size)

	# 设置标题和内容（可通过函数修改）
	set_dialog_title("默认标题")
	set_dialog_content("默认内容")

	# 添加取消按钮
	var cancel_btn = self.add_cancel_button(cancel_text)
	_customize_button(cancel_btn)

	# 获取并设置确认按钮
	var ok_btn = self.get_ok_button()
	ok_btn.text = ok_text
	_customize_button(ok_btn)

	# 设置按钮样式属性
	self.add_theme_constant_override("buttons_min_height", 40)
	self.add_theme_constant_override("buttons_min_width", 120)
	self.add_theme_constant_override("buttons_separation", 16)

	# 添加样式美化
	_apply_custom_theme()

func set_dialog_position(new_position :Vector2):
	self.position = new_position
	pass

func set_dialog_title(title: String) -> void:
	self.title = title


func set_dialog_content(content: String) -> void:
	self.dialog_text = content


func set_ok_text(text: String) -> void:
	ok_text = text
	get_ok_button().text = text


func set_cancel_text(text: String) -> void:
	cancel_text = text
	# 注意：add_cancel_button 只能调用一次，想动态更新需要重建按钮


func _customize_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(120, 40)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_color_pressed", Color.WHITE)
	button.add_theme_color_override("font_color_hover", Color.WHITE)
	button.add_theme_color_override("bg_color", Color("3c82f6"))  # 蓝色
	button.add_theme_color_override("bg_color_hover", Color("2563eb"))
	button.add_theme_color_override("bg_color_pressed", Color("1e40af"))
	button.add_theme_color_override("bg_color_disabled", Color("94a3b8"))


func _apply_custom_theme() -> void:
	# 设置面板背景颜色
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("f8fafc")  # very light gray
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color("cbd5e1")

	self.add_theme_stylebox_override("panel", panel_style)  # ✅ 修正方法名

	# 设置文字颜色（内容部分）
	var label = self.get_label()
	label.add_theme_color_override("font_color", Color("1e293b"))  # 深灰蓝



# 确认按钮点击
func _on_confirmed() -> void:
	print("确认按钮被点击")


# 取消按钮点击
func _on_canceled() -> void:
	print("取消按钮被点击")

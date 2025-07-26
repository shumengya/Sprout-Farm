extends Panel
# 这是宠物背包面板，用来显示玩家获得的宠物

# 宠物背包格子容器
@onready var bag_grid: GridContainer = $ScrollContainer/Bag_Grid
@onready var quit_button: Button = $QuitButton
@onready var refresh_button: Button = $RefreshButton
@onready var scroll_container = $ScrollContainer

# 预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var pet_store_panel: Panel = $'../PetStorePanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var pet_inform_panel: Panel = $'../../SmallPanel/PetInformPanel'

# 宠物配置数据
var pet_config: Dictionary = {}

# 准备函数
func _ready():
	# 连接关闭按钮信号
	quit_button.pressed.connect(self._on_quit_button_pressed)
	refresh_button.pressed.connect(self._on_refresh_button_pressed)
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 隐藏面板（初始默认隐藏）
	self.hide()
		
# 初始化宠物背包
func init_pet_bag():
	
	# 显示背包中的宠物
	update_pet_bag_ui()

	# 更新宠物背包UI（同步版本，用于刷新按钮）
func update_pet_bag_ui():
	if scroll_container:
		scroll_container.clip_contents = false
	
	# 设置GridContainer也不裁剪内容
	if bag_grid:
		bag_grid.clip_contents = false
	
	# 清空宠物背包格子
	for child in bag_grid.get_children():
		child.queue_free()
	
	# 确保宠物背包存在
	if not "pet_bag" in main_game or main_game.pet_bag == null:
		main_game.pet_bag = []
	
	# 为背包中的每个宠物创建按钮
	for pet_data in main_game.pet_bag:
		var pet_name = pet_data.get("pet_type", "未知宠物")
		var pet_level = pet_data.get("pet_level", 1)
		var pet_owner_name = pet_data.get("pet_name", pet_name)
		
		# 创建宠物按钮
		var button = _create_pet_button(pet_name, pet_level, pet_owner_name)
		
		# 更新按钮文本显示宠物信息
		button.text = str(pet_owner_name + "\n等级：" + str(pet_level))
		
		# 根据是否处于访问模式连接不同的事件
		if main_game.is_visiting_mode:
			# 访问模式下，点击宠物只显示信息
			button.pressed.connect(func(): _on_visit_pet_selected(pet_name, pet_data))
		else:
			# 正常模式下，连接宠物选择事件
			button.pressed.connect(func(): _on_pet_selected(pet_name, pet_data, button))
		
		bag_grid.add_child(button)

# 创建宠物按钮
func _create_pet_button(pet_name: String, pet_level: int, pet_owner_name: String) -> Button:
	# 使用按钮作为宠物背包按钮的样式
	var button = main_game.item_button.duplicate()
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 关闭按钮的内容裁剪，允许图片超出按钮边界
	button.clip_contents = false
	
	
	# 添加工具提示
	button.tooltip_text = str(
		"宠物: " + pet_name + "\n" +
		"名称: " + pet_owner_name + "\n" +
		"等级: " + str(pet_level) + "\n" +
		"点击查看宠物详情"
	)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = "宠物"
		button.get_node("Title").modulate = Color.MAGENTA  # 宠物标题使用洋红色
	
	# 更新按钮的宠物图片
	_update_button_pet_image(button, pet_name)
	
	return button

# 更新按钮的宠物图片
func _update_button_pet_image(button: Button, pet_name: String):
	# 检查按钮是否有CropImage节点
	var pet_image = button.get_node_or_null("CropImage")
	if not pet_image:
		print("宠物背包按钮没有找到CropImage节点：", button.name)
		return
	
	# 从服务器的宠物配置获取场景路径
	var texture = null
	var pet_config = main_game.pet_config  # 使用服务器返回的宠物配置
	
	if pet_config.has(pet_name):
		var pet_info = pet_config[pet_name]
		var scene_path = pet_info.get("pet_image", "")  # 使用服务器数据的pet_image字段
		print("宠物背包 ", pet_name, " 的图片路径：", scene_path)
		
		if scene_path != "" and ResourceLoader.exists(scene_path):
			print("宠物背包开始加载宠物场景：", scene_path)
			# 加载宠物场景并获取PetImage的纹理
			var pet_scene = load(scene_path)
			if pet_scene:
				var pet_instance = pet_scene.instantiate()
				# 直接使用实例化的场景根节点，因为根节点就是PetImage
				if pet_instance and pet_instance.sprite_frames:
					# 获取默认动画的第一帧
					var animation_names = pet_instance.sprite_frames.get_animation_names()
					if animation_names.size() > 0:
						var default_animation = animation_names[0]
						var frame_count = pet_instance.sprite_frames.get_frame_count(default_animation)
						if frame_count > 0:
							texture = pet_instance.sprite_frames.get_frame_texture(default_animation, 0)
							print("宠物背包成功获取宠物纹理：", pet_name)
					else:
						print("宠物背包场景没有动画：", pet_name)
				else:
					print("宠物背包场景没有PetImage节点或sprite_frames：", pet_name)
				pet_instance.queue_free()
			else:
				print("宠物背包无法加载宠物场景：", scene_path)
		else:
			print("宠物背包图片路径无效或文件不存在：", scene_path)
	else:
		print("宠物背包配置中没有找到：", pet_name)
	
	# 设置图片
	if texture:
		pet_image.texture = texture
		pet_image.visible = true
		pet_image.scale = Vector2(10, 10)
		# 确保图片居中显示
		pet_image.centered = true
		print("宠物背包成功设置宠物图片：", pet_name)
	else:
		pet_image.visible = false
		print("宠物背包无法获取宠物图片：", pet_name)

# 加载宠物配置数据
func _load_pet_config() -> Dictionary:
	var file = FileAccess.open("res://Data/pet_data.json", FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}
	
	return json.data

# 计算宠物年龄（以天为单位）
func _calculate_pet_age(birthday: String) -> int:
	if birthday == "":
		return 0
	
	# 解析生日字符串，格式：2025年7月5日10时7分25秒
	var birthday_parts = birthday.split("年")
	if birthday_parts.size() < 2:
		return 0
	
	var year = int(birthday_parts[0])
	var rest = birthday_parts[1]
	
	var month_parts = rest.split("月")
	if month_parts.size() < 2:
		return 0
	
	var month = int(month_parts[0])
	var rest2 = month_parts[1]
	
	var day_parts = rest2.split("日")
	if day_parts.size() < 2:
		return 0
	
	var day = int(day_parts[0])
	var rest3 = day_parts[1]
	
	var hour_parts = rest3.split("时")
	if hour_parts.size() < 2:
		return 0
	
	var hour = int(hour_parts[0])
	var rest4 = hour_parts[1]
	
	var minute_parts = rest4.split("分")
	if minute_parts.size() < 2:
		return 0
	
	var minute = int(minute_parts[0])
	var rest5 = minute_parts[1]
	
	var second_parts = rest5.split("秒")
	if second_parts.size() < 1:
		return 0
	
	var second = int(second_parts[0])
	
	# 将生日转换为Unix时间戳
	var birthday_dict = {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}
	
	var birthday_timestamp = Time.get_unix_time_from_datetime_dict(birthday_dict)
	var current_timestamp = Time.get_unix_time_from_system()
	
	# 计算天数差
	var age_seconds = current_timestamp - birthday_timestamp
	var age_days = int(age_seconds / (24 * 3600))
	
	return max(0, age_days)


# 正常模式下的宠物点击处理 - 查看宠物信息
func _on_pet_selected(pet_name: String, pet_data: Dictionary, button: Button):
	# 显示宠物信息面板
	if pet_inform_panel:
		pet_inform_panel.show_pet_info(pet_name, pet_data)
		pet_inform_panel.show()


# 访问模式下的宠物点击处理
func _on_visit_pet_selected(pet_name: String, pet_data: Dictionary):
	# 显示宠物信息面板
	if pet_inform_panel:
		pet_inform_panel.show_pet_info(pet_name, pet_data)
		pet_inform_panel.show()

#=========================面板通用处理=========================
# 关闭宠物背包面板
func _on_quit_button_pressed() -> void:
	self.hide()

# 手动刷新宠物背包面板
func _on_refresh_button_pressed() -> void:
	# 刷新宠物背包UI
	update_pet_bag_ui()
	Toast.show("宠物背包已刷新", Color.GREEN, 2.0, 1.0)
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时自动刷新数据
		update_pet_bag_ui()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=========================面板通用处理=========================

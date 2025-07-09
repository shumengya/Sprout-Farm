extends Panel
# 这是宠物商店面板，用来展示各种宠物

# 宠物商店格子容器
@onready var store_grid: GridContainer = $ScrollContainer/Store_Grid
@onready var quit_button: Button = $QuitButton
@onready var refresh_button: Button = $RefreshButton
@onready var scroll_container = $ScrollContainer

# 预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var pet_bag_panel: Panel = $'../PetBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var batch_buy_popup: PanelContainer = $'../../DiaLog/BatchBuyPopup'

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


# 初始化宠物商店
func init_pet_store():
	# 从主游戏脚本获取宠物配置数据
	_load_pet_config_from_main()
	update_pet_store_ui()

# 更新宠物商店UI
func update_pet_store_ui():
	if scroll_container:
		scroll_container.clip_contents = false
	
	# 设置GridContainer也不裁剪内容
	if store_grid:
		store_grid.clip_contents = false
	
	# 清空宠物商店格子
	for child in store_grid.get_children():
		child.queue_free()
	
	print("更新宠物商店UI，宠物种类：", pet_config.size())
	
	# 为每个宠物配置创建按钮
	for pet_name in pet_config.keys():
		var pet_info = pet_config[pet_name]
		var purchase_info = pet_info.get("购买信息", {})
		var can_buy = purchase_info.get("能否购买", false)
		
		# 只显示可购买的宠物
		if not can_buy:
			continue
			
		var pet_cost = purchase_info.get("购买价格", 0)
		var basic_info = pet_info.get("基本信息", {})
		var pet_desc = basic_info.get("简介", "可爱的宠物伙伴")
		
		# 检查玩家是否已购买该宠物
		var is_owned = _check_pet_owned(pet_name)
		
		# 创建宠物按钮
		var button = _create_pet_button(pet_name, pet_cost, pet_desc, is_owned)
		
		# 更新按钮文本显示价格和状态
		if is_owned:
			button.text = str(pet_name + "\n（已购买）")
			button.disabled = true
		else:
			button.text = str(pet_name + "\n价格：" + str(pet_cost) + "元")
			# 连接购买点击事件
			button.pressed.connect(func(): _on_store_pet_selected(pet_name, pet_cost, pet_desc))
		
		store_grid.add_child(button)

# 检查玩家是否已拥有某种宠物
func _check_pet_owned(pet_name: String) -> bool:
	if not main_game.pet_bag:
		return false
	
	for pet_data in main_game.pet_bag:
		var basic_info = pet_data.get("基本信息", {})
		var pet_type = basic_info.get("宠物类型", "")
		if pet_type == pet_name:
			return true
	return false

# 创建宠物按钮
func _create_pet_button(pet_name: String, pet_cost: int, pet_desc: String, is_owned: bool = false) -> Button:
	# 使用按钮作为宠物商店按钮的样式
	var button = main_game.item_button.duplicate()
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 关闭按钮的内容裁剪，允许图片超出按钮边界
	button.clip_contents = false
	
	# 设置按钮文本
	button.text = pet_name
	
	# 添加工具提示
	button.tooltip_text = str(
		"宠物: " + pet_name + "\n" +
		"价格: " + str(pet_cost) + "元\n" +
		"描述: " + pet_desc + "\n" +
		"点击购买宠物"
	)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		if is_owned:
			button.get_node("Title").text = "已购买"
			button.get_node("Title").modulate = Color.GRAY  # 已购买使用灰色
		else:
			button.get_node("Title").text = "宠物商店"
			button.get_node("Title").modulate = Color.PINK  # 宠物商店标题使用粉色
	
	# 更新按钮的宠物图片
	_update_button_pet_image(button, pet_name)
	
	return button

# 更新按钮的宠物图片
func _update_button_pet_image(button: Button, pet_name: String):
	# 检查按钮是否有CropImage节点
	var pet_image = button.get_node_or_null("CropImage")
	if not pet_image:
		return
	
	# 从宠物配置获取场景路径
	var texture = null
	if pet_config.has(pet_name):
		var pet_info = pet_config[pet_name]
		var scene_path = pet_info.get("场景路径", "")
		
		if scene_path != "" and ResourceLoader.exists(scene_path):
			# 加载宠物场景并获取PetImage的纹理
			var pet_scene = load(scene_path)
			if pet_scene:
				var pet_instance = pet_scene.instantiate()
				var pet_image_node = pet_instance.get_node_or_null("PetImage")
				if pet_image_node and pet_image_node.sprite_frames:
					# 获取默认动画的第一帧
					var default_animation = pet_image_node.sprite_frames.get_animation_names()[0]
					var frame_count = pet_image_node.sprite_frames.get_frame_count(default_animation)
					if frame_count > 0:
						texture = pet_image_node.sprite_frames.get_frame_texture(default_animation, 0)
				pet_instance.queue_free()
	
	
	# 设置图片
	if texture:
		pet_image.texture = texture
		pet_image.visible = true
		pet_image.scale = Vector2(10, 10)
		# 确保图片居中显示
		pet_image.centered = true
		
	else:
		pet_image.visible = false

# 从主游戏脚本获取宠物配置数据
func _load_pet_config_from_main():
	# 从宠物数据文件加载配置
	var file = FileAccess.open("res://Data/pet_data.json", FileAccess.READ)
	if file == null:
		print("宠物商店：无法打开宠物配置文件")
		pet_config = {}
		return
	
	var json = JSON.new()
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("宠物商店：解析宠物配置文件失败")
		pet_config = {}
		return
	
	pet_config = json.data
	print("宠物商店：成功加载宠物配置数据，宠物种类：", pet_config.size())

# 商店宠物点击处理 - 购买宠物
func _on_store_pet_selected(pet_name: String, pet_cost: int, pet_desc: String):
	# 检查玩家金钱是否足够
	if main_game.money < pet_cost:
		Toast.show("金钱不足！需要 " + str(pet_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		return
	
	# 显示购买确认对话框（宠物只能购买1只，不需要批量购买）
	_show_buy_confirmation_dialog(pet_name, pet_cost, pet_desc)

# 显示购买确认对话框
func _show_buy_confirmation_dialog(pet_name: String, pet_cost: int, pet_desc: String):
	# 创建确认对话框
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = str(
		"确认购买宠物？\n\n" +
		"宠物名称: " + pet_name + "\n" +
		"购买价格: " + str(pet_cost) + " 元\n" +
		"宠物描述: " + pet_desc + "\n\n" +
		"当前金钱: " + str(main_game.money) + " 元\n" +
		"购买后余额: " + str(main_game.money - pet_cost) + " 元\n\n" +
		"注意：每种宠物只能购买一只！"
	)
	confirm_dialog.title = "购买宠物确认"
	confirm_dialog.ok_button_text = "确认购买"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_buy_pet.bind(pet_name, pet_cost, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_buy_pet.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认购买宠物
func _on_confirm_buy_pet(pet_name: String, pet_cost: int, dialog: AcceptDialog):
	# 再次检查金钱是否足够
	if main_game.money < pet_cost:
		Toast.show("金钱不足！需要 " + str(pet_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		dialog.queue_free()
		return
	
	# 发送购买请求到服务器
	_send_buy_pet_request(pet_name, pet_cost)
	dialog.queue_free()

# 取消购买宠物
func _on_cancel_buy_pet(dialog: AcceptDialog):
	print("取消购买宠物")
	dialog.queue_free()

# 发送购买宠物请求
func _send_buy_pet_request(pet_name: String, pet_cost: int):
	# 发送购买请求到服务器
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendBuyPet"):
		if tcp_network_manager_panel.sendBuyPet(pet_name, pet_cost):
			# 服务器会处理购买逻辑，客户端等待响应
			print("已发送购买宠物请求：", pet_name)
		else:
			Toast.show("购买请求发送失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络管理器不可用", Color.RED, 2.0, 1.0)

#=========================面板通用处理=========================
# 手动刷新宠物商店面板
func _on_refresh_button_pressed() -> void:
	# 重新初始化宠物商店
	init_pet_store()
	Toast.show("宠物商店已刷新", Color.GREEN, 2.0, 1.0)

# 关闭宠物商店面板
func _on_quit_button_pressed() -> void:
	# 打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	self.hide()
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时自动刷新数据
		update_pet_store_ui()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=========================面板通用处理=========================

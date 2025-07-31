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
# 请求状态标志，防止重复请求
var is_requesting_config: bool = false

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
	print("宠物配置数据：", pet_config)
	
	# 为每个宠物配置创建按钮
	for pet_name in pet_config.keys():
		var pet_info = pet_config[pet_name]
		print("处理宠物：", pet_name, "，数据：", pet_info)
		
		# 适配扁平化数据格式
		var can_buy = pet_info.get("can_purchase", false)
		
		# 只显示可购买的宠物
		if not can_buy:
			print("宠物 ", pet_name, " 不可购买，跳过")
			continue
			
		var pet_cost = pet_info.get("cost", 0)
		var pet_desc = pet_info.get("description", "可爱的宠物伙伴")
		
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
		print("已添加宠物按钮：", pet_name)

# 检查玩家是否已拥有某种宠物
func _check_pet_owned(pet_name: String) -> bool:
	if not main_game.pet_bag:
		return false
	
	for pet_data in main_game.pet_bag:
		var pet_type = pet_data.get("pet_type", "")
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
		print("按钮没有CropImage节点，跳过图片设置")
		return
	
	# 从宠物配置获取场景路径
	var texture = null
	if pet_config.has(pet_name):
		var pet_info = pet_config[pet_name]
		var scene_path = pet_info.get("pet_image", "")
		print("宠物 ", pet_name, " 的图片路径：", scene_path)
		
		if scene_path != "" and ResourceLoader.exists(scene_path):
			print("开始加载宠物场景：", scene_path)
			# 加载宠物场景并获取PetImage的纹理
			var pet_scene = load(scene_path)
			if pet_scene:
				var pet_instance = pet_scene.instantiate()
				# 场景的根节点就是PetImage，直接使用
				var pet_image_node = pet_instance
				if pet_image_node and pet_image_node.sprite_frames:
					# 获取默认动画的第一帧
					var animation_names = pet_image_node.sprite_frames.get_animation_names()
					if animation_names.size() > 0:
						var default_animation = animation_names[0]
						var frame_count = pet_image_node.sprite_frames.get_frame_count(default_animation)
						if frame_count > 0:
							texture = pet_image_node.sprite_frames.get_frame_texture(default_animation, 0)
							print("成功获取宠物纹理：", pet_name)
					else:
						print("宠物场景没有动画：", pet_name)
				else:
					print("宠物场景没有PetImage节点或sprite_frames：", pet_name)
				pet_instance.queue_free()
			else:
				print("无法加载宠物场景：", scene_path)
		else:
			print("宠物图片路径无效或文件不存在：", scene_path)
	else:
		print("宠物配置中没有找到：", pet_name)
	
	# 设置图片
	if texture:
		pet_image.texture = texture
		pet_image.visible = true
		pet_image.scale = Vector2(10, 10)
		# 确保图片居中显示
		pet_image.centered = true
		print("成功设置宠物图片：", pet_name)
	else:
		# 如果无法获取图片，隐藏图片节点但保留按钮
		pet_image.visible = false
		print("无法获取宠物图片，隐藏图片节点：", pet_name)

# 从服务器获取MongoDB中的宠物配置数据
func _load_pet_config_from_main():
	# 如果正在请求中，避免重复发送
	if is_requesting_config:
		print("宠物商店：正在请求配置数据中，跳过重复请求")
		return
	
	# 发送请求到服务器获取宠物配置
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendGetPetConfig"):
		is_requesting_config = true
		if tcp_network_manager_panel.sendGetPetConfig():
			print("宠物商店：已发送获取宠物配置请求")
			# 等待服务器响应，配置数据将通过网络回调更新
		else:
			print("宠物商店：发送获取宠物配置请求失败")
			pet_config = {}
			is_requesting_config = false
	else:
		print("宠物商店：网络管理器不可用，无法获取宠物配置")
		pet_config = {}
		is_requesting_config = false

# 处理服务器返回的宠物配置数据
func _on_pet_config_received(response_data: Dictionary):
	"""处理从服务器接收到的宠物配置数据"""
	# 重置请求状态
	is_requesting_config = false
	
	var success = response_data.get("success", false)
	if success:
		pet_config = response_data.get("pet_config", {})
		print("宠物商店：成功接收宠物配置数据，宠物种类：", pet_config.size())
		# 只更新UI，不重新发送请求
		update_pet_store_ui()
	else:
		var error_message = response_data.get("message", "获取宠物配置失败")
		print("宠物商店：获取宠物配置失败：", error_message)
		pet_config = {}
		# 显示错误提示
		Toast.show(error_message, Color.RED, 3.0, 1.0)

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
	init_pet_store()
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
#刷新按钮点击
func _on_refresh_button_pressed() -> void:
	# 清空现有配置和请求状态，强制重新获取
	pet_config = {}
	is_requesting_config = false
	# 重新初始化宠物商店
	init_pet_store()
	#Toast.show("宠物商店已刷新", Color.GREEN, 2.0, 1.0)

# 关闭宠物商店面板
func _on_quit_button_pressed() -> void:
	# 打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	self.hide()
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		# 面板显示时只在没有配置数据时才请求
		if pet_config.is_empty():
			init_pet_store()
		else:
			# 如果已有配置数据，直接更新UI
			update_pet_store_ui()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=========================面板通用处理=========================

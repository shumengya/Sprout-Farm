extends Panel
#这是作物仓库面板 用来显示玩家收获的作物的成熟品 比如各种果实和花朵 

# 作物仓库格子容器
@onready var crop_warehouse_grid_container : GridContainer = $ScrollContainer/Warehouse_Grid
@onready var quit_button : Button = $QuitButton
@onready var refresh_button : Button = $RefreshButton

#各种排序过滤按钮
@onready var sort_all_button : Button = $SortContainer/Sort_All#全部
@onready var sort_common_button : Button = $SortContainer/Sort_Common#普通
@onready var sort_superior_button : Button = $SortContainer/Sort_Superior#优良
@onready var sort_rare_button : Button = $SortContainer/Sort_Rare#稀有
@onready var sort_epic_button : Button = $SortContainer/Sort_Epic#史诗
@onready var sort_legendary_button : Button = $SortContainer/Sort_Legendary#传奇
@onready var sort_price_button : Button = $SortContainer/Sort_Price#价格
@onready var sort_growtime_button : Button = $SortContainer/Sort_GrowTime#生长时间
@onready var sort_profit_button : Button = $SortContainer/Sort_Profit#收益
@onready var sort_level_button : Button = $SortContainer/Sort_Level#等级

#预添加常用的面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'


# 作物图片缓存（复用主游戏的缓存系统）
var crop_textures_cache : Dictionary = {}
var crop_frame_counts : Dictionary = {}

# 当前过滤和排序设置
var current_filter_quality = ""
var current_sort_key = ""
var current_sort_ascending = true

# 宠物喂食模式相关变量
var is_pet_feeding_mode = false
var current_pet_data = {}

# 准备函数
func _ready():
	# 连接按钮信号
	_connect_buttons()
	
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 隐藏面板（初始默认隐藏）
	self.hide()


# 连接所有按钮信号
func _connect_buttons():
	quit_button.pressed.connect(self._on_quit_button_pressed)
	refresh_button.pressed.connect(self._on_refresh_button_pressed)
	
	# 过滤按钮
	sort_all_button.pressed.connect(func(): _filter_by_quality(""))
	sort_common_button.pressed.connect(func(): _filter_by_quality("普通"))
	sort_superior_button.pressed.connect(func(): _filter_by_quality("优良"))
	sort_rare_button.pressed.connect(func(): _filter_by_quality("稀有"))
	sort_epic_button.pressed.connect(func(): _filter_by_quality("史诗"))
	sort_legendary_button.pressed.connect(func(): _filter_by_quality("传奇"))
	
	# 排序按钮
	sort_price_button.pressed.connect(func(): _sort_by("花费"))
	sort_growtime_button.pressed.connect(func(): _sort_by("生长时间"))
	sort_profit_button.pressed.connect(func(): _sort_by("收益"))
	sort_level_button.pressed.connect(func(): _sort_by("等级"))

# 设置宠物喂食模式
func set_pet_feeding_mode(feeding_mode: bool, pet_data: Dictionary = {}):
	is_pet_feeding_mode = feeding_mode
	current_pet_data = pet_data
	
	# 更新UI以反映当前模式
	if is_pet_feeding_mode:
		# 宠物喂食模式下，只显示有喂养效果的作物
		var pet_name = pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
		Toast.show("宠物喂食模式：选择要喂给 " + pet_name + " 的作物", Color.CYAN, 3.0, 1.0)
	else:
		# 普通模式
		Toast.show("普通模式：查看作物仓库", Color.GREEN, 2.0, 1.0)
	
	# 刷新UI
	update_crop_warehouse_ui()

# 初始化作物仓库
func init_crop_warehouse():
	# 清空作物仓库格子
	for child in crop_warehouse_grid_container.get_children():
		child.queue_free()
	# 显示仓库中的成熟物
	update_crop_warehouse_ui()

# 更新作物仓库UI
func update_crop_warehouse_ui():
	# 清空作物仓库格子
	for child in crop_warehouse_grid_container.get_children():
		child.queue_free()
	
	# 应用过滤和排序
	var filtered_crops = _get_filtered_and_sorted_crops()
	
	# 为仓库中的每个过滤后的成熟物创建按钮
	for crop_item in filtered_crops:
		var crop_name = crop_item["name"]
		var crop_quality = crop_item.get("quality", "普通")
		var crop_count = crop_item["count"]
		# 创建成熟物按钮
		var button = _create_crop_button(crop_name, crop_quality)
		
		# 更新按钮文本显示数量
		if is_pet_feeding_mode:
			# 宠物喂食模式下显示喂养效果
			var crop_data = main_game.can_planted_crop.get(crop_name, {})
			var feed_effects = crop_data.get("喂养效果", {})
			
			# 构建效果描述
			var effect_descriptions = []
			for effect_name in feed_effects:
				var effect_value = feed_effects[effect_name]
				if effect_value > 0:
					effect_descriptions.append(effect_name + "+" + str(effect_value))
			
			var effect_text = " ".join(effect_descriptions) if effect_descriptions.size() > 0 else "无效果"
			button.text = str(crop_quality + "-" + crop_name + "\n数量：" + str(crop_count) )
			button.pressed.connect(func(): _on_crop_feed_selected(crop_name, crop_count))
		else:
			button.text = str(crop_quality + "-" + crop_name + "\n数量：" + str(crop_count))
			button.pressed.connect(func(): _on_crop_selected(crop_name, crop_count))
		
		crop_warehouse_grid_container.add_child(button)
	print("作物仓库初始化完成，共添加按钮: " + str(crop_warehouse_grid_container.get_child_count()) + "个")

# 获取过滤和排序后的成熟物列表
func _get_filtered_and_sorted_crops():
	var filtered_crops = []
	
	# 收集符合条件的成熟物
	for crop_item in main_game.crop_warehouse:
		# 安全获取品质字段（兼容老数据）
		var item_quality = crop_item.get("quality", "普通")
		
		# 品质过滤
		if current_filter_quality != "" and item_quality != current_filter_quality:
			continue
			
		# 获取成熟物对应的作物数据
		var crop_data = null
		if main_game.can_planted_crop.has(crop_item["name"]):
			crop_data = main_game.can_planted_crop[crop_item["name"]]
		
		# 宠物喂食模式过滤：只显示有喂养效果的作物
		if is_pet_feeding_mode:
			if crop_data == null or not crop_data.has("喂养效果"):
				continue
		
		# 添加到过滤后的列表
		filtered_crops.append({
			"name": crop_item["name"],
			"quality": item_quality,
			"count": crop_item["count"],
			"data": crop_data
		})
	
	# 如果有排序条件且数据可用，进行排序
	if current_sort_key != "":
		filtered_crops.sort_custom(Callable(self, "_sort_crop_items"))
	
	return filtered_crops

# 自定义排序函数
func _sort_crop_items(a, b):
	# 检查是否有有效数据用于排序
	if a["data"] == null or b["data"] == null:
		# 如果某一项没有数据，将其排在后面
		if a["data"] == null and b["data"] != null:
			return false
		if a["data"] != null and b["data"] == null:
			return true
		# 如果都没有数据，按名称排序
		return a["name"] < b["name"]
	
	# 确保排序键存在于数据中
	if !a["data"].has(current_sort_key) or !b["data"].has(current_sort_key):
		print("警告: 排序键 ", current_sort_key, " 在某些成熟物数据中不存在")
		return false
	
	# 执行排序
	if current_sort_ascending:
		return a["data"][current_sort_key] < b["data"][current_sort_key]
	else:
		return a["data"][current_sort_key] > b["data"][current_sort_key]

# 按品质过滤成熟物
func _filter_by_quality(quality: String):
	current_filter_quality = quality
	update_crop_warehouse_ui()

# 按指定键排序
func _sort_by(sort_key: String):
	# 切换排序方向或设置新排序键
	if current_sort_key == sort_key:
		current_sort_ascending = !current_sort_ascending
	else:
		current_sort_key = sort_key
		current_sort_ascending = true
	
	update_crop_warehouse_ui()

# 创建作物按钮
func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = main_game.item_button.duplicate()

	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本
	button.text = str(crop_quality + "-" + crop_name)
	
	# 添加工具提示 (tooltip)
	if main_game.can_planted_crop.has(crop_name):
		var crop = main_game.can_planted_crop[crop_name]
		
		# 将成熟时间从秒转换为天时分秒格式
		var total_seconds = int(crop["生长时间"])
		
		# 定义时间单位换算
		var SECONDS_PER_MINUTE = 60
		var SECONDS_PER_HOUR = 3600
		var SECONDS_PER_DAY = 86400
		
		# 计算各时间单位
		var days = total_seconds / SECONDS_PER_DAY
		total_seconds %= SECONDS_PER_DAY
		
		var hours = total_seconds / SECONDS_PER_HOUR
		total_seconds %= SECONDS_PER_HOUR
		
		var minutes = total_seconds / SECONDS_PER_MINUTE
		var seconds = total_seconds % SECONDS_PER_MINUTE
		
		# 构建时间字符串（只显示有值的单位）
		var time_str = ""
		if days > 0:
			time_str += str(days) + "天"
		if hours > 0:
			time_str += str(hours) + "小时"
		if minutes > 0:
			time_str += str(minutes) + "分钟"
		if seconds > 0:
			time_str += str(seconds) + "秒"
		
		button.tooltip_text = str(
			"作物: " + crop_name + "\n" +
			"品质: " + crop_quality + "\n" +
			"原价格: " + str(crop["花费"]) + "元\n" +
			"成熟时间: " + time_str + "\n" +
			"原收益: " + str(crop["收益"]) + "元\n" +
			"需求等级: " + str(crop["等级"]) + "\n" +
			"耐候性: " + str(crop["耐候性"]) + "\n" +
			"经验: " + str(crop["经验"]) + "点\n" +
			"描述: " + str(crop["描述"])
		)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = crop_quality
		match crop_quality:
			"普通":
				button.get_node("Title").modulate = Color.HONEYDEW#白色
			"优良":
				button.get_node("Title").modulate =Color.DODGER_BLUE#深蓝色
			"稀有":
				button.get_node("Title").modulate =Color.HOT_PINK#品红色
			"史诗":
				button.get_node("Title").modulate =Color.YELLOW#黄色
			"传奇":
				button.get_node("Title").modulate =Color.ORANGE_RED#红色
	
	# 更新按钮的作物图片（使用收获物.webp）
	_update_button_crop_image(button, crop_name)
	
	return button

# 正常模式下的成熟物点击处理
func _on_crop_selected(crop_name, crop_count):
	# 显示成熟物信息
	var info_text = ""
	
	if main_game.can_planted_crop.has(crop_name):
		var crop = main_game.can_planted_crop[crop_name]
		var quality = crop.get("品质", "未知")
		var price = crop.get("花费", 0)
		var grow_time = crop.get("生长时间", 0)
		var profit = crop.get("收益", 0)
		var level_req = crop.get("等级", 1)
		
		# 将成熟时间转换为可读格式
		var time_str = ""
		var total_seconds = int(grow_time)
		var hours = total_seconds / 3600
		var minutes = (total_seconds % 3600) / 60
		var seconds = total_seconds % 60
		
		if hours > 0:
			time_str += str(hours) + "小时"
		if minutes > 0:
			time_str += str(minutes) + "分钟"
		if seconds > 0:
			time_str += str(seconds) + "秒"
		
		info_text = quality + "-" + crop_name + " (数量: " + str(crop_count) + ")\n"
		info_text += "原价格: " + str(price) + "元, 原收益: " + str(profit) + "元\n"
		info_text += "成熟时间: " + time_str + ", 需求等级: " + str(level_req) + "\n"
		info_text += "这是收获的成熟品，可以用于出售或其他用途"
	else:
		info_text = crop_name + " (数量: " + str(crop_count) + ")"
	
	Toast.show(info_text, Color.GOLD, 3.0, 1.0)

# 访问模式下的成熟物点击处理
func _on_visit_crop_selected(crop_name, crop_count):
	# 显示成熟物信息
	var info_text = ""
	
	if main_game.can_planted_crop.has(crop_name):
		var crop = main_game.can_planted_crop[crop_name]
		var quality = crop.get("品质", "未知")
		var price = crop.get("花费", 0)
		var grow_time = crop.get("生长时间", 0)
		var profit = crop.get("收益", 0)
		var level_req = crop.get("等级", 1)
		
		# 将成熟时间转换为可读格式
		var time_str = ""
		var total_seconds = int(grow_time)
		var hours = total_seconds / 3600
		var minutes = (total_seconds % 3600) / 60
		var seconds = total_seconds % 60
		
		if hours > 0:
			time_str += str(hours) + "小时"
		if minutes > 0:
			time_str += str(minutes) + "分钟"
		if seconds > 0:
			time_str += str(seconds) + "秒"
		
		info_text = quality + "-" + crop_name + " (数量: " + str(crop_count) + ")\n"
		info_text += "原价格: " + str(price) + "元, 原收益: " + str(profit) + "元\n"
		info_text += "成熟时间: " + time_str + ", 需求等级: " + str(level_req)
	else:
		info_text = crop_name + " (数量: " + str(crop_count) + ")"
	
	Toast.show(info_text, Color.CYAN, 3.0, 1.0)

# 宠物喂食模式下的作物选择处理
func _on_crop_feed_selected(crop_name: String, crop_count: int):
	if not is_pet_feeding_mode or current_pet_data.is_empty():
		Toast.show("当前不在宠物喂食模式", Color.RED, 2.0, 1.0)
		return
	
	# 检查作物是否有喂养效果
	var crop_data = main_game.can_planted_crop.get(crop_name, {})
	if not crop_data.has("喂养效果"):
		Toast.show("该作物没有喂养效果", Color.RED, 2.0, 1.0)
		return
	
	# 获取喂养效果
	var feed_effects = crop_data.get("喂养效果", {})
	
	# 获取宠物信息
	var pet_name = current_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
	var pet_id = current_pet_data.get("基本信息", {}).get("宠物ID", "")
	
	if pet_id == "":
		Toast.show("宠物ID无效", Color.RED, 2.0, 1.0)
		return
	
	# 构建效果描述
	var effect_descriptions = []
	for effect_name in feed_effects:
		var effect_value = feed_effects[effect_name]
		if effect_value > 0:
			effect_descriptions.append(effect_name + "+" + str(effect_value))
	
	var effect_text = "，".join(effect_descriptions) if effect_descriptions.size() > 0 else "无效果"
	
	# 显示确认对话框
	var confirm_text = str(
		"确认喂食 " + pet_name + " 吗？\n\n" +
		"作物：" + crop_name + "\n" +
		"效果：" + effect_text + "\n\n" +
		"确认后将消耗1个" + crop_name
	)
	
	_show_feed_confirmation_dialog(confirm_text, crop_name, pet_id, feed_effects)

# 显示喂食确认对话框
func _show_feed_confirmation_dialog(confirm_text: String, crop_name: String, pet_id: String, feed_effects: Dictionary):
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = confirm_text
	confirm_dialog.title = "宠物喂食确认"
	confirm_dialog.ok_button_text = "确认喂食"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_feed_pet.bind(crop_name, pet_id, feed_effects, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_feed_pet.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认喂食宠物
func _on_confirm_feed_pet(crop_name: String, pet_id: String, feed_effects: Dictionary, dialog: AcceptDialog):
	# 发送喂食请求到服务器
	_send_feed_pet_request(crop_name, pet_id, feed_effects)
	dialog.queue_free()

# 取消喂食宠物
func _on_cancel_feed_pet(dialog: AcceptDialog):
	dialog.queue_free()

# 发送喂食宠物请求
func _send_feed_pet_request(crop_name: String, pet_id: String, feed_effects: Dictionary):
	if not tcp_network_manager_panel or not tcp_network_manager_panel.has_method("send_message"):
		Toast.show("网络功能不可用", Color.RED, 2.0, 1.0)
		return
	
	# 构建喂食请求消息
	var message = {
		"type": "feed_pet",
		"pet_id": pet_id,
		"crop_name": crop_name,
		"feed_effects": feed_effects
	}
	
	# 发送请求
	tcp_network_manager_panel.send_message(message)
	
	# 退出喂食模式
	set_pet_feeding_mode(false)
	self.hide()



# 获取作物的收获物图片（用于仓库显示）
func _get_crop_harvest_texture(crop_name: String) -> Texture2D:
	# 尝试加载"收获物.webp"图片
	var crop_path = "res://assets/作物/" + crop_name + "/"
	var harvest_texture_path = crop_path + "收获物.webp"
	
	if ResourceLoader.exists(harvest_texture_path):
		var texture = load(harvest_texture_path)
		if texture:
			print("仓库加载作物收获物图片：", crop_name)
			return texture
	
	
	# 如果都没有找到，使用默认的收获物图片
	var default_harvest_path = "res://assets/作物/默认/收获物.webp"
	if ResourceLoader.exists(default_harvest_path):
		var texture = load(default_harvest_path)
		if texture:
			print("仓库使用默认收获物图片：", crop_name)
			return texture
	
	return null

# 更新按钮的作物图片
func _update_button_crop_image(button: Button, crop_name: String):
	# 检查按钮是否有CropImage节点
	var crop_image = button.get_node_or_null("CropImage")
	if not crop_image:
		print("仓库按钮没有找到CropImage节点：", button.name)
		return
	
	# 获取作物的收获物图片
	var texture = _get_crop_harvest_texture(crop_name)
	
	if texture:
		# CropImage是Sprite2D，直接设置texture属性
		crop_image.texture = texture
		crop_image.visible = true
	else:
		crop_image.visible = false
		print("仓库无法获取作物收获物图片：", crop_name) 


#=========================面板通用处理=========================
#手动刷新作物仓库面板
func _on_refresh_button_pressed() -> void:
	# 刷新作物仓库UI
	update_crop_warehouse_ui()
	Toast.show("作物仓库已刷新", Color.GREEN, 2.0, 1.0)
	
# 关闭作物仓库面板
func _on_quit_button_pressed():
	
	# 如果是宠物喂食模式，退出该模式
	if is_pet_feeding_mode:
		set_pet_feeding_mode(false)
	
	self.hide()
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		update_crop_warehouse_ui()
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
		
#=========================面板通用处理=========================

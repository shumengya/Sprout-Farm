extends Panel

#种子商店面板
#种子商店格子
@onready var crop_grid_container : GridContainer = $ScrollContainer/Crop_Grid
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
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var batch_buy_popup: PanelContainer = $'../../DiaLog/BatchBuyPopup'



# 作物图片缓存（复用主游戏的缓存系统）
var crop_textures_cache : Dictionary = {}
var crop_frame_counts : Dictionary = {}

# 当前过滤和排序设置
var current_filter_quality = ""
var current_sort_key = ""
var current_sort_ascending = true

# 准备函数
func _ready():
	# 连接按钮信号
	_connect_buttons()
	
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 隐藏面板（初始默认隐藏）
	self.hide()

# 面板显示时的处理
func _on_visibility_changed():
	if visible:
		# 面板显示时自动刷新数据
		init_store()
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

# 连接所有按钮信号
func _connect_buttons():
	# 关闭按钮
	quit_button.pressed.connect(self._on_quit_button_pressed)
	
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

# 初始化商店
func init_store():
	
	# 清空已有的作物按钮
	for child in crop_grid_container.get_children():
		child.queue_free()
	
	# 遍历可种植的作物数据并添加到商店
	for crop_name in main_game.can_planted_crop:
		var crop = main_game.can_planted_crop[crop_name]
		
		# 检查是否可以购买
		if not crop.get("能否购买", true):
			continue
		
		# 只显示当前等级可以种植的作物
		if crop["等级"] <= main_game.level:
			var store_btn = _create_store_button(crop_name, crop["品质"])
			crop_grid_container.add_child(store_btn)
	
	print("商店初始化完成，共添加按钮: " + str(crop_grid_container.get_child_count()) + "个")
	
	# 更新金钱显示
	_update_money_display()

# 创建商店按钮
func _create_store_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的按钮
	var button = main_game.item_button.duplicate()

	var crop = main_game.can_planted_crop[crop_name]
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本，显示价格
	var display_name = crop.get("作物名称", crop_name)
	button.text = str(crop_quality + "-" + display_name + "\n价格: ¥" + str(crop["花费"]))
		
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
		"作物: " + display_name + "\n" +
		"品质: " + crop_quality + "\n" +
		"价格: " + str(crop["花费"]) + "元\n" +
		"成熟时间: " + time_str + "\n" +
		"收获收益: " + str(crop["收益"]) + "元\n" +
		"需求等级: " + str(crop["等级"]) + "\n" +
		"耐候性: " + str(crop["耐候性"]) + "\n" +
		"经验: " + str(crop["经验"]) + "点\n" +
		"描述: " + str(crop["描述"])
	)
	
	# 添加按钮事件
	button.pressed.connect(func(): _on_store_buy_pressed(crop_name))
	
	# 更新按钮的作物图片
	_update_button_crop_image(button, crop_name)
	
		# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
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
	
	return button

# 购买种子事件处理
func _on_store_buy_pressed(crop_name: String):
	var crop = main_game.can_planted_crop[crop_name]
	
	# 检查等级要求
	if main_game.level < crop["等级"]:
		Toast.show("等级不足，无法购买此种子", Color.RED)
		return
	
	# 检查金钱是否足够（至少能买1个）
	if main_game.money < crop["花费"]:
		Toast.show("金钱不足，无法购买种子", Color.RED)
		return
	
	# 显示批量购买弹窗
	if batch_buy_popup:
		var crop_desc = crop.get("描述", "暂无描述")
		batch_buy_popup.show_buy_popup(
			crop_name, 
			crop["花费"], 
			crop_desc, 
			"seed", 
			_on_confirm_buy_seed,
			_on_cancel_buy_seed
		)
	else:
		print("批量购买弹窗未找到")

# 确认购买种子回调
func _on_confirm_buy_seed(crop_name: String, unit_cost: int, quantity: int, buy_type: String):
	var total_cost = unit_cost * quantity
	
	# 再次检查金钱是否足够
	if main_game.money < total_cost:
		Toast.show("金钱不足！需要 " + str(total_cost) + " 元，当前只有 " + str(main_game.money) + " 元", Color.RED, 3.0, 1.0)
		return
	
	# 发送批量购买请求到服务器
	_send_batch_buy_seed_request(crop_name, quantity)

# 取消购买种子回调
func _on_cancel_buy_seed():
	print("取消购买种子")

# 发送批量购买种子请求
func _send_batch_buy_seed_request(crop_name: String, quantity: int):
	# 发送批量购买请求到服务器
	if tcp_network_manager_panel and tcp_network_manager_panel.sendBuySeed(crop_name, quantity):
		# 服务器会处理批量购买逻辑，客户端等待响应
		print("已发送批量购买种子请求：", crop_name, " 数量：", quantity)
	else:
		Toast.show("购买请求发送失败", Color.RED, 2.0, 1.0)


# 按品质过滤作物
func _filter_by_quality(quality: String):
	current_filter_quality = quality
	_apply_filter_and_sort()

# 按指定键排序
func _sort_by(sort_key: String):
	# 切换排序方向或设置新排序键
	if current_sort_key == sort_key:
		current_sort_ascending = !current_sort_ascending
	else:
		current_sort_key = sort_key
		current_sort_ascending = true
	
	_apply_filter_and_sort()

# 应用过滤和排序
func _apply_filter_and_sort():
	# 清空现有按钮
	for child in crop_grid_container.get_children():
		child.queue_free()
	
	# 收集符合条件的作物
	var filtered_crops = []
	for crop_name in main_game.can_planted_crop:
		var crop = main_game.can_planted_crop[crop_name]
		
		# 检查是否可以购买
		if not crop.get("能否购买", true):
			continue
		
		# 检查等级和品质过滤
		if crop["等级"] > main_game.level:
			continue
			
		if current_filter_quality != "" and crop["品质"] != current_filter_quality:
			continue
			
		# 添加到过滤后的列表
		filtered_crops.append({
			"name": crop_name,
			"data": crop
		})
	
	# 如果有排序条件，进行排序
	if current_sort_key != "":
		filtered_crops.sort_custom(Callable(self, "_sort_crop_items"))
	
	# 添加所有过滤和排序后的作物
	for crop in filtered_crops:
		var store_btn = _create_store_button(crop["name"], crop["data"]["品质"])
		crop_grid_container.add_child(store_btn)
		
	# 更新金钱显示
	_update_money_display()

# 自定义排序函数
func _sort_crop_items(a, b):
	if current_sort_ascending:
		return a["data"][current_sort_key] < b["data"][current_sort_key]
	else:
		return a["data"][current_sort_key] > b["data"][current_sort_key]

# 更新金钱显示
func _update_money_display():
	var money_label = get_node_or_null("MoneyLabel")
	if money_label == null:
		# 创建金钱显示标签
		money_label = Label.new()
		money_label.name = "MoneyLabel"
		money_label.position = Vector2(10, 10)
		money_label.size = Vector2(300, 45)
		
		# 设置标签样式
		money_label.add_theme_color_override("font_color", Color(1, 0.647, 0, 1)) # 橙色
		money_label.add_theme_font_size_override("font_size", 24)
		
		add_child(money_label)
	
	# 更新金钱显示
	money_label.text = "当前金钱：" + str(main_game.money) + " 元"

# 刷新商店内容，可以在金钱变化或等级提升后调用
func refresh_store():
	# 清空并重新创建商店按钮
	init_store()
	# 尝试创建过滤按钮（如果商店面板中没有这些按钮）
	_create_filter_buttons_if_needed()

# 如果需要，动态创建过滤按钮
func _create_filter_buttons_if_needed():
	# 检查是否已存在过滤器容器
	var filter_container = get_node_or_null("FilterContainer")
	if filter_container == null:
		# 创建过滤器容器
		filter_container = HBoxContainer.new()
		filter_container.name = "FilterContainer"
		
		# 设置容器位置和大小
		filter_container.position = Vector2(320, 10)
		filter_container.size = Vector2(770, 45)
		
		add_child(filter_container)
		
		# 添加过滤按钮
		_add_filter_button(filter_container, "全部", func(): _filter_by_quality(""))
		_add_filter_button(filter_container, "普通", func(): _filter_by_quality("普通"))
		_add_filter_button(filter_container, "优良", func(): _filter_by_quality("优良")) 
		_add_filter_button(filter_container, "稀有", func(): _filter_by_quality("稀有"))
		_add_filter_button(filter_container, "史诗", func(): _filter_by_quality("史诗"))
		_add_filter_button(filter_container, "传奇", func(): _filter_by_quality("传奇"))
	
	# 检查是否已存在排序容器
	var sort_container = get_node_or_null("SortContainer")
	if sort_container == null:
		# 创建排序容器
		sort_container = HBoxContainer.new()
		sort_container.name = "SortContainer"
		
		# 设置容器位置和大小
		sort_container.position = Vector2(320, 55)
		sort_container.size = Vector2(770, 30)
		
		add_child(sort_container)
		
		# 添加排序按钮
		_add_filter_button(sort_container, "按价格", func(): _sort_by("花费"))
		_add_filter_button(sort_container, "按生长时间", func(): _sort_by("生长时间"))
		_add_filter_button(sort_container, "按收益", func(): _sort_by("收益"))
		_add_filter_button(sort_container, "按等级", func(): _sort_by("等级"))

# 添加过滤按钮
func _add_filter_button(container, text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(100, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(button)
	button.pressed.connect(callback)

# 获取作物的成熟图片（用于商店显示）
func _get_crop_final_texture(crop_name: String) -> Texture2D:
	# 优先从主游戏的缓存中获取成熟图片
	if main_game and main_game.crop_mature_textures_cache.has(crop_name):
		return main_game.crop_mature_textures_cache[crop_name]
	
	# 如果缓存中没有，再尝试加载"成熟.webp"图片
	var crop_path = "res://assets/作物/" + crop_name + "/"
	var mature_texture_path = crop_path + "成熟.webp"
	
	if ResourceLoader.exists(mature_texture_path):
		var texture = load(mature_texture_path)
		if texture:
			print("商店加载作物成熟图片：", crop_name)
			# 如果主游戏存在，也缓存到主游戏中
			if main_game:
				main_game.crop_mature_textures_cache[crop_name] = texture
			return texture
	
	# 如果没有找到作物的成熟图片，使用默认的成熟图片
	if main_game and main_game.crop_mature_textures_cache.has("默认"):
		var default_texture = main_game.crop_mature_textures_cache["默认"]
		# 缓存给这个作物
		main_game.crop_mature_textures_cache[crop_name] = default_texture
		return default_texture
	
	# 最后尝试直接加载默认成熟图片
	var default_mature_path = "res://assets/作物/默认/成熟.webp"
	if ResourceLoader.exists(default_mature_path):
		var texture = load(default_mature_path)
		if texture:
			print("商店使用默认成熟图片：", crop_name)
			# 缓存到主游戏
			if main_game:
				main_game.crop_mature_textures_cache["默认"] = texture
				main_game.crop_mature_textures_cache[crop_name] = texture
			return texture
	
	return null

# 加载作物图片序列帧（复用主游戏的逻辑）
func _load_crop_textures(crop_name: String) -> Array:
	if crop_textures_cache.has(crop_name):
		return crop_textures_cache[crop_name]
	
	var textures = []
	var crop_path = "res://assets/作物/" + crop_name + "/"
	var default_path = "res://assets/作物/默认/"
	
	# 检查作物文件夹是否存在
	if DirAccess.dir_exists_absolute(crop_path):
		# 尝试加载作物的序列帧（从0开始）
		var frame_index = 0
		while true:
			var texture_path = crop_path + str(frame_index) + ".webp"
			if ResourceLoader.exists(texture_path):
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
					frame_index += 1
				else:
					break
			else:
				break
		
		if textures.size() > 0:
			pass
		else:
			textures = _load_default_textures()
	else:
		print("商店：作物 ", crop_name, " 的文件夹不存在，使用默认图片")
		textures = _load_default_textures()
	
	# 缓存结果
	crop_textures_cache[crop_name] = textures
	crop_frame_counts[crop_name] = textures.size()
	
	return textures

# 加载默认图片
func _load_default_textures() -> Array:
	if crop_textures_cache.has("默认"):
		return crop_textures_cache["默认"]
	
	var textures = []
	var default_path = "res://assets/作物/默认/"
	
	# 尝试加载默认图片序列帧
	var frame_index = 0
	while true:
		var texture_path = default_path + str(frame_index) + ".webp"
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture:
				textures.append(texture)
				frame_index += 1
			else:
				break
		else:
			break
	
	# 如果没有找到序列帧，尝试加载单个默认图片
	if textures.size() == 0:
		var single_texture_path = default_path + "0.webp"
		if ResourceLoader.exists(single_texture_path):
			var texture = load(single_texture_path)
			if texture:
				textures.append(texture)
	
	# 缓存默认图片
	crop_textures_cache["默认"] = textures
	crop_frame_counts["默认"] = textures.size()
	
	return textures

# 更新按钮的作物图片
func _update_button_crop_image(button: Button, crop_name: String):
	# 检查按钮是否有CropImage节点
	var crop_image = button.get_node_or_null("CropImage")
	if not crop_image:
		print("商店按钮没有找到CropImage节点：", button.name)
		return
	
	# 获取作物的最后一帧图片
	var texture = _get_crop_final_texture(crop_name)
	
	if texture:
		# CropImage是Sprite2D，直接设置texture属性
		crop_image.texture = texture
		crop_image.visible = true
		print("商店更新作物图片：", crop_name)
	else:
		crop_image.visible = false
		print("商店无法获取作物图片：", crop_name)

# 兼容MainGame.gd中的调用，转发到_on_store_buy_pressed
func _on_crop_selected(crop_name: String):
	_on_store_buy_pressed(crop_name)


#=========================面板通用处理=========================
#手动刷新种子商店面板
func _on_refresh_button_pressed() -> void:
	# 重新初始化种子商店
	init_store()
	Toast.show("种子商店已刷新", Color.GREEN, 2.0, 1.0)

#关闭种子商店面板
func _on_quit_button_pressed():
	self.hide()
#=========================面板通用处理=========================

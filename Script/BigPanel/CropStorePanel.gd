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

# 库存系统
var crop_stock_data : Dictionary = {}  # 存储每个作物的库存数量
var stock_file_path : String = ""  # 库存数据文件路径（根据用户名动态设置）
var last_refresh_date : String = ""  # 上次刷新库存的日期

# 准备函数
func _ready():
	# 连接按钮信号
	_connect_buttons()
	
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	
	# 初始化库存系统
	_init_stock_system()
	
	# 隐藏面板（初始默认隐藏）
	self.hide()



# 连接所有按钮信号
func _connect_buttons():
	# 关闭按钮
	quit_button.pressed.connect(self._on_quit_button_pressed)
	# 刷新按钮
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

# 初始化商店
func init_store():
	
	# 重新初始化库存系统（确保用户名正确）
	_init_stock_system()
	
	# 清空已有的作物按钮
	for child in crop_grid_container.get_children():
		child.queue_free()
	
	# 检查并刷新库存（如果需要）
	_check_daily_refresh()
	
	# 获取玩家当前等级，确定可解锁的格子数量
	var player_level = main_game.level
	var max_unlocked_slots = player_level  # 玩家等级 = 可解锁的格子数量
	
	# 收集符合条件的作物
	var available_crops = []
	for crop_name in main_game.can_planted_crop:
		var crop = main_game.can_planted_crop[crop_name]
		
		# 检查是否可以购买
		if not crop.get("能否购买", true):
			continue
		
		# 只显示当前等级可以种植的作物
		if crop["等级"] <= main_game.level:
			available_crops.append({"name": crop_name, "data": crop})
	
	# 根据等级限制显示的格子数量
	var slots_to_show = min(available_crops.size(), max_unlocked_slots)
	
	# 添加可显示的作物按钮
	for i in range(slots_to_show):
		var crop_info = available_crops[i]
		var store_btn = _create_store_button(crop_info["name"], crop_info["data"]["品质"])
		crop_grid_container.add_child(store_btn)
	
	# 添加锁定的格子（如果有剩余的可用作物但等级不够解锁）
	var remaining_crops = available_crops.size() - slots_to_show
	if remaining_crops > 0:
		# 创建锁定格子提示
		var locked_slots = min(remaining_crops, 5)  # 最多显示5个锁定格子作为提示
		for i in range(locked_slots):
			var locked_btn = _create_locked_slot_button(player_level + 1)
			crop_grid_container.add_child(locked_btn)
	
	print("商店初始化完成，玩家等级: ", player_level, ", 解锁格子: ", slots_to_show, ", 可用作物: ", available_crops.size())
	
	# 更新金钱显示
	_update_money_display()
	
	# 显示等级限制提示
	_show_level_restriction_info(player_level, available_crops.size(), slots_to_show)

# 创建商店按钮
func _create_store_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的按钮
	var button = main_game.item_button.duplicate()

	var crop = main_game.can_planted_crop[crop_name]
	
	# 获取当前库存
	var current_stock = _get_crop_stock(crop_name)
	var is_sold_out = current_stock <= 0
	
	# 设置按钮状态
	button.visible = true
	button.disabled = is_sold_out
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本，显示价格和库存
	var display_name = crop.get("作物名称", crop_name)
	var stock_text = "库存: " + str(current_stock) if not is_sold_out else "已售罄"
	var price_text = "价格: ¥" + str(crop["花费"])
	
	if is_sold_out:
		button.text = str(crop_quality + "-" + display_name + "\n" + price_text + "\n" + stock_text)
		button.modulate = Color(0.6, 0.6, 0.6, 0.8)  # 灰色半透明效果
	else:
		button.text = str(crop_quality + "-" + display_name + "\n" + price_text + "\n" + stock_text)
		button.modulate = Color.WHITE  # 正常颜色
		
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
		
	# 添加库存信息到tooltip
	var stock_tooltip = "\n库存: " + str(current_stock) + " 个" if not is_sold_out else "\n状态: 已售罄"
	
	button.tooltip_text = str(
		"作物: " + display_name + "\n" +
		"品质: " + crop_quality + "\n" +
		"价格: " + str(crop["花费"]) + "元\n" +
		"成熟时间: " + time_str + "\n" +
		"收获收益: " + str(crop["收益"]) + "元\n" +
		"需求等级: " + str(crop["等级"]) + "\n" +
		"耐候性: " + str(crop["耐候性"]) + "\n" +
		"经验: " + str(crop["经验"]) + "点" + stock_tooltip + "\n" +
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
	
	# 检查库存
	if not _is_crop_in_stock(crop_name):
		Toast.show("该种子已售罄，请等待明日刷新", Color.RED)
		return
	
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
		var max_stock = _get_crop_stock(crop_name)
		batch_buy_popup.show_buy_popup(
			crop_name, 
			crop["花费"], 
			crop_desc, 
			"seed", 
			_on_confirm_buy_seed,
			_on_cancel_buy_seed,
			max_stock  # 传递最大库存限制
		)
	else:
		print("批量购买弹窗未找到")

# 确认购买种子回调
func _on_confirm_buy_seed(crop_name: String, unit_cost: int, quantity: int, buy_type: String):
	var total_cost = unit_cost * quantity
	
	# 再次检查库存是否足够
	var current_stock = _get_crop_stock(crop_name)
	if current_stock < quantity:
		Toast.show("库存不足！当前库存: " + str(current_stock) + "，需要: " + str(quantity), Color.RED, 3.0, 1.0)
		return
	
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
		
		# 购买成功后扣减库存
		if _reduce_crop_stock(crop_name, quantity):
			print("库存扣减成功：", crop_name, " 扣减数量：", quantity)
			# 刷新商店显示
			_apply_filter_and_sort()
			Toast.show("购买成功！剩余库存: " + str(_get_crop_stock(crop_name)), Color.GREEN, 2.0, 1.0)
		else:
			Toast.show("库存扣减失败", Color.RED, 2.0, 1.0)
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
	
	# 获取玩家当前等级，确定可解锁的格子数量
	var player_level = main_game.level
	var max_unlocked_slots = player_level
	
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
	
	# 根据等级限制显示的格子数量
	var slots_to_show = min(filtered_crops.size(), max_unlocked_slots)
	
	# 添加可显示的作物按钮
	for i in range(slots_to_show):
		var crop = filtered_crops[i]
		var store_btn = _create_store_button(crop["name"], crop["data"]["品质"])
		crop_grid_container.add_child(store_btn)
	
	# 添加锁定的格子（如果有剩余的可用作物但等级不够解锁）
	var remaining_crops = filtered_crops.size() - slots_to_show
	if remaining_crops > 0:
		# 创建锁定格子提示
		var locked_slots = min(remaining_crops, 5)  # 最多显示5个锁定格子作为提示
		for i in range(locked_slots):
			var locked_btn = _create_locked_slot_button(player_level + 1)
			crop_grid_container.add_child(locked_btn)
		
	# 更新金钱显示
	_update_money_display()
	
	# 显示等级限制提示
	_show_level_restriction_info(player_level, filtered_crops.size(), slots_to_show)

# 自定义排序函数
func _sort_crop_items(a, b):
	# 安全地获取排序值，并进行类型转换
	var value_a = a["data"].get(current_sort_key, 0)
	var value_b = b["data"].get(current_sort_key, 0)
	
	# 如果是数值类型的字段，确保转换为数值进行比较
	if current_sort_key in ["花费", "生长时间", "收益", "等级", "经验", "耐候性"]:
		# 转换为数值，如果转换失败则使用0
		if typeof(value_a) == TYPE_STRING:
			value_a = int(value_a) if value_a.is_valid_int() else 0
		if typeof(value_b) == TYPE_STRING:
			value_b = int(value_b) if value_b.is_valid_int() else 0
	
	# 执行排序比较
	if current_sort_ascending:
		return value_a < value_b
	else:
		return value_a > value_b

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

#=========================库存系统=========================

# 初始化库存系统
func _init_stock_system():
	# 根据用户名设置库存文件路径，实现账号隔离
	var user_name = main_game.user_name if main_game.user_name != "" else "default_user"
	stock_file_path = "user://crop_stock_" + user_name + ".json"
	print("库存系统初始化，用户：", user_name, "，文件路径：", stock_file_path)
	
	_load_stock_data()
	_check_daily_refresh()

# 加载库存数据
func _load_stock_data():
	print("尝试加载库存数据，文件路径：", stock_file_path)
	
	if FileAccess.file_exists(stock_file_path):
		var file = FileAccess.open(stock_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			print("读取到的JSON数据：", json_string)
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var data = json.data
				crop_stock_data = data.get("stock", {})
				last_refresh_date = data.get("last_refresh_date", "")
				print("库存数据加载成功，库存条目数：", crop_stock_data.size())
				print("加载的库存数据：", crop_stock_data)
				print("上次刷新日期：", last_refresh_date)
				
				# 如果库存数据为空，重新生成
				if crop_stock_data.is_empty():
					print("库存数据为空，重新生成")
					_generate_initial_stock()
			else:
				print("库存数据解析失败，错误：", parse_result, "，重新生成")
				_generate_initial_stock()
		else:
			print("无法打开库存文件，重新生成")
			_generate_initial_stock()
	else:
		print("库存文件不存在，生成初始库存")
		_generate_initial_stock()

# 保存库存数据
func _save_stock_data():
	var data = {
		"stock": crop_stock_data,
		"last_refresh_date": last_refresh_date
	}
	
	print("准备保存库存数据到：", stock_file_path)
	print("保存的数据：", data)
	
	var file = FileAccess.open(stock_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		print("库存数据保存成功，JSON字符串：", json_string)
	else:
		print("无法保存库存数据，文件打开失败")

# 生成初始库存
func _generate_initial_stock():
	crop_stock_data.clear()
	
	# 确保main_game和can_planted_crop存在
	if not main_game or not main_game.can_planted_crop:
		print("错误：无法访问主游戏数据，无法生成库存")
		return
	
	var generated_count = 0
	for crop_name in main_game.can_planted_crop:
		var crop = main_game.can_planted_crop[crop_name]
		
		# 检查是否可以购买
		if not crop.get("能否购买", true):
			continue
		
		# 根据品质设置库存范围
		var stock_amount = _get_stock_amount_by_quality(crop["品质"])
		crop_stock_data[crop_name] = stock_amount
		generated_count += 1
		print("生成库存：", crop_name, " - ", crop["品质"], " - ", stock_amount, "个")
	
	# 设置当前日期为刷新日期
	last_refresh_date = _get_current_date()
	_save_stock_data()
	print("初始库存生成完成，共生成", generated_count, "种作物的库存")
	print("当前库存数据：", crop_stock_data)

# 根据品质获取库存数量
func _get_stock_amount_by_quality(quality: String) -> int:
	var min_stock: int
	var max_stock: int
	
	match quality:
		"传奇":
			min_stock = 10
			max_stock = 30
		"史诗":
			min_stock = 20
			max_stock = 50
		"稀有":
			min_stock = 40
			max_stock = 80
		"优良":
			min_stock = 80
			max_stock = 150
		"普通":
			min_stock = 150
			max_stock = 300
		_:
			min_stock = 100
			max_stock = 200
	
	return randi_range(min_stock, max_stock)

# 获取当前日期字符串
func _get_current_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return str(datetime.year) + "-" + str(datetime.month).pad_zeros(2) + "-" + str(datetime.day).pad_zeros(2)

# 检查是否需要每日刷新
func _check_daily_refresh():
	var current_date = _get_current_date()
	if last_refresh_date != current_date:
		print("检测到新的一天，刷新库存")
		_refresh_daily_stock()

# 每日刷新库存
func _refresh_daily_stock():
	_generate_initial_stock()
	Toast.show("种子商店库存已刷新！", Color.GREEN, 3.0, 1.0)

# 获取作物当前库存
func _get_crop_stock(crop_name: String) -> int:
	return crop_stock_data.get(crop_name, 0)

# 减少作物库存
func _reduce_crop_stock(crop_name: String, amount: int) -> bool:
	var current_stock = _get_crop_stock(crop_name)
	if current_stock >= amount:
		crop_stock_data[crop_name] = current_stock - amount
		_save_stock_data()
		return true
	return false

# 检查作物是否有库存
func _is_crop_in_stock(crop_name: String) -> bool:
	return _get_crop_stock(crop_name) > 0


# 创建锁定格子按钮
func _create_locked_slot_button(required_level: int) -> Button:
	var button = main_game.item_button.duplicate()
	
	# 设置按钮为禁用状态
	button.disabled = true
	button.modulate = Color(0.5, 0.5, 0.5, 0.8)  # 灰色半透明效果
	
	# 设置按钮文本
	button.text = "🔒 锁定\n需要等级: " + str(required_level)
	button.tooltip_text = "此格子已锁定，需要达到等级 " + str(required_level) + " 才能解锁"
	
	# 隐藏作物图片
	var crop_image = button.get_node_or_null("CropImage")
	if crop_image:
		crop_image.visible = false
	
	# 设置标题颜色为灰色
	if button.has_node("Title"):
		button.get_node("Title").modulate = Color.GRAY
	
	return button

# 显示等级限制信息
func _show_level_restriction_info(player_level: int, total_crops: int, unlocked_slots: int):
	# 查找或创建信息标签
	var info_label = get_node_or_null("LevelInfoLabel")
	if info_label == null:
		info_label = Label.new()
		info_label.name = "LevelInfoLabel"
		info_label.position = Vector2(10, 55)
		info_label.size = Vector2(300, 30)
		
		# 设置标签样式
		info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))  # 淡蓝色
		info_label.add_theme_font_size_override("font_size", 18)
		
		add_child(info_label)
	
	# 更新信息显示
	var locked_crops = total_crops - unlocked_slots
	if locked_crops > 0:
		info_label.text = "等级 " + str(player_level) + " | 已解锁: " + str(unlocked_slots) + "/" + str(total_crops) + " 个格子"
		info_label.modulate = Color.YELLOW
	else:
		info_label.text = "等级 " + str(player_level) + " | 所有格子已解锁 (" + str(unlocked_slots) + "/" + str(total_crops) + ")"
		info_label.modulate = Color.GREEN


#=========================面板通用处理=========================
#手动刷新种子商店面板
func _on_refresh_button_pressed() -> void:
	# 重新初始化种子商店
	init_store()
	Toast.show("种子商店已刷新", Color.GREEN, 2.0, 1.0)

#关闭种子商店面板
func _on_quit_button_pressed():
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
#=========================面板通用处理=========================

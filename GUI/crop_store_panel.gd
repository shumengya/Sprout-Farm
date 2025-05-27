extends Panel

#种子商店面板
#种子商店格子
@onready var crop_grid_container : GridContainer = $ScrollContainer/Crop_Grid
@onready var quit_button : Button = $QuitButton

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
@onready var land_panel = get_node("/root/main/UI/LandPanel")
@onready var crop_store_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var player_ranking_panel = get_node("/root/main/UI/PlayerRankingPanel")
@onready var player_bag_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var network_manager = get_node("/root/main/UI/TCPNetworkManager")

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
	# 隐藏面板（初始默认隐藏）
	self.hide()

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
	print("初始化商店...")
	
	# 清空已有的作物按钮
	for child in crop_grid_container.get_children():
		child.queue_free()
	
	# 遍历可种植的作物数据并添加到商店
	print("初始化商店，显示所有作物...")
	for crop_name in main_game.can_planted_crop:
		var crop = main_game.can_planted_crop[crop_name]
		
		# 只显示当前等级可以种植的作物
		if crop["等级"] <= main_game.level:
			var store_btn = _create_store_button(crop_name, crop["品质"])
			crop_grid_container.add_child(store_btn)
			#print("添加商店按钮: " + crop_name)
	
	print("商店初始化完成，共添加按钮: " + str(crop_grid_container.get_child_count()) + "个")
	
	# 更新金钱显示
	_update_money_display()

# 创建商店按钮
func _create_store_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的按钮
	var button = null
	match crop_quality:
		"普通":
			button = main_game.green_bar.duplicate()
		"优良":
			button = main_game.orange_bar.duplicate()
		"稀有":
			button = main_game.white_blue_bar.duplicate()
		"史诗":
			button = main_game.pink_bar.duplicate()
		"传奇":
			button = main_game.black_blue_bar.duplicate()
		_:  # 默认情况
			button = main_game.green_bar.duplicate()

	var crop = main_game.can_planted_crop[crop_name]
	
	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本，显示价格
	button.text = str(crop_quality + "-" + crop_name + "\n价格: ¥" + str(crop["花费"]))
		
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
	print("购买种子: " + crop_name)
	var crop = main_game.can_planted_crop[crop_name]
	
	# 检查等级要求
	if main_game.level < crop["等级"]:
		Toast.show("等级不足，无法购买此种子", Color.RED)
		return
	
	# 检查金钱是否足够
	if main_game.money < crop["花费"]:
		Toast.show("金钱不足，无法购买种子", Color.RED)
		return
	
	# 发送购买请求到服务器
	if network_manager and network_manager.sendBuySeed(crop_name):
		# 购买请求已发送，等待服务器响应
		Toast.show("正在购买种子...", Color.YELLOW, 2.0, 1.0)
		
		# 将种子添加到背包
		var found = false
		for seed_item in main_game.player_bag:
			if seed_item["name"] == crop_name:
				seed_item["count"] += 1
				found = true
				break
		
		if not found:
			main_game.player_bag.append({
				"name": crop_name,
				"quality": crop["品质"],
				"count": 1
			})
		
		# 显示购买成功消息
		Toast.show("购买了" + crop["品质"] + "-" + crop_name + "种子", Color.GREEN)
		
		# 更新背包UI
		crop_store_panel.update_player_bag_ui()
		
		# 更新金钱显示
		_update_money_display()

# 关闭面板
func _on_quit_button_pressed():
	print("关闭商店面板")
	self.hide()

# 按品质过滤作物
func _filter_by_quality(quality: String):
	current_filter_quality = quality
	print("过滤作物，品质: " + (quality if quality != "" else "全部"))
	_apply_filter_and_sort()

# 按指定键排序
func _sort_by(sort_key: String):
	# 切换排序方向或设置新排序键
	if current_sort_key == sort_key:
		current_sort_ascending = !current_sort_ascending
	else:
		current_sort_key = sort_key
		current_sort_ascending = true
	
	print("排序作物，键: " + sort_key + "，升序: " + str(current_sort_ascending))
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
	print("更新商店金钱显示：" + str(main_game.money))

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

# 获取作物的最后一帧图片（用于商店显示）
func _get_crop_final_texture(crop_name: String) -> Texture2D:
	"""
	获取作物的最后一帧图片，用于商店和背包显示
	如果作物图片不存在，使用默认图片的最后一帧
	"""
	# 先尝试从主游戏的缓存中获取
	if main_game and main_game.crop_textures_cache.has(crop_name):
		var textures = main_game.crop_textures_cache[crop_name]
		if textures.size() > 0:
			return textures[textures.size() - 1]  # 返回最后一帧
	
	# 如果主游戏缓存中没有，自己加载
	var textures = _load_crop_textures(crop_name)
	if textures.size() > 0:
		return textures[textures.size() - 1]  # 返回最后一帧
	
	return null

# 加载作物图片序列帧（复用主游戏的逻辑）
func _load_crop_textures(crop_name: String) -> Array:
	"""
	加载指定作物的所有序列帧图片
	"""
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
			var texture_path = crop_path + str(frame_index) + ".png"
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
			print("商店加载作物 ", crop_name, " 的 ", textures.size(), " 帧图片")
		else:
			print("商店：作物 ", crop_name, " 文件夹存在但没有找到有效图片，使用默认图片")
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
	"""
	加载默认作物图片
	"""
	if crop_textures_cache.has("默认"):
		return crop_textures_cache["默认"]
	
	var textures = []
	var default_path = "res://assets/作物/默认/"
	
	# 尝试加载默认图片序列帧
	var frame_index = 0
	while true:
		var texture_path = default_path + str(frame_index) + ".png"
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
		var single_texture_path = default_path + "0.png"
		if ResourceLoader.exists(single_texture_path):
			var texture = load(single_texture_path)
			if texture:
				textures.append(texture)
	
	# 缓存默认图片
	crop_textures_cache["默认"] = textures
	crop_frame_counts["默认"] = textures.size()
	
	print("商店加载了 ", textures.size(), " 个默认作物图片")
	return textures

# 更新按钮的作物图片
func _update_button_crop_image(button: Button, crop_name: String):
	"""
	更新按钮中的作物图片
	"""
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

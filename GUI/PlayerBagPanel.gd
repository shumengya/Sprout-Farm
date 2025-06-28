extends Panel

# 背包格子容器
@onready var player_bag_grid_container : GridContainer = $ScrollContainer/Bag_Grid
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

# 当前选择的地块索引，从MainGame获取
var selected_lot_index : int = -1

# 当前过滤和排序设置
var current_filter_quality = ""
var current_sort_key = ""
var current_sort_ascending = true

# 一键种植模式相关变量
var is_planting_mode = false
var planting_type = ""
var one_click_plant_panel = null

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

# 初始化玩家背包
func init_player_bag():
	# 清空玩家背包格子
	for child in player_bag_grid_container.get_children():
		child.queue_free()

	# 显示背包中的种子
	update_player_bag_ui()

# 更新玩家背包UI
func update_player_bag_ui():
	# 清空玩家背包格子
	for child in player_bag_grid_container.get_children():
		child.queue_free()
	#print("更新背包UI，背包中物品数量：", main_game.player_bag.size())
	
	# 应用过滤和排序
	var filtered_seeds = _get_filtered_and_sorted_seeds()
	
	# 为背包中的每个过滤后的种子创建按钮
	for seed_item in filtered_seeds:
		var crop_name = seed_item["name"]
		var crop_quality = seed_item.get("quality", "普通")
		var crop_count = seed_item["count"]
		#print("背包物品：", crop_name, " 数量：", crop_count)
		# 创建种子按钮
		var button = _create_crop_button(crop_name, crop_quality)
		# 更新按钮文本显示数量
		button.text = str(crop_quality + "-" + crop_name + "\n数量：" + str(crop_count))
		
		# 根据是否处于访问模式连接不同的事件
		if main_game.is_visiting_mode:
			# 访问模式下，点击种子只显示信息，不能种植
			button.pressed.connect(func(): _on_visit_seed_selected(crop_name, crop_count))
		else:
			# 正常模式下，连接种植事件
			button.pressed.connect(func(): _on_bag_seed_selected(crop_name))
		
		player_bag_grid_container.add_child(button)

# 获取过滤和排序后的种子列表
func _get_filtered_and_sorted_seeds():
	var filtered_seeds = []
	
	# 收集符合条件的种子
	for seed_item in main_game.player_bag:
		# 安全获取品质字段（兼容老数据）
		var item_quality = seed_item.get("quality", "普通")
		
		# 品质过滤
		if current_filter_quality != "" and item_quality != current_filter_quality:
			continue
			
		# 获取种子对应的作物数据
		var crop_data = null
		if main_game.can_planted_crop.has(seed_item["name"]):
			crop_data = main_game.can_planted_crop[seed_item["name"]]
		
		# 添加到过滤后的列表
		filtered_seeds.append({
			"name": seed_item["name"],
			"quality": item_quality,
			"count": seed_item["count"],
			"data": crop_data
		})
	
	# 如果有排序条件且数据可用，进行排序
	if current_sort_key != "":
		filtered_seeds.sort_custom(Callable(self, "_sort_seed_items"))
	
	return filtered_seeds

# 自定义排序函数
func _sort_seed_items(a, b):
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
		print("警告: 排序键 ", current_sort_key, " 在某些种子数据中不存在")
		return false
	
	# 执行排序
	if current_sort_ascending:
		return a["data"][current_sort_key] < b["data"][current_sort_key]
	else:
		return a["data"][current_sort_key] > b["data"][current_sort_key]

# 按品质过滤种子
func _filter_by_quality(quality: String):
	current_filter_quality = quality
	update_player_bag_ui()

# 按指定键排序
func _sort_by(sort_key: String):
	# 切换排序方向或设置新排序键
	if current_sort_key == sort_key:
		current_sort_ascending = !current_sort_ascending
	else:
		current_sort_key = sort_key
		current_sort_ascending = true
	
	update_player_bag_ui()

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
			"价格: " + str(crop["花费"]) + "元\n" +
			"成熟时间: " + time_str + "\n" +
			"收获收益: " + str(crop["收益"]) + "元\n" +
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
	
	# 更新按钮的作物图片
	_update_button_crop_image(button, crop_name)
	
	return button

# 从背包中选择种子并种植
func _on_bag_seed_selected(crop_name):
	# 检查是否处于访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法种植", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查是否是一键种植模式
	if is_planting_mode:
		# 一键种植模式下，回调给一键种植面板
		if one_click_plant_panel and one_click_plant_panel.has_method("on_crop_selected"):
			one_click_plant_panel.on_crop_selected(crop_name, planting_type)
		# 退出种植模式
		_exit_planting_mode()
		self.hide()
		return
	
	# 从主场景获取当前选择的地块索引
	selected_lot_index = main_game.selected_lot_index
	
	if selected_lot_index != -1:
		# 检查背包中是否有这个种子
		var seed_index = -1
		for i in range(len(main_game.player_bag)):
			if main_game.player_bag[i]["name"] == crop_name:
				seed_index = i
				break
		
		if seed_index != -1 and main_game.player_bag[seed_index]["count"] > 0:
			# 种植种子并从背包中减少数量
			_plant_crop_from_bag(selected_lot_index, crop_name, seed_index)
			main_game.selected_lot_index = -1
			self.hide()

# 访问模式下的种子点击处理
func _on_visit_seed_selected(crop_name, crop_count):
	# 显示种子信息
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
		info_text += "价格: " + str(price) + "元, 收益: " + str(profit) + "元\n"
		info_text += "成熟时间: " + time_str + ", 需求等级: " + str(level_req)
	else:
		info_text = crop_name + " (数量: " + str(crop_count) + ")"
	
	Toast.show(info_text, Color.CYAN, 3.0, 1.0)
	print("查看种子信息: ", info_text)

# 从背包种植作物
func _plant_crop_from_bag(index, crop_name, seed_index):
	var crop = main_game.can_planted_crop[crop_name]
	
	# 检查是否有效的种子索引，防止越界访问
	if seed_index < 0 or seed_index >= main_game.player_bag.size():
		#print("错误：无效的种子索引 ", seed_index)
		return
	# 发送种植请求到服务器
	if network_manager and network_manager.sendPlantCrop(index, crop_name):
		# 关闭背包面板
		hide()

# 设置种植模式
func set_planting_mode(plant_type: String, plant_panel):
	is_planting_mode = true
	planting_type = plant_type
	one_click_plant_panel = plant_panel
	print("进入种植模式：", plant_type)

# 退出种植模式
func _exit_planting_mode():
	is_planting_mode = false
	planting_type = ""
	one_click_plant_panel = null
	print("退出种植模式")


# 获取作物的成熟图片（用于背包显示）
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
			print("背包加载作物成熟图片：", crop_name)
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
			print("背包使用默认成熟图片：", crop_name)
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
			print("背包加载作物 ", crop_name, " 的 ", textures.size(), " 帧图片")
		else:
			print("背包：作物 ", crop_name, " 文件夹存在但没有找到有效图片，使用默认图片")
			textures = _load_default_textures()
	else:
		print("背包：作物 ", crop_name, " 的文件夹不存在，使用默认图片")
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
		var single_texture_path = default_path + ".webp"
		if ResourceLoader.exists(single_texture_path):
			var texture = load(single_texture_path)
			if texture:
				textures.append(texture)
	
	# 缓存默认图片
	crop_textures_cache["默认"] = textures
	crop_frame_counts["默认"] = textures.size()
	
	print("背包加载了 ", textures.size(), " 个默认作物图片")
	return textures

# 更新按钮的作物图片
func _update_button_crop_image(button: Button, crop_name: String):
	# 检查按钮是否有CropImage节点
	var crop_image = button.get_node_or_null("CropImage")
	if not crop_image:
		print("背包按钮没有找到CropImage节点：", button.name)
		return
	
	# 获取作物的最后一帧图片
	var texture = _get_crop_final_texture(crop_name)
	
	if texture:
		# CropImage是Sprite2D，直接设置texture属性
		crop_image.texture = texture
		crop_image.visible = true
		print("背包更新作物图片：", crop_name)
	else:
		crop_image.visible = false
		print("背包无法获取作物图片：", crop_name)

#=========================面板通用处理=========================
#手动刷新种子仓库面板
func _on_refresh_button_pressed() -> void:
	# 刷新种子背包UI
	update_player_bag_ui()
	Toast.show("种子背包已刷新", Color.GREEN, 2.0, 1.0)

# 关闭面板
func _on_quit_button_pressed():
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	# 退出种植模式（如果当前在种植模式下）
	if is_planting_mode:
		_exit_planting_mode()
	self.hide()
#=========================面板通用处理=========================

extends Panel
#这是作物仓库面板 用来显示玩家收获的作物的成熟品 比如各种果实和花朵 

# 作物仓库格子容器
@onready var crop_warehouse_grid_container : GridContainer = $ScrollContainer/Warehouse_Grid
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
	#print("更新作物仓库UI，仓库中物品数量：", main_game.crop_warehouse.size())
	
	# 应用过滤和排序
	var filtered_crops = _get_filtered_and_sorted_crops()
	
	# 为仓库中的每个过滤后的成熟物创建按钮
	for crop_item in filtered_crops:
		var crop_name = crop_item["name"]
		var crop_quality = crop_item.get("quality", "普通")
		var crop_count = crop_item["count"]
		#print("仓库物品：", crop_name, " 数量：", crop_count)
		# 创建成熟物按钮
		var button = _create_crop_button(crop_name, crop_quality)
		# 更新按钮文本显示数量
		button.text = str(crop_quality + "-" + crop_name + "\n数量：" + str(crop_count))
		
		# 根据是否处于访问模式连接不同的事件
		if main_game.is_visiting_mode:
			# 访问模式下，点击成熟物只显示信息，不能操作
			button.pressed.connect(func(): _on_visit_crop_selected(crop_name, crop_count))
		else:
			# 正常模式下，连接成熟物信息显示事件
			button.pressed.connect(func(): _on_crop_selected(crop_name, crop_count))
		
		crop_warehouse_grid_container.add_child(button)

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
	print("过滤成熟物，品质: " + (quality if quality != "" else "全部"))
	update_crop_warehouse_ui()

# 按指定键排序
func _sort_by(sort_key: String):
	# 切换排序方向或设置新排序键
	if current_sort_key == sort_key:
		current_sort_ascending = !current_sort_ascending
	else:
		current_sort_key = sort_key
		current_sort_ascending = true
	
	print("排序成熟物，键: " + sort_key + "，升序: " + str(current_sort_ascending))
	update_crop_warehouse_ui()

# 创建作物按钮
func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = main_game.item_button.duplicate()
	#普通 Color.HONEYDEW#白色
	#优良 Color.DODGER_BLUE#深蓝色
	#稀有 Color.HOT_PINK#品红色
	#史诗 Color.YELLOW#黄色
	#传奇 Color.ORANGE_RED#红色
	#空地 Color.GREEN#绿色
	#未开垦 Color.WEB_GRAY#深褐色
	

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
	print("查看成熟物信息: ", info_text)

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
	print("查看成熟物信息: ", info_text)



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
	
	# 如果没有找到收获物图片，使用成熟图片作为后备
	var mature_texture_path = crop_path + "成熟.webp"
	if ResourceLoader.exists(mature_texture_path):
		var texture = load(mature_texture_path)
		if texture:
			print("仓库使用成熟图片作为收获物：", crop_name)
			return texture
	
	# 如果都没有找到，使用默认的收获物图片
	var default_harvest_path = "res://assets/作物/默认/收获物.webp"
	if ResourceLoader.exists(default_harvest_path):
		var texture = load(default_harvest_path)
		if texture:
			print("仓库使用默认收获物图片：", crop_name)
			return texture
	
	# 最后尝试默认成熟图片
	var default_mature_path = "res://assets/作物/默认/成熟.webp"
	if ResourceLoader.exists(default_mature_path):
		var texture = load(default_mature_path)
		if texture:
			print("仓库使用默认成熟图片：", crop_name)
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
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	self.hide()
#=========================面板通用处理=========================

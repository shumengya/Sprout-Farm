extends Panel
#一键种植面板
#通过不断地调用土地面板的种植功能来实现一键种植，减少玩家重复性工作
#执行间隔为0.25秒
#目前分为
#全屏种植：从序列号0开始依次种植玩家选定植物，直到玩家种子用完为止，或者完成种植
#行种植：需要玩家点击某个地块，然后从该行从左到右依次种植
#列种植：需要玩家点击某个地块，然后从该列从上到下依次种植
#九宫格种植：需要玩家点击某个地块，然后从该地块上下左右四周九个方向各自种植一个植物
#十字法种植：需要玩家点击某个地块，然后从上下左右四个方向各自种植一个植物
#注意，无论点击的是已经种植的地块，未开垦地块还是空地地块都不影响，因为点击只是为了确认一个具体位置
#然后在一键种植过程中，如果遇到已种植地块，未开垦地块，还是这个方向根本就没有地块等非法操作，没有关系直接跳过即可
#为了方便你确认位置和方向，我的客户端地块排列是10行，4-8列（目前是但不确定以后会不会更改排布，你最好留个接口）
#你可以参考一下一键收获功能的原理实现
#注意注意，以上操作都是在客户端完成，服务端不要添加什么操作
#默认一键种植收费为种植作物的总和价格的20%+基础费用500
#注意钱不够的问题

@onready var full_screen_plant_btn: Button = $Grid/FullScreenPlantBtn 	#全屏种植
@onready var one_row_plant_btn: Button = $Grid/OneRowPlantBtn			#行种植
@onready var one_column_plant_btn: Button = $Grid/OneColumnPlantBtn		#列种植
@onready var nine_square_plant_btn: Button = $Grid/NineSquarePlantBtn	#九宫格种植
@onready var cross_plant_btn: Button = $Grid/CrossPlantBtn				#十字法种植
@onready var random_plant_btn: Button = $Grid/RandomPlantBtn			#随机种植

# 引用主游戏和其他面板
@onready var main_game = get_node("/root/main")

@onready var lucky_draw_panel: LuckyDrawPanel = $'../../BigPanel/LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../../BigPanel/DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../../BigPanel/ItemStorePanel'
@onready var item_bag_panel: Panel = $'../../BigPanel/ItemBagPanel'
@onready var player_bag_panel: Panel = $'../../BigPanel/PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../../BigPanel/CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../../BigPanel/CropStorePanel'
@onready var player_ranking_panel: Panel = $'../../BigPanel/PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../../BigPanel/LoginPanel'


# 种植配置  
# 注意：地块的实际布局可能与代码设想的不同，这里提供可配置的接口
const GRID_COLUMNS = 10  # 地块列数配置接口，可根据需要调整  
const GRID_ROWS_MIN = 4  # 最小行数
const GRID_ROWS_MAX = 8  # 最大行数
const BASE_COST = 500    # 基础费用
const COST_RATE = 0.2    # 种植成本比例（20%）
const PLANT_INTERVAL = 0.25  # 种植间隔时间




# 种植状态变量
var is_planting = false
var selected_crop_name = ""
var selected_crop_count = 0
var plant_timer = 0.0
var plant_queue = []  # 种植队列，存储要种植的地块索引
var current_plant_index = 0

# 等待用户点击地块的状态
var is_waiting_for_lot_selection = false
var pending_plant_type = ""

func _ready():
	self.hide()
	
	# 连接按钮信号
	full_screen_plant_btn.pressed.connect(_on_full_screen_plant_pressed)
	one_row_plant_btn.pressed.connect(_on_one_row_plant_pressed)
	one_column_plant_btn.pressed.connect(_on_one_column_plant_pressed)
	nine_square_plant_btn.pressed.connect(_on_nine_square_plant_pressed)
	cross_plant_btn.pressed.connect(_on_cross_plant_pressed)
	random_plant_btn.pressed.connect(_on_random_plant_pressed)
	
	# 设置按钮提示文本
	_setup_button_tooltips()

func _process(delta):
	if is_planting:
		plant_timer += delta
		if plant_timer >= PLANT_INTERVAL:
			plant_timer = 0.0
			_process_plant_queue()


#=================================一键种植模式=========================================
# 全屏种植按钮处理
func _on_full_screen_plant_pressed():
	_request_crop_selection("全屏种植", "选择要种植的作物进行全屏种植")

# 行种植按钮处理
func _on_one_row_plant_pressed():
	_start_lot_selection_mode("行种植")

# 列种植按钮处理
func _on_one_column_plant_pressed():
	_start_lot_selection_mode("列种植")

# 九宫格种植按钮处理
func _on_nine_square_plant_pressed():
	_start_lot_selection_mode("九宫格种植")

# 十字法种植按钮处理
func _on_cross_plant_pressed():
	_start_lot_selection_mode("十字法种植")

# 随机种植按钮处理
func _on_random_plant_pressed():
	_prepare_random_plant()


# 准备全屏种植
func _prepare_full_screen_plant():
	plant_queue.clear()
	
	# 从序列号0开始依次添加可种植的地块
	for i in range(len(main_game.farm_lots)):
		if _can_plant_at_index(i):
			plant_queue.append(i)
	
	_start_planting("全屏种植")

# 准备行种植
func _prepare_row_plant():
	plant_queue.clear()
	var target_row = _get_row_from_index(main_game.selected_lot_index)
	
	# 添加同一行的所有可种植地块（从左到右）
	for i in range(len(main_game.farm_lots)):
		if _get_row_from_index(i) == target_row and _can_plant_at_index(i):
			plant_queue.append(i)
	
	_start_planting("行种植")

# 准备列种植
func _prepare_column_plant():
	plant_queue.clear()
	var target_column = _get_column_from_index(main_game.selected_lot_index)
	
	# 添加同一列的所有可种植地块（从上到下）
	for i in range(len(main_game.farm_lots)):
		if _get_column_from_index(i) == target_column and _can_plant_at_index(i):
			plant_queue.append(i)
	
	_start_planting("列种植")

# 准备九宫格种植
func _prepare_nine_square_plant():
	plant_queue.clear()
	var center_row = _get_row_from_index(main_game.selected_lot_index)
	var center_column = _get_column_from_index(main_game.selected_lot_index)
	
	# 九宫格的相对位置偏移
	var offsets = [
		[-1, -1], [-1, 0], [-1, 1],
		[0, -1],  [0, 0],  [0, 1],
		[1, -1],  [1, 0],  [1, 1]
	]
	
	for offset in offsets:
		var row = center_row + offset[0]
		var column = center_column + offset[1]
		var index = _get_index_from_row_column(row, column)
		
		if index != -1 and _can_plant_at_index(index):
			plant_queue.append(index)
	
	_start_planting("九宫格种植")

# 准备十字法种植
func _prepare_cross_plant():
	plant_queue.clear()
	var center_row = _get_row_from_index(main_game.selected_lot_index)
	var center_column = _get_column_from_index(main_game.selected_lot_index)
	
	# 十字法的相对位置偏移
	var offsets = [
		[0, 0],   # 中心
		[-1, 0],  # 上
		[1, 0],   # 下
		[0, -1],  # 左
		[0, 1]    # 右
	]
	
	for offset in offsets:
		var row = center_row + offset[0]
		var column = center_column + offset[1]
		var index = _get_index_from_row_column(row, column)
		
		if index != -1 and _can_plant_at_index(index):
			plant_queue.append(index)
	
	_start_planting("十字法种植")

# 准备随机种植
func _prepare_random_plant():
	# 检查背包是否有种子
	if main_game.player_bag.size() == 0:
		Toast.show("背包中没有种子，请先去商店购买", Color.RED)
		return
	
	# 获取背包中所有的种子类型和数量
	var available_seeds = []
	for item in main_game.player_bag:
		if item["count"] > 0:
			# 根据种子数量添加多个相同种子到列表中
			for i in range(item["count"]):
				available_seeds.append(item["name"])
	
	if available_seeds.size() == 0:
		Toast.show("背包中没有可用的种子", Color.RED)
		return
	
	# 打乱种子列表
	available_seeds.shuffle()
	
	# 获取所有可种植的地块
	var available_lots = []
	for i in range(len(main_game.farm_lots)):
		if _can_plant_at_index(i):
			available_lots.append(i)
	
	if available_lots.size() == 0:
		Toast.show("没有可种植的地块", Color.YELLOW)
		return
	
	# 根据种子数量和可种植地块数量确定实际种植数量
	var plant_count = min(available_seeds.size(), available_lots.size())
	
	# 准备种植队列，每个元素包含地块索引和对应的种子名称
	plant_queue.clear()
	var random_plant_data = []  # 存储地块索引和对应种子的映射
	
	for i in range(plant_count):
		var lot_index = available_lots[i]
		var seed_name = available_seeds[i]
		plant_queue.append(lot_index)
		random_plant_data.append({"lot_index": lot_index, "seed_name": seed_name})
	
	# 存储随机种植数据到全局变量，供种植过程使用
	if not has_meta("random_plant_data"):
		set_meta("random_plant_data", random_plant_data)
	else:
		set_meta("random_plant_data", random_plant_data)
	
	# 计算总费用（基于所有要种植的种子）
	var total_crop_cost = 0
	for data in random_plant_data:
		var crop_data = main_game.can_planted_crop.get(data["seed_name"], {})
		var crop_price = crop_data.get("花费", 0)
		total_crop_cost += crop_price
	
	var service_fee = int(total_crop_cost * COST_RATE) + BASE_COST
	
	print("随机种植费用计算：")
	var seed_names = []
	for data in random_plant_data:
		seed_names.append(data["seed_name"])
	print("  将要种植的种子：%s" % str(seed_names))
	print("  种植数量：%d 个地块" % plant_count)
	print("  作物总成本：%d 元" % total_crop_cost)
	print("  服务费率：%.1f%%" % (COST_RATE * 100))
	print("  基础费用：%d 元" % BASE_COST)
	print("  总服务费：%d 元" % service_fee)
	print("  玩家当前金钱：%d 元" % main_game.money)
	
	# 检查金钱是否足够支付服务费
	if main_game.money < service_fee:
		Toast.show("金钱不足！随机种植需要服务费 %d 元（当前：%d 元）" % [service_fee, main_game.money], Color.RED)
		return
	
	# 扣除服务费
	main_game.money -= service_fee
	main_game._update_ui()
	
	# 开始种植
	is_planting = true
	current_plant_index = 0
	plant_timer = 0.0
	
	# 更新按钮状态为种植中
	_update_buttons_planting_state(true)
	
	# 计算不同种子的数量
	var unique_seeds = {}
	for data in random_plant_data:
		unique_seeds[data["seed_name"]] = true
	var unique_seed_count = unique_seeds.size()
	
	Toast.show("开始随机种植，预计种植 %d 个地块，使用 %d 种不同种子，服务费 %d 元" % [plant_count, unique_seed_count, service_fee], Color.GREEN)


#=================================一键种植模式=========================================



# 开始地块选择模式
func _start_lot_selection_mode(plant_type: String):
	is_waiting_for_lot_selection = true
	pending_plant_type = plant_type
	
	# 隐藏一键种植面板
	self.hide()
	
	# 显示提示信息
	var tip_message = ""
	match plant_type:
		"行种植":
			tip_message = "请点击一个地块来确定要种植的行"
		"列种植":
			tip_message = "请点击一个地块来确定要种植的列"
		"九宫格种植":
			tip_message = "请点击一个地块来确定九宫格种植的中心位置"
		"十字法种植":
			tip_message = "请点击一个地块来确定十字法种植的中心位置"
		_:
			tip_message = "请点击一个地块"
	
	Toast.show(tip_message + "（按ESC键取消）", Color.CYAN)
	print("进入地块选择模式：%s" % plant_type)

# 处理地块选择（从MainGame调用）
func on_lot_selected(lot_index: int):
	if not is_waiting_for_lot_selection:
		return false  # 不是等待地块选择状态，返回false让MainGame正常处理
	
	# 退出地块选择模式
	is_waiting_for_lot_selection = false
	
	# 设置选择的地块索引
	main_game.selected_lot_index = lot_index
	
	# 开始作物选择
	_request_crop_selection(pending_plant_type, "选择要种植的作物进行" + pending_plant_type)
	
	# 清空待处理的种植类型
	pending_plant_type = ""
	
	return true  # 返回true表示已处理了地块选择

# 请求作物选择
func _request_crop_selection(plant_type: String, tip_message: String):
	# 检查背包是否有种子
	if main_game.player_bag.size() == 0:
		Toast.show("背包中没有种子，请先去商店购买", Color.RED)
		return
	
	var has_seeds = false
	for item in main_game.player_bag:
		if item["count"] > 0:
			has_seeds = true
			break
	
	if not has_seeds:
		Toast.show("背包中没有可用的种子", Color.RED)
		return
	
	Toast.show(tip_message, Color.CYAN)
	self.hide()
	
	# 设置背包面板的种植模式回调
	player_bag_panel.set_planting_mode(plant_type, self)
	player_bag_panel.show()

# 背包选择作物回调函数
func on_crop_selected(crop_name: String, plant_type: String):
	selected_crop_name = crop_name
	
	# 检查背包中的作物数量
	selected_crop_count = _get_crop_count_in_bag(crop_name)
	if selected_crop_count <= 0:
		Toast.show("背包中没有 " + crop_name + " 种子", Color.RED)
		return
	
	
	# 根据种植类型生成种植队列
	match plant_type:
		"全屏种植":
			_prepare_full_screen_plant()
		"行种植":
			_prepare_row_plant()
		"列种植":
			_prepare_column_plant()
		"九宫格种植":
			_prepare_nine_square_plant()
		"十字法种植":
			_prepare_cross_plant()
		_:
			Toast.show("未知的种植模式：" + plant_type, Color.RED)
			print("错误：未知的种植模式：%s" % plant_type)

# 获取背包中指定作物的数量
func _get_crop_count_in_bag(crop_name: String) -> int:
	for item in main_game.player_bag:
		if item["name"] == crop_name:
			return item["count"]
	return 0

# 开始种植
func _start_planting(plant_type: String):
	if plant_queue.size() == 0:
		Toast.show("没有可种植的地块", Color.YELLOW)
		return
	
	# 限制种植数量不超过背包中的种子数量
	var max_plantable = min(plant_queue.size(), selected_crop_count)
	if max_plantable < plant_queue.size():
		plant_queue = plant_queue.slice(0, max_plantable)
	
	# 计算总费用
	var crop_data = main_game.can_planted_crop.get(selected_crop_name, {})
	var crop_price = crop_data.get("花费", 0)
	var total_crop_cost = crop_price * plant_queue.size()
	var service_fee = int(total_crop_cost * COST_RATE) + BASE_COST
	var total_cost = service_fee  # 只收取服务费，种子费用由种植时扣除
	
	print("一键种植费用计算：")
	print("  作物：%s，单价：%d 元" % [selected_crop_name, crop_price])
	print("  种植数量：%d 个地块" % plant_queue.size())
	print("  作物总成本：%d 元" % total_crop_cost)
	print("  服务费率：%.1f%%" % (COST_RATE * 100))
	print("  基础费用：%d 元" % BASE_COST)
	print("  总服务费：%d 元" % total_cost)
	print("  玩家当前金钱：%d 元" % main_game.money)
	
	# 检查金钱是否足够支付服务费
	if main_game.money < total_cost:
		Toast.show("金钱不足！%s需要服务费 %d 元（当前：%d 元）" % [plant_type, total_cost, main_game.money], Color.RED)
		return
	
	# 扣除服务费
	main_game.money -= total_cost
	main_game._update_ui()
	
	# 开始种植
	is_planting = true
	current_plant_index = 0
	plant_timer = 0.0
	
	# 更新按钮状态为种植中
	_update_buttons_planting_state(true)
	
	Toast.show("开始%s，预计种植 %d 个地块，服务费 %d 元" % [plant_type, plant_queue.size(), total_cost], Color.GREEN)

# 处理种植队列
func _process_plant_queue():
	if current_plant_index >= plant_queue.size():
		# 种植完成
		_finish_planting()
		return
	
	var lot_index = plant_queue[current_plant_index]
	
	# 检查是否是随机种植模式
	if has_meta("random_plant_data"):
		# 随机种植模式：每个地块种植不同的种子
		var random_plant_data = get_meta("random_plant_data")
		if current_plant_index < random_plant_data.size():
			var plant_data = random_plant_data[current_plant_index]
			var seed_name = plant_data["seed_name"]
			
			# 检查是否还有该种子和该地块是否仍可种植
			if _get_crop_count_in_bag(seed_name) > 0 and _can_plant_at_index(lot_index):
				# 执行随机种植
				_plant_at_index_with_seed(lot_index, seed_name)
	else:
		# 普通种植模式：所有地块种植相同的种子
		# 检查是否还有种子和该地块是否仍可种植
		if _get_crop_count_in_bag(selected_crop_name) > 0 and _can_plant_at_index(lot_index):
			# 执行种植
			_plant_at_index(lot_index)
	
	current_plant_index += 1

# 完成种植
func _finish_planting():
	is_planting = false
	
	# 恢复按钮状态
	_update_buttons_planting_state(false)
	
	# 清空队列
	plant_queue.clear()
	current_plant_index = 0
	
	# 清理随机种植的元数据
	if has_meta("random_plant_data"):
		remove_meta("random_plant_data")

# 在指定索引处种植
func _plant_at_index(lot_index: int):
	if tcp_network_manager_panel and tcp_network_manager_panel.sendPlantCrop(lot_index, selected_crop_name):
		pass
	else:
		print("发送种植请求失败：地块 %d" % lot_index)

# 在指定索引处种植指定种子（用于随机种植）
func _plant_at_index_with_seed(lot_index: int, seed_name: String):
	if tcp_network_manager_panel and tcp_network_manager_panel.sendPlantCrop(lot_index, seed_name):
		pass
	else:
		print("发送种植请求失败：地块 %d，种子 %s" % [lot_index, seed_name])

# 检查指定索引的地块是否可以种植
func _can_plant_at_index(index: int) -> bool:
	if index < 0 or index >= len(main_game.farm_lots):
		return false
	
	var lot = main_game.farm_lots[index]
	
	# 必须是已开垦且未种植的地块
	return lot.get("is_diged", false) and not lot.get("is_planted", false)

# 根据索引获取行号
func _get_row_from_index(index: int) -> int:
	if index < 0:
		return -1
	return index / GRID_COLUMNS

# 根据索引获取列号
func _get_column_from_index(index: int) -> int:
	if index < 0:
		return -1
	return index % GRID_COLUMNS

# 根据行列号获取索引
func _get_index_from_row_column(row: int, column: int) -> int:
	if row < 0 or column < 0 or column >= GRID_COLUMNS:
		return -1
	
	var index = row * GRID_COLUMNS + column
	if index >= len(main_game.farm_lots):
		return -1
	
	return index

# 设置按钮提示文本
func _setup_button_tooltips():
	full_screen_plant_btn.tooltip_text = "从第一个地块开始依次种植选定作物，直到种子用完或地块种完\n费用：种植总成本的20% + 500元基础费"
	one_row_plant_btn.tooltip_text = "在选定地块所在的行中从左到右依次种植\n点击此按钮后，再点击农场中的任意地块确定行位置\n费用：种植总成本的20% + 500元基础费"
	one_column_plant_btn.tooltip_text = "在选定地块所在的列中从上到下依次种植\n点击此按钮后，再点击农场中的任意地块确定列位置\n费用：种植总成本的20% + 500元基础费"
	nine_square_plant_btn.tooltip_text = "以选定地块为中心的3x3九宫格范围内种植\n点击此按钮后，再点击农场中的任意地块确定中心位置\n费用：种植总成本的20% + 500元基础费"
	cross_plant_btn.tooltip_text = "以选定地块为中心的十字形（上下左右+中心）种植\n点击此按钮后，再点击农场中的任意地块确定中心位置\n费用：种植总成本的20% + 500元基础费"
	random_plant_btn.tooltip_text = "获取背包中所有种子并打乱后随机种植到所有空地块\n自动使用背包中的各种种子，每个地块种植不同种子\n费用：种植总成本的20% + 500元基础费"

# 更新按钮状态
func _update_buttons_planting_state(planting: bool):
	if planting:
		# 种植中，禁用所有种植按钮
		full_screen_plant_btn.disabled = true
		one_row_plant_btn.disabled = true
		one_column_plant_btn.disabled = true
		nine_square_plant_btn.disabled = true
		cross_plant_btn.disabled = true
		random_plant_btn.disabled = true
		
		full_screen_plant_btn.text = "种植中..."
		one_row_plant_btn.text = "种植中..."
		one_column_plant_btn.text = "种植中..."
		nine_square_plant_btn.text = "种植中..."
		cross_plant_btn.text = "种植中..."
		random_plant_btn.text = "种植中..."
	else:
		# 种植完成，恢复按钮状态
		full_screen_plant_btn.disabled = false
		one_row_plant_btn.disabled = false
		one_column_plant_btn.disabled = false
		nine_square_plant_btn.disabled = false
		cross_plant_btn.disabled = false
		random_plant_btn.disabled = false
		
		full_screen_plant_btn.text = "全屏种植"
		one_row_plant_btn.text = "行种植"
		one_column_plant_btn.text = "列种植"
		nine_square_plant_btn.text = "九宫格\n种植"
		cross_plant_btn.text = "十字法\n种植"
		random_plant_btn.text = "随机\n种植"

# 取消地块选择模式
func cancel_lot_selection():
	if is_waiting_for_lot_selection:
		is_waiting_for_lot_selection = false
		pending_plant_type = ""
		Toast.show("已取消地块选择", Color.YELLOW)
		# 重新显示一键种植面板
		self.show()

# 停止当前种植过程
func stop_planting():
	if is_planting:
		is_planting = false
		Toast.show("一键种植已停止", Color.YELLOW)
		_finish_planting()

#关闭一键种植面板
func _on_quit_button_pressed() -> void:
	# 如果正在种植，先停止种植
	if is_planting:
		stop_planting()
	# 如果正在等待地块选择，取消选择
	elif is_waiting_for_lot_selection:
		cancel_lot_selection()
		return   
	self.hide()
	pass 

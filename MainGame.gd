extends Node

# 变量定义
@onready var grid_container : GridContainer = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item : Button = $CopyNodes/CropItem


@onready var show_money : Label =   $UI/GUI/GameInfoHBox1/money				# 显示当前剩余的钱
@onready var show_experience : Label = $UI/GUI/GameInfoHBox1/experience  	# 显示当前玩家的经验
@onready var show_level : Label =   $UI/GUI/GameInfoHBox1/level				# 显示当前玩家的等级
@onready var show_tip : Label =  $UI/GUI/GameInfoHBox3/tip					# 显示小提示
@onready var show_like: Label = $UI/GUI/GameInfoHBox1/like					# 显示别人给自己点赞的总赞数
@onready var show_onlineplayer: Label = $UI/GUI/GameInfoHBox2/onlineplayer	# 显示服务器在线人数
@onready var show_player_name : Label =  $UI/GUI/GameInfoHBox2/player_name	# 显示玩家昵称
@onready var show_farm_name : Label = $UI/GUI/GameInfoHBox2/farm_name		# 显示农场名称
@onready var show_status_label : Label = $UI/GUI/GameInfoHBox2/StatusLabel	# 显示与服务器连接状态
@onready var show_fps: Label = $UI/GUI/GameInfoHBox2/FPS					# 显示游戏FPS	
@onready var show_hunger_value :Label = $UI/GUI/GameInfoHBox1/hunger_value	# 显示玩家体力值
@onready var network_status_label :Label = get_node("/root/main/UI/TCPNetworkManager/StatusLabel")

#一堆按钮 
#访问其他人农场相关的按钮
@onready var return_my_farm_button: Button = $UI/GUI/VisitVBox/ReturnMyFarmButton	#返回我的农场
@onready var like_button: Button = $UI/GUI/VisitVBox/LikeButton						#给别人点赞

#和农场操作相关的按钮
@onready var one_click_harvestbutton: Button = $UI/GUI/FarmVBox/OneClickHarvestButton	#一键收获
@onready var one_click_plant_button: Button = $UI/GUI/FarmVBox/OneClickPlantButton	#一键种植面板
@onready var player_bag_button: Button = $UI/GUI/FarmVBox/SeedWarehouseButton			#打开玩家背包
@onready var add_new_ground_button: Button = $UI/GUI/FarmVBox/AddNewGroundButton		#购买新地块
@onready var open_store_button: Button = $UI/GUI/FarmVBox/SeedStoreButton				#打开种子商店

#其他一些按钮（暂未分类）
@onready var setting_button: Button = $UI/GUI/OtherVBox/SettingButton				#打开设置面板	
@onready var lucky_draw_button: Button = $UI/GUI/OtherVBox/LuckyDrawButton				#幸运抽奖
@onready var daily_check_in_button: Button = $UI/GUI/OtherVBox/DailyCheckInButton		#每日签到
@onready var player_ranking_button: Button = $UI/GUI/OtherVBox/PlayerRankingButton		#打开玩家排行榜
@onready var scare_crow_button: Button = $UI/GUI/OtherVBox/ScareCrowButton	#打开稻草人面板按钮
@onready var my_pet_button: Button = $UI/GUI/OtherVBox/MyPetButton		#打开宠物面板按钮
@onready var return_main_menu_button: Button = $UI/GUI/OtherVBox/ReturnMainMenuButton	#返回主菜单按钮
@onready var new_player_gift_button: Button = $UI/GUI/OtherVBox/NewPlayerGiftButton		#领取新手大礼包按钮
@onready var account_setting_button: Button = $UI/GUI/OtherVBox/AccountSettingButton	#账户设置按钮  


@onready var crop_grid_container : GridContainer = $UI/CropStorePanel/ScrollContainer/Crop_Grid #种子商店格子
@onready var player_bag_grid_container : GridContainer = $UI/PlayerBagPanel/ScrollContainer/Bag_Grid #玩家背包格子

#作物品质按钮

@onready var item_button :Button = $CopyNodes/item_button			#通用面板按钮

#各种面板
@onready var land_panel : Panel = $UI/LandPanel									#地块面板
@onready var login_panel : PanelContainer = $UI/LoginPanel						#登录注册面板
@onready var crop_store_panel : Panel = $UI/CropStorePanel						#种子商店面板
@onready var player_bag_panel : Panel = $UI/PlayerBagPanel						#玩家背包面板
@onready var crop_warehouse_panel : Panel = $UI/CropWarehousePanel				#作物仓库面板
@onready var item_bag_panel : Panel = $UI/ItemBagPanel							#道具背包面板
@onready var item_store_panel : Panel = $UI/ItemStorePanel						#道具商店面板
@onready var network_manager : Panel = $UI/TCPNetworkManager					#网络管理器
@onready var player_ranking_panel : Panel = $UI/PlayerRankingPanel				#玩家排行榜面板
@onready var daily_check_in_panel: DailyCheckInPanel = $UI/DailyCheckInPanel	#每日签到面板
@onready var lucky_draw_panel: LuckyDrawPanel = $UI/LuckyDrawPanel				#幸运抽签面板
@onready var one_click_plant_panel: Panel = $UI/OneClickPlantPanel				#一键种植面板
@onready var online_gift_panel: Panel = $UI/OnlineGiftPanel						#在线礼包面板
@onready var account_setting_panel: Panel = $UI/AccountSettingPanel				#账户设置面板

#加载缓存资源显示面板
@onready var load_progress_panel: Panel = $UI/LoadProgressPanel						#加载资源面板默认为显示状态，加载完后隐藏
@onready var load_progress_bar: ProgressBar = $UI/LoadProgressPanel/LoadProgressBar	#显示加载进度进度条


@onready var game_info_h_box_1: HBoxContainer = $UI/GUI/GameInfoHBox1
@onready var game_info_h_box_2: HBoxContainer = $UI/GUI/GameInfoHBox2
@onready var game_info_h_box_3: HBoxContainer = $UI/GUI/GameInfoHBox3
@onready var farm_v_box: VBoxContainer = $UI/GUI/FarmVBox
@onready var visit_v_box: VBoxContainer = $UI/GUI/VisitVBox
@onready var other_v_box: VBoxContainer = $UI/GUI/OtherVBox

@onready var accept_dialog: AcceptDialog = $UI/AcceptDialog

var money: int = 500  # 默认每个人初始为100元
var experience: float = 0.0  # 初始每个玩家的经验为0
var grow_speed: float = 1  # 作物生长速度
var level: int = 1  # 初始玩家等级为1
var dig_money : int = 1000 #开垦费用
var stamina: int = 20  # 玩家体力值，默认20点


#临时变量
var user_name : String = ""
var user_password : String = ""
var login_data : Dictionary = {}
var data : Dictionary = {}
var buttons : Array = []

var start_game : bool = false
# 玩家背包数据
var player_bag : Array = []  
# 作物仓库数据
var crop_warehouse : Array = []
# 道具背包数据
var item_bag : Array = []
# 道具选择状态
var selected_item_name : String = ""
var is_item_selected : bool = false
#农作物种类JSON
var can_planted_crop : Dictionary = {}
# 新手大礼包领取状态
var new_player_gift_claimed : bool = false
# 当前被选择的地块索引
var selected_lot_index : int = -1  
var farm_lots : Array = []  # 用于保存每个地块的状态
var dig_index : int = 0
var climate_death_timer : int = 0

# 访问模式相关变量
var is_visiting_mode : bool = false  # 是否处于访问模式
var original_player_data : Dictionary = {}  # 保存原始玩家数据
var visited_player_data : Dictionary = {}  # 被访问玩家的数据

# 作物图片缓存
var crop_textures_cache : Dictionary = {}  # 缓存已加载的作物图片
var crop_frame_counts : Dictionary = {}  # 记录每种作物的帧数
var crop_mature_textures_cache : Dictionary = {}  # 缓存已加载的作物成熟图片

# FPS显示相关变量
var fps_timer: float = 0.0          # FPS更新计时器
var fps_update_interval: float = 0.5  # FPS更新间隔
var frame_count: int = 0            # 帧数计数器
var current_fps: float = 0.0        # 当前FPS值

var client_version :String = GlobalVariables.client_version #记录客户端版本

var five_timer = 0.0
var five_interval = 5.0

var one_timer: float = 0.0
var one_interval: float = 1.0  

# 准备阶段
func _ready():
	# 显示加载进度面板，隐藏其他所有UI
	load_progress_panel.show()
	load_progress_bar.value = 0
	
	#未登录时隐藏所有UI
	game_info_h_box_1.hide()
	game_info_h_box_2.hide()
	game_info_h_box_3.hide()
	farm_v_box.hide()
	visit_v_box.hide()
	other_v_box.hide()
	
	# 隐藏面板
	crop_store_panel.hide()
	player_bag_panel.hide()
	crop_warehouse_panel.hide()
	item_bag_panel.hide()
	item_store_panel.hide()
	lucky_draw_panel.hide()
	daily_check_in_panel.hide()
	player_ranking_panel.hide()
	one_click_plant_panel.hide()
	account_setting_panel.hide()
	accept_dialog.hide()
	

	
	_update_ui()
	_create_farm_buttons() # 创建地块按钮
	_update_farm_lots_state() # 初始更新地块状态
	
	# 先尝试加载本地数据进行快速初始化
	_load_local_crop_data()
	
	# 初始化玩家背包UI
	player_bag_panel.init_player_bag()
	# 初始化作物仓库UI
	crop_warehouse_panel.init_crop_warehouse()
	# 初始化道具背包UI
	item_bag_panel.init_item_bag()
	# 初始化商店
	crop_store_panel.init_store()
	# 初始化道具商店UI
	item_store_panel.init_item_store()
	
	# 连接AcceptDialog的确认信号
	accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)
	
	# 启动在线人数更新定时器
	_start_online_players_timer()
	
	# 预加载所有作物图片（带进度显示）
	await _preload_all_crop_textures()
	
	# 启动后稍等片刻尝试从服务器获取最新数据
	await get_tree().create_timer(0.5).timeout
	_try_load_from_server()


func _process(delta: float) -> void:
	# FPS计算和显示
	fps_timer += delta
	frame_count += 1
	
	#更新一次FPS显示
	if fps_timer >= fps_update_interval:
		# 计算FPS：帧数 / 时间间隔
		current_fps = frame_count / fps_timer
		
		# 更新FPS显示，保留1位小数
		show_fps.text = "FPS: " + str("%d" % current_fps)
		
		# 根据FPS值设置颜色
		if current_fps >= 50:
			show_fps.modulate = Color.GREEN      # 绿色：流畅
		elif current_fps >= 30:
			show_fps.modulate = Color.YELLOW     # 黄色：一般
		elif current_fps >= 20:
			show_fps.modulate = Color.ORANGE     # 橙色：较卡
		else:
			show_fps.modulate = Color.RED        # 红色：卡顿
		
		# 重置计数器
		fps_timer = 0.0
		frame_count = 0
	
	# 检查ESC键取消一键种植地块选择模式
	if Input.is_action_just_pressed("ui_cancel"):
		if one_click_plant_panel and one_click_plant_panel.has_method("cancel_lot_selection"):
			one_click_plant_panel.cancel_lot_selection()
	pass


#每时每刻都更新
func _physics_process(delta):
	
	#1秒计时器
	one_timer += delta
	if one_timer >= one_interval:
		one_timer = 0.0  # 重置计时器
		

		
		#同步网络管理器的状态
		show_status_label.text = "服务器状态："+network_status_label.text
		show_status_label.modulate = network_status_label.modulate
		
		if start_game == true:
			_update_farm_lots_state() # 更新地块状态，不重新创建UI
			
			#访客模式处理
			if is_visiting_mode:
				farm_v_box.hide()
				visit_v_box.show()
				other_v_box.hide()
				pass
			else:
				game_info_h_box_1.show()
				game_info_h_box_2.show()
				game_info_h_box_3.show()
				farm_v_box.show()
				visit_v_box.hide()
				other_v_box.show()
				pass
			pass

	#5秒计时器
	five_timer += delta
	if five_timer >= five_interval:
		five_timer = 0.0  # 重置计时器
		show_tip.text = _random_small_game_tips()

#随机游戏提示
func _random_small_game_tips() -> String:
	const game_tips = [
		"按住wsad可以移动游戏画面",
		"使用鼠标滚轮来缩放游戏画面",
		"移动端双指缩放游戏画面",
		"不要一上来就花光你的初始资金",
		"钱币是目前游戏唯一货币",
		"每隔一小时体力值+1",
		"不要忘记领取你的新手礼包！",
		"记得使用一键截图来分享你的农场",
		"新注册用户可享受三天10倍速作物生长",
		"偷别人菜时不要忘了给别人浇水哦",
		"你能分得清小麦和稻谷吗",
		"凌晨刷新体力值",
		"面板左上角有刷新按钮，可以刷新面板",
	]
	var random_index = randi() % game_tips.size()
	var selected_tip = game_tips[random_index]
	return selected_tip


# 处理服务器作物更新消息
func _handle_crop_update(update_data):
	# 检查是否是访问模式的更新
	var is_visiting_update = update_data.get("is_visiting", false)
	
	if is_visiting_update and is_visiting_mode:
		# 访问模式下的更新，更新被访问玩家的农场数据
		farm_lots = update_data["farm_lots"]
	elif not is_visiting_update and not is_visiting_mode:
		# 正常模式下的更新，更新自己的农场数据
		farm_lots = update_data["farm_lots"]
	else:
		# 状态不匹配，忽略更新
		print("忽略不匹配的作物更新，当前访问模式：", is_visiting_mode, "，更新类型：", is_visiting_update)
		return
	
	# 更新UI显示
	_update_farm_lots_state()

# 修复背包数据，确保所有物品都有quality字段
func _fix_player_bag_data():
	"""修复背包数据，为缺少quality字段的物品添加默认质量"""
	if not player_bag:
		return
	
	print("检查并修复背包数据...")
	var fixed_count = 0
	
	for i in range(player_bag.size()):
		var item = player_bag[i]
		
		# 如果物品缺少quality字段，尝试从作物数据中获取或设置默认值
		if not item.has("quality"):
			var item_name = item.get("name", "")
			var quality = "普通"  # 默认质量
			
			# 尝试从作物数据中获取质量
			if can_planted_crop.has(item_name):
				quality = can_planted_crop[item_name].get("品质", "普通")
			
			item["quality"] = quality
			fixed_count += 1
			print("修复背包物品 [", item_name, "] 的质量字段为：", quality)
	
	if fixed_count > 0:
		print("背包数据修复完成，共修复 ", fixed_count, " 个物品")
	else:
		print("背包数据检查完成，无需修复")

# 处理登录成功
func handle_login_success(player_data: Dictionary):
	"""处理登录成功后的逻辑"""
	
	# 修复背包数据兼容性问题
	_fix_player_bag_data()
	
	# 更新新手大礼包状态
	new_player_gift_claimed = player_data.get("new_player_gift_claimed", false)
	
	# 根据新手大礼包状态控制按钮显示
	var new_player_gift_button = find_child("NewPlayerGiftButton")
	if new_player_gift_button:
		if new_player_gift_claimed:
			new_player_gift_button.hide()
		else:
			new_player_gift_button.show()
	
	# 立即请求在线人数
	if network_manager and network_manager.is_connected_to_server():
		network_manager.sendGetOnlinePlayers()
		print("登录成功后请求在线人数更新")
	
	# 其他登录成功后的初始化逻辑可以在这里添加
	start_game = true


# 处理玩家排行榜响应
func _handle_player_rankings_response(data):
	player_ranking_panel.handle_player_rankings_response(data)

# 处理玩家游玩时间响应
func _handle_play_time_response(data):
	player_ranking_panel.handle_play_time_response(data)

# 处理访问玩家响应
func _handle_visit_player_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var target_player_data = data.get("player_data", {})
		
		# 保存当前玩家数据
		if not is_visiting_mode:
			original_player_data = {
				"user_name": user_name,
				"player_name": show_player_name.text.replace("玩家昵称：", ""),
				"farm_name": show_farm_name.text.replace("农场名称：", ""),
				"level": level,
				"money": money,
				"experience": experience,
				"stamina": stamina,
				"farm_lots": farm_lots.duplicate(true),
				"player_bag": player_bag.duplicate(true)
			}
		
		# 切换到访问模式
		is_visiting_mode = true
		visited_player_data = target_player_data
		
		# 更新显示数据
		money = target_player_data.get("money", 0)
		experience = target_player_data.get("experience", 0)
		level = target_player_data.get("level", 1)
		stamina = target_player_data.get("体力值", 20)
		farm_lots = target_player_data.get("farm_lots", [])
		player_bag = target_player_data.get("player_bag", [])
		crop_warehouse = target_player_data.get("作物仓库", [])
		item_bag = target_player_data.get("道具背包", [])
		
		# 更新UI显示
		show_player_name.text = "玩家昵称：" + target_player_data.get("player_name", "未知")
		show_farm_name.text = "农场名称：" + target_player_data.get("farm_name", "未知农场")
		
		# 显示被访问玩家的点赞数
		var target_likes = target_player_data.get("total_likes", 0)
		show_like.text = "总赞数：" + str(int(target_likes))
		
		_update_ui()
		
		# 重新创建地块按钮以显示被访问玩家的农场
		_create_farm_buttons()
		_update_farm_lots_state()
		
		# 更新背包UI
		if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
			player_bag_panel.update_player_bag_ui()
		# 更新作物仓库UI
		if crop_warehouse_panel and crop_warehouse_panel.has_method("update_crop_warehouse_ui"):
			crop_warehouse_panel.update_crop_warehouse_ui()
		# 更新道具背包UI
		if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
			item_bag_panel.update_item_bag_ui()
		
		# 隐藏排行榜面板
		if player_ranking_panel:
			player_ranking_panel.hide()
		
		Toast.show("正在访问 " + target_player_data.get("player_name", "未知") + " 的农场", Color.CYAN)
		print("成功进入访问模式，访问玩家：", target_player_data.get("player_name", "未知"))
	else:
		Toast.show("访问失败：" + message, Color.RED)
		print("访问玩家失败：", message)

# 处理返回自己农场响应
func _handle_return_my_farm_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var player_data = data.get("player_data", {})
		
		# 恢复玩家数据
		money = player_data.get("money", 500)
		experience = player_data.get("experience", 0)
		level = player_data.get("level", 1)
		stamina = player_data.get("体力值", 20)
		farm_lots = player_data.get("farm_lots", [])
		player_bag = player_data.get("player_bag", [])
		crop_warehouse = player_data.get("作物仓库", [])
		item_bag = player_data.get("道具背包", [])
		
		# 恢复UI显示
		show_player_name.text = "玩家昵称：" + player_data.get("player_name", "未知")
		show_farm_name.text = "农场名称：" + player_data.get("farm_name", "我的农场")
		
		# 显示自己的点赞数
		var my_likes = player_data.get("total_likes", 0)
		show_like.text = "总赞数：" + str(int(my_likes))
		
		# 退出访问模式
		is_visiting_mode = false
		visited_player_data.clear()
		original_player_data.clear()
		
		# 更新UI
		_update_ui()
		
		# 重新创建地块按钮以显示自己的农场
		_create_farm_buttons()
		_update_farm_lots_state()
		
		# 更新背包UI
		if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
			player_bag_panel.update_player_bag_ui()
		# 更新作物仓库UI
		if crop_warehouse_panel and crop_warehouse_panel.has_method("update_crop_warehouse_ui"):
			crop_warehouse_panel.update_crop_warehouse_ui()
		# 更新道具背包UI
		if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
			item_bag_panel.update_item_bag_ui()
		
		Toast.show("已返回自己的农场", Color.GREEN)
		print("成功返回自己的农场")
	else:
		Toast.show("返回农场失败：" + message, Color.RED)
		print("返回农场失败：", message)


#创建作物按钮
func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = item_button.duplicate()
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


	# 确保按钮可见并可点击
	button.visible = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	
	# 设置按钮文本
	button.text = str(crop_quality + "-" + crop_name)
	
	# 如果按钮有标题标签，设置标题
	if button.has_node("Title"):
		button.get_node("Title").text = crop_quality
	
	return button


# 初始化农场地块按钮 - 只在游戏开始时调用一次
func _create_farm_buttons():
	# 清空当前显示的地块
	for child in grid_container.get_children():
		child.queue_free()
		
	# 创建所有地块按钮
	for i in range(len(farm_lots)):
		var button = crop_item.duplicate()
		button.name = "FarmLot_" + str(i)
		
		button.connect("pressed", Callable(self, "_on_item_selected").bind(i))
		
		grid_container.add_child(button)

# 更新农场地块状态到 GridContainer 更新现有按钮的状态
func _update_farm_lots_state():
	var digged_count = 0  # 统计已开垦地块的数量

	for i in range(len(farm_lots)):
		if i >= grid_container.get_child_count():
			break # 防止越界
			
		var lot = farm_lots[i]
		var button = grid_container.get_child(i)
		var label = button.get_node("crop_name")
		var ground_image = button.get_node("ground_sprite")
		var status_label = button.get_node("status_label")
		var progressbar = button.get_node("ProgressBar")

		# 更新作物图片
		_update_lot_crop_sprite(button, lot)

		if lot["is_diged"]:
			digged_count += 1  # 增加已开垦地块计数
			if lot["is_planted"]:
				# 如果作物已死亡
				if lot["is_dead"]:
					label.modulate = Color.NAVY_BLUE
					label.text = "[" + farm_lots[i]["crop_type"] + "已死亡" + "]"
					# 死亡作物不显示tooltip
					button.tooltip_text = ""
				else:
					# 正常生长逻辑
					var crop_name = lot["crop_type"]
					
					# 检查是否为杂草，如果是杂草则隐藏进度条和作物名字
					var is_weed = false
					if can_planted_crop.has(crop_name):
						is_weed = can_planted_crop[crop_name].get("是否杂草", false)
					
					if is_weed:
						# 杂草：隐藏进度条和作物名字
						label.hide()
						progressbar.hide()
						# 杂草不显示tooltip和状态标签
						button.tooltip_text = ""
						status_label.text = ""
						
						# 杂草也要显示土地等级颜色
						var land_level = int(lot.get("土地等级", 0))
						var level_config = {
							0: {"color": Color.WHITE},
							1: {"color": Color(1.0, 1.0, 0.0)},
							2: {"color": Color(1.0, 0.41, 0.0)},
							3: {"color": Color(0.55, 0.29, 0.97)},
							4: {"color": Color(0.33, 0.4, 0.59)}
						}
						
						if land_level in level_config:
							var config = level_config[land_level]
							ground_image.self_modulate = config["color"]
						else:
							ground_image.self_modulate = Color.WHITE
					else:
						# 正常作物：显示进度条和作物名字
						label.show()
						label.text = "[" + can_planted_crop[crop_name]["品质"] + "-" + lot["crop_type"] +"]"
						
						var status_text = ""
						# 添加状态标识
						var status_indicators = []
						
						# 检查浇水状态（1小时内浇过水）
						var current_time = Time.get_unix_time_from_system()
						var last_water_time = lot.get("浇水时间", 0)
						var water_cooldown = 3600  # 1小时冷却时间
						
						if current_time - last_water_time < water_cooldown:
							status_indicators.append("已浇水")#💧
						
						if lot.get("已施肥", false):
							status_indicators.append("已施肥")#🌱
						
						# 土地等级颜色（不显示文本，只通过颜色区分）
						var land_level = int(lot.get("土地等级", 0))  # 确保是整数
						var level_config = {
							0: {"color": Color.WHITE},                              # 默认土地：默认颜色
							1: {"color": Color(1.0, 1.0, 0.0)},                     # 黄土地：ffff00
							2: {"color": Color(1.0, 0.41, 0.0)},                    # 红土地：ff6900
							3: {"color": Color(0.55, 0.29, 0.97)},                  # 紫土地：8e4af7
							4: {"color": Color(0.33, 0.4, 0.59)}                    # 黑土地：546596
						}
						
						if land_level in level_config:
							var config = level_config[land_level]
							ground_image.self_modulate = config["color"]
						else:
							# 未知等级，使用默认颜色
							ground_image.self_modulate = Color.WHITE

						
						if status_indicators.size() > 0:
							status_text += " " + " ".join(status_indicators)
						status_label.text = status_text
						
						# 根据品质显示颜色
						match can_planted_crop[crop_name]["品质"]:
							"普通":
								label.modulate = Color.HONEYDEW#白色
							"优良":
								label.modulate = Color.DODGER_BLUE#深蓝色
							"稀有":
								label.modulate = Color.HOT_PINK#品红色
							"史诗":
								label.modulate = Color.YELLOW#黄色
							"传奇":
								label.modulate = Color.ORANGE_RED#红色

						progressbar.show()
						progressbar.max_value = int(lot["max_grow_time"])
						progressbar.value = int(lot["grow_time"]) # 直接设置值，不使用动画
					
						# 添加作物详细信息到tooltip（只对正常作物）
						if can_planted_crop.has(crop_name):
							var crop = can_planted_crop[crop_name]
							var crop_quality = crop.get("品质", "未知")
							
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
						else:
							# 如果作物数据不存在，显示基本信息
							button.tooltip_text = "作物: " + crop_name + "\n" + "作物数据未找到"
			else:
				# 已开垦但未种植的地块显示为空地
				var land_text = "[空地]"
				
				# 土地等级颜色（空地也要显示土地等级颜色）
				var land_level = int(lot.get("土地等级", 0))  # 确保是整数
				var level_config = {
					0: {"color": Color.WHITE},                              # 默认土地：默认颜色
					1: {"color": Color(1.0, 1.0, 0.0)},                     # 黄土地：ffff00
					2: {"color": Color(1.0, 0.41, 0.0)},                    # 红土地：ff6900
					3: {"color": Color(0.55, 0.29, 0.97)},                  # 紫土地：8e4af7
					4: {"color": Color(0.33, 0.4, 0.59)}                    # 黑土地：546596
				}
				
				if land_level in level_config:
					var config = level_config[land_level]
					ground_image.self_modulate = config["color"]
				else:
					# 未知等级，使用默认颜色
					ground_image.self_modulate = Color.WHITE
				
				# 空地不显示状态标签
				status_label.text = ""
				
				# 确保label显示并设置文本
				label.show()
				label.modulate = Color.GREEN#绿色
				label.text = land_text
				progressbar.hide()
				# 空地不显示tooltip
				button.tooltip_text = ""
		else:
			# 未开垦的地块
			# 确保label显示并设置文本
			label.show()
			label.modulate = Color.WEB_GRAY#深褐色
			label.text = "[" + "未开垦" + "]"
			progressbar.hide()
			# 未开垦地块恢复默认颜色和状态
			ground_image.self_modulate = Color.WHITE
			status_label.text = ""
			# 未开垦地块不显示tooltip
			button.tooltip_text = ""

	# 根据已开垦地块数量更新 dig_money
	dig_money = digged_count * 1000


# 仅在加载游戏或特定情况下完全刷新地块 - 用于与服务器同步时
func _refresh_farm_lots():
	_create_farm_buttons()
	_update_farm_lots_state()


# 更新玩家信息显示
func _update_ui():
	show_money.text = "当前金钱：" + str(money) + " 元"
	show_experience.text = "当前经验：" + str(experience) + " 点"
	show_level.text = "当前等级：" + str(level) + " 级"
	show_hunger_value.text = "体力值：" + str(stamina)
	
	
	# 根据当前模式显示点赞数
	if is_visiting_mode:
		var target_likes = visited_player_data.get("total_likes", 0)
		show_like.text = "总赞数：" + str(int(target_likes))
	else:
		# 需要从登录数据中获取自己的点赞数
		var my_likes = login_data.get("total_likes", 0)
		show_like.text = "总赞数：" + str(int(my_likes))


# 处理地块点击事件
func _on_item_selected(index):
	print("调试：地块点击事件 - 地块索引: ", index)
	print("调试：道具选择状态 - is_item_selected: ", is_item_selected, ", selected_item_name: ", selected_item_name)
	
	# 检查是否处于一键种植的地块选择模式
	if one_click_plant_panel and one_click_plant_panel.has_method("on_lot_selected"):
		if one_click_plant_panel.on_lot_selected(index):
			# 一键种植面板已处理了这次点击，直接返回
			print("调试：一键种植面板处理了此点击")
			return
	
	# 检查是否有道具被选择，如果有则使用道具
	if is_item_selected and selected_item_name != "":
		print("调试：检测到道具选择状态，调用道具使用函数")
		_use_item_on_lot(index, selected_item_name)
		return
	
	print("调试：没有道具选择，打开土地面板")
	# 正常模式下，先设置地块索引，再打开土地面板
	land_panel.selected_lot_index = index
	selected_lot_index = index
	land_panel.show_panel()
	# 更新按钮文本
	if land_panel.has_method("_update_button_texts"):
		land_panel._update_button_texts()

# 收获作物
func _harvest_crop(index):
	var lot = farm_lots[index]
	if lot["grow_time"] >= lot["max_grow_time"]:
		# 发送收获请求到服务器
		if network_manager and network_manager.sendHarvestCrop(index):
			pass
	else:   
		Toast.show("作物还未成熟", Color.RED)

# 检查玩家是否可以升级
func _check_level_up():
	var level_up_experience = 100 * level
	if experience >= level_up_experience:
		level += 1
		experience -= level_up_experience
		#print("恭喜！你升到了等级 ", level)
		Toast.show("恭喜！你升到了" + str(level) + "级 ", Color.SKY_BLUE)
		crop_store_panel.init_store()


#===============================================作物数据处理===============================================
# 从服务器获取作物数据
func _load_crop_data():
	var network_manager = get_node("/root/main/UI/TCPNerworkManager")
	if network_manager and network_manager.is_connected_to_server():
		# 从服务器请求作物数据
		print("正在从服务器获取作物数据...")
		network_manager.sendGetCropData()
	else:
		# 如果无法连接服务器，尝试加载本地数据
		print("无法连接服务器，尝试加载本地作物数据...")
		_load_local_crop_data()

# 尝试从服务器加载最新数据
func _try_load_from_server():

	if network_manager and network_manager.is_connected_to_server():
		# 从服务器请求最新作物数据
		print("尝试从服务器获取最新作物数据...")
		network_manager.sendGetCropData()
	else:
		print("服务器未连接，使用当前作物数据")

# 处理服务器作物数据响应
func _handle_crop_data_response(response_data):
	var success = response_data.get("success", false)
	
	if success:
		var crop_data = response_data.get("crop_data", {})
		if crop_data:
			# 保存到本地文件
			_save_crop_data_to_local(crop_data)
			# 设置全局变量
			can_planted_crop = crop_data
			print("作物数据已从服务器更新")
			
			# 重新初始化商店和背包UI，因为现在有了作物数据
			_refresh_ui_after_crop_data_loaded()
		else:
			print("服务器返回的作物数据为空")
			_load_local_crop_data()
	else:
		var message = response_data.get("message", "未知错误")
		print("从服务器获取作物数据失败：", message)
		_load_local_crop_data()

# 从本地文件加载作物数据（备用方案）
func _load_local_crop_data():
	# 优先尝试加载用户目录下的缓存文件
	var file = FileAccess.open("user://crop_data.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			can_planted_crop = json.get_data()
			print("已加载本地缓存的作物数据")
			_refresh_ui_after_crop_data_loaded()
			return
		else:
			print("本地缓存作物数据JSON解析错误：", json.get_error_message())
	
	# 如果缓存文件不存在或解析失败，加载默认数据
	file = FileAccess.open("res://Data/crop_data.json", FileAccess.READ)
	if not file:
		print("无法读取默认作物数据文件！")
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("默认作物数据JSON解析错误：", json.get_error_message())
		return
		
	can_planted_crop = json.get_data()
	print("已加载默认作物数据")
	_refresh_ui_after_crop_data_loaded()

# 作物数据加载后刷新UI
func _refresh_ui_after_crop_data_loaded():
	# 重新初始化商店和背包UI，因为现在有了作物数据
	if crop_store_panel and crop_store_panel.has_method("init_store"):
		crop_store_panel.init_store()
		print("商店已根据作物数据重新初始化")
	
	if player_bag_panel and player_bag_panel.has_method("init_player_bag"):
		player_bag_panel.init_player_bag()
		print("背包已根据作物数据重新初始化")

# 保存作物数据到本地文件
func _save_crop_data_to_local(crop_data):
	var file = FileAccess.open("user://crop_data.json", FileAccess.WRITE)
	if not file:
		print("无法创建本地作物数据缓存文件！")
		return
		
	var json_string = JSON.stringify(crop_data, "\t")
	file.store_string(json_string)
	file.close()
	print("作物数据已保存到本地缓存")

#===============================================作物数据处理===============================================



#===============================================作物图片缓存系统===============================================

## 作物图片缓存和管理系统
class CropTextureManager:
	"""作物图片缓存管理器 - 负责所有作物图片的加载、缓存和管理"""
	
	# 缓存字典
	var texture_cache: Dictionary = {}          # 序列帧缓存 {crop_name: [Texture2D]}
	var mature_texture_cache: Dictionary = {}   # 成熟图片缓存 {crop_name: Texture2D}
	var frame_counts: Dictionary = {}           # 帧数记录 {crop_name: int}
	
	# 加载状态
	var is_loading: bool = false
	var load_progress: float = 0.0
	var total_crops: int = 0
	var loaded_crops: int = 0
	
	func _init():
		print("[CropTextureManager] 初始化作物图片管理器")
	
	## 异步预加载所有作物图片 - 主要入口函数
	func preload_all_textures_async(crop_data: Dictionary, progress_callback: Callable) -> void:
		"""异步预加载所有作物图片，提供进度回调"""
		if is_loading:
			print("[CropTextureManager] 正在加载中，跳过重复请求")
			return
		
		is_loading = true
		load_progress = 0.0
		total_crops = crop_data.size()
		loaded_crops = 0
		
		print("[CropTextureManager] 开始异步预加载 %d 种作物图片" % total_crops)
		
		# 阶段1：加载默认图片 (0-10%)
		progress_callback.call(0, "正在加载默认图片...")
		await _load_default_textures_async()
		progress_callback.call(10, "默认图片加载完成")
		
		# 阶段2：批量加载作物图片 (10-90%)
		await _load_crops_batch_async(crop_data, progress_callback)
		
		# 阶段3：完成 (90-100%)
		progress_callback.call(100, "所有作物图片加载完成！")
		_print_cache_stats()
		
		is_loading = false
		print("[CropTextureManager] 预加载完成")
	
	## 批量异步加载作物图片
	func _load_crops_batch_async(crop_data: Dictionary, progress_callback: Callable) -> void:
		"""批量异步加载作物图片，每帧加载有限数量避免卡顿"""
		const BATCH_SIZE = 3  # 每帧最多加载3种作物
		var crop_names = crop_data.keys()
		var batch_count = 0
		
		for crop_name in crop_names:
			# 加载序列帧和成熟图片
			_load_crop_textures_immediate(crop_name)
			_load_mature_texture_immediate(crop_name)
			
			loaded_crops += 1
			batch_count += 1
			
			# 更新进度 (10% 到 90% 区间)
			var progress = 10 + int((float(loaded_crops) / float(total_crops)) * 80)
			var message = "加载作物图片: %s (%d/%d)" % [crop_name, loaded_crops, total_crops]
			progress_callback.call(progress, message)
			
			# 每批次后暂停一帧，避免卡顿
			if batch_count >= BATCH_SIZE:
				batch_count = 0
				await Engine.get_main_loop().process_frame
	
	## 立即加载默认图片（同步）
	func _load_default_textures_async() -> void:
		"""异步加载默认图片"""
		const DEFAULT_CROP = "默认"
		const DEFAULT_PATH = "res://assets/作物/默认/"
		
		if texture_cache.has(DEFAULT_CROP):
			return
		
		var textures = []
		var frame_index = 0
		
		# 加载序列帧
		while true:
			var texture_path = DEFAULT_PATH + str(frame_index) + ".webp"
			if ResourceLoader.exists(texture_path):
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
					frame_index += 1
				else:
					break
			else:
				break
		
		# 如果没有序列帧，尝试加载单个图片
		if textures.size() == 0:
			var single_path = DEFAULT_PATH + "0.webp"
			if ResourceLoader.exists(single_path):
				var texture = load(single_path)
				if texture:
					textures.append(texture)
		
		# 缓存结果
		texture_cache[DEFAULT_CROP] = textures
		frame_counts[DEFAULT_CROP] = textures.size()
		
		# 加载默认成熟图片
		var mature_path = DEFAULT_PATH + "成熟.webp"
		if ResourceLoader.exists(mature_path):
			var mature_texture = load(mature_path)
			if mature_texture:
				mature_texture_cache[DEFAULT_CROP] = mature_texture
		
		print("[CropTextureManager] 默认图片加载完成：%d 帧" % textures.size())
		
		# 让出一帧
		await Engine.get_main_loop().process_frame
	
	## 立即加载单个作物的序列帧图片
	func _load_crop_textures_immediate(crop_name: String) -> Array:
		"""立即加载指定作物的序列帧图片"""
		if texture_cache.has(crop_name):
			return texture_cache[crop_name]
		
		var textures = []
		var crop_path = "res://assets/作物/" + crop_name + "/"
		
		# 检查作物文件夹是否存在
		if not DirAccess.dir_exists_absolute(crop_path):
			# 文件夹不存在，使用默认图片
			textures = texture_cache.get("默认", [])
		else:
			# 加载序列帧
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
			
			# 如果没找到图片，使用默认图片
			if textures.size() == 0:
				textures = texture_cache.get("默认", [])
		
		# 缓存结果
		texture_cache[crop_name] = textures
		frame_counts[crop_name] = textures.size()
		
		return textures
	
	## 立即加载单个作物的成熟图片
	func _load_mature_texture_immediate(crop_name: String) -> Texture2D:
		"""立即加载指定作物的成熟图片"""
		if mature_texture_cache.has(crop_name):
			return mature_texture_cache[crop_name]
		
		var crop_path = "res://assets/作物/" + crop_name + "/"
		var mature_path = crop_path + "成熟.webp"
		var texture: Texture2D = null
		
		# 尝试加载作物专属成熟图片
		if ResourceLoader.exists(mature_path):
			texture = load(mature_path)
		
		# 如果没找到，使用默认成熟图片
		if not texture:
			texture = mature_texture_cache.get("默认", null)
		
		# 缓存结果
		if texture:
			mature_texture_cache[crop_name] = texture
		
		return texture
	
	## 根据生长进度获取作物图片
	func get_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
		"""根据作物名称和生长进度获取对应的图片"""
		# 100%成熟时优先使用成熟图片
		if progress >= 1.0:
			var mature_texture = mature_texture_cache.get(crop_name, null)
			if mature_texture:
				return mature_texture
		
		# 使用序列帧图片
		var textures = texture_cache.get(crop_name, [])
		if textures.size() == 0:
			return null
		
		if textures.size() == 1:
			return textures[0]
		
		# 根据进度计算帧索引
		var frame_index = int(progress * (textures.size() - 1))
		frame_index = clamp(frame_index, 0, textures.size() - 1)
		
		return textures[frame_index]
	
	## 清理缓存
	func clear_cache() -> void:
		"""清理所有缓存，释放内存"""
		texture_cache.clear()
		mature_texture_cache.clear()
		frame_counts.clear()
		print("[CropTextureManager] 缓存已清理")
	
	## 打印缓存统计信息
	func _print_cache_stats() -> void:
		"""打印缓存统计信息"""
		print("[CropTextureManager] 缓存统计:")
		print("  - 序列帧缓存: %d 种作物" % texture_cache.size())
		print("  - 成熟图片缓存: %d 种作物" % mature_texture_cache.size())
		var total_frames = 0
		for count in frame_counts.values():
			total_frames += count
		print("  - 总图片帧数: %d 帧" % total_frames)
	
	## 获取详细缓存信息
	func get_cache_info() -> String:
		"""获取详细的缓存信息字符串"""
		var info = "作物图片缓存详情:\n"
		for crop_name in texture_cache.keys():
			var frame_count = frame_counts.get(crop_name, 0)
			var has_mature = mature_texture_cache.has(crop_name)
			info += "  - %s: %d帧" % [crop_name, frame_count]
			if has_mature:
				info += " (含成熟图片)"
			info += "\n"
		return info

# 全局作物图片管理器实例
var crop_texture_manager: CropTextureManager

#===============================================作物图片更新===============================================

## 更新单个地块的作物图片显示（直接切换）
func _update_lot_crop_sprite(button: Button, lot_data: Dictionary) -> void:
	var crop_sprite = button.get_node("crop_sprite")
	
	# 未开垦或空地，隐藏图片
	if not lot_data["is_diged"] or not lot_data["is_planted"] or lot_data["crop_type"] == "":
		crop_sprite.visible = false
		return
	
	# 显示作物图片
	crop_sprite.visible = true
	
	var crop_name = lot_data["crop_type"]
	var grow_time = float(lot_data["grow_time"])
	var max_grow_time = float(lot_data["max_grow_time"])
	
	# 计算生长进度
	var progress = 0.0
	if max_grow_time > 0:
		progress = clamp(grow_time / max_grow_time, 0.0, 1.0)
	
	# 获取对应图片
	var texture: Texture2D = null
	if crop_texture_manager:
		texture = crop_texture_manager.get_texture_by_progress(crop_name, progress)
	
	if texture:
		# 直接切换图片，无渐变效果
		crop_sprite.texture = texture
		crop_sprite.modulate = Color.WHITE
	else:
		crop_sprite.visible = false



## 批量刷新所有地块的作物图片
func _refresh_all_crop_sprites() -> void:
	for i in range(min(farm_lots.size(), grid_container.get_child_count())):
		var button = grid_container.get_child(i)
		var lot = farm_lots[i]
		_update_lot_crop_sprite(button, lot)
#===============================================作物图片更新===============================================


#===============================================加载进度管理===============================================

## 更新加载进度显示
func _update_load_progress(progress: int, message: String = "") -> void:
	"""更新加载进度条和提示信息"""
	load_progress_bar.value = progress
	
	# 更新消息显示
	var message_label = load_progress_panel.get_node_or_null("MessageLabel")
	if message_label and message != "":
		message_label.text = message
	
	if message != "":
		print("[加载进度] %d%% - %s" % [progress, message])

## 主预加载函数 - 游戏启动时调用
func _preload_all_crop_textures() -> void:
	"""预加载所有作物图片的主函数"""
	print("[主游戏] 开始预加载作物图片...")
	
	# 初始化管理器
	if not crop_texture_manager:
		crop_texture_manager = CropTextureManager.new()
	
	# 等待作物数据加载
	_update_load_progress(0, "等待作物数据...")
	await _wait_for_crop_data()
	
	# 开始异步预加载
	await crop_texture_manager.preload_all_textures_async(
		can_planted_crop,
		Callable(self, "_update_load_progress")
	)
	
	# 完成后隐藏加载面板
	await get_tree().create_timer(0.5).timeout
	load_progress_panel.hide()
	print("[主游戏] 图片预加载完成，隐藏加载面板")

## 等待作物数据加载完成
func _wait_for_crop_data() -> void:
	"""等待作物数据加载完成"""
	const MAX_WAIT_TIME = 5.0
	var wait_time = 0.0
	
	while can_planted_crop.size() == 0 and wait_time < MAX_WAIT_TIME:
		await get_tree().create_timer(0.1).timeout
		wait_time += 0.1
	
	if can_planted_crop.size() == 0:
		_update_load_progress(90, "作物数据加载失败，跳过图片预加载")
		print("[警告] 作物数据未加载，跳过图片预加载")
	else:
		print("[主游戏] 作物数据加载完成，共 %d 种作物" % can_planted_crop.size())

#===============================================调试和维护工具===============================================

## 调试：测试直接切换图片
func _debug_test_direct_switch(lot_index: int = 0) -> void:
	"""调试用：测试指定地块的直接图片切换"""
	if lot_index >= 0 and lot_index < grid_container.get_child_count():
		var button = grid_container.get_child(lot_index)
		var crop_sprite = button.get_node_or_null("crop_sprite")
		if crop_sprite and crop_texture_manager:
			# 随机选择一个作物图片进行测试
			var crop_names = can_planted_crop.keys()
			if crop_names.size() > 0:
				var random_crop = crop_names[randi() % crop_names.size()]
				var test_texture = crop_texture_manager.get_texture_by_progress(random_crop, 1.0)
				if test_texture:
					print("[调试] 测试地块 ", lot_index, " 的直接图片切换，使用作物：", random_crop)
					crop_sprite.texture = test_texture
					crop_sprite.modulate = Color.WHITE
					crop_sprite.visible = true
				else:
					print("[调试] 无法获取测试贴图")
			else:
				print("[调试] 作物数据为空")
		else:
			print("[调试] 无法找到crop_sprite或图片管理器未初始化")
	else:
		print("[调试] 地块索引无效：", lot_index)

## 调试：打印缓存信息
func _debug_print_crop_cache() -> void:
	"""调试用：打印当前作物图片缓存信息"""
	if crop_texture_manager:
		print(crop_texture_manager.get_cache_info())
	else:
		print("[调试] 作物图片管理器未初始化")

## 调试：强制刷新所有图片
func _debug_refresh_all_crop_sprites() -> void:
	"""调试用：强制刷新所有地块的作物图片"""
	print("[调试] 强制刷新所有地块图片...")
	_refresh_all_crop_sprites()
	print("[调试] 图片刷新完成")

## 调试：清理图片缓存
func _debug_clear_crop_cache() -> void:
	"""调试用：清理作物图片缓存"""
	if crop_texture_manager:
		crop_texture_manager.clear_cache()
		print("[调试] 图片缓存已清理")

#===============================================向后兼容性===============================================

# 为了保持向后兼容，保留一些原来的函数名
func _load_crop_textures(crop_name: String) -> Array:
	"""向后兼容：加载作物图片序列帧"""
	if crop_texture_manager:
		return crop_texture_manager._load_crop_textures_immediate(crop_name)
	return []

func _get_crop_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
	"""向后兼容：根据进度获取作物图片"""
	if crop_texture_manager:
		return crop_texture_manager.get_texture_by_progress(crop_name, progress)
	return null

func _clear_crop_textures_cache() -> void:
	"""向后兼容：清理图片缓存"""
	if crop_texture_manager:
		crop_texture_manager.clear_cache()

func _get_crop_cache_info() -> String:
	"""向后兼容：获取缓存信息"""
	if crop_texture_manager:
		return crop_texture_manager.get_cache_info()
	return "图片管理器未初始化"

#===============================================作物图片处理结束===============================================



#===============================================返回自己的农场处理===============================================
#访客模式下返回我的农场
func _on_return_my_farm_button_pressed() -> void:
	# 如果当前处于访问模式，返回自己的农场
	if is_visiting_mode:
		return_to_my_farm()
	else:
		# 如果不在访问模式，这个按钮可能用于其他功能或者不做任何操作
		print("当前已在自己的农场")

# 返回自己的农场
func return_to_my_farm():
	if not is_visiting_mode:
		return
	
	# 发送返回自己农场的请求到服务器
	if network_manager and network_manager.has_method("sendReturnMyFarm"):
		var success = network_manager.sendReturnMyFarm()
		if success:
			print("已发送返回自己农场的请求")
		else:
			Toast.show("网络未连接，无法返回农场", Color.RED)
			print("发送返回农场请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

#===============================================返回自己的农场处理===============================================






#打开种子商店面板
func _on_open_store_button_pressed() -> void:
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = true
	
	# 如果处于访问模式，不允许打开商店
	if is_visiting_mode:
		Toast.show("访问模式下无法使用商店", Color.ORANGE)
		return
	
	# 确保商店面板已初始化
	crop_store_panel.init_store()
	# 显示商店面板
	crop_store_panel.show()
	# 确保在最前面显示
	crop_store_panel.move_to_front() 
	pass

#打开玩家排行榜面板
func _on_player_ranking_button_pressed() -> void:
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = true
	
	player_ranking_panel.show()
	player_ranking_panel.request_player_rankings()
	pass 


#打开设置面板 暂时没想到可以设置什么
func _on_setting_button_pressed() -> void:
	pass


#打开我的宠物系统，这个比较复杂以后再实现
func _on_my_pet_button_pressed() -> void:
	pass 


# 处理AcceptDialog的确认信号
func _on_accept_dialog_confirmed() -> void:
	var action_type = accept_dialog.get_meta("action_type", "")
	
	if action_type == "one_click_harvest":
		# 执行一键收获逻辑
		_execute_one_click_harvest()
	elif action_type == "buy_new_ground":
		# 执行购买新地块逻辑
		_execute_buy_new_ground()
	elif action_type == "return_main_menu":
		# 执行返回主菜单逻辑
		_execute_return_main_menu()
	else:
		# 处理其他类型的确认逻辑
		pass


#打开一键种植面板
func _on_one_click_plant_button_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法使用一键种植", Color.ORANGE)
		return
	
	# 检查是否有网络连接
	if not network_manager.is_connected_to_server():
		Toast.show("未连接服务器，无法使用一键种植", Color.RED)
		return
	
	# 显示一键种植面板
	one_click_plant_panel.show()
	one_click_plant_panel.move_to_front() 

# 处理连接断开事件
func _on_connection_lost():
	
	# 重置游戏状态
	start_game = false
	
	# 隐藏所有游戏UI
	game_info_h_box_1.hide()
	game_info_h_box_2.hide()
	farm_v_box.hide()
	visit_v_box.hide()
	other_v_box.hide()
	
	# 隐藏所有面板
	crop_store_panel.hide()
	player_bag_panel.hide()
	lucky_draw_panel.hide()
	daily_check_in_panel.hide()
	player_ranking_panel.hide()
	one_click_plant_panel.hide()
	land_panel.hide()
	accept_dialog.hide()
	
	# 重置访问模式
	if is_visiting_mode:
		_handle_return_my_farm_response({"success": true})
	
	# 显示登录面板
	if login_panel:
		login_panel.show()
		
		# 更新登录面板状态
		if login_panel.has_method("_on_connection_lost"):
			login_panel._on_connection_lost()
	
	# 显示连接断开的提示
	Toast.show("与服务器的连接已断开，请重新登录", Color.ORANGE, 3.0, 1.0)

#打开种子仓库面板
func _on_seed_warehouse_button_pressed() -> void:
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = true
	player_bag_panel.show()
	pass


#打开玩家道具背包面板
func _on_item_bag_button_pressed() -> void:
	item_bag_panel.show()
	pass 
	
#打开道具商店面板
func _on_item_store_button_pressed() -> void:
	item_store_panel.show()
	pass 

#打开作物仓库面板
func _on_crop_warehouse_button_pressed() -> void:
	crop_warehouse_panel.show()
	pass










#===============================================添加新地块处理===============================================
#添加新的地块，默认花费2000
func _on_add_new_ground_button_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法购买新地块", Color.ORANGE)
		return
	
	# 检查是否有网络连接
	if not network_manager.is_connected_to_server():
		Toast.show("未连接服务器，无法购买新地块", Color.RED)
		return
	
	# 检查玩家金钱是否足够
	var new_ground_cost = 2000
	if money < new_ground_cost:
		Toast.show("金钱不足！购买新地块需要 " + str(new_ground_cost) + " 元", Color.RED)
		return
	
	# 检查地块数量限制（可以根据需要设置最大地块数）
	var max_lots = 80  # 假设最大100个地块
	if farm_lots.size() >= max_lots:
		Toast.show("已达到最大地块数量限制（" + str(max_lots) + "个）", Color.YELLOW)
		return
	
	# 显示确认弹窗
	accept_dialog.set_dialog_title("购买新地块确认")
	accept_dialog.set_dialog_content("购买一个新的未开垦地块\n花费 " + str(new_ground_cost) + " 元？\n\n当前地块数量：" + str(farm_lots.size()) + " 个")
	accept_dialog.popup_centered()
	
	# 标记当前操作为购买新地块
	accept_dialog.set_meta("action_type", "buy_new_ground")

# 执行购买新地块逻辑
func _execute_buy_new_ground():
	var new_ground_cost = 2000
	
	# 发送购买新地块请求到服务器
	if network_manager and network_manager.has_method("sendBuyNewGround"):
		var success = network_manager.sendBuyNewGround()
		if success:
			print("已发送购买新地块请求")
		else:
			Toast.show("网络未连接，无法购买新地块", Color.RED)
			print("发送购买新地块请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

#===============================================添加新地块处理===============================================



#===============================================每日签到处理===============================================
#每日签到 奖励可以有钱币，经验，随机种子 连续签到奖励更多 连续签到只要不中断，奖励会随着签到的次数逐渐变得丰厚
func _on_daily_check_in_button_pressed() -> void:
	daily_check_in_panel.show()
	# 刷新签到数据
	if daily_check_in_panel.has_method("refresh_check_in_data"):
		daily_check_in_panel.refresh_check_in_data()

# 处理每日签到响应
func _handle_daily_check_in_response(response: Dictionary) -> void:
	# 更新玩家数据
	var updated_data = response.get("updated_data", {})
	if updated_data.has("money"):
		money = updated_data["money"]
	if updated_data.has("experience"):
		experience = updated_data["experience"]
	if updated_data.has("level"):
		level = updated_data["level"]
	if updated_data.has("player_bag"):
		player_bag = updated_data["player_bag"]
		# 修复背包数据兼容性问题
		_fix_player_bag_data()
	
	# 更新UI
	_update_ui()
	
	# 更新玩家背包UI
	if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
		player_bag_panel.update_player_bag_ui()
	
	# 向签到面板传递响应
	if daily_check_in_panel and daily_check_in_panel.has_method("handle_check_in_response"):
		daily_check_in_panel.handle_check_in_response(response)
	
	# 显示签到结果通知
	var success = response.get("success", false)
	if success:
		var rewards = response.get("rewards", {})
		var consecutive_days = response.get("consecutive_days", 1)
		var message = "签到成功！连续签到 %d 天" % consecutive_days
		Toast.show(message, Color.GREEN)
	else:
		var error_message = response.get("message", "签到失败")
		Toast.show(error_message, Color.RED)

# 处理获取签到数据响应
func _handle_check_in_data_response(response: Dictionary) -> void:
	# 向签到面板传递响应
	if daily_check_in_panel and daily_check_in_panel.has_method("handle_check_in_data_response"):
		daily_check_in_panel.handle_check_in_data_response(response)

#===============================================每日签到处理===============================================



#===============================================一键收获处理===============================================
#一键收获 默认花费400元 可以一键收获已成熟作物 
func _on_one_click_harvestbutton_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法使用一键收获", Color.ORANGE)
		return
	
	# 检查是否有网络连接
	if not network_manager.is_connected_to_server():
		Toast.show("未连接服务器，无法使用一键收获", Color.RED)
		return
	
	# 统计有多少成熟的作物
	var mature_crops_count = 0
	for lot in farm_lots:
		if lot["is_diged"] and lot["is_planted"] and not lot.get("is_dead", false):
			if lot["grow_time"] >= lot["max_grow_time"]:
				mature_crops_count += 1
	
	# 如果没有成熟的作物
	if mature_crops_count == 0:
		Toast.show("没有可以收获的成熟作物", Color.YELLOW)
		return
	
	# 检查玩家金钱是否足够
	var one_click_cost = 400
	if money < one_click_cost:
		Toast.show("金钱不足！一键收获需要 " + str(one_click_cost) + " 元", Color.RED)
		return
	
	# 显示确认弹窗
	accept_dialog.set_dialog_title("一键收获确认")
	accept_dialog.set_dialog_content("发现 " + str(mature_crops_count) + " 个成熟作物\n花费 " + str(one_click_cost) + " 元进行一键收获？")
	accept_dialog.popup_centered()
	
	# 标记当前操作为一键收获
	accept_dialog.set_meta("action_type", "one_click_harvest")

# 执行一键收获逻辑
func _execute_one_click_harvest():
	var one_click_cost = 400
	var harvested_count = 0
	var success_count = 0
	
	# 先扣除费用
	money -= one_click_cost
	_update_ui()
	
	# 遍历所有地块，收获成熟作物
	for i in range(len(farm_lots)):
		var lot = farm_lots[i]
		if lot["is_diged"] and lot["is_planted"] and not lot.get("is_dead", false):
			if lot["grow_time"] >= lot["max_grow_time"]:
				harvested_count += 1
				# 发送收获请求到服务器
				if network_manager and network_manager.sendHarvestCrop(i):
					success_count += 1
					# 添加小延迟避免服务器压力过大
					await get_tree().create_timer(0.3).timeout
	
	# 显示结果
	if success_count > 0:
		Toast.show("一键收获完成！成功收获 " + str(success_count) + " 个作物，花费 " + str(one_click_cost) + " 元", Color.GREEN)
		print("一键收获完成，收获了 ", success_count, " 个作物")
	else:
		Toast.show("一键收获失败，请检查网络连接", Color.RED)
		# 如果失败，退还费用
		money += one_click_cost
		_update_ui()

#===============================================一键收获处理===============================================



#===============================================返回主菜单处理===============================================
#断开连接并返回主菜单界面
func _on_return_main_menu_button_pressed() -> void:
	# 显示确认弹窗
	accept_dialog.set_dialog_title("返回主菜单")
	accept_dialog.set_dialog_content("确定要断开连接并返回主菜单吗？\n")
	accept_dialog.popup_centered()
	
	# 标记当前操作为返回主菜单
	accept_dialog.set_meta("action_type", "return_main_menu")

# 执行返回主菜单逻辑
func _execute_return_main_menu():
	# 断开与服务器的连接
	if network_manager and network_manager.is_connected_to_server():
		network_manager.client.disconnect_from_server()
		print("已断开与服务器的连接")
	
	# 直接切换到主菜单场景
	get_tree().change_scene_to_file('res://GUI/MainMenuPanel.tscn')
#===============================================返回主菜单处理===============================================



#===============================================幸运抽奖处理===============================================
#幸运抽奖 默认800元抽一次 五连抽打九折 十连抽打八折 奖励可以有钱币，经验，随机种子  
func _on_lucky_draw_button_pressed() -> void:
	lucky_draw_panel.show()
	# 刷新抽奖显示数据
	if lucky_draw_panel.has_method("refresh_reward_display"):
		lucky_draw_panel.refresh_reward_display()

# 处理幸运抽奖响应
func _handle_lucky_draw_response(response: Dictionary) -> void:
	# 更新玩家数据
	var updated_data = response.get("updated_data", {})
	if updated_data.has("money"):
		money = updated_data["money"]
	if updated_data.has("experience"):
		experience = updated_data["experience"]
	if updated_data.has("level"):
		level = updated_data["level"]
	if updated_data.has("player_bag"):
		player_bag = updated_data["player_bag"]
		# 修复背包数据兼容性问题
		_fix_player_bag_data()
	
	# 更新UI
	_update_ui()
	
	# 更新玩家背包UI
	if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
		player_bag_panel.update_player_bag_ui()
	
	# 向抽奖面板传递响应
	if lucky_draw_panel and lucky_draw_panel.has_method("handle_lucky_draw_response"):
		lucky_draw_panel.handle_lucky_draw_response(response)
	
	# 显示抽奖结果通知
	var success = response.get("success", false)
	if success:
		var draw_type = response.get("draw_type", "single")
		var cost = response.get("cost", 0)
		var rewards = response.get("rewards", [])
		
		var type_names = {
			"single": "单抽",
			"five": "五连抽",
			"ten": "十连抽"
		}
		
		var message = "%s成功！消费 %d 金币，获得 %d 个奖励" % [
			type_names.get(draw_type, draw_type), cost, rewards.size()
		]
		Toast.show(message, Color.GREEN)
		
		# 检查是否有传奇奖励
		var has_legendary = false
		for reward in rewards:
			if reward.get("rarity") == "传奇":
				has_legendary = true
				break
		
		if has_legendary:
			Toast.show("🎉 恭喜获得传奇奖励！", Color.GOLD)
	else:
		var error_message = response.get("message", "抽奖失败")
		Toast.show(error_message, Color.RED)

# 幸运抽奖完成信号处理
func _on_lucky_draw_completed(rewards: Array, draw_type: String) -> void:
	# 可以在这里添加额外的处理逻辑，比如成就检查、特殊效果等
	print("幸运抽奖完成：", draw_type, "，获得奖励：", rewards.size(), "个")

# 幸运抽奖失败信号处理
func _on_lucky_draw_failed(error_message: String) -> void:
	print("幸运抽奖失败：", error_message)

# 获取作物数据（供抽奖面板使用）
func get_crop_data() -> Dictionary:
	return can_planted_crop

#===============================================幸运抽奖处理===============================================



#===============================================点赞处理===============================================
#访客模式下可以给别人点赞，然后总赞数显示在show_like节点上
func _on_like_button_pressed() -> void:
	# 检查是否处于访问模式
	if not is_visiting_mode:
		Toast.show("只能在访问其他玩家农场时点赞", Color.ORANGE)
		return
	
	# 检查是否有网络连接
	if not network_manager.is_connected_to_server():
		Toast.show("未连接服务器，无法点赞", Color.RED)
		return
	
	# 获取被访问玩家的用户名
	var target_username = visited_player_data.get("user_name", "")
	if target_username == "":
		Toast.show("无法获取目标玩家信息", Color.RED)
		return
	
	# 发送点赞请求
	if network_manager and network_manager.has_method("sendLikePlayer"):
		var success = network_manager.sendLikePlayer(target_username)
		if success:
			print("已发送点赞请求给玩家：", target_username)
		else:
			Toast.show("网络未连接，无法点赞", Color.RED)
			print("发送点赞请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

# 处理点赞响应
func _handle_like_player_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var target_likes = data.get("target_likes", 0)
		Toast.show(message, Color.PINK)
		
		# 更新被访问玩家的点赞数显示
		if is_visiting_mode and visited_player_data:
			visited_player_data["total_likes"] = target_likes
			show_like.text = "总赞数：" + str(int(target_likes))
		
		print("点赞成功，目标玩家总赞数：", target_likes)
	else:
		Toast.show(message, Color.RED)
		print("点赞失败：", message)

#===============================================点赞处理===============================================



#===============================================获取在线人数处理===============================================
# 启动在线人数更新定时器
func _start_online_players_timer():
	# 初始显示连接中状态
	_update_online_players_display(0, false, true)
	
	# 立即请求一次在线人数
	_request_online_players()
	
	# 创建定时器，每60秒请求一次在线人数
	var timer = Timer.new()
	timer.wait_time = 60.0  # 60秒
	timer.timeout.connect(_request_online_players)
	timer.autostart = true
	add_child(timer)
	print("在线人数更新定时器已启动，每60秒更新一次")

# 请求在线人数
func _request_online_players():
	if network_manager and network_manager.is_connected_to_server():
		var success = network_manager.sendGetOnlinePlayers()
		if success:
			print("已发送在线人数请求")
		else:
			print("发送在线人数请求失败")
			_update_online_players_display(0, false, false)
	else:
		print("未连接服务器，无法获取在线人数")
		_update_online_players_display(0, false, false)

# 处理在线人数响应
func _handle_online_players_response(data):
	var success = data.get("success", false)
	if success:
		var online_players = data.get("online_players", 0)
		_update_online_players_display(online_players, true, false)
		print("当前在线人数：", online_players)
	else:
		var message = data.get("message", "获取在线人数失败")
		print("在线人数请求失败：", message)
		_update_online_players_display(0, false, false)

# 更新在线人数显示
func _update_online_players_display(count: int, connected: bool, connecting: bool = false):
	if connecting:
		show_onlineplayer.text = "连接中..."
		show_onlineplayer.modulate = Color.YELLOW
	elif connected:
		show_onlineplayer.text = "在线设备：" + str(count) 
		show_onlineplayer.modulate = Color.GREEN
	else:
		show_onlineplayer.text = "离线"
		show_onlineplayer.modulate = Color.RED

#===============================================获取在线人数处理===============================================



#====================================领取新手玩家礼包处理=========================================
#新手玩家大礼包按钮点击，只能领取一次，领取后这个按钮对该账号永久隐藏
func _on_new_player_gift_button_pressed() -> void:
	# 检查网络连接
	if not network_manager or not network_manager.is_connected_to_server():
		Toast.show("网络未连接，无法领取新手大礼包", Color.RED, 2.0, 1.0)
		return
	
	# 显示确认对话框
	var confirm_dialog = preload("res://GUI/AcceptDialog.gd").new()
	add_child(confirm_dialog)
	
	confirm_dialog.set_dialog_title("领取新手大礼包")
	confirm_dialog.set_dialog_content("新手大礼包包含:\n• 6000金币\n• 1000经验\n• 龙果种子 x1\n• 杂交树1种子 x1\n• 杂交树2种子 x1\n\n每个账号只能领取一次，确定要领取吗？")
	confirm_dialog.set_ok_text("领取")
	confirm_dialog.set_cancel_text("取消")
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_claim_new_player_gift)
	confirm_dialog.canceled.connect(_on_cancel_claim_new_player_gift.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

#确认领取新手大礼包
func _on_confirm_claim_new_player_gift():
	if network_manager and network_manager.sendClaimNewPlayerGift():
		pass
	else:
		Toast.show("发送请求失败", Color.RED, 2.0, 1.0)

#取消领取新手大礼包
func _on_cancel_claim_new_player_gift(dialog):
	if dialog:
		dialog.queue_free()

#处理新手大礼包响应
func _handle_new_player_gift_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		if updated_data.has("money"):
			money = updated_data["money"]
		if updated_data.has("experience"):
			experience = updated_data["experience"]
		if updated_data.has("level"):
			level = updated_data["level"]
		if updated_data.has("player_bag"):
			player_bag = updated_data["player_bag"]
			# 修复背包数据兼容性问题
			_fix_player_bag_data()
		if updated_data.has("new_player_gift_claimed"):
			new_player_gift_claimed = updated_data["new_player_gift_claimed"]
		
		# 隐藏新手大礼包按钮
		var new_player_gift_button = find_child("NewPlayerGiftButton")
		if new_player_gift_button:
			new_player_gift_button.hide()
		
		# 更新UI
		_update_ui()
		
		# 显示成功消息
		Toast.show(message, Color.GOLD, 3.0, 1.0)
		
		print("新手大礼包领取成功！")
	else:
		# 如果已经领取过，也隐藏按钮
		if message.find("已经领取过") >= 0:
			new_player_gift_claimed = true
			var new_player_gift_button = find_child("NewPlayerGiftButton")
			if new_player_gift_button:
				new_player_gift_button.hide()
		
		# 显示错误消息
		Toast.show(message, Color.RED, 2.0, 1.0)

#====================================领取新手玩家礼包处理=========================================



#====================================一键截图处理=========================================
#一键截图按钮,隐藏所有UI，截图，然后保存在相应位置
func _on_one_click_screen_shot_pressed() -> void:
	# 保存当前UI状态
	var ui_state = _save_ui_visibility_state()
	
	# 隐藏所有UI
	_hide_all_ui_for_screenshot()
	
	# 进行截图
	var success = await _take_and_save_screenshot()
	
	# 等待一帧
	await get_tree().create_timer(2).timeout
	# 恢复UI显示
	_restore_ui_visibility_state(ui_state)
	
	# 显示截图结果
	if success:
		Toast.show("截图保存成功！", Color.GREEN, 2.0, 1.0)
	else:
		Toast.show("截图保存失败！", Color.RED, 2.0, 1.0)

# 保存当前UI可见性状态
func _save_ui_visibility_state() -> Dictionary:
	var state = {}
	
	# 保存主要UI容器状态
	state["game_info_h_box_1"] = game_info_h_box_1.visible
	state["game_info_h_box_2"] = game_info_h_box_2.visible
	state["farm_v_box"] = farm_v_box.visible
	state["visit_v_box"] = visit_v_box.visible
	state["other_v_box"] = other_v_box.visible
	state["game_info_h_box_3"] = game_info_h_box_3.visible
	
	# 保存面板状态
	state["crop_store_panel"] = crop_store_panel.visible
	state["player_bag_panel"] = player_bag_panel.visible
	state["lucky_draw_panel"] = lucky_draw_panel.visible
	state["daily_check_in_panel"] = daily_check_in_panel.visible
	state["player_ranking_panel"] = player_ranking_panel.visible
	state["one_click_plant_panel"] = one_click_plant_panel.visible
	state["land_panel"] = land_panel.visible
	state["accept_dialog"] = accept_dialog.visible
	state["login_panel"] = login_panel.visible if login_panel else false
	
	return state

# 隐藏所有UI用于截图
func _hide_all_ui_for_screenshot():
	# 隐藏主要UI容器
	game_info_h_box_1.hide()
	game_info_h_box_2.hide()
	farm_v_box.hide()
	visit_v_box.hide()
	other_v_box.hide()
	game_info_h_box_3.hide()
	
	# 隐藏所有面板
	crop_store_panel.hide()
	player_bag_panel.hide()
	lucky_draw_panel.hide()
	daily_check_in_panel.hide()
	player_ranking_panel.hide()
	one_click_plant_panel.hide()
	land_panel.hide()
	accept_dialog.hide()
	login_panel.hide()

# 恢复UI可见性状态
func _restore_ui_visibility_state(state: Dictionary):
	# 恢复主要UI容器状态
	if state.get("game_info_h_box_1", false):
		game_info_h_box_1.show()
	if state.get("game_info_h_box_2", false):
		game_info_h_box_2.show()
	if state.get("farm_v_box", false):
		farm_v_box.show()
	if state.get("visit_v_box", false):
		visit_v_box.show()
	if state.get("other_v_box", false):
		other_v_box.show()
	
	if state.get("game_info_h_box_3",false):
		game_info_h_box_3.show()
	
	# 恢复面板状态
	if state.get("crop_store_panel", false):
		crop_store_panel.show()
	if state.get("player_bag_panel", false):
		player_bag_panel.show()
	if state.get("lucky_draw_panel", false):
		lucky_draw_panel.show()
	if state.get("daily_check_in_panel", false):
		daily_check_in_panel.show()
	if state.get("player_ranking_panel", false):
		player_ranking_panel.show()
	if state.get("one_click_plant_panel", false):
		one_click_plant_panel.show()
	if state.get("land_panel", false):
		land_panel.show()
	if state.get("accept_dialog", false):
		accept_dialog.show()
	if state.get("login_panel", false) and login_panel:
		login_panel.show()

# 截图并保存到合适的位置
func _take_and_save_screenshot() -> bool:
	# 获取当前视口
	var viewport = get_viewport()
	if not viewport:
		print("无法获取视口")
		return false
	
	# 强制渲染一帧以确保所有效果都被应用
	RenderingServer.force_sync()
	await get_tree().process_frame
	
	# 获取包含所有后处理效果的最终图像
	var image = await _capture_viewport_with_effects(viewport)
	if not image:
		print("无法获取视口图像")
		return false
	
	# 生成文件名（包含时间戳）
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "萌芽农场_%04d%02d%02d_%02d%02d%02d.png" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	# 根据平台选择保存路径
	var save_path = _get_screenshot_save_path(filename)
	
	if save_path == "":
		print("无法确定截图保存路径")
		return false
	
	# 确保目录存在
	var dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		# 如果目录不存在，尝试创建
		var error = DirAccess.make_dir_recursive_absolute(dir_path)
		if error != OK:
			print("创建目录失败: ", dir_path, " 错误代码: ", error)
			return false
	
	# 保存图像
	var error = image.save_png(save_path)
	if error == OK:
		print("截图已保存到: ", save_path)
		return true
	else:
		print("保存截图失败，错误代码: ", error)
		return false

# 捕获包含所有视觉效果的视口图像
func _capture_viewport_with_effects(viewport: Viewport) -> Image:
	# 确保视口设置启用HDR和后处理效果
	var original_hdr = viewport.use_hdr_2d
	var original_msaa = viewport.msaa_2d
	
	# 临时启用HDR和抗锯齿以获得更好的截图质量
	viewport.use_hdr_2d = true
	viewport.msaa_2d = Viewport.MSAA_4X
	
	# 等待几帧让设置生效
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 获取图像
	var image = viewport.get_texture().get_image()
	
	# 恢复原始设置
	viewport.use_hdr_2d = original_hdr
	viewport.msaa_2d = original_msaa
	
	return image

# 根据平台获取截图保存路径
func _get_screenshot_save_path(filename: String) -> String:
	var platform = OS.get_name()
	
	match platform:
		"Windows":
			# Windows平台保存到桌面
			var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
			if desktop_path != "":
				return desktop_path + "/" + filename
			else:
				# 如果获取桌面路径失败，使用用户文档目录
				var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
				return documents_path + "/萌芽农场截图/" + filename
		
		"Android":
			# Android平台保存到Pictures目录
			var pictures_path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
			if pictures_path != "":
				return pictures_path + "/萌芽农场/" + filename
			else:
				# 如果获取Pictures目录失败，使用Downloads目录
				var downloads_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
				return downloads_path + "/萌芽农场截图/" + filename
		
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			# Linux/BSD平台优先保存到Pictures，其次是桌面
			var pictures_path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
			if pictures_path != "":
				return pictures_path + "/萌芽农场/" + filename
			else:
				var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
				if desktop_path != "":
					return desktop_path + "/" + filename
				else:
					# 最后选择用户主目录
					return OS.get_environment("HOME") + "/萌芽农场截图/" + filename
		
		"macOS":
			# macOS平台优先保存到桌面
			var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
			if desktop_path != "":
				return desktop_path + "/" + filename
			else:
				# 如果获取桌面路径失败，使用Pictures目录
				var pictures_path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
				return pictures_path + "/萌芽农场/" + filename
		
		"iOS":
			# iOS平台保存到Documents目录
			var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			return documents_path + "/萌芽农场截图/" + filename
		
		_:
			# 其他平台默认保存到用户目录
			var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			if documents_path != "":
				return documents_path + "/萌芽农场截图/" + filename
			else:
				# 最后使用game的用户数据目录
				return OS.get_user_data_dir() + "/screenshots/" + filename 
#====================================一键截图处理=========================================



#====================================在线礼包处理=========================================
#在线礼包，在线时间越久，越丰富，默认 1分钟 10分钟 30分钟 1小时 3小时 5小时 每天刷新
func _on_online_gift_button_pressed() -> void:
	# 每次打开面板时都请求最新的在线数据
	if online_gift_panel and online_gift_panel.has_method("show_panel_and_request_data"):
		online_gift_panel.show_panel_and_request_data()
	else:
		online_gift_panel.show()
		online_gift_panel.move_to_front()

# 处理在线礼包数据响应
func _handle_online_gift_data_response(data: Dictionary):
	if online_gift_panel and online_gift_panel.has_method("handle_online_gift_data_response"):
		online_gift_panel.handle_online_gift_data_response(data)

# 处理领取在线礼包响应
func _handle_claim_online_gift_response(data: Dictionary):
	var success = data.get("success", false)
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		if updated_data.has("money"):
			money = updated_data["money"]
		if updated_data.has("experience"):
			experience = updated_data["experience"]
		if updated_data.has("level"):
			level = updated_data["level"]
		if updated_data.has("player_bag"):
			player_bag = updated_data["player_bag"]
			# 修复背包数据兼容性问题
			_fix_player_bag_data()
		
		# 更新UI
		_update_ui()
		player_bag_panel.update_player_bag_ui()
	
	# 将响应传递给在线礼包面板处理UI更新
	if online_gift_panel and online_gift_panel.has_method("handle_claim_online_gift_response"):
		online_gift_panel.handle_claim_online_gift_response(data)
#====================================在线礼包处理=========================================



#====================================账户设置处理=========================================
# 处理账户设置响应
func _handle_account_setting_response(data: Dictionary):
	# 如果是刷新玩家信息响应，需要同步更新主游戏的数据
	if data.get("type") == "refresh_player_info_response" and data.get("success", false):
		if data.has("account_info"):
			var account_info = data["account_info"]
			
			# 只更新账户相关信息，不影响农场和背包数据
			if account_info.has("user_password"):
				user_password = account_info["user_password"]
			if account_info.has("farm_name"):
				show_farm_name.text = "农场名称：" + account_info.get("farm_name", "")
			if account_info.has("player_name"):
				show_player_name.text = "玩家昵称：" + account_info.get("player_name", "")
			
			# 更新基本游戏状态显示
			if account_info.has("experience"):
				experience = account_info.get("experience", 0)
			if account_info.has("level"):
				level = account_info.get("level", 1)
			if account_info.has("money"):
				money = account_info.get("money", 0)
			
			# 同步更新login_data和data中的账户信息
			if login_data.size() > 0:
				login_data["user_password"] = account_info.get("user_password", "")
				login_data["player_name"] = account_info.get("player_name", "")
				login_data["farm_name"] = account_info.get("farm_name", "")
				login_data["个人简介"] = account_info.get("个人简介", "")
			
			if data.size() > 0:
				data["user_password"] = account_info.get("user_password", "")
				data["player_name"] = account_info.get("player_name", "")
				data["farm_name"] = account_info.get("farm_name", "")
				data["个人简介"] = account_info.get("个人简介", "")
			
			# 更新UI显示
			_update_ui()
	
	# 将响应传递给账户设置面板
	if account_setting_panel and account_setting_panel.has_method("handle_account_response"):
		account_setting_panel.handle_account_response(data)

# 显示消息提示
func show_message(message: String, color: Color):
	# 使用Toast显示消息
	Toast.show(message, color)

#打开账户设置面板
func _on_account_setting_button_pressed() -> void:
	account_setting_panel.show()
	GlobalVariables.isZoomDisabled = true
	account_setting_panel._refresh_player_info()
	pass 
#====================================账户设置处理=========================================



#===============================================道具使用处理===============================================
# 在地块上使用道具
func _use_item_on_lot(lot_index: int, item_name: String):
	Toast.show("正在使用道具: " + item_name, Color.CYAN, 2.0, 1.0)
	
	# 检查地块索引是否有效
	if lot_index < 0 or lot_index >= farm_lots.size():
		Toast.show("无效的地块索引", Color.RED, 2.0, 1.0)
		return
	
	# 检查是否处于访问模式
	if is_visiting_mode:
		Toast.show("访问模式下无法使用道具", Color.ORANGE, 2.0, 1.0)
		return
	
	var lot = farm_lots[lot_index]
	
	# 根据道具类型执行不同的逻辑
	match item_name:
		"农家肥", "金坷垃", "生长素":
			print("调试：识别为施肥类道具")
			_use_fertilizer_item(lot_index, item_name, lot)
		"水壶", "水桶":
			print("调试：识别为浇水类道具")
			_use_watering_item(lot_index, item_name, lot)
		"铲子":
			print("调试：识别为铲除类道具")
			_use_removal_item(lot_index, item_name, lot)
		"除草剂":
			print("调试：识别为铲除类道具")
			_use_weed_killer_item(lot_index, item_name, lot)
		"精准采集锄", "时运锄":
			print("调试：识别为收获类道具")
			_use_harvest_item(lot_index, item_name, lot)
		_:
			print("错误：未识别的道具类型: ", item_name)
			Toast.show("该道具暂未实现使用功能: " + item_name, Color.YELLOW, 2.0, 1.0)

# 使用施肥类道具
func _use_fertilizer_item(lot_index: int, item_name: String, lot: Dictionary):
	
	# 检查地块是否已开垦且已种植
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法施肥", Color.ORANGE, 2.0, 1.0)
		return
	
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法施肥", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已死亡
	if lot.get("is_dead", false):
		Toast.show("作物已死亡，无法施肥", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已成熟
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	print("调试：作物生长时间: ", grow_time, "/", max_grow_time)
	if grow_time >= max_grow_time:
		Toast.show("作物已成熟，无需施肥", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查是否已经施过肥
	if lot.get("已施肥", false):
		Toast.show("此作物已经施过肥了", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查玩家是否有这个道具
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	# 发送使用道具请求到服务器
	var target_username = ""
	if is_visiting_mode:
		target_username = visited_player_data.get("user_name", "")

	
	if network_manager and network_manager.has_method("sendUseItem"):
		if network_manager.sendUseItem(lot_index, item_name, "fertilize", target_username):
			# 取消道具选择状态
			_clear_item_selection()
			var action_text = "帮助施肥" if is_visiting_mode else "施肥"
			Toast.show("正在使用 " + item_name + " " + action_text + "...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 使用浇水类道具
func _use_watering_item(lot_index: int, item_name: String, lot: Dictionary):
	# 检查地块是否已开垦且已种植
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法浇水", Color.ORANGE, 2.0, 1.0)
		return
	
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法浇水", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已死亡
	if lot.get("is_dead", false):
		Toast.show("作物已死亡，无法浇水", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已成熟
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	if grow_time >= max_grow_time:
		Toast.show("作物已成熟，无需浇水", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查玩家是否有这个道具
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	# 发送使用道具请求到服务器
	var target_username = ""
	if is_visiting_mode:
		target_username = visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.has_method("sendUseItem"):
		if network_manager.sendUseItem(lot_index, item_name, "water", target_username):
			# 取消道具选择状态
			_clear_item_selection()
			var action_text = "帮助浇水" if is_visiting_mode else "浇水"
			Toast.show("正在使用 " + item_name + " " + action_text + "...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 检查玩家是否拥有指定道具
func _has_item_in_bag(item_name: String) -> bool:
	for item in item_bag:
		if item.get("name", "") == item_name and item.get("count", 0) > 0:
			return true
	return false

# 使用铲除类道具（铲子）
func _use_removal_item(lot_index: int, item_name: String, lot: Dictionary):
	# 检查地块是否已开垦
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法使用铲子", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查地块是否有作物
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法铲除", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查玩家是否有这个道具
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	# 发送使用道具请求到服务器
	var target_username = ""
	if is_visiting_mode:
		target_username = visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.has_method("sendUseItem"):
		if network_manager.sendUseItem(lot_index, item_name, "remove", target_username):
			# 取消道具选择状态
			_clear_item_selection()
			var action_text = "帮助铲除" if is_visiting_mode else "铲除"
			Toast.show("正在使用 " + item_name + " " + action_text + "作物...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 使用除草剂
func _use_weed_killer_item(lot_index: int, item_name: String, lot: Dictionary):
	# 检查地块是否已开垦
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法使用除草剂", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查地块是否有作物
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法除草", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查是否为杂草
	var crop_type = lot.get("crop_type", "")
	var is_weed = false
	if can_planted_crop.has(crop_type):
		is_weed = can_planted_crop[crop_type].get("是否杂草", false)
	
	if not is_weed:
		Toast.show("除草剂只能用于清除杂草，此作物不是杂草", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查玩家是否有这个道具
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	# 发送使用道具请求到服务器
	var target_username = ""
	if is_visiting_mode:
		target_username = visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.has_method("sendUseItem"):
		if network_manager.sendUseItem(lot_index, item_name, "weed_killer", target_username):
			# 取消道具选择状态
			_clear_item_selection()
			var action_text = "帮助除草" if is_visiting_mode else "除草"
			Toast.show("正在使用 " + item_name + " " + action_text + "...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 使用采集道具（精准采集锄、时运锄）
func _use_harvest_item(lot_index: int, item_name: String, lot: Dictionary):
	# 检查地块是否已开垦
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法使用采集道具", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查地块是否有作物
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法收获", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已成熟
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	if grow_time < max_grow_time:
		Toast.show("作物还未成熟，无法使用采集道具", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查作物是否已死亡
	if lot.get("is_dead", false):
		Toast.show("作物已死亡，无法收获", Color.ORANGE, 2.0, 1.0)
		return
	
	# 检查玩家是否有这个道具
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	# 发送使用道具请求到服务器
	var target_username = ""
	if is_visiting_mode:
		target_username = visited_player_data.get("user_name", "")
	
	if network_manager and network_manager.has_method("sendUseItem"):
		if network_manager.sendUseItem(lot_index, item_name, "harvest", target_username):
			# 取消道具选择状态
			_clear_item_selection()
			var action_text = "帮助收获" if is_visiting_mode else "收获"
			Toast.show("正在使用 " + item_name + " " + action_text + "作物...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 清除道具选择状态
func _clear_item_selection():
	selected_item_name = ""
	is_item_selected = false
	
	# 通知道具背包面板取消选择
	if item_bag_panel and item_bag_panel.has_method("_deselect_item"):
		item_bag_panel._deselect_item()
#===============================================道具使用处理===============================================

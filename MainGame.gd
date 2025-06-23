extends Node

# 变量定义
@onready var grid_container : GridContainer = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item : Button = $CopyNodes/CropItem


@onready var show_money : Label =   $UI/GUI/GameInfoHBox1/money				# 显示当前剩余的钱
@onready var show_experience : Label = $UI/GUI/GameInfoHBox1/experience  	# 显示当前玩家的经验
@onready var show_level : Label =   $UI/GUI/GameInfoHBox1/level				# 显示当前玩家的等级
@onready var show_tip : Label =  $UI/GUI/GameInfoHBox1/tip					# 显示小提示
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
@onready var player_bag_button: Button = $UI/GUI/FarmVBox/PlayerBagButton			#打开玩家背包
@onready var add_new_ground_button: Button = $UI/GUI/FarmVBox/AddNewGroundButton		#购买新地块
@onready var open_store_button: Button = $UI/GUI/FarmVBox/OpenStoreButton				#打开种子商店

#其他一些按钮（暂未分类）
@onready var setting_button: Button = $UI/GUI/OtherVBox/SettingButton				#打开设置面板	
@onready var lucky_draw_button: Button = $UI/GUI/OtherVBox/LuckyDrawButton				#幸运抽奖
@onready var daily_check_in_button: Button = $UI/GUI/OtherVBox/DailyCheckInButton		#每日签到
@onready var player_ranking_button: Button = $UI/GUI/OtherVBox/PlayerRankingButton		#打开玩家排行榜
@onready var scare_crow_button: Button = $UI/GUI/OtherVBox/ScareCrowButton	#打开稻草人面板按钮
@onready var my_pet_button: Button = $UI/GUI/OtherVBox/MyPetButton		#打开宠物面板按钮
@onready var return_main_menu_button: Button = $UI/GUI/OtherVBox/ReturnMainMenuButton	#返回主菜单按钮
@onready var new_player_gift_button: Button = $UI/GUI/OtherVBox/NewPlayerGiftButton	#领取新手大礼包按钮  


@onready var crop_grid_container : GridContainer = $UI/CropStorePanel/ScrollContainer/Crop_Grid #种子商店格子
@onready var player_bag_grid_container : GridContainer = $UI/PlayerBagPanel/ScrollContainer/Bag_Grid #玩家背包格子

#作物品质按钮
@onready var green_bar : Button = $CopyNodes/GreenCrop				#普通
@onready var white_blue_bar : Button = $CopyNodes/WhiteBlueCrop		#稀有
@onready var orange_bar : Button = $CopyNodes/OrangeCrop			#优良
@onready var pink_bar : Button = $CopyNodes/PinkCrop				#史诗
@onready var black_blue_bar : Button = $CopyNodes/BlackBlueCrop		#传奇
@onready var red_bar : Button = $CopyNodes/RedCrop					#神圣

#各种面板
@onready var land_panel : Panel = $UI/LandPanel									#地块面板
@onready var login_panel : PanelContainer = $UI/LoginPanel						#登录注册面板
@onready var crop_store_panel : Panel = $UI/CropStorePanel						#种子商店面板
@onready var player_bag_panel : Panel = $UI/PlayerBagPanel						#玩家背包面板
@onready var network_manager : Panel = $UI/TCPNetworkManager					#网络管理器
@onready var player_ranking_panel : Panel = $UI/PlayerRankingPanel				#玩家排行榜面板
@onready var daily_check_in_panel: DailyCheckInPanel = $UI/DailyCheckInPanel	#每日签到面板
@onready var lucky_draw_panel: LuckyDrawPanel = $UI/LuckyDrawPanel				#幸运抽签面板
@onready var one_click_plant_panel: Panel = $UI/OneClickPlantPanel				#一键种植面板

@onready var game_info_h_box_1: HBoxContainer = $UI/GUI/GameInfoHBox1
@onready var game_info_h_box_2: HBoxContainer = $UI/GUI/GameInfoHBox2
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
# 使用 _process 计时器实现作物生长机制
var update_timer: float = 0.0
var update_interval: float = 1.0  
var start_game : bool = false
# 玩家背包数据
var player_bag : Array = []  
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

# FPS显示相关变量
var fps_timer: float = 0.0          # FPS更新计时器
var fps_update_interval: float = 0.5  # FPS更新间隔
var frame_count: int = 0            # 帧数计数器
var current_fps: float = 0.0        # 当前FPS值

var client_version :String = GlobalVariables.client_version #记录客户端版本



# 准备阶段
func _ready():
	#未登录时隐藏所有UI
	game_info_h_box_1.hide()
	game_info_h_box_2.hide()
	farm_v_box.hide()
	visit_v_box.hide()
	other_v_box.hide()
	
	# 隐藏面板
	crop_store_panel.hide()
	player_bag_panel.hide()
	lucky_draw_panel.hide()
	daily_check_in_panel.hide()
	player_ranking_panel.hide()
	one_click_plant_panel.hide()
	accept_dialog.hide()
	
	print("萌芽农场客户端 v" + client_version + " 启动")

	
	_update_ui()
	_create_farm_buttons() # 创建地块按钮
	_update_farm_lots_state() # 初始更新地块状态
	
	# 预加载默认作物图片
	_preload_common_crop_textures()
	
	# 先尝试加载本地数据进行快速初始化
	_load_local_crop_data()
	
	# 初始化玩家背包UI
	player_bag_panel.init_player_bag()
	# 初始化商店
	crop_store_panel.init_store()
	
	# 连接AcceptDialog的确认信号
	accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)
	
	# 启动在线人数更新定时器
	_start_online_players_timer()
	
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
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0  # 重置计时器
		
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
				farm_v_box.show()
				visit_v_box.hide()
				other_v_box.show()
				pass
			pass






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

# 处理登录成功
func handle_login_success(player_data: Dictionary):
	"""处理登录成功后的逻辑"""
	print("登录成功，正在初始化游戏数据...")
	
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
		
		Toast.show("已返回自己的农场", Color.GREEN)
		print("成功返回自己的农场")
	else:
		Toast.show("返回农场失败：" + message, Color.RED)
		print("返回农场失败：", message)


#创建作物按钮
func _create_crop_button(crop_name: String, crop_quality: String) -> Button:
	# 根据品质选择相应的进度条
	var button = null
	match crop_quality:
		"普通":
			button = green_bar.duplicate()
		"优良":
			button = orange_bar.duplicate()
		"稀有":
			button = white_blue_bar.duplicate()
		"史诗":
			button = pink_bar.duplicate()
		"传奇":
			button = black_blue_bar.duplicate()
		_:  # 默认情况
			button = green_bar.duplicate()

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
					
					# 添加作物详细信息到tooltip
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
				
				label.modulate = Color.GREEN#绿色
				label.text = land_text
				progressbar.hide()
				# 空地不显示tooltip
				button.tooltip_text = ""
		else:
			# 未开垦的地块
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
	# 检查是否处于一键种植的地块选择模式
	if one_click_plant_panel and one_click_plant_panel.has_method("on_lot_selected"):
		if one_click_plant_panel.on_lot_selected(index):
			# 一键种植面板已处理了这次点击，直接返回
			return
	
	# 正常模式下，打开土地面板
	land_panel.show_panel()
	land_panel.selected_lot_index = index
	selected_lot_index = index
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

# 加载作物图片序列帧
func _load_crop_textures(crop_name: String) -> Array:
	"""
	加载指定作物的所有序列帧图片
	返回图片数组，如果作物不存在则返回默认图片
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
			print("成功加载作物 ", crop_name, " 的 ", textures.size(), " 帧图片")
		else:
			print("作物 ", crop_name, " 文件夹存在但没有找到有效图片，使用默认图片")
			textures = _load_default_textures()
	else:
		print("作物 ", crop_name, " 的文件夹不存在，使用默认图片")
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
	
	print("加载了 ", textures.size(), " 个默认作物图片")
	return textures

# 根据生长进度获取对应的作物图片
func _get_crop_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
	"""
	根据作物名称和生长进度获取对应的图片
	progress: 0.0 到 1.0 的生长进度
	"""
	var textures = _load_crop_textures(crop_name)
	
	if textures.size() == 0:
		return null
	
	if textures.size() == 1:
		return textures[0]
	
	# 根据进度计算应该显示的帧
	var frame_index = int(progress * (textures.size() - 1))
	frame_index = clamp(frame_index, 0, textures.size() - 1)
	
	return textures[frame_index]

# 更新地块的作物图片
func _update_lot_crop_sprite(button: Button, lot_data: Dictionary):
	"""
	更新单个地块按钮的作物图片
	"""
	var crop_sprite = button.get_node("crop_sprite")
	
	if not lot_data["is_diged"]:
		# 未开垦的地块，隐藏作物图片
		crop_sprite.visible = false
		return
	
	if not lot_data["is_planted"] or lot_data["crop_type"] == "":
		# 空地，隐藏作物图片
		crop_sprite.visible = false
		return
	
	# 有作物的地块
	crop_sprite.visible = true
	
	var crop_name = lot_data["crop_type"]
	var grow_time = float(lot_data["grow_time"])
	var max_grow_time = float(lot_data["max_grow_time"])
	var is_dead = lot_data.get("is_dead", false)
	
	# 计算生长进度
	var progress = 0.0
	if max_grow_time > 0:
		progress = grow_time / max_grow_time
		progress = clamp(progress, 0.0, 1.0)
	
	# 如果作物死亡，显示最后一帧并调整颜色
	if is_dead:
		var texture = _get_crop_texture_by_progress(crop_name, 1.0)  # 使用最后一帧
		if texture:
			crop_sprite.texture = texture
			crop_sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)  # 变暗表示死亡
		else:
			crop_sprite.visible = false
	else:
		# 正常作物，恢复正常颜色
		crop_sprite.modulate = Color.WHITE
		
		# 获取对应的图片
		var texture = _get_crop_texture_by_progress(crop_name, progress)
		
		if texture:
			crop_sprite.texture = texture
		else:
			print("无法获取作物 ", crop_name, " 的图片")
			crop_sprite.visible = false

# 预加载常用作物图片
func _preload_common_crop_textures():
	"""
	预加载一些常用的作物图片，提高游戏性能
	"""
	print("开始预加载作物图片...")
	
	# 首先加载默认图片
	_load_default_textures()
	
	# 预加载一些常见作物（可以根据实际情况调整）
	var common_crops = [
		"草莓","大白菜","大豆", "稻谷", "冬虫夏草", "番茄", "富贵竹", "甘蔗"
		, "哈密瓜", "胡萝卜", "花椰菜", "黄瓜", "金橘", "橘子树", "蕨菜", "辣椒"
		, "蓝莓", "龙果", "芦荟", "芦笋", "南瓜", "甘蔗", "苹果树", "葡萄"
		]
	
	for crop_name in common_crops:
		_load_crop_textures(crop_name)
	
	print("作物图片预加载完成，已缓存 ", crop_textures_cache.size(), " 种作物")

# 清理作物图片缓存
func _clear_crop_textures_cache():
	"""
	清理作物图片缓存，释放内存
	"""
	crop_textures_cache.clear()
	crop_frame_counts.clear()
	print("作物图片缓存已清理")

# 获取作物图片缓存信息
func _get_crop_cache_info() -> String:
	"""
	获取当前作物图片缓存的信息
	"""
	var info = "作物图片缓存信息:\n"
	for crop_name in crop_textures_cache.keys():
		var frame_count = crop_frame_counts.get(crop_name, 0)
		info += "- " + crop_name + ": " + str(frame_count) + " 帧\n"
	return info

# 调试：打印作物图片缓存信息
func _debug_print_crop_cache():
	"""
	调试用：打印当前作物图片缓存信息
	"""
	print(_get_crop_cache_info())

# 调试：强制刷新所有地块的作物图片
func _debug_refresh_all_crop_sprites():
	"""
	调试用：强制刷新所有地块的作物图片
	"""
	print("强制刷新所有地块的作物图片...")
	for i in range(len(farm_lots)):
		if i >= grid_container.get_child_count():
			break
		var button = grid_container.get_child(i)
		var lot = farm_lots[i]
		_update_lot_crop_sprite(button, lot)
	print("作物图片刷新完成")

#打开种子商店面板
func _on_open_store_button_pressed():
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
	player_ranking_panel.show()
	player_ranking_panel.request_player_rankings()
	pass 
#访客模式下返回我的农场
func _on_return_my_farm_button_pressed() -> void:
	# 如果当前处于访问模式，返回自己的农场
	if is_visiting_mode:
		return_to_my_farm()
	else:
		# 如果不在访问模式，这个按钮可能用于其他功能或者不做任何操作
		print("当前已在自己的农场")

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

#打开设置面板 暂时没想到可以设置什么
func _on_setting_button_pressed() -> void:
	pass

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

#打开我的宠物系统，这个比较复杂以后再实现
func _on_my_pet_button_pressed() -> void:
	pass 

#断开连接并返回主菜单界面
func _on_return_main_menu_button_pressed() -> void:
	# 显示确认弹窗
	accept_dialog.set_dialog_title("返回主菜单确认")
	accept_dialog.set_dialog_content("确定要断开连接并返回主菜单吗？\n\n注意：未保存的进度可能会丢失！")
	accept_dialog.popup_centered()
	
	# 标记当前操作为返回主菜单
	accept_dialog.set_meta("action_type", "return_main_menu")

# 处理AcceptDialog的确认信号
func _on_accept_dialog_confirmed():
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

# 执行返回主菜单逻辑
func _execute_return_main_menu():
	# 断开与服务器的连接
	if network_manager and network_manager.is_connected_to_server():
		network_manager.client.disconnect_from_server()
		print("已断开与服务器的连接")
	
	# 直接切换到主菜单场景
	get_tree().change_scene_to_file('res://GUI/MainMenuPanel.tscn')

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
		show_onlineplayer.text = "在线：" + str(count) + " 人"
		show_onlineplayer.modulate = Color.GREEN
	else:
		show_onlineplayer.text = "离线"
		show_onlineplayer.modulate = Color.RED

# 显示玩家背包面板
func _on_player_bag_button_pressed() -> void:
	player_bag_panel.show()
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

extends Node

# 变量定义
@onready var grid_container : GridContainer = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item : Button = $CopyNodes/CropItem


#显示信息栏
@onready var show_money : Label =   $UI/GUI/GameInfoHBox1/money				# 显示当前剩余的钱
@onready var show_experience : Label = $UI/GUI/GameInfoHBox1/experience  	# 显示当前玩家的经验
@onready var show_level : Label =   $UI/GUI/GameInfoHBox1/level				# 显示当前玩家的等级
@onready var show_tip : Label =  $UI/GUI/GameInfoHBox3/tip					# 显示小提示
@onready var show_like: Label = $UI/GUI/GameInfoHBox1/like					# 显示别人给自己点赞的总赞数
@onready var show_onlineplayer: Label = $UI/GUI/GameInfoHBox3/onlineplayer	# 显示服务器在线人数
@onready var show_player_name : Label =  $UI/GUI/GameInfoHBox2/player_name	# 显示玩家昵称
@onready var show_farm_name : Label = $UI/GUI/GameInfoHBox2/farm_name		# 显示农场名称
@onready var show_status_label : Label = $UI/GUI/GameInfoHBox2/StatusLabel	# 显示与服务器连接状态
@onready var show_fps: Label = $UI/GUI/GameInfoHBox2/FPS					# 显示游戏FPS	
@onready var show_hunger_value :Label = $UI/GUI/GameInfoHBox1/hunger_value	# 显示玩家体力值
@onready var global_server_broadcast: Label = $UI/GUI/GameInfoHBox3/GlobalServerBroadcast # 显示全服大喇叭的最新消息，走马灯式滚动显示
@onready var watch_broadcast_button: Button = $UI/GUI/GameInfoHBox3/WatchBroadcast # 查看大喇叭按钮

@onready var network_status_label :Label = get_node("/root/main/UI/BigPanel/TCPNetworkManagerPanel/StatusLabel")


#访问模式按钮 
@onready var return_my_farm_button: Button = $UI/GUI/VisitVBox/ReturnMyFarmButton	#返回我的农场
@onready var like_button: Button = $UI/GUI/VisitVBox/LikeButton						#给别人点赞
@onready var battle_button: Button = $UI/GUI/VisitVBox/BattleButton						#发起对战

#和农场操作相关的按钮
@onready var one_click_harvestbutton: Button = $UI/GUI/FarmVBox/OneClickHarvestButton	#一键收获
@onready var one_click_plant_button: Button = $UI/GUI/FarmVBox/OneClickPlantButton	#一键种植面板
@onready var player_bag_button: Button = $UI/GUI/FarmVBox/SeedWarehouseButton			#打开玩家背包
@onready var add_new_ground_button: Button = $UI/GUI/FarmVBox/AddNewGroundButton		#购买新地块
@onready var open_store_button: Button = $UI/GUI/FarmVBox/SeedStoreButton				#打开种子商店

#其他一些按钮（暂未分类）
@onready var setting_button: Button = $UI/GUI/OtherVBox/SettingButton					#打开设置面板	
@onready var lucky_draw_button: Button = $UI/GUI/OtherVBox/LuckyDrawButton				#幸运抽奖
@onready var daily_check_in_button: Button = $UI/GUI/OtherVBox/DailyCheckInButton		#每日签到
@onready var player_ranking_button: Button = $UI/GUI/OtherVBox/PlayerRankingButton		#打开玩家排行榜
@onready var scare_crow_button: Button = $UI/GUI/OtherVBox/ScareCrowButton				#打开稻草人面板按钮
@onready var return_main_menu_button: Button = $UI/GUI/OtherVBox/ReturnMainMenuButton	#返回主菜单按钮
@onready var new_player_gift_button: Button = $UI/GUI/OtherVBox/NewPlayerGiftButton		#领取新手大礼包按钮
@onready var account_setting_button: Button = $UI/GUI/OtherVBox/AccountSettingButton	#账户设置按钮  


@onready var crop_grid_container : GridContainer = $UI/BigPanel/CropStorePanel/ScrollContainer/Crop_Grid #种子商店格子
@onready var player_bag_grid_container : GridContainer = $UI/BigPanel/PlayerBagPanel/ScrollContainer/Bag_Grid #玩家背包格子

#作物品质按钮
@onready var item_button :Button = $CopyNodes/item_button			

#各种面板
#大面板
@onready var lucky_draw_panel: LuckyDrawPanel = $UI/BigPanel/LuckyDrawPanel  #幸运抽奖面板
@onready var daily_check_in_panel: DailyCheckInPanel = $UI/BigPanel/DailyCheckInPanel  #每日签到面板
@onready var tcp_network_manager_panel: Panel = $UI/BigPanel/TCPNetworkManagerPanel  #网络管理器面板
@onready var item_store_panel: Panel = $UI/BigPanel/ItemStorePanel  #道具商店面板
@onready var item_bag_panel: Panel = $UI/BigPanel/ItemBagPanel  #道具背包面板
@onready var player_bag_panel: Panel = $UI/BigPanel/PlayerBagPanel  #种子仓库面板
@onready var crop_warehouse_panel: Panel = $UI/BigPanel/CropWarehousePanel  #作物仓库面板
@onready var crop_store_panel: Panel = $UI/BigPanel/CropStorePanel  #种子商店面板
@onready var player_ranking_panel: Panel = $UI/BigPanel/PlayerRankingPanel  #玩家排行榜面板
@onready var login_panel: PanelContainer = $UI/BigPanel/LoginPanel  #登录面板
@onready var pet_bag_panel: Panel = $UI/BigPanel/PetBagPanel  #宠物背包面板
@onready var pet_store_panel: Panel = $UI/BigPanel/PetStorePanel  #宠物商店面板
@onready var pet_fight_panel: Panel = $UI/BigPanel/PetFightPanel  #宠物战斗面板
@onready var pet_inform_panel: Panel = $UI/SmallPanel/PetInformPanel #宠物信息面板
@onready var player_store_panel: Panel = $UI/BigPanel/PlayerStorePanel #玩家小卖部面板
@onready var game_setting_panel: Panel = $UI/BigPanel/GameSettingPanel #游戏设置面板



#小面板
@onready var land_panel: Panel = $UI/SmallPanel/LandPanel  #地块面板
@onready var load_progress_panel: Panel = $UI/SmallPanel/LoadProgressPanel  #加载进度面板
@onready var account_setting_panel: Panel = $UI/SmallPanel/AccountSettingPanel  #账户设置面板
@onready var one_click_plant_panel: Panel = $UI/SmallPanel/OneClickPlantPanel  #一键种植地块面板
@onready var online_gift_panel: Panel = $UI/SmallPanel/OnlineGiftPanel  #在线礼包面板
@onready var debug_panel: Panel = $UI/SmallPanel/DebugPanel  #调试面板
@onready var global_server_broadcast_panel: Panel = $UI/SmallPanel/GlobalServerBroadcastPanel  #全服大喇叭面板
@onready var scare_crow_panel: Panel = $UI/SmallPanel/ScareCrowPanel #农场稻草人设置面板 
@onready var wisdom_tree_panel: Panel = $UI/SmallPanel/WisdomTreePanel #智慧树设置面板


#稻草人系统
@onready var scare_crow: Button = $Decoration/ScareCrow #打开农场稻草人设置面板
@onready var scare_crow_image: Sprite2D = $Decoration/ScareCrow/ScareCrowImage #稻草人显示的图片 
@onready var scare_crow_name: RichTextLabel = $Decoration/ScareCrow/ScareCrowName #稻草人显示的昵称
@onready var scare_crowtalks: RichTextLabel = $Decoration/ScareCrow/BackgroundPanel/ScareCrowtalks #稻草人显示的话 

#智慧树系统
@onready var wisdom_tree_image: Sprite2D = $Decoration/WisdomTree/WisdomTreeImage #智慧树图片从大小从0.5变到1.6
@onready var tree_status: Label = $Decoration/WisdomTree/TreeStatus #智慧树状态 只显示 等级和高度
@onready var anonymous_talk: RichTextLabel = $Decoration/WisdomTree/BackgroundPanel/AnonymousTalk #给智慧树听音乐100%会刷新 施肥浇水

#天气系统
@onready var weather_system: Node2D = $WeatherSystem #天气系统节点


#各种弹窗
@onready var accept_dialog: AcceptDialog = $UI/DiaLog/AcceptDialog
@onready var batch_buy_popup: PanelContainer = $UI/DiaLog/BatchBuyPopup


@onready var load_progress_bar: ProgressBar = $UI/SmallPanel/LoadProgressPanel/LoadProgressBar	#显示加载进度进度条

#用于一键隐藏或者显示
@onready var game_info_h_box_1: HBoxContainer = $UI/GUI/GameInfoHBox1
@onready var game_info_h_box_2: HBoxContainer = $UI/GUI/GameInfoHBox2
@onready var game_info_h_box_3: HBoxContainer = $UI/GUI/GameInfoHBox3
@onready var farm_v_box: VBoxContainer = $UI/GUI/FarmVBox
@onready var visit_v_box: VBoxContainer = $UI/GUI/VisitVBox
@onready var other_v_box: VBoxContainer = $UI/GUI/OtherVBox

@onready var pet_battle_panel: PetBattlePanel = $UI/BigPanel/PetBattlePanel #新的宠物对战场景


@onready var pet_patrol_points: Node = $PetPatrolPoints
@onready var pos_1: Marker2D = $PetPatrolPoints/Pos1 #生成点1
@onready var pos_2: Marker2D = $PetPatrolPoints/Pos2#生成点2
@onready var pos_3: Marker2D = $PetPatrolPoints/Pos3#生成点3
@onready var pos_4: Marker2D = $PetPatrolPoints/Pos4#生成点4



#玩家基本信息
var money: int = 500  # 默认每个人初始为100元
var experience: float = 0.0  # 初始每个玩家的经验为0
#var grow_speed: float = 1  # 作物生长速度
var level: int = 1  # 初始玩家等级为1
var dig_money : int = 1000 #开垦费用
var stamina: int = 20  # 玩家体力值，默认20点

var user_name : String = ""
var user_password : String = ""
var login_data : Dictionary = {}
#var data : Dictionary = {}

var start_game : bool = false
var remaining_likes : int = 10  # 今日剩余点赞次数
# 种子背包数据
var player_bag : Array = []  
# 作物仓库数据
var crop_warehouse : Array = []
# 道具背包数据
var item_bag : Array = []
# 宠物背包数据
var pet_bag : Array = []
# 巡逻宠物数据
var patrol_pets : Array = []
# 出战宠物数据
var battle_pets : Array = []


#农作物种类JSON
var can_planted_crop : Dictionary = {}
#道具配置数据
var item_config_data : Dictionary = {}
# 宠物配置数据
var pet_config : Dictionary = {}
# 新手大礼包领取状态
var new_player_gift_claimed : bool = false


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

#五秒计时器
var five_timer = 0.0
var five_interval = 5.0
#一秒计时器
var one_timer: float = 0.0
var one_interval: float = 1.0

# 稻草人话语切换相关
var scare_crow_talk_index: int = 0
var scare_crow_talk_timer: float = 0.0
var scare_crow_talk_interval: float = 5.0  # 每5秒切换一次
var scare_crow_talks_list: Array = []  

#=======================临时变量=======================
# 道具选择状态
var selected_item_name : String = ""
var is_item_selected : bool = false

# 当前被选择的地块索引
var selected_lot_index : int = -1  
var farm_lots : Array = []  # 用于保存每个地块的状态
var dig_index : int = 0
var climate_death_timer : int = 0
#=======================临时变量=======================



#=======================脚本基础方法=======================

func _ready():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0  # 0 表示解锁
	print("V-Sync disabled，max_fps =", Engine.max_fps)
	
	
	# 显示加载进度面板，隐藏其他所有UI
	load_progress_panel.show()
	load_progress_bar.value = 0
	
	# 初始化调试面板（默认隐藏）
	debug_panel.hide()
	
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
	global_server_broadcast_panel.hide()
	game_setting_panel.hide()
	accept_dialog.hide()
	

	
	_update_ui()
	_create_farm_buttons() # 创建地块按钮
	_update_farm_lots_state() # 初始更新地块状态
	
	# 先尝试加载本地数据进行快速初始化
	_load_local_crop_data()
	_load_local_item_config()
#==================================初始化比较重要的几个面板==================================
	# 初始化种子仓库UI
	player_bag_panel.init_player_bag()
	# 初始化作物仓库UI
	crop_warehouse_panel.init_crop_warehouse()
	# 初始化道具背包UI
	item_bag_panel.init_item_bag()
	# 初始化种子商店
	crop_store_panel.init_store()
	# 初始化道具商店UI
	item_store_panel.init_item_store()
#==================================初始化比较重要的几个面板==================================
	# 连接AcceptDialog的确认信号
	accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)
	
	# 连接宠物对战面板的battle_ended信号
	pet_battle_panel.battle_ended.connect(_on_pet_battle_ended)
	
	# 启动在线人数更新定时器
	_start_online_players_timer()
	
	
	# 预加载所有作物图片（带进度显示）
	await _preload_all_crop_textures()
	
	# 启动后稍等片刻尝试从服务器获取最新数据
	await get_tree().create_timer(0.5).timeout
	_try_load_from_server()
	
	# 初始化对战按钮显示状态
	_update_battle_button_visibility()


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
		
	
	# 稻草人话语切换计时器
	if scare_crow_talks_list.size() > 0 and scare_crow.visible:
		scare_crow_talk_timer += delta
		if scare_crow_talk_timer >= scare_crow_talk_interval:
			scare_crow_talk_timer = 0.0
			_update_scare_crow_talk()


func _input(event):
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		
		if key_code == KEY_F10:
			# 显示调试面板
			if debug_panel:
				debug_panel.visible = !debug_panel.visible
		elif key_code == KEY_F11:
			# 切换全屏模式
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif key_code == KEY_F12:
			# 截图
			print("截图功能暂未实现")

#=======================脚本基础方法=======================



#==========================玩家排行榜+访问模式处理============================
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
				"玩家账号": user_name,
				"玩家昵称": show_player_name.text.replace("玩家昵称：", ""),
				"农场名称": show_farm_name.text.replace("农场名称：", ""),
				"等级": level,
				"钱币": money,
				"经验值": experience,
				"stamina": stamina,
				"农场土地": farm_lots.duplicate(true),
				"种子仓库": player_bag.duplicate(true)
			}
		
		# 切换到访问模式
		is_visiting_mode = true
		visited_player_data = target_player_data
		
		# 控制对战按钮显示
		_update_battle_button_visibility()
		
		# 更新显示数据
		money = target_player_data.get("钱币", 0)
		experience = target_player_data.get("经验值", 0)
		level = target_player_data.get("等级", 1)
		stamina = target_player_data.get("体力值", 20)
		farm_lots = target_player_data.get("农场土地", [])
		player_bag = target_player_data.get("种子仓库", [])
		crop_warehouse = target_player_data.get("作物仓库", [])
		item_bag = target_player_data.get("道具背包", [])
		pet_bag = target_player_data.get("宠物背包", [])
		patrol_pets = target_player_data.get("巡逻宠物", [])
		
		# 更新UI显示
		show_player_name.text = "玩家昵称：" + target_player_data.get("玩家昵称", "未知")
		show_farm_name.text = "农场名称：" + target_player_data.get("农场名称", "未知农场")
		
		# 显示被访问玩家的点赞数
		var target_likes = target_player_data.get("点赞数", 0)
		show_like.text = "点赞数：" + str(int(target_likes))
		
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
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
		# 初始化巡逻宠物（访问模式）
		print("[访问模式] 准备初始化巡逻宠物，数据量: ", patrol_pets.size())
		for i in range(patrol_pets.size()):
			var pet_data = patrol_pets[i]
			print("[访问模式] 巡逻宠物", i, ": ", pet_data.get("pet_name", "未知"), " ID:", pet_data.get("pet_id", "无ID"))
		if has_method("init_patrol_pets"):
			init_patrol_pets()
		
		# 更新稻草人显示（访问模式）
		update_scare_crow_display()
		
		# 更新智慧树配置显示（访问模式）
		if target_player_data.has("智慧树配置") and target_player_data["智慧树配置"] != null:
			# 确保智慧树配置格式正确
			var target_wisdom_config = target_player_data["智慧树配置"]
			if target_wisdom_config is Dictionary:
				target_wisdom_config = _ensure_wisdom_tree_config_format(target_wisdom_config)
				
				# 更新智慧树显示
				_update_wisdom_tree_display(target_wisdom_config)
			else:
				print("智慧树配置不是Dictionary类型：", typeof(target_wisdom_config))
		else:
			print("目标玩家没有智慧树配置或配置为空")
		
		# 隐藏排行榜面板
		if player_ranking_panel:
			player_ranking_panel.hide()
		
		Toast.show("正在访问 " + target_player_data.get("玩家昵称", "未知") + " 的农场", Color.CYAN)
	else:
		Toast.show("访问失败：" + message, Color.RED)
		print("访问玩家失败：", message)

# 处理返回自己农场响应
func _handle_return_my_farm_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var player_data = data.get("player_data", {})
		
		# 隐藏对战按钮（返回自己农场时）
		battle_button.hide()
		
		# 恢复玩家数据
		money = player_data.get("钱币", 500)
		experience = player_data.get("经验值", 0)
		level = player_data.get("等级", 1)
		stamina = player_data.get("体力值", 20)
		farm_lots = player_data.get("农场土地", [])
		player_bag = player_data.get("种子仓库", [])
		crop_warehouse = player_data.get("作物仓库", [])
		item_bag = player_data.get("道具背包", [])
		pet_bag = player_data.get("宠物背包", [])
		patrol_pets = player_data.get("巡逻宠物", [])
		battle_pets = player_data.get("出战宠物", [])
		
		# 恢复UI显示
		show_player_name.text = "玩家昵称：" + player_data.get("玩家昵称", "未知")
		show_farm_name.text = "农场名称：" + player_data.get("农场名称", "我的农场")
		
		# 显示自己的点赞数
		var my_likes = player_data.get("点赞数", 0)
		show_like.text = "点赞数：" + str(int(my_likes))
		
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
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
		# 初始化巡逻宠物（返回自己农场）
		print("[返回农场] 准备初始化巡逻宠物，数据量: ", patrol_pets.size())
		for i in range(patrol_pets.size()):
			var pet_data = patrol_pets[i]
			print("[返回农场] 巡逻宠物", i, ": ", pet_data.get("pet_name", "未知"), " ID:", pet_data.get("pet_id", "无ID"))
		if has_method("init_patrol_pets"):
			init_patrol_pets()
		
		# 更新稻草人显示（返回自己农场）
		update_scare_crow_display()
		
		# 恢复智慧树显示（返回自己农场）
		if player_data.has("智慧树配置") and player_data["智慧树配置"] != null:
			var my_wisdom_config = player_data["智慧树配置"]
			if my_wisdom_config is Dictionary:
				my_wisdom_config = _ensure_wisdom_tree_config_format(my_wisdom_config)
				# 更新本地智慧树配置
				login_data["智慧树配置"] = my_wisdom_config
				# 恢复智慧树显示
				update_wisdom_tree_display()
		
		Toast.show("已返回自己的农场", Color.GREEN)
	else:
		Toast.show("返回农场失败：" + message, Color.RED)
		print("返回农场失败：", message)

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
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendReturnMyFarm"):
		var success = tcp_network_manager_panel.sendReturnMyFarm()
		if success:
			print("已发送返回自己农场的请求")
		else:
			Toast.show("网络未连接，无法返回农场", Color.RED)
			print("发送返回农场请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

#==========================玩家排行榜+访问模式处理============================




#===============================================这个函数也比较重要===============================================
# 处理地块点击事件
func _on_item_selected(index):
	# 检查是否处于一键种植的地块选择模式
	if one_click_plant_panel.on_lot_selected(index):
		return
	
	# 检查是否有道具被选择，如果有则使用道具
	if is_item_selected and selected_item_name != "":
		_use_item_on_lot(index, selected_item_name)
		return
	

	# 正常模式下，先设置地块索引，再打开土地面板
	land_panel.selected_lot_index = index
	selected_lot_index = index
	land_panel.show_panel()
	land_panel._update_button_texts()
#===============================================这个函数也比较重要===============================================



#========================================杂项未分类函数=======================================
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
		"小心偷菜被巡逻宠物发现"
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
		farm_lots = update_data["农场土地"]
	elif not is_visiting_update and not is_visiting_mode:
		# 正常模式下的更新，更新自己的农场数据
		farm_lots = update_data["农场土地"]
	else:
		# 状态不匹配，忽略更新
		print("忽略不匹配的作物更新，当前访问模式：", is_visiting_mode, "，更新类型：", is_visiting_update)
		return
	
	# 更新UI显示
	_update_farm_lots_state()

# 处理登录成功
func handle_login_success(player_data: Dictionary):
	
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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		tcp_network_manager_panel.sendGetOnlinePlayers()
		print("登录成功后请求在线人数更新")
	
	# 登录成功后请求宠物配置数据
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendGetPetConfig"):
		if tcp_network_manager_panel.sendGetPetConfig():
			print("登录成功后请求宠物配置数据")
		else:
			print("登录成功后请求宠物配置数据失败")
	
	# 其他登录成功后的初始化逻辑可以在这里添加
	start_game = true
	
	# 登录成功后初始化大喇叭显示
	_init_broadcast_display()
	
	# 初始化稻草人显示
	init_scare_crow_config()
	
	# 初始化智慧树显示
	update_wisdom_tree_display()
	
	# 初始化对战按钮显示状态
	_update_battle_button_visibility()
	
	# 立即请求服务器历史消息以刷新显示
	call_deferred("_request_server_history_for_refresh")

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

# 更新农场地块状态
func _update_farm_lots_state():
	var digged_count = 0
	var land_colors = {0: Color.WHITE, 1: Color(1.0, 1.0, 0.0), 2: Color(1.0, 0.41, 0.0), 3: Color(0.55, 0.29, 0.97), 4: Color(0.33, 0.4, 0.59)}
	var quality_colors = {"普通": Color.HONEYDEW, "优良": Color.DODGER_BLUE, "稀有": Color.HOT_PINK, "史诗": Color.YELLOW, "传奇": Color.ORANGE_RED}

	for i in range(len(farm_lots)):
		if i >= grid_container.get_child_count():
			break
			
		var lot = farm_lots[i]
		var button = grid_container.get_child(i)
		var label = button.get_node("crop_name")
		var ground_image = button.get_node("ground_sprite")
		var status_label = button.get_node("status_label")
		var progressbar = button.get_node("ProgressBar")

		_update_lot_crop_sprite(button, lot)
		ground_image.self_modulate = land_colors.get(int(lot.get("土地等级", 0)), Color.WHITE)

		if not lot["is_diged"]:
			label.show()
			label.modulate = Color.WEB_GRAY
			label.text = "[未开垦]"
			progressbar.hide()
			status_label.text = ""
			button.tooltip_text = ""
			
		elif not lot["is_planted"]:
			digged_count += 1
			label.show()
			label.modulate = Color.GREEN
			label.text = "[空地]"
			progressbar.hide()
			status_label.text = ""
			button.tooltip_text = ""
			
		elif lot["is_dead"]:
			digged_count += 1
			label.show()
			label.modulate = Color.NAVY_BLUE
			var crop_name = lot["crop_type"]
			var display_name = crop_name
			if can_planted_crop.has(crop_name):
				display_name = can_planted_crop[crop_name].get("作物名称", crop_name)
			label.text = "[" + display_name + "已死亡]"
			progressbar.hide()
			status_label.text = ""
			button.tooltip_text = ""
			
		else:
			digged_count += 1
			var crop_name = lot["crop_type"]
			var is_weed = can_planted_crop.has(crop_name) and can_planted_crop[crop_name].get("是否杂草", false)
			
			if is_weed:
				label.hide()
				progressbar.hide()
				status_label.text = ""
				button.tooltip_text = ""
			else:
				label.show()
				progressbar.show()
				
				if can_planted_crop.has(crop_name):
					var crop_quality = can_planted_crop[crop_name]["品质"]
					var display_name = can_planted_crop[crop_name].get("作物名称", crop_name)
					label.text = "[" + crop_quality + "-" + display_name + "]"
					label.modulate = quality_colors.get(crop_quality, Color.WHITE)
				else:
					label.text = "[" + crop_name + "]"
					label.modulate = Color.WHITE
				
				progressbar.max_value = int(lot["max_grow_time"])
				progressbar.value = int(lot["grow_time"])
				
				var status_indicators = []
				var current_time = Time.get_unix_time_from_system()
				var last_water_time = lot.get("浇水时间", 0)
				
				if current_time - last_water_time < 3600:
					status_indicators.append("已浇水")
				if lot.get("已施肥", false):
					status_indicators.append("已施肥")
				
				status_label.text = " ".join(status_indicators)
				
				if can_planted_crop.has(crop_name):
					var crop = can_planted_crop[crop_name]
					var display_name = crop.get("作物名称", crop_name)
					var grow_time = int(crop["生长时间"])
					var days = grow_time / 86400
					var hours = (grow_time % 86400) / 3600
					var minutes = (grow_time % 3600) / 60
					var seconds = grow_time % 60
					
					var time_str = ""
					if days > 0: time_str += str(days) + "天"
					if hours > 0: time_str += str(hours) + "小时"
					if minutes > 0: time_str += str(minutes) + "分钟"
					if seconds > 0: time_str += str(seconds) + "秒"
					if time_str == "": time_str = "0秒"
					
					button.tooltip_text = "作物: " + display_name + "\n品质: " + crop.get("品质", "未知") + "\n价格: " + str(crop["花费"]) + "元\n成熟时间: " + time_str + "\n收获收益: " + str(crop["收益"]) + "元\n需求等级: " + str(crop["等级"]) + "\n经验: " + str(crop["经验"]) + "点"
				else:
					button.tooltip_text = "作物: " + crop_name + "\n作物数据未找到"

	dig_money = digged_count * 1000

# 仅在加载游戏或特定情况下完全刷新地块 - 用于与服务器同步时
func _refresh_farm_lots():
	_create_farm_buttons()
	_update_farm_lots_state()

# 更新玩家信息显示
func _update_ui():
	show_money.text = "钱币数：" + str(money) + " 元"
	show_experience.text = "经验值：" + str(experience) + " 点"
	show_level.text = "等级：" + str(level) + " 级"
	show_hunger_value.text = "体力值：" + str(stamina)
	# 显示点赞数
	var my_likes = login_data.get("点赞数", 0)
	show_like.text = "点赞数：" + str(int(my_likes))

#打开玩家排行榜面板
func _on_player_ranking_button_pressed() -> void:
	
	player_ranking_panel.show()
	player_ranking_panel.request_player_rankings()
	pass 

#打开设置面板
func _on_setting_button_pressed() -> void:
	game_setting_panel.show()

#查看全服大喇叭按钮点击事件
func _on_watch_broadcast_button_pressed() -> void:
	
	# 显示全服大喇叭面板
	global_server_broadcast_panel.show()
	global_server_broadcast_panel.move_to_front()

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
	game_info_h_box_3.hide()
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
	global_server_broadcast_panel.hide()
	land_panel.hide()
	accept_dialog.hide()
	
	# 重置访问模式
	if is_visiting_mode:
		_handle_return_my_farm_response({"success": true})
	
	# 显示登录面板
	login_panel.show()
#========================================杂项未分类函数=======================================
	


#==========================打开基础面板================================
#打开种子商店面板
func _on_open_store_button_pressed() -> void:
	
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

#打开种子仓库面板
func _on_seed_warehouse_button_pressed() -> void:
	player_bag_panel.show()

#打开玩家道具背包面板
func _on_item_bag_button_pressed() -> void:
	item_bag_panel.show()
	
#打开道具商店面板
func _on_item_store_button_pressed() -> void:
	item_store_panel.show()

#打开作物仓库面板
func _on_crop_warehouse_button_pressed() -> void:
	crop_warehouse_panel.show()

#打开宠物背包面板
func _on_pet_bag_button_pressed() -> void:
	pet_bag_panel.show()
	pass 

#打开宠物商店面板
func _on_pet_store_button_pressed() -> void:
	pet_store_panel.show()
	pass

#==========================打开基础面板================================



#===============================================初始化数据处理===============================================
# 从服务器获取作物数据
func _load_crop_data():
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		# 从服务器请求作物数据
		tcp_network_manager_panel.sendGetCropData()
	else:
		# 如果无法连接服务器，尝试加载本地数据
		print("无法连接服务器，尝试加载本地作物数据...")
		_load_local_crop_data()

# 尝试从服务器加载最新数据
#玩家登录后在后台把服务器的配置文件通过网络覆写到本地config里面 然后也使用服务器的配置
func _try_load_from_server():

	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		# 从服务器请求最新作物数据
		print("尝试从服务器获取最新作物数据...")
		tcp_network_manager_panel.sendGetCropData()
		
		# 从服务器请求最新道具配置数据
		print("尝试从服务器获取最新道具配置数据...")
		tcp_network_manager_panel.sendGetItemConfig()
	else:
		print("服务器未连接，使用当前本地数据")

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
	
	_refresh_ui_after_crop_data_loaded()

# 作物数据加载后刷新UI
func _refresh_ui_after_crop_data_loaded():
	# 重新初始化商店和背包UI，因为现在有了作物数据
	crop_store_panel.init_store()
	print("种子商店已根据作物数据重新初始化")
	
	player_bag_panel.update_player_bag_ui()
	print("种子背包已根据作物数据重新初始化")
	
	crop_warehouse_panel.update_crop_warehouse_ui()
	print("作物仓库已根据作物数据重新初始化")
	
	item_bag_panel.update_item_bag_ui()
	print("道具背包已根据作物数据重新初始化")
	
	item_store_panel.init_item_store()
	print("道具商店已根据作物数据重新初始化")

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

# 保存道具配置数据到本地文件
func _save_item_config_to_local(config_data):
	var file = FileAccess.open("user://item_config.json", FileAccess.WRITE)
	if not file:
		print("无法创建本地道具配置缓存文件！")
		return
		
	var json_string = JSON.stringify(config_data, "\t")
	file.store_string(json_string)
	file.close()
	print("道具配置数据已保存到本地缓存")

# 从本地文件加载道具配置数据（备用方案）
func _load_local_item_config():
	# 优先尝试加载用户目录下的缓存文件
	var file = FileAccess.open("user://item_config.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			item_config_data = json.get_data()
			print("已加载本地缓存的道具配置数据")
			_refresh_ui_after_item_config_loaded()
			return
		else:
			print("本地缓存道具配置数据JSON解析错误：", json.get_error_message())
	
	_refresh_ui_after_item_config_loaded()

# 道具配置数据加载后刷新UI
func _refresh_ui_after_item_config_loaded():
	# 重新初始化道具相关UI
	item_store_panel.init_item_store()
	print("道具商店已根据道具配置数据重新初始化")
	
	item_bag_panel.update_item_bag_ui()
	print("道具背包已根据道具配置数据重新初始化")

# 处理服务器道具配置响应
func _handle_item_config_response(response_data):
	var success = response_data.get("success", false)
	
	if success:
		var config_data = response_data.get("item_config", {})
		if config_data:
			# 保存到本地文件
			_save_item_config_to_local(config_data)
			# 设置全局变量
			item_config_data = config_data
			print("道具配置数据已从服务器更新，道具种类：", item_config_data.size())
			
			# 重新初始化道具相关UI
			_refresh_ui_after_item_config_loaded()
		else:
			print("服务器返回的道具配置数据为空")
			_load_local_item_config()
	else:
		var message = response_data.get("message", "未知错误")
		print("从服务器获取道具配置数据失败：", message)
		_load_local_item_config()

# 处理服务器宠物配置响应
func _handle_pet_config_response(response_data):
	var success = response_data.get("success", false)
	
	if success:
		var config_data = response_data.get("pet_config", {})
		if config_data:
			# 设置全局变量
			pet_config = config_data
			print("宠物配置数据已从服务器更新，宠物种类：", pet_config.size())
		else:
			print("服务器返回的宠物配置数据为空")
			pet_config = {}
	else:
		var message = response_data.get("message", "未知错误")
		print("从服务器获取宠物配置数据失败：", message)
		pet_config = {}

#===============================================初始化数据处理===============================================



#===============================================作物图片缓存系统===============================================
## 优化的作物图片缓存和管理系统
class CropTextureManager:
	
	# 缓存字典 - 改为三阶段图片缓存
	var texture_cache: Dictionary = {}          # 阶段图片缓存 {crop_name: {"幼苗": Texture2D, "未成熟": Texture2D, "成熟": Texture2D}}
	var default_textures: Dictionary = {}       # 默认图片缓存 {"幼苗": Texture2D, "未成熟": Texture2D, "成熟": Texture2D}
	var failed_resources: Array = []           # 记录加载失败的资源路径
	
	# 三个生长阶段
	const GROWTH_STAGES = ["幼苗", "未成熟", "成熟"]
	
	# 加载状态
	var is_loading: bool = false
	var load_progress: float = 0.0
	var total_crops: int = 0
	var loaded_crops: int = 0
	var failed_crops: int = 0
	
	# 线程管理
	var worker_threads: Array = []
	var max_threads: int = 4  # 最大线程数
	var loading_queue: Array = []
	var loading_mutex: Mutex
	var results_mutex: Mutex
	var completed_results: Array = []
	
	# 内存管理
	var max_cache_size: int = 300  # 最大缓存图片数量
	var cache_access_order: Array = []  # LRU缓存访问顺序
	
	func _init():
		print("[CropTextureManager] 初始化优化的作物图片管理器")
		loading_mutex = Mutex.new()
		results_mutex = Mutex.new()
		# 根据设备性能动态调整线程数
		_adjust_thread_count()
	
	## 根据设备性能调整线程数
	func _adjust_thread_count():
		var platform = OS.get_name()
		var processor_count = OS.get_processor_count()
		
		match platform:
			"Android", "iOS":
				# 移动设备使用较少线程，避免过热和电量消耗
				max_threads = min(3, max(1, processor_count / 2))
			"Windows", "Linux", "macOS":
				# 桌面设备可以使用更多线程
				max_threads = min(6, max(2, processor_count - 1))
			_:
				max_threads = 3
		
		print("[CropTextureManager] 设备: %s, CPU核心: %d, 使用线程数: %d" % [platform, processor_count, max_threads])
	


	
	## 异步预加载所有作物图片 - 主要入口函数
	func preload_all_textures_async(crop_data: Dictionary, progress_callback: Callable) -> void:
		if is_loading:
			print("[CropTextureManager] 正在加载中，跳过重复请求")
			return
		
		is_loading = true
		load_progress = 0.0
		total_crops = crop_data.size()
		loaded_crops = 0
		failed_crops = 0
		failed_resources.clear()
		completed_results.clear()
		
		print("[CropTextureManager] 开始预加载 %d 种作物图片" % total_crops)
		
		# 阶段1：加载默认图片 (0-10%)
		progress_callback.call(0, "正在加载默认图片...")
		await _load_default_textures_async()
		progress_callback.call(10, "默认图片加载完成")
		
		# 阶段2：多线程批量加载作物图片 (10-90%)
		await _load_crops_multithreaded_async(crop_data, progress_callback)
		
		# 阶段3：完成 (90-100%)
		progress_callback.call(100, "所有作物图片加载完成！")
		_print_cache_stats()
		
		# 清理线程
		await _cleanup_threads()
		
		is_loading = false
		var success_message = "预加载完成，成功: %d, 失败: %d" % [loaded_crops, failed_crops]
		print("[CropTextureManager] " + success_message)
	
	## 多线程批量异步加载作物图片
	func _load_crops_multithreaded_async(crop_data: Dictionary, progress_callback: Callable) -> void:
		var crop_names = crop_data.keys()
		
		# 准备加载队列 - 为每个作物的每个阶段创建任务
		loading_mutex.lock()
		loading_queue.clear()
		for crop_name in crop_names:
			for stage in GROWTH_STAGES:
				loading_queue.append({
					"crop_name": crop_name,
					"stage": stage
				})
		loading_mutex.unlock()
		
		# 启动工作线程
		for i in range(max_threads):
			var thread = Thread.new()
			worker_threads.append(thread)
			thread.start(_worker_thread_function)
		
		# 监控进度
		var total_tasks = loading_queue.size()
		var last_completed = 0
		
		while true:
			# 处理完成的结果
			results_mutex.lock()
			var current_results = completed_results.duplicate()
			completed_results.clear()
			results_mutex.unlock()
			
			# 应用加载结果
			for result in current_results:
				_apply_loading_result(result)
				loaded_crops += 1
			
			# 更新进度
			var completed_tasks = total_tasks - loading_queue.size()
			if completed_tasks != last_completed:
				var progress = 10 + int((float(completed_tasks) / float(total_tasks)) * 80)
				var message = "多线程加载中... (%d/%d)" % [completed_tasks, total_tasks]
				progress_callback.call(progress, message)
				last_completed = completed_tasks
			
			# 检查是否完成
			loading_mutex.lock()
			var queue_empty = loading_queue.is_empty()
			loading_mutex.unlock()
			
			if queue_empty and completed_results.is_empty():
				break
			
			# 短暂等待
			await Engine.get_main_loop().process_frame
	
	## 工作线程函数
	func _worker_thread_function():
		while true:
			# 获取任务
			loading_mutex.lock()
			if loading_queue.is_empty():
				loading_mutex.unlock()
				break
			
			var task = loading_queue.pop_front()
			loading_mutex.unlock()
			
			# 执行加载任务
			var result = _load_texture_task(task)
			
			# 存储结果
			results_mutex.lock()
			completed_results.append(result)
			results_mutex.unlock()
	
	## 执行单个纹理加载任务
	func _load_texture_task(task: Dictionary) -> Dictionary:
		var crop_name = task["crop_name"]
		var stage = task["stage"]
		var result = {
			"crop_name": crop_name,
			"stage": stage,
			"success": false,
			"texture": null,
			"error": ""
		}
		
		result["texture"] = _load_stage_texture_threadsafe(crop_name, stage)
		result["success"] = result["texture"] != null
		
		# 检查加载是否成功
		if not result["success"]:
			result["error"] = "加载失败: %s - %s" % [crop_name, stage]
			failed_resources.append(crop_name + "/" + stage)
		
		return result
	
	## 线程安全的阶段图片加载
	func _load_stage_texture_threadsafe(crop_name: String, stage: String) -> Texture2D:
		var crop_path = "res://assets/作物/" + crop_name + "/"
		var texture_path = crop_path + stage + ".webp"
		
		# 首先尝试加载作物特定的阶段图片
		if ResourceLoader.exists(texture_path):
			var texture = _load_resource_safe(texture_path)
			if texture:
				return texture
		
		# 如果没有找到，尝试使用默认图片
		var default_path = "res://assets/作物/默认/" + stage + ".webp"
		if ResourceLoader.exists(default_path):
			var default_texture = _load_resource_safe(default_path)
			if default_texture:
				return default_texture
		
		return null
	
	## 安全的资源加载函数，带错误处理
	func _load_resource_safe(path: String) -> Resource:
		if not ResourceLoader.exists(path):
			return null
		
		# 使用ResourceLoader.load，它在Godot 4中是线程安全的
		var resource = ResourceLoader.load(path, "Texture2D")
		
		# 验证资源
		if resource and resource is Texture2D:
			return resource
		else:
			if resource == null:
				print("[错误] 加载资源失败: ", path)
				failed_resources.append(path)
			else:
				print("[警告] 资源类型不匹配: ", path)
			return null
	
	## 应用加载结果到缓存
	func _apply_loading_result(result: Dictionary):
		var crop_name = result["crop_name"]
		var stage = result["stage"]
		var success = result["success"]
		
		if not success:
			return
		
		var texture = result["texture"]
		if texture:
			# 确保作物有缓存字典
			if not texture_cache.has(crop_name):
				texture_cache[crop_name] = {}
			
			# 缓存阶段图片
			texture_cache[crop_name][stage] = texture
			_update_cache_access(crop_name + "_" + stage)
		
		# 检查缓存大小，必要时清理
		_check_and_cleanup_cache()
	
	## 立即加载默认图片（同步，但优化）
	func _load_default_textures_async() -> void:
		const DEFAULT_PATH = "res://assets/作物/默认/"
		
		if default_textures.size() > 0:
			return
		
		# 加载三个阶段的默认图片
		for stage in GROWTH_STAGES:
			var texture_path = DEFAULT_PATH + stage + ".webp"
			if ResourceLoader.exists(texture_path):
				var texture = _load_resource_safe(texture_path)
				if texture:
					default_textures[stage] = texture
		
		print("[CropTextureManager] 默认图片加载完成：%d 个阶段" % default_textures.size())
		
		# 让出一帧
		await Engine.get_main_loop().process_frame
	
	## 更新缓存访问顺序（LRU）
	func _update_cache_access(key: String):
		if key in cache_access_order:
			cache_access_order.erase(key)
		cache_access_order.append(key)
	
	## 检查并清理缓存
	func _check_and_cleanup_cache():
		var total_cached = 0
		for crop_name in texture_cache.keys():
			total_cached += texture_cache[crop_name].size()
		
		if total_cached > max_cache_size:
			var to_remove = total_cached - max_cache_size + 10  # 多清理一些
			
			for i in range(min(to_remove, cache_access_order.size())):
				var key = cache_access_order[i]
				
				# 不清理默认图片相关的键
				if key.begins_with("默认"):
					continue
				
				# 解析键：crop_name_stage
				var parts = key.split("_")
				if parts.size() >= 2:
					var stage = parts[-1]
					var crop_name = "_".join(parts.slice(0, -1))
					
					if texture_cache.has(crop_name) and texture_cache[crop_name].has(stage):
						texture_cache[crop_name].erase(stage)
						
						# 如果作物的所有阶段都被清理，删除作物条目
						if texture_cache[crop_name].is_empty():
							texture_cache.erase(crop_name)
			
			# 更新访问顺序
			cache_access_order = cache_access_order.slice(to_remove)
			
			var current_size = 0
			for crop_name in texture_cache.keys():
				current_size += texture_cache[crop_name].size()
			var cleanup_msg = "缓存清理完成，当前缓存: %d" % current_size
			print("[CropTextureManager] " + cleanup_msg)
	
	## 根据生长进度获取作物图片（带缓存优化）
	func get_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
		# 根据进度确定阶段
		var stage = ""
		if progress < 0.33:
			stage = "幼苗"
		elif progress < 0.85:
			stage = "未成熟"
		else:
			stage = "成熟"
		
		# 更新访问记录
		var access_key = crop_name + "_" + stage
		_update_cache_access(access_key)
		
		# 尝试获取作物特定的阶段图片
		if texture_cache.has(crop_name) and texture_cache[crop_name].has(stage):
			var texture = texture_cache[crop_name][stage]
			if texture:
				return texture
		
		# 如果没有缓存，尝试直接从文件夹加载
		var direct_texture = _load_stage_texture_threadsafe(crop_name, stage)
		if direct_texture:
			# 将直接加载的图片加入缓存，避免下次再次加载
			if not texture_cache.has(crop_name):
				texture_cache[crop_name] = {}
			texture_cache[crop_name][stage] = direct_texture
			_update_cache_access(crop_name + "_" + stage)
			return direct_texture
		
		# 最后才回退到默认图片
		if default_textures.has(stage):
			var default_texture = default_textures[stage]
			if default_texture:
				return default_texture
		
		# 如果都没有，返回null
		return null
	
	## 清理线程
	func _cleanup_threads() -> void:
		for thread in worker_threads:
			if thread.is_started():
				thread.wait_to_finish()
		worker_threads.clear()
		print("[CropTextureManager] 工作线程已清理")
	
	## 清理缓存
	func clear_cache() -> void:
		await _cleanup_threads()
		texture_cache.clear()
		default_textures.clear()
		cache_access_order.clear()
		failed_resources.clear()
		print("[CropTextureManager] 缓存已清理")
	
	## 打印缓存统计信息
	func _print_cache_stats() -> void:
		print("[CropTextureManager] 缓存统计:")
		print("  - 阶段图片缓存: %d 种作物" % texture_cache.size())
		print("  - 默认图片缓存: %d 个阶段" % default_textures.size())
		print("  - 加载失败: %d 个资源" % failed_resources.size())
		var total_stages = 0
		for crop_name in texture_cache.keys():
			total_stages += texture_cache[crop_name].size()
		print("  - 总阶段图片数: %d 个" % total_stages)
		
		if failed_resources.size() > 0:
			print("  - 失败的资源:")
			for failed in failed_resources:
				print("    * ", failed)
	
	## 获取详细缓存信息
	func get_cache_info() -> String:
		var info = "作物图片缓存详情:\n"
		for crop_name in texture_cache.keys():
			var stages = texture_cache[crop_name].keys()
			info += "  - %s: %s" % [crop_name, "/".join(stages)]
			info += "\n"
		
		if default_textures.size() > 0:
			info += "\n默认图片:\n"
			for stage in default_textures.keys():
				info += "  - " + stage + "\n"
		
		if failed_resources.size() > 0:
			info += "\n加载失败的资源:\n"
			for failed in failed_resources:
				info += "  - " + failed + "\n"
		
		return info
	
	## 预热常用作物（可选优化）
	func preheat_common_crops(common_crops: Array) -> void:
		print("[CropTextureManager] 预热常用作物: ", common_crops.size(), " 种")
		for crop_name in common_crops:
			# 确保常用作物在缓存中
			if not texture_cache.has(crop_name):
				texture_cache[crop_name] = {}
				
				# 加载各个阶段的图片
				for stage in GROWTH_STAGES:
					var texture = _load_stage_texture_threadsafe(crop_name, stage)
					if texture:
						texture_cache[crop_name][stage] = texture
	


# 全局作物图片管理器实例
var crop_texture_manager: CropTextureManager

#===============================================作物图片缓存系统===============================================



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
	load_progress_bar.value = progress
	
	# 更新消息显示
	var message_label = load_progress_panel.get_node_or_null("MessageLabel")
	if message_label and message != "":
		message_label.text = message
	

	# 检测卡顿
	_check_loading_stuck(progress)
	
	if message != "":
		#print("[加载进度] %d%% - %s" % [progress, message])
		pass

# 上一次进度更新的时间和进度值
var last_progress_time: float = 0.0
var last_progress_value: int = 0

## 检测加载卡顿
func _check_loading_stuck(progress: int):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 如果进度没有变化
	if progress == last_progress_value:
		var stuck_time = current_time - last_progress_time
		if stuck_time > 5.0:  # 5秒没有进度变化
			print("⚠ 加载卡顿检测: 在 %d%% 停留了 %.1f 秒" % [progress, stuck_time])
	else:
		# 进度有变化，更新记录
		last_progress_value = progress
		last_progress_time = current_time

## 主预加载函数 - 游戏启动时调用
func _preload_all_crop_textures() -> void:
	
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
#===============================================加载进度管理============================================



#===============================================向后兼容性===============================================
# 为了保持向后兼容，保留一些原来的函数名
func _load_crop_textures(crop_name: String) -> Array:
	# 返回所有阶段的图片
	if crop_texture_manager and crop_texture_manager.texture_cache.has(crop_name):
		var stages = crop_texture_manager.texture_cache[crop_name]
		var textures = []
		for stage in crop_texture_manager.GROWTH_STAGES:
			if stages.has(stage):
				textures.append(stages[stage])
		return textures
	return []

func _get_crop_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
	if crop_texture_manager:
		return crop_texture_manager.get_texture_by_progress(crop_name, progress)
	return null

func _clear_crop_textures_cache() -> void:
	if crop_texture_manager:
		crop_texture_manager.clear_cache()

func _get_crop_cache_info() -> String:
	if crop_texture_manager:
		return crop_texture_manager.get_cache_info()
	return "图片管理器未初始化"
#===============================================向后兼容性===============================================



#===============================================添加新地块处理===============================================
#添加新的地块，默认花费2000
func _on_add_new_ground_button_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法购买新地块", Color.ORANGE)
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
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendBuyNewGround"):
		var success = tcp_network_manager_panel.sendBuyNewGround()
		if success:
			print("已发送购买新地块请求")
		else:
			Toast.show("网络未连接，无法购买新地块", Color.RED)
	else:
		Toast.show("网络管理器不可用", Color.RED)

#===============================================添加新地块处理===============================================



#===============================================每日签到处理===============================================
#每日签到 奖励可以有钱币，经验，随机种子 连续签到奖励更多 连续签到只要不中断，奖励会随着签到的次数逐渐变得丰厚
func _on_daily_check_in_button_pressed() -> void:
	daily_check_in_panel.show()
	# 刷新签到数据
	daily_check_in_panel.refresh_check_in_data()

# 处理每日签到响应
func _handle_daily_check_in_response(response: Dictionary) -> void:
	# 更新玩家数据
	var updated_data = response.get("updated_data", {})

	money = updated_data["钱币"]
	experience = updated_data["经验值"]
	level = updated_data["等级"]
	player_bag = updated_data["种子仓库"]
	
	# 更新UI
	_update_ui()
	
	# 更新玩家背包UI
	player_bag_panel.update_player_bag_ui()
	
	# 向签到面板传递响应
	daily_check_in_panel.handle_daily_check_in_response(response)
	
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
	daily_check_in_panel.handle_check_in_data_response(response)

#===============================================每日签到处理===============================================



#===============================================一键收获处理===============================================
#一键收获 默认花费400元 可以一键收获已成熟作物 
func _on_one_click_harvestbutton_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法使用一键收获", Color.ORANGE)
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
				if tcp_network_manager_panel and tcp_network_manager_panel.sendHarvestCrop(i):
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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		tcp_network_manager_panel.client.disconnect_from_server()
		print("已断开与服务器的连接")
	
	# 直接切换到主菜单场景
	get_tree().change_scene_to_file('res://GUI/MainMenuPanel.tscn')
#===============================================返回主菜单处理===============================================



#===============================================幸运抽奖处理===============================================
#幸运抽奖 默认800元抽一次 五连抽打九折 十连抽打八折 奖励可以有钱币，经验，随机种子  
func _on_lucky_draw_button_pressed() -> void:
	lucky_draw_panel.show()
	# 刷新抽奖显示数据
	lucky_draw_panel.refresh_reward_display()

# 处理幸运抽奖响应
func _handle_lucky_draw_response(response: Dictionary) -> void:
	# 更新玩家数据
	var updated_data = response.get("updated_data", {})
	money = updated_data["钱币"]
	experience = updated_data["经验值"]
	level = updated_data["等级"]
	player_bag = updated_data["种子仓库"]
	
	# 更新UI
	_update_ui()
	
	# 更新玩家背包UI
	player_bag_panel.update_player_bag_ui()
	
	# 向抽奖面板传递响应
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
	
	# 检查剩余点赞次数
	if remaining_likes <= 0:
		Toast.show("今日点赞次数已用完，明天再来吧！", Color.ORANGE)
		return
	
	# 获取被访问玩家的用户名
	var target_username = visited_player_data.get("玩家账号", "")
	if target_username == "":
		Toast.show("无法获取目标玩家信息", Color.RED)
		return
	
	# 发送点赞请求
	var success = tcp_network_manager_panel.sendLikePlayer(target_username)
	if success:
		print("已发送点赞请求给玩家：", target_username, "，剩余点赞次数：", remaining_likes)
	else:
		Toast.show("网络未连接，无法点赞", Color.RED)
		print("发送点赞请求失败，网络未连接")

# 处理点赞响应
func _handle_like_player_response(data):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		var target_likes = data.get("target_likes", 0)
		var remaining_likes_from_server = data.get("remaining_likes", 0)
		
		# 更新本地剩余点赞次数
		remaining_likes = remaining_likes_from_server
		
		# 显示成功消息，包含剩余次数
		Toast.show(message, Color.PINK)
		
		# 更新被访问玩家的点赞数显示
		visited_player_data["点赞数"] = target_likes
		show_like.text = "点赞数：" + str(int(target_likes))
		
		# 显示剩余点赞次数提示
		if remaining_likes > 0:
			print("点赞成功，目标玩家点赞数：", target_likes, "，您今日还可点赞", remaining_likes, "次")
		else:
			print("点赞成功，目标玩家点赞数：", target_likes, "，您今日点赞次数已用完")
			Toast.show("今日点赞次数已用完，明天再来吧！", Color.ORANGE)
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
	
	# 创建定时器，每10秒请求一次在线人数
	var timer = Timer.new()
	timer.wait_time = 10.0  # 10秒
	timer.timeout.connect(_request_online_players)
	timer.autostart = true
	add_child(timer)

# 请求在线人数
func _request_online_players():
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		var success = tcp_network_manager_panel.sendGetOnlinePlayers()
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

# 更新在线设备显示
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
	
	# 显示确认对话框
	var confirm_dialog = preload("res://Script/Dialog/AcceptDialog.gd").new()
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
	var success = tcp_network_manager_panel.sendClaimNewPlayerGift()
	if success:
		pass
	else:
		Toast.show("发送请求失败", Color.RED)

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
		money = updated_data.get("钱币", money)
		experience = updated_data.get("经验值", experience)
		level = updated_data.get("等级", level)
		
		# 安全更新背包数据
		if updated_data.has("种子仓库"):
			player_bag = updated_data["种子仓库"]
		if updated_data.has("宠物背包"):
			pet_bag = updated_data["宠物背包"]
		
		# 获取新手礼包状态
		var new_player_gift_data = updated_data.get("新手礼包", {})
		if new_player_gift_data.get("已领取", false):
			new_player_gift_claimed = true
			new_player_gift_button.hide()
		
		# 更新UI
		_update_ui()
		
		# 更新宠物背包UI
		if updated_data.has("宠物背包"):
			pet_bag_panel.update_pet_bag_ui()
			# 更新对战按钮显示
			_update_battle_button_visibility()
		
		# 显示成功消息
		Toast.show(message, Color.GOLD, 3.0, 1.0)
		
		print("新手大礼包领取成功！")
	else:
		# 如果已经领取过，也隐藏按钮
		if message.find("已经领取过") >= 0:
			new_player_gift_claimed = true
			new_player_gift_button.hide()
		
		# 显示错误消息
		Toast.show(message, Color.RED, 2.0, 1.0)

#====================================领取新手玩家礼包处理=========================================



#====================================全服大喇叭处理=========================================
# 处理全服大喇叭消息
func _handle_global_broadcast_message(data: Dictionary):
	# 将消息传递给大喇叭面板处理
	global_server_broadcast_panel.receive_broadcast_message(data)
	
	# 立即更新主界面大喇叭显示
	update_broadcast_display_from_message(data)

# 处理全服大喇叭发送响应
func _handle_global_broadcast_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	
	if success:
		Toast.show("大喇叭消息发送成功", Color.GREEN, 2.0, 1.0)
	else:
		Toast.show("大喇叭消息发送失败：" + message, Color.RED, 3.0, 1.0)

# 处理全服大喇叭历史消息响应
func _handle_broadcast_history_response(data: Dictionary):
	#print("收到历史消息响应: ", data.get("messages", []).size(), " 条消息")
	
	if global_server_broadcast_panel and global_server_broadcast_panel.has_method("receive_history_messages"):
		global_server_broadcast_panel.receive_history_messages(data)
		
		# 更新主界面大喇叭显示为最新消息
		update_broadcast_display_from_panel()

# 从消息数据直接更新大喇叭显示
func update_broadcast_display_from_message(data: Dictionary):
	if global_server_broadcast:
		var username = data.get("username", "匿名")
		var player_name = data.get("玩家昵称", "")
		var content = data.get("content", "")
		
		# 优先显示玩家昵称
		var display_name = player_name if player_name != "" else username
		global_server_broadcast.text = display_name + ": " + content
		#print("主界面大喇叭已更新为: ", global_server_broadcast.text)

# 从面板获取最新消息更新大喇叭显示
func update_broadcast_display_from_panel():
	if global_server_broadcast and global_server_broadcast_panel:
		var latest_message = global_server_broadcast_panel.get_latest_message()
		if latest_message != "暂无消息" and latest_message != "全服大喇叭":
			global_server_broadcast.text = latest_message
			#print("主界面大喇叭已更新为: ", latest_message)
		else:
			global_server_broadcast.text = "全服大喇叭"


# 初始化大喇叭显示
func _init_broadcast_display():
	if global_server_broadcast and global_server_broadcast_panel:
		# 设置默认文本
		global_server_broadcast.text = "全服大喇叭"
		
		# 先从本地加载，然后请求服务器最新消息
		_load_broadcast_from_local()
		_request_latest_broadcast_message()

# 从本地文件加载大喇叭消息
func _load_broadcast_from_local():
	var file_path = "user://chat_history.json"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var data = json.data
				if data is Array and data.size() > 0:
					# 按时间戳排序，确保类型一致
					data.sort_custom(func(a, b): 
						var timestamp_a = a.get("timestamp", 0)
						var timestamp_b = b.get("timestamp", 0)
						# 确保都是数字类型
						if timestamp_a is String:
							timestamp_a = float(timestamp_a)
						if timestamp_b is String:
							timestamp_b = float(timestamp_b)
						return timestamp_a < timestamp_b
					)
					# 获取最新消息
					var latest = data[-1]
					var display_name = latest.get("display_name", "匿名")
					var content = latest.get("content", "")
					global_server_broadcast.text = display_name + ": " + content

# 请求服务器获取最新的一条大喇叭消息
func _request_latest_broadcast_message():
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		# 请求最近1天的消息
		var success = tcp_network_manager_panel.send_message({
			"type": "request_broadcast_history",
			"days": 1,
			"limit": 10,  # 获取最近10条，客户端取最新的
			"timestamp": Time.get_unix_time_from_system()
		})
		
		if not success:
			print("请求最新大喇叭消息失败")
	else:
		print("未连接到服务器，无法请求最新大喇叭消息")

# 请求服务器历史消息用于刷新显示
func _request_server_history_for_refresh():
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		# 请求最近3天的消息
		var success = tcp_network_manager_panel.send_message({
			"type": "request_broadcast_history",
			"days": 3,
			"timestamp": Time.get_unix_time_from_system()
		})
		
		if success:
			pass
		else:
			print("请求服务器历史消息失败")

#====================================全服大喇叭处理=========================================



#====================================一键截图处理=========================================
#一键截图按钮,隐藏所有UI，截图，然后保存在相应位置
func _on_one_click_screen_shot_pressed() -> void:
	# 保存当前UI状态
	var ui_state = _save_ui_visibility_state()
	
	# 临时禁用UI自动显示逻辑
	var original_start_game = start_game
	start_game = false
	
	# 隐藏所有UI
	_hide_all_ui_for_screenshot()
	
	# 等待5秒
	await get_tree().create_timer(5.0).timeout
	
	# 恢复游戏状态
	start_game = original_start_game
	
	# 恢复UI显示
	_restore_ui_visibility_state(ui_state)
	

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

#====================================一键截图处理=========================================



#====================================在线礼包处理=========================================
#在线礼包，在线时间越久，越丰富，默认 1分钟 10分钟 30分钟 1小时 3小时 5小时 每天刷新
func _on_online_gift_button_pressed() -> void:
	# 每次打开面板时都请求最新的在线数据
	online_gift_panel.show_panel_and_request_data()

# 处理在线礼包数据响应
func _handle_online_gift_data_response(data: Dictionary):
	online_gift_panel.handle_online_gift_data_response(data)

# 处理领取在线礼包响应
func _handle_claim_online_gift_response(data: Dictionary):
	var success = data.get("success", false)
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		money = updated_data["钱币"]
		experience = updated_data["经验值"]
		level = updated_data["等级"]
		player_bag = updated_data["种子仓库"]
		
		# 更新UI
		_update_ui()
		player_bag_panel.update_player_bag_ui()
	
	# 将响应传递给在线礼包面板处理UI更新
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
			user_password = account_info["玩家密码"]
			show_farm_name.text = "农场名称：" + account_info.get("农场名称", "")
			show_player_name.text = "玩家昵称：" + account_info.get("玩家昵称", "")
			
			# 更新基本游戏状态显示
			experience = account_info.get("经验值", 0)
			level = account_info.get("等级", 1)
			money = account_info.get("钱币", 0)
			
			# 同步更新login_data和data中的账户信息
			if login_data.size() > 0:
				login_data["玩家密码"] = account_info.get("玩家密码", "")
				login_data["玩家昵称"] = account_info.get("玩家昵称", "")
				login_data["农场名称"] = account_info.get("农场名称", "")
				login_data["个人简介"] = account_info.get("个人简介", "")
			
			if data.size() > 0:
				data["玩家密码"] = account_info.get("玩家密码", "")
				data["玩家昵称"] = account_info.get("玩家昵称", "")
				data["农场名称"] = account_info.get("农场名称", "")
				data["个人简介"] = account_info.get("个人简介", "")
			
			# 更新UI显示
			_update_ui()
	
	# 将响应传递给账户设置面板
	account_setting_panel.handle_account_response(data)

# 处理宠物使用道具响应
func _handle_use_pet_item_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 安全更新宠物背包数据
		if updated_data.has("宠物背包"):
			pet_bag = updated_data["宠物背包"]
			# 更新宠物背包UI
			if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
				pet_bag_panel.update_pet_bag_ui()
			# 更新对战按钮显示
			_update_battle_button_visibility()
		
		# 安全更新道具背包数据
		if updated_data.has("道具背包"):
			item_bag = updated_data["道具背包"]
			# 更新道具背包UI
			if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
				item_bag_panel.update_item_bag_ui()
		
		# 刷新宠物信息面板（如果当前有显示的宠物）
		var pet_inform_panel = get_node_or_null("UI/SmallPanel/PetInformPanel")
		if pet_inform_panel and pet_inform_panel.has_method("show_pet_info"):
			# 如果宠物信息面板当前有显示的宠物，刷新其信息
			if not pet_inform_panel.current_pet_data.is_empty():
				var current_pet_id = pet_inform_panel.current_pet_data.get("基本信息", {}).get("宠物ID", "")
				if current_pet_id != "":
					# 查找更新后的宠物数据
					for pet in pet_bag:
						if pet.get("基本信息", {}).get("宠物ID", "") == current_pet_id:
							pet_inform_panel.show_pet_info(pet_inform_panel.current_pet_name, pet)
							break
		
		Toast.show(message, Color.GREEN, 3.0, 1.0)
	else:
		Toast.show(message, Color.RED, 3.0, 1.0)

# 处理农场道具使用响应
func _handle_use_farm_item_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 安全更新金币
		if updated_data.has("钱币"):
			money = updated_data["钱币"]
		# 安全更新经验
		if updated_data.has("经验值"):
			experience = updated_data["经验值"]
		# 安全更新等级
		if updated_data.has("等级"):
			level = updated_data["等级"]
		# 安全更新道具背包数据
		if updated_data.has("道具背包"):
			item_bag = updated_data["道具背包"]
			# 更新道具背包UI
			if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
				item_bag_panel.update_item_bag_ui()
		# 更新UI显示
		_update_ui()
		
		Toast.show(message, Color.GREEN, 3.0, 1.0)
	else:
		Toast.show(message, Color.RED, 3.0, 1.0)

#打开账户设置面板
func _on_account_setting_button_pressed() -> void:
	account_setting_panel.show()
	GlobalVariables.isZoomDisabled = true
	account_setting_panel._refresh_player_info()
	pass 
#====================================账户设置处理=========================================



#====================================稻草人系统处理=========================================
# 处理购买稻草人响应
func _handle_buy_scare_crow_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		money = updated_data["钱币"]
		login_data["稻草人配置"] = updated_data["稻草人配置"]
			
		# 将稻草人配置传递给稻草人面板
		scare_crow_panel.handle_buy_scare_crow_response(success, message, updated_data)
		
		# 更新UI
		_update_ui()
		
		# 更新稻草人显示
		update_scare_crow_display()
	else:
		scare_crow_panel.handle_buy_scare_crow_response(success, message, updated_data)

# 处理修改稻草人配置响应
func _handle_modify_scare_crow_config_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		money = updated_data["钱币"]
		login_data["稻草人配置"] = updated_data["稻草人配置"]
			
		# 将稻草人配置传递给稻草人面板
		scare_crow_panel.handle_modify_scare_crow_config_response(success, message, updated_data)
		
		# 更新UI
		_update_ui()
		
		# 更新稻草人显示
		update_scare_crow_display()
	else:
		scare_crow_panel.handle_modify_scare_crow_config_response(success, message, updated_data)

# 处理获取稻草人配置响应
func _handle_get_scare_crow_config_response(data: Dictionary):
	var success = data.get("success", false)
	var scare_crow_config = data.get("scare_crow_config", {})
	
	if success:
		# 更新登录数据中的稻草人配置
		login_data["稻草人配置"] = scare_crow_config
		
		# 将稻草人配置传递给稻草人面板
		scare_crow_panel.set_player_scare_crow_config(scare_crow_config)
		
		# 更新稻草人显示
		update_scare_crow_display()

# 更新稻草人显示
func update_scare_crow_display():
	scare_crow.show()
	
	# 如果处于访问模式，显示被访问玩家的稻草人
	var config_to_display = {}
	
	if is_visiting_mode and visited_player_data.has("稻草人配置"):
		config_to_display = visited_player_data["稻草人配置"]
	elif login_data.has("稻草人配置"):
		config_to_display = login_data["稻草人配置"]
	else:
		# 如果没有稻草人配置，隐藏稻草人图片和话语
		scare_crow_image.hide()
		scare_crowtalks.hide()
		scare_crow_name.hide()
		return
	
	# 检查是否有已拥有的稻草人类型
	var owned_types = config_to_display.get("已拥有稻草人类型", [])
	if owned_types.size() == 0:
		# 如果没有购买过任何稻草人，隐藏稻草人图片和话语
		scare_crow_image.hide()
		scare_crowtalks.hide()
		scare_crow_name.hide()
		return
	
	# 显示稻草人元素
	scare_crow_image.show()
	scare_crowtalks.show()
	scare_crow_name.show()
	
	# 更新稻草人图片
	var display_type = config_to_display.get("稻草人展示类型", "")
	if display_type != "":
		var image_path = ""
		match display_type:
			"稻草人1":
				image_path = "res://assets/稻草人图片/稻草人1.webp"
			"稻草人2":
				image_path = "res://assets/稻草人图片/稻草人2.webp"
			"稻草人3":
				image_path = "res://assets/稻草人图片/稻草人3.webp"
		
		if image_path != "" and ResourceLoader.exists(image_path):
			var texture = load(image_path)
			scare_crow_image.texture = texture
	
	# 更新稻草人昵称和颜色
	var scare_crow_nickname = config_to_display.get("稻草人昵称", "稻草人")
	var nickname_color = config_to_display.get("稻草人昵称颜色", "#ffffff")
	scare_crow_name.text = "[color=" + nickname_color + "]" + scare_crow_nickname + "[/color]"
	
	# 准备稻草人说的话列表
	var talks = config_to_display.get("稻草人说的话", {})
	scare_crow_talks_list.clear()
	
	for i in range(1, 5):
		var talk_key = "第" + ["一", "二", "三", "四"][i-1] + "句话"
		if talks.has(talk_key):
			var talk_data = talks[talk_key]
			var content = talk_data.get("内容", "")
			var color = talk_data.get("颜色", "#000000")
			
			if content != "":
				scare_crow_talks_list.append({
					"content": content,
					"color": color
				})
	
	# 如果没有话语内容，添加默认话语
	if scare_crow_talks_list.size() == 0:
		scare_crow_talks_list.append({
			"content": "我是一个可爱的稻草人！",
			"color": "#000000"
		})
	
	# 重置话语索引和计时器
	scare_crow_talk_index = 0
	scare_crow_talk_timer = 0.0
	
	# 显示第一句话
	_update_scare_crow_talk()

# 更新稻草人当前说的话
func _update_scare_crow_talk():
	if scare_crow_talks_list.size() == 0:
		return
	
	# 循环切换话语索引
	if scare_crow_talk_index >= scare_crow_talks_list.size():
		scare_crow_talk_index = 0
	
	# 获取当前话语
	var current_talk = scare_crow_talks_list[scare_crow_talk_index]
	var content = current_talk.get("content", "")
	var color = current_talk.get("color", "#000000")
	
	# 更新显示
	scare_crowtalks.text = "[color=" + color + "]" + content + "[/color]"
	
	# 切换到下一句话
	scare_crow_talk_index += 1

# 初始化稻草人配置（登录时调用）
func init_scare_crow_config():
	if login_data.has("稻草人配置"):
		# 有稻草人配置，检查是否有已拥有的稻草人类型
		var scare_crow_config = login_data["稻草人配置"]
		var owned_types = scare_crow_config.get("已拥有稻草人类型", [])
		
		if owned_types.size() > 0:
			# 有已拥有的稻草人，更新显示
			update_scare_crow_display()
			
			# 传递配置给稻草人面板
			if scare_crow_panel and scare_crow_panel.has_method("set_player_scare_crow_config"):
				scare_crow_panel.set_player_scare_crow_config(scare_crow_config)
		else:
			# 没有已拥有的稻草人，隐藏稻草人
			scare_crow.hide()
	else:
		# 没有稻草人配置，隐藏稻草人
		scare_crow.hide()


#打开农场稻草人设置面板
func _on_scare_crow_pressed() -> void:
	if is_visiting_mode:
		Toast.show("访问模式不能打开稻草人配置面板",Color.RED)
		return
	
	scare_crow_panel.show()
	scare_crow_panel.move_to_front()
	pass 

#====================================稻草人系统处理=========================================



#===============================================道具使用处理===============================================
# 在地块上使用道具
func _use_item_on_lot(lot_index: int, item_name: String):
	# 基础检查
	if lot_index < 0 or lot_index >= farm_lots.size():
		Toast.show("无效的地块索引", Color.RED, 2.0, 1.0)
		return
	
	if is_visiting_mode:
		Toast.show("访问模式下无法使用道具", Color.ORANGE, 2.0, 1.0)
		return
	
	var lot = farm_lots[lot_index]
	
	# 根据道具类型执行不同的逻辑
	var action_type = ""
	var action_name = ""
	
	match item_name:
		"农家肥", "金坷垃", "生长素":
			action_type = "fertilize"
			action_name = "施肥"
			if not _validate_lot_for_growth_items(lot, action_name) or lot.get("已施肥", false):
				if lot.get("已施肥", false):
					Toast.show("此作物已经施过肥了", Color.ORANGE, 2.0, 1.0)
				return
		"水壶", "水桶":
			action_type = "water"
			action_name = "浇水"
			if not _validate_lot_for_growth_items(lot, action_name):
				return
		"铲子":
			action_type = "remove"
			action_name = "铲除"
			if not _validate_lot_for_planted_crop(lot, action_name):
				return
		"除草剂":
			action_type = "weed_killer"
			action_name = "除草"
			if not _validate_lot_for_planted_crop(lot, action_name):
				return
			var crop_type = lot.get("crop_type", "")
			var is_weed = can_planted_crop.has(crop_type) and can_planted_crop[crop_type].get("是否杂草", false)
			if not is_weed:
				Toast.show("除草剂只能用于清除杂草，此作物不是杂草", Color.ORANGE, 2.0, 1.0)
				return
		"精准采集锄", "时运锄":
			action_type = "harvest"
			action_name = "收获"
			if not _validate_lot_for_harvest(lot, action_name):
				return
		_:
			Toast.show("该道具暂未实现使用功能: " + item_name, Color.YELLOW, 2.0, 1.0)
			return
	
	# 检查道具并发送请求
	if not _has_item_in_bag(item_name):
		Toast.show("您没有 " + item_name, Color.RED, 2.0, 1.0)
		return
	
	_send_use_item_request(lot_index, item_name, action_type, action_name)

# 验证地块是否适合使用生长类道具（施肥、浇水）
func _validate_lot_for_growth_items(lot: Dictionary, action_name: String) -> bool:
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	if lot.get("is_dead", false):
		Toast.show("作物已死亡，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	if grow_time >= max_grow_time:
		Toast.show("作物已成熟，无需" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	return true

# 验证地块是否适合铲除类操作
func _validate_lot_for_planted_crop(lot: Dictionary, action_name: String) -> bool:
	if not lot.get("is_diged", false):
		Toast.show("此地块尚未开垦，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
		Toast.show("此地块没有种植作物，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	return true

# 验证地块是否适合收获
func _validate_lot_for_harvest(lot: Dictionary, action_name: String) -> bool:
	if not _validate_lot_for_planted_crop(lot, action_name):
		return false
	
	if lot.get("is_dead", false):
		Toast.show("作物已死亡，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	var grow_time = float(lot.get("grow_time", 0))
	var max_grow_time = float(lot.get("max_grow_time", 1))
	if grow_time < max_grow_time:
		Toast.show("作物还未成熟，无法" + action_name, Color.ORANGE, 2.0, 1.0)
		return false
	
	return true

# 检查玩家是否拥有指定道具
func _has_item_in_bag(item_name: String) -> bool:
	for item in item_bag:
		if item.get("name", "") == item_name and item.get("count", 0) > 0:
			return true
	return false

# 发送使用道具请求
func _send_use_item_request(lot_index: int, item_name: String, action_type: String, action_name: String):
	var target_username = visited_player_data.get("玩家账号", "") if is_visiting_mode else ""
	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, action_type, target_username):
			_clear_item_selection()
			var action_text = ("帮助" if is_visiting_mode else "") + action_name
			Toast.show("正在使用 " + item_name + " " + action_text + "...", Color.CYAN, 2.0, 1.0)
		else:
			Toast.show("发送使用道具请求失败", Color.RED, 2.0, 1.0)
	else:
		Toast.show("网络未连接，无法使用道具", Color.RED, 2.0, 1.0)

# 清除道具选择状态
func _clear_item_selection():
	selected_item_name = ""
	is_item_selected = false
	
	if item_bag_panel and item_bag_panel.has_method("_deselect_item"):
		item_bag_panel._deselect_item()
#===============================================道具使用处理===============================================





#===============================================巡逻宠物管理===============================================
# 简单的巡逻宠物管理
var patrol_pet_instances: Array[Area2D] = []

func _create_single_patrol_pet(pet_data: Dictionary, position_index: int):
	# 检查巡逻点节点
	if not pet_patrol_points:
		print("错误：找不到巡逻点节点")
		return
	
	# 获取四个巡逻点
	var patrol_positions = []
	if pos_1: patrol_positions.append(pos_1.global_position)
	if pos_2: patrol_positions.append(pos_2.global_position)
	if pos_3: patrol_positions.append(pos_3.global_position)
	if pos_4: patrol_positions.append(pos_4.global_position)


	
	if patrol_positions.size() == 0:
		print("错误：没有找到有效的巡逻点")
		return
	
	# 确保位置索引有效
	if position_index >= patrol_positions.size():
		position_index = position_index % patrol_positions.size()
	
	# 实例化NewPetBase场景
	var newpet_scene_path = "res://Scene/NewPet/NewPetBase.tscn"
	if not ResourceLoader.exists(newpet_scene_path):
		print("错误：找不到NewPetBase场景")
		return
	
	var pet_scene = load(newpet_scene_path)
	var pet_instance = pet_scene.instantiate()
	
	# 设置基本属性
	var pet_name = pet_data.get("pet_name", pet_data.get("pet_type", "巡逻宠物"))
	pet_instance.pet_name = pet_name
	pet_instance.pet_id = pet_data.get("pet_id", "")
	pet_instance.pet_type = pet_data.get("pet_type", "")
	pet_instance.pet_level = pet_data.get("pet_level", 1)
	
	# 设置为巡逻状态
	pet_instance.is_patrolling = true
	
	# 添加到场景
	pet_patrol_points.add_child(pet_instance)
	patrol_pet_instances.append(pet_instance)
	
	# 在添加到场景后设置位置（避免坐标系转换问题）
	pet_instance.global_position = patrol_positions[position_index]
	
	# 设置巡逻中心点
	pet_instance.set_patrol_center(patrol_positions[position_index])
	
	# 应用宠物图片
	var pet_type = pet_data.get("pet_type", "")
	var image_scene_path = _get_pet_image_path(pet_type)
	print("应用宠物图片: " + pet_type + " -> " + image_scene_path)
	
	# 等待一帧确保节点完全添加到场景树
	await get_tree().process_frame
	
	if pet_instance.has_method("apply_pet_image") and image_scene_path != "":
		pet_instance.apply_pet_image(pet_instance, image_scene_path)
		print("宠物图片应用完成")
	else:
		print("无法应用宠物图片: " + str(pet_instance.has_method("apply_pet_image")) + ", " + image_scene_path)
	
	print("创建巡逻宠物成功: " + pet_instance.pet_name + " 在位置" + str(position_index + 1))

# 获取宠物图片路径
func _get_pet_image_path(pet_type: String) -> String:
	print("[调试] 获取宠物图片路径，宠物类型: " + pet_type)
	print("[调试] 服务器pet_config大小: " + str(pet_config.size()))
	
	# 类型映射表
	var type_mapping = {
		"小绿": "大蓝虫", "小蓝": "大蓝虫", "小红": "烈焰鸟", "小黄": "烈焰鸟",
		"小紫": "大蓝虫", "小橙": "烈焰鸟", "小粉": "大蓝虫", "小黑": "大蓝虫",
		"小白": "大蓝虫", "小灰": "大蓝虫", "大甲壳虫": "大蓝虫", "小甲壳虫": "大蓝虫",
		"飞鸟": "烈焰鸟", "小骑士": "大蓝虫", "绿史莱姆": "大蓝虫", "小钻头": "大蓝虫"
	}
	
	# 优先使用本地PetConfig配置（更可靠）
	var local_pet_config = PetConfig.new()
	
	# 首先尝试直接匹配宠物类型
	var config_data = local_pet_config.get_pet_config(pet_type)
	if config_data.has("pet_image") and config_data["pet_image"] != "":
		print("[调试] 从本地配置直接获取图片路径: " + pet_type + " -> " + config_data["pet_image"])
		return config_data["pet_image"]
	
	# 如果直接匹配失败，使用类型映射
	var mapped_type = type_mapping.get(pet_type, "大蓝虫")
	#print("[调试] 使用类型映射: " + pet_type + " -> " + mapped_type)
	
	config_data = local_pet_config.get_pet_config(mapped_type)
	if config_data.has("pet_image") and config_data["pet_image"] != "":
		#print("[调试] 从本地配置获取映射图片路径: " + mapped_type + " -> " + config_data["pet_image"])
		return config_data["pet_image"]
	
	# 检查服务器配置（作为备选）
	if pet_config.has(pet_type):
		var server_config_data = pet_config[pet_type]
		if server_config_data.has("pet_image") and server_config_data["pet_image"] != "":
			#print("[调试] 从服务器配置获取图片路径: " + pet_type + " -> " + server_config_data["pet_image"])
			return server_config_data["pet_image"]
	
	if pet_config.has(mapped_type):
		var server_config_data = pet_config[mapped_type]
		if server_config_data.has("pet_image") and server_config_data["pet_image"] != "":
			#print("[调试] 从服务器配置获取映射图片路径: " + mapped_type + " -> " + server_config_data["pet_image"])
			return server_config_data["pet_image"]
	
	# 默认返回大蓝虫场景
	print("[调试] 使用默认图片路径: big_beetle.tscn")
	return "res://Scene/NewPet/PetType/big_beetle.tscn"

# 更新巡逻宠物（从服务器数据）
func update_patrol_pets(patrol_pets_data: Array):
	# 清除现有巡逻宠物
	clear_patrol_pets()
	
	print("[update_patrol_pets] 开始更新巡逻宠物，输入数据量: ", patrol_pets_data.size())
	print("[update_patrol_pets] 当前访问模式: ", is_visiting_mode)
	
	# 限制最多4个巡逻宠物
	var max_pets = min(patrol_pets_data.size(), 4)
	
	# 为每个巡逻宠物创建实例
	for i in range(max_pets):
		var pet_data = patrol_pets_data[i]
		print("[update_patrol_pets] 处理宠物", i, ": ", pet_data.get("pet_name", "未知") if pet_data else "空数据")
		if pet_data and pet_data.has("pet_id"):
			_create_single_patrol_pet(pet_data, i)
		else:
			print("[update_patrol_pets] 跳过无效宠物数据")
	
	print("更新巡逻宠物完成，共创建 " + str(max_pets) + " 个巡逻宠物")

# 清除所有巡逻宠物
func clear_patrol_pets():
	for pet_instance in patrol_pet_instances:
		if pet_instance and is_instance_valid(pet_instance):
			pet_instance.queue_free()
	patrol_pet_instances.clear()

# 根据宠物ID查找宠物数据
func get_pet_data_by_id(pet_id: String) -> Dictionary:
	if pet_bag == null:
		return {}
	
	for pet_data in pet_bag:
		var current_id = pet_data.get("pet_id", "")
		if current_id == pet_id:
			return pet_data
	return {}

# 初始化巡逻宠物
func init_patrol_pets():
	# 使用新的更新函数来初始化巡逻宠物
	update_patrol_pets(patrol_pets)

# 检查出战宠物和巡逻宠物是否冲突
func check_battle_patrol_conflict(battle_pet_id: String, patrol_pet_id: String) -> bool:
	return battle_pet_id == patrol_pet_id

#===============================================巡逻宠物管理===============================================



#====================================偷菜被发现-宠物对战处理=========================================
# 处理偷菜被发现响应
func _handle_steal_caught_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var has_battle_pet = data.get("has_battle_pet", false)
	
	if not success:
		if has_battle_pet:
			# 有出战宠物，显示对战选择弹窗
			var patrol_pet_data = data.get("patrol_pet_data", {})
			var battle_pet_data = data.get("battle_pet_data", {})
			var escape_cost = data.get("escape_cost", 1000)
			var battle_cost = data.get("battle_cost", 1300)
			var target_username = data.get("target_username", "")
			var current_username = data.get("current_username", "")
			
			_show_steal_caught_dialog(
				message, 
				patrol_pet_data, 
				battle_pet_data, 
				escape_cost, 
				battle_cost,
				target_username,
				current_username
			)
		else:
			# 没有出战宠物，直接显示逃跑结果
			var updated_data = data.get("updated_data", {})
			if updated_data.has("钱币"):
				money = updated_data["钱币"]
				_update_ui()
			Toast.show(message, Color.RED, 3.0)
	else:
		# 成功情况的处理（如果有的话）
		Toast.show(message, Color.GREEN)

# 显示偷菜被发现对话框
func _show_steal_caught_dialog(message: String, patrol_pet_data: Dictionary, battle_pet_data: Dictionary, escape_cost: int, battle_cost: int, target_username: String, current_username: String):
	# 使用AcceptDialog创建对战选择弹窗
	if not accept_dialog:
		print("错误：找不到AcceptDialog")
		return
	
	# 构建对话框内容
	var dialog_content = message + "\n\n"
	
	# 显示对方的巡逻宠物（所有）
	dialog_content += "🛡️ " + target_username + "的巡逻宠物：\n"
	var defender_pets = visited_player_data.get("巡逻宠物", [patrol_pet_data])
	for i in range(min(4, defender_pets.size())):
		var pet = defender_pets[i]
		var pet_name = pet.get("pet_name", "未知宠物")
		var pet_level = pet.get("pet_level", 1)
		var pet_type = pet.get("pet_type", "未知类型")
		dialog_content += "   %d. %s (类型:%s, 等级:%d)\n" % [i+1, pet_name, pet_type, pet_level]
	
	dialog_content += "\n⚔️ 你的出战宠物：\n"
	# 显示自己的出战宠物（所有）
	var attacker_pets = battle_pets if battle_pets.size() > 0 else [battle_pet_data]
	for i in range(min(4, attacker_pets.size())):
		var pet = attacker_pets[i]
		var pet_name = pet.get("pet_name", "未知宠物")
		var pet_level = pet.get("pet_level", 1)
		var pet_type = pet.get("pet_type", "未知类型")
		dialog_content += "   %d. %s (类型:%s, 等级:%d)\n" % [i+1, pet_name, pet_type, pet_level]
	
	dialog_content += "\n请选择你的行动：\n"
	dialog_content += "💰 逃跑：支付 " + str(escape_cost) + " 金币\n"
	dialog_content += "⚔️ 对战：如果失败支付 " + str(battle_cost) + " 金币"
	
	# 设置对话框
	accept_dialog.set_dialog_title("偷菜被发现！")
	accept_dialog.set_dialog_content(dialog_content)
	accept_dialog.set_ok_text("宠物对战")
	accept_dialog.set_cancel_text("逃跑")
	
	# 清除之前的信号连接
	if accept_dialog.confirmed.is_connected(_on_steal_battle_confirmed):
		accept_dialog.confirmed.disconnect(_on_steal_battle_confirmed)
	if accept_dialog.canceled.is_connected(_on_steal_escape_confirmed):
		accept_dialog.canceled.disconnect(_on_steal_escape_confirmed)
	
	# 连接新的信号处理
	accept_dialog.confirmed.connect(_on_steal_battle_confirmed.bind(patrol_pet_data, battle_pet_data, target_username))
	accept_dialog.canceled.connect(_on_steal_escape_confirmed.bind(escape_cost))
	
	# 居中显示对话框
	var screen_size = get_viewport().get_visible_rect().size
	var dialog_pos = Vector2(
		(screen_size.x - 500) / 2,  # 假设对话框宽度为500
		(screen_size.y - 400) / 2   # 假设对话框高度为400
	)
	accept_dialog.set_dialog_position(dialog_pos)
	
	# 显示对话框
	accept_dialog.popup_centered()
	print("显示偷菜被发现对话框")

# 玩家选择宠物对战
func _on_steal_battle_confirmed(patrol_pet_data: Dictionary, battle_pet_data: Dictionary, target_username: String):
	print("玩家选择宠物对战")
	
	# 验证宠物数据完整性（新格式）
	var battle_pet_id = battle_pet_data.get("pet_id", "")
	var patrol_pet_id = patrol_pet_data.get("pet_id", "")
	
	if battle_pet_id == "" or patrol_pet_id == "":
		Toast.show("宠物数据不完整，无法开始对战", Color.RED, 3.0)
		return
	
	# 检查是否为同一个宠物
	if check_battle_patrol_conflict(battle_pet_id, patrol_pet_id):
		Toast.show("出战宠物和巡逻宠物不能为同一个！", Color.RED, 3.0)
		return
	
	# 停止宠物对战面板的自动对战逻辑
	if pet_battle_panel and pet_battle_panel.has_method("stop_auto_battle"):
		pet_battle_panel.stop_auto_battle()
	
	# 加载双方宠物数据到对战面板
	if pet_battle_panel and pet_battle_panel.has_method("setup_steal_battle"):
		# 传递完整的出战宠物数组和巡逻宠物数组
		var attacker_pets = battle_pets if battle_pets.size() > 0 else [battle_pet_data]
		var defender_pets = visited_player_data.get("巡逻宠物", [patrol_pet_data])
		pet_battle_panel.setup_steal_battle(attacker_pets, defender_pets, user_name, target_username)
	
	# 显示宠物对战面板
	pet_battle_panel.show()
	GlobalVariables.isZoomDisabled = true
	
	Toast.show("准备进入宠物对战！", Color.YELLOW, 2.0)

# 玩家选择逃跑
func _on_steal_escape_confirmed(escape_cost: int):
	print("玩家选择逃跑，支付", escape_cost, "金币")
	
	
	# 扣除金币
	money -= escape_cost
	_update_ui()
	
	Toast.show("支付了 " + str(escape_cost) + " 金币逃跑成功", Color.ORANGE, 3.0)
#====================================偷菜被发现-宠物对战处理=========================================


#========================访问模式直接向巡逻宠物发起战斗========================
func _on_battle_button_pressed() -> void:
	# 检查是否为访问模式
	if not is_visiting_mode:
		Toast.show("只有在访问模式下才能向巡逻宠物发起对战", Color.ORANGE, 3.0)
		return
	
	# 检查对方是否有巡逻宠物
	if not visited_player_data.has("巡逻宠物") or visited_player_data["巡逻宠物"].size() == 0:
		Toast.show("对方没有巡逻宠物，无法发起对战", Color.RED, 3.0)
		return
	
	# 检查自己是否有出战宠物
	if not battle_pets or battle_pets.size() == 0:
		Toast.show("你没有出战宠物，无法发起对战", Color.RED, 3.0)
		return
	
	# 获取对方的巡逻宠物数据（取第一个）- 新格式
	var target_patrol_pet = visited_player_data["巡逻宠物"][0]
	var target_patrol_pet_name = target_patrol_pet.get("pet_name", "未知宠物")
	var target_patrol_pet_level = target_patrol_pet.get("pet_level", 1)
	var target_patrol_pet_type = target_patrol_pet.get("pet_type", "未知类型")
	
	# 获取自己的出战宠物数据（取第一个）- 新格式
	var my_battle_pet = battle_pets[0]
	var my_battle_pet_name = my_battle_pet.get("pet_name", "未知宠物")
	var my_battle_pet_level = my_battle_pet.get("pet_level", 1)
	var my_battle_pet_type = my_battle_pet.get("pet_type", "未知类型")
	
	# 检查是否为同一个宠物（防止冲突）- 新格式
	var my_battle_pet_id = my_battle_pet.get("pet_id", "")
	var target_patrol_pet_id = target_patrol_pet.get("pet_id", "")
	if check_battle_patrol_conflict(my_battle_pet_id, target_patrol_pet_id):
		Toast.show("出战宠物和巡逻宠物不能为同一个！", Color.RED, 3.0)
		return
	
	# 显示对战确认弹窗
	_show_battle_confirmation_dialog(
		target_patrol_pet, 
		my_battle_pet, 
		visited_player_data.get("玩家昵称", "未知玩家")
	)

# 显示对战确认弹窗
func _show_battle_confirmation_dialog(target_patrol_pet: Dictionary, my_battle_pet: Dictionary, target_player_name: String) -> void:
	# 构建对话框内容
	var dialog_content = "确定要向 %s 的巡逻宠物发起对战吗？\n\n" % target_player_name
	
	# 显示对方的巡逻宠物（所有）
	dialog_content += "🛡️ 对方巡逻宠物：\n"
	var defender_pets = visited_player_data.get("巡逻宠物", [target_patrol_pet])
	for i in range(min(4, defender_pets.size())):
		var pet = defender_pets[i]
		var pet_name = pet.get("pet_name", "未知宠物")
		var pet_level = pet.get("pet_level", 1)
		var pet_type = pet.get("pet_type", "未知类型")
		dialog_content += "   %d. %s (类型:%s, 等级:%d)\n" % [i+1, pet_name, pet_type, pet_level]
	
	dialog_content += "\n⚔️ 你的出战宠物：\n"
	# 显示自己的出战宠物（所有）
	var attacker_pets = battle_pets if battle_pets.size() > 0 else [my_battle_pet]
	for i in range(min(4, attacker_pets.size())):
		var pet = attacker_pets[i]
		var pet_name = pet.get("pet_name", "未知宠物")
		var pet_level = pet.get("pet_level", 1)
		var pet_type = pet.get("pet_type", "未知类型")
		dialog_content += "   %d. %s (类型:%s, 等级:%d)\n" % [i+1, pet_name, pet_type, pet_level]
	
	dialog_content += "\n⚠️ 注意：对战失败可能会有惩罚！"
	
	# 使用现有的accept_dialog
	if not accept_dialog:
		Toast.show("对话框不可用", Color.RED, 2.0)
		return
	
	# 清除之前的信号连接
	if accept_dialog.confirmed.is_connected(_on_direct_battle_confirmed):
		accept_dialog.confirmed.disconnect(_on_direct_battle_confirmed)
	if accept_dialog.canceled.is_connected(_on_direct_battle_canceled):
		accept_dialog.canceled.disconnect(_on_direct_battle_canceled)
	
	# 设置对话框内容
	accept_dialog.set_dialog_title("宠物对战确认")
	accept_dialog.set_dialog_content(dialog_content)
	accept_dialog.set_ok_text("发起对战")
	accept_dialog.set_cancel_text("取消")
	
	# 连接信号
	accept_dialog.confirmed.connect(_on_direct_battle_confirmed.bind(target_patrol_pet, my_battle_pet))
	accept_dialog.canceled.connect(_on_direct_battle_canceled)
	
	# 显示对话框
	accept_dialog.popup_centered()

# 确认发起对战
func _on_direct_battle_confirmed(target_patrol_pet: Dictionary, my_battle_pet: Dictionary) -> void:
	# 获取玩家名称
	var my_name = show_player_name.text.replace("玩家昵称：", "")
	var target_name = visited_player_data.get("玩家昵称", "对方")
	
	# 设置对战面板数据
	pet_battle_panel.setup_steal_battle(
		battle_pets,  # 传递完整的出战宠物数组
		visited_player_data.get("巡逻宠物", [target_patrol_pet]),  # 传递完整的巡逻宠物数组
		my_name,
		target_name
	)
	
	# 显示对战面板
	pet_battle_panel.show()
	GlobalVariables.isZoomDisabled = true
	
	Toast.show("对战开始！", Color.GREEN, 2.0)

# 取消发起对战
func _on_direct_battle_canceled() -> void:
	Toast.show("已取消对战", Color.GRAY, 2.0)

# 更新对战按钮显示状态
func _update_battle_button_visibility() -> void:
	
	# 检查对方是否有巡逻宠物
	var has_patrol_pets = visited_player_data.has("巡逻宠物") and visited_player_data["巡逻宠物"].size() > 0
	
	# 检查自己是否有出战宠物
	var has_battle_pets = battle_pets and battle_pets.size() > 0
	
	# 只有当对方有巡逻宠物且自己有出战宠物时才显示对战按钮
	if has_patrol_pets and has_battle_pets:
		battle_button.show()
	else:
		battle_button.hide()
#========================访问模式直接向巡逻宠物发起战斗========================




#=======================================智慧树系统=========================================
#智慧树按钮点击
func _on_wisdom_tree_pressed() -> void:
	if is_visiting_mode:
		Toast.show("访问模式不能打开智慧树配置面板",Color.RED)
		return
	wisdom_tree_panel.show()

# 更新智慧树显示
func update_wisdom_tree_display():
	var config = login_data.get("智慧树配置", {})
	if config.is_empty():
		return
	_update_wisdom_tree_display(_ensure_wisdom_tree_config_format(config))

# 更新智慧树显示（统一处理）
func _update_wisdom_tree_display(config: Dictionary):
	var level = config.get("等级", 1)
	var height = config.get("高度", 20)
	var current_health = config.get("当前生命值", 100)
	var max_health = config.get("最大生命值", 100)
	var message = config.get("智慧树显示的话", "")
	
	if tree_status:
		tree_status.text = "等级lv：" + str(level) + "  高度：" + str(height) + "cm"
	
	if wisdom_tree_image:
		
		if current_health <= 0:
			wisdom_tree_image.self_modulate = Color(0.5, 0.5, 0.5)
		elif current_health <= max_health * 0.3:
			wisdom_tree_image.self_modulate = Color(1.0, 0.8, 0.8)
		else:
			wisdom_tree_image.self_modulate = Color.WHITE
	
	if anonymous_talk:
		if is_visiting_mode:
			anonymous_talk.hide()
		elif message != "":
			anonymous_talk.show()
			var time_str = Time.get_datetime_string_from_system().replace(" ", " ")
			anonymous_talk.text = "[color=cyan][" + time_str + "][/color] " + message
		else:
			anonymous_talk.show()
			anonymous_talk.text = "给未来的某个陌生人说一句话吧"

# 显示随机智慧树消息
func show_random_wisdom_tree_message():
	if tcp_network_manager_panel:
		tcp_network_manager_panel.send_wisdom_tree_operation("get_random_message")

# 处理智慧树响应消息
func handle_wisdom_tree_response(data: Dictionary):
	var message_type = data.get("operation_type", "")
	var message_content = data.get("random_message", "")
	
	if message_type == "play_music" and message_content != "" and anonymous_talk:
		var time_str = Time.get_datetime_string_from_system().replace(" ", " ")
		anonymous_talk.text = "[color=cyan][" + time_str + "][/color] " + message_content
		
		if login_data.has("智慧树配置"):
			login_data["智慧树配置"]["智慧树显示的话"] = message_content

# 确保智慧树配置格式正确
func _ensure_wisdom_tree_config_format(config: Dictionary) -> Dictionary:
	var new_config = config.duplicate()
	# 确保必需字段
	for key in ["当前生命值", "最大生命值", "当前经验值"]:
		if not new_config.has(key):
			new_config[key] = 100 if "生命" in key else 0
	
	if not new_config.has("最大经验值"):
		var level = new_config.get("等级", 1)
		new_config["最大经验值"] = int(50 * pow(level, 1.5) * 1.2)
	
	return new_config

# 处理智慧树配置响应
func _handle_wisdom_tree_config_response(data):
	if data.get("success", false):
		var config = _ensure_wisdom_tree_config_format(data.get("config", {}))
		login_data["智慧树配置"] = config
		update_wisdom_tree_display()
		
		var wisdom_tree_panel = get_node_or_null("BigPanel/SmallPanel/WisdomTreePanel")
		if wisdom_tree_panel and wisdom_tree_panel.visible:
			wisdom_tree_panel.wisdom_tree_config = config
			wisdom_tree_panel.update_ui()
# ======================================= 智慧树系统 ========================================= 


# ======================================= 天气系统 =========================================
# 处理天气变更
func _handle_weather_change(weather_type: String, weather_name: String):
	"""处理服务器发送的天气变更消息"""
	if weather_system and weather_system.has_method("set_weather"):
		weather_system.set_weather(weather_type)
		print("天气已切换为：", weather_name)
	else:
		print("天气系统不可用")
# ======================================= 天气系统 =========================================


# ======================================= 游戏设置系统 =========================================
# 处理游戏设置保存响应
func _handle_save_game_settings_response(data):
	"""处理服务器返回的游戏设置保存响应"""
	var success = data.get("success", false)
	var message = data.get("message", "")
	var settings = data.get("settings", {})
	
	if success:
		# 设置保存成功，更新本地设置面板
		if game_setting_panel and game_setting_panel.has_method("apply_settings_from_server"):
			game_setting_panel.apply_settings_from_server(settings)
		
		Toast.show("游戏设置保存成功", Color.GREEN)
		print("游戏设置保存成功: ", settings)
	else:
		Toast.show("游戏设置保存失败: " + message, Color.RED)
		print("游戏设置保存失败: ", message)
# ======================================= 游戏设置系统 =========================================


#打开小卖部面板
func _on_my_store_button_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人小卖部",Color.RED)
		return
	player_store_panel.show()
	pass

#打开小卖部面板
func _on_player_store_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人小卖部",Color.RED)
		return
	player_store_panel.show()
	pass 

#打开种子商店
func _on_seed_store_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人种子商店",Color.RED)
		return
	crop_store_panel.show()
	pass 

#打开道具商店
func _on_item_store_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人道具商店",Color.RED)
		return
	item_store_panel.show()
	pass 

#打开宠物商店
func _on_pet_store_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人宠物商店",Color.RED)
		return
	pet_store_panel.show()
	pass

#打开作物仓库
func _on_crop_warehouse_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人作物仓库",Color.RED)
		return
	crop_warehouse_panel.show()
	pass 

#打开种子仓库
func _on_seed_warehouse_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人种子仓库",Color.RED)
		return	
	crop_store_panel.show()
	pass 

#打开玩家排行榜
func _on_player_rank_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人玩家排行榜",Color.RED)
		return
	player_ranking_panel.show()
	pass 

#打开每日签到
func _on_daily_checkin_gift_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人每日签到礼包",Color.RED)
		return
	daily_check_in_panel.show()
	pass 

#打开在线礼包
func _on_online_time_gift_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人在线时长礼包",Color.RED)
		return
	online_gift_panel.show()
	pass 

#打开宠物背包
func _on_pet_bag_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人宠物背包",Color.RED)
		return
	pet_bag_panel.show()
	pass 

#打开道具背包
func _on_item_bag_pressed() -> void:
	if is_visiting_mode:
		Toast.show("您不能访问他人道具背包",Color.RED)
		return
	item_bag_panel.show()
	pass

# ======================================= 宠物对战系统 =========================================
# 处理宠物对战结束
func _on_pet_battle_ended(winner_team: String, battle_data: Dictionary):
	"""处理宠物对战结束后的逻辑"""
	print("[宠物对战] 对战结束，获胜方: ", winner_team)
	print("[宠物对战] 对战数据: ", battle_data)
	
	# 准备发送到服务器的对战结果数据
	var battle_result = {
		"winner_team": winner_team,
		"attacker_name": user_name,  # 攻击方（玩家自己）
		"defender_name": visited_player_data.get("玩家昵称", "未知玩家"),  # 防守方（被访问玩家）
		"battle_type": "steal_battle",  # 对战类型：偷菜对战
		"attacker_pets": battle_data.get("attacker_pets", []),  # 攻击方宠物数据
		"defender_pets": battle_data.get("defender_pets", []),  # 防守方宠物数据
		"battle_duration": battle_data.get("battle_duration", 0),  # 对战持续时间
		"timestamp": Time.get_unix_time_from_system()  # 对战时间戳
	}
	
	# 发送对战结果到服务器
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("send_pet_battle_result"):
		tcp_network_manager_panel.send_pet_battle_result(battle_result)
		print("[宠物对战] 对战结果已发送到服务器")
	else:
		print("[宠物对战] 无法发送对战结果到服务器")
	
	# 显示对战结果提示
	if winner_team == "attacker":
		Toast.show("恭喜！您在偷菜对战中获胜！", Color.GREEN)
	else:
		Toast.show("很遗憾，您在偷菜对战中失败了。", Color.RED)
# ======================================= 宠物对战系统 =========================================

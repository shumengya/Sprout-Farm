extends Node

# 变量定义
@onready var grid_container : GridContainer = $GridContainer  # 农场地块的 GridContainer
@onready var crop_item : Button = $CopyNodes/CropItem
@onready var pet_patrol_path_line: Line2D = $PetPatrolPathLine #宠物农场巡逻线

#显示信息栏
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
@onready var global_server_broadcast: Label = $UI/GUI/GameInfoHBox3/GlobalServerBroadcast # 显示全服大喇叭的最新消息，走马灯式滚动显示
@onready var watch_broadcast_button: Button = $UI/GUI/GameInfoHBox3/WatchBroadcast # 查看大喇叭按钮

@onready var network_status_label :Label = get_node("/root/main/UI/BigPanel/TCPNetworkManagerPanel/StatusLabel")


#一堆按钮 
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
@onready var player_bag_panel: Panel = $UI/BigPanel/PlayerBagPanel  #种子背包面板
@onready var crop_warehouse_panel: Panel = $UI/BigPanel/CropWarehousePanel  #作物仓库面板
@onready var crop_store_panel: Panel = $UI/BigPanel/CropStorePanel  #种子商店面板
@onready var player_ranking_panel: Panel = $UI/BigPanel/PlayerRankingPanel  #玩家排行榜面板
@onready var login_panel: PanelContainer = $UI/BigPanel/LoginPanel  #登录面板
@onready var pet_bag_panel: Panel = $UI/BigPanel/PetBagPanel  #宠物背包面板
@onready var pet_store_panel: Panel = $UI/BigPanel/PetStorePanel  #宠物商店面板
@onready var pet_fight_panel: Panel = $UI/BigPanel/PetFightPanel  #宠物战斗面板
@onready var pet_inform_panel: Panel = $UI/SmallPanel/PetInformPanel #宠物信息面板


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


#各种弹窗
@onready var accept_dialog: AcceptDialog = $UI/DiaLog/AcceptDialog


@onready var load_progress_bar: ProgressBar = $UI/SmallPanel/LoadProgressPanel/LoadProgressBar	#显示加载进度进度条


@onready var game_info_h_box_1: HBoxContainer = $UI/GUI/GameInfoHBox1
@onready var game_info_h_box_2: HBoxContainer = $UI/GUI/GameInfoHBox2
@onready var game_info_h_box_3: HBoxContainer = $UI/GUI/GameInfoHBox3
@onready var farm_v_box: VBoxContainer = $UI/GUI/FarmVBox
@onready var visit_v_box: VBoxContainer = $UI/GUI/VisitVBox
@onready var other_v_box: VBoxContainer = $UI/GUI/OtherVBox



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
var battle_pets : Array = []  # 出战宠物数据

# 道具选择状态
var selected_item_name : String = ""
var is_item_selected : bool = false
#农作物种类JSON
var can_planted_crop : Dictionary = {}
#道具配置数据
var item_config_data : Dictionary = {}
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

# 稻草人话语切换相关
var scare_crow_talk_index: int = 0
var scare_crow_talk_timer: float = 0.0
var scare_crow_talk_interval: float = 3.0  # 每3秒切换一次
var scare_crow_talks_list: Array = []  

#=======================脚本基础方法=======================

func _ready():
	# 显示加载进度面板，隐藏其他所有UI
	load_progress_panel.show()
	load_progress_bar.value = 0
	
	# 初始化调试面板（默认隐藏）
	debug_panel.hide()
	debug_panel_script = debug_panel
	
	# 在加载进度面板上添加调试按钮
	_add_debug_button_to_loading_panel()
	
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
	
	# 启动在线人数更新定时器
	_start_online_players_timer()
	
	# 初始化大喇叭显示（延迟到登录成功后）
	# _init_broadcast_display()
	
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
		
	
	# 稻草人话语切换计时器
	if scare_crow_talks_list.size() > 0 and scare_crow.visible:
		scare_crow_talk_timer += delta
		if scare_crow_talk_timer >= scare_crow_talk_interval:
			scare_crow_talk_timer = 0.0
			_update_scare_crow_talk()
#=======================脚本基础方法=======================


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
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		tcp_network_manager_panel.sendGetOnlinePlayers()
		print("登录成功后请求在线人数更新")
	
	# 其他登录成功后的初始化逻辑可以在这里添加
	start_game = true
	
	# 登录成功后初始化大喇叭显示
	_init_broadcast_display()
	
	# 初始化稻草人显示
	init_scare_crow_config()
	
	# 初始化智慧树显示
	update_wisdom_tree_display()
	
	# 立即请求服务器历史消息以刷新显示
	call_deferred("_request_server_history_for_refresh")


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
		pet_bag = target_player_data.get("宠物背包", [])
		patrol_pets = target_player_data.get("巡逻宠物", [])
		
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
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
		# 初始化巡逻宠物（访问模式）
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
		pet_bag = player_data.get("宠物背包", [])
		patrol_pets = player_data.get("巡逻宠物", [])
		
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
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
		# 初始化巡逻宠物（返回自己农场）
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


#===============================================这个函数也比较重要===============================================
# 处理地块点击事件
func _on_item_selected(index):
	# 检查是否处于一键种植的地块选择模式
	if one_click_plant_panel and one_click_plant_panel.has_method("on_lot_selected"):
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
	# 更新按钮文本
	if land_panel.has_method("_update_button_texts"):
		land_panel._update_button_texts()
#===============================================这个函数也比较重要===============================================


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

#查看全服大喇叭按钮点击事件
func _on_watch_broadcast_button_pressed() -> void:
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = true
	
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
	
	# 检查是否有网络连接
	if not tcp_network_manager_panel.is_connected_to_server():
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
	global_server_broadcast_panel.hide()
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


#==========================打开基础面板================================
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
	var network_manager = get_node("/root/main/UI/TCPNerworkManager")
	if network_manager and network_manager.is_connected_to_server():
		# 从服务器请求作物数据
		network_manager.sendGetCropData()
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
	
	# 如果缓存文件不存在或解析失败，加载默认数据
	file = FileAccess.open("user://crop_data.json", FileAccess.READ)
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
		print("种子商店已根据作物数据重新初始化")
	
	if player_bag_panel and player_bag_panel.has_method("update_player_bag_ui"):
		player_bag_panel.update_player_bag_ui()
		print("种子背包已根据作物数据重新初始化")
	
	if crop_warehouse_panel and crop_warehouse_panel.has_method("update_crop_warehouse_ui"):
		crop_warehouse_panel.update_crop_warehouse_ui()
		print("作物仓库已根据作物数据重新初始化")
	
	if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
		item_bag_panel.update_item_bag_ui()
		print("道具背包已根据作物数据重新初始化")
	
	if item_store_panel and item_store_panel.has_method("init_item_store"):
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
	
	# 如果缓存文件不存在或解析失败，加载默认数据
	file = FileAccess.open("user://item_config.json", FileAccess.READ)
	if not file:
		print("无法读取默认道具配置文件！")
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("默认道具配置数据JSON解析错误：", json.get_error_message())
		return
		
	item_config_data = json.get_data()
	print("已加载默认道具配置数据")
	_refresh_ui_after_item_config_loaded()

# 道具配置数据加载后刷新UI
func _refresh_ui_after_item_config_loaded():
	# 重新初始化道具相关UI
	if item_store_panel and item_store_panel.has_method("init_item_store"):
		item_store_panel.init_item_store()
		print("道具商店已根据道具配置数据重新初始化")
	
	if item_bag_panel and item_bag_panel.has_method("update_item_bag_ui"):
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

#===============================================初始化数据处理===============================================



#===============================================作物图片缓存系统===============================================

## 优化的作物图片缓存和管理系统
class CropTextureManager:
	
	# 缓存字典
	var texture_cache: Dictionary = {}          # 序列帧缓存 {crop_name: [Texture2D]}
	var mature_texture_cache: Dictionary = {}   # 成熟图片缓存 {crop_name: Texture2D}
	var frame_counts: Dictionary = {}           # 帧数记录 {crop_name: int}
	var failed_resources: Array = []           # 记录加载失败的资源路径
	
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
	
	# 调试面板引用
	var debug_panel_ref = null
	
	# 内存管理
	var max_cache_size: int = 200  # 最大缓存图片数量
	var cache_access_order: Array = []  # LRU缓存访问顺序
	
	func _init():
		print("[CropTextureManager] 初始化优化的作物图片管理器")
		loading_mutex = Mutex.new()
		results_mutex = Mutex.new()
		# 根据设备性能动态调整线程数
		_adjust_thread_count()
		# 尝试获取调试面板引用
		_connect_debug_panel()
	
	## 根据设备性能调整线程数
	func _adjust_thread_count():
		var platform = OS.get_name()
		var processor_count = OS.get_processor_count()
		
		match platform:
			"Android", "iOS":
				# 移动设备使用较少线程，避免过热和电量消耗
				max_threads = min(2, max(1, processor_count / 2))
			"Windows", "Linux", "macOS":
				# 桌面设备可以使用更多线程
				max_threads = min(6, max(2, processor_count - 1))
			_:
				max_threads = 2
		
		print("[CropTextureManager] 设备: %s, CPU核心: %d, 使用线程数: %d" % [platform, processor_count, max_threads])
	
	## 连接调试面板
	func _connect_debug_panel():
		# 延迟获取调试面板引用，因为初始化时可能还未创建
		call_deferred("_try_get_debug_panel")
	
	## 尝试获取调试面板引用
	func _try_get_debug_panel():
		var main_node = Engine.get_main_loop().current_scene
		if main_node:
			debug_panel_ref = main_node.get_node_or_null("UI/SmallPanel/DebugPanel")
			if debug_panel_ref:
				print("[CropTextureManager] 已连接到调试面板")
	
	## 向调试面板发送消息
	func _send_debug_message(message: String, color: Color = Color.WHITE):
		if debug_panel_ref and debug_panel_ref.has_method("add_debug_message"):
			debug_panel_ref.add_debug_message(message, color)
	
	## 设置当前加载项目
	func _set_current_loading_item(item_name: String):
		if debug_panel_ref and debug_panel_ref.has_method("set_current_loading_item"):
			debug_panel_ref.set_current_loading_item(item_name)
	
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
		_send_debug_message("开始预加载 %d 种作物图片" % total_crops, Color.CYAN)
		
		# 阶段1：加载默认图片 (0-10%)
		progress_callback.call(0, "正在加载默认图片...")
		_send_debug_message("阶段1: 加载默认图片", Color.YELLOW)
		await _load_default_textures_async()
		progress_callback.call(10, "默认图片加载完成")
		_send_debug_message("默认图片加载完成", Color.GREEN)
		
		# 阶段2：多线程批量加载作物图片 (10-90%)
		_send_debug_message("阶段2: 多线程加载作物图片", Color.YELLOW)
		await _load_crops_multithreaded_async(crop_data, progress_callback)
		
		# 阶段3：完成 (90-100%)
		progress_callback.call(100, "所有作物图片加载完成！")
		_print_cache_stats()
		_send_debug_message("所有作物图片加载完成！", Color.GREEN)
		
		# 清理线程
		await _cleanup_threads()
		
		is_loading = false
		var success_message = "预加载完成，成功: %d, 失败: %d" % [loaded_crops, failed_crops]
		print("[CropTextureManager] " + success_message)
		_send_debug_message(success_message, Color.CYAN)
	
	## 多线程批量异步加载作物图片
	func _load_crops_multithreaded_async(crop_data: Dictionary, progress_callback: Callable) -> void:
		var crop_names = crop_data.keys()
		
		# 准备加载队列
		loading_mutex.lock()
		loading_queue.clear()
		for crop_name in crop_names:
			loading_queue.append({
				"crop_name": crop_name,
				"type": "sequence"
			})
			loading_queue.append({
				"crop_name": crop_name,
				"type": "mature"
			})
		loading_mutex.unlock()
		
		# 启动工作线程
		_send_debug_message("启动 %d 个工作线程" % max_threads, Color.CYAN)
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
		var task_type = task["type"]
		var result = {
			"crop_name": crop_name,
			"type": task_type,
			"success": false,
			"textures": [],
			"texture": null,
			"error": ""
		}
		
		if task_type == "sequence":
			result["textures"] = _load_crop_textures_threadsafe(crop_name)
			result["success"] = result["textures"].size() > 0
		elif task_type == "mature":
			result["texture"] = _load_mature_texture_threadsafe(crop_name)
			result["success"] = result["texture"] != null
		
		# 检查加载是否成功
		if not result["success"]:
			result["error"] = "加载失败: " + crop_name
			failed_resources.append(crop_name)
		
		return result
	
	## 线程安全的作物序列帧加载
	func _load_crop_textures_threadsafe(crop_name: String) -> Array:
		var textures = []
		var crop_path = "res://assets/作物/" + crop_name + "/"
		
		# 检查作物文件夹是否存在
		if not DirAccess.dir_exists_absolute(crop_path):
			return []
		
		# 使用ResourceLoader.load_threaded_request进行异步加载
		var frame_index = 0
		var max_frames = 20  # 限制最大帧数，避免无限循环
		
		while frame_index < max_frames:
			var texture_path = crop_path + str(frame_index) + ".webp"
			
			if not ResourceLoader.exists(texture_path):
				break
			
			# 使用线程安全的资源加载
			var texture = _load_resource_safe(texture_path)
			if texture:
				textures.append(texture)
				frame_index += 1
			else:
				break
		
		return textures
	
	## 线程安全的成熟图片加载
	func _load_mature_texture_threadsafe(crop_name: String) -> Texture2D:
		var crop_path = "res://assets/作物/" + crop_name + "/"
		var mature_path = crop_path + "成熟.webp"
		
		if ResourceLoader.exists(mature_path):
			return _load_resource_safe(mature_path)
		
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
		var task_type = result["type"]
		var success = result["success"]
		
		if not success:
			var error_msg = "加载失败: %s (%s)" % [crop_name, task_type]
			_send_debug_message(error_msg, Color.RED)
			return
		
		if task_type == "sequence":
			var textures = result["textures"]
			if textures.size() > 0:
				texture_cache[crop_name] = textures
				frame_counts[crop_name] = textures.size()
				_update_cache_access(crop_name)
				_send_debug_message("✓ %s: %d帧" % [crop_name, textures.size()], Color.GREEN)
		elif task_type == "mature":
			var texture = result["texture"]
			if texture:
				mature_texture_cache[crop_name] = texture
				_update_cache_access(crop_name + "_mature")
				_send_debug_message("✓ %s: 成熟图片" % crop_name, Color.GREEN)
		
		# 检查缓存大小，必要时清理
		_check_and_cleanup_cache()
	
	## 立即加载默认图片（同步，但优化）
	func _load_default_textures_async() -> void:
		const DEFAULT_CROP = "默认"
		const DEFAULT_PATH = "res://assets/作物/默认/"
		
		if texture_cache.has(DEFAULT_CROP):
			return
		
		var textures = []
		var frame_index = 0
		
		# 限制默认图片帧数
		while frame_index < 10:
			var texture_path = DEFAULT_PATH + str(frame_index) + ".webp"
			if ResourceLoader.exists(texture_path):
				var texture = _load_resource_safe(texture_path)
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
				var texture = _load_resource_safe(single_path)
				if texture:
					textures.append(texture)
		
		# 缓存结果
		if textures.size() > 0:
			texture_cache[DEFAULT_CROP] = textures
			frame_counts[DEFAULT_CROP] = textures.size()
		
		# 加载默认成熟图片
		var mature_path = DEFAULT_PATH + "成熟.webp"
		if ResourceLoader.exists(mature_path):
			var mature_texture = _load_resource_safe(mature_path)
			if mature_texture:
				mature_texture_cache[DEFAULT_CROP] = mature_texture
		
		print("[CropTextureManager] 默认图片加载完成：%d 帧" % textures.size())
		
		# 让出一帧
		await Engine.get_main_loop().process_frame
	
	## 更新缓存访问顺序（LRU）
	func _update_cache_access(key: String):
		if key in cache_access_order:
			cache_access_order.erase(key)
		cache_access_order.append(key)
	
	## 检查并清理缓存
	func _check_and_cleanup_cache():
		var total_cached = texture_cache.size() + mature_texture_cache.size()
		
		if total_cached > max_cache_size:
			var to_remove = total_cached - max_cache_size + 10  # 多清理一些
			_send_debug_message("⚠ 缓存超限，开始清理 %d 个项目" % to_remove, Color.ORANGE)
			
			for i in range(min(to_remove, cache_access_order.size())):
				var key = cache_access_order[i]
				
				# 不清理默认图片
				if key.begins_with("默认"):
					continue
				
				if key.ends_with("_mature"):
					var crop_name = key.replace("_mature", "")
					mature_texture_cache.erase(crop_name)
				else:
					texture_cache.erase(key)
					frame_counts.erase(key)
			
			# 更新访问顺序
			cache_access_order = cache_access_order.slice(to_remove)
			
			var current_size = texture_cache.size() + mature_texture_cache.size()
			var cleanup_msg = "缓存清理完成，当前缓存: %d" % current_size
			print("[CropTextureManager] " + cleanup_msg)
			_send_debug_message(cleanup_msg, Color.YELLOW)
	
	## 根据生长进度获取作物图片（带缓存优化）
	func get_texture_by_progress(crop_name: String, progress: float) -> Texture2D:
		# 更新访问记录
		_update_cache_access(crop_name)
		
		# 100%成熟时优先使用成熟图片
		if progress >= 1.0:
			var mature_texture = mature_texture_cache.get(crop_name, null)
			if mature_texture:
				_update_cache_access(crop_name + "_mature")
				return mature_texture
		
		# 使用序列帧图片
		var textures = texture_cache.get(crop_name, [])
		if textures.size() == 0:
			# 如果没有缓存，尝试使用默认图片
			textures = texture_cache.get("默认", [])
			if textures.size() == 0:
				return null
		
		if textures.size() == 1:
			return textures[0]
		
		# 根据进度计算帧索引
		var frame_index = int(progress * (textures.size() - 1))
		frame_index = clamp(frame_index, 0, textures.size() - 1)
		
		return textures[frame_index]
	
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
		mature_texture_cache.clear()
		frame_counts.clear()
		cache_access_order.clear()
		failed_resources.clear()
		print("[CropTextureManager] 缓存已清理")
	
	## 打印缓存统计信息
	func _print_cache_stats() -> void:
		print("[CropTextureManager] 缓存统计:")
		print("  - 序列帧缓存: %d 种作物" % texture_cache.size())
		print("  - 成熟图片缓存: %d 种作物" % mature_texture_cache.size())
		print("  - 加载失败: %d 个资源" % failed_resources.size())
		var total_frames = 0
		for count in frame_counts.values():
			total_frames += count
		print("  - 总图片帧数: %d 帧" % total_frames)
		
		if failed_resources.size() > 0:
			print("  - 失败的资源:")
			for failed in failed_resources:
				print("    * ", failed)
	
	## 获取详细缓存信息
	func get_cache_info() -> String:
		var info = "作物图片缓存详情:\n"
		for crop_name in texture_cache.keys():
			var frame_count = frame_counts.get(crop_name, 0)
			var has_mature = mature_texture_cache.has(crop_name)
			info += "  - %s: %d帧" % [crop_name, frame_count]
			if has_mature:
				info += " (含成熟图片)"
			info += "\n"
		
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
				var textures = _load_crop_textures_threadsafe(crop_name)
				if textures.size() > 0:
					texture_cache[crop_name] = textures
					frame_counts[crop_name] = textures.size()
			
			if not mature_texture_cache.has(crop_name):
				var mature = _load_mature_texture_threadsafe(crop_name)
				if mature:
					mature_texture_cache[crop_name] = mature

# 全局作物图片管理器实例
var crop_texture_manager: CropTextureManager

# 资源加载调试器（可选，用于调试）
var resource_debugger = null

# 调试面板脚本引用
var debug_panel_script = null

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
	
	# 向调试面板发送进度信息
	if debug_panel_script and debug_panel_script.has_method("add_debug_message"):
		if message != "":
			debug_panel_script.add_debug_message("进度 %d%%: %s" % [progress, message], Color.CYAN)
	
	# 检测卡顿
	_check_loading_stuck(progress)
	
	if message != "":
		print("[加载进度] %d%% - %s" % [progress, message])

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
			if debug_panel_script and debug_panel_script.has_method("add_debug_message"):
				debug_panel_script.add_debug_message("⚠ 加载卡顿检测: 在 %d%% 停留了 %.1f 秒" % [progress, stuck_time], Color.ORANGE)
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



#===============================================调试和维护工具===============================================

## 调试：打印缓存信息
func _debug_print_crop_cache() -> void:
	if crop_texture_manager:
		print(crop_texture_manager.get_cache_info())
	else:
		print("[调试] 作物图片管理器未初始化")

## 调试：强制刷新所有图片
func _debug_refresh_all_crop_sprites() -> void:
	print("[调试] 强制刷新所有地块图片...")
	_refresh_all_crop_sprites()
	print("[调试] 图片刷新完成")

## 调试：清理图片缓存
func _debug_clear_crop_cache() -> void:
	if crop_texture_manager:
		crop_texture_manager.clear_cache()
		print("[调试] 图片缓存已清理")

## 调试：启用资源加载调试器
func _debug_enable_resource_debugger() -> void:
	if not resource_debugger:
		resource_debugger = preload("res://GlobalScript/ResourceLoadingDebugger.gd").new()
		add_child(resource_debugger)
		print("[调试] 资源加载调试器已启用")
	else:
		print("[调试] 资源加载调试器已经在运行")

## 调试：生成资源加载报告
func _debug_generate_loading_report() -> void:
	if resource_debugger:
		var report = resource_debugger.generate_loading_report()
		print(report)
		resource_debugger.export_debug_data_to_file()
	else:
		print("[调试] 资源加载调试器未启用，请先调用 _debug_enable_resource_debugger()")

## 调试：检测设备能力
func _debug_detect_device_capabilities() -> void:
	if resource_debugger:
		var capabilities = resource_debugger.detect_device_capabilities()
		print("[调试] 设备能力检测结果:")
		for key in capabilities:
			print("  %s: %s" % [key, str(capabilities[key])])
	else:
		print("[调试] 资源加载调试器未启用")

## 调试：强制触发低内存模式
func _debug_trigger_low_memory_mode() -> void:
	if crop_texture_manager:
		# 临时降低缓存大小来模拟低内存环境
		crop_texture_manager.max_cache_size = 50
		crop_texture_manager._check_and_cleanup_cache()
		print("[调试] 已触发低内存模式，缓存大小限制为50")

## 调试：恢复正常内存模式
func _debug_restore_normal_memory_mode() -> void:
	if crop_texture_manager:
		crop_texture_manager.max_cache_size = 200
		print("[调试] 已恢复正常内存模式，缓存大小限制为200")

## 在加载进度面板上添加调试按钮
func _add_debug_button_to_loading_panel():
	# 创建调试按钮
	var debug_button = Button.new()
	debug_button.text = "调试信息"
	debug_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	debug_button.position = Vector2(10, 500)  # 左下角位置
	debug_button.size = Vector2(120, 40)
	
	# 设置按钮样式
	debug_button.modulate = Color(0.8, 0.8, 1.0, 0.9)  # 半透明蓝色
	
	# 连接点击信号
	debug_button.pressed.connect(_on_debug_button_pressed)
	
	# 添加到加载进度面板
	load_progress_panel.add_child(debug_button)
	
	print("[MainGame] 调试按钮已添加到加载进度面板")

## 调试按钮点击处理
func _on_debug_button_pressed():
	if debug_panel.visible:
		debug_panel.hide()
	else:
		debug_panel.show()
		debug_panel.move_to_front()
	print("[MainGame] 调试面板切换显示状态")

#===============================================调试和维护工具===============================================



#===============================================向后兼容性===============================================
# 为了保持向后兼容，保留一些原来的函数名
func _load_crop_textures(crop_name: String) -> Array:
	"""向后兼容：加载作物图片序列帧"""
	if crop_texture_manager:
		return crop_texture_manager._load_crop_textures_threadsafe(crop_name)
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
#===============================================向后兼容性===============================================





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

#===============================================返回自己的农场处理===============================================






#===============================================添加新地块处理===============================================
#添加新的地块，默认花费2000
func _on_add_new_ground_button_pressed() -> void:
	# 如果处于访问模式，不允许操作
	if is_visiting_mode:
		Toast.show("访问模式下无法购买新地块", Color.ORANGE)
		return
	
	# 检查是否有网络连接
	if not tcp_network_manager_panel.is_connected_to_server():
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
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendBuyNewGround"):
		var success = tcp_network_manager_panel.sendBuyNewGround()
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
	if not tcp_network_manager_panel.is_connected_to_server():
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
	if not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接服务器，无法点赞", Color.RED)
		return
	
	# 获取被访问玩家的用户名
	var target_username = visited_player_data.get("user_name", "")
	if target_username == "":
		Toast.show("无法获取目标玩家信息", Color.RED)
		return
	
	# 发送点赞请求
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendLikePlayer"):
		var success = tcp_network_manager_panel.sendLikePlayer(target_username)
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
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("网络未连接，无法领取新手大礼包", Color.RED, 2.0, 1.0)
		return
	
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
	if tcp_network_manager_panel and tcp_network_manager_panel.sendClaimNewPlayerGift():
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
		if updated_data.has("宠物背包"):
			pet_bag = updated_data["宠物背包"]
		
		# 隐藏新手大礼包按钮
		var new_player_gift_button = find_child("NewPlayerGiftButton")
		if new_player_gift_button:
			new_player_gift_button.hide()
		
		# 更新UI
		_update_ui()
		
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
		
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



#====================================全服大喇叭处理=========================================
# 处理全服大喇叭消息
func _handle_global_broadcast_message(data: Dictionary):
	# 将消息传递给大喇叭面板处理
	if global_server_broadcast_panel and global_server_broadcast_panel.has_method("receive_broadcast_message"):
		global_server_broadcast_panel.receive_broadcast_message(data)

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
	print("收到历史消息响应: ", data.get("messages", []).size(), " 条消息")
	
	if global_server_broadcast_panel and global_server_broadcast_panel.has_method("receive_history_messages"):
		global_server_broadcast_panel.receive_history_messages(data)
		
		# 更新主界面大喇叭显示为最新消息
		if global_server_broadcast:
			var latest_message = global_server_broadcast_panel.get_latest_message()
			print("获取到的最新消息: ", latest_message)
			if latest_message != "暂无消息":
				global_server_broadcast.text = latest_message
				print("主界面大喇叭已更新为: ", latest_message)
			else:
				global_server_broadcast.text = ""
				print("没有消息，清空主界面大喇叭显示")

# 更新主界面大喇叭显示（超出部分显示...）
func update_broadcast_display(message: String):
	if global_server_broadcast and message != "":
		
		global_server_broadcast.text = message


# 初始化大喇叭显示
func _init_broadcast_display():
	if global_server_broadcast and global_server_broadcast_panel:
		# 先设置为空
		global_server_broadcast.text = ""
		
		# 直接从本地文件加载历史消息
		_load_broadcast_from_local()
		
		# 无论是否有本地消息，都请求服务器获取最新消息
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
					# 按时间戳排序
					data.sort_custom(func(a, b): return a.get("timestamp", 0) < b.get("timestamp", 0))
					# 获取最新消息
					var latest = data[-1]
					var display_name = latest.get("display_name", "匿名")
					var content = latest.get("content", "")
					global_server_broadcast.text = display_name + ": " + content
					print("从本地加载大喇叭消息: ", global_server_broadcast.text)



# 请求服务器获取最新的一条大喇叭消息
func _request_latest_broadcast_message():
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		# 请求最近1天的消息，只获取最新的一条
		var success = tcp_network_manager_panel.send_message({
			"type": "request_broadcast_history",
			"days": 1,
			"limit": 1,  # 只要最新的一条
			"timestamp": Time.get_unix_time_from_system()
		})
		
		if not success:
			print("请求最新大喇叭消息失败")

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
			print("已请求服务器历史消息用于刷新显示")
		else:
			print("请求服务器历史消息失败")

#====================================全服大喇叭处理=========================================



#====================================一键截图处理=========================================
#一键截图按钮,隐藏所有UI，截图，然后保存在相应位置
func _on_one_click_screen_shot_pressed() -> void:
	# 保存当前UI状态
	var ui_state = _save_ui_visibility_state()
	
	# 隐藏所有UI
	_hide_all_ui_for_screenshot()
	

	await get_tree().create_timer(3).timeout
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
		if updated_data.has("宠物背包"):
			pet_bag = updated_data["宠物背包"]
		
		# 更新UI
		_update_ui()
		player_bag_panel.update_player_bag_ui()
		# 更新宠物背包UI
		if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
			pet_bag_panel.update_pet_bag_ui()
	
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

# 处理宠物使用道具响应
func _handle_use_pet_item_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新宠物背包数据
		if updated_data.has("宠物背包"):
			pet_bag = updated_data["宠物背包"]
			
			# 更新宠物背包UI
			if pet_bag_panel and pet_bag_panel.has_method("update_pet_bag_ui"):
				pet_bag_panel.update_pet_bag_ui()
		
		# 更新道具背包数据
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
		# 更新金币
		if updated_data.has("money"):
			money = updated_data["money"]
		
		# 更新经验
		if updated_data.has("experience"):
			experience = updated_data["experience"]
		
		# 更新等级
		if updated_data.has("level"):
			level = updated_data["level"]
		
		# 更新道具背包数据
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

#====================================稻草人系统处理=========================================
# 处理购买稻草人响应
func _handle_buy_scare_crow_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		if updated_data.has("money"):
			money = updated_data["money"]
		if updated_data.has("稻草人配置"):
			# 更新登录数据中的稻草人配置
			login_data["稻草人配置"] = updated_data["稻草人配置"]
			
			# 将稻草人配置传递给稻草人面板
			if scare_crow_panel and scare_crow_panel.has_method("handle_buy_scare_crow_response"):
				scare_crow_panel.handle_buy_scare_crow_response(success, message, updated_data)
		
		# 更新UI
		_update_ui()
		
		# 更新稻草人显示
		update_scare_crow_display()
	else:
		if scare_crow_panel and scare_crow_panel.has_method("handle_buy_scare_crow_response"):
			scare_crow_panel.handle_buy_scare_crow_response(success, message, updated_data)

# 处理修改稻草人配置响应
func _handle_modify_scare_crow_config_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var updated_data = data.get("updated_data", {})
	
	if success:
		# 更新玩家数据
		if updated_data.has("money"):
			money = updated_data["money"]
		if updated_data.has("稻草人配置"):
			# 更新登录数据中的稻草人配置
			login_data["稻草人配置"] = updated_data["稻草人配置"]
			
			# 将稻草人配置传递给稻草人面板
			if scare_crow_panel and scare_crow_panel.has_method("handle_modify_scare_crow_config_response"):
				scare_crow_panel.handle_modify_scare_crow_config_response(success, message, updated_data)
		
		# 更新UI
		_update_ui()
		
		# 更新稻草人显示
		update_scare_crow_display()
	else:
		if scare_crow_panel and scare_crow_panel.has_method("handle_modify_scare_crow_config_response"):
			scare_crow_panel.handle_modify_scare_crow_config_response(success, message, updated_data)

# 处理获取稻草人配置响应
func _handle_get_scare_crow_config_response(data: Dictionary):
	var success = data.get("success", false)
	var scare_crow_config = data.get("scare_crow_config", {})
	
	if success:
		# 更新登录数据中的稻草人配置
		login_data["稻草人配置"] = scare_crow_config
		
		# 将稻草人配置传递给稻草人面板
		if scare_crow_panel and scare_crow_panel.has_method("set_player_scare_crow_config"):
			scare_crow_panel.set_player_scare_crow_config(scare_crow_config)
		
		# 更新稻草人显示
		update_scare_crow_display()

# 更新稻草人显示
func update_scare_crow_display():
	# 始终显示稻草人按钮，这样玩家可以点击进入设置面板
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
	GlobalVariables.isZoomDisabled = true
	scare_crow_panel.show()
	scare_crow_panel.move_to_front()
	pass 

#====================================稻草人系统处理=========================================



#===============================================道具使用处理===============================================
# 在地块上使用道具
func _use_item_on_lot(lot_index: int, item_name: String):
	
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

	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, "fertilize", target_username):
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
	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, "water", target_username):
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
	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, "remove", target_username):
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
	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, "weed_killer", target_username):
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
	
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendUseItem"):
		if tcp_network_manager_panel.sendUseItem(lot_index, item_name, "harvest", target_username):
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




#===============================================巡逻宠物管理===============================================

# 当前巡逻宠物实例（只允许一个）
var current_patrol_pet: CharacterBody2D = null

# 初始化巡逻宠物（登录时调用）
func init_patrol_pets():
	# 确保巡逻宠物数组存在
	if patrol_pets == null:
		patrol_pets = []
	
	# 检查巡逻线设置
	check_patrol_line_setup()
	
	# 更新巡逻宠物显示
	update_patrol_pets()

# 检查巡逻线设置
func check_patrol_line_setup():
	if not pet_patrol_path_line:
		print("错误：找不到巡逻线节点 PetPatrolPathLine，请检查场景设置")
		return
	
	print("巡逻线节点找到: " + pet_patrol_path_line.name)
	print("巡逻路径点数: " + str(pet_patrol_path_line.points.size()))
	
	if pet_patrol_path_line.points.size() == 0:
		print("警告：巡逻线没有设置路径点，将设置默认路径")
		# 设置一个简单的矩形巡逻路径作为默认
		pet_patrol_path_line.points = PackedVector2Array([
			Vector2(100, 100),
			Vector2(300, 100),
			Vector2(300, 300),
			Vector2(100, 300)
		])
		print("已设置默认矩形巡逻路径")
	
	# 设置巡逻线可见性和样式
	pet_patrol_path_line.visible = true
	pet_patrol_path_line.width = 3.0
	pet_patrol_path_line.default_color = Color.YELLOW
	pet_patrol_path_line.closed = true  # 闭合路径
	
	# 打印路径点信息
	for i in range(pet_patrol_path_line.points.size()):
		print("巡逻点 " + str(i) + ": " + str(pet_patrol_path_line.points[i]))
	
	print("巡逻线节点位置: " + str(pet_patrol_path_line.position))
	print("巡逻线节点全局位置: " + str(pet_patrol_path_line.global_position))

# 更新巡逻宠物显示（根据patrol_pets数组创建）
func update_patrol_pets():
	# 先清除现有巡逻宠物
	clear_patrol_pets()
	
	if patrol_pets == null or patrol_pets.size() == 0:
		print("没有巡逻宠物需要显示")
		return
	
	# 目前只支持一个巡逻宠物，取第一个
	var first_patrol_pet = patrol_pets[0]
	var pet_id = first_patrol_pet.get("基本信息", {}).get("宠物ID", "")
	
	if pet_id != "":
		# 直接根据巡逻宠物数据创建（不从宠物背包查找）
		create_patrol_pet_from_data(first_patrol_pet)
	else:
		print("巡逻宠物ID为空")

# 清除巡逻宠物实例
func clear_patrol_pets():
	if current_patrol_pet and is_instance_valid(current_patrol_pet):
		current_patrol_pet.queue_free()
		current_patrol_pet = null
	
	# 清除巡逻线节点下的所有宠物（确保完全清理）
	if pet_patrol_path_line:
		for child in pet_patrol_path_line.get_children():
			if child is CharacterBody2D:
				child.queue_free()
	
	print("已清除巡逻宠物")

# 根据宠物ID设置巡逻宠物
func set_patrol_pet_by_id(pet_id: String):
	if pet_id == "":
		print("警告：宠物ID为空，无法设置巡逻宠物")
		return
	
	# 从宠物背包中查找宠物数据
	var pet_data = find_pet_by_id(pet_id)
	if pet_data.is_empty():
		print("错误：在宠物背包中找不到ID为 " + pet_id + " 的宠物")
		return
	
	# 检查巡逻线节点是否存在
	if not pet_patrol_path_line:
		print("错误：找不到巡逻线节点 PetPatrolPathLine")
		return
	
	# 检查巡逻路径是否设置
	if pet_patrol_path_line.points.size() < 2:
		print("警告：巡逻路径点数少于2个，无法创建巡逻宠物")
		return
	
	# 先清除现有巡逻宠物
	clear_patrol_pets()
	
	# 等待一帧确保旧实例被清理
	await get_tree().process_frame
	
	# 获取宠物场景路径
	var scene_path = pet_data.get("场景路径", "")
	if scene_path == "":
		print("错误：宠物数据中没有场景路径")
		return
	
	# 检查场景文件是否存在
	if not ResourceLoader.exists(scene_path):
		print("错误：宠物场景文件不存在: " + scene_path)
		return
	
	# 加载宠物场景
	var pet_scene = load(scene_path)
	if not pet_scene:
		print("错误：无法加载宠物场景: " + scene_path)
		return
	
	var pet_instance = pet_scene.instantiate()
	if not pet_instance:
		print("错误：无法创建宠物实例")
		return
	
	# 应用宠物数据到实例
	apply_pet_data_to_patrol_instance(pet_instance, pet_data)
	
	# 设置巡逻状态和路径
	pet_instance.is_patrolling = true
	pet_instance.patrol_path = pet_patrol_path_line.points.duplicate()
	pet_instance.patrol_speed = 80.0
	pet_instance.current_patrol_index = 0
	pet_instance.patrol_wait_time = 0.0
	
	# 添加到巡逻线节点下
	pet_patrol_path_line.add_child(pet_instance)
	current_patrol_pet = pet_instance
	
	# 设置初始位置
	pet_instance.position = pet_patrol_path_line.points[0]
	
	var pet_name = pet_data.get("基本信息", {}).get("宠物名称", "未知")
	print("创建巡逻宠物成功: " + pet_name + " (场景: " + scene_path + ")")

# 在宠物背包中根据ID查找宠物数据
func find_pet_by_id(pet_id: String) -> Dictionary:
	if pet_bag == null:
		return {}
	
	for pet_data in pet_bag:
		var current_id = pet_data.get("基本信息", {}).get("宠物ID", "")
		if current_id == pet_id:
			return pet_data
	
	return {}

# 应用宠物数据到巡逻实例
func apply_pet_data_to_patrol_instance(pet_instance: CharacterBody2D, pet_data: Dictionary):
	var basic_info = pet_data.get("基本信息", {})
	var level_exp = pet_data.get("等级经验", {})
	var health_defense = pet_data.get("生命与防御", {})
	
	# 设置基本信息
	var original_name = basic_info.get("宠物名称", basic_info.get("宠物类型", "未知宠物"))
	pet_instance.pet_name = "[巡逻] " + original_name  # 添加巡逻标识
	pet_instance.pet_id = basic_info.get("宠物ID", "")
	pet_instance.pet_type = basic_info.get("宠物类型", "")
	pet_instance.pet_birthday = basic_info.get("生日", "")
	pet_instance.pet_personality = basic_info.get("性格", "活泼")
	pet_instance.pet_team = "patrol"  # 设置为巡逻队伍
	
	# 设置等级经验
	pet_instance.pet_level = level_exp.get("宠物等级", 1)
	pet_instance.pet_experience = level_exp.get("当前经验", 0.0)
	pet_instance.max_experience = level_exp.get("最大经验", 100.0)
	pet_instance.pet_intimacy = level_exp.get("亲密度", 0.0)
	
	# 设置生命防御
	pet_instance.max_health = health_defense.get("最大生命值", 100.0)
	pet_instance.current_health = health_defense.get("当前生命值", pet_instance.max_health)
	pet_instance.max_shield = health_defense.get("最大护盾值", 0.0)
	pet_instance.current_shield = health_defense.get("当前护盾值", 0.0)
	pet_instance.max_armor = health_defense.get("最大护甲值", 0.0)
	pet_instance.current_armor = health_defense.get("当前护甲值", 0.0)
	
	# 禁用战斗行为（巡逻宠物不参与战斗）
	if pet_instance.has_method("set_combat_enabled"):
		pet_instance.set_combat_enabled(false)
	
	# 显示宠物状态栏，让访问者看到宠物的强大！
	if pet_instance.has_node("PetInformVBox"):
		pet_instance.get_node("PetInformVBox").visible = true  # 显示状态栏
	
	# 设置宠物为稍小的比例
	pet_instance.scale = Vector2(0.8, 0.8)
	
	# 设置宠物名称标签，并确保可见
	if pet_instance.pet_name_rich_text:
		pet_instance.pet_name_rich_text.text = pet_instance.pet_name
		pet_instance.pet_name_rich_text.modulate = Color.YELLOW  # 巡逻宠物名称为黄色
		pet_instance.pet_name_rich_text.visible = true

# 根据巡逻宠物数据直接创建巡逻宠物（不依赖宠物背包）
func create_patrol_pet_from_data(pet_data: Dictionary):
	# 检查巡逻线节点是否存在
	if not pet_patrol_path_line:
		print("错误：找不到巡逻线节点 PetPatrolPathLine")
		return
	
	# 检查巡逻路径是否设置
	if pet_patrol_path_line.points.size() < 2:
		print("警告：巡逻路径点数少于2个，无法创建巡逻宠物")
		return
	
	# 获取宠物场景路径
	var scene_path = pet_data.get("场景路径", "")
	if scene_path == "":
		print("错误：巡逻宠物数据中没有场景路径")
		return
	
	# 检查场景文件是否存在
	if not ResourceLoader.exists(scene_path):
		print("错误：巡逻宠物场景文件不存在: " + scene_path)
		return
	
	# 加载宠物场景
	var pet_scene = load(scene_path)
	if not pet_scene:
		print("错误：无法加载巡逻宠物场景: " + scene_path)
		return
	
	var pet_instance = pet_scene.instantiate()
	if not pet_instance:
		print("错误：无法创建巡逻宠物实例")
		return
	
	# 应用宠物数据到实例
	apply_pet_data_to_patrol_instance(pet_instance, pet_data)
	
	# 设置巡逻状态和路径
	pet_instance.is_patrolling = true
	pet_instance.patrol_path = pet_patrol_path_line.points.duplicate()
	pet_instance.patrol_speed = 80.0
	pet_instance.current_patrol_index = 0
	pet_instance.patrol_wait_time = 0.0
	
	# 设置宠物状态为巡逻
	pet_instance.current_state = pet_instance.PetState.PATROLLING
	
	# 添加到巡逻线节点下
	pet_patrol_path_line.add_child(pet_instance)
	current_patrol_pet = pet_instance
	
	# 设置初始位置
	pet_instance.position = pet_patrol_path_line.points[0]
	
	var pet_name = pet_data.get("基本信息", {}).get("宠物名称", "未知")
	print("从服务器数据创建巡逻宠物成功: " + pet_name + " (场景: " + scene_path + ")")



#====================================偷菜被发现处理=========================================
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
			if updated_data.has("money"):
				money = updated_data["money"]
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
	
	# 获取巡逻宠物和出战宠物信息
	var patrol_pet_name = patrol_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
	var patrol_pet_level = patrol_pet_data.get("等级经验", {}).get("宠物等级", 1)
	var patrol_pet_type = patrol_pet_data.get("基本信息", {}).get("宠物类型", "未知类型")
	
	var battle_pet_name = battle_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
	var battle_pet_level = battle_pet_data.get("等级经验", {}).get("宠物等级", 1)
	var battle_pet_type = battle_pet_data.get("基本信息", {}).get("宠物类型", "未知类型")
	
	# 构建对话框内容
	var dialog_content = message + "\n\n"
	dialog_content += "🛡️ " + target_username + "的巡逻宠物：\n"
	dialog_content += "   " + patrol_pet_name + " (类型:" + patrol_pet_type + ", 等级:" + str(patrol_pet_level) + ")\n\n"
	dialog_content += "⚔️ 你的出战宠物：\n"
	dialog_content += "   " + battle_pet_name + " (类型:" + battle_pet_type + ", 等级:" + str(battle_pet_level) + ")\n\n"
	dialog_content += "请选择你的行动：\n"
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
	
	# 验证宠物数据完整性
	var battle_pet_id = battle_pet_data.get("基本信息", {}).get("宠物ID", "")
	var patrol_pet_id = patrol_pet_data.get("基本信息", {}).get("宠物ID", "")
	
	if battle_pet_id == "" or patrol_pet_id == "":
		Toast.show("宠物数据不完整，无法开始对战", Color.RED, 3.0)
		return
	
	# 检查是否为同一个宠物
	if check_battle_patrol_conflict(battle_pet_id, patrol_pet_id):
		Toast.show("出战宠物和巡逻宠物不能为同一个！", Color.RED, 3.0)
		return
	
	# 停止宠物对战面板的自动对战逻辑
	if pet_fight_panel and pet_fight_panel.has_method("stop_auto_battle"):
		pet_fight_panel.stop_auto_battle()
	
	# 加载双方宠物数据到对战面板
	if pet_fight_panel and pet_fight_panel.has_method("setup_steal_battle"):
		pet_fight_panel.setup_steal_battle(battle_pet_data, patrol_pet_data, user_name, target_username)
	
	# 显示宠物对战面板
	pet_fight_panel.show()
	GlobalVariables.isZoomDisabled = true
	
	Toast.show("准备进入宠物对战！", Color.YELLOW, 2.0)

# 玩家选择逃跑
func _on_steal_escape_confirmed(escape_cost: int):
	print("玩家选择逃跑，支付", escape_cost, "金币")
	
	# 检查金币是否足够
	if money < escape_cost:
		Toast.show("金币不足，无法逃跑！需要" + str(escape_cost) + "金币", Color.RED, 3.0)
		return
	
	# 扣除金币
	money -= escape_cost
	_update_ui()
	
	Toast.show("支付了 " + str(escape_cost) + " 金币逃跑成功", Color.ORANGE, 3.0)
#====================================偷菜被发现处理=========================================

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


# 检查出战宠物和巡逻宠物是否冲突
func check_battle_patrol_conflict(battle_pet_id: String, patrol_pet_id: String) -> bool:
	if battle_pet_id == "" or patrol_pet_id == "":
		return false
	return battle_pet_id == patrol_pet_id

# 根据宠物ID获取完整的宠物数据
func get_pet_data_by_id(pet_id: String) -> Dictionary:
	for pet_data in pet_bag:
		var current_id = pet_data.get("基本信息", {}).get("宠物ID", "")
		if current_id == pet_id:
			return pet_data
	return {}

#智慧树按钮点击
func _on_wisdom_tree_pressed() -> void:
	wisdom_tree_panel.show()
	# 确保智慧树面板有正确的可见性处理
	if wisdom_tree_panel.has_method("_on_visibility_changed"):
		wisdom_tree_panel._on_visibility_changed()

#=======================================智慧树系统=========================================
# 更新智慧树显示
func update_wisdom_tree_display():
	if not login_data.has("智慧树配置"):
		return
	
	var wisdom_tree_config = login_data["智慧树配置"]
	
	# 确保配置格式正确，兼容旧格式
	wisdom_tree_config = _ensure_wisdom_tree_config_format(wisdom_tree_config)
	
	var level = wisdom_tree_config.get("等级", 1)
	var height = wisdom_tree_config.get("高度", 20)
	var current_health = wisdom_tree_config.get("当前生命值", 100)
	var max_health = wisdom_tree_config.get("最大生命值", 100)
	var anonymous_message = wisdom_tree_config.get("智慧树显示的话", "")
	
	# 更新智慧树状态显示
	if tree_status:
		tree_status.text = "等级lv：" + str(level) + "  高度：" + str(height) + "cm"
	
	# 更新智慧树图片大小（从0.5到1.6倍）
	update_wisdom_tree_size()
	
	# 如果有匿名消息，显示在智慧树对话框中（访问模式下隐藏）
	if anonymous_talk:
		if is_visiting_mode:
			# 访问模式下隐藏智慧树消息
			anonymous_talk.hide()
		elif anonymous_message != "":
			anonymous_talk.show()
			# 获取当前时间戳 - 显示完整时间
			var current_time = Time.get_datetime_string_from_system()
			var date_part = current_time.substr(0, 10)  # 年月日
			var time_part = current_time.substr(11, 8)  # 时分秒
			anonymous_talk.text = "[color=cyan][" + date_part + " " + time_part + "][/color] " + anonymous_message
		else:
			anonymous_talk.show()
			anonymous_talk.text = "给未来的某个陌生人说一句话吧"

# 更新智慧树显示（用于访问模式）
func _update_wisdom_tree_display(wisdom_config: Dictionary):
	if not wisdom_config:
		return
	
	# 更新智慧树等级和高度
	var level = wisdom_config.get("等级", 1)
	var height = wisdom_config.get("高度", 20)
	var current_health = wisdom_config.get("当前生命值", 100)
	var max_health = wisdom_config.get("最大生命值", 100)
	var current_exp = wisdom_config.get("当前经验值", 0)
	var max_exp = wisdom_config.get("最大经验值", 100)
	var wisdom_message = wisdom_config.get("智慧树显示的话", "")
	
	# 更新智慧树状态显示
	if tree_status:
		tree_status.text = "等级lv：" + str(level) + "  高度：" + str(height) + "cm"
	
	# 更新智慧树图片大小和位置（确保居中）
	if wisdom_tree_image:
		# 计算缩放比例（高度20cm对应0.5倍，最大1.6倍）
		var min_height = 20.0
		var max_height = 100.0
		var min_scale = 0.5
		var max_scale = 1.6
		
		# 确保高度在有效范围内
		height = clamp(height, min_height, max_height)
		
		# 计算缩放比例
		var scale_factor = min_scale + (max_scale - min_scale) * (height - min_height) / (max_height - min_height)
		
		
		# 应用缩放，确保图片居中
		wisdom_tree_image.scale = Vector2(scale_factor, scale_factor)
		
		# 根据生命值设置智慧树图片的颜色
		if current_health <= 0:
			wisdom_tree_image.self_modulate = Color(0.5, 0.5, 0.5, 1.0)  # 灰色表示死亡
		elif current_health <= max_health * 0.3:  # 生命值低于30%
			wisdom_tree_image.self_modulate = Color(1.0, 0.8, 0.8, 1.0)  # 浅红色表示生病
		else:
			wisdom_tree_image.self_modulate = Color(1.0, 1.0, 1.0, 1.0)  # 正常颜色
	
	# 更新智慧树消息显示
	if wisdom_message != "" and anonymous_talk:
		# 显示完整的时间格式
		var current_time = Time.get_datetime_string_from_system()
		var date_part = current_time.substr(0, 10)  # 年月日
		var time_part = current_time.substr(11, 8)  # 时分秒
		anonymous_talk.text = "[color=cyan][" + date_part + " " + time_part + "][/color] " + wisdom_message
	

# 更新智慧树图片大小
func update_wisdom_tree_size():
	if not login_data.has("智慧树配置") or not wisdom_tree_image:
		return
	
	var wisdom_tree_config = login_data["智慧树配置"]
	var height = wisdom_tree_config.get("高度", 20)
	
	# 计算缩放比例（高度20cm对应0.5倍，最大1.6倍）
	# 高度范围：20-100cm，缩放范围：0.5-1.6倍
	var min_height = 20.0
	var max_height = 999999999999.0
	var min_scale = 0.5
	var max_scale = 1.6
	
	# 确保高度在有效范围内
	height = clamp(height, min_height, max_height)
	
	# 计算缩放比例
	var scale_factor = min_scale + (max_scale - min_scale) * (height - min_height) / (max_height - min_height)
	
	# 应用缩放
	wisdom_tree_image.scale = Vector2(scale_factor, scale_factor)
	
	print("智慧树高度: ", height, "cm, 缩放比例: ", scale_factor)

# 随机显示智慧树匿名消息（放音乐时调用）
func show_random_wisdom_tree_message():
	# 发送请求到服务器获取随机消息
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("send_wisdom_tree_operation"):
		tcp_network_manager_panel.send_wisdom_tree_operation("get_random_message")

# 智慧树生命值衰减现在完全由服务端处理，客户端不再处理


# 智慧树护理时间更新（已移到服务端处理）
func update_wisdom_tree_care_time():
	# 护理时间更新现在由服务端处理
	pass

# 处理智慧树响应消息
func handle_wisdom_tree_response(data: Dictionary):
	var message_type = data.get("operation_type", "")
	var message_content = data.get("random_message", "")
	
	if message_type == "play_music" and message_content != "":
		# 显示随机获得的匿名消息
		if anonymous_talk:
			var current_time = Time.get_datetime_string_from_system()
			var date_part = current_time.substr(0, 10)  # 年月日
			var time_part = current_time.substr(11, 8)  # 时分秒
			anonymous_talk.text = "[color=cyan][" + date_part + " " + time_part + "][/color] " + message_content
		
		# 保存到智慧树配置中
		if login_data.has("智慧树配置"):
			var wisdom_tree_config = login_data["智慧树配置"]
			wisdom_tree_config["智慧树显示的话"] = message_content
			login_data["智慧树配置"] = wisdom_tree_config

# 确保智慧树配置格式正确，兼容旧格式
func _ensure_wisdom_tree_config_format(wisdom_tree_config: Dictionary) -> Dictionary:
	# 创建配置副本以避免修改原始数据
	var config = wisdom_tree_config.duplicate()
	
	# 如果是旧格式，转换为新格式
	if config.has("生命值") and not config.has("当前生命值"):
		var old_health = config.get("生命值", 100)
		config["当前生命值"] = old_health
		config["最大生命值"] = 100
		config.erase("生命值")
	
	if config.has("经验") and not config.has("当前经验值"):
		var old_exp = config.get("经验", 0)
		config["当前经验值"] = old_exp
		var level = config.get("等级", 1)
		# 使用动态公式计算最大经验值
		var base_exp = 50
		var exp_multiplier = 1.2
		var level_factor = pow(level, 1.5)
		var max_exp = int(base_exp * level_factor * exp_multiplier)
		config["最大经验值"] = max_exp
		config.erase("经验")
	
	# 确保所有必需字段存在
	if not config.has("当前生命值"):
		config["当前生命值"] = 100
	if not config.has("最大生命值"):
		config["最大生命值"] = 100
	if not config.has("当前经验值"):
		config["当前经验值"] = 0
	if not config.has("最大经验值"):
		var level = config.get("等级", 1)
		var base_exp = 50
		var exp_multiplier = 1.2
		var level_factor = pow(level, 1.5)
		var max_exp = int(base_exp * level_factor * exp_multiplier)
		config["最大经验值"] = max_exp
	
	return config

#处理智慧树配置响应
func _handle_wisdom_tree_config_response(data):
	var success = data.get("success", false)
	if success:
		var config = data.get("config", {})
		# 确保配置格式正确
		config = _ensure_wisdom_tree_config_format(config)
		# 更新本地智慧树配置
		login_data["智慧树配置"] = config
		# 更新界面显示
		update_wisdom_tree_display()
		print("智慧树配置已更新")
		
		# 如果智慧树面板打开，也更新面板显示
		var wisdom_tree_panel = get_node_or_null("BigPanel/SmallPanel/WisdomTreePanel")
		if wisdom_tree_panel and wisdom_tree_panel.visible:
			wisdom_tree_panel.wisdom_tree_config = config
			wisdom_tree_panel.update_ui()
#=======================================智慧树系统========================================= 

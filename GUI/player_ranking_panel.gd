extends Panel

@onready var player_ranking_list : VBoxContainer = $Scroll/PlayerList
@onready var refresh_button : Button = $RefreshButton
@onready var quit_button : Button = $QuitButton
@onready var register_player_num: Label = $RegisterPlayerNum	#显示注册总人数


#预添加常用的面板
@onready var main_game = get_node("/root/main")
@onready var land_panel = get_node("/root/main/UI/LandPanel")
@onready var crop_store_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var player_ranking_panel = get_node("/root/main/UI/PlayerRankingPanel")
@onready var player_bag_panel = get_node("/root/main/UI/PlayerBagPanel")
@onready var network_manager = get_node("/root/main/UI/TCPNetworkManager")

#下面这是每个玩家要展示的信息，直接获取服务器玩家数据json文件来实现
#模板用于复制创建新的玩家条目
@onready var player_info_template : VBoxContainer = $Scroll/PlayerList/player_ranking_item

func _ready() -> void:
	# 隐藏模板
	player_info_template.visible = false

	# 连接按钮信号
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	

# 请求玩家排行榜数据
func request_player_rankings():
	if not network_manager:
		print("网络管理器不可用")
		register_player_num.text = "网络管理器不可用"
		register_player_num.modulate = Color.RED
		return false
	
	if not network_manager.is_connected_to_server():
		print("未连接到服务器")
		register_player_num.text = "未连接服务器"
		register_player_num.modulate = Color.RED
		return false
	
	var success = network_manager.sendGetPlayerRankings()
	if not success:
		print("发送排行榜请求失败")
		register_player_num.text = "请求发送失败"
		register_player_num.modulate = Color.RED
		return false
	
	return true

# 处理玩家排行榜响应
func handle_player_rankings_response(data):
	# 重新启用刷新按钮
	refresh_button.disabled = false
	refresh_button.text = "刷新"
	
	# 检查响应是否成功
	if not data.get("success", false):
		print("获取玩家排行榜失败：", data.get("message", "未知错误"))
		register_player_num.text = "获取注册人数失败"
		register_player_num.modulate = Color.RED
		Toast.show("获取排行榜失败：" + data.get("message", "未知错误"), Color.RED)
		return
	
	# 显示注册总人数和在线人数
	var total_registered = data.get("total_registered_players", 0)
	var players_list = data.get("players", [])
	var online_count = 0
	for player in players_list:
		if player.get("is_online", false):
			online_count += 1
	
	register_player_num.text = "总人数：" + str(int(total_registered)) + "|  在线：" + str(online_count) 
	register_player_num.modulate = Color.CYAN
	
	# 清除现有的玩家条目（除了模板）
	for child in player_ranking_list.get_children():
		if child != player_info_template:
			child.queue_free()
	
	# 添加玩家条目
	var players = players_list
	for player_data in players:
		add_player_entry(player_data)
	
	print("排行榜数据已更新，显示", players.size(), "个玩家，注册总人数：", total_registered)
	Toast.show("排行榜已刷新！显示 " + str(players.size()) + " 个玩家", Color.GREEN)

# 添加单个玩家条目
func add_player_entry(player_data):
	# 复制模板
	var player_entry = player_info_template.duplicate()
	player_entry.visible = true
	player_ranking_list.add_child(player_entry)
	
	# 设置玩家信息
	var player_name = player_entry.get_node("HBox/PlayerName")
	var player_level = player_entry.get_node("HBox/PlayerLevel")
	var player_money = player_entry.get_node("HBox/PlayerMoney")
	var player_seed_num = player_entry.get_node("HBox/SeedNum")
	var player_online_time = player_entry.get_node("HBox2/OnlineTime")
	var player_last_login_time = player_entry.get_node("HBox2/LastLoginTime")
	var player_avatar = player_entry.get_node("HBox/PlayerAvatar")
	var visit_button = player_entry.get_node("HBox/VisitButton")
	var player_is_online_time = player_entry.get_node("HBox2/IsOnlineTime")
	
	# 填充数据
	var username = player_data.get("user_name", "未知")
	var display_name = player_data.get("player_name", username)
	player_name.text = display_name
	#都是整数，不要乱用浮点数
	player_level.text = "等级: " + str(int(player_data.get("level", 0)))
	player_money.text = "金币: " + str(int(player_data.get("money", 0)))
	player_seed_num.text = "种子: " + str(int(player_data.get("seed_count", 0)))
	player_online_time.text = "游玩时间: " + player_data.get("total_login_time", "0时0分0秒")
	player_last_login_time.text = "最后登录: " + player_data.get("last_login_time", "未知")
	
	# 设置在线状态显示
	var is_online = player_data.get("is_online", false)
	if is_online:
		player_is_online_time.text = "🟢 在线"
		player_is_online_time.modulate = Color.GREEN
	else:
		player_is_online_time.text = "🔴 离线"
		player_is_online_time.modulate = Color.GRAY
	
	# 尝试加载玩家头像（使用用户名/QQ号加载头像，而不是显示名）
	if username.is_valid_int():
		player_avatar.load_from_url("http://q1.qlogo.cn/g?b=qq&nk=" + username + "&s=100")
	
	# 设置访问按钮
	visit_button.pressed.connect(func(): _on_visit_player_pressed(username))

# 访问玩家按钮点击
func _on_visit_player_pressed(username):
	print("访问玩家：", username)
	
	# 检查网络连接
	if not network_manager or not network_manager.is_connected_to_server():
		Toast.show("未连接服务器，无法访问玩家", Color.RED)
		return
	
	# 检查是否尝试访问自己
	if main_game and main_game.user_name == username:
		Toast.show("不能访问自己的农场", Color.ORANGE)
		return
	
	# 发送访问玩家请求
	if network_manager and network_manager.has_method("sendVisitPlayer"):
		var success = network_manager.sendVisitPlayer(username)
		if success:
			Toast.show("正在访问 " + username + " 的农场...", Color.YELLOW)
			print("已发送访问玩家请求：", username)
		else:
			Toast.show("发送访问请求失败", Color.RED)
			print("发送访问玩家请求失败，网络未连接")
	else:
		Toast.show("网络管理器不可用", Color.RED)
		print("网络管理器不可用")

# 刷新按钮点击
func _on_refresh_button_pressed():
	# 检查网络连接
	if not network_manager or not network_manager.is_connected_to_server():
		register_player_num.text = "未连接服务器，无法刷新"
		register_player_num.modulate = Color.RED
		Toast.show("未连接服务器，无法刷新排行榜", Color.RED)
		return
	
	# 显示加载状态
	register_player_num.text = "正在刷新注册人数..."
	register_player_num.modulate = Color.YELLOW
	refresh_button.disabled = true
	refresh_button.text = "刷新中..."
	
	# 请求排行榜数据
	request_player_rankings()
	
	# 5秒后重新启用按钮（防止卡住）
	await get_tree().create_timer(5.0).timeout
	if refresh_button.disabled:
		refresh_button.disabled = false
		refresh_button.text = "刷新"
		if register_player_num.text == "正在刷新注册人数...":
			register_player_num.text = "刷新超时，请重试"
			register_player_num.modulate = Color.RED

# 退出按钮点击
func _on_quit_button_pressed():
	self.hide()

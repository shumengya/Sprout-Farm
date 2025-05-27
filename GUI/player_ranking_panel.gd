extends Panel

@onready var player_ranking_list : VBoxContainer = $Scroll/PlayerList
@onready var refresh_button : Button = $RefreshButton
@onready var quit_button : Button = $QuitButton

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
	
	# 初始加载排行榜
	request_player_rankings()

# 请求玩家排行榜数据
func request_player_rankings():
	if network_manager:
		network_manager.sendGetPlayerRankings()

# 处理玩家排行榜响应
func handle_player_rankings_response(data):
	# 检查响应是否成功
	if not data.get("success", false):
		print("获取玩家排行榜失败：", data.get("message", "未知错误"))
		return
	
	# 清除现有的玩家条目（除了模板）
	for child in player_ranking_list.get_children():
		if child != player_info_template:
			child.queue_free()
	
	# 添加玩家条目
	var players = data.get("players", [])
	for player_data in players:
		add_player_entry(player_data)

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
	
	# 填充数据
	var username = player_data.get("user_name", "未知")
	var display_name = player_data.get("player_name", username)
	player_name.text = display_name
	player_level.text = "等级: " + str(player_data.get("level", 0))
	player_money.text = "金币: " + str(player_data.get("money", 0))
	player_seed_num.text = "种子: " + str(player_data.get("seed_count", 0))
	player_online_time.text = "游玩时间: " + player_data.get("total_login_time", "0时0分0秒")
	player_last_login_time.text = "最后登录: " + player_data.get("last_login_time", "未知")
	
	# 尝试加载玩家头像（使用用户名/QQ号加载头像，而不是显示名）
	if username.is_valid_int():
		player_avatar.load_from_url("http://q1.qlogo.cn/g?b=qq&nk=" + username + "&s=100")
	
	# 设置访问按钮
	visit_button.pressed.connect(func(): _on_visit_player_pressed(username))

# 访问玩家按钮点击
func _on_visit_player_pressed(username):
	print("访问玩家：", username)
	
	# 发送访问玩家请求
	if network_manager and network_manager.has_method("sendVisitPlayer"):
		var success = network_manager.sendVisitPlayer(username)
		if success:
			print("已发送访问玩家请求：", username)
		else:
			print("发送访问玩家请求失败，网络未连接")
	else:
		print("网络管理器不可用")

# 刷新按钮点击
func _on_refresh_button_pressed():
	request_player_rankings()

# 退出按钮点击
func _on_quit_button_pressed():
	self.hide()

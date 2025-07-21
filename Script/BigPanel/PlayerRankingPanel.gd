extends Panel

@onready var player_ranking_list : VBoxContainer = $Scroll/PlayerList
@onready var refresh_button : Button = $RefreshButton			#刷新玩家排行榜面板按钮
@onready var quit_button : Button = $QuitButton					#关闭面板按钮
@onready var search_button: Button = $SearchButton				#搜索玩家按钮
@onready var register_player_num: Label = $RegisterPlayerNum	#显示注册总人数

#搜索玩家输入框，通过输入QQ号来查询
@onready var search_line_edit: LineEdit = $SearchLineEdit

#排序筛选玩家面板按钮，默认按从大到小排序
#排序元素：种子数，等级，在线时长，最后登录时长，点赞数
#筛选元素：是否在线 筛选出在线玩家
@onready var seed_sort_btn: Button = $FiterAndSortHBox/SeedSortBtn
@onready var level_sort_btn: Button = $FiterAndSortHBox/LevelSortBtn
@onready var online_time_sort_btn: Button = $FiterAndSortHBox/OnlineTimeSortBtn
@onready var login_time_sort_btn: Button = $FiterAndSortHBox/LoginTimeSortBtn
@onready var like_num_sort_btn: Button = $FiterAndSortHBox/LikeNumSortBtn
@onready var money_sort_btn: Button = $FiterAndSortHBox/MoneySortBtn
@onready var is_online_sort_btn: Button = $FiterAndSortHBox/IsOnlineSortBtn


#预添加常用的面板
@onready var main_game = get_node("/root/main")


@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'


# 排序状态管理
var current_sort_by = "level"  # 当前排序字段
var current_sort_order = "desc"  # 当前排序顺序
var filter_online_only = false  # 是否只显示在线玩家
var current_search_qq = ""  # 当前搜索的QQ号

#下面这是每个玩家要展示的信息，直接获取服务器玩家数据json文件来实现
#模板用于复制创建新的玩家条目
@onready var player_info_template : VBoxContainer = $Scroll/PlayerList/PlayerRankingItem
@onready var player_entry_scene : PackedScene = preload("res://GUI/PlayerRankingItem.tscn")

func _ready() -> void:
	# 隐藏模板
	player_info_template.visible = false

	# 连接按钮信号
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	search_button.pressed.connect(_on_search_button_pressed)
	
	# 连接排序按钮信号
	seed_sort_btn.pressed.connect(func(): _on_sort_button_pressed("seed_count"))
	level_sort_btn.pressed.connect(func(): _on_sort_button_pressed("level"))
	online_time_sort_btn.pressed.connect(func(): _on_sort_button_pressed("online_time"))
	login_time_sort_btn.pressed.connect(func(): _on_sort_button_pressed("login_time"))
	like_num_sort_btn.pressed.connect(func(): _on_sort_button_pressed("like_num"))
	money_sort_btn.pressed.connect(func(): _on_sort_button_pressed("money"))
	is_online_sort_btn.pressed.connect(_on_online_filter_pressed)
	
	# 初始化按钮状态
	_update_button_states()

# 排序按钮点击处理
func _on_sort_button_pressed(sort_field: String):
	# 如果点击的是当前排序字段，切换排序顺序
	if current_sort_by == sort_field:
		current_sort_order = "asc" if current_sort_order == "desc" else "desc"
	else:
		# 切换到新的排序字段，默认降序
		current_sort_by = sort_field
		current_sort_order = "desc"
	
	# 更新按钮状态
	_update_button_states()
	
	# 重新请求排行榜
	request_player_rankings()

# 在线筛选按钮点击处理
func _on_online_filter_pressed():
	filter_online_only = !filter_online_only
	_update_button_states()
	request_player_rankings()

# 更新按钮状态显示
func _update_button_states():
	# 重置所有排序按钮
	var sort_buttons = [seed_sort_btn, level_sort_btn, online_time_sort_btn, login_time_sort_btn, like_num_sort_btn, money_sort_btn]
	var sort_fields = ["seed_count", "level", "online_time", "login_time", "like_num", "money"]
	var sort_names = ["种子数", "等级", "游玩时间", "登录时间", "点赞数", "金币数"]
	
	for i in range(sort_buttons.size()):
		var btn = sort_buttons[i]
		var field = sort_fields[i]
		var name = sort_names[i]
		
		if current_sort_by == field:
			# 当前排序字段，显示排序方向
			var arrow = "↓" if current_sort_order == "desc" else "↑"
			btn.text = name + arrow
			btn.modulate = Color.YELLOW
		else:
			# 非当前排序字段
			btn.text = name
			btn.modulate = Color.WHITE
	
	# 更新在线筛选按钮
	if filter_online_only:
		is_online_sort_btn.text = "仅在线✓"
		is_online_sort_btn.modulate = Color.GREEN
	else:
		is_online_sort_btn.text = "全部玩家"
		is_online_sort_btn.modulate = Color.WHITE

# 请求玩家排行榜数据
func request_player_rankings():
	if not tcp_network_manager_panel:
		register_player_num.text = "网络管理器不可用"
		register_player_num.modulate = Color.RED
		return false
	
	if not tcp_network_manager_panel.is_connected_to_server():
		register_player_num.text = "未连接服务器"
		register_player_num.modulate = Color.RED
		return false
	
	var success = tcp_network_manager_panel.sendGetPlayerRankings(current_sort_by, current_sort_order, filter_online_only, current_search_qq)
	if not success:
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
	
	# 显示搜索和筛选信息
	var info_text = "总人数：" + str(int(total_registered)) + "|  在线：" + str(online_count)
	if current_search_qq != "":
		info_text += "|  搜索：" + current_search_qq
	if filter_online_only:
		info_text += "|  仅在线"
	
	register_player_num.text = info_text
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
	
	var result_text = "排行榜已刷新！显示 " + str(players.size()) + " 个玩家"
	if current_search_qq != "":
		result_text += "（搜索：" + current_search_qq + "）"
	if filter_online_only:
		result_text += "（仅在线）"
	
	Toast.show(result_text, Color.GREEN)

# 添加单个玩家条目
func add_player_entry(player_data):
	# 实例化新的玩家条目场景，避免 duplicate 引发的复制错误
	var player_entry = player_entry_scene.instantiate()
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
	var player_like_num = player_entry.get_node("HBox2/LikeNum")
	
	# 填充数据
	var username = player_data.get("user_name", "未知")
	var display_name = player_data.get("player_name", username)
	player_name.text = display_name
	#都是整数，不要乱用浮点数
	player_level.text = "等级: " + str(int(player_data.get("level", 0)))
	player_money.text = "金币: " + str(int(player_data.get("money", 0)))
	player_seed_num.text = "种子: " + str(int(player_data.get("seed_count", 0)))
	player_online_time.text = "游玩时间: " + player_data.get("总游玩时间", "0时0分0秒")
	player_last_login_time.text = "最后登录: " + player_data.get("最后登录时间", "未知")
	
	# 设置在线状态显示
	var is_online = player_data.get("is_online", false)
	if is_online:
		player_is_online_time.text = "🟢 在线"
		player_is_online_time.modulate = Color.GREEN
	else:
		player_is_online_time.text = "🔴 离线"
		player_is_online_time.modulate = Color.GRAY
	
	# 设置点赞数显示
	player_like_num.text = "点赞: " + str(int(player_data.get("like_num", 0)))
	
	# 尝试加载玩家头像（使用用户名/QQ号加载头像，而不是显示名）
	if username.is_valid_int():
		player_avatar.load_from_url("http://q1.qlogo.cn/g?b=qq&nk=" + username + "&s=100")
	
	# 设置访问按钮
	visit_button.pressed.connect(func(): _on_visit_player_pressed(username))

# 访问玩家按钮点击
func _on_visit_player_pressed(username):
	#访问玩家后取消禁用相机功能，否则无法恢复
	GlobalVariables.isZoomDisabled = false
	
	
	# 检查网络连接
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接服务器，无法访问玩家", Color.RED)
		return
	
	# 检查是否尝试访问自己
	if main_game and main_game.user_name == username:
		Toast.show("不能访问自己的农场", Color.ORANGE)
		return
	
	# 发送访问玩家请求
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendVisitPlayer"):
		var success = tcp_network_manager_panel.sendVisitPlayer(username)
		if success:
			Toast.show("正在访问 " + username + " 的农场...", Color.YELLOW)
		else:
			Toast.show("发送访问请求失败", Color.RED)
	else:
		Toast.show("网络管理器不可用", Color.RED)

# 刷新按钮点击
func _on_refresh_button_pressed():
	# 检查网络连接
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		register_player_num.text = "未连接服务器，无法刷新"
		register_player_num.modulate = Color.RED
		Toast.show("未连接服务器，无法刷新排行榜", Color.RED)
		return
	
	# 显示加载状态
	register_player_num.text = "正在刷新排行榜..."
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
		if register_player_num.text == "正在刷新排行榜...":
			register_player_num.text = "刷新超时，请重试"
			register_player_num.modulate = Color.RED

# 退出按钮点击
func _on_quit_button_pressed():
	#打开面板后暂时禁用相机功能
	GlobalVariables.isZoomDisabled = false
	
	self.hide()

#搜索按钮点击 - 通过QQ号查询玩家
func _on_search_button_pressed():
	var search_text = search_line_edit.text.strip_edges()
	
	# 如果搜索框为空，清除搜索条件
	if search_text == "":
		current_search_qq = ""
		Toast.show("已清除搜索条件", Color.YELLOW)
	else:
		# 验证输入是否为数字（QQ号）
		if not search_text.is_valid_int():
			Toast.show("请输入有效的QQ号（纯数字）", Color.RED)
			return
		
		current_search_qq = search_text
		Toast.show("搜索QQ号：" + search_text, Color.YELLOW)
	
	# 重新请求排行榜
	request_player_rankings()

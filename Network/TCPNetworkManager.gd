extends Panel

# TCP客户端通信处理

# UI组件引用
@onready var status_label = $StatusLabel
@onready var message_input = $MessageInput
@onready var send_button = $SendButton
@onready var response_label = $Scroll/ResponseLabel
@onready var connection_button = $ConnectionButton

#所有面板
@onready var main_game = get_node("/root/main")
@onready var lucky_draw_panel: LuckyDrawPanel = $'../LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'
@onready var wisdom_tree_panel: Panel = $'../../SmallPanel/WisdomTreePanel'



# TCP客户端
var client: TCPClient = TCPClient.new()

# 服务器配置 - 支持多个服务器地址
var server_configs = GlobalVariables.server_configs

var current_server_index = 0
var auto_retry = true
var retry_delay = 3.0
var connection_timeout = 5.0  # 连接超时时间
var is_trying_to_connect = false
var connection_start_time = 0.0
var has_tried_all_servers = false  # 是否已尝试过所有服务器

# 延迟测量相关变量
var ping_start_time = 0.0
var current_ping = -1  # -1表示尚未测量
var ping_timer = 0.0
var ping_interval = 3.0  # 每3秒ping一次
var ping_timeout = 5.0  # ping超时时间
var is_measuring_ping = false

#=====================================网络连接基本处理=========================================
func _ready():
	# 创建TCP客户端实例
	self.add_child(client)
	
	# 连接信号
	client.connected_to_server.connect(_on_connected)
	client.connection_failed.connect(_on_connection_failed)
	client.connection_closed.connect(_on_connection_closed)
	client.data_received.connect(_on_data_received)
	
	# 连接按钮事件
	connection_button.pressed.connect(_on_connection_button_pressed)
	send_button.pressed.connect(_on_send_button_pressed)
	
	# 初始设置
	status_label.text = "❌未连接"
	status_label.modulate = Color.RED
	response_label.text = "等待响应..."
	connection_button.text = "连接"

# 每帧检查连接状态和超时
func _process(delta):
	# 检查连接超时
	if is_trying_to_connect:
		var elapsed_time = Time.get_unix_time_from_system() - connection_start_time
		if elapsed_time > connection_timeout:
			is_trying_to_connect = false
			client.disconnect_from_server()
			
			status_label.text = "连接超时"
			status_label.modulate = Color.RED
			connection_button.text = "连接"
			
			# 通知主游戏更新在线人数显示
			if main_game and main_game.has_method("_update_online_players_display"):
				main_game._update_online_players_display(0, false, false)
	
	# 处理延迟测量
	if client.is_client_connected():
		ping_timer += delta
		if ping_timer >= ping_interval and not is_measuring_ping:
			ping_timer = 0.0
			send_ping()
		
		# 检查ping超时
		if is_measuring_ping:
			var ping_elapsed = Time.get_unix_time_from_system() - ping_start_time
			if ping_elapsed > ping_timeout:
				is_measuring_ping = false
				current_ping = 999  # 显示为高延迟
		
		# 更新状态显示
		update_connection_status()
	else:
		# 未连接时重置延迟相关状态
		current_ping = -1
		is_measuring_ping = false
		ping_timer = 0.0
		
		# 更新状态显示
		update_connection_status()

func _on_connected():
	print("成功连接到服务器: ", server_configs[current_server_index]["name"])
	status_label.text = "已连接 ..."
	status_label.modulate = Color.GREEN
	connection_button.text = "断开"
	is_trying_to_connect = false
	has_tried_all_servers = false  # 连接成功后重置标志
	
	# 重置延迟测量
	current_ping = -1
	ping_timer = 0.0
	is_measuring_ping = false
	
	# 发送连接成功消息
	client.send_data({
		"type": "greeting", 
		"content": "你好，服务器！"
	})
	
	# 连接成功后立即请求作物数据
	sendGetCropData()
	
	# 连接成功后立即请求在线人数
	sendGetOnlinePlayers()
	
	# 请求智慧树配置
	send_get_wisdom_tree_config()
	
	# 立即开始第一次ping测量
	send_ping()

func _on_connection_failed():
	print("连接失败: ", server_configs[current_server_index]["name"])
	status_label.text = "连接失败 - " + server_configs[current_server_index]["name"]
	status_label.modulate = Color.RED
	connection_button.text = "连接"
	is_trying_to_connect = false
	
	# 重置延迟测量
	current_ping = -1
	is_measuring_ping = false
	ping_timer = 0.0
	
	# 通知主游戏更新在线人数显示
	main_game._update_online_players_display(0, false, false)
	

func _on_connection_closed():
	print("连接断开: ", server_configs[current_server_index]["name"])
	status_label.text = "连接断开 "
	status_label.modulate = Color.RED
	connection_button.text = "连接"
	is_trying_to_connect = false
	
	# 重置延迟测量
	current_ping = -1
	is_measuring_ping = false
	ping_timer = 0.0
	
	# 通知主游戏更新在线人数显示
	if main_game and main_game.has_method("_update_online_players_display"):
		main_game._update_online_players_display(0, false, false)
	
	# 通知主游戏连接已断开，显示登录面板
	main_game._on_connection_lost()
	
	
#=========================客户端与服务端通信核心=========================================
func _on_data_received(data):
	# 根据数据类型处理数据
	response_label.text = "收到: %s" % JSON.stringify(data)
	match typeof(data):

		TYPE_DICTIONARY:
			# 处理JSON对象
			var message_type = data.get("type", "")
			
			match message_type:
				"ping":							#ping是否在线
					return
				"response":						#服务器通用响应
					return
				"login_response":				#登录响应
					var status = data.get("status", "")
					var message = data.get("message", "")
					var player_data = data.get("player_data", {})
					if login_panel:
						login_panel._on_login_response_received(status == "success", message, player_data)
				"register_response":			#注册响应
					var status = data.get("status", "")
					var message = data.get("message", "")
					if login_panel:
						login_panel._on_register_response_received(status == "success", message)
				"verification_code_response":	#验证码发送响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					if login_panel:
						login_panel._on_verification_code_response(success, message)
				"verify_code_response":			#验证码验证响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					if login_panel:
						login_panel._on_verify_code_response(success, message)
				"crop_update":					#作物更新响应
					if main_game:
						main_game._handle_crop_update(data)
				"action_response":				#玩家操作响应
					if main_game:
						# 处理玩家动作到服务端响应消息
						var action_type = data.get("action_type", "")
						var success = data.get("success", false)
						var message = data.get("message", "")
						var updated_data = data.get("updated_data", {})
						
						match action_type:
							"harvest_crop":#处理收获作物响应
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("experience"):
										main_game.experience = updated_data["experience"]
									if updated_data.has("level"):
										main_game.level = updated_data["level"]
									if updated_data.has("体力值"):
										main_game.stamina = updated_data["体力值"]
									if updated_data.has("作物仓库"):
										main_game.crop_warehouse = updated_data["作物仓库"]
									
									# 更新UI
									main_game._update_ui()
									# 更新作物仓库UI
									if main_game.crop_warehouse_panel:
										main_game.crop_warehouse_panel.update_crop_warehouse_ui()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"plant_crop":#处理种植作物响应
								if success:
									# 更新玩家背包
									if updated_data.has("player_bag"):
										main_game.player_bag = updated_data["player_bag"]
									
									# 更新玩家背包UI
									main_game.player_bag_panel.update_player_bag_ui()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"buy_seed":#处理购买种子响应
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("player_bag"):
										main_game.player_bag = updated_data["player_bag"]
									
									# 更新UI
									main_game._update_ui()
									main_game.player_bag_panel.update_player_bag_ui()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"buy_item":#处理购买道具响应
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("道具背包"):
										main_game.item_bag = updated_data["道具背包"]
									
									# 更新UI
									main_game._update_ui()
									if main_game.item_bag_panel:
										main_game.item_bag_panel.update_item_bag_ui()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"buy_pet":#处理购买宠物响应
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("宠物背包"):
										main_game.pet_bag = updated_data["宠物背包"]
									
									# 更新UI
									main_game._update_ui()
									if main_game.pet_bag_panel:
										main_game.pet_bag_panel.update_pet_bag_ui()
									Toast.show(message, Color.MAGENTA)
								else:
									Toast.show(message, Color.RED)
							"rename_pet":#处理重命名宠物响应
								if success:
									# 更新玩家数据
									if updated_data.has("宠物背包"):
										main_game.pet_bag = updated_data["宠物背包"]
									
									# 更新UI
									if main_game.pet_bag_panel:
										main_game.pet_bag_panel.update_pet_bag_ui()
									
									# 通知宠物信息面板更新
									var pet_inform_panel = get_node_or_null("/root/main/BigPanel/SmallPanel/PetInformPanel")
									if pet_inform_panel and pet_inform_panel.has_method("on_rename_pet_success"):
										var pet_id = data.get("pet_id", "")
										var new_name = data.get("new_name", "")
										pet_inform_panel.on_rename_pet_success(pet_id, new_name)
									
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"set_patrol_pet":#处理设置巡逻宠物响应
								if success:
									# 更新巡逻宠物数据
									if updated_data.has("巡逻宠物"):
										main_game.patrol_pets = updated_data["巡逻宠物"]
									
									# 更新巡逻宠物显示
									if main_game.has_method("update_patrol_pets"):
										main_game.update_patrol_pets()
									
									# 更新巡逻按钮状态
									var pet_inform_panel = get_node_or_null("/root/main/BigPanel/SmallPanel/PetInformPanel")
									if pet_inform_panel and pet_inform_panel.has_method("_refresh_patrol_button"):
										pet_inform_panel._refresh_patrol_button()
									
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"use_item":#处理使用道具响应
								print("调试：收到道具使用响应")
								print("  - success: ", success)
								print("  - message: ", message)
								print("  - updated_data: ", updated_data)
								
								if success:
									print("调试：道具使用成功，开始更新数据")
									# 更新玩家数据
									if updated_data.has("道具背包"):
										main_game.item_bag = updated_data["道具背包"]
										print("调试：更新道具背包")
									if updated_data.has("farm_lots"):
										print("调试：更新地块数据")
										main_game.farm_lots = updated_data["farm_lots"]
									if updated_data.has("experience"):
										main_game.experience = updated_data["experience"]
										print("调试：更新经验值: ", main_game.experience)
									if updated_data.has("level"):
										main_game.level = updated_data["level"]
										print("调试：更新等级: ", main_game.level)
									
									# 更新UI
									print("调试：开始更新UI")
									main_game._update_ui()
									main_game._update_farm_lots_state()
									if main_game.item_bag_panel:
										main_game.item_bag_panel.update_item_bag_ui()
									print("调试：UI更新完成")
									Toast.show(message, Color.GREEN)
								else:
									print("错误：道具使用失败: ", message)
									Toast.show(message, Color.RED)
							"dig_ground":#处理开垦土地
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("experience"):
										main_game.experience = updated_data["experience"]
									if updated_data.has("level"):
										main_game.level = updated_data["level"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									if updated_data.has("player_bag"):
										main_game.player_bag = updated_data["player_bag"]
									
									# 更新UI
									main_game._update_ui()
									main_game._update_farm_lots_state()
									# 更新背包UI
									if main_game.player_bag_panel:
										main_game.player_bag_panel.update_player_bag_ui()
									Toast.show(message, Color.GREEN, 3.0, 1.0)
								else:
									Toast.show(message, Color.RED)
							"remove_crop":#处理铲除作物
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									
									# 更新UI
									main_game._update_ui()
									main_game._update_farm_lots_state()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
							"water_crop":#处理浇水
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									if updated_data.has("experience"):
										main_game.experience = updated_data["experience"]
									if updated_data.has("level"):
										main_game.level = updated_data["level"]
									
									# 更新UI
									main_game._update_ui()
									main_game._update_farm_lots_state()
									Toast.show(message, Color.CYAN)
								else:
									Toast.show(message, Color.RED)
							"fertilize_crop":#处理施肥	
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									if updated_data.has("experience"):
										main_game.experience = updated_data["experience"]
									if updated_data.has("level"):
										main_game.level = updated_data["level"]
									
									# 更新UI
									main_game._update_ui()
									main_game._update_farm_lots_state()
									Toast.show(message, Color.PURPLE)
								else:
									Toast.show(message, Color.RED)
							"upgrade_land":#处理升级土地	
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									
									# 更新UI
									main_game._update_ui()
									main_game._update_farm_lots_state()
									Toast.show(message, Color.GOLD)
								else:
									Toast.show(message, Color.RED)
							"buy_new_ground":#处理添加新土地
								if success:
									# 更新玩家数据
									if updated_data.has("money"):
										main_game.money = updated_data["money"]
									if updated_data.has("farm_lots"):
										main_game.farm_lots = updated_data["farm_lots"]
									
									# 重新创建UI来显示新地块
									main_game._create_farm_buttons()
									main_game._update_farm_lots_state()
									main_game._update_ui()
									Toast.show(message, Color.GREEN)
								else:
									Toast.show(message, Color.RED)
				"play_time_response":			#游玩时间统计响应
					if main_game and main_game.has_method("_handle_play_time_response"):
						main_game._handle_play_time_response(data)
				"player_rankings_response":		#玩家排行榜响应
					if main_game and main_game.has_method("_handle_player_rankings_response"):
						main_game._handle_player_rankings_response(data)
				"crop_data_response":			#作物数据更新响应
					if main_game and main_game.has_method("_handle_crop_data_response"):
						main_game._handle_crop_data_response(data)
				"item_config_response":			#道具配置数据响应
					if main_game and main_game.has_method("_handle_item_config_response"):
						main_game._handle_item_config_response(data)
				"visit_player_response":		#访问玩家响应
					if main_game and main_game.has_method("_handle_visit_player_response"):
						main_game._handle_visit_player_response(data)
				"return_my_farm_response":		#返回我的农场响应
					if main_game and main_game.has_method("_handle_return_my_farm_response"):
						main_game._handle_return_my_farm_response(data)
				"like_player_response":			#点赞玩家响应
					if main_game and main_game.has_method("_handle_like_player_response"):
						main_game._handle_like_player_response(data)
				"online_players_response":		#玩家在线响应
					if main_game and main_game.has_method("_handle_online_players_response"):
						main_game._handle_online_players_response(data)
				"daily_check_in_response":		#每日签到响应
					if main_game and main_game.has_method("_handle_daily_check_in_response"):
						main_game._handle_daily_check_in_response(data)
				"check_in_data_response":		#获取签到数据响应
					if main_game and main_game.has_method("_handle_check_in_data_response"):
						main_game._handle_check_in_data_response(data)
				"lucky_draw_response":			#幸运抽奖响应
					if main_game and main_game.has_method("_handle_lucky_draw_response"):
						main_game._handle_lucky_draw_response(data)
				"new_player_gift_response":		#新手大礼包响应
					if main_game and main_game.has_method("_handle_new_player_gift_response"):
						main_game._handle_new_player_gift_response(data)
				"online_gift_data_response":	#在线礼包数据响应
					if main_game and main_game.has_method("_handle_online_gift_data_response"):
						main_game._handle_online_gift_data_response(data)
				"claim_online_gift_response":	#领取在线礼包响应
					if main_game and main_game.has_method("_handle_claim_online_gift_response"):
						main_game._handle_claim_online_gift_response(data)
				"pong":							#延迟检测响应
					handle_pong_response(data)
				"modify_account_info_response":	#修改账号信息响应
					if main_game and main_game.has_method("_handle_account_setting_response"):
						main_game._handle_account_setting_response(data)
				"delete_account_response":		#删除账号响应
					if main_game and main_game.has_method("_handle_account_setting_response"):
						main_game._handle_account_setting_response(data)
				"refresh_player_info_response":	#刷新玩家信息响应
					if main_game and main_game.has_method("_handle_account_setting_response"):
						main_game._handle_account_setting_response(data)
				"steal_caught":					#偷菜被发现响应
					if main_game and main_game.has_method("_handle_steal_caught_response"):
						main_game._handle_steal_caught_response(data)
				"global_broadcast_message":		#全服大喇叭消息
					if main_game and main_game.has_method("_handle_global_broadcast_message"):
						main_game._handle_global_broadcast_message(data)
				"global_broadcast_response":	#全服大喇叭发送响应
					if main_game and main_game.has_method("_handle_global_broadcast_response"):
						main_game._handle_global_broadcast_response(data)
				"broadcast_history_response":	#全服大喇叭历史消息响应
					if main_game and main_game.has_method("_handle_broadcast_history_response"):
						main_game._handle_broadcast_history_response(data)
				"use_pet_item_response":		#宠物使用道具响应
					if main_game and main_game.has_method("_handle_use_pet_item_response"):
						main_game._handle_use_pet_item_response(data)
				"use_farm_item_response":		#农场道具使用响应
					if main_game and main_game.has_method("_handle_use_farm_item_response"):
						main_game._handle_use_farm_item_response(data)
				"buy_scare_crow_response":		#购买稻草人响应
					if main_game and main_game.has_method("_handle_buy_scare_crow_response"):
						main_game._handle_buy_scare_crow_response(data)
				"modify_scare_crow_config_response":	#修改稻草人配置响应
					if main_game and main_game.has_method("_handle_modify_scare_crow_config_response"):
						main_game._handle_modify_scare_crow_config_response(data)
				"get_scare_crow_config_response":	#获取稻草人配置响应
					if main_game and main_game.has_method("_handle_get_scare_crow_config_response"):
						main_game._handle_get_scare_crow_config_response(data)
				"wisdom_tree_operation_response":	#智慧树操作响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					var operation_type = data.get("operation_type", "")
					var updated_data = data.get("updated_data", {})
					
					if wisdom_tree_panel and wisdom_tree_panel.has_method("handle_wisdom_tree_operation_response"):
						wisdom_tree_panel.handle_wisdom_tree_operation_response(success, message, operation_type, updated_data)
				"wisdom_tree_message_response":		#智慧树消息发送响应
					var success = data.get("success", false)
					var message = data.get("message", "")
					var updated_data = data.get("updated_data", {})
					
					if wisdom_tree_panel and wisdom_tree_panel.has_method("handle_wisdom_tree_message_response"):
						wisdom_tree_panel.handle_wisdom_tree_message_response(success, message, updated_data)
				"wisdom_tree_config_response":		#智慧树配置响应
					if main_game and main_game.has_method("_handle_wisdom_tree_config_response"):
						main_game._handle_wisdom_tree_config_response(data)
				_:
					# 显示其他类型的消息
					return
		_:
			# 处理非JSON数据
			return
#=========================客户端与服务端通信核心=========================================

#=====================================网络连接基本处理=========================================





#=====================================网络操作处理=========================================
func _on_connection_button_pressed():
	if client.is_client_connected():
		# 断开连接
		client.disconnect_from_server()
		is_trying_to_connect = false
		has_tried_all_servers = false
	else:
		# 连接服务器，从当前服务器开始尝试
		has_tried_all_servers = false
		connect_to_current_server()

# 连接到当前选择的服务器
func connect_to_current_server():
	var config = server_configs[current_server_index]
	status_label.text = "正在连接 " + config["name"] + "..."
	status_label.modulate = Color.YELLOW
	
	print("=== 尝试连接服务器 ===")
	print("服务器名称: ", config["name"])
	print("服务器地址: ", config["host"], ":", config["port"])
	print("服务器索引: ", current_server_index, "/", server_configs.size() - 1)
	
	is_trying_to_connect = true
	connection_start_time = Time.get_unix_time_from_system()
	
	client.connect_to_server(config["host"], config["port"])
#手动发送消息处理
func _on_send_button_pressed():
	if not client.is_client_connected():
		status_label.text = "未连接，无法发送"
		return
	
	# 获取输入文本
	var text = message_input.text.strip_edges()
	if text.is_empty():
		return
	
	# 发送消息
	client.send_data({
		"type": "message",
		"content": text,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# 清空输入
	message_input.text = "" 
#=====================================网络操作处理=========================================


#=====================================客户端向服务端发送消息处理=========================================
#发送登录信息
func sendLoginInfo(username, password):
	client.send_data({
		"type": "login",
		"username": username,
		"password": password,
		"client_version": main_game.client_version
	})

#发送注册信息
func sendRegisterInfo(username, password, farmname, player_name="", verification_code=""):
	client.send_data({
		"type": "register",
		"username": username,
		"password": password,
		"farm_name": farmname,
		"player_name": player_name,
		"verification_code": verification_code,
		"client_version": main_game.client_version
	})

#发送收获作物信息
func sendHarvestCrop(lot_index, target_username = ""):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "harvest_crop",
		"lot_index": lot_index,
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送种植作物信息
func sendPlantCrop(lot_index, crop_name):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "plant_crop",
		"lot_index": lot_index,
		"crop_name": crop_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送开垦土地信息
func sendDigGround(lot_index):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "dig_ground",
		"lot_index": lot_index,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送铲除作物信息
func sendRemoveCrop(lot_index):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "remove_crop",
		"lot_index": lot_index,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买种子信息
func sendBuySeed(crop_name, quantity = 1):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_seed",
		"crop_name": crop_name,
		"quantity": quantity,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买道具信息
func sendBuyItem(item_name, item_cost, quantity = 1):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_item",
		"item_name": item_name,
		"item_cost": item_cost,
		"quantity": quantity,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买宠物信息
func sendBuyPet(pet_name, pet_cost):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_pet",
		"pet_name": pet_name,
		"pet_cost": pet_cost,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送重命名宠物信息
func sendRenamePet(pet_id, new_name):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "rename_pet",
		"pet_id": pet_id,
		"new_name": new_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送设置巡逻宠物信息
func sendSetPatrolPet(pet_id, is_patrolling):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "set_patrol_pet",
		"pet_id": pet_id,
		"is_patrolling": is_patrolling,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送设置出战宠物信息
func sendSetBattlePet(pet_id, is_battle):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "set_battle_pet",
		"pet_id": pet_id,
		"is_battle": is_battle,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送使用道具信息
func sendUseItem(lot_index, item_name, use_type, target_username = ""):
	
	if not client.is_client_connected():
		return false
		
	var message = {
		"type": "use_item",
		"lot_index": lot_index,
		"item_name": item_name,
		"use_type": use_type,
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	}
	client.send_data(message)
	return true

#发送获取游玩时间请求
func sendGetPlayTime():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_play_time"
	})
	return true

#发送更新游玩时间请求
func sendUpdatePlayTime():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "update_play_time"
	})
	return true

#发送获取玩家排行榜请求
func sendGetPlayerRankings(sort_by = "level", sort_order = "desc", filter_online = false, search_qq = ""):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_player_rankings",
		"sort_by": sort_by,
		"sort_order": sort_order,
		"filter_online": filter_online,
		"search_qq": search_qq
	})
	return true

#发送验证码请求
func sendVerificationCodeRequest(qq_number):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_verification_code",
		"qq_number": qq_number,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送验证码验证
func sendVerifyCode(qq_number, code):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "verify_code",
		"qq_number": qq_number,
		"code": code,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取作物数据请求
func sendGetCropData():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_crop_data"
	})
	return true

#发送获取道具配置数据请求
func sendGetItemConfig():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_item_config"
	})
	return true

#发送访问玩家请求
func sendVisitPlayer(target_username):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "visit_player",
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送返回自己农场请求
func sendReturnMyFarm():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "return_my_farm",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送浇水作物信息
func sendWaterCrop(lot_index, target_username = ""):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "water_crop",
		"lot_index": lot_index,
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送施肥作物信息
func sendFertilizeCrop(lot_index, target_username = ""):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "fertilize_crop",
		"lot_index": lot_index,
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送升级土地信息
func sendUpgradeLand(lot_index):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "upgrade_land",
		"lot_index": lot_index,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买新地块请求
func sendBuyNewGround():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_new_ground",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送点赞玩家请求
func sendLikePlayer(target_username):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "like_player",
		"target_username": target_username,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取在线人数请求
func sendGetOnlinePlayers():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "request_online_players",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送每日签到请求
func sendDailyCheckIn():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "daily_check_in",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取签到数据请求
func sendGetCheckInData():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_check_in_data",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送幸运抽奖请求
func sendLuckyDraw(draw_type: String):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "lucky_draw",
		"draw_type": draw_type,  # "single", "five", "ten"
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送新手大礼包请求
func sendClaimNewPlayerGift():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "claim_new_player_gift",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取在线礼包数据请求
func sendGetOnlineGiftData():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_online_gift_data",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送领取在线礼包请求
func sendClaimOnlineGift(gift_name: String):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "claim_online_gift",
		"gift_name": gift_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送购买稻草人请求
func send_buy_scare_crow(scare_crow_type: String, price: int):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "buy_scare_crow",
		"scare_crow_type": scare_crow_type,
		"price": price,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送修改稻草人配置请求
func send_modify_scare_crow_config(config_data: Dictionary, modify_cost: int):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "modify_scare_crow_config",
		"config_data": config_data,
		"modify_cost": modify_cost,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取稻草人配置请求
func send_get_scare_crow_config():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_scare_crow_config",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送智慧树操作请求
func send_wisdom_tree_operation(operation_type: String):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "wisdom_tree_operation",
		"operation_type": operation_type,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送智慧树消息
func send_wisdom_tree_message(message: String):
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "wisdom_tree_message",
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#发送获取智慧树配置请求
func send_get_wisdom_tree_config():
	if not client.is_client_connected():
		return false
		
	client.send_data({
		"type": "get_wisdom_tree_config",
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

#检查是否连接到服务器
func is_connected_to_server():
	return client.is_client_connected()

#发送通用消息
func send_message(message: Dictionary):
	if not client.is_client_connected():
		return false
	
	client.send_data(message)
	return true
	
	
# 手动切换到指定服务器
func switch_to_server(server_index: int):
	if server_index >= 0 and server_index < server_configs.size():
		current_server_index = server_index
		has_tried_all_servers = false
		
		if client.is_client_connected():
			client.disconnect_from_server()
		
		# 等待一下再连接新服务器
		var timer = get_tree().create_timer(0.5)
		await timer.timeout
		connect_to_current_server()

# 获取当前服务器信息
func get_current_server_info() -> Dictionary:
	return server_configs[current_server_index]

# 检查网络连接状态
func check_network_status():
	# 检查设备是否有网络连接
	if OS.get_name() == "Android":
		# 在Android上检查网络状态
		status_label.text = "检查网络状态..."
		
	# 尝试连接到当前配置的服务器
	if not client.is_client_connected():
		connect_to_current_server()

# 发送ping消息测量延迟
func send_ping():
	if client.is_client_connected() and not is_measuring_ping:
		is_measuring_ping = true
		ping_start_time = Time.get_unix_time_from_system()
		
		client.send_data({
			"type": "ping",
			"timestamp": ping_start_time
		})

#=====================================客户端向服务端发送消息处理=========================================


# 处理服务器返回的pong消息
func handle_pong_response(data = null):
	if is_measuring_ping:
		var current_time = Time.get_unix_time_from_system()
		current_ping = int((current_time - ping_start_time) * 1000)  # 转换为毫秒
		is_measuring_ping = false
		#print("延迟: ", current_ping, "ms")
		
		# 更新连接状态显示
		update_connection_status()

# 更新连接状态显示
func update_connection_status():
	if client.is_client_connected():
		if current_ping >= 0 and not is_measuring_ping:
			# 根据延迟设置颜色和显示文本
			var ping_text = str(current_ping) + "ms"
			var server_name = server_configs[current_server_index]["name"]
			
			if current_ping < 100:
				status_label.text = "✅ " + server_name + " " + ping_text
				status_label.modulate = Color.GREEN
			elif current_ping < 150:
				status_label.text = "🟡 " + server_name + " " + ping_text
				status_label.modulate = Color.YELLOW
			elif current_ping < 300:
				status_label.text = "🟠 " + server_name + " " + ping_text
				status_label.modulate = Color.ORANGE
			else:
				status_label.text = "🔴 " + server_name + " " + ping_text
				status_label.modulate = Color.RED
		else:
			var server_name = server_configs[current_server_index]["name"]
			status_label.text = "🔄 " + server_name + "..."
			status_label.modulate = Color.CYAN
	else:
		status_label.text = "❌ 未连接"
		status_label.modulate = Color.RED

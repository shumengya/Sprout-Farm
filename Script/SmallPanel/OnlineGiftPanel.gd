extends Panel

@onready var one_minute: Button = $Grid/OneMinute
@onready var three_minutes: Button = $Grid/ThreeMinutes
@onready var five_minutes: Button = $Grid/FiveMinutes
@onready var ten_minutes: Button = $Grid/TenMinutes
@onready var thirty_minutes: Button = $Grid/ThirtyMinutes
@onready var one_hour: Button = $Grid/OneHour
@onready var three_hours: Button = $Grid/ThreeHours
@onready var five_hours: Button = $Grid/FiveHours

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



# 在线礼包配置（从服务器动态获取）
var online_gift_config = {}
var gift_time_config = {
	"1分钟": 60,
	"3分钟": 180,
	"5分钟": 300,
	"10分钟": 600,
	"30分钟": 1800,
	"1小时": 3600,
	"3小时": 10800,
	"5小时": 18000
}

# 按钮映射
var button_mapping = {}
# 礼包领取状态
var gift_claimed_status = {}
# 在线开始时间
var online_start_time: float = 0
# 当前在线时长
var current_online_duration: float = 0

func _ready():
	# 初始化按钮映射
	button_mapping = {
		"1分钟": one_minute,
		"3分钟": three_minutes,
		"5分钟": five_minutes,
		"10分钟": ten_minutes,
		"30分钟": thirty_minutes,
		"1小时": one_hour,
		"3小时": three_hours,
		"5小时": five_hours
	}
	
	# 连接按钮信号
	for gift_name in button_mapping.keys():
		var button = button_mapping[gift_name]
		if button:
			button.pressed.connect(_on_gift_button_pressed.bind(gift_name))
	
	# 初始化时禁用所有按钮
	disable_all_buttons()

#显示面板并请求最新数据
func show_panel_and_request_data():
	show()
	move_to_front()
	request_online_gift_data()

#禁用所有礼包按钮
func disable_all_buttons():
	for button in button_mapping.values():
		if button:
			button.disabled = true
			
#更新按钮状态
func update_button_status():
	for gift_name in gift_time_config.keys():
		var button = button_mapping.get(gift_name)
		if not button:
			continue
		
		var required_time = gift_time_config[gift_name]
		var is_claimed = gift_claimed_status.get(gift_name, false)
		
		if is_claimed:
			# 已领取
			button.disabled = true
			button.text = gift_name + "\n(已领取)"
		elif current_online_duration >= required_time:
			# 可以领取
			button.disabled = false
			button.text = gift_name + "\n(可领取)"
		else:
			# 时间未到
			button.disabled = true
			var remaining_time = required_time - current_online_duration
			button.text = gift_name + "\n(" + format_time(remaining_time) + ")"

#格式化时间显示
func format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var minutes = int(int(seconds) % 3600 / 60)
	var secs = int(int(seconds) % 60)
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%02d:%02d" % [minutes, secs]

#处理礼包按钮点击
func _on_gift_button_pressed(gift_name: String):
	if gift_claimed_status.get(gift_name, false):
		Toast.show("该礼包已经领取过了！", Color.RED)
		return
	
	# 发送领取请求到服务器
	request_claim_online_gift(gift_name)
	
#请求在线礼包数据
func request_online_gift_data():
	tcp_network_manager_panel.sendGetOnlineGiftData()
	
#请求领取在线礼包
func request_claim_online_gift(gift_name: String):
	tcp_network_manager_panel.sendClaimOnlineGift(gift_name)

#处理在线礼包数据响应
func handle_online_gift_data_response(data: Dictionary):
	if data.has("claimed_gifts"):
		gift_claimed_status = data["claimed_gifts"]
	
	if data.has("online_start_time"):
		online_start_time = data["online_start_time"]
	
	# 直接使用服务端计算的在线时长
	if data.has("current_online_duration"):
		current_online_duration = data["current_online_duration"]
	
	# 更新按钮状态
	update_button_status()

#处理领取在线礼包响应
func handle_claim_online_gift_response(data: Dictionary):
	var success = data.get("success", false)
	var message = data.get("message", "")
	var gift_name = data.get("gift_name", "")

	
	if success:
		# 标记为已领取
		gift_claimed_status[gift_name] = true
		
		# 显示奖励信息
		var rewards = data.get("rewards", {})
		var reward_text = "获得奖励: "
		
		# 处理中文配置格式的奖励
		if rewards.has("金币"):
			reward_text += "金币+" + str(rewards["金币"]) + " "
		if rewards.has("经验"):
			reward_text += "经验+" + str(rewards["经验"]) + " "
		if rewards.has("种子"):
			for seed in rewards["种子"]:
				reward_text += seed["名称"] + "x" + str(seed["数量"]) + " "
		
		# 兼容老格式
		if rewards.has("钱币"):
			reward_text += "金币+" + str(rewards["钱币"]) + " "
		if rewards.has("经验值"):
			reward_text += "经验+" + str(rewards["经验值"]) + " "
		if rewards.has("seeds"):
			for seed in rewards["seeds"]:
				reward_text += seed["name"] + "x" + str(seed["count"]) + " "
		
		Toast.show(reward_text, Color.GOLD)
		Toast.show(message, Color.GREEN)
		
		# 更新按钮状态
		update_button_status()
	else:
		Toast.show(message, Color.RED)

#关闭在线礼包面板
func _on_quit_button_pressed() -> void:
	self.hide() 

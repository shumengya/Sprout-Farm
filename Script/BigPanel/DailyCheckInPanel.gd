extends Panel
class_name DailyCheckInPanel

signal check_in_completed(rewards: Dictionary)
signal check_in_failed(error_message: String)

@onready var daily_check_in_history: RichTextLabel = $Scroll/DailyCheckInHistory
@onready var daily_check_in_reward: RichTextLabel = $DailyCheckInReward
@onready var daily_check_in_button: Button = $DailyCheckInButton
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'

@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog #确认弹窗


var check_in_history: Dictionary = {}
var consecutive_days: int = 0
var has_checked_in_today: bool = false

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_initialize_system()

func _initialize_system() -> void:
	daily_check_in_reward.hide()
	_update_display()
	_check_daily_status()
	
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		tcp_network_manager_panel.sendGetCheckInData()

func handle_daily_check_in_response(response: Dictionary) -> void:
	var success = response.get("success", false)
	var message = response.get("message", "")
	
	if success:
		var rewards = response.get("rewards", {})
		consecutive_days = response.get("consecutive_days", 0)
		has_checked_in_today = true
		
		# 显示奖励内容
		_show_reward_content(rewards)
		
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1))
		
		check_in_completed.emit(rewards)
		Toast.show(message, Color.GREEN)
	else:
		has_checked_in_today = response.get("has_checked_in", false)
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1)) if has_checked_in_today else _set_button_state(true, "签到", Color(1, 1, 0.52549, 1))
		check_in_failed.emit(message)
		Toast.show(message, Color.RED)

func handle_check_in_data_response(response: Dictionary) -> void:
	var success = response.get("success", false)
	
	if success:
		check_in_history = response.get("check_in_data", {})
		consecutive_days = response.get("consecutive_days", 0)
		has_checked_in_today = response.get("has_checked_in_today", false)
		
		_update_display()
		_check_daily_status()

func _check_daily_status() -> void:
	if has_checked_in_today:
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1))
	else:
		_set_button_state(true, "签到", Color(1, 1, 0.52549, 1))

func _set_button_state(enabled: bool, text: String, color: Color) -> void:
	daily_check_in_button.disabled = not enabled
	daily_check_in_button.text = text
	daily_check_in_button.modulate = color

func execute_check_in() -> void:
	if has_checked_in_today:
		Toast.show("今日已签到，请明日再来", Color.ORANGE)
		return
	
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接到服务器，无法签到", Color.RED)
		return
	
	tcp_network_manager_panel.sendDailyCheckIn()
	daily_check_in_button.disabled = true
	daily_check_in_button.text = "签到中..."
	
	await get_tree().create_timer(3.0).timeout
	if daily_check_in_button.disabled and daily_check_in_button.text == "签到中...":
		daily_check_in_button.disabled = false
		daily_check_in_button.text = "签到"


func _format_reward_text(rewards: Dictionary) -> String:
	var text = ""
	
	text += "[center][color=#FF69B4]🔥 连续签到第%d天 🔥[/color][/center]\n" % consecutive_days
	if consecutive_days > 1:
		var multiplier = 1.0 + (consecutive_days - 1) * 0.1
		multiplier = min(multiplier, 3.0)
		text += "[center][color=#90EE90]奖励倍数: %.1fx[/color][/center]\n\n" % multiplier
	else:
		text += "\n"
	
	if rewards.has("coins"):
		text += "[color=#FFD700]💰 +%d 金币[/color]\n" % rewards.coins
	
	if rewards.has("exp"):
		text += "[color=#00BFFF]⭐ +%d 经验[/color]\n" % rewards.exp
	
	if rewards.has("seeds") and rewards.seeds.size() > 0:
		for seed_reward in rewards.seeds:
			var seed_name = seed_reward.name
			var quantity = seed_reward.quantity
			var quality = seed_reward.quality
			var rarity_color = _get_rarity_color(quality)
			
			text += "[color=%s]🌱 %s x%d[/color] [color=%s](%s)[/color]\n" % [
				rarity_color, seed_name, quantity, rarity_color, quality
			]
	
	if rewards.has("bonus_coins"):
		text += "\n[color=#FFD700]🎁 连续签到奖励:[/color]\n"
		text += "[color=#FFD700]💰 +%d 额外金币[/color] [color=#FFD700]✨[/color]\n" % rewards.bonus_coins
	
	if rewards.has("bonus_exp"):
		if not rewards.has("bonus_coins"):
			text += "\n[color=#FFD700]🎁 连续签到奖励:[/color]\n"
		text += "[color=#00BFFF]⭐ +%d 额外经验[/color] [color=#FFD700]✨[/color]\n" % rewards.bonus_exp
	
	var next_bonus_day = 0
	if consecutive_days < 3:
		next_bonus_day = 3
	elif consecutive_days < 7:
		next_bonus_day = 7
	elif consecutive_days < 14:
		next_bonus_day = 14
	elif consecutive_days < 21:
		next_bonus_day = 21
	elif consecutive_days < 30:
		next_bonus_day = 30
	
	if next_bonus_day > 0:
		var days_needed = next_bonus_day - consecutive_days
		text += "\n[center][color=#87CEEB]再签到%d天可获得特殊奖励！[/color][/center]" % days_needed
	
	return text

func _get_rarity_color(rarity: String) -> String:
	match rarity:
		"普通": return "#90EE90"
		"优良": return "#87CEEB"
		"稀有": return "#DDA0DD"
		"史诗": return "#9932CC"
		"传奇": return "#FF8C00"
		_: return "#FFFFFF"

func _show_reward_content(rewards: Dictionary) -> void:
	var reward_text = _format_reward_text(rewards)
	daily_check_in_reward.text = reward_text
	daily_check_in_reward.show()

func _update_display() -> void:
	var history_text = "[center][color=#FFB6C1]📋 签到历史[/color][/center]\n"
	
	if consecutive_days > 0:
		history_text += "[center][color=#FF69B4]🔥 当前连续签到: %d天[/color][/center]\n" % consecutive_days
		if consecutive_days >= 30:
			history_text += "[center][color=#FFD700]⭐ 已达到最高连击等级！ ⭐[/color][/center]\n"
	else:
		history_text += "[center][color=#DDDDDD]还未开始连续签到[/color][/center]\n"
	
	history_text += "\n"
	
	if check_in_history.size() == 0:
		history_text += "[center][color=#DDDDDD]暂无签到记录[/color][/center]"
	else:
		# 按时间排序显示历史记录
		var sorted_times = check_in_history.keys()
		sorted_times.sort()
		sorted_times.reverse()
		
		for time_key in sorted_times:
			var reward_text = check_in_history[time_key]
			history_text += "[color=#87CEEB]%s[/color]  [color=#90EE90]%s[/color]\n" % [time_key, reward_text]
			history_text += "---------------------------------------------\n"
	
	daily_check_in_history.text = history_text

# 事件处理
func _on_quit_button_pressed() -> void:
	self.hide()

func _on_daily_check_in_button_pressed() -> void:
	# 显示确认弹窗
	confirm_dialog.title = "每日签到确认"
	confirm_dialog.dialog_text = "确定要进行今日签到吗？\n签到可获得金币、经验和种子奖励！"
	confirm_dialog.popup_centered()
	
	# 连接确认信号（如果还没连接的话）
	if not confirm_dialog.confirmed.is_connected(_on_confirm_check_in):
		confirm_dialog.confirmed.connect(_on_confirm_check_in)

func _on_confirm_check_in() -> void:
	execute_check_in()

func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
	else:
		GlobalVariables.isZoomDisabled = false

# 公共接口
func refresh_check_in_data() -> void:
	if tcp_network_manager_panel and tcp_network_manager_panel.is_connected_to_server():
		tcp_network_manager_panel.sendGetCheckInData()

func get_check_in_status() -> Dictionary:
	return {
		"has_checked_in_today": has_checked_in_today,
		"consecutive_days": consecutive_days
	}

	

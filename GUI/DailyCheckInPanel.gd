extends Panel
class_name DailyCheckInPanel

## 每日签到系统 - 后端对接版本
## 功能：与服务器对接的签到系统，支持实时数据同步
## 奖励平衡性已根据 crop_data.json 调整

# =============================================================================
# 信号定义 - 用于与后端系统通信
# =============================================================================
signal check_in_completed(rewards: Dictionary)  # 签到完成信号
signal reward_claimed(reward_type: String, amount: int)  # 奖励领取信号
signal check_in_data_loaded(data: Dictionary)  # 签到数据加载完成信号
signal check_in_failed(error_message: String)  # 签到失败信号

# =============================================================================
# 节点引用
# =============================================================================
@onready var daily_check_in_history: RichTextLabel = $Scroll/DailyCheckInHistory
@onready var daily_check_in_reward: RichTextLabel = $DailyCheckInReward
@onready var daily_check_in_button: Button = $DailyCheckInButton

# =============================================================================
# 数据存储
# =============================================================================
var check_in_data: Dictionary = {}
var today_date: String
var consecutive_days: int = 0
var has_checked_in_today: bool = false

# 网络管理器引用
var network_manager
var main_game

# =============================================================================
# 奖励配置系统 - 根据 crop_data.json 平衡调整
# =============================================================================
var reward_configs: Dictionary = {
	"coins": {
		"min": 200,
		"max": 500,
		"name": "钱币",
		"color": "#FFD700",
		"icon": "💰"
	},
	"exp": {
		"min": 50,
		"max": 120,
		"name": "经验",
		"color": "#00BFFF",
		"icon": "⭐"
	},
	# 种子配置根据 crop_data.json 的作物等级和价值设定
	"seeds": {
		"普通": [
			{"name": "小麦", "color": "#F4A460", "icon": "🌱", "rarity_color": "#FFFFFF"},
			{"name": "胡萝卜", "color": "#FFA500", "icon": "🌱", "rarity_color": "#FFFFFF"},
			{"name": "土豆", "color": "#D2691E", "icon": "🌱", "rarity_color": "#FFFFFF"},
			{"name": "稻谷", "color": "#DAA520", "icon": "🌱", "rarity_color": "#FFFFFF"}
		],
		"优良": [
			{"name": "玉米", "color": "#FFD700", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "番茄", "color": "#FF6347", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "洋葱", "color": "#DDA0DD", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "大豆", "color": "#8FBC8F", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "豌豆", "color": "#90EE90", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "黄瓜", "color": "#32CD32", "icon": "🌱", "rarity_color": "#00FF00"},
			{"name": "大白菜", "color": "#F0FFF0", "icon": "🌱", "rarity_color": "#00FF00"}
		],
		"稀有": [
			{"name": "草莓", "color": "#FF69B4", "icon": "🌱", "rarity_color": "#0080FF"},
			{"name": "花椰菜", "color": "#F5F5DC", "icon": "🌱", "rarity_color": "#0080FF"},
			{"name": "柿子", "color": "#FF4500", "icon": "🌱", "rarity_color": "#0080FF"},
			{"name": "蓝莓", "color": "#4169E1", "icon": "🌱", "rarity_color": "#0080FF"},
			{"name": "树莓", "color": "#DC143C", "icon": "🌱", "rarity_color": "#0080FF"}
		],
		"史诗": [
			{"name": "葡萄", "color": "#9370DB", "icon": "🌱", "rarity_color": "#8A2BE2"},
			{"name": "南瓜", "color": "#FF8C00", "icon": "🌱", "rarity_color": "#8A2BE2"},
			{"name": "芦笋", "color": "#9ACD32", "icon": "🌱", "rarity_color": "#8A2BE2"},
			{"name": "茄子", "color": "#9400D3", "icon": "🌱", "rarity_color": "#8A2BE2"},
			{"name": "向日葵", "color": "#FFD700", "icon": "🌱", "rarity_color": "#8A2BE2"},
			{"name": "蕨菜", "color": "#228B22", "icon": "🌱", "rarity_color": "#8A2BE2"}
		],
		"传奇": [
			{"name": "西瓜", "color": "#FF69B4", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "甘蔗", "color": "#DDA0DD", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "香草", "color": "#98FB98", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "甜菜", "color": "#DC143C", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "人参", "color": "#DAA520", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "富贵竹", "color": "#32CD32", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "芦荟", "color": "#9ACD32", "icon": "🌱", "rarity_color": "#FF8C00"},
			{"name": "哈密瓜", "color": "#FFB6C1", "icon": "🌱", "rarity_color": "#FF8C00"}
		]
	}
}

# =============================================================================
# 系统初始化
# =============================================================================
func _ready() -> void:
	_initialize_system()

func _initialize_system() -> void:
	"""初始化签到系统"""
	daily_check_in_reward.hide()
	today_date = Time.get_date_string_from_system()
	
	# 获取网络管理器和主游戏引用
	network_manager = get_node("/root/main/UI/TCPNetworkManager")
	main_game = get_node("/root/main")
	
	_update_display()
	_check_daily_status()
	
	# 从服务器加载签到数据
	if network_manager and network_manager.is_connected_to_server():
		network_manager.sendGetCheckInData()

# =============================================================================
# 网络后端交互方法
# =============================================================================

## 处理服务器签到响应
func handle_daily_check_in_response(response: Dictionary) -> void:
	var success = response.get("success", false)
	var message = response.get("message", "")
	
	if success:
		var rewards = response.get("rewards", {})
		consecutive_days = response.get("consecutive_days", 0)
		has_checked_in_today = true
		
		# 显示奖励
		_show_reward_animation(rewards)
		
		# 更新按钮状态
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1))
		
		# 发送完成信号
		check_in_completed.emit(rewards)
		
		# 发送奖励信号
		for reward_type in rewards.keys():
			if reward_type == "seeds":
				for seed_reward in rewards.seeds:
					reward_claimed.emit("seed_" + seed_reward.name, seed_reward.quantity)
			elif reward_type in ["coins", "exp", "bonus_coins", "bonus_exp"]:
				reward_claimed.emit(reward_type, rewards[reward_type])
		
		Toast.show(message, Color.GREEN)
		print("签到成功: ", message)
	else:
		has_checked_in_today = response.get("has_checked_in", false)
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1)) if has_checked_in_today else _set_button_state(true, "签到", Color(1, 1, 0.52549, 1))
		check_in_failed.emit(message)
		Toast.show(message, Color.RED)
		print("签到失败: ", message)

## 处理服务器签到数据响应
func handle_check_in_data_response(response: Dictionary) -> void:
	var success = response.get("success", false)
	
	if success:
		check_in_data = response.get("check_in_data", {})
		consecutive_days = response.get("consecutive_days", 0)
		has_checked_in_today = response.get("has_checked_in_today", false)
		today_date = response.get("current_date", Time.get_date_string_from_system())
		
		# 更新显示
		_update_display()
		_check_daily_status()
		
		# 发送数据加载完成信号
		check_in_data_loaded.emit(check_in_data)
		
		print("签到数据加载成功，连续签到：", consecutive_days, "天")
	else:
		print("加载签到数据失败")

# =============================================================================
# 核心业务逻辑
# =============================================================================

## 检查今日签到状态
func _check_daily_status() -> void:
	if has_checked_in_today:
		_set_button_state(false, "已签到", Color(0.7, 0.7, 0.7, 1))
	else:
		_set_button_state(true, "签到", Color(1, 1, 0.52549, 1))

## 设置按钮状态
func _set_button_state(enabled: bool, text: String, color: Color) -> void:
	daily_check_in_button.disabled = not enabled
	daily_check_in_button.text = text
	daily_check_in_button.modulate = color

## 执行签到
func execute_check_in() -> void:
	if has_checked_in_today:
		Toast.show("今日已签到，请明日再来", Color.ORANGE)
		return
	
	if not network_manager or not network_manager.is_connected_to_server():
		Toast.show("未连接到服务器，无法签到", Color.RED)
		return
	
	# 发送签到请求到服务器
	network_manager.sendDailyCheckIn()
	daily_check_in_button.disabled = true
	daily_check_in_button.text = "签到中..."
	
	# 3秒后重新启用按钮（防止网络超时）
	await get_tree().create_timer(3.0).timeout
	if daily_check_in_button.disabled and daily_check_in_button.text == "签到中...":
		daily_check_in_button.disabled = false
		daily_check_in_button.text = "签到"

## 显示奖励动画
func _show_reward_animation(rewards: Dictionary) -> void:
	daily_check_in_reward.text = _format_reward_text(rewards)
	daily_check_in_reward.show()
	
	# 创建动画效果
	var tween = create_tween()
	tween.parallel().tween_method(_animate_reward_display, 0.0, 1.0, 0.5)

## 奖励显示动画
func _animate_reward_display(progress: float) -> void:
	daily_check_in_reward.modulate.a = progress
	var scale = 0.8 + (0.2 * progress)
	daily_check_in_reward.scale = Vector2(scale, scale)

# =============================================================================
# UI显示格式化
# =============================================================================

## 格式化奖励显示文本
func _format_reward_text(rewards: Dictionary) -> String:
	var text = ""
	
	# 显示连续签到信息
	text += "[center][color=#FF69B4]🔥 连续签到第%d天 🔥[/color][/center]\n" % consecutive_days
	if consecutive_days > 1:
		var multiplier = 1.0 + (consecutive_days - 1) * 0.1
		multiplier = min(multiplier, 3.0)
		text += "[center][color=#90EE90]奖励倍数: %.1fx[/color][/center]\n\n" % multiplier
	else:
		text += "\n"
	
	# 基础奖励
	if rewards.has("coins"):
		text += "[color=%s]%s +%d %s[/color]\n" % [
			reward_configs.coins.color,
			reward_configs.coins.icon,
			rewards.coins,
			reward_configs.coins.name
		]
	
	if rewards.has("exp"):
		text += "[color=%s]%s +%d %s[/color]\n" % [
			reward_configs.exp.color,
			reward_configs.exp.icon,
			rewards.exp,
			reward_configs.exp.name
		]
	
	# 种子奖励
	if rewards.has("seeds") and rewards.seeds.size() > 0:
		for seed_reward in rewards.seeds:
			var seed_name = seed_reward.name
			var quantity = seed_reward.quantity
			var quality = seed_reward.quality
			
			# 从配置中找到对应的种子信息
			var seed_info = _get_seed_info(seed_name, quality)
			if seed_info:
				text += "[color=%s]%s[/color] [color=%s]%s[/color] x%d [color=%s](%s)[/color]\n" % [
					seed_info.color, seed_info.icon, seed_info.color, seed_name, quantity, seed_info.rarity_color, quality
				]
	
	# 连续签到额外奖励
	if rewards.has("bonus_coins"):
		text += "\n[color=#FFD700]🎁 连续签到奖励:[/color]\n"
		text += "[color=%s]%s +%d %s[/color] [color=#FFD700]✨[/color]\n" % [
			reward_configs.coins.color,
			reward_configs.coins.icon,
			rewards.bonus_coins,
			reward_configs.coins.name
		]
	
	if rewards.has("bonus_exp"):
		if not rewards.has("bonus_coins"):
			text += "\n[color=#FFD700]🎁 连续签到奖励:[/color]\n"
		text += "[color=%s]%s +%d %s[/color] [color=#FFD700]✨[/color]\n" % [
			reward_configs.exp.color,
			reward_configs.exp.icon,
			rewards.bonus_exp,
			reward_configs.exp.name
		]
	
	# 下一个奖励预告
	var next_bonus_day = 0
	if consecutive_days < 3:
		next_bonus_day = 3
	elif consecutive_days < 7:
		next_bonus_day = 7
	elif consecutive_days < 14:
		next_bonus_day = 14
	elif consecutive_days < 21:
		next_bonus_day = 21
	
	if next_bonus_day > 0:
		var days_needed = next_bonus_day - consecutive_days
		text += "\n[center][color=#87CEEB]再签到%d天可获得特殊奖励！[/color][/center]" % days_needed
	
	return text

## 获取种子信息
func _get_seed_info(seed_name: String, quality: String) -> Dictionary:
	if quality in reward_configs.seeds:
		for seed in reward_configs.seeds[quality]:
			if seed.name == seed_name:
				return seed
	return {}

## 格式化历史记录文本
func _format_history_text(date: String, rewards: Dictionary) -> String:
	var text = "[color=#87CEEB]📅 %s[/color]  " % date
	
	var reward_parts = []
	if rewards.has("coins"):
		reward_parts.append("[color=%s]%s %d[/color]" % [
			reward_configs.coins.color,
			reward_configs.coins.name,
			rewards.coins
		])
	
	if rewards.has("exp"):
		reward_parts.append("[color=%s]%s %d[/color]" % [
			reward_configs.exp.color,
			reward_configs.exp.name,
			rewards.exp
		])
	
	if rewards.has("seeds") and rewards.seeds.size() > 0:
		for seed_reward in rewards.seeds:
			var seed_name = seed_reward.name
			var quantity = seed_reward.quantity
			var quality = seed_reward.quality
			var seed_info = _get_seed_info(seed_name, quality)
			if seed_info:
				reward_parts.append("[color=%s]%s x%d[/color]" % [
					seed_info.color, seed_name, quantity
				])
	
	text += " ".join(reward_parts)
	return text

## 更新显示内容
func _update_display() -> void:
	var history_text = "[center][color=#FFB6C1]📋 签到历史[/color][/center]\n"
	
	# 显示连续签到状态
	if consecutive_days > 0:
		history_text += "[center][color=#FF69B4]🔥 当前连续签到: %d天[/color][/center]\n" % consecutive_days
		if consecutive_days >= 30:
			history_text += "[center][color=#FFD700]⭐ 已达到最高连击等级！ ⭐[/color][/center]\n"
	else:
		history_text += "[center][color=#DDDDDD]还未开始连续签到[/color][/center]\n"
	
	history_text += "\n"
	
	if check_in_data.size() == 0:
		history_text += "[center][color=#DDDDDD]暂无签到记录[/color][/center]"
	else:
		# 按日期排序显示历史记录
		var sorted_dates = check_in_data.keys()
		sorted_dates.sort()
		sorted_dates.reverse()  # 最新的在前
		
		for date in sorted_dates:
			var day_data = check_in_data[date]
			var rewards = day_data.get("rewards", {})
			var day_consecutive = day_data.get("consecutive_days", 1)
			
			history_text += _format_history_text(date, rewards)
			history_text += " [color=#90EE90](连续%d天)[/color]\n" % day_consecutive
			history_text += "-----------------------------------------------------------------------------------------------------------------\n"
	
	daily_check_in_history.text = history_text

# =============================================================================
# 事件处理
# =============================================================================

## 关闭面板按钮
func _on_quit_button_pressed() -> void:
	self.hide()

## 签到按钮
func _on_daily_check_in_button_pressed() -> void:
	execute_check_in()

# =============================================================================
# 公共接口方法 - 供主游戏调用
# =============================================================================

## 刷新签到数据
func refresh_check_in_data() -> void:
	if network_manager and network_manager.is_connected_to_server():
		network_manager.sendGetCheckInData()

## 获取当前签到状态
func get_check_in_status() -> Dictionary:
	return {
		"has_checked_in_today": has_checked_in_today,
		"consecutive_days": consecutive_days,
		"today_date": today_date
	}

	

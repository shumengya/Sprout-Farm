extends Panel
class_name LuckyDrawPanel


signal draw_completed(rewards: Array, draw_type: String)  # 抽奖完成信号
signal reward_obtained(reward_type: String, amount: int)  # 奖励获得信号
signal draw_failed(error_message: String)  # 抽奖失败信号


#这个展示抽奖获得的奖励
@onready var lucky_draw_reward: RichTextLabel = $LuckyDrawReward
#这个是展示有哪些奖励选项，最多15个，奖励就在这里面随机挑选
@onready var grid: GridContainer = $Grid
#这个是奖励模板
@onready var reward_item: RichTextLabel = $Grid/RewardItem

var reward_templates: Array[RichTextLabel] = []
var current_rewards: Array = []
@onready var main_game = get_node("/root/main")

@onready var daily_check_in_panel: DailyCheckInPanel = $'../DailyCheckInPanel'
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'
@onready var item_store_panel: Panel = $'../ItemStorePanel'
@onready var item_bag_panel: Panel = $'../ItemBagPanel'
@onready var player_bag_panel: Panel = $'../PlayerBagPanel'
@onready var crop_warehouse_panel: Panel = $'../CropWarehousePanel'
@onready var crop_store_panel: Panel = $'../CropStorePanel'
@onready var player_ranking_panel: Panel = $'../PlayerRankingPanel'
@onready var login_panel: PanelContainer = $'../LoginPanel'


# 15种不同的模板颜色
var template_colors: Array[Color] = [
	Color(1.0, 0.8, 0.8, 1.0),    # 淡红色
	Color(0.8, 1.0, 0.8, 1.0),    # 淡绿色
	Color(0.8, 0.8, 1.0, 1.0),    # 淡蓝色
	Color(1.0, 1.0, 0.8, 1.0),    # 淡黄色
	Color(1.0, 0.8, 1.0, 1.0),    # 淡紫色
	Color(0.8, 1.0, 1.0, 1.0),    # 淡青色
	Color(1.0, 0.9, 0.8, 1.0),    # 淡橙色
	Color(0.9, 0.8, 1.0, 1.0),    # 淡紫蓝色
	Color(0.8, 1.0, 0.9, 1.0),    # 淡薄荷色
	Color(1.0, 0.8, 0.9, 1.0),    # 淡粉色
	Color(0.9, 1.0, 0.8, 1.0),    # 淡柠檬色
	Color(0.8, 0.9, 1.0, 1.0),    # 淡天蓝色
	Color(1.0, 0.95, 0.8, 1.0),   # 淡香槟色
	Color(0.85, 0.8, 1.0, 1.0),   # 淡薰衣草色
	Color(0.95, 1.0, 0.85, 1.0)   # 淡春绿色
]

var anticipation_tween: Tween = null

var base_rewards: Dictionary = {
	"coins": {"name": "金币", "icon": "💰", "color": "#FFD700"},
	"exp": {"name": "经验", "icon": "⭐", "color": "#00BFFF"},
	"empty": {"name": "谢谢惠顾", "icon": "😅", "color": "#CCCCCC"}
}

var seed_rewards: Dictionary = {}

# 抽奖费用配置
var draw_costs: Dictionary = {
	"single": 800,
	"five": 3600,  # 800 * 5 * 0.9 = 3600
	"ten": 6400    # 800 * 10 * 0.8 = 6400
}

var server_reward_pools: Dictionary = {}

func _ready() -> void:
	_initialize_system()

#初始化抽奖系统
func _initialize_system() -> void:
	
	# 连接信号
	if main_game:
		draw_completed.connect(main_game._on_lucky_draw_completed)
		draw_failed.connect(main_game._on_lucky_draw_failed)
	
	lucky_draw_reward.hide()
	_load_crop_data_and_build_rewards()
	_generate_reward_templates()
	_update_template_display()

#从主游戏加载作物数据并构建种子奖励
func _load_crop_data_and_build_rewards() -> void:
	if main_game and main_game.has_method("get_crop_data"):
		var crop_data = main_game.get_crop_data()
		if crop_data:
			_build_seed_rewards_from_crop_data(crop_data)

#根据 crop_data.json 构建种子奖励配置
func _build_seed_rewards_from_crop_data(crop_data: Dictionary) -> void:
	seed_rewards.clear()
	
	for crop_name in crop_data.keys():
		var crop_info = crop_data[crop_name]
		
		# 跳过测试作物和不能购买的作物
		if crop_name == "测试作物" or not crop_info.get("能否购买", true):
			continue
		
		var quality = crop_info.get("品质", "普通")
		var rarity_color = _get_rarity_color(quality)
		
		seed_rewards[crop_name] = {
			"icon": "🌱", 
			"color": rarity_color, 
			"rarity": quality,
			"level": crop_info.get("等级", 1),
			"cost": crop_info.get("花费", 50)
		}

#根据稀有度获取颜色
func _get_rarity_color(rarity: String) -> String:
	match rarity:
		"普通":
			return "#90EE90"
		"优良":
			return "#87CEEB"
		"稀有":
			return "#DDA0DD"
		"史诗":
			return "#9932CC"
		"传奇":
			return "#FF8C00"
		_:
			return "#FFFFFF"


## 生成15个奖励模板
func _generate_reward_templates() -> void:
	# 清空现有模板
	for child in grid.get_children():
		if child != reward_item:
			child.queue_free()
	
	reward_templates.clear()
	
	# 生成15个模板（包括原有的一个）
	for i in range(15):
		var template: RichTextLabel
		
		if i == 0:
			# 使用原有的模板
			template = reward_item
		else:
			# 创建新的模板
			template = reward_item.duplicate()
			grid.add_child(template)
		
		# 设置不同的颜色
		template.self_modulate = template_colors[i]
		template.bbcode_enabled = true
		template.threaded = true
		
		reward_templates.append(template)

## 更新模板显示
func _update_template_display() -> void:
	var sample_rewards = _generate_sample_rewards()
	
	for i in range(reward_templates.size()):
		var template = reward_templates[i]
		if i < sample_rewards.size():
			var reward = sample_rewards[i]
			template.text = _format_template_text(reward)
			template.show()
		else:
			template.hide()

## 生成示例奖励显示
func _generate_sample_rewards() -> Array:
	var sample_rewards = []
	
	# 添加基础奖励示例
	sample_rewards.append({"type": "coins", "amount_range": [100, 300], "rarity": "普通"})
	sample_rewards.append({"type": "exp", "amount_range": [50, 150], "rarity": "普通"})
	sample_rewards.append({"type": "empty", "name": "谢谢惠顾", "rarity": "空奖"})
	
	# 添加各品质种子示例
	var quality_examples = ["普通", "优良", "稀有", "史诗", "传奇"]
	for quality in quality_examples:
		var example_seeds = []
		for seed_name in seed_rewards.keys():
			if seed_rewards[seed_name].rarity == quality:
				example_seeds.append(seed_name)
		
		if example_seeds.size() > 0:
			var seed_name = example_seeds[0]  # 取第一个作为示例
			sample_rewards.append({
				"type": "seed", 
				"name": seed_name, 
				"rarity": quality,
				"amount_range": [1, 3] if quality != "传奇" else [1, 1]
			})
	
	# 添加礼包示例
	sample_rewards.append({"type": "package", "name": "成长套餐", "rarity": "优良"})
	sample_rewards.append({"type": "package", "name": "稀有礼包", "rarity": "稀有"})
	sample_rewards.append({"type": "package", "name": "传奇大礼包", "rarity": "传奇"})
	
	# 添加高级奖励示例
	sample_rewards.append({"type": "coins", "amount_range": [1000, 2000], "rarity": "史诗"})
	sample_rewards.append({"type": "exp", "amount_range": [500, 1000], "rarity": "传奇"})
	
	return sample_rewards.slice(0, 15)  # 只取前15个

## 格式化模板文本
func _format_template_text(reward: Dictionary) -> String:
	var text = "[center]"
	
	match reward.type:
		"empty":
			text += "[color=%s]%s[/color]\n" % [base_rewards.empty.color, base_rewards.empty.icon]
			text += "[color=%s]%s[/color]" % [base_rewards.empty.color, reward.get("name", "谢谢惠顾")]
		
		"package":
			var rarity_color = _get_rarity_color(reward.get("rarity", "普通"))
			text += "[color=%s]🎁[/color]\n" % [rarity_color]
			text += "[color=%s]%s[/color]\n" % [rarity_color, reward.get("name", "礼包")]
			text += "[color=#CCCCCC](%s)[/color]" % reward.get("rarity", "普通")
		
		"coins":
			var rarity_color = _get_rarity_color(reward.get("rarity", "普通"))
			text += "[color=%s]%s[/color]\n" % [rarity_color, base_rewards.coins.icon]
			if reward.has("amount_range"):
				text += "[color=%s]%d-%d[/color]\n" % [rarity_color, reward.amount_range[0], reward.amount_range[1]]
			text += "[color=%s]%s[/color]" % [rarity_color, base_rewards.coins.name]
		
		"exp":
			var rarity_color = _get_rarity_color(reward.get("rarity", "普通"))
			text += "[color=%s]%s[/color]\n" % [rarity_color, base_rewards.exp.icon]
			if reward.has("amount_range"):
				text += "[color=%s]%d-%d[/color]\n" % [rarity_color, reward.amount_range[0], reward.amount_range[1]]
			text += "[color=%s]%s[/color]" % [rarity_color, base_rewards.exp.name]
		
		"seed":
			if reward.has("name") and reward.name in seed_rewards:
				var seed_info = seed_rewards[reward.name]
				text += "[color=%s]%s[/color]\n" % [seed_info.color, seed_info.icon]
				text += "[color=%s]%s[/color]\n" % [seed_info.color, reward.name]
				if reward.has("amount_range"):
					text += "[color=%s]x%d-%d[/color]\n" % [seed_info.color, reward.amount_range[0], reward.amount_range[1]]
				text += "[color=#CCCCCC](%s)[/color]" % seed_info.rarity
			else:
				text += "[color=#90EE90]🌱[/color]\n"
				text += "[color=#90EE90]种子[/color]"
	
	text += "[/center]"
	return text

## 执行网络抽奖
func _perform_network_draw(draw_type: String) -> void:
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		_show_error_message("网络未连接，无法进行抽奖")
		return
	
	# 检查费用
	var cost = draw_costs.get(draw_type, 800)
	if main_game and main_game.money < cost:
		_show_error_message("金币不足，需要 %d 金币" % cost)
		return
	
	# 发送抽奖请求
	var success = tcp_network_manager_panel.sendLuckyDraw(draw_type)
	if not success:
		_show_error_message("发送抽奖请求失败")
		return
	
	# 显示等待动画
	_show_waiting_animation(draw_type)

## 显示等待动画
func _show_waiting_animation(draw_type: String) -> void:
	# 禁用抽奖按钮
	_set_draw_buttons_enabled(false)
	
	# 隐藏结果区域
	lucky_draw_reward.hide()
	
	# 播放期待动画
	_play_anticipation_animation()

## 处理服务器抽奖响应
func handle_lucky_draw_response(response: Dictionary) -> void:
	# 停止期待动画
	_stop_anticipation_animation()
	
	# 重新启用按钮
	_set_draw_buttons_enabled(true)
	
	if response.get("success", false):
		var rewards = response.get("rewards", [])
		var draw_type = response.get("draw_type", "single")
		var cost = response.get("cost", 0)
		
		# 显示抽奖结果
		_show_server_draw_results(rewards, draw_type, cost)
		
		# 发送信号
		draw_completed.emit(rewards, draw_type)
		
	else:
		var error_message = response.get("message", "抽奖失败")
		_show_error_message(error_message)
		draw_failed.emit(error_message)

## 显示服务器返回的抽奖结果
func _show_server_draw_results(rewards: Array, draw_type: String, cost: int) -> void:
	current_rewards = rewards
	
	# 显示结果（动画已在handle_lucky_draw_response中停止）
	var result_text = _format_server_draw_results(rewards, draw_type, cost)
	lucky_draw_reward.text = result_text
	lucky_draw_reward.show()
	
	# 播放结果动画
	_play_result_animation()

## 格式化服务器抽奖结果文本
func _format_server_draw_results(rewards: Array, draw_type: String, cost: int) -> String:
	var type_names = {
		"single": "单抽",
		"five": "五连抽", 
		"ten": "十连抽"
	}
	
	var text = "[center][color=#FFD700]🎊 %s结果 🎊[/color][/center]\n" % type_names.get(draw_type, draw_type)
	text += "[center][color=#87CEEB]消费 %d 金币[/color][/center]\n" % cost
	
	# 统计稀有度
	var stats = _count_server_reward_rarity(rewards)
	
	# 显示稀有度统计
	var stat_parts = []
	if stats.legendary > 0:
		stat_parts.append("[color=#FF8C00]🏆传奇x%d[/color]" % stats.legendary)
	if stats.epic > 0:
		stat_parts.append("[color=#9932CC]💎史诗x%d[/color]" % stats.epic)
	if stats.rare > 0:
		stat_parts.append("[color=#DDA0DD]⭐稀有x%d[/color]" % stats.rare)
	if stats.package > 0:
		stat_parts.append("[color=#FF69B4]🎁礼包x%d[/color]" % stats.package)
	
	if stat_parts.size() > 0:
		text += "[center]%s[/center]\n" % " ".join(stat_parts)
	
	text += "\n"
	
	# 显示具体奖励
	for reward in rewards:
		text += _format_single_server_reward(reward) + "\n"
	
	# 鼓励文案
	if stats.empty_only:
		text += "[center][color=#87CEEB]💪 别灰心，下次一定能中大奖！[/color][/center]"
	elif stats.legendary > 0:
		text += "[center][color=#FF8C00]🎉 恭喜获得传奇奖励！[/color][/center]"
	elif stats.epic > 0:
		text += "[center][color=#9932CC]✨ 史诗奖励，运气不错！[/color][/center]"
	
	return text

## 统计服务器奖励稀有度
func _count_server_reward_rarity(rewards: Array) -> Dictionary:
	var stats = {
		"legendary": 0,
		"epic": 0,
		"rare": 0,
		"package": 0,
		"empty": 0,
		"empty_only": false
	}
	
	for reward in rewards:
		var rarity = reward.get("rarity", "普通")
		match rarity:
			"传奇":
				stats.legendary += 1
			"史诗":
				stats.epic += 1
			"稀有":
				stats.rare += 1
			"空奖":
				stats.empty += 1
		
		if reward.get("type") == "package":
			stats.package += 1
	
	stats.empty_only = (stats.empty == rewards.size() and rewards.size() == 1)
	return stats

## 格式化单个服务器奖励显示
func _format_single_server_reward(reward: Dictionary) -> String:
	var text = ""
	var reward_type = reward.get("type", "")
	var rarity = reward.get("rarity", "普通")
	var rarity_color = _get_rarity_color(rarity)
	
	match reward_type:
		"empty":
			var reward_name = reward.get("name", "空奖励")
			text = "[color=%s]😅 %s[/color]" % [rarity_color, reward_name]
		
		"package":
			var reward_name = reward.get("name", "礼包")
			text = "[color=%s]🎁 %s[/color]\n" % [rarity_color, reward_name]
			text += "[color=#DDDDDD]内含:[/color] "
			
			var content_parts = []
			if reward.has("contents"):
				for content in reward.contents:
					var part = _format_package_content(content)
					if part != "":
						content_parts.append(part)
			
			text += " ".join(content_parts)
		
		"coins":
			var amount = reward.get("amount", 0)
			text = "[color=%s]💰 金币 +%d[/color]" % [rarity_color, amount]
		
		"exp":
			var amount = reward.get("amount", 0)
			text = "[color=%s]⭐ 经验 +%d[/color]" % [rarity_color, amount]
		
		"seed":
			var reward_name = reward.get("name", "种子")
			var amount = reward.get("amount", 0)
			text = "[color=%s]🌱 %s x%d[/color] [color=#CCCCCC](%s)[/color]" % [
				rarity_color, reward_name, amount, rarity
			]
		
		_:
			text = "[color=#CCCCCC]未知奖励[/color]"
	
	return text

## 格式化礼包内容
func _format_package_content(content: Dictionary) -> String:
	var content_type = content.get("type", "")
	var amount = content.get("amount", 0)
	
	match content_type:
		"coins":
			return "[color=#FFD700]💰%d[/color]" % amount
		"exp":
			return "[color=#00BFFF]⭐%d[/color]" % amount
		"seed":
			var seed_name = content.get("name", "种子")
			return "[color=#90EE90]🌱%sx%d[/color]" % [seed_name, amount]
		_:
			return ""

## 播放期待动画（简化版）
func _play_anticipation_animation() -> void:
	"""播放期待动画"""
	# 停止之前的动画
	_stop_anticipation_animation()
	
	# 创建简单的闪烁动画
	anticipation_tween = create_tween()
	anticipation_tween.set_loops()
	
	for template in reward_templates:
		if template.visible:
			anticipation_tween.parallel().tween_method(
				func(progress: float): _anticipation_flash(template, progress),
				0.0, 1.0, 0.5
			)



func _anticipation_flash(template: RichTextLabel, progress: float) -> void:
	"""期待动画闪烁效果"""
	var flash_intensity = 1.0 + sin(progress * PI * 2) * 0.3
	template.modulate = Color(flash_intensity, flash_intensity, flash_intensity, 1.0)

## 停止期待动画
func _stop_anticipation_animation() -> void:
	if anticipation_tween:
		anticipation_tween.kill()
		anticipation_tween = null
	
	# 恢复所有模板的正常颜色
	for i in range(reward_templates.size()):
		var template = reward_templates[i]
		template.modulate = Color.WHITE

## 播放结果动画
func _play_result_animation() -> void:
	var tween = create_tween()
	
	# 奖励区域动画
	lucky_draw_reward.modulate.a = 0.0
	lucky_draw_reward.scale = Vector2(0.8, 0.8)
	
	tween.parallel().tween_property(lucky_draw_reward, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(lucky_draw_reward, "scale", Vector2(1.0, 1.0), 0.5)

## 显示错误信息
func _show_error_message(message: String) -> void:
	lucky_draw_reward.text = "[center][color=#FF6B6B]❌ %s[/color][/center]" % message
	lucky_draw_reward.show()
	
	# 2秒后隐藏错误信息
	await get_tree().create_timer(2.0).timeout
	lucky_draw_reward.hide()

# =============================================================================
# 事件处理
# =============================================================================

## 关闭面板
func _on_quit_button_pressed() -> void:
	self.hide()

## 单次抽奖
func _on_lucky_draw_button_pressed() -> void:
	_perform_network_draw("single")

## 五连抽
func _on_five_lucky_draw_button_pressed() -> void:
	_perform_network_draw("five")

## 十连抽
func _on_ten_lucky_draw_button_pressed() -> void:
	_perform_network_draw("ten")

## 设置抽奖按钮可用状态
func _set_draw_buttons_enabled(enabled: bool) -> void:
	var buttons = [
		$HBox/LuckyDrawButton,
		$HBox/FiveLuckyDrawButton, 
		$HBox/TenLuckyDrawButton
	]
	
	for button in buttons:
		if button:
			button.disabled = not enabled

# =============================================================================
# 公共接口方法
# =============================================================================

## 获取当前奖励结果
func get_current_rewards() -> Array:
	return current_rewards

## 清空抽奖结果
func clear_draw_results() -> void:
	current_rewards.clear()
	lucky_draw_reward.hide()

## 刷新奖励显示（当作物数据更新时调用）
func refresh_reward_display() -> void:
	_load_crop_data_and_build_rewards()
	_update_template_display()


#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

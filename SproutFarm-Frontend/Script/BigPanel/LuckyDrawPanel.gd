extends Panel
class_name LuckyDrawPanel

signal draw_completed(rewards: Array, draw_type: String)
signal draw_failed(error_message: String)

@onready var lucky_draw_reward: RichTextLabel = $LuckyDrawReward
@onready var grid: GridContainer = $Grid
@onready var reward_item: RichTextLabel = $Grid/RewardItem
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'

@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog #确认弹窗


var reward_templates: Array[RichTextLabel] = []
var current_rewards: Array = []
var seed_rewards: Dictionary = {}
var anticipation_tween: Tween = null

# 15种模板颜色
var template_colors: Array[Color] = [
	Color(1.0, 0.8, 0.8, 1.0), Color(0.8, 1.0, 0.8, 1.0), Color(0.8, 0.8, 1.0, 1.0),
	Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.8, 1.0, 1.0), Color(0.8, 1.0, 1.0, 1.0),
	Color(1.0, 0.9, 0.8, 1.0), Color(0.9, 0.8, 1.0, 1.0), Color(0.8, 1.0, 0.9, 1.0),
	Color(1.0, 0.8, 0.9, 1.0), Color(0.9, 1.0, 0.8, 1.0), Color(0.8, 0.9, 1.0, 1.0),
	Color(1.0, 0.95, 0.8, 1.0), Color(0.85, 0.8, 1.0, 1.0), Color(0.95, 1.0, 0.85, 1.0)
]

var base_rewards: Dictionary = {
	"coins": {"name": "金币", "icon": "💰", "color": "#FFD700"},
	"exp": {"name": "经验", "icon": "⭐", "color": "#00BFFF"},
	"empty": {"name": "谢谢惠顾", "icon": "😅", "color": "#CCCCCC"}
}

var draw_costs: Dictionary = {
	"single": 800,
	"five": 3600,
	"ten": 6400
}

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_initialize_system()

func _initialize_system() -> void:
	if main_game:
		draw_completed.connect(main_game._on_lucky_draw_completed)
		draw_failed.connect(main_game._on_lucky_draw_failed)
	
	lucky_draw_reward.hide()
	_load_crop_data_and_build_rewards()
	_generate_reward_templates()
	_update_template_display()

func _load_crop_data_and_build_rewards() -> void:
	if main_game and main_game.has_method("get_crop_data"):
		var crop_data = main_game.get_crop_data()
		if crop_data:
			_build_seed_rewards_from_crop_data(crop_data)

func _build_seed_rewards_from_crop_data(crop_data: Dictionary) -> void:
	seed_rewards.clear()
	
	for crop_name in crop_data.keys():
		var crop_info = crop_data[crop_name]
		
		if crop_name == "测试作物" or not crop_info.get("能否购买", true):
			continue
		
		var quality = crop_info.get("品质", "普通")
		var rarity_color = _get_rarity_color(quality)
		
		seed_rewards[crop_name] = {
			"icon": "🌱",
			"color": rarity_color,
			"rarity": quality,
			"等级": crop_info.get("等级", 1),
			"cost": crop_info.get("花费", 50)
		}

func _get_rarity_color(rarity: String) -> String:
	match rarity:
		"普通": return "#90EE90"
		"优良": return "#87CEEB"
		"稀有": return "#DDA0DD"
		"史诗": return "#9932CC"
		"传奇": return "#FF8C00"
		_: return "#FFFFFF"

func _generate_reward_templates() -> void:
	for child in grid.get_children():
		if child != reward_item:
			child.queue_free()
	
	reward_templates.clear()
	
	for i in range(15):
		var template: RichTextLabel
		
		if i == 0:
			template = reward_item
		else:
			template = reward_item.duplicate()
			grid.add_child(template)
		
		template.self_modulate = template_colors[i]
		template.bbcode_enabled = true
		template.threaded = true
		reward_templates.append(template)

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

func _generate_sample_rewards() -> Array:
	var sample_rewards = []
	
	sample_rewards.append({"type": "coins", "amount_range": [100, 300], "rarity": "普通"})
	sample_rewards.append({"type": "exp", "amount_range": [50, 150], "rarity": "普通"})
	sample_rewards.append({"type": "empty", "name": "谢谢惠顾", "rarity": "空奖"})
	
	var quality_examples = ["普通", "优良", "稀有", "史诗", "传奇"]
	for quality in quality_examples:
		var example_seeds = []
		for seed_name in seed_rewards.keys():
			if seed_rewards[seed_name].rarity == quality:
				example_seeds.append(seed_name)
		
		if example_seeds.size() > 0:
			var seed_name = example_seeds[0]
			sample_rewards.append({
				"type": "seed",
				"name": seed_name,
				"rarity": quality,
				"amount_range": [1, 3] if quality != "传奇" else [1, 1]
			})
	
	sample_rewards.append({"type": "package", "name": "成长套餐", "rarity": "优良"})
	sample_rewards.append({"type": "package", "name": "稀有礼包", "rarity": "稀有"})
	sample_rewards.append({"type": "package", "name": "传奇大礼包", "rarity": "传奇"})
	sample_rewards.append({"type": "coins", "amount_range": [1000, 2000], "rarity": "史诗"})
	sample_rewards.append({"type": "exp", "amount_range": [500, 1000], "rarity": "传奇"})
	
	return sample_rewards.slice(0, 15)

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

func _perform_network_draw(draw_type: String) -> void:
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		_show_error_message("网络未连接，无法进行抽奖")
		return
	
	var cost = draw_costs.get(draw_type, 800)
	if main_game and main_game.money < cost:
		_show_error_message("金币不足，需要 %d 金币" % cost)
		return
	
	var success = tcp_network_manager_panel.sendLuckyDraw(draw_type)
	if not success:
		_show_error_message("发送抽奖请求失败")
		return
	
	_show_waiting_animation()

func _show_waiting_animation() -> void:
	_set_draw_buttons_enabled(false)
	lucky_draw_reward.hide()

func handle_lucky_draw_response(response: Dictionary) -> void:
	_set_draw_buttons_enabled(true)
	
	if response.get("success", false):
		var rewards = response.get("rewards", [])
		var draw_type = response.get("draw_type", "single")
		var cost = response.get("cost", 0)
		
		_show_server_draw_results(rewards, draw_type, cost)
		draw_completed.emit(rewards, draw_type)
	else:
		var error_message = response.get("message", "抽奖失败")
		_show_error_message(error_message)
		draw_failed.emit(error_message)

func _show_server_draw_results(rewards: Array, draw_type: String, cost: int) -> void:
	current_rewards = rewards
	
	var result_text = _format_server_draw_results(rewards, draw_type, cost)
	lucky_draw_reward.text = result_text
	lucky_draw_reward.show()
	
	
func _format_server_draw_results(rewards: Array, draw_type: String, cost: int) -> String:
	var type_names = {"single": "单抽", "five": "五连抽", "ten": "十连抽"}
	
	var text = "[center][color=#FFD700]🎊 %s结果 🎊[/color][/center]\n" % type_names.get(draw_type, draw_type)
	text += "[center][color=#87CEEB]消费 %d 金币[/color][/center]\n" % cost
	
	var stats = _count_server_reward_rarity(rewards)
	
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
	
	for reward in rewards:
		text += _format_single_server_reward(reward) + "\n"
	
	if stats.empty_only:
		text += "[center][color=#87CEEB]💪 别灰心，下次一定能中大奖！[/color][/center]"
	elif stats.legendary > 0:
		text += "[center][color=#FF8C00]🎉 恭喜获得传奇奖励！[/color][/center]"
	elif stats.epic > 0:
		text += "[center][color=#9932CC]✨ 史诗奖励，运气不错！[/color][/center]"
	
	return text

func _count_server_reward_rarity(rewards: Array) -> Dictionary:
	var stats = {"legendary": 0, "epic": 0, "rare": 0, "package": 0, "empty": 0, "empty_only": false}
	
	for reward in rewards:
		var rarity = reward.get("rarity", "普通")
		match rarity:
			"传奇": stats.legendary += 1
			"史诗": stats.epic += 1
			"稀有": stats.rare += 1
			"空奖": stats.empty += 1
		
		if reward.get("type") == "package":
			stats.package += 1
	
	stats.empty_only = (stats.empty == rewards.size() and rewards.size() == 1)
	return stats

func _format_single_server_reward(reward: Dictionary) -> String:
	var reward_type = reward.get("type", "")
	var rarity = reward.get("rarity", "普通")
	var rarity_color = _get_rarity_color(rarity)
	
	match reward_type:
		"empty":
			return "[color=%s]😅 %s[/color]" % [rarity_color, reward.get("name", "空奖励")]
		
		"package":
			var text = "[color=%s]🎁 %s[/color]\n" % [rarity_color, reward.get("name", "礼包")]
			text += "[color=#DDDDDD]内含:[/color] "
			
			var content_parts = []
			if reward.has("contents"):
				for content in reward.contents:
					var part = _format_package_content(content)
					if part != "":
						content_parts.append(part)
			
			text += " ".join(content_parts)
			return text
		
		"coins":
			return "[color=%s]💰 金币 +%d[/color]" % [rarity_color, reward.get("amount", 0)]
		
		"exp":
			return "[color=%s]⭐ 经验 +%d[/color]" % [rarity_color, reward.get("amount", 0)]
		
		"seed":
			return "[color=%s]🌱 %s x%d[/color] [color=#CCCCCC](%s)[/color]" % [
				rarity_color, reward.get("name", "种子"), reward.get("amount", 0), rarity
			]
		
		_:
			return "[color=#CCCCCC]未知奖励[/color]"

func _format_package_content(content: Dictionary) -> String:
	var content_type = content.get("type", "")
	var amount = content.get("amount", 0)
	
	match content_type:
		"coins": return "[color=#FFD700]💰%d[/color]" % amount
		"exp": return "[color=#00BFFF]⭐%d[/color]" % amount
		"seed": return "[color=#90EE90]🌱%sx%d[/color]" % [content.get("name", "种子"), amount]
		_: return ""


func _anticipation_flash(template: RichTextLabel, progress: float) -> void:
	var flash_intensity = 1.0 + sin(progress * PI * 2) * 0.2
	template.modulate = Color(flash_intensity, flash_intensity, flash_intensity, 1.0)


func _show_error_message(message: String) -> void:
	lucky_draw_reward.text = "[center][color=#FF6B6B]❌ %s[/color][/center]" % message
	lucky_draw_reward.show()
	
	await get_tree().create_timer(2.0).timeout
	lucky_draw_reward.hide()

func _set_draw_buttons_enabled(enabled: bool) -> void:
	var buttons = [
		$HBox/LuckyDrawButton,
		$HBox/FiveLuckyDrawButton,
		$HBox/TenLuckyDrawButton
	]
	
	for button in buttons:
		if button:
			button.disabled = not enabled

# 事件处理
func _on_quit_button_pressed() -> void:
	self.hide()

func _on_lucky_draw_button_pressed() -> void:
	_show_draw_confirmation("single")

func _on_five_lucky_draw_button_pressed() -> void:
	_show_draw_confirmation("five")

func _on_ten_lucky_draw_button_pressed() -> void:
	_show_draw_confirmation("ten")

func _show_draw_confirmation(draw_type: String) -> void:
	var cost = draw_costs.get(draw_type, 800)
	var type_names = {"single": "单抽", "five": "五连抽", "ten": "十连抽"}
	var type_name = type_names.get(draw_type, draw_type)
	
	confirm_dialog.title = "幸运抽奖确认"
	confirm_dialog.dialog_text = "确定要进行%s吗？\n需要花费 %d 金币\n\n可能获得金币、经验、种子等奖励！" % [type_name, cost]
	confirm_dialog.popup_centered()
	
	# 保存当前抽奖类型
	confirm_dialog.set_meta("draw_type", draw_type)
	
	# 连接确认信号（如果还没连接的话）
	if not confirm_dialog.confirmed.is_connected(_on_confirm_draw):
		confirm_dialog.confirmed.connect(_on_confirm_draw)

func _on_confirm_draw() -> void:
	var draw_type = confirm_dialog.get_meta("draw_type", "single")
	_perform_network_draw(draw_type)

func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
	else:
		GlobalVariables.isZoomDisabled = false

# 公共接口
func get_current_rewards() -> Array:
	return current_rewards

func clear_draw_results() -> void:
	current_rewards.clear()
	lucky_draw_reward.hide()

func refresh_reward_display() -> void:
	_load_crop_data_and_build_rewards()
	_update_template_display()

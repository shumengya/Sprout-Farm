extends Panel
@onready var pet_image: TextureRect = $PetImage #显示宠物图片
@onready var pet_name_edit: LineEdit = $InformScroll/VBox/PetNameHBox/PetNameEdit #编辑宠物名字
@onready var pet_inform: RichTextLabel = $InformScroll/VBox/PetInform #显示宠物其他信息

@onready var quit_button: Button = $QuitButton
@onready var refresh_button: Button = $RefreshButton

@onready var edit_inform_button: Button = $ButtonHBox/EditInformButton
@onready var feed_button: Button = $ButtonHBox/FeedButton #宠物喂食
@onready var use_item_button: Button = $ButtonHBox/UseItemButton #宠物使用道具
@onready var patro_button: Button = $ButtonHBox/PatroButton  #宠物农场巡逻 
@onready var battle_button: Button = $ButtonHBox/BattleButton #宠物设置为出战


# 当前显示的宠物数据
var current_pet_data: Dictionary = {}
var current_pet_name: String = ""

# 游戏节点引用
@onready var main_game = get_node("/root/main")

@onready var tcp_network_manager_panel: Panel = $'../../BigPanel/TCPNetworkManagerPanel'
@onready var lucky_draw_panel: LuckyDrawPanel = $'../../BigPanel/LuckyDrawPanel'
@onready var daily_check_in_panel: DailyCheckInPanel = $'../../BigPanel/DailyCheckInPanel'
@onready var player_ranking_panel: Panel = $'../../BigPanel/PlayerRankingPanel'
@onready var item_store_panel: Panel = $'../../BigPanel/ItemStorePanel'
@onready var crop_warehouse_panel: Panel = $'../../BigPanel/CropWarehousePanel'
@onready var login_panel: PanelContainer = $'../../BigPanel/LoginPanel'
@onready var player_bag_panel: Panel = $'../../BigPanel/PlayerBagPanel'
@onready var crop_store_panel: Panel = $'../../BigPanel/CropStorePanel'
@onready var item_bag_panel: Panel = $'../../BigPanel/ItemBagPanel'
@onready var pet_store_panel: Panel = $'../../BigPanel/PetStorePanel'
@onready var pet_bag_panel: Panel = $'../../BigPanel/PetBagPanel'
@onready var pet_fight_panel: Panel = $'../../BigPanel/PetFightPanel'




func _ready() -> void:
	quit_button.pressed.connect(self.on_quit_button_pressed)
	refresh_button.pressed.connect(self.on_refresh_button_pressed)
	edit_inform_button.pressed.connect(self.on_edit_inform_button_pressed)
	feed_button.pressed.connect(self.on_feed_button_pressed)
	use_item_button.pressed.connect(self.on_use_item_button_pressed)
	patro_button.pressed.connect(self._on_patrol_button_pressed)
	battle_button.pressed.connect(self._on_battle_button_pressed)
	
	# 启用bbcode支持
	pet_inform.bbcode_enabled = true
	
	# 默认隐藏面板
	self.hide()
	
# 显示宠物信息的主函数
func show_pet_info(pet_name: String, pet_data: Dictionary):
	current_pet_name = pet_name
	current_pet_data = pet_data
	
	# 设置宠物图片
	_set_pet_image(pet_name)
	
	# 设置宠物名称
	var basic_info = pet_data.get("基本信息", {})
	var pet_owner_name = basic_info.get("宠物名称", pet_name)
	pet_name_edit.text = pet_owner_name
	
	# 设置宠物详细信息
	_set_pet_detailed_info(pet_name, pet_data)
	
	# 刷新巡逻按钮状态
	_refresh_patrol_button()
	
	# 刷新出战按钮状态
	_refresh_battle_button()

# 设置宠物图片
func _set_pet_image(pet_name: String):
	var texture = _get_pet_texture(pet_name)
	if texture:
		pet_image.texture = texture
		pet_image.visible = true
	else:
		pet_image.visible = false

# 获取宠物纹理
func _get_pet_texture(pet_name: String) -> Texture2D:
	var pet_config = _load_pet_config()
	if pet_config.has(pet_name):
		var pet_info = pet_config[pet_name]
		var scene_path = pet_info.get("场景路径", "")
		
		if scene_path != "" and ResourceLoader.exists(scene_path):
			var pet_scene = load(scene_path)
			if pet_scene:
				var pet_instance = pet_scene.instantiate()
				var pet_image_node = pet_instance.get_node_or_null("PetImage")
				if pet_image_node and pet_image_node.sprite_frames:
					var animation_names = pet_image_node.sprite_frames.get_animation_names()
					if animation_names.size() > 0:
						var default_animation = animation_names[0]
						var frame_count = pet_image_node.sprite_frames.get_frame_count(default_animation)
						if frame_count > 0:
							var texture = pet_image_node.sprite_frames.get_frame_texture(default_animation, 0)
							pet_instance.queue_free()
							return texture
				pet_instance.queue_free()
	return null

# 加载宠物配置数据
func _load_pet_config() -> Dictionary:
	var file = FileAccess.open("res://Data/pet_data.json", FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}
	
	return json.data

# 设置宠物详细信息（使用bbcode美化）
func _set_pet_detailed_info(pet_name: String, pet_data: Dictionary):
	var basic_info = pet_data.get("基本信息", {})
	var level_exp = pet_data.get("等级经验", {})
	var purchase_info = pet_data.get("购买信息", {})
	var health_defense = pet_data.get("生命与防御", {})
	var attack_info = pet_data.get("基础攻击属性", {})
	var movement = pet_data.get("移动与闪避", {})
	var element = pet_data.get("元素属性", {})
	var quality = pet_data.get("品质系统", {})
	
	# 计算宠物年龄
	var pet_birthday = basic_info.get("生日", "")
	var pet_age = 0
	if pet_birthday != "":
		pet_age = _calculate_pet_age(pet_birthday)
	
	# 使用bbcode美化显示
	var info_text = ""
	
	# 基本信息
	info_text += "[color=pink][b]🐾 基本信息[/b][/color]\n"
	info_text += "宠物类型：[color=yellow]" + str(basic_info.get("宠物类型", "未知")) + "[/color]\n"
	info_text += "宠物编号：[color=gray]" + str(basic_info.get("宠物ID", "无")) + "[/color]\n"
	info_text += "性格特点：[color=cyan]" + str(basic_info.get("性格", "活泼")) + "[/color]\n"
	info_text += "出生日期：[color=green]" + str(pet_birthday) + "[/color]\n"
	info_text += "年龄天数：[color=orange]" + str(pet_age) + " 天[/color]\n"

	# 等级经验
	info_text += "[color=gold][b]⭐ 等级经验[/b][/color]\n"
	info_text += "当前等级：[color=yellow]" + str(level_exp.get("宠物等级", 1)) + " 级[/color]\n"
	info_text += "经验值：[color=cyan]" + str(level_exp.get("当前经验", 0)) + "/" + str(level_exp.get("最大经验", 100)) + "[/color]\n"
	info_text += "亲密度：[color=pink]" + str(level_exp.get("亲密度", 0)) + "/" + str(level_exp.get("最大亲密度", 1000)) + "[/color]\n\n"
	
	# 生命与防御
	info_text += "[color=red][b]❤️ 生命与防御[/b][/color]\n"
	info_text += "生命值：[color=red]" + str(health_defense.get("当前生命值", 0)) + "/" + str(health_defense.get("最大生命值", 0)) + "[/color]\n"
	info_text += "护甲值：[color=blue]" + str(health_defense.get("当前护甲值", 0)) + "/" + str(health_defense.get("最大护甲值", 0)) + "[/color]\n"
	info_text += "护盾值：[color=cyan]" + str(health_defense.get("当前护盾值", 0)) + "/" + str(health_defense.get("最大护盾值", 0)) + "[/color]\n"
	info_text += "生命恢复：[color=lime]" + str(health_defense.get("生命恢复速度", 0)) + "/秒[/color]\n\n"
	
	# 攻击属性
	info_text += "[color=orange][b]⚔️ 攻击属性[/b][/color]\n"
	info_text += "攻击类型：[color=yellow]" + _get_attack_type_name(str(attack_info.get("攻击类型", "MELEE"))) + "[/color]\n"
	info_text += "攻击伤害：[color=red]" + str(attack_info.get("基础攻击伤害", 0)) + " 点[/color]\n"
	info_text += "攻击距离：[color=green]" + str(attack_info.get("攻击距离", 0)) + " 像素[/color]\n"
	info_text += "暴击几率：[color=purple]" + str(attack_info.get("暴击率", 0) * 100) + "%[/color]\n"
	info_text += "暴击倍数：[color=purple]" + str(attack_info.get("暴击伤害倍数", 1.0)) + " 倍[/color]\n"
	info_text += "生命汲取：[color=magenta]" + str(attack_info.get("生命汲取", 0) * 100) + "%[/color]\n\n"
	
	# 移动与闪避
	info_text += "[color=green][b]🏃 移动与闪避[/b][/color]\n"
	info_text += "移动速度：[color=cyan]" + str(movement.get("移动速度", 0)) + " 像素/秒[/color]\n"
	info_text += "闪避几率：[color=yellow]" + str(movement.get("闪避率", 0) * 100) + "%[/color]\n"
	info_text += "击退力度：[color=red]" + str(movement.get("击退力度", 0)) + " 点[/color]\n"
	info_text += "击退抗性：[color=blue]" + str(movement.get("击退抗性", 0) * 100) + "%[/color]\n\n"
	
	# 元素属性
	info_text += "[color=purple][b]🔥 元素属性[/b][/color]\n"
	info_text += "元素类型：[color=yellow]" + _get_element_name(str(element.get("元素类型", "NONE"))) + "[/color]\n"
	info_text += "元素伤害：[color=orange]" + str(element.get("元素克制额外伤害", 0)) + " 点[/color]\n\n"
	
	# 品质系统
	var quality_text = str(quality.get("宠物品质", "COMMON"))
	var quality_color = "white"
	var quality_name = ""
	if quality_text == "COMMON":
		quality_color = "gray"
		quality_name = "普通"
	elif quality_text == "RARE":
		quality_color = "blue"
		quality_name = "稀有"
	elif quality_text == "EPIC":
		quality_color = "purple"
		quality_name = "史诗"
	elif quality_text == "LEGENDARY":
		quality_color = "orange"
		quality_name = "传说"
	else:
		quality_name = quality_text
	
	info_text += "[color=gold][b]✨ 品质系统[/b][/color]\n"
	info_text += "宠物品质：[color=" + quality_color + "]" + quality_name + "[/color]\n\n"
	
	# 购买信息
	info_text += "[color=gold][b]💰 购买信息[/b][/color]\n"
	info_text += "购买价格：[color=yellow]" + str(purchase_info.get("购买价格", 0)) + " 金币[/color]\n"
	
	# 设置文本
	pet_inform.text = info_text


# 获取攻击类型名称
func _get_attack_type_name(attack_type: String) -> String:
	match attack_type:
		"MELEE":
			return "近战攻击"
		"RANGED":
			return "远程攻击"
		"MAGIC":
			return "魔法攻击"
		_:
			return attack_type

# 获取元素类型名称
func _get_element_name(element_type: String) -> String:
	match element_type:
		"NONE":
			return "无元素"
		"FIRE":
			return "火元素"
		"WATER":
			return "水元素"
		"EARTH":
			return "土元素"
		"AIR":
			return "风元素"
		"LIGHT":
			return "光元素"
		"DARK":
			return "暗元素"
		_:
			return element_type

# 计算宠物年龄（以天为单位）
func _calculate_pet_age(birthday: String) -> int:
	if birthday == "":
		return 0
	
	# 解析生日字符串，格式：2025年7月5日10时7分25秒
	var birthday_parts = birthday.split("年")
	if birthday_parts.size() < 2:
		return 0
	
	var year = int(birthday_parts[0])
	var rest = birthday_parts[1]
	
	var month_parts = rest.split("月")
	if month_parts.size() < 2:
		return 0
	
	var month = int(month_parts[0])
	var rest2 = month_parts[1]
	
	var day_parts = rest2.split("日")
	if day_parts.size() < 2:
		return 0
	
	var day = int(day_parts[0])
	var rest3 = day_parts[1]
	
	var hour_parts = rest3.split("时")
	if hour_parts.size() < 2:
		return 0
	
	var hour = int(hour_parts[0])
	var rest4 = hour_parts[1]
	
	var minute_parts = rest4.split("分")
	if minute_parts.size() < 2:
		return 0
	
	var minute = int(minute_parts[0])
	var rest5 = minute_parts[1]
	
	var second_parts = rest5.split("秒")
	if second_parts.size() < 1:
		return 0
	
	var second = int(second_parts[0])
	
	# 将生日转换为Unix时间戳
	var birthday_dict = {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}
	
	var birthday_timestamp = Time.get_unix_time_from_datetime_dict(birthday_dict)
	var current_timestamp = Time.get_unix_time_from_system()
	
	# 计算天数差
	var age_seconds = current_timestamp - birthday_timestamp
	var age_days = int(age_seconds / (24 * 3600))
	
	return max(0, age_days)

func on_quit_button_pressed():
	self.hide()

#刷新面板
func on_refresh_button_pressed():
	if current_pet_name != "" and current_pet_data.size() > 0:
		show_pet_info(current_pet_name, current_pet_data)
	
#编辑宠物信息按钮（目前就只有宠物名字）
func on_edit_inform_button_pressed():
	if current_pet_data.is_empty():
		Toast.show("没有选择宠物", Color.RED, 2.0, 1.0)
		return
	
	# 获取输入框中的新名字
	var new_pet_name = pet_name_edit.text.strip_edges()
	
	# 检查名字是否为空
	if new_pet_name == "":
		Toast.show("宠物名字不能为空", Color.RED, 2.0, 1.0)
		return
	
	# 检查名字长度
	if new_pet_name.length() > 20:
		Toast.show("宠物名字太长，最多20个字符", Color.RED, 2.0, 1.0)
		return
	
	# 获取当前宠物名字
	var basic_info = current_pet_data.get("基本信息", {})
	var current_name = basic_info.get("宠物名称", "")
	
	# 检查名字是否有变化
	if new_pet_name == current_name:
		Toast.show("宠物名字没有变化", Color.YELLOW, 2.0, 1.0)
		return
	
	# 显示确认对话框
	_show_rename_confirmation_dialog(new_pet_name, current_name)

# 显示重命名确认对话框
func _show_rename_confirmation_dialog(new_name: String, old_name: String):
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = str(
		"确认修改宠物名字？\n\n" +
		"原名字：" + old_name + "\n" +
		"新名字：" + new_name + "\n\n" +
		"修改后将无法撤销！"
	)
	confirm_dialog.title = "宠物重命名确认"
	confirm_dialog.ok_button_text = "确认修改"
	confirm_dialog.add_cancel_button("取消")
	
	# 添加到场景
	add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_on_confirm_rename_pet.bind(new_name, confirm_dialog))
	confirm_dialog.canceled.connect(_on_cancel_rename_pet.bind(confirm_dialog))
	
	# 显示对话框
	confirm_dialog.popup_centered()

# 确认重命名宠物
func _on_confirm_rename_pet(new_name: String, dialog: AcceptDialog):
	# 发送重命名请求到服务器
	_send_rename_pet_request(new_name)
	dialog.queue_free()

# 取消重命名宠物
func _on_cancel_rename_pet(dialog: AcceptDialog):
	# 恢复原名字
	var basic_info = current_pet_data.get("基本信息", {})
	var original_name = basic_info.get("宠物名称", "")
	pet_name_edit.text = original_name
	dialog.queue_free()

# 发送重命名宠物请求
func _send_rename_pet_request(new_name: String):
	if not tcp_network_manager_panel or not tcp_network_manager_panel.has_method("sendRenamePet"):
		Toast.show("网络功能不可用", Color.RED, 2.0, 1.0)
		return
	
	# 获取宠物ID
	var basic_info = current_pet_data.get("基本信息", {})
	var pet_id = basic_info.get("宠物ID", "")
	
	if pet_id == "":
		Toast.show("宠物ID无效", Color.RED, 2.0, 1.0)
		return
	
	# 发送重命名请求
	if tcp_network_manager_panel.sendRenamePet(pet_id, new_name):
		pass
	else:
		Toast.show("重命名请求发送失败", Color.RED, 2.0, 1.0)

# 处理重命名成功的响应（从宠物背包或其他地方调用）
func on_rename_pet_success(pet_id: String, new_name: String):
	# 更新当前宠物数据
	if current_pet_data.get("基本信息", {}).get("宠物ID", "") == pet_id:
		current_pet_data["基本信息"]["宠物名称"] = new_name
		pet_name_edit.text = new_name
		Toast.show("宠物名字修改成功！", Color.GREEN, 2.0, 1.0)
		
		# 刷新显示
		show_pet_info(current_pet_name, current_pet_data)
	
#喂养宠物
func on_feed_button_pressed():
	if current_pet_data.is_empty():
		Toast.show("没有选择宠物", Color.RED, 2.0, 1.0)
		return
	
	# 检查是否为访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法喂养宠物", Color.ORANGE, 2.0, 1.0)
		return
	

	if crop_warehouse_panel:
		# 设置为宠物喂食模式
		crop_warehouse_panel.set_pet_feeding_mode(true, current_pet_data)
		crop_warehouse_panel.show()
		
		pet_bag_panel.hide()
		self.hide()
	else:
		Toast.show("无法找到作物仓库面板", Color.RED, 2.0, 1.0)
	
#对宠物使用道具
func on_use_item_button_pressed():
	# 检查是否有选择的宠物
	if current_pet_data.is_empty():
		Toast.show("请先选择一个宠物", Color.RED, 2.0, 1.0)
		return
	
	# 检查是否为访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法使用道具", Color.ORANGE, 2.0, 1.0)
		return
	
	if item_bag_panel:
		# 设置道具背包面板为宠物使用道具模式
		item_bag_panel.set_pet_item_mode(true, current_pet_data)
		item_bag_panel.show()
		
		# 隐藏宠物信息面板
		self.hide()
		pet_bag_panel.hide()
		
		Toast.show("请选择要使用的宠物道具", Color.CYAN, 3.0, 1.0)
	else:
		Toast.show("无法找到道具背包面板", Color.RED, 2.0, 1.0)

# 巡逻按钮点击事件
func _on_patrol_button_pressed():
	#直接在客户端
	patro_button.text = "取消巡逻"
	patro_button.modulate = Color.ORANGE
	
	
	if current_pet_data.is_empty():
		Toast.show("没有选择宠物", Color.RED, 2.0, 1.0)
		return
	
	# 检查是否为访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法设置巡逻宠物", Color.ORANGE, 2.0, 1.0)
		return
	
	# 获取宠物ID
	var basic_info = current_pet_data.get("基本信息", {})
	var pet_id = basic_info.get("宠物ID", "")
	
	if pet_id == "":
		Toast.show("宠物ID无效", Color.RED, 2.0, 1.0)
		return
	
	# 检查当前宠物是否已在巡逻
	var is_currently_patrolling = _is_pet_patrolling(pet_id)
	
	if is_currently_patrolling:
		# 取消巡逻
		_remove_from_patrol(pet_id)
	else:
		# 添加到巡逻
		_add_to_patrol(pet_id)

# 检查宠物是否正在巡逻（基于服务器数据）
func _is_pet_patrolling(pet_id: String) -> bool:
	# 检查服务器的巡逻宠物数据
	if main_game.patrol_pets == null or main_game.patrol_pets.size() == 0:
		return false
	
	# 遍历巡逻宠物列表，查找匹配的ID
	for patrol_pet in main_game.patrol_pets:
		var patrol_pet_id = patrol_pet.get("基本信息", {}).get("宠物ID", "")
		if patrol_pet_id == pet_id:
			return true
	
	return false

# 添加到巡逻（新的基于ID的逻辑）
func _add_to_patrol(pet_id: String):
	# 检查巡逻宠物数量限制（目前服务器设置最多3个）
	if main_game.patrol_pets != null and main_game.patrol_pets.size() >= 3:
		Toast.show("最多只能设置3个巡逻宠物", Color.ORANGE, 3.0, 1.0)
		return
	
	# 目前简化为只允许一个巡逻宠物
	if main_game.patrol_pets != null and main_game.patrol_pets.size() >= 1:
		Toast.show("已有宠物在巡逻，请先取消当前巡逻", Color.ORANGE, 3.0, 1.0)
		return
	
	# 如果不是访问模式，则发送到服务器保存
	if not main_game.is_visiting_mode:
		# 发送到服务器保存
		tcp_network_manager_panel.sendSetPatrolPet(pet_id, true)
		var pet_name = current_pet_data.get("基本信息", {}).get("宠物名称", "未知")
	else:
		Toast.show("访问模式下无法设置巡逻宠物", Color.ORANGE, 2.0, 1.0)

# 从巡逻中移除（新的基于ID的逻辑）
func _remove_from_patrol(pet_id: String):
	# 如果不是访问模式，则发送到服务器保存
	if not main_game.is_visiting_mode:
		# 发送到服务器移除
		tcp_network_manager_panel.sendSetPatrolPet(pet_id, false)
	else:
		Toast.show("访问模式下无法取消巡逻宠物", Color.ORANGE, 2.0, 1.0)

# 更新巡逻按钮文本
func _update_patrol_button_text(is_patrolling: bool):
	if is_patrolling:
		patro_button.text = "取消巡逻"
		patro_button.modulate = Color.ORANGE
	else:
		patro_button.text = "设置巡逻"
		patro_button.modulate = Color.GREEN

# 刷新巡逻按钮状态（在显示宠物信息时调用）
func _refresh_patrol_button():
	if current_pet_data.is_empty():
		return
	
	var basic_info = current_pet_data.get("基本信息", {})
	var pet_id = basic_info.get("宠物ID", "")
	
	if pet_id == "":
		return
	
	var is_patrolling = _is_pet_patrolling(pet_id)
	_update_patrol_button_text(is_patrolling)

# 出战按钮点击事件
func _on_battle_button_pressed():
	if current_pet_data.is_empty():
		Toast.show("没有选择宠物", Color.RED, 2.0, 1.0)
		return
	
	# 检查是否为访问模式
	if main_game.is_visiting_mode:
		Toast.show("访问模式下无法设置出战宠物", Color.ORANGE, 2.0, 1.0)
		return
	
	# 获取宠物ID
	var basic_info = current_pet_data.get("基本信息", {})
	var pet_id = basic_info.get("宠物ID", "")
	
	if pet_id == "":
		Toast.show("宠物ID无效", Color.RED, 2.0, 1.0)
		return
	
	# 检查当前宠物是否已在出战
	var is_currently_battling = _is_pet_battling(pet_id)
	
	if is_currently_battling:
		# 取消出战
		_remove_from_battle(pet_id)
	else:
		# 添加到出战
		_add_to_battle(pet_id)

# 检查宠物是否正在出战（基于服务器数据）
func _is_pet_battling(pet_id: String) -> bool:
	# 检查服务器的出战宠物数据
	if main_game.battle_pets == null or main_game.battle_pets.size() == 0:
		return false
	
	# 遍历出战宠物列表，查找匹配的ID
	for battle_pet in main_game.battle_pets:
		var battle_pet_id = battle_pet.get("基本信息", {}).get("宠物ID", "")
		if battle_pet_id == pet_id:
			return true
	
	return false

# 添加到出战（新的基于ID的逻辑）
func _add_to_battle(pet_id: String):
	# 检查出战宠物数量限制（目前服务器设置最多1个）
	if main_game.battle_pets != null and main_game.battle_pets.size() >= 1:
		Toast.show("最多只能设置1个出战宠物", Color.ORANGE, 3.0, 1.0)
		return
	
	# 检查是否在巡逻中（出战宠物不能是巡逻宠物）
	if _is_pet_patrolling(pet_id):
		Toast.show("该宠物正在巡逻，不能同时设置为出战宠物", Color.ORANGE, 3.0, 1.0)
		return
	
	# 如果不是访问模式，则发送到服务器保存
	if not main_game.is_visiting_mode:
		# 发送到服务器保存
		tcp_network_manager_panel.sendSetBattlePet(pet_id, true)
		var pet_name = current_pet_data.get("基本信息", {}).get("宠物名称", "未知")
		Toast.show("正在设置 " + pet_name + " 为出战宠物...", Color.YELLOW, 2.0, 1.0)
	else:
		Toast.show("访问模式下无法设置出战宠物", Color.ORANGE, 2.0, 1.0)

# 从出战中移除（新的基于ID的逻辑）
func _remove_from_battle(pet_id: String):
	# 如果不是访问模式，则发送到服务器保存
	if not main_game.is_visiting_mode:
		# 发送到服务器移除
		tcp_network_manager_panel.sendSetBattlePet(pet_id, false)
		pass
	else:
		Toast.show("访问模式下无法取消出战宠物", Color.ORANGE, 2.0, 1.0)

# 更新出战按钮文本
func _update_battle_button_text(is_battling: bool):
	if is_battling:
		battle_button.text = "取消出战"
		battle_button.modulate = Color.ORANGE
	else:
		battle_button.text = "设置出战"
		battle_button.modulate = Color.GREEN

# 刷新出战按钮状态（在显示宠物信息时调用）
func _refresh_battle_button():
	if current_pet_data.is_empty():
		return
	
	var basic_info = current_pet_data.get("基本信息", {})
	var pet_id = basic_info.get("宠物ID", "")
	
	if pet_id == "":
		return
	
	var is_battling = _is_pet_battling(pet_id)
	_update_battle_button_text(is_battling)


#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

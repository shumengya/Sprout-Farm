extends Panel

# 可用的宠物场景字典（直接使用现有场景文件）
var available_pets: Dictionary = {
	"小绿": preload("res://Scene/Pet/SmallGreen.tscn"),
	"小蓝": preload("res://Scene/Pet/SmallBlue.tscn"),
	"小黄": preload("res://Scene/Pet/SmallYellow.tscn"),
	"小橙": preload("res://Scene/Pet/SmallOrange.tscn"),
	"小粉": preload("res://Scene/Pet/SmallPink.tscn"),
	"红史莱姆": preload("res://Scene/Pet/RedSlime.tscn"),
	"绿史莱姆": preload("res://Scene/Pet/GreenSlime.tscn"),
	"小骑士": preload("res://Scene/Pet/LittleKnight.tscn"),
	"大甲虫": preload("res://Scene/Pet/BigBeetle.tscn"),
	"小甲虫": preload("res://Scene/Pet/SmallBeetle.tscn"),
	"飞鸟": preload("res://Scene/Pet/FlyingBird.tscn"),
	"小钻头": preload("res://Scene/Pet/SmallDrillBit.tscn")
}

# 宠物配置数据
var pet_configs: Dictionary = {}

@onready var battle_end_panel: Panel = $BattleEndPanel #战斗结算面板
@onready var contents: Label = $BattleEndPanel/Contents #结算内容 
@onready var return_farm_button: Button = $BattleEndPanel/ReturnFarmButton #返回农场按钮 暂时设定为隐藏战斗面板

@onready var pet_battle_details_panel: Panel = $PetBattleDetailsPanel  #宠物对战细节面板
@onready var battle_details: RichTextLabel = $PetBattleDetailsPanel/BattleDetails  #宠物对战细节

@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'


# 对战区域边界
var battle_area_min: Vector2 = Vector2(50, 50)
var battle_area_max: Vector2 = Vector2(1350, 670)

# 队伍宠物列表
var team1_pets: Array[CharacterBody2D] = []
var team2_pets: Array[CharacterBody2D] = []

# 对战状态
var battle_started: bool = false
var battle_ended: bool = false
var winner_team: String = ""
var auto_battle_enabled: bool = true  # 是否启用自动对战
var is_steal_battle: bool = false  # 是否为偷菜对战
var steal_battle_cost: int = 1300  # 偷菜对战失败的惩罚金币
var battle_start_time: float = 0.0  # 战斗开始时间

# 偷菜对战相关数据
var current_battle_pet_id: String = ""  # 当前出战宠物ID
var current_attacker_name: String = ""  # 当前进攻者用户名

# 队伍节点引用
@onready var team1_node: Node = $team1
@onready var team2_node: Node = $team2
@onready var neutral_node: Node = $neutral


func _ready():
	# 加载宠物配置
	load_pet_configs()
	
	# 连接返回农场按钮
	if return_farm_button:
		return_farm_button.pressed.connect(_on_return_farm_pressed)
	
	# 初始隐藏结算面板和细节面板
	if battle_end_panel:
		battle_end_panel.visible = false
	if pet_battle_details_panel:
		pet_battle_details_panel.visible = false
	

# 加载宠物配置
func load_pet_configs():
	var file = FileAccess.open("res://Data/pet_data.json", FileAccess.READ)
	if file == null:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return
	
	pet_configs = json.data

# 添加对战细节到细节面板
func add_battle_detail(text: String, color: Color = Color.WHITE):
	if not battle_details:
		return
	
	# 安全获取当前时间
	var time_parts = Time.get_datetime_string_from_system().split(" ")
	var current_time = ""
	if time_parts.size() >= 2:
		current_time = time_parts[1]  # 获取时间部分
	else:
		# 如果格式不对，使用简单的时间格式
		var time_dict = Time.get_datetime_dict_from_system()
		current_time = str(time_dict.hour).pad_zeros(2) + ":" + str(time_dict.minute).pad_zeros(2) + ":" + str(time_dict.second).pad_zeros(2)
	
	var detail_text = "[color=#" + color.to_html() + "]" + current_time + " " + text + "[/color]\n"
	battle_details.text += detail_text
	
	# 自动滚动到底部
	await get_tree().process_frame
	if battle_details.get_v_scroll_bar():
		battle_details.get_v_scroll_bar().value = battle_details.get_v_scroll_bar().max_value

# 清空对战细节
func clear_battle_details():
	if battle_details:
		battle_details.text = ""

func _process(delta):
	# 只有启用自动对战时才检查战斗结束
	if auto_battle_enabled and battle_started and not battle_ended:
		check_battle_end()


# 获取队伍节点 - 供宠物调用
func get_team_node(team_name: String) -> Node:
	match team_name:
		"team1":
			return team1_node
		"team2":
			return team2_node
		"neutral":
			return neutral_node
		_:
			return null



# 开始战斗
func start_battle():
	if battle_started:
		return
		
	battle_started = true
	battle_ended = false
	battle_start_time = Time.get_ticks_msec() / 1000.0  # 记录战斗开始时间
	
	# 显示细节面板并初始化内容
	if pet_battle_details_panel:
		pet_battle_details_panel.visible = true
		add_battle_detail("⚔️ 战斗开始！", Color.YELLOW)
		
		# 显示双方宠物信息
		var all_pets = get_tree().get_nodes_in_group("pets")
		for pet in all_pets:
			if pet.pet_team == "team1":
				add_battle_detail("🔵 " + pet.pet_name + " 参战！", Color.CYAN)
			elif pet.pet_team == "team2":
				add_battle_detail("🟠 " + pet.pet_name + " 参战！", Color.ORANGE)

# 检查战斗是否结束
func check_battle_end():
	if battle_ended or not battle_started:
		return
	
	# 等待战斗真正开始后再检查（避免立即结束）
	if Time.get_ticks_msec() / 1000.0 - battle_start_time < 2.0:
		return
		
	var team1_alive = 0
	var team2_alive = 0
	
	# 统计存活宠物数量 - 只检查当前对战面板下的宠物
	for pet in team1_pets:
		if is_instance_valid(pet) and pet.is_alive:
			team1_alive += 1
	
	for pet in team2_pets:
		if is_instance_valid(pet) and pet.is_alive:
			team2_alive += 1
	
	# 判断胜负
	if team1_alive == 0 and team2_alive == 0:
		end_battle("draw")
	elif team1_alive == 0:
		end_battle("team2")
	elif team2_alive == 0:
		end_battle("team1")

# 结束战斗
func end_battle(winner: String):
	if battle_ended:
		return
		
	battle_ended = true
	winner_team = winner
	
	# 添加战斗结束细节
	var end_message = ""
	var end_color = Color.WHITE
	match winner:
		"team1":
			end_message = "🏆 我方获胜！"
			end_color = Color.GREEN
		"team2":
			end_message = "🏆 敌方获胜！"
			end_color = Color.RED
		"draw":
			end_message = "🤝 平局！双方同归于尽"
			end_color = Color.GRAY
	
	add_battle_detail(end_message, end_color)
	
	# 显示战斗结算面板
	show_battle_end_panel(winner)

	# 处理偷菜对战结果
	if is_steal_battle:
		await get_tree().create_timer(2.0).timeout
		handle_steal_battle_result(winner)




# 显示战斗结算面板
func show_battle_end_panel(winner: String):
	var result_text = ""
	var team1_survivors = 0
	var team2_survivors = 0
	var team1_total_damage = 0.0
	var team2_total_damage = 0.0
	var team1_pets_info: Array[String] = []
	var team2_pets_info: Array[String] = []
	
	# 统计存活宠物和详细信息 - 从宠物组中获取
	var all_pets = get_tree().get_nodes_in_group("pets")
	for pet in all_pets:
		if not is_instance_valid(pet):
			continue
			
		var status = "💀死亡"
		if pet.is_alive:
			status = "❤️存活(" + str(int(pet.current_health)) + ")"
			if pet.pet_team == "team1":
				team1_survivors += 1
			elif pet.pet_team == "team2":
				team2_survivors += 1
		
		# 统计战力
		if pet.pet_team == "team1":
			team1_total_damage += pet.attack_damage
			team1_pets_info.append(pet.pet_name + " " + status)
		elif pet.pet_team == "team2":
			team2_total_damage += pet.attack_damage
			team2_pets_info.append(pet.pet_name + " " + status)
	
	# 构建结算文本
	result_text += "=== 战斗结算 ===\n\n"
	
	match winner:
		"team1":
			result_text += "🏆 我方获胜！\n\n"
		"team2":
			result_text += "🏆 敌方获胜！\n\n"
		"draw":
			result_text += "🤝 平局！双方同归于尽\n\n"
	
	# 给所有参与对战的宠物奖励经验和亲密度
	for pet in all_pets:
		if is_instance_valid(pet):
			# 所有宠物获得参与对战奖励
			pet.gain_experience(30.0)  # 参与对战随机获得30-100经验
			pet.gain_intimacy(15.0)    # 参与对战随机获得1-12亲密度


	contents.text = result_text
	battle_end_panel.visible = true

# 设置偷菜对战
func setup_steal_battle(battle_pet_data: Dictionary, patrol_pet_data: Dictionary, attacker_name: String, defender_name: String):
	
	# 停止当前对战
	stop_auto_battle()
	
	# 清理现有宠物
	clear_all_pets()
	
	# 设置为偷菜对战模式
	is_steal_battle = true
	steal_battle_cost = 1300
	
	# 记录对战信息
	current_attacker_name = attacker_name
	current_battle_pet_id = battle_pet_data.get("基本信息", {}).get("宠物ID", "")
	
	# 根据宠物数据创建对战宠物
	var battle_pet = create_pet_from_data(battle_pet_data, team1_node, Vector2(200, 300))
	var patrol_pet = create_pet_from_data(patrol_pet_data, team2_node, Vector2(1000, 300))
	
	if battle_pet and patrol_pet:
		# 设置宠物名称标识
		var battle_original_name = battle_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
		var patrol_original_name = patrol_pet_data.get("基本信息", {}).get("宠物名称", "未知宠物")
		
		battle_pet.pet_name = "[出战] " + battle_original_name
		patrol_pet.pet_name = "[巡逻] " + patrol_original_name
		
		# 确保宠物正确设置类型并加载配置
		var battle_pet_type = battle_pet_data.get("基本信息", {}).get("宠物类型", "")
		var patrol_pet_type = patrol_pet_data.get("基本信息", {}).get("宠物类型", "")
		
		if battle_pet_type != "":
			battle_pet.set_pet_type_and_load_config(battle_pet_type)
		if patrol_pet_type != "":
			patrol_pet.set_pet_type_and_load_config(patrol_pet_type)
		
		# 重新应用宠物数据（覆盖JSON配置）
		apply_pet_data_to_instance(battle_pet, battle_pet_data)
		apply_pet_data_to_instance(patrol_pet, patrol_pet_data)
		
		# 强制设置正确的队伍信息（在数据应用之后）
		battle_pet.pet_team = "team1"
		patrol_pet.pet_team = "team2"
		
		# 设置碰撞层
		battle_pet.setup_collision_layers()
		patrol_pet.setup_collision_layers()
		
		# 启用战斗模式
		battle_pet.set_combat_enabled(true)
		patrol_pet.set_combat_enabled(true)
		
		# 添加到队伍数组
		team1_pets.clear()
		team2_pets.clear()
		team1_pets.append(battle_pet)
		team2_pets.append(patrol_pet)
		
		# 添加到宠物组
		battle_pet.add_to_group("pets")
		battle_pet.add_to_group("team1")
		patrol_pet.add_to_group("pets")
		patrol_pet.add_to_group("team2")
		
		# 重置对战状态
		auto_battle_enabled = true
		battle_started = false
		battle_ended = false
		
		# 延迟启动战斗
		await get_tree().create_timer(1.0).timeout
		start_battle()

# 根据宠物数据创建宠物实例
func create_pet_from_data(pet_data: Dictionary, team_node: Node, spawn_pos: Vector2) -> CharacterBody2D:
	var pet_type = pet_data.get("基本信息", {}).get("宠物类型", "")
	var scene_path = pet_data.get("场景路径", "")
	
	# 优先使用场景路径
	var pet_scene = null
	if scene_path != "" and ResourceLoader.exists(scene_path):
		pet_scene = load(scene_path)
	elif available_pets.has(pet_type):
		pet_scene = available_pets[pet_type]
	else:
		return null
	
	var pet_instance = pet_scene.instantiate()
	team_node.add_child(pet_instance)
	
	# 应用宠物数据
	apply_pet_data_to_instance(pet_instance, pet_data)
	
	# 设置位置
	pet_instance.global_position = spawn_pos
	
	return pet_instance

# 应用宠物数据到实例
func apply_pet_data_to_instance(pet_instance: CharacterBody2D, pet_data: Dictionary):
	var basic_info = pet_data.get("基本信息", {})
	var level_exp = pet_data.get("等级经验", {})
	var health_defense = pet_data.get("生命与防御", {})
	
	# 应用基本信息
	pet_instance.pet_owner = basic_info.get("宠物主人", "未知主人")
	pet_instance.pet_name = basic_info.get("宠物名称", basic_info.get("宠物类型", "未知宠物"))
	pet_instance.pet_id = basic_info.get("宠物ID", "")
	pet_instance.pet_type = basic_info.get("宠物类型", "")
	pet_instance.pet_birthday = basic_info.get("生日", "")
	pet_instance.pet_personality = basic_info.get("性格", "活泼")
	
	# 应用等级经验
	pet_instance.pet_level = level_exp.get("宠物等级", 1)
	pet_instance.pet_experience = level_exp.get("当前经验", 0.0)
	pet_instance.max_experience = level_exp.get("最大经验", 100.0)
	pet_instance.pet_intimacy = level_exp.get("亲密度", 0.0)
	
	# 应用生命防御属性
	pet_instance.max_health = health_defense.get("最大生命值", 100.0)
	pet_instance.current_health = health_defense.get("当前生命值", pet_instance.max_health)
	pet_instance.max_shield = health_defense.get("最大护盾值", 0.0)
	pet_instance.current_shield = health_defense.get("当前护盾值", 0.0)
	pet_instance.max_armor = health_defense.get("最大护甲值", 0.0)
	pet_instance.current_armor = health_defense.get("当前护甲值", 0.0)
	
	# 启用战斗模式
	if pet_instance.has_method("set_combat_enabled"):
		pet_instance.set_combat_enabled(true)
	
	# 更新UI显示
	if pet_instance.has_method("update_ui"):
		pet_instance.update_ui()

# 清理所有宠物
func clear_all_pets():
	# 清空对战细节
	clear_battle_details()
	
	# 先移除宠物组标签
	var all_pets = get_tree().get_nodes_in_group("pets")
	for pet in all_pets:
		if is_instance_valid(pet):
			# 检查是否是当前面板下的宠物
			if pet.get_parent() == team1_node or pet.get_parent() == team2_node or pet.get_parent() == neutral_node:
				pet.remove_from_group("pets")
				pet.remove_from_group("team1")
				pet.remove_from_group("team2")
				pet.remove_from_group("neutral")
	
	# 清理现有宠物
	for child in team1_node.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	for child in team2_node.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	for child in neutral_node.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	# 清空队伍数组
	team1_pets.clear()
	team2_pets.clear()
	
	# 清理所有子弹
	var all_projectiles = get_tree().get_nodes_in_group("projectiles")
	for projectile in all_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()

# 处理偷菜对战结果
func handle_steal_battle_result(winner: String):
	var main_game = get_node("/root/main")
	if not main_game:
		return
	
	# 计算出战宠物获得的经验和亲密度
	var exp_gained = 30.0  # 基础参与经验
	var intimacy_gained = 15.0  # 基础参与亲密度
	
	# 获取出战宠物的当前状态
	var battle_pet = null
	for pet in team1_pets:
		if is_instance_valid(pet):
			battle_pet = pet
			break
	
	if not battle_pet:
		return
		
	if winner == "team1":  # 出战宠物获胜
		exp_gained += 50.0  # 胜利额外经验
		intimacy_gained += 25.0  # 胜利额外亲密度
		Toast.show("对战胜利！可以继续偷菜", Color.GREEN, 3.0)
	else:  # 巡逻宠物获胜或平局
		exp_gained += 10.0  # 失败安慰经验
		intimacy_gained += 5.0  # 失败安慰亲密度
		
		# 扣除惩罚金币
		if main_game.money >= steal_battle_cost:
			main_game.money -= steal_battle_cost
			main_game._update_ui()
			Toast.show("对战失败！支付了 " + str(steal_battle_cost) + " 金币", Color.RED, 3.0)
		else:
			Toast.show("对战失败！但金币不足支付惩罚", Color.RED, 3.0)
	
	# 更新宠物数据到服务器
	update_battle_pet_data(current_battle_pet_id, current_attacker_name, exp_gained, intimacy_gained, battle_pet)
	
	# 重置偷菜对战状态
	is_steal_battle = false
	current_battle_pet_id = ""
	current_attacker_name = ""

# 返回农场按钮点击事件
func _on_return_farm_pressed():
	# 隐藏结算面板和细节面板
	if battle_end_panel:
		battle_end_panel.visible = false
	if pet_battle_details_panel:
		pet_battle_details_panel.visible = false
	
	# 完全清理所有宠物和数据
	clear_all_pets()
	
	# 等待一帧确保清理完成
	await get_tree().process_frame
	
	# 重置对战状态
	battle_started = false
	battle_ended = false
	is_steal_battle = false
	auto_battle_enabled = true
	winner_team = ""
	
	# 重新启用相机缩放
	GlobalVariables.isZoomDisabled = false
	
	# 隐藏面板
	self.hide()

# 更新出战宠物数据到服务器
func update_battle_pet_data(pet_id: String, attacker_name: String, exp_gained: float, intimacy_gained: float, battle_pet: CharacterBody2D):
	if pet_id == "" or attacker_name == "":
		return
	
	# 计算新的经验和亲密度
	var current_exp = battle_pet.pet_experience + exp_gained
	var current_intimacy = battle_pet.pet_intimacy + intimacy_gained
	var current_level = battle_pet.pet_level
	var max_exp = battle_pet.max_experience
	
	# 检查升级
	var level_ups = 0
	while current_exp >= max_exp and current_level < 50:
		current_exp -= max_exp
		current_level += 1
		level_ups += 1
		# 重新计算升级经验需求（指数增长）
		max_exp = 100.0 * pow(1.2, current_level - 1)
	
	# 计算升级后的属性加成
	var level_bonus_multiplier = pow(1.1, level_ups)  # 每级10%属性加成
	
	# 准备发送给服务器的数据
	var update_data = {
		"type": "update_battle_pet_data",
		"pet_id": pet_id,
		"attacker_name": attacker_name,
		"exp_gained": exp_gained,
		"intimacy_gained": intimacy_gained,
		"new_level": current_level,
		"new_experience": current_exp,
		"new_max_experience": max_exp,
		"new_intimacy": current_intimacy,
		"level_ups": level_ups,
		"level_bonus_multiplier": level_bonus_multiplier
	}
	
	# 发送数据到服务器

	if tcp_network_manager_panel:
		tcp_network_manager_panel.client.send_data(update_data)
		if level_ups > 0:
			add_battle_detail("🎉 " + battle_pet.pet_name + " 升级了 " + str(level_ups) + " 级！当前等级：" + str(current_level), Color.GOLD)
		add_battle_detail("📈 " + battle_pet.pet_name + " 获得 " + str(int(exp_gained)) + " 经验，" + str(int(intimacy_gained)) + " 亲密度", Color.GREEN)

# 停止自动对战逻辑
func stop_auto_battle():
	auto_battle_enabled = false
	battle_started = false
	battle_ended = false
	is_steal_battle = false  # 重置偷菜对战状态
	battle_start_time = 0.0  # 重置战斗开始时间
	winner_team = ""
	
#面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass

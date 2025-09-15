extends Panel
class_name PetBattlePanel

# 宠物对战系统管理器
# 支持PVP、PVE，最多20个宠物同时对战
# 高性能设计，适合移动端

signal battle_started
signal battle_ended(winner_team: String, battle_data: Dictionary)
signal pet_spawned(pet: NewPetBase)

# UI节点引用
@onready var map_background: TextureRect = $MapBackGround
@onready var title_label: Label = $Title
@onready var team_a_node: Node2D = $TeamA
@onready var team_b_node: Node2D = $TeamB
@onready var battle_end_panel: Panel = $BattleEndPanel
@onready var battle_details_panel: Panel = $PetBattleDetailsPanel
@onready var battle_details_text: RichTextLabel = $PetBattleDetailsPanel/BattleDetails
@onready var return_farm_button: Button = $BattleEndPanel/ReturnFarmButton
@onready var time: Label = $Time #剩余对战时间
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog #确认弹窗，每当操作需要确认时出现

# 辅助功能按钮引用
@onready var team_a_heal_button: Button = $PlayerSkillPanel/TeamASkills/TeamAHeal
@onready var team_a_rage_button: Button = $PlayerSkillPanel/TeamASkills/TeamARage
@onready var team_a_shield_button: Button = $PlayerSkillPanel/TeamASkills/TeamAShield

@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'#客户端通信函数


# 队伍名称
var team_a_name: String = ""
var team_b_name: String = ""

# 战斗状态
enum BattleState {
	PREPARING,	# 准备阶段
	BATTLING,	# 战斗中
	ENDED		# 战斗结束
}

var current_battle_state: BattleState = BattleState.PREPARING
var battle_time: float = 0.0
var max_battle_time: float = 300.0  # 5分钟最大战斗时间

# 队伍管理
var team_a_pets: Array[NewPetBase] = []
var team_b_pets: Array[NewPetBase] = []
var all_pets: Array[NewPetBase] = []

# 战斗统计
var battle_log: Array[String] = []
var damage_dealt: Dictionary = {}  # 记录每个宠物造成的伤害
var damage_taken: Dictionary = {}  # 记录每个宠物受到的伤害
var kills: Dictionary = {}  # 记录每个宠物的击杀数

# 性能优化
var update_timer: float = 0.0
var update_interval: float = 0.2  # 战斗状态更新间隔（降低频率）
var cleanup_timer: float = 0.0
var cleanup_interval: float = 2.0  # 清理死亡宠物和子弹的间隔（降低频率）

# 宠物配置系统
var pet_config: PetConfig

# 辅助功能冷却系统
var assist_cooldown_time: float = 5.0  # 冷却时间5秒
var heal_cooldown_timer: float = 0.0
var rage_cooldown_timer: float = 0.0
var shield_cooldown_timer: float = 0.0
var current_assist_operation: String = ""  # 当前待执行的辅助操作 

#========================基础函数======================
func _ready():
	# 初始化UI
	battle_end_panel.visible = false
	return_farm_button.pressed.connect(_on_return_farm_pressed)
	# 连接可见性改变信号
	visibility_changed.connect(_on_visibility_changed)
	# 连接确认弹窗信号
	confirm_dialog.confirmed.connect(_on_assist_confirmed)
	confirm_dialog.canceled.connect(_on_assist_canceled)
	# 初始化宠物配置系统
	pet_config = PetConfig.new()
	# 等待一帧确保PetConfig的_ready函数执行完毕
	await get_tree().process_frame
	# 初始化战斗日志
	battle_details_text.text = "[color=green]战斗准备中...[/color]\n"
	

	
	# 美化确认弹窗
	setup_confirm_dialog()
	
	# 延迟一帧后设置演示数据，确保所有节点都已准备好
	await get_tree().process_frame
	#setup_farm_battle()
	# 可以调用测试函数进行本地测试
	#setup_test_battle()

func _process(delta):
	# 更新时间显示（无论什么状态都显示）
	update_time_display()
#	
	# 更新辅助功能冷却计时器
	update_assist_cooldowns(delta)
	
	if current_battle_state != BattleState.BATTLING:
		return
	
	# 更新战斗时间
	battle_time += delta
	
	# 检查时间是否到达
	var remaining_time = max_battle_time - battle_time
	if remaining_time <= 0:
		# 时间到，立即清理所有宠物并结束为平局
		clear_all_pets_immediately()
		end_battle("平局")
		return
	
	# 更新计时器
	update_timer += delta
	cleanup_timer += delta
	
	# 定期更新战斗状态
	if update_timer >= update_interval:
		update_battle_state()
		update_timer = 0.0
	
	# 定期清理
	if cleanup_timer >= cleanup_interval:
		cleanup_dead_objects()
		cleanup_timer = 0.0
#========================基础函数======================


#=====================本地测试函数===========================
# 本地测试对战函数 - 方便调试各种宠物属性
func setup_test_battle():
	"""设置本地测试对战，可以快速测试各种宠物配置和属性"""
	print("[测试] 开始设置本地测试对战")
	
	# 清理现有战斗
	clear_all_pets()
	
	# 设置队伍名称
	team_a_name = "测试队伍A"
	team_b_name = "测试队伍B"
	
	# 创建测试队伍A的宠物数据（进攻方）
	var team_a_data = [
		{"config_key": "烈焰鸟"},  # 使用配置文件中的烈焰鸟
	]
	
	# 创建测试队伍B的宠物数据（防守方）
	var team_b_data = [
		{"config_key": "小蓝虫"},  # 使用配置文件中的小蓝虫
	]
	
	# 开始战斗
	start_battle(team_a_data, team_b_data)
	
	# 等待宠物生成完成
	await get_tree().process_frame
	
	# 获取生成的宠物进行属性调试
	var redman_pet = null  # 烈焰鸟
	var bluebug_pet = null # 大蓝虫
	var smallbug_pet = null # 小蓝虫
	var smallblue_pet = null # 小蓝
	
	# 查找特定宠物
	for pet in team_a_pets:
		if pet.pet_type == "烈焰鸟":
			redman_pet = pet
		elif pet.pet_type == "大蓝虫":
			bluebug_pet = pet
	
	for pet in team_b_pets:
		if pet.pet_type == "小蓝虫":
			smallbug_pet = pet
		elif pet.pet_type == "小蓝":
			smallblue_pet = pet
	
	# =================== 在这里可以一行代码调试宠物属性 ===================
	# 示例：开启烈焰鸟的反弹伤害技能
	if redman_pet:
		redman_pet.enable_damage_reflection_skill = true
		redman_pet.damage_reflection_percentage = 0.8  # 反弹80%伤害
		redman_pet.damage_reflection_cooldown = 5.0    # 5秒冷却
		print("[测试] 烈焰鸟开启反弹伤害技能")
	
	
	
	print("[测试] 本地测试对战设置完成，可以观察宠物战斗效果")
	
	# 添加测试日志
	add_battle_log("[color=cyan]本地测试对战开始！[/color]")
	add_battle_log("[color=yellow]队伍A: 烈焰鸟(反弹伤害) + 大蓝虫(召唤增强)[/color]")
	add_battle_log("[color=yellow]队伍B: 小蓝虫(狂暴模式) + 小蓝(自爆技能)[/color]")


#=====================UI显示===========================
#更新时间显示
func update_time_display():
	"""更新时间显示"""
	var remaining_time: float
	
	if current_battle_state == BattleState.BATTLING:
		remaining_time = max_battle_time - battle_time
	else:
		remaining_time = max_battle_time
	
	# 确保时间不为负数
	remaining_time = max(0, remaining_time)
	
	# 更新时间显示（格式：分:秒）
	var minutes = int(remaining_time) / 60
	var seconds = int(remaining_time) % 60
	time.text = "剩余时间: %02d:%02d" % [minutes, seconds]
	
	# 根据剩余时间设置颜色
	if current_battle_state == BattleState.BATTLING:
		if remaining_time <= 30:
			time.modulate = Color.RED
		elif remaining_time <= 60:
			time.modulate = Color.ORANGE
		else:
			time.modulate = Color.WHITE
	else:
		time.modulate = Color.WHITE

#显示战斗结果
func show_battle_result(winner: String):
	"""显示战斗结果"""
	battle_end_panel.visible = true
	
	var title_label = battle_end_panel.get_node("Title")
	var contents_label = battle_end_panel.get_node("Contents")
	
	# 设置标题
	match winner:
		"attacker":
			title_label.text = "进攻方获胜！"
		"defender":
			title_label.text = "防守方获胜！"
		_:
			title_label.text = "平局！"
	
	# 生成战斗统计
	var stats_text = generate_battle_stats()
	contents_label.text = stats_text

#生成战斗统计信息
func generate_battle_stats() -> String:
	"""生成战斗统计信息"""
	var stats = "战斗时间: %.1f秒\n\n" % battle_time
	
	# MVP统计
	var max_damage = 0.0
	var mvp_pet = ""
	for pet_id in damage_dealt:
		if damage_dealt[pet_id] > max_damage:
			max_damage = damage_dealt[pet_id]
			mvp_pet = pet_id
	
	if mvp_pet != "":
		stats += "MVP: %s (造成伤害: %.0f)\n" % [mvp_pet, max_damage]
	
	stats += "\n战斗详情:\n"
	for log_entry in battle_log.slice(-10):  # 显示最后10条记录
		stats += log_entry + "\n"
	
	return stats

#添加战斗日志
func add_battle_log(message: String):
	"""添加战斗日志"""
	battle_log.append(message)
	
	# 限制日志数量以优化内存
	if battle_log.size() > 50:
		battle_log = battle_log.slice(-30)  # 保留最后30条
	
	# 减少UI更新频率
	if battle_log.size() % 5 == 0:  # 每5条日志更新一次UI
		var display_logs = battle_log.slice(-15)  # 只显示最后15条
		battle_details_text.text = "\n".join(display_logs)

#返回农场按钮
func _on_return_farm_pressed():
	"""返回农场按钮"""
	# 清理战斗场景
	clear_all_pets()
	
	# 清理子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		bullet.queue_free()
	
	# 隐藏面板
	visible = false

#获取战斗总结数据
func get_battle_summary() -> Dictionary:
	"""获取战斗总结数据"""
	return {
		"battle_time": battle_time,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"kills": kills,
		"battle_log": battle_log
	}

#直接认输逃跑
func _on_stop_battle_button_pressed() -> void:
	# 检查战斗是否已经结束
	if current_battle_state == BattleState.ENDED:
		return
	
	# 添加逃跑日志
	add_battle_log("[color=yellow]玩家选择认输逃跑！[/color]")
	
	# 立即结束战斗，设置防守方获胜（玩家认输）
	end_battle("defender")
	
	# 清理所有宠物的AI状态并移除宠物
	for pet in all_pets:
		if is_instance_valid(pet):
			pet.current_state = NewPetBase.PetState.DEAD  # 设置为死亡状态
			pet.current_target = null  # 清除目标
			pet.is_alive = false  # 设置为死亡
			pet.queue_free()  # 删除宠物
	
	# 清理所有召唤的仆从小弟
	clear_all_minions()
	
	# 清空宠物数组
	team_a_pets.clear()
	team_b_pets.clear()
	all_pets.clear()
	
	# 清理子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		bullet.queue_free()

# 面板显示时的处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
		pass
	else:
		GlobalVariables.isZoomDisabled = false
		pass
#=====================UI显示===========================


#开始战斗
func start_battle(team_a_data: Array, team_b_data: Array):
	"""开始战斗"""
	current_battle_state = BattleState.PREPARING
	battle_time = 0.0
	battle_log.clear()
	damage_dealt.clear()
	damage_taken.clear()
	kills.clear()
	
	# 清理现有宠物
	clear_all_pets()
	# 生成队伍A的宠物（进攻方）
	spawn_team(team_a_data, "attacker", team_a_node)
	# 生成队伍B的宠物（防守方）
	spawn_team(team_b_data, "defender", team_b_node)
	
	# 开始战斗
	current_battle_state = BattleState.BATTLING
	battle_started.emit()
	
	add_battle_log("[color=yellow]战斗开始！[/color]")

#生成队伍宠物
func spawn_team(team_data: Array, team_name: String, team_node: Node2D):
	"""生成队伍宠物"""
	var positions = get_team_positions(team_node)
	
	for i in range(min(team_data.size(), positions.size())):
		var pet_info = team_data[i]
		var pet = spawn_pet(pet_info, team_name, positions[i])
		if pet:
			if team_name == "attacker":
				team_a_pets.append(pet)
			else:
				team_b_pets.append(pet)
			all_pets.append(pet)

#获取队伍位置点
func get_team_positions(team_node: Node2D) -> Array[Vector2]:
	"""获取队伍位置点"""
	var positions: Array[Vector2] = []
	for child in team_node.get_children():
		if child is Marker2D:
			positions.append(team_node.global_position + child.position)
	return positions

#生成单个宠物
func spawn_pet(pet_info: Dictionary, team: String, pos: Vector2) -> NewPetBase:
	"""生成单个宠物"""
	var pet_scene = preload("res://Scene/NewPet/NewPetBase.tscn")
	var pet = pet_scene.instantiate()
	
	# 添加到场景
	add_child(pet)
	pet.global_position = pos
	pet.pet_team = team
	
	# 处理服务器返回的完整宠物数据或配置键值
	var config_key = pet_info.get("config_key", "")
	var pet_type = pet_info.get("pet_type", "")
	var config_data: Dictionary
	
	if config_key != "" and pet_config:
		# 使用指定的配置键值
		config_data = pet_config.get_pet_config(config_key)
		apply_pet_config(pet, config_data)
		apply_level_scaling(pet)
	elif pet_type != "" and pet_config and pet_config.has_pet_config(pet_type):
		# 使用宠物类型作为配置键值
		config_data = pet_config.get_pet_config(pet_type)
		apply_pet_config(pet, config_data)
		# 覆盖配置中的数据为服务器返回的实际数据
		apply_server_pet_data(pet, pet_info)
		apply_level_scaling(pet)
	else:
		# 直接使用服务器返回的宠物数据
		apply_server_pet_data(pet, pet_info)
		apply_level_scaling(pet)
	
	# 连接信号
	pet.pet_died.connect(_on_pet_died)
	pet.pet_attacked.connect(_on_pet_attacked)
	pet.pet_skill_used.connect(_on_pet_skill_used)
	
	# 添加到宠物组
	pet.add_to_group("pets")
	
	# 初始化统计数据
	damage_dealt[pet.pet_id] = 0.0
	damage_taken[pet.pet_id] = 0.0
	kills[pet.pet_id] = 0
	
	pet_spawned.emit(pet)
	return pet

#应用服务器返回的宠物数据
func apply_server_pet_data(pet: NewPetBase, pet_data: Dictionary):
	"""应用服务器返回的完整宠物数据"""
	if pet_data.is_empty():
		return
	
	# 基本属性
	if pet_data.has("pet_name"):
		pet.pet_name = pet_data["pet_name"]
	if pet_data.has("pet_id"):
		pet.pet_id = pet_data["pet_id"]
	if pet_data.has("pet_type"):
		pet.pet_type = pet_data["pet_type"]
	if pet_data.has("pet_level"):
		pet.pet_level = pet_data["pet_level"]
	
	# 生命与防御
	if pet_data.has("max_health"):
		pet.max_health = pet_data["max_health"]
		# 优先使用服务器返回的当前生命值，否则使用最大生命值
		if pet_data.has("pet_current_health"):
			pet.current_health = pet_data["pet_current_health"]
		else:
			pet.current_health = pet.max_health
	if pet_data.has("enable_health_regen"):
		pet.enable_health_regen = pet_data["enable_health_regen"]
	if pet_data.has("health_regen"):
		pet.health_regen = pet_data["health_regen"]
	if pet_data.has("enable_shield_regen"):
		pet.enable_shield_regen = pet_data["enable_shield_regen"]
	if pet_data.has("max_shield"):
		pet.max_shield = pet_data["max_shield"]
		pet.current_shield = pet.max_shield
	if pet_data.has("shield_regen"):
		pet.shield_regen = pet_data["shield_regen"]
	if pet_data.has("max_armor"):
		pet.max_armor = pet_data["max_armor"]
		pet.current_armor = pet.max_armor
	
	# 攻击属性
	if pet_data.has("base_attack_damage"):
		pet.base_attack_damage = pet_data["base_attack_damage"]
	if pet_data.has("crit_rate"):
		pet.crit_rate = pet_data["crit_rate"]
	if pet_data.has("crit_damage"):
		pet.crit_damage = pet_data["crit_damage"]
	if pet_data.has("armor_penetration"):
		pet.armor_penetration = pet_data["armor_penetration"]
	
	# 技能配置
	if pet_data.has("enable_multi_projectile_skill"):
		pet.enable_multi_projectile_skill = pet_data["enable_multi_projectile_skill"]
	if pet_data.has("multi_projectile_delay"):
		pet.multi_projectile_delay = pet_data["multi_projectile_delay"]
	if pet_data.has("enable_berserker_skill"):
		pet.enable_berserker_skill = pet_data["enable_berserker_skill"]
	if pet_data.has("berserker_bonus"):
		pet.berserker_bonus = pet_data["berserker_bonus"]
	if pet_data.has("berserker_duration"):
		pet.berserker_duration = pet_data["berserker_duration"]
	if pet_data.has("enable_self_destruct_skill"):
		pet.enable_self_destruct_skill = pet_data["enable_self_destruct_skill"]
	if pet_data.has("self_destruct_damage"):
		pet.self_destruct_damage = pet_data["self_destruct_damage"]
	if pet_data.has("enable_summon_pet_skill"):
		pet.enable_summon_pet_skill = pet_data["enable_summon_pet_skill"]
	if pet_data.has("summon_count"):
		pet.summon_count = pet_data["summon_count"]
	if pet_data.has("summon_scale"):
		pet.summon_scale = pet_data["summon_scale"]
	if pet_data.has("enable_death_respawn_skill"):
		pet.enable_death_respawn_skill = pet_data["enable_death_respawn_skill"]
	if pet_data.has("respawn_health_percentage"):
		pet.respawn_health_percentage = pet_data["respawn_health_percentage"]
	
	# 移动属性
	if pet_data.has("move_speed"):
		pet.move_speed = pet_data["move_speed"]
	if pet_data.has("dodge_rate"):
		pet.dodge_rate = pet_data["dodge_rate"]
	
	# 元素属性
	if pet_data.has("element_type"):
		if typeof(pet_data["element_type"]) == TYPE_STRING:
			pet.element_type = string_to_element_type(pet_data["element_type"])
		else:
			pet.element_type = pet_data["element_type"]
	if pet_data.has("element_damage_bonus"):
		pet.element_damage_bonus = pet_data["element_damage_bonus"]
	
	# 武器系统
	if pet_data.has("left_weapon") and pet_data["left_weapon"] != "":
		pet.equip_weapon(pet_data["left_weapon"], "left")
	if pet_data.has("right_weapon") and pet_data["right_weapon"] != "":
		pet.equip_weapon(pet_data["right_weapon"], "right")
	
	# 宠物外观配置
	if pet_data.has("pet_image"):
		pet.pet_image_path = pet_data["pet_image"]
		apply_pet_image(pet, pet_data["pet_image"])
	
	# 打印调试信息
	print("[PetBattlePanel] 应用服务器宠物数据: %s (等级%d)" % [pet.pet_name, pet.pet_level])

#字符串转元素类型枚举
func string_to_element_type(element_string: String) -> NewPetBase.ElementType:
	"""将字符串转换为元素类型枚举"""
	match element_string.to_upper():
		"FIRE":
			return NewPetBase.ElementType.FIRE
		"WATER":
			return NewPetBase.ElementType.WATER
		"EARTH":
			return NewPetBase.ElementType.EARTH
		"METAL":
			return NewPetBase.ElementType.METAL
		"WOOD":
			return NewPetBase.ElementType.WOOD
		"THUNDER":
			return NewPetBase.ElementType.THUNDER
		_:
			return NewPetBase.ElementType.NONE

#将配置应用到宠物上
func apply_pet_config(pet: NewPetBase, config: Dictionary):
	"""将配置应用到宠物上"""
	if not config.is_empty():
		# 基本属性
		if config.has("pet_name"):
			pet.pet_name = config["pet_name"]
		if config.has("pet_id"):
			pet.pet_id = config["pet_id"]
		if config.has("pet_type"):
			pet.pet_type = config["pet_type"]
		if config.has("pet_level"):
			pet.pet_level = config["pet_level"]
		
		# 生命与防御
		if config.has("max_health"):
			pet.max_health = config["max_health"]
			pet.current_health = pet.max_health
		if config.has("enable_health_regen"):
			pet.enable_health_regen = config["enable_health_regen"]
		if config.has("health_regen"):
			pet.health_regen = config["health_regen"]
		if config.has("enable_shield_regen"):
			pet.enable_shield_regen = config["enable_shield_regen"]
		if config.has("max_shield"):
			pet.max_shield = config["max_shield"]
			pet.current_shield = pet.max_shield
		if config.has("shield_regen"):
			pet.shield_regen = config["shield_regen"]
		if config.has("max_armor"):
			pet.max_armor = config["max_armor"]
			pet.current_armor = pet.max_armor
		
		# 攻击属性
		if config.has("base_attack_damage"):
			pet.base_attack_damage = config["base_attack_damage"]
		if config.has("crit_rate"):
			pet.crit_rate = config["crit_rate"]
		if config.has("crit_damage"):
			pet.crit_damage = config["crit_damage"]
		if config.has("armor_penetration"):
			pet.armor_penetration = config["armor_penetration"]
		
		# 技能配置
		if config.has("enable_multi_projectile_skill"):
			pet.enable_multi_projectile_skill = config["enable_multi_projectile_skill"]
		if config.has("multi_projectile_delay"):
			pet.multi_projectile_delay = config["multi_projectile_delay"]
		if config.has("enable_berserker_skill"):
			pet.enable_berserker_skill = config["enable_berserker_skill"]
		if config.has("berserker_bonus"):
			pet.berserker_bonus = config["berserker_bonus"]
		if config.has("berserker_duration"):
			pet.berserker_duration = config["berserker_duration"]
		if config.has("enable_self_destruct_skill"):
			pet.enable_self_destruct_skill = config["enable_self_destruct_skill"]
		if config.has("self_destruct_damage"):
			pet.self_destruct_damage = config["self_destruct_damage"]
		if config.has("enable_summon_pet_skill"):
			pet.enable_summon_pet_skill = config["enable_summon_pet_skill"]
		if config.has("summon_count"):
			pet.summon_count = config["summon_count"]
		if config.has("summon_scale"):
			pet.summon_scale = config["summon_scale"]
		if config.has("enable_death_respawn_skill"):
			pet.enable_death_respawn_skill = config["enable_death_respawn_skill"]
		if config.has("respawn_health_percentage"):
			pet.respawn_health_percentage = config["respawn_health_percentage"]
		
		# 移动属性
		if config.has("move_speed"):
			pet.move_speed = config["move_speed"]
		if config.has("dodge_rate"):
			pet.dodge_rate = config["dodge_rate"]
		
		# 元素属性
		if config.has("element_type"):
			pet.element_type = config["element_type"]
		if config.has("element_damage_bonus"):
			pet.element_damage_bonus = config["element_damage_bonus"]
		
		# 武器系统
		if config.has("left_weapon") and config["left_weapon"] != "":
			pet.equip_weapon(config["left_weapon"], "left")
		if config.has("right_weapon") and config["right_weapon"] != "":
			pet.equip_weapon(config["right_weapon"], "right")
		
		# 宠物外观配置
		if config.has("pet_image"):
			pet.pet_image_path = config["pet_image"]  # 保存图片路径
			apply_pet_image(pet, config["pet_image"])
	
#应用宠物外观图片
func apply_pet_image(pet: NewPetBase, image_path: String):
	"""应用宠物外观图片"""
	if image_path == "" or not ResourceLoader.exists(image_path):
		return
	
	# 加载新的宠物场景
	var new_pet_scene = load(image_path)
	if not new_pet_scene:
		return
	
	# 实例化新场景以获取图片组件
	var temp_instance = new_pet_scene.instantiate()
	# 根节点本身就是PetImage
	var new_pet_image = temp_instance
	var new_left_tool = temp_instance.get_node_or_null("LeftToolImage")
	var new_right_tool = temp_instance.get_node_or_null("RightToolImage")
	
	if new_pet_image and new_pet_image is AnimatedSprite2D:
		# 复制动画帧到现有宠物
		if new_pet_image.sprite_frames:
			pet.pet_image.sprite_frames = new_pet_image.sprite_frames
			pet.pet_image.animation = new_pet_image.animation
			pet.pet_image.scale = new_pet_image.scale
			# 确保动画播放
			pet.pet_image.play()
			
		# 复制工具图片
		if new_left_tool and pet.left_tool_image:
			pet.left_tool_image.texture = new_left_tool.texture
			pet.left_tool_image.position = new_left_tool.position
			pet.left_tool_image.flip_h = new_left_tool.flip_h
			pet.left_tool_image.z_index = new_left_tool.z_index
			pet.left_tool_image.visible = true
			
		if new_right_tool and pet.right_tool_image:
			pet.right_tool_image.texture = new_right_tool.texture
			pet.right_tool_image.position = new_right_tool.position
			pet.right_tool_image.flip_h = new_right_tool.flip_h
			pet.right_tool_image.show_behind_parent = new_right_tool.show_behind_parent
			pet.right_tool_image.visible = true
			
		# 外观应用成功
	else:
		pass  # 静默处理错误
	
	# 清理临时实例
	temp_instance.queue_free()
	
	# 重新更新武器图标（因为外观应用可能覆盖了武器图标）
	if pet.weapon_system != null:
		pet.update_weapon_icons()

# 每5级特殊效果配置字典
var level_bonus_config = {
	5: {"crit_rate": 0.05, "armor_penetration": 10.0, "dodge_rate": 0.05},
	10: {"crit_rate": 0.05, "armor_penetration": 10.0, "dodge_rate": 0.05, "move_speed": 20.0},
	15: {"crit_rate": 0.05, "armor_penetration": 15.0, "dodge_rate": 0.05, "crit_damage": 0.2},
	20: {"crit_rate": 0.05, "armor_penetration": 15.0, "dodge_rate": 0.05, "health_regen": 2.0, "shield_regen": 2.0},
	25: {"crit_rate": 0.05, "armor_penetration": 20.0, "dodge_rate": 0.05, "element_damage_bonus": 30.0},
	30: {"crit_rate": 0.05, "armor_penetration": 20.0, "dodge_rate": 0.05, "knockback_force": 100.0},
	35: {"crit_rate": 0.05, "armor_penetration": 25.0, "dodge_rate": 0.05, "attack_range": 20.0},
	40: {"crit_rate": 0.05, "armor_penetration": 25.0, "dodge_rate": 0.05, "crit_damage": 0.3},
	45: {"crit_rate": 0.05, "armor_penetration": 30.0, "dodge_rate": 0.05, "move_speed": 30.0},
	50: {"crit_rate": 0.05, "armor_penetration": 30.0 , "dodge_rate": 0.05, "element_damage_bonus": 50.0, "health_regen": 3.0}
}

#应用等级缩放
func apply_level_scaling(pet: NewPetBase):
	"""应用等级缩放"""
	# 每级+2基本属性
	var level_bonus = (pet.pet_level - 1) * 2.0
	
	# 基本属性增长
	pet.max_health += level_bonus  # 最大生命值
	pet.current_health = pet.max_health
	pet.base_attack_damage += level_bonus  # 基础攻击伤害
	pet.max_armor += level_bonus  # 最大护甲值
	pet.current_armor = pet.max_armor
	pet.max_shield += level_bonus  # 最大护盾值
	pet.current_shield = pet.max_shield
	
	# 应用每5级的特殊效果
	for level_threshold in level_bonus_config.keys():
		if pet.pet_level >= level_threshold:
			var bonuses = level_bonus_config[level_threshold]
			for attribute in bonuses.keys():
				var bonus_value = bonuses[attribute]
				match attribute:
					"crit_rate":
						pet.crit_rate = min(0.8, pet.crit_rate + bonus_value)  # 最大80%暴击率
					"armor_penetration":
						pet.armor_penetration += bonus_value
					"attack_speed":
						pet.attack_speed += bonus_value
					"dodge_rate":
						pet.dodge_rate = min(0.5, pet.dodge_rate + bonus_value)  # 最大50%闪避率
					"move_speed":
						pet.move_speed += bonus_value
					"crit_damage":
						pet.crit_damage += bonus_value
					"health_regen":
						pet.health_regen += bonus_value
					"shield_regen":
						pet.shield_regen += bonus_value
					"element_damage_bonus":
						pet.element_damage_bonus += bonus_value
					"knockback_force":
						pet.knockback_force += bonus_value
					"attack_range":
						pet.attack_range += bonus_value 

#更新战斗状态
func update_battle_state():
	"""更新战斗状态"""
	# 先清理无效的宠物引用
	cleanup_invalid_pet_references()
	
	# 检查是否有队伍全灭
	var team_a_alive = team_a_pets.filter(func(pet): return is_instance_valid(pet) and pet.is_alive).size()
	var team_b_alive = team_b_pets.filter(func(pet): return is_instance_valid(pet) and pet.is_alive).size()
	
	if team_a_alive == 0 and team_b_alive == 0:
		end_battle("平局")
	elif team_a_alive == 0:
		end_battle("defender")
	elif team_b_alive == 0:
		end_battle("attacker")



#=================即时清理防止游戏卡死=====================
#清理无效的宠物引用
func cleanup_invalid_pet_references():
	"""清理数组中的无效宠物引用"""
	# 清理all_pets数组中的无效引用
	var valid_all_pets: Array[NewPetBase] = []
	for pet in all_pets:
		if is_instance_valid(pet):
			valid_all_pets.append(pet)
	all_pets = valid_all_pets
	
	# 清理team_a_pets数组中的无效引用
	var valid_team_a_pets: Array[NewPetBase] = []
	for pet in team_a_pets:
		if is_instance_valid(pet):
			valid_team_a_pets.append(pet)
	team_a_pets = valid_team_a_pets
	
	# 清理team_b_pets数组中的无效引用
	var valid_team_b_pets: Array[NewPetBase] = []
	for pet in team_b_pets:
		if is_instance_valid(pet):
			valid_team_b_pets.append(pet)
	team_b_pets = valid_team_b_pets

func cleanup_dead_objects():
	"""清理死亡对象以优化性能"""
	# 更严格的死亡宠物清理逻辑
	var dead_pets = []
	for pet in all_pets:
		# 检查宠物是否真正死亡（防止重生技能导致的状态不一致）
		if not is_instance_valid(pet):
			# 无效的宠物对象，直接标记清理
			dead_pets.append(pet)
		elif not pet.is_alive and pet.current_health <= 0:
			# 确保宠物真正死亡：生命值为0且is_alive为false
			# 额外检查：如果有重生技能但重生次数已用完
			if pet.enable_death_respawn_skill and pet.current_respawn_count < pet.max_respawn_count:
				# 还有重生机会，不清理
				continue
			else:
				# 确认死亡，标记清理
				pet.current_state = NewPetBase.PetState.DEAD
				dead_pets.append(pet)
	
	# 清理确认死亡的宠物
	for pet in dead_pets:
		if is_instance_valid(pet):
			# 确保从所有数组中移除
			all_pets.erase(pet)
			team_a_pets.erase(pet)
			team_b_pets.erase(pet)
			# 从场景中移除
			if pet.get_parent():
				pet.get_parent().remove_child(pet)
			pet.queue_free()
		else:
			# 无效对象，直接从数组中移除
			all_pets.erase(pet)
			team_a_pets.erase(pet)
			team_b_pets.erase(pet)
	
	# 清理无效子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if not is_instance_valid(bullet) or (bullet.has_method("is_active") and not bullet.is_active):
			bullet.queue_free()

#结束战斗
func end_battle(winner: String):
	"""结束战斗"""
	if current_battle_state == BattleState.ENDED:
		return
	
	current_battle_state = BattleState.ENDED
	
	# 清理所有宠物的AI状态并移除宠物
	for pet in all_pets:
		if is_instance_valid(pet):
			pet.current_state = NewPetBase.PetState.DEAD  # 设置为死亡状态
			pet.current_target = null  # 清除目标
			pet.is_alive = false  # 设置为死亡
			pet.queue_free()  # 删除宠物
	
	# 清理所有召唤的仆从小弟
	clear_all_minions()
	
	# 清空宠物数组
	team_a_pets.clear()
	team_b_pets.clear()
	all_pets.clear()
	
	# 清理子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		bullet.queue_free()
	
	# 显示战斗结果
	show_battle_result(winner)
	
	# 生成战斗数据
	var battle_data = {
		"attacker_pets": [],
		"defender_pets": [],
		"battle_duration": battle_time,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"kills": kills,
		"battle_log": battle_log
	}
	
	# 发射战斗结束信号
	battle_ended.emit(winner, battle_data)
	
	add_battle_log("[color=red]战斗结束！获胜方: %s[/color]" % winner)

	for child in get_children():
		if child is Area2D:
			remove_child(child)
			child.queue_free()

#清理所有宠物
func clear_all_pets():
	"""清理所有宠物"""
	for pet in all_pets:
		if is_instance_valid(pet):
			pet.queue_free()
	
	# 清理所有召唤的仆从小弟
	clear_all_minions()
	
	team_a_pets.clear()
	team_b_pets.clear()
	all_pets.clear()

#清理所有召唤的仆从小弟
func clear_all_minions():
	"""清理所有召唤的仆从小弟"""
	# 获取所有pets组中的节点
	var all_pets_in_group = get_tree().get_nodes_in_group("pets")
	var minions_cleared = 0
	
	for pet in all_pets_in_group:
		if is_instance_valid(pet) and pet is NewPetBase:
			# 立即设置为死亡状态
			pet.is_alive = false
			pet.current_state = NewPetBase.PetState.DEAD
			pet.current_target = null
			# 从场景中移除
			if pet.get_parent():
				pet.get_parent().remove_child(pet)
			pet.queue_free()
			minions_cleared += 1
	
	if minions_cleared > 0:
		add_battle_log("[color=purple]清理了 %d 个召唤仆从[/color]" % minions_cleared)

#立即清理所有宠物
func clear_all_pets_immediately():
	"""立即清理所有宠物（用于时间到时的平局处理）"""
	for pet in all_pets:
		if is_instance_valid(pet):
			# 立即设置为死亡状态
			pet.is_alive = false
			pet.current_state = NewPetBase.PetState.DEAD
			pet.current_target = null
			# 立即从场景中移除
			pet.get_parent().remove_child(pet)
			pet.queue_free()
	
	# 清理所有召唤的仆从小弟
	clear_all_minions()
	
	# 清理所有子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	# 清空宠物数组
	team_a_pets.clear()
	team_b_pets.clear()
	all_pets.clear()
	
	add_battle_log("[color=red]时间到！所有宠物已被清理，战斗结束！[/color]")
#=================即时清理防止游戏卡死=====================


#宠物死亡事件
func _on_pet_died(pet: NewPetBase):
	"""宠物死亡事件"""
	# 简化死亡处理，减少不必要的计算
	if battle_log.size() < 30:  # 限制死亡日志数量
		add_battle_log("[color=red]%s 死亡[/color]" % pet.pet_name)

#宠物攻击事件
func _on_pet_attacked(attacker: NewPetBase, target: NewPetBase, damage: float):
	"""宠物攻击事件"""
	# 简化统计更新
	damage_dealt[attacker.pet_id] = damage_dealt.get(attacker.pet_id, 0.0) + damage
	damage_taken[target.pet_id] = damage_taken.get(target.pet_id, 0.0) + damage
	
	# 大幅减少攻击日志，只记录关键事件
	if damage >= 100:  # 只记录高伤害攻击
		add_battle_log("[color=orange]%s->%s %.0f[/color]" % [attacker.pet_name, target.pet_name, damage])

#宠物技能使用事件
func _on_pet_skill_used(pet: NewPetBase, skill_name: String):
	"""宠物技能使用事件"""
	# 减少技能日志，只记录重要技能
	if skill_name in ["狂暴模式", "自爆", "召唤小弟", "死亡重生"]:
		add_battle_log("[color=cyan]%s:%s[/color]" % [pet.pet_name, skill_name])


#================偷菜对战设置===========================
# 设置偷菜对战
func setup_steal_battle(attacker_pets: Array, defender_pets: Array, attacker_name: String, defender_name: String):
	"""设置偷菜对战"""
	print("[PetBattlePanel] 设置偷菜对战: 攻击者=%s, 防守者=%s" % [attacker_name, defender_name])
	print("[PetBattlePanel] 攻击方宠物数量: %d, 防守方宠物数量: %d" % [attacker_pets.size(), defender_pets.size()])
	
	# 检查双方是否都有宠物
	if attacker_pets.is_empty() or defender_pets.is_empty():
		print("[PetBattlePanel] 错误: 双方必须至少有一个宠物才能参战")
		return false
	
	# 重置战斗状态和UI
	current_battle_state = BattleState.PREPARING
	battle_time = 0.0
	battle_log.clear()
	damage_dealt.clear()
	damage_taken.clear()
	kills.clear()
	
	# 隐藏战斗结束面板，显示战斗细节面板
	battle_end_panel.visible = false
	battle_details_panel.visible = true
	
	# 重置战斗日志显示
	battle_details_text.text = "[color=green]战斗准备中...[/color]\n"
	
	# 限制出战宠物数量最多4个
	var limited_attacker_pets = attacker_pets.slice(0, min(4, attacker_pets.size()))
	var limited_defender_pets = defender_pets.slice(0, min(4, defender_pets.size()))
	
	print("[PetBattlePanel] 限制后攻击方宠物数量: %d, 防守方宠物数量: %d" % [limited_attacker_pets.size(), limited_defender_pets.size()])
	
	# 显示对战面板
	show()
	
	# 清理现有宠物
	clear_all_pets()
	
	# 设置队伍信息
	team_a_name = attacker_name + "(攻击方)"
	team_b_name = defender_name + "(防守方)"
	
	# 获取队伍位置点
	var team_a_positions = get_team_positions(team_a_node)
	var team_b_positions = get_team_positions(team_b_node)
	
	# 生成攻击方宠物(teamA)
	for i in range(limited_attacker_pets.size()):
		var pet_data = limited_attacker_pets[i]
		var position = team_a_positions[i] if i < team_a_positions.size() else team_a_positions[0]
		var pet = spawn_pet(pet_data, "attacker", position)
		if pet:
			team_a_pets.append(pet)
			all_pets.append(pet)
	
	# 生成防守方宠物(teamB)
	for i in range(limited_defender_pets.size()):
		var pet_data = limited_defender_pets[i]
		var position = team_b_positions[i] if i < team_b_positions.size() else team_b_positions[0]
		var pet = spawn_pet(pet_data, "defender", position)
		if pet:
			team_b_pets.append(pet)
			all_pets.append(pet)
	
	print("[PetBattlePanel] 对战设置完成，攻击方: %d只，防守方: %d只" % [team_a_pets.size(), team_b_pets.size()])
	
	# 添加战斗日志
	add_battle_log("[color=yellow]偷菜对战开始！[/color]")
	add_battle_log("[color=cyan]%s VS %s[/color]" % [team_a_name, team_b_name])
	
	# 开始战斗
	start_battle(limited_attacker_pets, limited_defender_pets)
	
	return true
#================偷菜对战设置===========================


#================场外辅助===========================

#美化确认弹窗
func setup_confirm_dialog():
	"""设置和美化确认弹窗"""
	confirm_dialog.title = "辅助功能确认"
	confirm_dialog.ok_button_text = "确认使用"
	confirm_dialog.cancel_button_text = "取消"
	confirm_dialog.unresizable = false
	confirm_dialog.size = Vector2i(450, 200)
	
	# 创建并应用主题样式
	var theme = Theme.new()
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.4, 0.95)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.4, 0.6, 0.8, 1.0)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	
	theme.set_stylebox("panel", "AcceptDialog", style_box)
	confirm_dialog.theme = theme

#更新辅助功能冷却计时器
func update_assist_cooldowns(delta: float):
	"""更新辅助功能冷却计时器"""
	# 更新冷却计时器
	if heal_cooldown_timer > 0:
		heal_cooldown_timer -= delta
		if heal_cooldown_timer <= 0:
			team_a_heal_button.disabled = false
			team_a_heal_button.text = "团队治疗"
		else:
			team_a_heal_button.text = "治疗冷却 %.1fs" % heal_cooldown_timer
	
	if rage_cooldown_timer > 0:
		rage_cooldown_timer -= delta
		if rage_cooldown_timer <= 0:
			team_a_rage_button.disabled = false
			team_a_rage_button.text = "团队狂暴"
		else:
			team_a_rage_button.text = "狂暴冷却 %.1fs" % rage_cooldown_timer
	
	if shield_cooldown_timer > 0:
		shield_cooldown_timer -= delta
		if shield_cooldown_timer <= 0:
			team_a_shield_button.disabled = false
			team_a_shield_button.text = "团队护盾"
		else:
			team_a_shield_button.text = "护盾冷却 %.1fs" % shield_cooldown_timer

#显示辅助功能确认弹窗
func show_assist_confirm(operation_type: String, description: String, effect: String):
	"""显示辅助功能确认弹窗"""
	current_assist_operation = operation_type
	
	# 设置弹窗内容（纯文本格式）
	var dialog_text = "%s\n\n" % description
	dialog_text += "效果：%s\n\n" % effect
	dialog_text += "注意：使用后该技能将进入5秒冷却时间\n\n"
	dialog_text += "确定要使用这个辅助功能吗？"
	
	confirm_dialog.dialog_text = dialog_text
	confirm_dialog.popup_centered()

#确认使用辅助功能
func _on_assist_confirmed():
	"""确认使用辅助功能"""
	match current_assist_operation:
		"heal":
			execute_team_heal()
		"rage":
			execute_team_rage()
		"shield":
			execute_team_shield()
	
	current_assist_operation = ""

#取消使用辅助功能
func _on_assist_canceled():
	"""取消使用辅助功能"""
	current_assist_operation = ""

#执行团队治疗
func execute_team_heal():
	"""执行团队治疗功能"""
	var healed_count = 0
	# 只对teamA（attacker队伍）的宠物生效
	for pet in all_pets:
		if pet.is_alive and pet.pet_team == "attacker":
			var heal_amount = pet.max_health * 0.3  # 恢复30%最大生命值
			pet.current_health = min(pet.max_health, pet.current_health + heal_amount)
			pet.update_health_bar()
			healed_count += 1
			
			# 添加治疗特效（绿色光芒）- 使用弱引用避免访问已销毁的对象
			if pet.pet_image:
				var pet_ref = weakref(pet)
				var tween = create_tween()
				tween.tween_method(func(color): 
					var pet_obj = pet_ref.get_ref()
					if pet_obj != null and is_instance_valid(pet_obj) and pet_obj.pet_image:
						pet_obj.pet_image.modulate = color, 
					Color.WHITE, Color.GREEN, 0.3)
				tween.tween_method(func(color): 
					var pet_obj = pet_ref.get_ref()
					if pet_obj != null and is_instance_valid(pet_obj) and pet_obj.pet_image:
						pet_obj.pet_image.modulate = color, 
					Color.GREEN, Color.WHITE, 0.3)
	
	# 启动冷却
	heal_cooldown_timer = assist_cooldown_time
	team_a_heal_button.disabled = true
	
	add_battle_log("[color=green]🌿 使用团队治疗！为 %d 只teamA宠物恢复了30%%生命值[/color]" % healed_count)

#执行团队狂暴
func execute_team_rage():
	"""执行团队狂暴功能"""
	var raged_count = 0
	# 只对teamA（attacker队伍）的宠物生效
	for pet in all_pets:
		if pet.is_alive and pet.pet_team == "attacker":
			# 激活狂暴模式5秒
			pet.is_berserker = true
			raged_count += 1
			
			# 添加狂暴特效（红色光芒）
			if pet.pet_image:
				pet.pet_image.modulate = Color.RED
				
			# 5秒后自动取消狂暴（使用弱引用避免访问已销毁的对象）
			var pet_ref = weakref(pet)
			get_tree().create_timer(5.0).timeout.connect(func():
				var pet_obj = pet_ref.get_ref()
				if pet_obj != null and is_instance_valid(pet_obj) and pet_obj.is_alive:
					pet_obj.is_berserker = false
					if pet_obj.pet_image:
						pet_obj.pet_image.modulate = Color.WHITE
			)
	
	# 启动冷却
	rage_cooldown_timer = assist_cooldown_time
	team_a_rage_button.disabled = true
	
	add_battle_log("[color=red]🔥 使用团队狂暴！%d 只teamA宠物进入狂暴状态5秒[/color]" % raged_count)

#执行团队护盾
func execute_team_shield():
	"""执行团队护盾功能"""
	var shielded_count = 0
	# 只对teamA（attacker队伍）的宠物生效
	for pet in all_pets:
		if pet.is_alive and pet.pet_team == "attacker":
			# 增加100点护盾（允许超过最大值）
			pet.current_shield += 10000
			# 临时提高最大护盾值以显示正确的进度条
			if pet.current_shield > pet.max_shield:
				pet.max_shield = pet.current_shield
			pet.update_shield_bar()
			shielded_count += 1
			
			# 添加护盾特效（蓝色光芒）- 使用弱引用避免访问已销毁的对象
			if pet.pet_image:
				var pet_ref = weakref(pet)
				var tween = create_tween()
				tween.tween_method(func(color): 
					var pet_obj = pet_ref.get_ref()
					if pet_obj != null and is_instance_valid(pet_obj) and pet_obj.pet_image:
						pet_obj.pet_image.modulate = color, 
					Color.WHITE, Color.BLUE, 0.3)
				tween.tween_method(func(color): 
					var pet_obj = pet_ref.get_ref()
					if pet_obj != null and is_instance_valid(pet_obj) and pet_obj.pet_image:
						pet_obj.pet_image.modulate = color, 
					Color.BLUE, Color.WHITE, 0.3)
	
	# 启动冷却
	shield_cooldown_timer = assist_cooldown_time
	team_a_shield_button.disabled = true
	
	add_battle_log("[color=blue]🛡️ 使用团队护盾！为 %d 只teamA宠物增加了100点护甲[/color]" % shielded_count)

#团队治疗按钮（直接恢复30%血量）
func _on_team_a_heal_pressed() -> void:
	if heal_cooldown_timer > 0:
		return
	
	show_assist_confirm("heal", "团队治疗", "为所有存活的己方宠物恢复30%最大生命值")

#团队狂暴按钮（直接进入五秒狂暴模式，与狂暴技能不冲突）
func _on_team_a_rage_pressed() -> void:
	if rage_cooldown_timer > 0:
		return
	
	show_assist_confirm("rage", "团队狂暴", "让所有存活的己方宠物进入狂暴状态5秒，攻击力翻倍")

#团队护盾按钮（直接加100护盾）
func _on_team_a_shield_pressed() -> void:
	if shield_cooldown_timer > 0:
		return
	
	show_assist_confirm("shield", "团队护盾", "为所有存活的己方宠物增加100点护甲值")

#================场外辅助===========================

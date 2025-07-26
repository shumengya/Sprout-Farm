extends Area2D
class_name NewPetBase

#============================信号管理==============================
signal pet_died(pet: NewPetBase)
signal pet_attacked(attacker: NewPetBase, target: NewPetBase, damage: float)
signal pet_skill_used(pet: NewPetBase, skill_name: String)
#============================信号管理==============================


#============================节点引用===============================
# 节点引用
@onready var pet_image: AnimatedSprite2D = $PetImage
@onready var left_tool_image: Sprite2D = $PetImage/LeftToolImage
@onready var right_tool_image: Sprite2D = $PetImage/RightToolImage
@onready var volume_collision: CollisionShape2D = $VolumeCollision

# UI节点引用
@onready var pet_inform_vbox: VBoxContainer = $PetInformVBox
@onready var pet_name_rich_text: RichTextLabel = $PetInformVBox/PetNameRichText
@onready var armor_bar: ProgressBar = $PetInformVBox/ArmorBar
@onready var armor_label: Label = $PetInformVBox/ArmorBar/ArmorLabel
@onready var shield_bar: ProgressBar = $PetInformVBox/ShieldBar
@onready var shield_label: Label = $PetInformVBox/ShieldBar/ShieldLabel
@onready var health_bar: ProgressBar = $PetInformVBox/HealthBar
@onready var health_label: Label = $PetInformVBox/HealthBar/HealthLabel
#============================节点引用===============================


#============================枚举===============================
# 攻击类型枚举
enum AttackType {
	MELEE		# 近战攻击
}

enum ElementType {
	NONE, METAL, WOOD, WATER, FIRE, EARTH, THUNDER
}

enum PetState {
	IDLE,		# 待机
	MOVING,		# 移动
	ATTACKING,	# 攻击中
	SKILL_CASTING,	# 释放技能
	PATROLLING,	# 巡逻
	DEAD		# 死亡
}
#============================枚举===============================


#============================宠物所有属性===============================
# 基本属性
var pet_name: String = "萌芽小绿"  # 宠物名称
var pet_team: String = "attacker"  # 所属队伍（attacker进攻方 或 defender防守方）
var pet_id: String = "0001"  # 宠物唯一编号
var pet_type: String = "小绿"  # 宠物种类
var pet_level: int = 50  # 宠物等级
var pet_image_path: String = ""  # 宠物图片路径

# 生命与防御
var max_health: float = 200.0  # 最大生命值
var current_health: float = 200.0  # 当前生命值
var enable_health_regen: bool = true  # 是否开启生命恢复
var health_regen: float = 1.0  # 每秒生命恢复大小
var enable_shield_regen: bool = true  # 是否开启护盾恢复
var max_shield: float = 100.0  # 最大护盾值
var current_shield: float = 100.0  # 当前护盾值
var shield_regen: float = 1.0  # 每秒护盾恢复大小
var max_armor: float = 100.0  # 最大护甲值
var current_armor: float = 100.0  # 当前护甲值

# 攻击属性
var attack_type: AttackType = AttackType.MELEE  # 攻击类型（仅近战）
var base_attack_damage: float = 25.0  # 基础攻击力
var attack_range: float = 100.0  # 攻击范围（近战或远程都适用）
var attack_speed: float = 1.0  # 每秒攻击次数（攻速）
var crit_rate: float = 0.1  # 暴击几率（0~1）
var crit_damage: float = 1.5  # 暴击伤害倍率（1.5 = 150%伤害）
var armor_penetration: float = 0.0  # 护甲穿透值（无视对方部分护甲）

# 技能-多发射击
var enable_multi_projectile_skill: bool = false
var projectile_speed: float = 300.0  # 投射物飞行速度
var multi_projectile_count: int = 0  # 多发射击触发标记（0=未触发，1=已触发）
var multi_projectile_delay: float = 2  # 多发射击延迟时间（秒）
var multi_projectile_spread: float = 10.0  # 多发射击角度范围（度）
var spawn_time: float = 0.0  # 宠物生成时间

# 技能-狂暴模式
var enable_berserker_skill: bool = false  
var berserker_threshold: float = 0.3  # 狂暴触发阈值（生命值百分比）
var berserker_bonus: float = 1.5  # 狂暴伤害加成
var berserker_duration: float = 5.0  # 狂暴持续时间（秒）
var berserker_triggered: bool = false  # 是否已触发过狂暴（防止重复触发）
var is_berserker: bool = false  # 是否处于狂暴状态
var berserker_end_time: float = 0.0  # 狂暴结束时间

#技能-自爆
var enable_self_destruct_skill: bool = false
var self_destruct_damage: float = 50.0  # 自爆伤害值

#技能-召唤小弟
var enable_summon_pet_skill: bool = false 
var summon_health_threshold: float = 0.5  # 召唤触发阈值（生命值百分比）
var summon_count: int = 1  # 召唤小弟数量
var summon_triggered: bool = false  # 是否已触发过召唤（防止重复触发）
var summon_scale: float = 0.1  # 召唤小弟属性缩放比例（10%）

#技能-死亡重生
var enable_death_respawn_skill: bool = false
var respawn_health_percentage: float = 0.3  # 重生时恢复的血量百分比（30%）
var max_respawn_count: int = 1  # 最大重生次数
var current_respawn_count: int = 0  # 当前已重生次数

#击退效果
var enable_knockback: bool = true  # 是否启用击退效果
var knockback_force: float = 300.0  # 击退力度（像素/秒）
var knockback_duration: float = 0.8  # 击退持续时间（秒）
var knockback_velocity: Vector2 = Vector2.ZERO  # 当前击退速度
var knockback_end_time: float = 0.0  # 击退结束时间
var is_being_knocked_back: bool = false  # 是否正在被击退

# 边界限制
var boundary_min: Vector2 = Vector2(0, 0)  # 边界最小坐标
var boundary_max: Vector2 = Vector2(1400, 720)  # 边界最大坐标
var boundary_damage: float = 10.0  # 碰撞边界时受到的伤害
var boundary_bounce_force: float = 200.0  # 边界反弹力度


# 移动属性
var move_speed: float = 150.0  # 移动速度（像素/秒）
var dodge_rate: float = 0.05  # 闪避概率（0~1）

# 元素属性
var element_type: ElementType = ElementType.NONE  # 元素类型（例如火、水、雷等）
var element_damage_bonus: float = 50.0  # 元素伤害加成（额外元素伤害）


# 武器系统
var left_weapon: String = ""  # 左手武器名称
var right_weapon: String = ""  # 右手武器名称
var weapon_system: WeaponBase  # 武器系统引用

# 巡逻状态
var is_patrolling: bool = false					# 是否正在巡逻
var patrol_path: PackedVector2Array = []		# 巡逻路径点
var patrol_speed: float = 80.0					# 巡逻移动速度
var current_patrol_index: int = 0				# 当前巡逻目标点索引
var patrol_wait_time: float = 0.0				# 在巡逻点的等待时间
var patrol_max_wait_time: float = 1.0			# 在巡逻点的最大等待时间

# 巡逻随机走动
var patrol_center_position: Vector2 = Vector2.ZERO	# 巡逻中心点位置
var patrol_radius: float = 150.0					# 巡逻半径
var patrol_target_position: Vector2 = Vector2.ZERO	# 当前巡逻目标位置
var patrol_move_timer: float = 0.0					# 巡逻移动计时器
var patrol_move_interval: float = 2.0				# 巡逻移动间隔（秒）

# 战斗控制
var combat_enabled: bool = true					# 是否启用战斗行为

#============================宠物所有属性===============================



#============================杂项未处理===============================
# 状态变量
var current_state: PetState = PetState.IDLE  # 当前状态（待机、移动、攻击等）
var current_target: NewPetBase = null  # 当前目标（敌方宠物对象）
var last_attack_time: float = 0.0  # 上次攻击时间（用于计算攻速冷却）
var velocity: Vector2 = Vector2.ZERO  # 当前移动速度（方向与速度）
var is_alive: bool = true  # 是否存活

# 子弹场景
var bullet_scene: PackedScene = preload("res://Scene/NewPet/BulletBase.tscn")

# 性能优化变量
var update_ui_timer: float = 0.0
var ui_update_interval: float = 0.2  # UI更新间隔，减少频繁更新
var ai_update_timer: float = 0.0
var ai_update_interval: float = 0.05  # AI更新间隔，平衡性能和反应速度
#============================杂项未处理===============================


#====================基础方法=========================
func _ready():
	# 记录生成时间
	spawn_time = Time.get_ticks_msec() / 1000.0
	#默认佩戴武器测试武器系统
	equip_weapon("钻石剑", "left")
	equip_weapon("铁镐", "right")
	
	# 初始化武器系统
	init_weapon_system()
	
	# 初始化UI
	update_ui()
	# 设置碰撞层和掩码
	setup_collision_layers()
	# 延迟一帧后开始AI，确保所有宠物都已生成
	await get_tree().process_frame
	_start_ai()

func _physics_process(delta):
	if not is_alive:
		return
	
	# 更新计时器
	update_ui_timer += delta
	ai_update_timer += delta
	
	# 生命恢复
	if enable_health_regen and current_health < max_health:
		current_health = min(max_health, current_health + health_regen * delta)
	
	# 护盾恢复
	if enable_shield_regen and max_shield > 0 and current_shield < max_shield:
		current_shield = min(max_shield, current_shield + shield_regen * delta)
	
	# 巡逻逻辑已简化为静态生成，无需移动处理
	
	# AI更新
	if ai_update_timer >= ai_update_interval:
		update_ai()
		ai_update_timer = 0.0
	
	# 检查技能-多发射击触发
	if enable_multi_projectile_skill:
		check_multi_projectile_skill()
	
	# 检查技能-狂暴模式触发
	if enable_berserker_skill:
		check_berserker_skill()
	
	# 检查技能-召唤小弟触发
	if enable_summon_pet_skill:
		check_summon_pet_skill()
	
	# 击退效果处理
	if is_being_knocked_back:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time >= knockback_end_time:
			# 击退结束
			is_being_knocked_back = false
			knockback_velocity = Vector2.ZERO
		else:
			# 应用击退速度，逐渐衰减
			var remaining_time = knockback_end_time - current_time
			var decay_factor = remaining_time / knockback_duration
			position += knockback_velocity * decay_factor * delta
	
	# 移动处理（击退时不应用普通移动）
	if not is_being_knocked_back and velocity.length() > 0:
		position += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)  # 摩擦力
	
	# 边界检测和反弹处理
	check_boundary_collision()
	
	# UI更新
	if update_ui_timer >= ui_update_interval:
		update_ui()
		update_ui_timer = 0.0
#====================基础方法=========================



#=========================宠物系统通用函数==================================
#设置碰撞体积（对远程攻击还是有用的）
func setup_collision_layers():
	collision_layer = 1
	collision_mask = 1

#开启宠物ai系统
func _start_ai():
	"""启动AI，立即寻找目标"""
	if not is_alive:
		return
	
	# 立即寻找最近的敌人
	current_target = find_nearest_enemy()
	
	# 如果找到目标，开始移动或攻击
	if current_target != null:
		current_state = PetState.MOVING
		# 找到攻击目标

#AI逻辑更新
func update_ai():
	"""AI逻辑更新"""
	if current_state == PetState.DEAD or is_being_knocked_back:
		return
	
	# 如果正在巡逻，执行巡逻AI逻辑
	if is_patrolling:
		update_patrol_ai()
		return
	
	# 如果启用了战斗且不在巡逻状态，执行战斗AI
	if combat_enabled and not is_patrolling:
		# 寻找目标（即使在攻击状态也要检查目标有效性）
		if current_target == null or not current_target.is_alive:
			current_target = find_nearest_enemy()
		
		if current_target == null:
			# 没有目标时，继续搜索而不是待机
			current_state = PetState.MOVING
			pet_image.animation = "walk"
			# 随机移动寻找敌人
			var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			velocity = random_direction * move_speed * 0.5
			return
		
		# 如果正在攻击，等待攻击完成
		if current_state == PetState.ATTACKING:
			return
		
		var distance_to_target = global_position.distance_to(current_target.global_position)
		
		# 优先近战攻击（包含武器攻击范围加成）
		var total_attack_range = attack_range
		if distance_to_target <= total_attack_range:
			if can_attack():
				perform_melee_attack()
			else:
				current_state = PetState.IDLE
				pet_image.animation = "idle"
		else:
			# 移动到目标
			move_towards_target()

#寻找最近的敌人
func find_nearest_enemy() -> NewPetBase:
	"""寻找最近的敌人"""
	var enemies = get_tree().get_nodes_in_group("pets")
	var nearest_enemy: NewPetBase = null
	var min_distance = INF
	
	for enemy in enemies:
		if enemy == self or not enemy.is_alive or enemy.pet_team == pet_team:
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

#移动到目标
func move_towards_target():
	"""移动到目标"""
	if current_target == null:
		return
	
	current_state = PetState.MOVING
	pet_image.animation = "walk"
	
	var direction = (current_target.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# 翻转精灵
	if direction.x < 0:
		pet_image.flip_h = false
		left_tool_image.flip_h = true
		right_tool_image.flip_h = true
		left_tool_image.position = Vector2(-12.5,3.5)
		right_tool_image.position = Vector2(-7.5,-6.25)
		#left_tool_image.rotation = 21.8
		#right_tool_image.rotation = -14.5
		

	else:
		pet_image.flip_h = true
		left_tool_image.flip_h = false
		right_tool_image.flip_h = false
		left_tool_image.position = Vector2(12.5,3.5)
		right_tool_image.position = Vector2(7.5,-6.25)
		#left_tool_image.rotation = -21.8
		#right_tool_image.rotation = 14.5

#检查边界碰撞并处理反弹和伤害
func check_boundary_collision():
	"""检查边界碰撞并处理反弹和伤害"""
	if not is_alive:
		return
	
	# 巡逻宠物不受边界限制
	if is_patrolling:
		return
	
	var collision_occurred = false
	var bounce_direction = Vector2.ZERO
	
	# 检查X轴边界
	if position.x < boundary_min.x:
		position.x = boundary_min.x
		bounce_direction.x = 1.0  # 向右反弹
		collision_occurred = true
	elif position.x > boundary_max.x:
		position.x = boundary_max.x
		bounce_direction.x = -1.0  # 向左反弹
		collision_occurred = true
	
	# 检查Y轴边界
	if position.y < boundary_min.y:
		position.y = boundary_min.y
		bounce_direction.y = 1.0  # 向下反弹
		collision_occurred = true
	elif position.y > boundary_max.y:
		position.y = boundary_max.y
		bounce_direction.y = -1.0  # 向上反弹
		collision_occurred = true
	
	# 如果发生碰撞，应用反弹和伤害
	if collision_occurred:
		# 应用反弹效果
		if bounce_direction.length() > 0:
			bounce_direction = bounce_direction.normalized()
			velocity = bounce_direction * boundary_bounce_force
			# 如果正在被击退，也要修改击退方向
			if is_being_knocked_back:
				knockback_velocity = bounce_direction * knockback_force
		
		# 造成边界伤害
		take_damage(boundary_damage, null)
		# 边界碰撞处理

#检查是否可以攻击
func can_attack() -> bool:
	"""检查是否可以攻击"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last_attack = current_time - last_attack_time
	# 计算总攻击速度（包含武器加成）
	var total_attack_speed = attack_speed 
	var attack_cooldown = 1.0 / max(0.1, total_attack_speed)  # 防止除零错误
	return time_since_last_attack >= attack_cooldown

#执行近战攻击
func perform_melee_attack():
	"""执行近战攻击"""
	current_state = PetState.ATTACKING
	pet_image.animation = "idle"  # 可以添加攻击动画
	last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# 显示武器
	left_tool_image.visible = true
	right_tool_image.visible = true
	
	# 直接攻击当前目标（如果在攻击范围内）
	if current_target != null and current_target.is_alive:
		var distance_to_target = global_position.distance_to(current_target.global_position)
		var total_attack_range = attack_range 
		if distance_to_target <= total_attack_range and current_target.pet_team != pet_team:
			deal_damage_to(current_target)
			# 执行近战攻击
	
	# 隐藏武器并重置状态（延迟）
	get_tree().create_timer(0.2).timeout.connect(func(): 
		#left_tool_image.visible = false
		#right_tool_image.visible = false
		current_state = PetState.IDLE
	)


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
			#pet.pet_image.animation = new_pet_image.animation
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

#对目标造成伤害
func deal_damage_to(target: NewPetBase):
	"""对目标造成伤害"""
	var damage = calculate_damage(target)
	target.take_damage(damage, self)
	
	# 应用击退效果
	if enable_knockback and target.enable_knockback and target.is_alive:
		apply_knockback_to(target)
	
	# 发射信号
	pet_attacked.emit(self, target, damage)

#对目标应用击退效果
func apply_knockback_to(target: NewPetBase):
	"""对目标应用击退效果"""
	if not target.is_alive or target.is_being_knocked_back:
		return
	
	# 计算击退方向（从攻击者指向目标）
	var knockback_direction = (target.global_position - global_position).normalized()
	
	# 如果距离太近，使用随机方向避免除零错误
	if knockback_direction.length() < 0.1:
		knockback_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 设置击退参数（包含武器击退力加成）
	var total_knockback_force = target.knockback_force 
	target.knockback_velocity = knockback_direction * total_knockback_force
	target.is_being_knocked_back = true
	var current_time = Time.get_ticks_msec() / 1000.0
	target.knockback_end_time = current_time + target.knockback_duration
	
	# 击退时暂停AI行为
	if target.current_state != PetState.DEAD:
		target.current_state = PetState.IDLE
	
	# 击退效果生效

#计算伤害
func calculate_damage(target: NewPetBase) -> float:
	"""计算伤害"""
	var damage = base_attack_damage
	
	# 添加元素伤害加成（固定额外伤害）
	damage += element_damage_bonus
	
	# 狂暴模式伤害加成
	if is_berserker:
		damage *= berserker_bonus
	
	# 暴击计算（包含武器暴击率加成）
	var total_crit_rate = crit_rate 
	if randf() < total_crit_rate:
		damage *= crit_damage
	
	# 元素克制倍数（相克关系的倍数加成）
	var element_multiplier = get_element_multiplier(element_type, target.element_type)
	damage *= element_multiplier
	
	# 护甲减伤计算（新系统：护甲值直接减免伤害，但最少保留1点伤害）
	# 包含武器护甲穿透加成
	var total_armor_penetration = armor_penetration 
	var effective_armor = max(0, target.current_armor - total_armor_penetration)
	# 护甲值直接减免伤害
	damage = max(1.0, damage - effective_armor)  # 最少保留1点伤害
	
	return damage

#获取元素克制倍数
func get_element_multiplier(attacker_element: ElementType, defender_element: ElementType) -> float:
	"""获取元素克制倍数"""
	# 简化的元素克制系统
	if attacker_element == ElementType.FIRE and defender_element == ElementType.WOOD:
		return 1.5
	elif attacker_element == ElementType.WATER and defender_element == ElementType.FIRE:
		return 1.5
	elif attacker_element == ElementType.WOOD and defender_element == ElementType.EARTH:
		return 1.5
	else:
		return 1.0

#受到伤害
func take_damage(damage: float, attacker: NewPetBase):
	"""受到伤害"""
	if not is_alive:
		return
	
	# 检查攻击者是否有效（防止已释放对象错误）
	var attacker_name = "未知攻击者"
	if attacker != null and is_instance_valid(attacker):
		attacker_name = attacker.pet_name
	
	# 闪避检查
	if randf() < dodge_rate:
		# 闪避成功
		return  # 闪避成功
	
	# 护盾优先吸收伤害
	if current_shield > 0:
		var shield_damage = min(current_shield, damage)
		current_shield -= shield_damage
		damage -= shield_damage
		# 护盾吸收伤害
	
	# 护盾消耗完后，剩余伤害扣除生命值
	if damage > 0:
		current_health -= damage
		# 受到伤害
		
		# 受伤视觉效果（短暂变红）
		if not is_berserker:  # 狂暴状态下不覆盖红色效果
			pet_image.modulate = Color(1.3, 0.7, 0.7, 1.0)
			get_tree().create_timer(0.15).timeout.connect(func(): 
				if not is_berserker and is_alive:
					pet_image.modulate = Color(1.0, 1.0, 1.0, 1.0)
			)
	
	# 检查死亡
	if current_health <= 0:
		die()

#治疗
func heal(amount: float):
	"""治疗"""
	current_health = min(max_health, current_health + amount)

#死亡处理
func die():
	"""死亡处理"""
	# 防止重复死亡处理
	if current_state == PetState.DEAD:
		return
	
	# 检查死亡重生技能
	if enable_death_respawn_skill and current_respawn_count < max_respawn_count:
		trigger_death_respawn_skill()
		return  # 重生成功，不执行死亡逻辑
	
	# 确认死亡状态
	is_alive = false
	current_state = PetState.DEAD
	current_health = 0  # 确保生命值为0
	velocity = Vector2.ZERO  # 停止移动
	current_target = null  # 清除目标
	
	# 死亡视觉效果
	modulate = Color(0.5, 0.5, 0.5, 0.7)  # 变灰
	
	# 触发自爆技能
	if enable_self_destruct_skill:
		trigger_self_destruct_skill()
	
	# 发射死亡信号
	pet_died.emit(self)
	
	# 从宠物组中移除
	remove_from_group("pets")

#更新UI显示
func update_ui():
	"""更新UI显示"""
	if pet_name_rich_text:
		pet_name_rich_text.text = pet_name
	
	update_health_bar()
	update_shield_bar()
	update_armor_bar()

#更新生命值条
func update_health_bar():
	"""更新生命值条"""
	if health_bar and health_label:
		health_bar.value = (current_health / max_health) * 100
		health_label.text = "生命值:%d/%d" % [current_health, max_health]

#更新护盾条
func update_shield_bar():
	"""更新护盾条"""
	if shield_bar and shield_label:
		if max_shield > 0:
			shield_bar.visible = true
			shield_label.visible = true
			shield_bar.value = (current_shield / max_shield) * 100
			shield_label.text = "护盾值:%d/%d" % [current_shield, max_shield]
		else:
			shield_bar.visible = false
			shield_label.visible = false

#更新护甲条
func update_armor_bar():
	"""更新护甲条"""
	if armor_bar and armor_label:
		if max_armor > 0:
			armor_bar.visible = true
			armor_label.visible = true
			armor_bar.value = (current_armor / max_armor) * 100
			armor_label.text = "护甲值:%d/%d" % [current_armor, max_armor]
		else:
			armor_bar.visible = false
			armor_label.visible = false
#=========================宠物系统通用函数==================================




#=======================宠物技能系统===================================


#==================特殊技能-多发射击=====================
func check_multi_projectile_skill():
	"""检查多发射击技能触发条件"""
	if multi_projectile_count > 0 or not is_alive:
		return
	
	# 宠物生成后按配置的延迟时间触发多发射击（只触发一次）
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - spawn_time >= multi_projectile_delay:  # 使用配置的延迟时间
		trigger_multi_projectile_skill()
		multi_projectile_count = 1  # 标记已触发，防止重复触发

func trigger_multi_projectile_skill():
	"""触发多发射击技能：发射3枚不同类型的平行子弹"""
	# 触发多发射击技能
	
	# 获取宠物朝向（基于精灵翻转状态）
	var forward_direction = Vector2.RIGHT if pet_image.flip_h else Vector2.LEFT
	
	# 定义三种不同的子弹类型
	var bullet_types = ["小蓝弹", "小红弹", "长紫弹"]
	
	# 发射3枚不同类型的平行子弹
	for i in range(3):
		var bullet = bullet_scene.instantiate()
		self.get_parent().add_child(bullet)
		
		# 计算子弹位置偏移（平行排列）
		var offset_y = (i - 1) * 30  # 上中下三枚子弹，间距30像素
		var bullet_position = global_position + Vector2(0, offset_y)
		bullet.global_position = bullet_position
		
		# 设置子弹属性，使用不同类型的子弹
		bullet.setup(forward_direction, projectile_speed, base_attack_damage * 0.6, self, bullet_types[i])
		
		# 稍微延迟发射，创造连发效果
		await get_tree().create_timer(0.05).timeout
#==================特殊技能-多发射击=====================


#==================特殊技能-狂暴模式=====================
func check_berserker_skill():
	"""检查狂暴技能触发条件"""
	if berserker_triggered or not is_alive:
		return
	
	# 检查生命值是否低于阈值
	var health_percentage = current_health / max_health
	if health_percentage <= berserker_threshold:
		trigger_berserker_skill()
		berserker_triggered = true
	
	# 检查狂暴是否结束
	if is_berserker:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time >= berserker_end_time:
			end_berserker_skill()

func trigger_berserker_skill():
	"""触发狂暴技能：提升攻击力和攻击速度"""
	# 触发狂暴技能
	
	is_berserker = true
	var current_time = Time.get_ticks_msec() / 1000.0
	berserker_end_time = current_time + berserker_duration
	
	# 视觉效果：宠物变红
	pet_image.modulate = Color(1.5, 0.8, 0.8, 1.0)
	
	# 提升攻击速度
	attack_speed *= 1.3
	
	# 发射技能信号
	pet_skill_used.emit(self, "狂暴模式")

func end_berserker_skill():
	"""结束狂暴技能"""
	# 狂暴模式结束
	
	is_berserker = false
	
	# 恢复正常颜色
	pet_image.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 恢复攻击速度
	attack_speed /= 1.3
#==================特殊技能-狂暴模式=====================


#==================特殊技能-自爆=====================
func trigger_self_destruct_skill():
	"""触发自爆技能：死亡时向周围360度发射12枚闪电子弹"""
	# 触发自爆技能
	
	# 计算12枚子弹的角度间隔（360度 / 12 = 30度）
	var bullet_count = 12
	var angle_step = 360.0 / bullet_count
	
	# 定义四种闪电子弹类型，循环使用
	var lightning_types = ["黄色闪电", "绿色闪电", "红色闪电", "紫色闪电"]
	
	# 发射12枚闪电子弹
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		# 计算子弹发射角度（度转弧度）
		var angle_degrees = i * angle_step
		var angle_radians = deg_to_rad(angle_degrees)
		
		# 计算子弹发射方向
		var direction = Vector2(cos(angle_radians), sin(angle_radians))
		
		# 设置子弹位置（从宠物中心发射）
		bullet.global_position = global_position
		
		# 设置子弹属性（自爆伤害），使用循环的闪电类型
		var bullet_type = lightning_types[i % lightning_types.size()]
		bullet.setup(direction, projectile_speed, self_destruct_damage, self, bullet_type)
		
		# 稍微延迟发射，创造爆炸效果
		await get_tree().create_timer(0.02).timeout
	
	# 发射技能信号
	pet_skill_used.emit(self, "自爆")
#==================特殊技能-自爆=====================


#==================特殊技能-召唤小弟=====================
func check_summon_pet_skill():
	"""检查召唤小弟技能触发条件"""
	if summon_triggered or not is_alive:
		return
	
	# 检查生命值是否低于阈值
	var health_percentage = current_health / max_health
	if health_percentage <= summon_health_threshold:
		trigger_summon_pet_skill()
		summon_triggered = true

func trigger_summon_pet_skill():
	"""触发召唤小弟技能：召唤迷你版自己"""
	# 触发召唤技能
	
	# 获取NewPetBase场景
	var pet_scene = preload("res://Scene/NewPet/NewPetBase.tscn")
	
	# 召唤指定数量的小弟
	for i in range(summon_count):
		var minion = pet_scene.instantiate()
		self.get_parent().add_child(minion)
		
		# 设置小弟位置（在召唤者周围随机位置）
		var offset_angle = randf() * 2 * PI
		var offset_distance = 80 + i * 30  # 避免重叠
		var offset = Vector2(cos(offset_angle), sin(offset_angle)) * offset_distance
		minion.global_position = global_position + offset
		
		# 设置小弟属性（原版的10%）
		minion.pet_name = pet_name + "的小弟" + str(i + 1)
		minion.pet_team = pet_team  # 同队伍
		minion.pet_id = pet_id + "_minion_" + str(i + 1)
		minion.pet_type = pet_type + "(迷你)"
		minion.pet_level = max(1, int(pet_level * summon_scale))
		
		# 复制宠物图片路径
		minion.pet_image_path = pet_image_path
		
		# 复制武器配置
		if left_weapon != "":
			minion.equip_weapon(left_weapon, "left")
		if right_weapon != "":
			minion.equip_weapon(right_weapon, "right")
		
		# 生命与防御属性缩放
		minion.max_health = max_health * summon_scale
		minion.current_health = minion.max_health
		minion.health_regen = health_regen * summon_scale
		minion.max_shield = max_shield * summon_scale
		minion.current_shield = minion.max_shield
		minion.shield_regen = shield_regen * summon_scale
		minion.max_armor = max_armor * summon_scale
		minion.current_armor = minion.max_armor
		
		# 攻击属性缩放
		minion.base_attack_damage = base_attack_damage * summon_scale
		minion.attack_range = attack_range * summon_scale
		minion.attack_speed = attack_speed * summon_scale
		minion.crit_rate = crit_rate * summon_scale
		minion.crit_damage = crit_damage
		minion.armor_penetration = armor_penetration * summon_scale
		
		# 移动属性缩放
		minion.move_speed = move_speed * summon_scale
		minion.dodge_rate = dodge_rate * summon_scale
		
		# 元素属性缩放
		minion.element_type = element_type
		minion.element_damage_bonus = element_damage_bonus * summon_scale
		
		# 技能属性缩放
		minion.self_destruct_damage = self_destruct_damage * summon_scale
		minion.berserker_bonus = berserker_bonus
		minion.berserker_duration = berserker_duration * summon_scale
		
		# 禁用小弟的所有技能
		minion.enable_multi_projectile_skill = false  # 禁用多发射击技能
		minion.enable_berserker_skill = false  # 禁用狂暴技能
		minion.enable_self_destruct_skill = false  # 禁用自爆技能
		minion.enable_summon_pet_skill = false  # 禁用召唤技能
		minion.enable_death_respawn_skill = false  # 禁用死亡重生技能
		
		# 应用宠物图片（如果有的话）
		if pet_image_path != "":
			apply_pet_image(minion, pet_image_path)
		
		# 设置小弟的缩放（视觉上更小，原宠物的二分之一）
		minion.scale = Vector2(0.5, 0.5)
		
		# 将小弟加入宠物组
		minion.add_to_group("pets")
		
		# 小弟召唤成功
	
	# 发射技能信号
	pet_skill_used.emit(self, "召唤小弟")
#==================特殊技能-召唤小弟=====================


#==================特殊技能-死亡重生=====================
func trigger_death_respawn_skill():
	"""触发死亡重生技能：重生并恢复30%血量"""
	# 增加重生次数
	current_respawn_count += 1
	
	# 恢复生命值到指定百分比
	current_health = max_health * respawn_health_percentage
	
	# 确保宠物处于存活状态
	is_alive = true
	current_state = PetState.IDLE
	velocity = Vector2.ZERO  # 重置速度
	
	# 恢复正常外观
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 重生视觉效果：短暂发光
	pet_image.modulate = Color(1.5, 1.5, 1.0, 1.0)  # 金色光芒
	get_tree().create_timer(1.0).timeout.connect(func(): 
		if is_alive and is_instance_valid(self):
			pet_image.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 恢复正常颜色
	)
	
	# 重生时清除所有负面状态
	is_being_knocked_back = false
	knockback_velocity = Vector2.ZERO
	
	# 重新加入宠物组（如果被移除了）
	if not is_in_group("pets"):
		add_to_group("pets")
	
	# 更新UI显示
	update_ui()
	
	# 发射技能信号
	pet_skill_used.emit(self, "死亡重生")
#==================特殊技能-死亡重生=====================


#=======================宠物技能系统===================================





#==========================巡逻系统函数=================================
# 巡逻AI逻辑更新
func update_patrol_ai():
	"""巡逻AI逻辑：在巡逻点周围随机走动"""
	current_target = null  # 清除攻击目标
	
	# 如果还没有设置巡逻中心点，使用当前位置作为中心点
	if patrol_center_position == Vector2.ZERO:
		patrol_center_position = global_position
		patrol_target_position = global_position
	
	# 更新巡逻移动计时器
	patrol_move_timer += get_physics_process_delta_time()
	
	# 检查是否到达目标位置或需要更换目标
	var distance_to_target = global_position.distance_to(patrol_target_position)
	if distance_to_target < 10.0 or patrol_move_timer >= patrol_move_interval:
		# 生成新的随机目标位置（在巡逻半径内）
		var random_angle = randf() * 5 * PI
		var random_distance = randf() * patrol_radius
		patrol_target_position = patrol_center_position + Vector2(
			cos(random_angle) * random_distance,
			sin(random_angle) * random_distance
		)
		patrol_move_timer = 0.0
	
	# 移动到目标位置
	var direction = (patrol_target_position - global_position).normalized()
	if direction.length() > 0.1:  # 避免抖动
		current_state = PetState.MOVING
		pet_image.animation = "walk"
		velocity = direction * patrol_speed
		
		# 翻转精灵
		if direction.x < 0:
			pet_image.flip_h = false
		else:
			pet_image.flip_h = true
	else:
		# 到达目标位置，待机
		current_state = PetState.IDLE
		pet_image.animation = "idle"
		velocity = Vector2.ZERO

# 设置巡逻中心点
func set_patrol_center(center_pos: Vector2):
	"""设置巡逻中心点位置"""
	patrol_center_position = center_pos
	patrol_target_position = center_pos

# 设置战斗启用状态
func set_combat_enabled(enabled: bool):
	combat_enabled = enabled
	if not enabled:
		# 禁用战斗时，清除当前目标
		current_target = null
		current_state = PetState.IDLE
#==========================巡逻系统函数=================================



#==========================武器系统函数=================================

func init_weapon_system():
	"""初始化武器系统"""
	weapon_system = WeaponBase.new()

func equip_weapon(weapon_name: String, slot: String) -> bool:
	"""装备武器到指定槽位"""
	if weapon_system == null:
		init_weapon_system()
	
	# 检查武器是否存在
	if not weapon_system.weapon_data.has(weapon_name):
		return false
	
	# 检查槽位是否有效
	if slot != "left" and slot != "right":
		return false
	
	# 卸下当前武器（如果有）
	if slot == "left" and left_weapon != "":
		unequip_weapon("left")
	elif slot == "right" and right_weapon != "":
		unequip_weapon("right")
	
	# 装备新武器
	if slot == "left":
		left_weapon = weapon_name
	elif slot == "right":
		right_weapon = weapon_name
	
	# 应用武器效果
	weapon_system.apply_weapon_effect(self, weapon_name)
	
	# 更新武器图标
	update_weapon_icons()
	
	# 武器装备完成
	return true

func unequip_weapon(slot: String) -> bool:
	"""卸下指定槽位的武器"""
	if weapon_system == null:
		return false
	
	var weapon_name = ""
	if slot == "left":
		weapon_name = left_weapon
		left_weapon = ""
	elif slot == "right":
		weapon_name = right_weapon
		right_weapon = ""
	else:
		return false
	
	if weapon_name == "":
		return false
	
	# 移除武器效果
	weapon_system.remove_weapon_effect(self, weapon_name)
	
	# 更新武器图标
	update_weapon_icons()
	
	# 武器卸载完成
	return true

func update_weapon_icons():
	"""更新武器图标显示"""
	if weapon_system == null:
		return
	
	# 更新左手武器图标
	if left_tool_image != null:
		if left_weapon != "":
			var icon_path = weapon_system.get_weapon_icon(left_weapon)
			if icon_path != "":
				left_tool_image.texture = load(icon_path)
				left_tool_image.visible = true
			else:
				left_tool_image.visible = false
		else:
			left_tool_image.visible = false
	
	# 更新右手武器图标
	if right_tool_image != null:
		if right_weapon != "":
			var icon_path = weapon_system.get_weapon_icon(right_weapon)
			if icon_path != "":
				right_tool_image.texture = load(icon_path)
				right_tool_image.visible = true
			else:
				right_tool_image.visible = false
		else:
			right_tool_image.visible = false
	
	# 武器图标更新完成

func get_equipped_weapons() -> Array:
	"""获取当前装备的武器列表"""
	var weapons = []
	if left_weapon != "":
		weapons.append({"slot": "left", "weapon": left_weapon})
	if right_weapon != "":
		weapons.append({"slot": "right", "weapon": right_weapon})
	return weapons

func has_weapon_type(weapon_type: String) -> bool:
	"""检查是否装备了指定类型的武器"""
	if weapon_system == null:
		return false
	
	# 根据武器名称判断类型
	var weapons_to_check = [left_weapon, right_weapon]
	for weapon_name in weapons_to_check:
		if weapon_name == "":
			continue
		
		# 根据武器名称判断类型
		if weapon_type == "sword" and (weapon_name.contains("剑")):
			return true
		elif weapon_type == "axe" and (weapon_name.contains("斧")):
			return true
		elif weapon_type == "pickaxe" and (weapon_name.contains("镐")):
			return true
	
	return false

func test_weapon_system():
	"""测试武器系统功能"""
	# 装备武器测试
	equip_weapon("钻石剑", "left")
	equip_weapon("铁镐", "right")

#==========================武器系统函数=================================

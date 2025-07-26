extends CharacterBody2D

@onready var pet_image: AnimatedSprite2D = $PetImage	#这里展示宠物动画
@onready var pet_tool_image: Sprite2D = $PetImage/PetToolImage #这里展示宠物武器工具
@onready var pet_name_rich_text: RichTextLabel = $PetInformVBox/PetNameRichText #这里展示主人给宠物命名的名字
@onready var armor_bar: ProgressBar = $PetInformVBox/ArmorBar #宠物盔甲值进度条
@onready var armor_label: Label = $PetInformVBox/ArmorBar/ArmorLabel #宠物盔甲值
@onready var shield_bar: ProgressBar = $PetInformVBox/ShieldBar #宠物护盾值进度条
@onready var shield_label: Label = $PetInformVBox/ShieldBar/ShieldLabel #宠物护盾值
@onready var health_bar: ProgressBar = $PetInformVBox/HealthBar #宠物生命值进度条
@onready var health_label: Label = $PetInformVBox/HealthBar/HealthLabel #宠物生命值
@onready var volume_collision: CollisionShape2D = $VolumeCollision #宠物碰撞体积


#=====================宠物基本属性=====================
### 一、基础信息  
#- 主人（主人名字）
#- 生日（年月日时分秒）
#- 年龄（从生日开始算
#- 性格（开朗，内向，活泼，安静，暴躁，温和，调皮，懒惰
#- 简介
#- 爱好
#- 宠物ID（唯一标识，从0000开始）
#- 宠物类型(宠物原本的名字，比如绿史莱姆，红史莱姆，迷你护卫，小绿人）
#- 宠物名称 （主人给宠物命名的名字）
#- 能否购买（true/false）
#- 购买价格（如果可以购买）
#- 出售价格（如果可以出售）

### 二、生存与防御  
#- 生命值（可恢复，小于等于0则死亡）
#- 护盾值（不可恢复的生命值）
#- 护甲值（折扣伤害）
#- 生命恢复（恢复生命值,多少秒恢复多少生命值，如0.5秒恢复10点生命值）
#- 闪避率（免疫伤害概率）
#- 控制抗性（减免被控时长和概率）
#- 击退抗性（抵消击退力度）
#- 移动速度

### 三、攻击与效果  
#- 普通攻击伤害
#- 普通攻击速度
#- 暴击率（暴击概率）
#- 暴击伤害
#- 护甲穿透（忽视敌人护甲）
#- 生命汲取（普攻回血%）
#- 击退（攻击使敌人后退）  

### 四、其他属性  
#- 元素属性（金木水火土，雷）
#- 等级（等级高属性强）
#- 经验值（满额升级）
#- 亲密度（额外加属性）
#- 品质（白/绿/蓝/橙/红/紫）

#近战
#近战攻击伤害
#近战攻击速度

#附录
#- 护甲公式示例：实际伤害 = 基础伤害 × (1 - 护甲值/(护甲值 + 100))，搭配"护甲穿透"可直接减少目标护甲值
#- 元素克制：火属性攻击对冰属性敌人造成150%伤害，同时被水属性克制（仅造成80%伤害）
#- 成长曲线：低级宠物升级快，高级宠物经验需求指数增长，避免养成周期过短

#特殊机制
#1.伤害反弹，无视防具穿透伤害，
#2.血量低于某个值进入狂暴模式，
#3.死亡后重生一次，
#4.毅力不倒、不死图腾(受到致命伤害抵挡并维持一滴血)
#5.援助 宠物血量低于某个值时，会自动召唤宠物仆从，宠物仆从会自动攻击敌人，唤数量（一次召唤多少个宠物仆从），唤间隔（多少秒召唤一次）
#=====================宠物基本属性=====================


# 宠物基本属性（从JSON配置文件加载）
var pet_owner: String = "树萌芽"	 # 宠物主人
var pet_name: String = "宠物名称"	 # 宠物名称
var pet_team: String = "team1" 		# 队伍标识：team1, team2, neutral
var pet_id: String = "0001"			# 宠物唯一ID
var pet_type: String = "小绿人"		# 宠物类型（原本名字）
var pet_birthday: String = ""		# 生日（年月日时分秒）
var pet_age: int = 0				# 年龄（天数）
var pet_personality: String = "活泼"	# 性格
var pet_introduction: String = ""	# 简介
var pet_hobby: String = ""			# 爱好

var pet_level: int = 1				# 宠物等级
var pet_experience: float = 0.0		# 当前经验值
var max_experience: float = 100.0	# 升级所需经验值
var pet_intimacy: float = 0.0		# 亲密度
var max_intimacy: float = 1000.0	# 最大亲密度

var can_buy: bool = true			# 能否购买
var buy_price: int = 100			# 购买价格
var sell_price: int = 50			# 出售价格

# 生命与防御属性
var max_health: float = 100.0		# 最大生命值
var current_health: float = 100.0	# 当前生命值
var health_regen: float = 1.0		# 生命恢复速度（每秒）
var max_shield: float = 0.0		# 最大护盾值
var current_shield: float = 0.0	# 当前护盾值
var shield_regen: float = 0.0		# 护盾恢复速度（每秒）- 默认不恢复
var max_armor: float = 100.0		# 最大护甲值
var current_armor: float = 100.0	# 当前护甲值

# 攻击属性
var attack_type: AttackType = AttackType.RANGED		# 攻击类型
var attack_damage: float = 20.0		# 基础攻击伤害
var attack_range: float = 400.0		# 攻击距离
var crit_rate: float = 0.1  		# 暴击率（0.0-1.0）
var crit_damage: float = 1.5  		# 暴击伤害倍数
var life_steal: float = 0.1			# 生命汲取（0.0-1.0）
var armor_penetration: float = 0.0	# 护甲穿透

var melee_damage_bonus: float = 0.0	# 近战额外伤害（在基础伤害上加成）
var melee_attack_speed: float = 1.0	# 近战攻击速度

var ranged_damage_bonus: float = 0.0	# 远程额外伤害（在基础伤害上加成）
var ranged_attack_speed: float = 1.0	# 远程攻击速度
var ranged_mode: RangedAttackMode = RangedAttackMode.SINGLE	# 远程攻击模式
var projectile_speed: float = 300.0				# 子弹速度

var shotgun_bullets: int = 5					# 散弹数量
var shotgun_spread_angle: float = 45.0			# 散弹扩散角度(度)

var burst_rows: int = 2							# 多发射击行数
var burst_cols: int = 3							# 多发射击列数
var burst_spacing: float = 30.0					# 多发射击间距

var gatling_bullets: int = 8					# 加特林子弹数量
var gatling_interval: float = 0.1				# 加特林射击间隔
var gatling_cooldown: float = 2.0				# 加特林冷却时间

var pierce_count: int = 3						# 穿透数量

# 远程攻击类型枚举
enum AttackType {
	MELEE,		# 近战攻击
	RANGED		# 远程攻击
}

enum RangedAttackMode {
	SINGLE,		# 普通单发
	SHOTGUN,	# 散弹攻击
	BURST,		# 多发射击(平行)
	GATLING,	# 加特林式连射
	PIERCING	# 穿透攻击
}


var attack_speed: float = 1.0  		# 当前攻击速度（根据攻击类型动态设置）
var gatling_firing: bool = false				# 是否正在加特林射击
var gatling_current_bullet: int = 0				# 当前加特林子弹计数
var gatling_last_shot: float = 0.0				# 上次加特林射击时间

@export var projectile_scene: PackedScene = preload("res://Scene/Pet/Projectile.tscn")	# 子弹场景

# 移动与闪避属性
var move_speed: float = 100.0		# 移动速度
var dodge_rate: float = 0.05  		# 闪避率（0.0-1.0）
var knockback_force: float = 300.0	# 击退力度
var knockback_resist: float = 0.0	# 击退抗性（0.0-1.0）

# 元素属性
enum ElementType {
	NONE,		# 无属性
	METAL,		# 金
	WOOD,		# 木
	WATER,		# 水
	FIRE,		# 火
	EARTH,		# 土
	THUNDER		# 雷
}
var element_type: ElementType = ElementType.NONE# 宠物元素属性
var element_damage_bonus: float = 50.0			# 元素克制额外伤害

var control_resist: float = 0.0					# 控制抗性（减少眩晕等控制时间）
var damage_reflect: float = 0.0					# 伤害反弹（0.0-1.0）
var death_immunity: bool = false				# 死亡免疫（一次性）
var berserker_threshold: float = 0.3			# 狂暴阈值（血量低于此值时触发狂暴）
var berserker_bonus: float = 1.5				# 狂暴状态伤害倍数

# 特殊机制开关（布尔值控制是否启用各种特殊机制）
var enable_damage_reflect: bool = false			# 启用伤害反弹机制
var enable_berserker_mode: bool = false			# 启用狂暴模式机制
var enable_death_immunity: bool = false			# 启用死亡免疫机制
var enable_aid_system: bool = false				# 启用援助召唤机制
var enable_resurrection: bool = false			# 启用死亡重生机制
var resurrection_used: bool = false				# 重生是否已使用

# 援助系统属性
var aid_threshold: float = 0.2					# 援助触发阈值（血量低于此值时召唤援助）
var aid_summon_count: int = 2					# 一次召唤的援助数量
var aid_summon_interval: float = 5.0			# 援助召唤间隔（秒）
var aid_last_summon_time: float = 0.0			# 上次召唤援助的时间
var aid_summoned: bool = false					# 是否已经召唤过援助（防止重复召唤）
var aid_minions: Array[CharacterBody2D] = []	# 召唤的援助宠物列表

# 品质系统
enum PetQuality {
	COMMON,		# 普通（白）
	UNCOMMON,	# 不凡（绿）
	RARE,		# 稀有（蓝）
	EPIC,		# 史诗（紫）
	LEGENDARY,	# 传说（橙）
	MYTHIC		# 神话（红）
}
var pet_quality: PetQuality = PetQuality.COMMON	# 宠物品质

# 战斗状态
var is_alive: bool = true						# 是否存活
var is_dying: bool = false						# 是否正在死亡过程中（防止重复调用die()）
var is_attacking: bool = false					# 是否正在攻击
var is_berserker: bool = false					# 是否处于狂暴状态
var is_stunned: bool = false					# 是否被眩晕
var is_invulnerable: bool = false				# 是否无敌
var current_target: CharacterBody2D = null		# 当前目标
var last_attacker: CharacterBody2D = null		# 最后攻击者（用于击杀奖励）
var last_attack_time: float = 0.0				# 上次攻击时间
var last_regen_time: float = 0.0				# 上次恢复时间
var last_target_check_time: float = 0.0		# 上次目标检查时间

# 受伤动画相关
var hurt_tween: Tween = null					# 受伤动画缓动
var original_modulate: Color = Color.WHITE		# 原始颜色
var last_hurt_time: float = 0.0				# 上次受伤时间（防止受伤动画过于频繁）
var hurt_animation_cooldown: float = 0.3		# 受伤动画冷却时间

# 攻击频率控制
var min_attack_interval: float = 0.5			# 最小攻击间隔（防止攻击过于频繁）

# 伤害反弹保护
var damage_reflect_depth: int = 0				# 伤害反弹递归深度
var max_reflect_depth: int = 3					# 最大反弹深度（防止无限递归）

# 性能保护
var performance_mode: bool = false				# 性能模式（减少特效和计算）
var frame_skip_counter: int = 0					# 帧跳跃计数器

# 升级系统 - 基础属性列表（每次升级随机选择加点）
var base_upgrade_attributes: Array[String] = [
	"max_health",      # 最大生命值
	"attack_damage",   # 攻击伤害  
	"move_speed",      # 移动速度
	"max_shield",      # 最大护盾值
	"max_armor",       # 最大护甲值
	"crit_rate",       # 暴击率
	"health_regen",    # 生命恢复
	"attack_range"     # 攻击距离
]

# 每次升级随机选择的属性数量
var attributes_per_level: int = 3

# 每5级额外属性奖励表
var level_milestone_bonuses: Dictionary = {
	5: {"max_health": 20, "attack_damage": 5, "crit_rate": 0.02}, 
	10: {"max_shield": 30, "armor_penetration": 5, "life_steal": 0.05},
	15: {"max_armor": 25, "knockback_resist": 0.1, "dodge_rate": 0.03},
	20: {"health_regen": 2, "move_speed": 15, "attack_range": 30},
	25: {"max_health": 40, "attack_damage": 10, "enable_berserker_mode": true},
	30: {"max_shield": 50, "shield_regen": 1, "enable_damage_reflect": true},
	35: {"crit_damage": 0.3, "berserker_bonus": 0.2, "damage_reflect": 0.05},
	40: {"max_armor": 40, "control_resist": 0.15, "enable_aid_system": true},
	45: {"projectile_speed": 50, "pierce_count": 1, "enable_death_immunity": true},
	50: {"max_health": 100, "attack_damage": 25, "enable_resurrection": true}
}

# 巡逻状态
var is_patrolling: bool = false					# 是否正在巡逻
var patrol_path: PackedVector2Array = []		# 巡逻路径点
var patrol_speed: float = 80.0					# 巡逻移动速度
var current_patrol_index: int = 0				# 当前巡逻目标点索引
var patrol_wait_time: float = 0.0				# 在巡逻点等待的时间
var patrol_max_wait_time: float = 1.0			# 在巡逻点的最大等待时间

# 战斗控制
var combat_enabled: bool = true					# 是否启用战斗行为

# AI状态
enum PetState {
	IDLE, #站立空闲
	MOVING_TO_TARGET, #移动到目标
	ATTACKING, #攻击
	PATROLLING, #巡逻
	DEAD #死亡
}
var current_state: PetState = PetState.IDLE	# 当前状态

# 队伍节点引用
var team_nodes: Dictionary = {}

# 从JSON配置文件加载宠物配置（强制要求）
func load_pet_config_from_json():
	var file = FileAccess.open("res://Data/pet_data.json", FileAccess.READ)
	if not file:
		set_basic_default_values()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		set_basic_default_values()
		return
	
	var pet_configs = json.data
	var pet_name_key = get_pet_name_key()
	
	if not pet_configs.has(pet_name_key):
		set_basic_default_values()
		return
	
	var config = pet_configs[pet_name_key]
	apply_json_config(config)

# 设置基本默认值（当JSON加载失败时使用）
func set_basic_default_values():
	# 基本信息
	pet_owner = "未知主人"
	pet_name = "未配置宠物"
	pet_team = "team1"
	pet_id = "0000"
	pet_type = "未知类型"
	pet_birthday = ""
	pet_age = 0
	pet_personality = "活泼"
	pet_introduction = ""
	pet_hobby = ""
	
	# 等级经验
	pet_level = 1
	pet_experience = 0.0
	max_experience = 100.0
	pet_intimacy = 0.0
	max_intimacy = 1000.0
	
	# 购买信息
	can_buy = true
	buy_price = 100
	sell_price = 50
	
	# 生命与防御
	max_health = 100.0
	current_health = 100.0
	health_regen = 1.0
	max_shield = 0.0
	current_shield = 0.0
	shield_regen = 0.0
	max_armor = 100.0
	current_armor = 100.0
	
	# 基础攻击属性
	attack_type = AttackType.RANGED
	attack_damage = 20.0
	attack_range = 300.0
	crit_rate = 0.1
	crit_damage = 1.5
	life_steal = 0.1
	armor_penetration = 0.0
	
	# 近战攻击
	melee_damage_bonus = 0.0
	melee_attack_speed = 1.0
	
	# 远程攻击
	ranged_damage_bonus = 0.0
	ranged_attack_speed = 1.0
	ranged_mode = RangedAttackMode.SINGLE
	projectile_speed = 300.0
	
	# 散弹攻击
	shotgun_bullets = 5
	shotgun_spread_angle = 45.0
	
	# 多发射击
	burst_rows = 2
	burst_cols = 3
	burst_spacing = 30.0
	
	# 加特林属性
	gatling_bullets = 8
	gatling_interval = 0.1
	gatling_cooldown = 2.0
	
	# 穿透属性
	pierce_count = 3
	
	# 移动与闪避
	move_speed = 100.0
	dodge_rate = 0.05
	knockback_force = 300.0
	knockback_resist = 0.0
	
	# 元素属性
	element_type = ElementType.NONE
	element_damage_bonus = 50.0
	
	# 特殊属性
	control_resist = 0.0
	damage_reflect = 0.0
	death_immunity = false
	berserker_threshold = 0.3
	berserker_bonus = 1.5
	
	# 特殊机制开关
	enable_damage_reflect = false
	enable_berserker_mode = false
	enable_death_immunity = false
	enable_aid_system = false
	enable_resurrection = false
	
	# 援助系统
	aid_threshold = 0.2
	aid_summon_count = 2
	aid_summon_interval = 5.0
	
	# 品质系统
	pet_quality = PetQuality.COMMON

# 获取宠物名称键（用于JSON配置查找）
func get_pet_name_key() -> String:
	# 直接返回宠物类型作为JSON键
	# 现在pet_type已经是正确的JSON键名了
	return pet_type

# 应用JSON配置到宠物属性
func apply_json_config(config: Dictionary):
	# 基本信息
	if config.has("基本信息"):
		var basic_info = config["基本信息"]
		if basic_info.has("宠物主人"):
			pet_owner = basic_info["宠物主人"]
		if basic_info.has("宠物名称"):
			pet_name = basic_info["宠物名称"]
		if basic_info.has("队伍标识"):
			pet_team = basic_info["队伍标识"]
		if basic_info.has("宠物ID"):
			pet_id = basic_info["宠物ID"]
		if basic_info.has("宠物类型"):
			pet_type = basic_info["宠物类型"]
		if basic_info.has("生日"):
			pet_birthday = basic_info["生日"]
		if basic_info.has("年龄"):
			pet_age = basic_info["年龄"]
		if basic_info.has("性格"):
			pet_personality = basic_info["性格"]
		if basic_info.has("简介"):
			pet_introduction = basic_info["简介"]
		if basic_info.has("爱好"):
			pet_hobby = basic_info["爱好"]
	
	# 等级经验
	if config.has("等级经验"):
		var level_exp = config["等级经验"]
		if level_exp.has("宠物等级"):
			pet_level = level_exp["宠物等级"]
		if level_exp.has("当前经验"):
			pet_experience = level_exp["当前经验"]
		if level_exp.has("最大经验"):
			max_experience = level_exp["最大经验"]
		if level_exp.has("亲密度"):
			pet_intimacy = level_exp["亲密度"]
		if level_exp.has("最大亲密度"):
			max_intimacy = level_exp["最大亲密度"]
	
	# 购买信息
	if config.has("购买信息"):
		var buy_info = config["购买信息"]
		if buy_info.has("能否购买"):
			can_buy = buy_info["能否购买"]
		if buy_info.has("购买价格"):
			buy_price = buy_info["购买价格"]
		if buy_info.has("出售价格"):
			sell_price = buy_info["出售价格"]
	
	# 生命与防御
	if config.has("生命与防御"):
		var health_defense = config["生命与防御"]
		if health_defense.has("最大生命值"):
			max_health = health_defense["最大生命值"]
		if health_defense.has("当前生命值"):
			current_health = health_defense["当前生命值"]
		if health_defense.has("生命恢复速度"):
			health_regen = health_defense["生命恢复速度"]
		if health_defense.has("最大护盾值"):
			max_shield = health_defense["最大护盾值"]
		if health_defense.has("当前护盾值"):
			current_shield = health_defense["当前护盾值"]
		if health_defense.has("护盾恢复速度"):
			shield_regen = health_defense["护盾恢复速度"]
		if health_defense.has("最大护甲值"):
			max_armor = health_defense["最大护甲值"]
		if health_defense.has("当前护甲值"):
			current_armor = health_defense["当前护甲值"]
	
	# 基础攻击属性
	if config.has("基础攻击属性"):
		var attack_attr = config["基础攻击属性"]
		if attack_attr.has("攻击类型"):
			var attack_type_str = attack_attr["攻击类型"]
			if attack_type_str == "MELEE":
				attack_type = AttackType.MELEE
			elif attack_type_str == "RANGED":
				attack_type = AttackType.RANGED
		if attack_attr.has("基础攻击伤害"):
			attack_damage = attack_attr["基础攻击伤害"]
		if attack_attr.has("攻击距离"):
			attack_range = attack_attr["攻击距离"]
		if attack_attr.has("暴击率"):
			crit_rate = attack_attr["暴击率"]
		if attack_attr.has("暴击伤害倍数"):
			crit_damage = attack_attr["暴击伤害倍数"]
		if attack_attr.has("生命汲取"):
			life_steal = attack_attr["生命汲取"]
		if attack_attr.has("护甲穿透"):
			armor_penetration = attack_attr["护甲穿透"]
	
	# 近战攻击
	if config.has("近战攻击"):
		var melee_attack = config["近战攻击"]
		if melee_attack.has("近战额外伤害"):
			melee_damage_bonus = melee_attack["近战额外伤害"]
		if melee_attack.has("近战攻击速度"):
			melee_attack_speed = melee_attack["近战攻击速度"]
	
	# 远程攻击
	if config.has("远程攻击"):
		var ranged_attack = config["远程攻击"]
		if ranged_attack.has("远程额外伤害"):
			ranged_damage_bonus = ranged_attack["远程额外伤害"]
		if ranged_attack.has("远程攻击速度"):
			ranged_attack_speed = ranged_attack["远程攻击速度"]
		if ranged_attack.has("远程攻击模式"):
			var ranged_mode_str = ranged_attack["远程攻击模式"]
			match ranged_mode_str:
				"SINGLE":
					ranged_mode = RangedAttackMode.SINGLE
				"SHOTGUN":
					ranged_mode = RangedAttackMode.SHOTGUN
				"BURST":
					ranged_mode = RangedAttackMode.BURST
				"GATLING":
					ranged_mode = RangedAttackMode.GATLING
				"PIERCING":
					ranged_mode = RangedAttackMode.PIERCING
		if ranged_attack.has("子弹速度"):
			projectile_speed = ranged_attack["子弹速度"]
	
	# 散弹攻击
	if config.has("散弹攻击"):
		var shotgun_attack = config["散弹攻击"]
		if shotgun_attack.has("散弹数量"):
			shotgun_bullets = shotgun_attack["散弹数量"]
		if shotgun_attack.has("散弹扩散角度"):
			shotgun_spread_angle = shotgun_attack["散弹扩散角度"]
	
	# 多发射击
	if config.has("多发射击"):
		var burst_attack = config["多发射击"]
		if burst_attack.has("多发射击行数"):
			burst_rows = burst_attack["多发射击行数"]
		if burst_attack.has("多发射击列数"):
			burst_cols = burst_attack["多发射击列数"]
		if burst_attack.has("多发射击间距"):
			burst_spacing = burst_attack["多发射击间距"]
	
	# 加特林属性
	if config.has("加特林属性"):
		var gatling_attr = config["加特林属性"]
		if gatling_attr.has("加特林子弹数量"):
			gatling_bullets = gatling_attr["加特林子弹数量"]
		if gatling_attr.has("加特林射击间隔"):
			gatling_interval = gatling_attr["加特林射击间隔"]
		if gatling_attr.has("加特林冷却时间"):
			gatling_cooldown = gatling_attr["加特林冷却时间"]
	
	# 穿透属性
	if config.has("穿透属性"):
		var pierce_attr = config["穿透属性"]
		if pierce_attr.has("穿透数量"):
			pierce_count = pierce_attr["穿透数量"]
	
	# 移动与闪避
	if config.has("移动与闪避"):
		var move_dodge = config["移动与闪避"]
		if move_dodge.has("移动速度"):
			move_speed = move_dodge["移动速度"]
		if move_dodge.has("闪避率"):
			dodge_rate = move_dodge["闪避率"]
		if move_dodge.has("击退力度"):
			knockback_force = move_dodge["击退力度"]
		if move_dodge.has("击退抗性"):
			knockback_resist = move_dodge["击退抗性"]
	
	# 元素属性
	if config.has("元素属性"):
		var element_attr = config["元素属性"]
		if element_attr.has("元素类型"):
			var element_type_str = element_attr["元素类型"]
			match element_type_str:
				"NONE":
					element_type = ElementType.NONE
				"METAL":
					element_type = ElementType.METAL
				"WOOD":
					element_type = ElementType.WOOD
				"WATER":
					element_type = ElementType.WATER
				"FIRE":
					element_type = ElementType.FIRE
				"EARTH":
					element_type = ElementType.EARTH
				"THUNDER":
					element_type = ElementType.THUNDER
		if element_attr.has("元素克制额外伤害"):
			element_damage_bonus = element_attr["元素克制额外伤害"]
	
	# 特殊属性
	if config.has("特殊属性"):
		var special_attr = config["特殊属性"]
		if special_attr.has("控制抗性"):
			control_resist = special_attr["控制抗性"]
		if special_attr.has("伤害反弹"):
			damage_reflect = special_attr["伤害反弹"]
		if special_attr.has("死亡免疫"):
			death_immunity = special_attr["死亡免疫"]
		if special_attr.has("狂暴阈值"):
			berserker_threshold = special_attr["狂暴阈值"]
		if special_attr.has("狂暴状态伤害倍数"):
			berserker_bonus = special_attr["狂暴状态伤害倍数"]
	
	# 特殊机制开关
	if config.has("特殊机制开关"):
		var special_toggle = config["特殊机制开关"]
		if special_toggle.has("启用伤害反弹机制"):
			enable_damage_reflect = special_toggle["启用伤害反弹机制"]
		if special_toggle.has("启用狂暴模式机制"):
			enable_berserker_mode = special_toggle["启用狂暴模式机制"]
		if special_toggle.has("启用死亡免疫机制"):
			enable_death_immunity = special_toggle["启用死亡免疫机制"]
		if special_toggle.has("启用援助召唤机制"):
			enable_aid_system = special_toggle["启用援助召唤机制"]
		if special_toggle.has("启用死亡重生机制"):
			enable_resurrection = special_toggle["启用死亡重生机制"]
	
	# 援助系统
	if config.has("援助系统"):
		var aid_system = config["援助系统"]
		if aid_system.has("援助触发阈值"):
			aid_threshold = aid_system["援助触发阈值"]
		if aid_system.has("援助召唤数量"):
			aid_summon_count = aid_system["援助召唤数量"]
		if aid_system.has("援助召唤间隔"):
			aid_summon_interval = aid_system["援助召唤间隔"]
	
	# 品质系统
	if config.has("品质系统"):
		var quality_system = config["品质系统"]
		if quality_system.has("宠物品质"):
			var quality_str = quality_system["宠物品质"]
			match quality_str:
				"COMMON":
					pet_quality = PetQuality.COMMON
				"UNCOMMON":
					pet_quality = PetQuality.UNCOMMON
				"RARE":
					pet_quality = PetQuality.RARE
				"EPIC":
					pet_quality = PetQuality.EPIC
				"LEGENDARY":
					pet_quality = PetQuality.LEGENDARY
				"MYTHIC":
					pet_quality = PetQuality.MYTHIC



func _ready():
	# 初始化生日
	initialize_birthday()
	
	# 保存原始颜色
	if pet_image:
		original_modulate = pet_image.modulate
	
	# 延迟初始化UI显示，确保所有节点都已准备好
	call_deferred("update_ui")
	
	# 设置初始动画为空闲状态
	if pet_image:
		pet_image.animation = "idle"
	
	# 获取队伍节点引用
	call_deferred("setup_team_references")
	
	# 延迟设置碰撞层，确保队伍信息已设置
	call_deferred("setup_collision_layers")

# 设置宠物类型并加载对应配置
func set_pet_type_and_load_config(pet_type_name: String):
	pet_type = pet_type_name
	load_pet_config_from_json()

# 设置队伍节点引用
func setup_team_references():
	var battle_panel = get_parent()
	while battle_panel and not battle_panel.has_method("get_team_node"):
		battle_panel = battle_panel.get_parent()
	
	if battle_panel:
		team_nodes["team1"] = battle_panel.get_node_or_null("team1")
		team_nodes["team2"] = battle_panel.get_node_or_null("team2")
		team_nodes["neutral"] = battle_panel.get_node_or_null("neutral")

# 设置碰撞层，让队友之间不碰撞
func setup_collision_layers():
	# 简化的碰撞层设计：
	# 第1位（值1）：team1宠物
	# 第2位（值2）：team2宠物  
	# 第3位（值4）：中立宠物
	
	match pet_team:
		"team1":
			collision_layer = 1   # 第1位
			collision_mask = 2    # 只检测team2
		"team2":
			collision_layer = 2   # 第2位
			collision_mask = 1    # 只检测team1
		"neutral":
			collision_layer = 4   # 第3位
			collision_mask = 3    # 检测team1和team2
		_:
			# 默认设置为team1
			collision_layer = 1
			collision_mask = 2

#限制宠物在战斗区域内
func clamp_to_battle_area():
	var battle_area_min = Vector2(0,0)
	var battle_area_max = Vector2(1400, 720)
	
	# 限制位置
	global_position.x = clamp(global_position.x, battle_area_min.x, battle_area_max.x)
	global_position.y = clamp(global_position.y, battle_area_min.y, battle_area_max.y)

#宠物物理更新（带性能保护）
func _physics_process(delta):
	if not is_alive or is_dying:
		return
	
	# 性能保护：每3帧执行一次非关键逻辑
	frame_skip_counter += 1
	var should_skip_frame = performance_mode and (frame_skip_counter % 3 != 0)
	
	# 检测性能问题（如果帧时间过长，自动启用性能模式）
	if delta > 0.025:  # 帧时间超过25ms（低于40FPS）
		if not performance_mode:
			performance_mode = true
			print("⚡ " + pet_name + " 启用性能模式（帧时间: " + str("%.3f" % delta) + "s）")
	
	# 巡逻宠物特殊处理
	if is_patrolling:
		handle_patrol(delta)
		return
	
	# 处理生命和护盾恢复
	if not should_skip_frame:
		handle_regeneration(delta)
	
	# 更新年龄和亲密度（低优先级，可跳帧）
	if not should_skip_frame:
		update_age_and_intimacy(delta)
	
	# 检查狂暴状态
	if not should_skip_frame:
		check_berserker_mode()
	
	# 检查援助系统（低优先级，可跳帧）
	if not should_skip_frame:
		check_aid_system()
	
	# 如果被眩晕则不能行动
	if is_stunned:
		return
		
	# 定期检查目标状态（性能模式下降低检查频率）
	var current_time = Time.get_ticks_msec() / 1000.0
	var check_interval = 0.5 if not performance_mode else 1.0
	if current_time - last_target_check_time >= check_interval:
		check_target_validity()
		last_target_check_time = current_time
	
	# 更新AI状态机
	update_ai_state(delta)
	
	# 处理移动
	handle_movement(delta)
	
	# 处理攻击
	handle_attack(delta)
	
	# 应用移动
	move_and_slide()
	
	# 限制在战斗区域内
	clamp_to_battle_area()

#宠物AI状态机
func update_ai_state(delta):
	match current_state:
		PetState.IDLE:
			# 播放空闲动画
			if pet_image.animation != "idle":
				pet_image.animation = "idle"
			
			# 只有启用战斗时才寻找敌人
			if combat_enabled:
				find_nearest_enemy()
				if current_target and is_instance_valid(current_target):
					current_state = PetState.MOVING_TO_TARGET
		
		PetState.MOVING_TO_TARGET:
			# 播放行走动画
			if pet_image.animation != "walk":
				pet_image.animation = "walk"
			
			if not current_target or not is_instance_valid(current_target):
				current_state = PetState.IDLE
			else:
				var distance_to_target = global_position.distance_to(current_target.global_position)
				if distance_to_target <= attack_range:
					# 进入攻击范围开始攻击
					current_state = PetState.ATTACKING
		
		PetState.ATTACKING:
			# 攻击时播放空闲动画（或者你可以添加攻击动画）
			if pet_image.animation != "idle":
				pet_image.animation = "idle"
			
			if not current_target or not is_instance_valid(current_target):
				current_state = PetState.IDLE
			else:
				var distance_to_target = global_position.distance_to(current_target.global_position)
				if distance_to_target > attack_range * 1.2:
					# 目标超出射程，继续追击
					current_state = PetState.MOVING_TO_TARGET

#宠物移动
func handle_movement(delta):
	if current_state == PetState.MOVING_TO_TARGET and current_target:
		var distance_to_target = global_position.distance_to(current_target.global_position)
		var direction = (current_target.global_position - global_position).normalized()
		
		# 根据攻击类型调整移动策略
		if attack_type == AttackType.MELEE:
			# 近战：直接冲向目标
			velocity = direction * move_speed
		else:
			# 远程：保持适当距离
			var optimal_distance = attack_range * 0.8  # 保持在80%射程距离
			if distance_to_target > optimal_distance:
				# 太远了，靠近一点
				velocity = direction * move_speed
			elif distance_to_target < optimal_distance * 0.6:
				# 太近了，后退一点
				velocity = -direction * move_speed * 0.5
			else:
				# 距离合适，停止移动
				velocity = Vector2.ZERO
		
		# 翻转精灵朝向
		if direction.x < 0:
			pet_image.flip_h = false
			pet_tool_image.flip_h = true
			pet_tool_image.position.x = -10
		elif direction.x > 0:
			pet_image.flip_h = true
			pet_tool_image.flip_h = false
			pet_tool_image.position.x = 10
	else:
		velocity = Vector2.ZERO

#宠物攻击（带频率保护）
func handle_attack(delta):
	if current_state == PetState.ATTACKING and current_target:
		var current_time = Time.get_ticks_msec() / 1000.0  # 转换为秒
		
		# 处理加特林连射
		if ranged_mode == RangedAttackMode.GATLING:
			handle_gatling_attack(current_time, delta)
		else:
			# 普通攻击频率控制（确保最小攻击间隔）
			var attack_interval = max(1.0 / attack_speed, min_attack_interval)
			if current_time - last_attack_time >= attack_interval:
				perform_attack(current_target)
				last_attack_time = current_time

# 处理加特林攻击
func handle_gatling_attack(current_time: float, delta: float):
	if gatling_firing:
		# 正在连射
		if current_time - gatling_last_shot >= gatling_interval:
			fire_projectile_by_mode(current_target)
			gatling_current_bullet += 1
			gatling_last_shot = current_time
			
			if gatling_current_bullet >= gatling_bullets:
				# 连射完毕，进入冷却
				gatling_firing = false
				gatling_current_bullet = 0
				last_attack_time = current_time + gatling_cooldown
				print(pet_name + " 加特林连射完毕，进入冷却")
	else:
		# 检查是否可以开始新的连射
		if current_time - last_attack_time >= 1.0 / attack_speed:
			gatling_firing = true
			gatling_current_bullet = 0
			gatling_last_shot = current_time - gatling_interval  # 立即开始第一发
			print(pet_name + " 开始加特林连射!")

#寻找最近的敌人
func find_nearest_enemy():
	var nearest_enemy: CharacterBody2D = null
	var nearest_distance: float = INF
	
	# 获取所有存活的敌方宠物
	var all_enemies: Array[CharacterBody2D] = []
	
	# 直接从pets组中查找敌人（更可靠的方法）
	var all_pets = get_tree().get_nodes_in_group("pets")
	for pet in all_pets:
		if not is_instance_valid(pet) or pet == self or not pet.is_alive:
			continue
		
		# 检查是否为敌人
		if pet.has_method("get_team") and pet.get_team() != pet_team:
			all_enemies.append(pet)
	
	# 如果没有敌人，清除目标
	if all_enemies.is_empty():
		if current_target:
			current_target = null
		return
	
	# 寻找最近的敌人
	for enemy in all_enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	# 更新目标（只有在没有目标或目标已死亡时才更换）
	if not current_target or not is_instance_valid(current_target) or not current_target.is_alive:
		if nearest_enemy != current_target:
			current_target = nearest_enemy

# 检查目标有效性
func check_target_validity():
	if current_target:
		# 检查目标是否还存活且有效
		if not is_instance_valid(current_target) or not current_target.is_alive:
			current_target = null
			current_state = PetState.IDLE
		# 检查目标是否还是敌人（防止队伍变更等情况）
		elif current_target.get_team() == pet_team:
			current_target = null
			current_state = PetState.IDLE

#宠物攻击
func perform_attack(target: CharacterBody2D):
	if not target or not is_instance_valid(target) or not target.is_alive:
		# 目标无效或已死亡，重新寻找目标
		current_target = null
		current_state = PetState.IDLE
		return
	
	# 根据攻击类型执行不同的攻击方式
	if attack_type == AttackType.MELEE:
		perform_melee_attack(target)
	else:
		fire_projectile_by_mode(target)

# 执行近战攻击
func perform_melee_attack(target: CharacterBody2D):
	# 计算基础伤害 + 近战额外伤害
	var damage = attack_damage + melee_damage_bonus
	
	# 狂暴状态加成
	if is_berserker:
		damage *= berserker_bonus
	
	# 护甲穿透计算
	var final_armor_penetration = armor_penetration
	
	# 暴击计算
	var is_critical = randf() < crit_rate
	if is_critical:
		damage *= crit_damage
	
	# 添加战斗细节
	add_battle_detail_to_panel("⚔️ " + pet_name + " 对 " + target.pet_name + " 造成近战攻击 " + str(int(damage)) + " 点伤害" + ("（暴击）" if is_critical else ""))
	
	# 对目标造成伤害
	target.take_damage(damage, final_armor_penetration, element_type, self)
	
	# 生命汲取
	if life_steal > 0:
		var heal_amount = damage * life_steal
		heal(heal_amount)
	
	# 击退效果已禁用
	# if knockback_force > 0:
	#	apply_knockback_to_target(target)

# 根据攻击模式发射子弹
func fire_projectile_by_mode(target: CharacterBody2D):
	# 计算基础伤害 + 远程额外伤害
	var damage = attack_damage + ranged_damage_bonus
	
	# 狂暴状态加成
	if is_berserker:
		damage *= berserker_bonus
	
	# 护甲穿透计算
	var final_armor_penetration = armor_penetration
	
	# 暴击计算
	var is_critical = randf() < crit_rate
	if is_critical:
		damage *= crit_damage
	
	# 根据远程攻击模式执行不同的射击方式
	match ranged_mode:
		RangedAttackMode.SINGLE:
			fire_single_projectile(target, damage, final_armor_penetration, is_critical)
		RangedAttackMode.SHOTGUN:
			fire_shotgun_projectiles(target, damage, final_armor_penetration, is_critical)
		RangedAttackMode.BURST:
			fire_burst_projectiles(target, damage, final_armor_penetration, is_critical)
		RangedAttackMode.GATLING:
			fire_single_projectile(target, damage, final_armor_penetration, is_critical)  # 加特林也是单发，但频率高
		RangedAttackMode.PIERCING:
			fire_piercing_projectile(target, damage, final_armor_penetration, is_critical)

# 发射单发子弹
func fire_single_projectile(target: CharacterBody2D, damage: float, armor_pen: float, is_critical: bool):
	add_battle_detail_to_panel("🏹 " + pet_name + " 向 " + target.pet_name + " 发射单发子弹 " + str(int(damage)) + " 点伤害" + ("（暴击）" if is_critical else ""))
	create_and_fire_projectile(global_position, target.global_position, damage, armor_pen, is_critical, 1)

# 发射散弹
func fire_shotgun_projectiles(target: CharacterBody2D, damage: float, armor_pen: float, is_critical: bool):
	var base_direction = (target.global_position - global_position).normalized()
	var base_angle = atan2(base_direction.y, base_direction.x)
	
	# 计算每发子弹的角度偏移
	var angle_step = deg_to_rad(shotgun_spread_angle) / (shotgun_bullets - 1)
	var start_angle = base_angle - deg_to_rad(shotgun_spread_angle) / 2
	
	for i in range(shotgun_bullets):
		var bullet_angle = start_angle + i * angle_step
		var bullet_direction = Vector2(cos(bullet_angle), sin(bullet_angle))
		var target_pos = global_position + bullet_direction * attack_range
		
		create_and_fire_projectile(global_position, target_pos, damage * 0.7, armor_pen, is_critical, 1)  # 散弹伤害降低

# 发射多发射击（平行）
func fire_burst_projectiles(target: CharacterBody2D, damage: float, armor_pen: float, is_critical: bool):
	var base_direction = (target.global_position - global_position).normalized()
	var perpendicular = Vector2(-base_direction.y, base_direction.x)  # 垂直方向
	
	# 计算起始位置偏移
	var total_width = (burst_cols - 1) * burst_spacing
	var total_height = (burst_rows - 1) * burst_spacing
	
	for row in range(burst_rows):
		for col in range(burst_cols):
			var offset_x = (col - (burst_cols - 1) * 0.5) * burst_spacing
			var offset_y = (row - (burst_rows - 1) * 0.5) * burst_spacing
			
			var start_pos = global_position + perpendicular * offset_x + base_direction.rotated(PI/2) * offset_y
			var target_pos = target.global_position + perpendicular * offset_x + base_direction.rotated(PI/2) * offset_y
			
			create_and_fire_projectile(start_pos, target_pos, damage * 0.8, armor_pen, is_critical, 1)  # 多发伤害稍微降低

# 发射穿透子弹
func fire_piercing_projectile(target: CharacterBody2D, damage: float, armor_pen: float, is_critical: bool):
	create_and_fire_projectile(global_position, target.global_position, damage * 1.2, armor_pen, is_critical, pierce_count)  # 穿透子弹伤害更高

# 创建并发射子弹的通用函数
func create_and_fire_projectile(start_pos: Vector2, target_pos: Vector2, damage: float, armor_pen: float, is_critical: bool, pierce: int = 1):
	# 直接创建新子弹
	if not projectile_scene:
		print("错误：没有设置子弹场景!")
		return
	
	var projectile: Area2D = projectile_scene.instantiate()
	if not projectile:
		print("错误：无法创建子弹实例")
		return
	
	# 将子弹添加到战斗场景中
	if get_tree():
		var battle_scene = get_tree().current_scene
		if battle_scene.has_node("PetFightPanel"):
			battle_scene.get_node("PetFightPanel").add_child(projectile)
		else:
			get_tree().current_scene.add_child(projectile)
	else:
		# 如果场景树不存在，直接销毁子弹
		projectile.queue_free()
		return
	
	# 设置子弹位置
	projectile.global_position = start_pos
	
	# 计算射击方向
	var direction = (target_pos - start_pos).normalized()
	
	# 设置子弹数据
	projectile.set_projectile_data(damage, projectile_speed, direction, pet_team, element_type, armor_pen, pierce, self)
	
	# 设置子弹颜色
	if projectile.has_node("ProjectileSprite"):
		if is_critical:
			projectile.get_node("ProjectileSprite").modulate = Color.RED  # 暴击红色
		elif pierce > 1:
			projectile.get_node("ProjectileSprite").modulate = Color.PURPLE  # 穿透紫色
		else:
			# 根据攻击模式设置不同颜色
			match ranged_mode:
				RangedAttackMode.SINGLE:
					projectile.get_node("ProjectileSprite").modulate = Color.YELLOW
				RangedAttackMode.SHOTGUN:
					projectile.get_node("ProjectileSprite").modulate = Color.ORANGE
				RangedAttackMode.BURST:
					projectile.get_node("ProjectileSprite").modulate = Color.CYAN
				RangedAttackMode.GATLING:
					projectile.get_node("ProjectileSprite").modulate = Color.GREEN
				RangedAttackMode.PIERCING:
					projectile.get_node("ProjectileSprite").modulate = Color.PURPLE

#宠物受到伤害（带死循环保护）
func take_damage(damage: float, armor_pen: float = 0.0, attacker_element: ElementType = ElementType.NONE, attacker: CharacterBody2D = null):
	if not is_alive or is_invulnerable:
		return
	
	# 防止过于频繁的伤害处理（性能保护）
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < 0.05:  # 50ms最小伤害间隔
		return
	
	# 增加伤害反弹递归深度
	damage_reflect_depth += 1
	
	# 递归深度保护（防止无限反弹）
	if damage_reflect_depth > max_reflect_depth:
		damage_reflect_depth = max(0, damage_reflect_depth - 1)
		return
	
	# 闪避检测
	if randf() < dodge_rate:
		if attacker and is_instance_valid(attacker):
			add_battle_detail_to_panel("✨ " + pet_name + " 闪避了 " + attacker.pet_name + " 的攻击！", Color.CYAN)
		damage_reflect_depth = max(0, damage_reflect_depth - 1)
		return
	
	var actual_damage = damage
	
	# 元素克制计算 - 额外伤害
	var element_extra_damage = get_element_multiplier(attacker_element, element_type)
	actual_damage += element_extra_damage
	
	# 护甲减伤计算（考虑护甲穿透）
	var effective_armor = max(0, current_armor - armor_pen)
	if effective_armor > 0:
		var armor_reduction = effective_armor / (effective_armor + 100.0)
		actual_damage = actual_damage * (1.0 - armor_reduction)
	
	# 先扣护盾
	if current_shield > 0:
		var shield_damage = min(actual_damage, current_shield)
		current_shield -= shield_damage
		actual_damage -= shield_damage
	
	# 再扣血量
	if actual_damage > 0:
		current_health -= actual_damage
	
	# 播放受伤动画（带冷却保护）
	play_hurt_animation()
	
	# 添加受伤细节（性能模式下减少文本输出）
	if not performance_mode and attacker and is_instance_valid(attacker):
		var damage_text = "💔 " + pet_name + " 受到 " + str(int(actual_damage)) + " 点伤害"
		if element_extra_damage > 0:
			damage_text += " （元素克制 +" + str(int(element_extra_damage)) + "）"
		add_battle_detail_to_panel(damage_text, Color.ORANGE)
	
	# 记录最后攻击者
	if attacker and is_instance_valid(attacker):
		last_attacker = attacker
	
	# 反击机制：立即将攻击者设为目标（只有启用战斗时才反击）
	# 添加反击冷却，防止过于频繁的目标切换
	if combat_enabled and attacker and is_instance_valid(attacker) and attacker.is_alive:
		if attacker.get_team() != pet_team:  # 确保不攻击队友
			# 只有当前没有目标或当前目标已死亡时才切换目标
			if not current_target or not is_instance_valid(current_target) or not current_target.is_alive:
				current_target = attacker
				current_state = PetState.MOVING_TO_TARGET
	
	# 伤害反弹（带递归深度保护）
	if enable_damage_reflect and damage_reflect > 0.0 and attacker and is_instance_valid(attacker) and damage_reflect_depth <= max_reflect_depth:
		var reflect_damage = damage * damage_reflect * 0.5  # 反弹伤害减半，防止无限递归
		# 延迟反弹，避免同帧内的递归调用
		call_deferred("apply_reflect_damage", attacker, reflect_damage)
	
	# 检查死亡
	if current_health <= 0:
		if enable_death_immunity and death_immunity:
			current_health = 1.0
			death_immunity = false
			is_invulnerable = true
			# 设置短暂无敌时间
			if get_tree():
				var timer = get_tree().create_timer(2.0)
				timer.timeout.connect(func(): is_invulnerable = false)
		else:
			if not is_dying:  # 防止重复调用die()
				call_deferred("die")
	
	# 减少伤害反弹递归深度
	damage_reflect_depth = max(0, damage_reflect_depth - 1)
	
	# 更新UI
	call_deferred("update_ui")

# 延迟应用反弹伤害（防止递归调用）
func apply_reflect_damage(target: CharacterBody2D, reflect_damage: float):
	if target and is_instance_valid(target) and target.is_alive:
		target.take_damage(reflect_damage, 0.0, element_type, self)

#宠物死亡
func die():
	if is_dying:  # 如果已经在死亡过程中，直接返回
		return
	
	# 检查重生机制
	if enable_resurrection and not resurrection_used:
		resurrection_used = true
		add_battle_detail_to_panel("💀 " + pet_name + " 死亡，但触发重生机制！", Color.GOLD)
		resurrect()
		return
	
	is_dying = true  # 设置死亡标志
	is_alive = false
	current_state = PetState.DEAD
	
	# 添加死亡细节
	var death_message = "💀 " + pet_name + " 死亡了！"
	if last_attacker and is_instance_valid(last_attacker):
		death_message += " （被 " + last_attacker.pet_name + " 击杀）"
	add_battle_detail_to_panel(death_message, Color.RED)
	
	# 给击杀者奖励
	if last_attacker and is_instance_valid(last_attacker) and last_attacker.has_method("on_kill_enemy"):
		last_attacker.on_kill_enemy(self)
	
	# 通知其他宠物这个目标已死亡，让它们重新寻找目标
	if get_tree():  # 确保场景树存在
		var all_pets = get_tree().get_nodes_in_group("pets")
		for pet in all_pets:
			if pet != self and is_instance_valid(pet) and pet.has_method("on_enemy_died"):
				pet.on_enemy_died(self)
	
	# 立即通知战斗面板检查战斗结束
	var battle_panel = get_parent()
	while battle_panel and not battle_panel.has_method("check_battle_end"):
		battle_panel = battle_panel.get_parent()
	
	if battle_panel:
		battle_panel.call_deferred("check_battle_end")
	
	# 延迟0.5秒后移除自己，避免在物理回调中操作
	if get_tree():
		await get_tree().create_timer(0.5).timeout
		if get_parent():
			get_parent().remove_child(self)
		queue_free()
	else:
		# 如果场景树不存在，直接销毁
		queue_free()

# 重生机制
func resurrect():
	# 恢复生命值到50%
	current_health = max_health * 0.5
	current_shield = max_shield * 0.5
	current_armor = max_armor * 0.5
	
	# 设置短暂无敌状态
	is_invulnerable = true
	is_dying = false
	is_alive = true
	current_state = PetState.IDLE
	
	# 清除目标，重新开始
	current_target = null
	
	# 重生特效（变为金色闪烁）
	var original_modulate = pet_image.modulate
	pet_image.modulate = Color.GOLD
	
	# 3秒后恢复正常状态
	if get_tree():
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): 
			is_invulnerable = false
			pet_image.modulate = original_modulate
		)
	
	call_deferred("update_ui")

# 显示启用的特殊机制
func show_enabled_special_abilities():
	var abilities: Array[String] = []
	
	if enable_damage_reflect:
		abilities.append("伤害反弹(" + str(int(damage_reflect * 100)) + "%)")
	if enable_berserker_mode:
		abilities.append("狂暴模式(" + str(int(berserker_threshold * 100)) + "%血量触发)")
	if enable_death_immunity:
		abilities.append("死亡免疫")
	if enable_aid_system:
		abilities.append("援助召唤(x" + str(aid_summon_count) + ")")
	if enable_resurrection:
		abilities.append("死亡重生")
	
	# 可以在这里添加UI显示特殊能力的逻辑，暂时注释掉print
	# if abilities.size() > 0:
	#	print(pet_name + " 启用特殊机制: " + ", ".join(abilities))
	# else:
	#	print(pet_name + " 无特殊机制")
	
#更新宠物状态UI
func update_ui():
	# 检查UI节点是否存在，防止援助宠物或未完全初始化的宠物出错
	if not health_bar or not shield_bar or not armor_bar or not health_label or not shield_label or not armor_label or not pet_name_rich_text:
		return
	
	# 更新血量条
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "生命值:" + str(int(current_health)) + "/" + str(int(max_health))
	
	# 更新护盾条
	shield_bar.max_value = max_shield
	shield_bar.value = current_shield
	shield_label.text = "护盾值:" + str(int(current_shield)) + "/" + str(int(max_shield))
	
	# 更新护甲条
	armor_bar.max_value = max_armor
	armor_bar.value = current_armor
	armor_label.text = "护甲值:" + str(int(current_armor)) + "/" + str(int(max_armor))
	
	# 更新名称（包含等级、经验、亲密度信息）
	var display_name = pet_name + " [Lv." + str(pet_level) + "]"
	display_name += "\n经验:" + str(int(pet_experience)) + "/" + str(int(max_experience))
	display_name += "\n亲密度:" + str(int(pet_intimacy)) + "/" + str(int(max_intimacy))
	if pet_age > 0:
		display_name += "\n年龄:" + get_age_display()
	pet_name_rich_text.text = display_name

# 获取友好的年龄显示
func get_age_display() -> String:
	if pet_age == 0:
		return "新生"
	elif pet_age < 7:
		return str(pet_age) + "天"
	elif pet_age < 30:
		var weeks = pet_age / 7
		return str(weeks) + "周"
	elif pet_age < 365:
		var months = pet_age / 30
		return str(months) + "个月"
	else:
		var years = pet_age / 365
		var remaining_days = pet_age % 365
		if remaining_days > 0:
			return str(years) + "年" + str(remaining_days) + "天"
		else:
			return str(years) + "年"

# 添加战斗细节到对战面板
func add_battle_detail_to_panel(text: String, color: Color = Color.WHITE):
	# 查找战斗面板
	var battle_panel = find_battle_panel()
	if battle_panel and battle_panel.has_method("add_battle_detail"):
		battle_panel.add_battle_detail(text, color)

# 查找战斗面板
func find_battle_panel():
	var current_scene = get_tree().current_scene
	if current_scene.has_node("PetFightPanel"):
		return current_scene.get_node("PetFightPanel")
	else:
		# 遍历所有子节点查找
		var queue = [current_scene]
		while queue.size() > 0:
			var node = queue.pop_front()
			if node.name == "PetFightPanel":
				return node
			for child in node.get_children():
				queue.append(child)
	return null

#设置宠物数据
func set_pet_data(name: String, team: String, health: float = 100.0, attack: float = 20.0, speed: float = 100.0, quality: PetQuality = PetQuality.COMMON, element: ElementType = ElementType.NONE):
	pet_name = name
	pet_team = team
	max_health = health
	current_health = health
	attack_damage = attack
	move_speed = speed
	pet_quality = quality
	element_type = element
	
	# 根据品质调整属性
	apply_quality_bonuses()
	
	# 更新攻击速度
	update_attack_speed()
	
	# 设置碰撞层（现在team信息已确定）
	setup_collision_layers()
	
	# 显示启用的特殊机制
	call_deferred("show_enabled_special_abilities")
	
	call_deferred("update_ui")

# 更新攻击速度（根据当前攻击类型）
func update_attack_speed():
	if attack_type == AttackType.MELEE:
		attack_speed = melee_attack_speed
	else:
		attack_speed = ranged_attack_speed

# 根据品质应用属性加成
func apply_quality_bonuses():
	var quality_multiplier = 1.0
	match pet_quality:
		PetQuality.COMMON:
			quality_multiplier = 1.0
		PetQuality.UNCOMMON:
			quality_multiplier = 1.1
		PetQuality.RARE:
			quality_multiplier = 1.25
		PetQuality.EPIC:
			quality_multiplier = 1.5
		PetQuality.LEGENDARY:
			quality_multiplier = 1.75
		PetQuality.MYTHIC:
			quality_multiplier = 2.0
	
	# 应用品质加成到基础属性
	max_health *= quality_multiplier
	current_health = max_health
	max_shield *= quality_multiplier
	current_shield = max_shield
	max_armor *= quality_multiplier
	current_armor = max_armor
	attack_damage *= quality_multiplier
	
	# 高品质宠物获得额外属性
	if pet_quality >= PetQuality.RARE:
		crit_rate += 0.05
		life_steal += 0.05
		enable_berserker_mode = true  # 稀有品质启用狂暴模式
	if pet_quality >= PetQuality.EPIC:
		armor_penetration += 10.0
		health_regen += 1.0
		enable_damage_reflect = true  # 史诗品质启用伤害反弹
		damage_reflect += 0.1
	if pet_quality >= PetQuality.LEGENDARY:
		knockback_resist += 0.2
		enable_aid_system = true  # 传说品质启用援助系统
		enable_death_immunity = true  # 传说品质启用死亡免疫
		death_immunity = true
	if pet_quality >= PetQuality.MYTHIC:
		berserker_bonus += 0.5
		enable_resurrection = true  # 神话品质启用重生机制

func get_team() -> String:
	return pet_team

# 获取攻击类型（调试用）
func get_attack_type() -> AttackType:
	return attack_type

# 处理生命和护盾恢复
func handle_regeneration(delta: float):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_regen_time >= 1.0:  # 每秒恢复一次
		# 生命恢复
		if current_health < max_health and health_regen > 0:
			current_health = min(max_health, current_health + health_regen)
		
		# 护盾恢复
		if current_shield < max_shield and shield_regen > 0:
			current_shield = min(max_shield, current_shield + shield_regen)
		
		last_regen_time = current_time
		call_deferred("update_ui")

# 更新亲密度
var intimacy_timer: float = 0.0

func update_age_and_intimacy(delta: float):
	# 更新年龄（基于出生日期和现实时间）
	update_pet_age()
	
	# 每10秒增加1点亲密度（战斗中会增加更多）
	intimacy_timer += delta
	if intimacy_timer >= 10.0:
		gain_intimacy(1.0)
		intimacy_timer = 0.0

# 根据出生日期计算宠物年龄
func update_pet_age():
	if pet_birthday == "":
		return
	
	# 解析出生日期
	var birth_parts = pet_birthday.split(" ")
	if birth_parts.size() != 2:
		return
	
	var date_parts = birth_parts[0].split("-")
	var time_parts = birth_parts[1].split(":")
	
	if date_parts.size() != 3 or time_parts.size() != 3:
		return
	
	# 获取当前时间
	var current_time = Time.get_datetime_dict_from_system()
	
	# 计算出生时间
	var birth_year = int(date_parts[0])
	var birth_month = int(date_parts[1])
	var birth_day = int(date_parts[2])
	var birth_hour = int(time_parts[0])
	var birth_minute = int(time_parts[1])
	var birth_second = int(time_parts[2])
	
	# 创建出生时间的Unix时间戳
	var birth_dict = {
		"year": birth_year,
		"month": birth_month,
		"day": birth_day,
		"hour": birth_hour,
		"minute": birth_minute,
		"second": birth_second
	}
	
	var birth_unix = Time.get_unix_time_from_datetime_dict(birth_dict)
	var current_unix = Time.get_unix_time_from_system()
	
	# 计算年龄（秒差转换为天数）
	var age_seconds = current_unix - birth_unix
	pet_age = int(age_seconds / 86400)  # 86400秒 = 1天
	
	if pet_age < 0:
		pet_age = 0  # 防止负数年龄

# 增加亲密度
func gain_intimacy(amount: float):
	if pet_intimacy < max_intimacy:
		pet_intimacy = min(max_intimacy, pet_intimacy + amount)
		
		# 每100点亲密度提供属性加成
		var intimacy_level = int(pet_intimacy / 100.0)
		if intimacy_level > 0:
			# 亲密度加成：每100点提供5%属性加成
			var intimacy_bonus = 1.0 + (intimacy_level * 0.05)
			# 这里可以应用到各种属性上，暂时先输出提示
			if int(pet_intimacy) % 100 == 0:
				pass

# 增加经验值
func gain_experience(amount: float):
	if pet_level >= 50:  # 等级上限
		return
	
	pet_experience += amount
	
	# 检查是否升级
	while pet_experience >= max_experience and pet_level < 50:
		level_up()

# 升级（新的随机属性系统）
func level_up():
	pet_experience -= max_experience
	pet_level += 1
	
	# 计算新的升级经验需求（指数增长）
	max_experience = 100.0 * pow(1.2, pet_level - 1)
	
	# 随机选择属性进行升级
	var upgraded_attributes = apply_random_attribute_upgrade()
	
	# 检查是否有里程碑奖励（每5级）
	var milestone_rewards = apply_milestone_bonus()
	
	# 升级回血和护盾护甲
	current_health = max_health
	current_shield = max_shield
	current_armor = max_armor
	
	# 升级特效
	show_level_up_effect()
	
	# 添加升级细节
	var upgrade_text = "🎉 " + pet_name + " 升级到 " + str(pet_level) + " 级！"
	upgrade_text += "\n📈 随机提升：" + ", ".join(upgraded_attributes)
	if milestone_rewards.size() > 0:
		upgrade_text += "\n🏆 里程碑奖励：" + ", ".join(milestone_rewards)
	
	add_battle_detail_to_panel(upgrade_text, Color.GOLD)
	
	call_deferred("update_ui")

# 应用随机属性升级
func apply_random_attribute_upgrade() -> Array[String]:
	var upgraded_attributes: Array[String] = []
	var available_attributes = base_upgrade_attributes.duplicate()
	
	# 随机选择几个属性进行升级
	for i in range(min(attributes_per_level, available_attributes.size())):
		var random_index = randi() % available_attributes.size()
		var selected_attribute = available_attributes[random_index]
		available_attributes.remove_at(random_index)
		
		# 应用属性升级
		var upgrade_applied = apply_single_attribute_upgrade(selected_attribute)
		if upgrade_applied:
			upgraded_attributes.append(upgrade_applied)
	
	return upgraded_attributes

# 应用单个属性升级
func apply_single_attribute_upgrade(attribute_name: String) -> String:
	match attribute_name:
		"max_health":
			var bonus = randf_range(8.0, 15.0)  # 随机8-15点生命值
			max_health += bonus
			return "生命值 +" + str(int(bonus))
		"attack_damage":
			var bonus = randf_range(2.0, 5.0)  # 随机2-5点攻击力
			attack_damage += bonus
			return "攻击力 +" + str(int(bonus))
		"move_speed":
			var bonus = randf_range(3.0, 8.0)  # 随机3-8点移动速度
			move_speed += bonus
			return "移动速度 +" + str(int(bonus))
		"max_shield":
			var bonus = randf_range(5.0, 12.0)  # 随机5-12点护盾值
			max_shield += bonus
			return "护盾值 +" + str(int(bonus))
		"max_armor":
			var bonus = randf_range(4.0, 10.0)  # 随机4-10点护甲值
			max_armor += bonus
			return "护甲值 +" + str(int(bonus))
		"crit_rate":
			var bonus = randf_range(0.01, 0.03)  # 随机1-3%暴击率
			crit_rate = min(1.0, crit_rate + bonus)  # 暴击率上限100%
			return "暴击率 +" + str(int(bonus * 100)) + "%"
		"health_regen":
			var bonus = randf_range(0.3, 0.8)  # 随机0.3-0.8点生命恢复
			health_regen += bonus
			return "生命恢复 +" + str("%.1f" % bonus)
		"attack_range":
			var bonus = randf_range(8.0, 20.0)  # 随机8-20点攻击距离
			attack_range += bonus
			return "攻击距离 +" + str(int(bonus))
		_:
			return ""

# 应用里程碑奖励
func apply_milestone_bonus() -> Array[String]:
	var milestone_rewards: Array[String] = []
	
	if not level_milestone_bonuses.has(pet_level):
		return milestone_rewards
	
	var bonuses = level_milestone_bonuses[pet_level]
	
	for bonus_key in bonuses.keys():
		var bonus_value = bonuses[bonus_key]
		var reward_text = apply_milestone_bonus_single(bonus_key, bonus_value)
		if reward_text != "":
			milestone_rewards.append(reward_text)
	
	return milestone_rewards

# 应用单个里程碑奖励
func apply_milestone_bonus_single(bonus_key: String, bonus_value) -> String:
	match bonus_key:
		"max_health":
			max_health += bonus_value
			return "生命值 +" + str(bonus_value)
		"attack_damage":
			attack_damage += bonus_value
			return "攻击力 +" + str(bonus_value)
		"max_shield":
			max_shield += bonus_value
			return "护盾值 +" + str(bonus_value)
		"max_armor":
			max_armor += bonus_value
			return "护甲值 +" + str(bonus_value)
		"crit_rate":
			crit_rate = min(1.0, crit_rate + bonus_value)
			return "暴击率 +" + str(int(bonus_value * 100)) + "%"
		"armor_penetration":
			armor_penetration += bonus_value
			return "护甲穿透 +" + str(bonus_value)
		"life_steal":
			life_steal = min(1.0, life_steal + bonus_value)
			return "生命汲取 +" + str(int(bonus_value * 100)) + "%"
		"knockback_resist":
			knockback_resist = min(1.0, knockback_resist + bonus_value)
			return "击退抗性 +" + str(int(bonus_value * 100)) + "%"
		"dodge_rate":
			dodge_rate = min(1.0, dodge_rate + bonus_value)
			return "闪避率 +" + str(int(bonus_value * 100)) + "%"
		"health_regen":
			health_regen += bonus_value
			return "生命恢复 +" + str(bonus_value)
		"move_speed":
			move_speed += bonus_value
			return "移动速度 +" + str(bonus_value)
		"attack_range":
			attack_range += bonus_value
			return "攻击距离 +" + str(bonus_value)
		"shield_regen":
			shield_regen += bonus_value
			return "护盾恢复 +" + str(bonus_value)
		"crit_damage":
			crit_damage += bonus_value
			return "暴击伤害 +" + str(int(bonus_value * 100)) + "%"
		"berserker_bonus":
			berserker_bonus += bonus_value
			return "狂暴加成 +" + str(int(bonus_value * 100)) + "%"
		"damage_reflect":
			damage_reflect = min(1.0, damage_reflect + bonus_value)
			return "伤害反弹 +" + str(int(bonus_value * 100)) + "%"
		"control_resist":
			control_resist = min(1.0, control_resist + bonus_value)
			return "控制抗性 +" + str(int(bonus_value * 100)) + "%"
		"projectile_speed":
			projectile_speed += bonus_value
			return "子弹速度 +" + str(bonus_value)
		"pierce_count":
			pierce_count += bonus_value
			return "穿透数量 +" + str(bonus_value)
		"enable_berserker_mode":
			if bonus_value:
				enable_berserker_mode = true
				return "解锁狂暴模式"
			else:
				return ""
		"enable_damage_reflect":
			if bonus_value:
				enable_damage_reflect = true
				return "解锁伤害反弹"
			else:
				return ""
		"enable_aid_system":
			if bonus_value:
				enable_aid_system = true
				return "解锁援助召唤"
			else:
				return ""
		"enable_death_immunity":
			if bonus_value:
				enable_death_immunity = true
				death_immunity = true
				return "解锁死亡免疫"
			else:
				return ""
		"enable_resurrection":
			if bonus_value:
				enable_resurrection = true
				return "解锁死亡重生"
			else:
				return ""
		_:
			return ""

# 显示升级特效
func show_level_up_effect():
	if not pet_image:
		return
	
	# 保存原始颜色
	var original_color = pet_image.modulate
	
	# 创建升级特效（金色闪烁）
	var tween = create_tween()
	tween.set_loops(3)  # 闪烁3次
	
	# 闪烁效果
	tween.tween_method(func(color): pet_image.modulate = color, original_color, Color.GOLD, 0.2)
	tween.tween_method(func(color): pet_image.modulate = color, Color.GOLD, original_color, 0.2)
	
	# 恢复原始颜色
	tween.tween_callback(func(): pet_image.modulate = original_color)

# 击杀敌人时获得额外经验
func on_kill_enemy(enemy: CharacterBody2D):
	var kill_exp = enemy.pet_level * 20.0  # 根据敌人等级获得经验
	gain_experience(kill_exp)
	gain_intimacy(10.0)  # 击杀获得更多亲密度

# 初始化生日
func initialize_birthday():
	if pet_birthday == "":
		var time_dict = Time.get_datetime_dict_from_system()
		pet_birthday = str(time_dict.year) + "-" + str(time_dict.month).pad_zeros(2) + "-" + str(time_dict.day).pad_zeros(2) + " " + str(time_dict.hour).pad_zeros(2) + ":" + str(time_dict.minute).pad_zeros(2) + ":" + str(time_dict.second).pad_zeros(2)

# 检查狂暴模式
func check_berserker_mode():
	if not enable_berserker_mode:
		return
		
	var health_ratio = current_health / max_health
	if health_ratio <= berserker_threshold and not is_berserker:
		is_berserker = true
		pet_image.modulate = Color.RED  # 狂暴状态变红色
		add_battle_detail_to_panel("🔥 " + pet_name + " 血量过低，进入狂暴模式！", Color.RED)
	elif health_ratio > berserker_threshold and is_berserker:
		is_berserker = false
		add_battle_detail_to_panel("😌 " + pet_name + " 脱离狂暴模式", Color.GREEN)
		# 恢复原来的队伍颜色
		if pet_team == "team1":
			pet_image.modulate = Color.CYAN
		else:
			pet_image.modulate = Color.ORANGE

# 检查援助系统
func check_aid_system():
	if not enable_aid_system:
		return
		
	var health_ratio = current_health / max_health
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 如果血量低于阈值且还没召唤过援助，或者距离上次召唤已经超过间隔时间
	if health_ratio <= aid_threshold:
		if not aid_summoned or (current_time - aid_last_summon_time >= aid_summon_interval):
			summon_aid()
			aid_last_summon_time = current_time
			aid_summoned = true

# 召唤援助
func summon_aid():
	# 获取战斗面板引用
	var battle_panel = get_parent()
	while battle_panel and not battle_panel.has_method("get_team_node"):
		battle_panel = battle_panel.get_parent()
	
	if not battle_panel:
		return
	
	var team_node = battle_panel.get_team_node(pet_team)
	if not team_node:
		return
	
	# 召唤多个援助宠物
	for i in range(aid_summon_count):
		var aid_pet = create_aid_minion()
		if aid_pet:
			team_node.add_child(aid_pet)
			aid_minions.append(aid_pet)
			
			# 设置援助宠物位置（在主宠物周围）
			var offset_angle = (PI * 2 / aid_summon_count) * i
			var offset_distance = 80.0
			var offset = Vector2(cos(offset_angle), sin(offset_angle)) * offset_distance
			aid_pet.global_position = global_position + offset
			
			# 添加到宠物组
			aid_pet.add_to_group("pets")
			aid_pet.add_to_group(pet_team)
			aid_pet.add_to_group("aid_minions")

# 创建援助宠物
func create_aid_minion() -> CharacterBody2D:
	# 使用相同的宠物场景
	var pet_scene = preload("res://Scene/Pet/PetBase.tscn")
	var aid_pet = pet_scene.instantiate()
	
	# 设置援助宠物属性（比主宠物弱一些）
	var aid_name = pet_name + "的援助"
	var aid_health = max_health * 0.3  # 30%血量
	var aid_attack = attack_damage * 0.5  # 50%攻击力
	var aid_speed = move_speed * 1.2  # 120%移动速度
	
	aid_pet.set_pet_data(aid_name, pet_team, aid_health, aid_attack, aid_speed, PetQuality.COMMON, element_type)
	
	# 援助宠物使用简单的远程攻击
	aid_pet.attack_type = AttackType.RANGED
	aid_pet.ranged_mode = RangedAttackMode.SINGLE
	aid_pet.attack_range = 250.0
	
	# 设置援助宠物的特殊标识（小一点，颜色稍微不同）
	aid_pet.scale = Vector2(0.7, 0.7)  # 缩小到70%
	if aid_pet.pet_image:
		aid_pet.pet_image.modulate = aid_pet.pet_image.modulate * Color(1.0, 1.0, 1.0, 0.8)  # 半透明
	
	# 隐藏援助宠物的UI面板，减少性能开销
	if aid_pet.has_node("PetInformVBox"):
		aid_pet.get_node("PetInformVBox").visible = false
	
	return aid_pet

# 治疗函数
func heal(amount: float):
	if not is_alive:
		return
	current_health = min(max_health, current_health + amount)
	call_deferred("update_ui")

# 击退效果已禁用
func apply_knockback_to_target(target: CharacterBody2D):
	# 击退功能暂时禁用
	pass

# 击退效果已禁用
func apply_knockback(direction: Vector2, force: float):
	# 击退功能暂时禁用
	pass

# 将位置限制在战斗区域内
func clamp_position_to_battle_area(pos: Vector2) -> Vector2:
	var battle_area_min = Vector2(50, 50)
	var battle_area_max = Vector2(1350, 670)
	
	pos.x = clamp(pos.x, battle_area_min.x, battle_area_max.x)
	pos.y = clamp(pos.y, battle_area_min.y, battle_area_max.y)
	return pos

# 元素克制计算
func get_element_multiplier(attacker_element: ElementType, defender_element: ElementType) -> float:
	# 如果攻击者无属性，返回正常伤害
	if attacker_element == ElementType.NONE:
		return 0.0  # 无额外伤害
	
	# 雷属性克制所有其他属性
	if attacker_element == ElementType.THUNDER and defender_element != ElementType.NONE:
		return element_damage_bonus  # 雷克制所有
	
	# 如果防御者无属性，无克制关系
	if defender_element == ElementType.NONE:
		return 0.0
	
	# 五行克制：金克木，木克水，水克火，火克土，土克金
	match attacker_element:
		ElementType.METAL:
			if defender_element == ElementType.WOOD:
				return element_damage_bonus  # 金克木
		ElementType.WOOD:
			if defender_element == ElementType.WATER:
				return element_damage_bonus  # 木克水
		ElementType.WATER:
			if defender_element == ElementType.FIRE:
				return element_damage_bonus  # 水克火
		ElementType.FIRE:
			if defender_element == ElementType.EARTH:
				return element_damage_bonus  # 火克土
		ElementType.EARTH:
			if defender_element == ElementType.METAL:
				return element_damage_bonus  # 土克金
	
	return 0.0  # 无克制关系，无额外伤害

# 当敌人死亡时被调用
func on_enemy_died(dead_enemy: CharacterBody2D):
	if current_target == dead_enemy:
		current_target = null
		current_state = PetState.IDLE

# 处理巡逻逻辑
func handle_patrol(delta: float):
	if patrol_path.size() == 0:
		return
	
	# 确保当前巡逻索引有效
	if current_patrol_index >= patrol_path.size():
		current_patrol_index = 0
	
	var target_point = patrol_path[current_patrol_index]
	# 使用本地坐标进行计算（因为宠物现在在巡逻线节点下）
	var distance_to_target = position.distance_to(target_point)
	
	# 如果距离目标点很近，移动到下一个点
	if distance_to_target < 30.0:  # 增加检测距离，避免抖动
		patrol_wait_time += delta
		if patrol_wait_time >= patrol_max_wait_time:
			current_patrol_index = (current_patrol_index + 1) % patrol_path.size()
			patrol_wait_time = 0.0
		
		# 在等待期间播放空闲动画
		if pet_image and pet_image.animation != "idle":
			pet_image.animation = "idle"
		velocity = Vector2.ZERO
	else:
		# 移动到目标点
		var direction = (target_point - position).normalized()
		velocity = direction * patrol_speed
		
		# 播放移动动画
		if pet_image and pet_image.animation != "walk":
			pet_image.animation = "walk"
		
		# 根据移动方向翻转精灵
		if direction.x < 0:
			pet_image.flip_h = false
		elif direction.x > 0:
			pet_image.flip_h = true
		
		patrol_wait_time = 0.0
	
	# 应用移动
	move_and_slide()
	
	# 限制在巡逻区域内（使用本地坐标）
	clamp_to_patrol_area()

# 设置战斗启用状态
func set_combat_enabled(enabled: bool):
	combat_enabled = enabled
	if not enabled:
		# 禁用战斗时，清除当前目标
		current_target = null
		current_state = PetState.IDLE

# 限制巡逻宠物在合理的坐标范围内
func clamp_to_patrol_area():
	# 基于巡逻路径计算合理的边界
	if patrol_path.size() > 0:
		var min_x = patrol_path[0].x
		var max_x = patrol_path[0].x
		var min_y = patrol_path[0].y
		var max_y = patrol_path[0].y
		
		# 找到路径的边界
		for point in patrol_path:
			min_x = min(min_x, point.x)
			max_x = max(max_x, point.x)
			min_y = min(min_y, point.y)
			max_y = max(max_y, point.y)
		
		# 添加一些缓冲区域
		var buffer = 100.0
		min_x -= buffer
		max_x += buffer
		min_y -= buffer
		max_y += buffer
		
		# 限制位置
		position.x = clamp(position.x, min_x, max_x)
		position.y = clamp(position.y, min_y, max_y)

# 播放受伤动画（带冷却保护）
func play_hurt_animation():
	if not pet_image:
		return
	
	# 检查受伤动画冷却时间
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_hurt_time < hurt_animation_cooldown:
		return  # 冷却中，不播放动画
	
	last_hurt_time = current_time
	
	# 如果已经有受伤动画在播放，停止之前的
	if hurt_tween:
		hurt_tween.kill()
		hurt_tween = null
	
	# 性能模式下简化动画
	if performance_mode:
		# 简单的颜色变化，无需Tween
		pet_image.modulate = Color.RED
		# 使用计时器恢复颜色（更轻量）
		await get_tree().create_timer(0.1).timeout
		if pet_image:  # 确保宠物还存在
			pet_image.modulate = original_modulate
		return
	
	# 创建受伤动画（闪红效果）
	hurt_tween = create_tween()
	
	# 立即变红
	pet_image.modulate = Color.RED
	
	# 0.2秒后恢复原色
	hurt_tween.tween_property(pet_image, "modulate", original_modulate, 0.2)
	
	# 动画结束后清理
	hurt_tween.tween_callback(func():
		hurt_tween = null
	)

# 切换性能模式
func toggle_performance_mode():
	performance_mode = !performance_mode
	var mode_text = "性能模式" if performance_mode else "正常模式"
	add_battle_detail_to_panel("⚡ " + pet_name + " 切换到 " + mode_text, Color.YELLOW)
	print("⚡ " + pet_name + " 切换到 " + mode_text)

# 输出宠物性能状态
func debug_performance_status():
	print("=== " + pet_name + " 性能状态调试 ===")
	print("性能模式: " + str(performance_mode))
	print("伤害反弹深度: " + str(damage_reflect_depth))
	print("帧跳跃计数: " + str(frame_skip_counter))
	print("上次受伤时间: " + str(last_hurt_time))
	print("上次攻击时间: " + str(last_attack_time))
	print("当前状态: " + str(current_state))
	print("是否存活: " + str(is_alive))
	print("是否正在死亡: " + str(is_dying))
	print("============================")

# 重置性能状态（紧急恢复）
func reset_performance_state():
	performance_mode = false
	damage_reflect_depth = 0
	frame_skip_counter = 0
	
	# 清理可能卡住的动画
	if hurt_tween:
		hurt_tween.kill()
		hurt_tween = null
	
	# 恢复正常颜色
	if pet_image:
		pet_image.modulate = original_modulate
	
	print("🔄 " + pet_name + " 性能状态已重置")
	add_battle_detail_to_panel("🔄 " + pet_name + " 性能状态已重置", Color.GREEN)

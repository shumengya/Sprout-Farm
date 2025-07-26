extends Node
class_name PetConfig
# 每一种宠物的配置数据 方便导出JSON数据，放到MongoDB数据库上



# 攻击类型枚举（简化为仅近战）
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
	DEAD		# 死亡
}

#==========================以下是导出数据可以被修改的=========================================
# 基本属性
var pet_name: String = "萌芽小绿"  # 宠物名称
var pet_id: String = "0001"  # 宠物唯一编号
var pet_type: String = "小绿"  # 宠物种类
var pet_level: int = 1  # 宠物等级
var pet_experience: int = 0  # 宠物经验值

#性格 出生日期 爱好 个人介绍
var pet_temperament: String = "温顺"  # 性格
var pet_birthday: String = "2023-01-01"  # 出生日期
var pet_hobby: String = "喜欢吃pet"  # 爱好
var pet_introduction: String = "我是一个小绿"  # 个人介绍

# 生命与防御
var max_health: float = 200.0  # 最大生命值
var enable_health_regen: bool = true  # 是否开启生命恢复
var health_regen: float = 1.0  # 每秒生命恢复大小
var enable_shield_regen: bool = true  # 是否开启护盾恢复
var max_shield: float = 100.0  # 最大护盾值
var shield_regen: float = 1.0  # 每秒护盾恢复大小
var max_armor: float = 100.0  # 最大护甲值

# 攻击属性
var base_attack_damage: float = 25.0  # 基础攻击力
var crit_rate: float = 0.1  # 暴击几率（0~1）
var crit_damage: float = 1.5  # 暴击伤害倍率（1.5 = 150%伤害）
var armor_penetration: float = 0.0  # 护甲穿透值（直接减少对方护甲值）

#======================以后有新技能在这里添加==============================
# 技能-多发射击
var enable_multi_projectile_skill: bool = false
var multi_projectile_delay: float = 2.0  # 多发射击延迟时间（秒）

# 技能-狂暴模式
var enable_berserker_skill: bool = false  
var berserker_bonus: float = 1.5  # 狂暴伤害加成
var berserker_duration: float = 5.0  # 狂暴持续时间（秒）

#技能-自爆
var enable_self_destruct_skill: bool = false
var self_destruct_damage: float = 50.0  # 自爆伤害值

#技能-召唤小弟
var enable_summon_pet_skill: bool = false 
var summon_count: int = 1  # 召唤小弟数量
var summon_scale: float = 0.1  # 召唤小弟属性缩放比例（10%）

#技能-死亡重生
var enable_death_respawn_skill: bool = false
var respawn_health_percentage: float = 0.3  # 重生时恢复的血量百分比（30%）
#======================以后有新技能在这里添加==============================

# 移动属性
var move_speed: float = 150.0  # 移动速度（像素/秒）
var dodge_rate: float = 0.05  # 闪避概率（0~1）

# 元素属性
var element_type: ElementType = ElementType.NONE  # 元素类型（例如火、水、雷等）
var element_damage_bonus: float = 50.0  # 元素伤害加成（额外元素伤害）

# 武器系统
var left_weapon: String = ""  # 左手武器名称
var right_weapon: String = ""  # 右手武器名称

# 宠物配置字典 - 用于导出到MongoDB数据库
var pet_configs: Dictionary = {
    "烈焰鸟": {
    "pet_name": "树萌芽の烈焰鸟",
    "can_purchase": true,
    "cost": 1000,
    "pet_image": "res://Scene/NewPet/PetType/flying_bird.tscn",
    "pet_id": "0001",
    "pet_type": "烈焰鸟",
    "pet_level": 1,
    "pet_experience": 500,
    "pet_temperament": "勇猛",
    "pet_birthday": "2023-03-15",
    "pet_hobby": "喜欢战斗和烈火",
    "pet_introduction": "我爱吃虫子",
    "max_health": 300,
    "enable_health_regen": true,
    "health_regen": 2,
    "enable_shield_regen": true,
    "max_shield": 150,
    "shield_regen": 1.5,
    "max_armor": 120,
    "base_attack_damage": 40,
    "crit_rate": 0.15,
    "crit_damage": 2,
    "armor_penetration": 10,
    "enable_multi_projectile_skill": true,
    "multi_projectile_delay": 2,
    "enable_berserker_skill": true,
    "berserker_bonus": 1.8,
    "berserker_duration": 6,
    "enable_self_destruct_skill": false,
    "enable_summon_pet_skill": false,
    "enable_death_respawn_skill": true,
    "respawn_health_percentage": 0.4,
    "move_speed": 180,
    "dodge_rate": 0.08,
    "element_type": "FIRE",
    "element_damage_bonus": 75,
    "left_weapon": "钻石剑",
    "right_weapon": "钻石剑"
  },
    "大蓝虫": {
    "pet_name": "树萌芽の大蓝虫",
    "can_purchase": true,
    "cost": 1000,
    "pet_image": "res://Scene/NewPet/PetType/big_beetle.tscn",
    "pet_id": "0002",
    "pet_type": "大蓝虫",
    "pet_level": 8,
    "pet_experience": 320,
    "pet_temperament": "冷静",
    "pet_birthday": "2023-06-20",
    "pet_hobby": "喜欢和小甲壳虫玩",
    "pet_introduction": "我是大蓝虫，不是大懒虫！",
    "max_health": 180,
    "enable_health_regen": true,
    "health_regen": 1.2,
    "enable_shield_regen": true,
    "max_shield": 200,
    "shield_regen": 2.5,
    "max_armor": 80,
    "base_attack_damage": 35,
    "crit_rate": 0.12,
    "crit_damage": 1.8,
    "armor_penetration": 15,
    "enable_multi_projectile_skill": true,
    "multi_projectile_delay": 1.5,
    "enable_berserker_skill": false,
    "enable_self_destruct_skill": false,
    "enable_summon_pet_skill": true,
    "summon_count": 2,
    "summon_scale": 0.15,
    "enable_death_respawn_skill": false,
    "move_speed": 120,
    "dodge_rate": 0.12,
    "element_type": "WATER",
    "element_damage_bonus": 100,
    "left_weapon": "钻石剑",
    "right_weapon": "钻石剑"
  },
    "小蓝虫": {
    "pet_name": "树萌芽の小蓝虫",
    "can_purchase": true,
    "cost": 1000,
    "pet_image": "res://Scene/NewPet/PetType/small_beetle.tscn",
    "pet_id": "0002",
    "pet_type": "小蓝虫",
    "pet_level": 1,
    "pet_experience": 0,
    "pet_temperament": "冷静",
    "pet_birthday": "2023-06-20",
    "pet_hobby": "喜欢和大蓝虫玩",
    "pet_introduction": "我是小蓝虫，不是小懒虫！",
    "max_health": 90,
    "enable_health_regen": true,
    "health_regen": 1.2,
    "enable_shield_regen": true,
    "max_shield": 200,
    "shield_regen": 2.5,
    "max_armor": 80,
    "base_attack_damage": 35,
    "crit_rate": 0.12,
    "crit_damage": 1.8,
    "armor_penetration": 15,
    "enable_multi_projectile_skill": true,
    "multi_projectile_delay": 1.5,
    "enable_berserker_skill": false,
    "enable_self_destruct_skill": false,
    "enable_summon_pet_skill": true,
    "summon_count": 2,
    "summon_scale": 0.15,
    "enable_death_respawn_skill": false,
    "move_speed": 120,
    "dodge_rate": 0.12,
    "element_type": "WATER",
    "element_damage_bonus": 100,
    "left_weapon": "钻石剑",
    "right_weapon": "钻石剑"
  },
    "小蓝": {
    "pet_name": "树萌芽の小蓝",
    "can_purchase": true,
    "cost": 1000,
    "pet_image": "res://Scene/NewPet/PetType/small_blue.tscn",
    "pet_id": "0002",
    "pet_type": "小蓝",
    "pet_level": 1,
    "pet_experience": 0,
    "pet_temperament": "冷静",
    "pet_birthday": "2023-06-20",
    "pet_hobby": "喜欢和小黄一起玩",
    "pet_introduction": "我是小黄！",
    "max_health": 120,
    "enable_health_regen": true,
    "health_regen": 1.2,
    "enable_shield_regen": true,
    "max_shield": 200,
    "shield_regen": 2.5,
    "max_armor": 80,
    "base_attack_damage": 35,
    "crit_rate": 0.12,
    "crit_damage": 1.8,
    "armor_penetration": 15,
    "enable_multi_projectile_skill": true,
    "multi_projectile_delay": 1.5,
    "enable_berserker_skill": false,
    "enable_self_destruct_skill": false,
    "enable_summon_pet_skill": true,
    "summon_count": 2,
    "summon_scale": 0.15,
    "enable_death_respawn_skill": false,
    "move_speed": 120,
    "dodge_rate": 0.12,
    "element_type": "WATER",
    "element_damage_bonus": 100,
    "left_weapon": "钻石剑",
    "right_weapon": "钻石剑"
  }
}

# 初始化函数
func _ready():
	"""节点准备就绪时自动加载JSON配置"""
	load_configs_from_json()

# 手动初始化配置的函数
func initialize_configs():
	"""手动初始化宠物配置，优先从JSON加载"""
	if not load_configs_from_json():
		print("JSON加载失败，使用默认配置")
		# 如果JSON加载失败，保持使用代码中的默认配置


# 获取宠物配置的函数
func get_pet_config(pet_key: String) -> Dictionary:
	"""根据宠物键值获取配置"""
	if pet_configs.has(pet_key):
		return pet_configs[pet_key]
	else:
		print("未找到宠物配置: ", pet_key, "，使用默认配置")
		return get_default_config()

# 获取所有宠物配置键值的函数
func get_all_pet_keys() -> Array:
	"""获取所有可用的宠物配置键值"""
	return pet_configs.keys()

# 检查宠物配置是否存在的函数
func has_pet_config(pet_key: String) -> bool:
	"""检查指定的宠物配置是否存在"""
	return pet_configs.has(pet_key)

# 获取默认配置的函数
func get_default_config() -> Dictionary:
	"""获取默认宠物配置"""
	return {
		"pet_name": pet_name,
		"pet_id": pet_id,
		"pet_type": pet_type,
		"pet_level": pet_level,
		"pet_experience": pet_experience,
		"pet_temperament": pet_temperament,
		"pet_birthday": pet_birthday,
		"pet_hobby": pet_hobby,
		"pet_introduction": pet_introduction,
		"max_health": max_health,
		"enable_health_regen": enable_health_regen,
		"health_regen": health_regen,
		"enable_shield_regen": enable_shield_regen,
		"max_shield": max_shield,
		"shield_regen": shield_regen,
		"max_armor": max_armor,
		"base_attack_damage": base_attack_damage,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,
		"armor_penetration": armor_penetration,
		"enable_multi_projectile_skill": enable_multi_projectile_skill,
		"multi_projectile_delay": multi_projectile_delay,
		"enable_berserker_skill": enable_berserker_skill,
		"berserker_bonus": berserker_bonus,
		"berserker_duration": berserker_duration,
		"enable_self_destruct_skill": enable_self_destruct_skill,
		"self_destruct_damage": self_destruct_damage,
		"enable_summon_pet_skill": enable_summon_pet_skill,
		"summon_count": summon_count,
		"summon_scale": summon_scale,
		"enable_death_respawn_skill": enable_death_respawn_skill,
		"respawn_health_percentage": respawn_health_percentage,
		"move_speed": move_speed,
		"dodge_rate": dodge_rate,
		"element_type": element_type,
		"element_damage_bonus": element_damage_bonus,
		"left_weapon": left_weapon,
		"right_weapon": right_weapon
	}

# 字符串转换为ElementType枚举的函数
func string_to_element_type(element_str: String) -> ElementType:
	"""将字符串转换为ElementType枚举"""
	match element_str.to_upper():
		"NONE":#没有元素类型
			return ElementType.NONE
		"METAL":#金元素
			return ElementType.METAL
		"WOOD":#木元素
			return ElementType.WOOD
		"WATER":#水元素
			return ElementType.WATER
		"FIRE":	#火元素
			return ElementType.FIRE
		"EARTH":#土元素
			return ElementType.EARTH
		"THUNDER":#雷元素
			return ElementType.THUNDER
		_:
			return ElementType.NONE

# 从JSON文件加载宠物配置的函数
func load_configs_from_json(file_path: String = "res://Scene/NewPet/Pet_data.json") -> bool:
	"""从JSON文件加载宠物配置"""
	if not FileAccess.file_exists(file_path):
		print("宠物配置文件不存在: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("无法打开宠物配置文件: ", file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("JSON解析失败: ", json.error_string)
		return false
	
	var loaded_configs = json.data
	if typeof(loaded_configs) != TYPE_DICTIONARY:
		print("JSON格式错误，期望字典类型")
		return false
	
	# 清空现有配置并加载新配置
	pet_configs.clear()
	
	# 遍历加载的配置
	for pet_key in loaded_configs.keys():
		var config = loaded_configs[pet_key]
		if typeof(config) != TYPE_DICTIONARY:
			print("跳过无效的宠物配置: ", pet_key)
			continue
		
		# 处理element_type字符串转换为枚举
		if config.has("element_type") and typeof(config["element_type"]) == TYPE_STRING:
			config["element_type"] = string_to_element_type(config["element_type"])
		
		# 添加到配置字典
		pet_configs[pet_key] = config
	
	print("成功从JSON加载了 ", pet_configs.size(), " 个宠物配置")
	return true

# 导出配置到JSON的函数
func export_configs_to_json() -> String:
	"""将宠物配置导出为JSON字符串，用于保存到MongoDB"""
	return JSON.stringify(pet_configs)

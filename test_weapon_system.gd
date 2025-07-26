extends Node

# 测试武器系统的简单脚本
func _ready():
	print("开始测试武器系统...")
	
	# 创建武器系统实例
	var weapon_system = WeaponBase.new()
	
	# 测试武器数据
	print("武器列表:")
	for weapon_name in weapon_system.get_all_weapon_names():
		print("  - %s: %s" % [weapon_name, weapon_system.get_weapon_icon(weapon_name)])
	
	# 创建一个模拟宠物对象来测试武器效果
	var mock_pet = Node.new()
	mock_pet.set_script(preload("res://Scene/NewPet/NewPetBase.gd"))
	mock_pet.pet_name = "测试宠物"
	mock_pet.base_attack_damage = 25.0
	mock_pet.crit_rate = 0.1
	mock_pet.attack_speed = 1.0
	mock_pet.armor_penetration = 0.0
	mock_pet.attack_range = 100.0
	mock_pet.knockback_force = 300.0
	
	print("\n测试武器效果:")
	print("装备前属性:")
	print("  攻击力: %.1f" % mock_pet.base_attack_damage)
	print("  暴击率: %.2f" % mock_pet.crit_rate)
	print("  攻击速度: %.1f" % mock_pet.attack_speed)
	
	# 测试装备钻石剑
	weapon_system.apply_weapon_effect(mock_pet, "钻石剑")
	print("\n装备钻石剑后:")
	print("  攻击力: %.1f" % mock_pet.base_attack_damage)
	print("  暴击率: %.2f" % mock_pet.crit_rate)
	print("  攻击速度: %.1f" % mock_pet.attack_speed)
	
	# 测试卸下武器
	weapon_system.remove_weapon_effect(mock_pet, "钻石剑")
	print("\n卸下钻石剑后:")
	print("  攻击力: %.1f" % mock_pet.base_attack_damage)
	print("  暴击率: %.2f" % mock_pet.crit_rate)
	print("  攻击速度: %.1f" % mock_pet.attack_speed)
	
	print("\n武器系统测试完成！")
	
	# 清理
	mock_pet.queue_free()
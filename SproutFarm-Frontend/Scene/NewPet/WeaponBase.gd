extends Node
class_name WeaponBase

#武器系统
var weapon_data = {
	"钻石剑": {
		"icon": 'res://assets/我的世界图片/武器工具/钻石剑.png',
		"function": "apply_diamond_sword_effect"
	},
	"铁剑": {
		"icon": 'res://assets/我的世界图片/武器工具/铁剑.png',
		"function": "apply_iron_sword_effect"
	},
	"钻石斧": {
		"icon": 'res://assets/我的世界图片/武器工具/钻石斧.png',
		"function": "apply_diamond_axe_effect"
	},
	"铁镐": {
		"icon": 'res://assets/我的世界图片/武器工具/铁镐.png',
		"function": "apply_iron_pickaxe_effect"
	}
}

# 武器效果函数 - 每种武器单独一个函数

#================钻石剑效果========================
# 钻石剑效果
func apply_diamond_sword_effect(pet):
	pet.base_attack_damage += 15.0
	pet.crit_rate += 0.1
	pet.attack_speed += 0.2
	# 钻石剑效果已应用

# 移除钻石剑效果
func remove_diamond_sword_effect(pet):
	pet.base_attack_damage -= 15.0
	pet.crit_rate -= 0.1
	pet.attack_speed -= 0.2
	# 钻石剑效果已移除

#================钻石剑效果========================

#================铁剑效果========================
# 铁剑效果
func apply_iron_sword_effect(pet):
	pet.base_attack_damage += 10.0
	pet.crit_rate += 0.05
	pet.attack_speed += 0.1
	# 铁剑效果已应用

# 移除铁剑效果
func remove_iron_sword_effect(pet):
	pet.base_attack_damage -= 10.0
	pet.crit_rate -= 0.05
	pet.attack_speed -= 0.1
	# 铁剑效果已移除
#================铁剑效果========================


#================钻石斧效果========================
# 钻石斧效果
func apply_diamond_axe_effect(pet):
	pet.base_attack_damage += 20.0
	pet.armor_penetration += 0.2
	pet.knockback_force += 100.0
	# 钻石斧效果已应用

# 移除钻石斧效果
func remove_diamond_axe_effect(pet):
	pet.base_attack_damage -= 20.0
	pet.armor_penetration -= 0.2
	pet.knockback_force -= 100.0
	# 钻石斧效果已移除
#================钻石斧效果========================


#================铁镐效果========================
# 铁镐效果
func apply_iron_pickaxe_effect(pet):
	pet.base_attack_damage += 8.0
	pet.armor_penetration += 0.3
	pet.attack_range += 20.0
	# 铁镐效果已应用

# 移除铁镐效果
func remove_iron_pickaxe_effect(pet):
	pet.base_attack_damage -= 8.0
	pet.armor_penetration -= 0.3
	pet.attack_range -= 20.0
	# 铁镐效果已移除
#================铁镐效果========================


#======================武器系统通用函数==========================
# 应用武器效果的主函数
func apply_weapon_effect(pet, weapon_name: String):
	if not weapon_data.has(weapon_name):
		return
	
	var weapon = weapon_data[weapon_name]
	var function_name = weapon.get("function", "")
	
	if function_name != "":
		call(function_name, pet)

# 移除武器效果的函数
func remove_weapon_effect(pet, weapon_name: String):
	if not weapon_data.has(weapon_name):
		return
	
	var weapon = weapon_data[weapon_name]
	var function_name = weapon.get("function", "")
	
	if function_name != "":
		# 将apply替换为remove来调用移除函数
		var remove_function_name = function_name.replace("apply_", "remove_")
		call(remove_function_name, pet)

# 获取武器图标路径
func get_weapon_icon(weapon_name: String) -> String:
	if weapon_data.has(weapon_name):
		return weapon_data[weapon_name].get("icon", "")
	return ""

# 获取所有武器名称列表
func get_all_weapon_names() -> Array:
	return weapon_data.keys()
#======================武器系统通用函数==========================

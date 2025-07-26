extends Node

# 子弹系统测试脚本
# 用于验证每种子弹的独立创建函数功能

func _ready():
	test_bullet_system()

func test_bullet_system():
	print("=== 子弹系统测试开始 ===")
	
	# 创建子弹实例
	var bullet_scene = preload("res://Scene/NewPet/BulletBase.tscn")
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	
	# 测试获取所有子弹名称
	print("\n可用子弹类型:")
	var bullet_names = bullet.get_all_bullet_names()
	for name in bullet_names:
		print("- %s" % name)
	
	# 测试每种子弹的创建
	print("\n=== 测试各种子弹创建 ===")
	
	# 测试小蓝弹
	print("\n测试小蓝弹:")
	bullet.create_blue_bullet()
	print("速度: %.1f, 伤害: %.1f, 生存时间: %.1f" % [bullet.speed, bullet.damage, bullet.lifetime])
	
	# 测试小红弹
	print("\n测试小红弹:")
	bullet.create_red_bullet()
	print("速度: %.1f, 伤害: %.1f, 生存时间: %.1f" % [bullet.speed, bullet.damage, bullet.lifetime])
	
	# 测试长橙弹
	print("\n测试长橙弹:")
	bullet.create_long_orange_bullet()
	print("速度: %.1f, 伤害: %.1f, 生存时间: %.1f, 最大距离: %.1f" % [bullet.speed, bullet.damage, bullet.lifetime, bullet.max_distance])
	
	# 测试黄色闪电
	print("\n测试黄色闪电:")
	bullet.create_yellow_lightning_bullet()
	print("速度: %.1f, 伤害: %.1f, 生存时间: %.1f, 最大距离: %.1f" % [bullet.speed, bullet.damage, bullet.lifetime, bullet.max_distance])
	
	# 测试紫色闪电
	print("\n测试紫色闪电:")
	bullet.create_purple_lightning_bullet()
	print("速度: %.1f, 伤害: %.1f, 生存时间: %.1f, 最大距离: %.1f" % [bullet.speed, bullet.damage, bullet.lifetime, bullet.max_distance])
	
	# 测试通过名称创建子弹
	print("\n=== 测试通过名称创建子弹 ===")
	bullet.create_bullet_by_name("小粉弹")
	print("小粉弹 - 速度: %.1f, 伤害: %.1f" % [bullet.speed, bullet.damage])
	
	bullet.create_bullet_by_name("长绿弹")
	print("长绿弹 - 速度: %.1f, 伤害: %.1f" % [bullet.speed, bullet.damage])
	
	# 测试获取子弹图标
	print("\n=== 测试获取子弹图标 ===")
	for name in ["小蓝弹", "小红弹", "黄色闪电"]:
		var icon_path = bullet.get_bullet_icon(name)
		print("%s 图标路径: %s" % [name, icon_path])
	
	# 测试setup函数的新功能
	print("\n=== 测试setup函数 ===")
	bullet.setup(Vector2.RIGHT, 100.0, 10.0, null, "绿色闪电")
	print("使用setup创建绿色闪电 - 速度: %.1f, 伤害: %.1f" % [bullet.speed, bullet.damage])
	
	bullet.setup(Vector2.LEFT, 200.0, 15.0, null)  # 不指定类型
	print("使用setup创建默认子弹 - 速度: %.1f, 伤害: %.1f" % [bullet.speed, bullet.damage])
	
	print("\n=== 子弹系统测试完成 ===")
	
	# 清理测试对象
	bullet.queue_free()
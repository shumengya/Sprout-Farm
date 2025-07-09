extends Area2D

# 子弹属性
var damage: float = 20.0
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var attacker_team: String = ""
var attacker_element: int = 0
var armor_penetration: float = 0.0
var attacker_pet: CharacterBody2D = null  # 攻击者引用

# 子弹生存时间（防止子弹飞出边界后一直存在）
var lifetime: float = 3.0

var lifetime_timer: float = 0.0  # 生存时间计时器

func _ready():
	# 连接碰撞信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# 设置子弹的碰撞层 - 子弹需要能检测到所有队伍的宠物
	collision_layer = 0  # 子弹本身不需要被检测
	collision_mask = 3   # 检测team1和team2的宠物 (1+2)
	
	# 创建简单的圆形纹理
	create_circle_texture()
	
	# 添加到子弹组
	add_to_group("projectiles")

func _physics_process(delta):
	# 子弹移动
	global_position += direction * speed * delta
	
	# 更新生存时间
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		destroy_projectile()

# 销毁子弹（直接销毁）
func destroy_projectile():
	# 延迟销毁，避免在物理回调中移除节点
	call_deferred("queue_free")

# 穿透属性
var pierce_remaining: int = 1				# 剩余穿透次数
var hit_enemies: Array[CharacterBody2D] = []	# 已击中的敌人列表（防止重复击中）

func set_projectile_data(dmg: float, spd: float, dir: Vector2, team: String, element: int, armor_pen: float = 0.0, pierce: int = 1, attacker: CharacterBody2D = null):
	damage = dmg
	speed = spd
	direction = dir.normalized()
	attacker_team = team
	attacker_element = element
	armor_penetration = armor_pen
	pierce_remaining = pierce
	attacker_pet = attacker

func _on_area_entered(area):
	# 这里可以处理与其他Area2D的碰撞（如果需要）
	pass

func _on_body_entered(body):
	# 检查是否击中敌方宠物
	if body is CharacterBody2D and body.has_method("get_team"):
		var target_team = body.get_team()
		
		# 不能击中同队伍的宠物
		if target_team == attacker_team:
			print("子弹跳过同队伍宠物: " + body.pet_name + " (队伍: " + target_team + ")")
			return
		
		# 不能击中死亡的宠物
		if not body.is_alive:
			print("子弹跳过死亡宠物: " + body.pet_name)
			return
		
		# 不能重复击中同一个敌人
		if body in hit_enemies:
			print("子弹跳过已击中的宠物: " + body.pet_name)
			return
		
		# 记录击中的敌人
		hit_enemies.append(body)
		
		# 对目标造成伤害（检查攻击者是否还有效）
		var valid_attacker = null
		if attacker_pet and is_instance_valid(attacker_pet):
			valid_attacker = attacker_pet
		body.take_damage(damage, armor_penetration, attacker_element, valid_attacker)
		print("子弹击中敌方宠物: " + body.pet_name + " (攻击方: " + attacker_team + " 目标: " + target_team + ") 造成伤害: " + str(damage))
		
		# 减少穿透次数
		pierce_remaining -= 1
		
		# 如果穿透次数用完，销毁子弹
		if pierce_remaining <= 0:
			print("子弹穿透次数用完，销毁")
			destroy_projectile()
		else:
			print("子弹穿透，剩余穿透次数: " + str(pierce_remaining))
	else:
		print("子弹击中非宠物对象: " + str(body))

# 创建简单的圆形纹理
func create_circle_texture():
	var sprite = get_node_or_null("ProjectileSprite")
	if sprite:
		# 创建一个简单的圆形图像纹理
		var image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
		var center = Vector2(10, 10)
		var radius = 8
		
		# 绘制圆形
		for x in range(20):
			for y in range(20):
				var distance = Vector2(x, y).distance_to(center)
				if distance <= radius:
					# 设置黄色像素
					image.set_pixel(x, y, Color.YELLOW)
				else:
					# 设置透明像素
					image.set_pixel(x, y, Color.TRANSPARENT)
		
		# 创建纹理并应用
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture 

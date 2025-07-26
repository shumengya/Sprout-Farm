extends Area2D
class_name BulletBase

# 简化子弹系统 - 辅助攻击用
# 基础功能：移动、碰撞检测、伤害

signal bullet_hit(bullet: BulletBase, target: NewPetBase)

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const bullet = {
	"小蓝弹":{
		"图片":"res://assets/子弹图片/01.png",
		"函数":"create_blue_bullet"
	},
	"小红弹":{
		"图片":"res://assets/子弹图片/02.png",
		"函数":"create_red_bullet"
	},
	"小粉弹":{
		"图片":"res://assets/子弹图片/03.png",
		"函数":"create_pink_bullet"
	},
	"小紫弹":{
		"图片":"res://assets/子弹图片/04.png",
		"函数":"create_purple_bullet"
	},
	"长橙弹":{
		"图片":"res://assets/子弹图片/21.png",
		"函数":"create_long_orange_bullet"
	},
	"长紫弹":{
		"图片":"res://assets/子弹图片/22.png",
		"函数":"create_long_purple_bullet"
	},
	"长绿弹":{
		"图片":"res://assets/子弹图片/25.png",
		"函数":"create_long_green_bullet"
	},
	"黄色闪电":{
		"图片":"res://assets/子弹图片/36.png",
		"函数":"create_yellow_lightning_bullet"
	},
	"绿色闪电":{
		"图片":"res://assets/子弹图片/35.png",
		"函数":"create_green_lightning_bullet"
	},
	"红色闪电":{
		"图片":"res://assets/子弹图片/33.png",
		"函数":"create_red_lightning_bullet"
	},
	"紫色闪电":{
		"图片":"res://assets/子弹图片/32.png",
		"函数":"create_purple_lightning_bullet"
	},
}


# 基础子弹属性
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 25.0
var owner_pet: NewPetBase = null
var max_distance: float = 800.0
var traveled_distance: float = 0.0
var is_active: bool = true

# 生存时间
var lifetime: float = 3.0
var current_lifetime: float = 0.0


#==================基础函数=========================
func _ready():
	# 连接碰撞信号
	area_entered.connect(_on_area_entered)
	
	# 设置碰撞层
	collision_layer = 4  # 子弹层
	collision_mask = 1   # 只检测宠物层
	
	# 添加到子弹组
	add_to_group("bullets")

func _physics_process(delta):
	if not is_active:
		return
	
	# 更新生存时间
	current_lifetime += delta
	if current_lifetime >= lifetime:
		call_deferred("destroy_bullet")
		return
	
	# 检查长紫弹分裂计时
	if has_meta("bullet_type") and get_meta("bullet_type") == "长紫弹":
		var current_split_time = get_meta("current_split_time", 0.0)
		var split_timer = get_meta("split_timer", 2.0)
		current_split_time += delta
		set_meta("current_split_time", current_split_time)
		
		if current_split_time >= split_timer:
			# 时间到了，分裂并销毁
			call_deferred("create_split_bullets", global_position)
			call_deferred("destroy_bullet")
			return
	
	# 移动子弹
	var movement = direction * speed * delta
	position += movement
	traveled_distance += movement.length()
	
	# 检查最大距离
	if traveled_distance >= max_distance:
		call_deferred("destroy_bullet")
		return
	
	# 检查是否超出屏幕边界
	var viewport_rect = get_viewport().get_visible_rect()
	if not viewport_rect.has_point(global_position):
		call_deferred("destroy_bullet")
#==================基础函数=========================


#=============================每个子弹单独效果============================
# 小蓝弹
func create_blue_bullet():
	sprite.texture = load(bullet["小蓝弹"]["图片"])
	speed = 250.0
	damage = 20.0
	lifetime = 2.5
	sprite.modulate = Color(0.5, 0.8, 1.0, 1.0)  # 蓝色调

# 小红弹
func create_red_bullet():
	sprite.texture = load(bullet["小红弹"]["图片"])
	speed = 300.0
	damage = 25.0
	lifetime = 3.0
	sprite.modulate = Color(1.0, 0.5, 0.5, 1.0)  # 红色调

# 小粉弹
func create_pink_bullet():
	sprite.texture = load(bullet["小粉弹"]["图片"])
	speed = 280.0
	damage = 22.0
	lifetime = 2.8
	sprite.modulate = Color(1.0, 0.7, 0.9, 1.0)  # 粉色调

# 小紫弹
func create_purple_bullet():
	sprite.texture = load(bullet["小紫弹"]["图片"])
	speed = 320.0
	damage = 28.0
	lifetime = 3.2
	sprite.modulate = Color(0.8, 0.5, 1.0, 1.0)  # 紫色调

# 长橙弹
func create_long_orange_bullet():
	sprite.texture = load(bullet["长橙弹"]["图片"])
	speed = 350.0
	damage = 35.0
	lifetime = 4.0
	max_distance = 1000.0
	sprite.modulate = Color(1.0, 0.7, 0.3, 1.0)  # 橙色调

# 长紫弹
func create_long_purple_bullet():
	sprite.texture = load(bullet["长紫弹"]["图片"])
	speed = 330.0
	damage = 32.0
	lifetime = 3.8
	max_distance = 950.0
	sprite.modulate = Color(0.9, 0.4, 1.0, 1.0)  # 深紫色调
	# 标记为长紫弹，2秒后自动分裂
	set_meta("bullet_type", "长紫弹")
	set_meta("split_timer", 2.0)  # 2秒后分裂
	set_meta("current_split_time", 0.0)  # 当前计时

# 创建分裂子弹（长紫弹2秒后的效果）
func create_split_bullets(hit_position: Vector2):
	"""在指定位置生成4个小弹向四周发射"""
	var bullet_types = ["小蓝弹", "小红弹", "小粉弹", "小紫弹"]
	var bullet_scene = preload("res://Scene/NewPet/BulletBase.tscn")
	
	# 生成4个方向的子弹
	for i in range(4):
		# 计算方向角度（每90度一个方向）
		var angle = i * PI / 2.0
		var direction_vector = Vector2(cos(angle), sin(angle))
		
		# 选择子弹类型（每种类型1个）
		var bullet_type = bullet_types[i]
		
		# 创建子弹实例
		var new_bullet = bullet_scene.instantiate()
		get_parent().add_child(new_bullet)
		
		# 设置子弹位置
		new_bullet.global_position = hit_position
		
		# 设置子弹属性（5个参数：方向、速度、伤害、所有者、子弹类型）
		new_bullet.setup(direction_vector, 200.0, 15.0, owner_pet, bullet_type)
		
		# 分裂子弹生成完成

# 长绿弹
func create_long_green_bullet():
	sprite.texture = load(bullet["长绿弹"]["图片"])
	speed = 310.0
	damage = 30.0
	lifetime = 3.5
	max_distance = 900.0
	sprite.modulate = Color(0.4, 1.0, 0.5, 1.0)  # 绿色调

# 黄色闪电
func create_yellow_lightning_bullet():
	sprite.texture = load(bullet["黄色闪电"]["图片"])
	speed = 400.0
	damage = 40.0
	lifetime = 2.0
	max_distance = 600.0
	sprite.modulate = Color(1.0, 1.0, 0.3, 1.0)  # 黄色闪电

# 绿色闪电
func create_green_lightning_bullet():
	sprite.texture = load(bullet["绿色闪电"]["图片"])
	speed = 380.0
	damage = 38.0
	lifetime = 2.2
	max_distance = 650.0
	sprite.modulate = Color(0.3, 1.0, 0.3, 1.0)  # 绿色闪电

# 红色闪电
func create_red_lightning_bullet():
	sprite.texture = load(bullet["红色闪电"]["图片"])
	speed = 420.0
	damage = 45.0
	lifetime = 1.8
	max_distance = 550.0
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # 红色闪电

# 紫色闪电
func create_purple_lightning_bullet():
	sprite.texture = load(bullet["紫色闪电"]["图片"])
	speed = 450.0
	damage = 50.0
	lifetime = 1.5
	max_distance = 500.0
	sprite.modulate = Color(0.8, 0.3, 1.0, 1.0)  # 紫色闪电
#=============================每个子弹单独效果============================



#=========================通用子弹函数==============================
# 通用子弹创建函数
func create_bullet_by_name(bullet_name: String):
	"""根据子弹名称创建对应类型的子弹"""
	if not bullet.has(bullet_name):
		return
	
	var bullet_data = bullet[bullet_name]
	var function_name = bullet_data.get("函数", "")
	
	if function_name != "":
		call(function_name)


# 获取子弹图标
func get_bullet_icon(bullet_name: String) -> Texture2D:
	if bullet.has(bullet_name) and bullet[bullet_name].has("图片"):
		return load(bullet[bullet_name]["图片"])
	else:
		return null

# 获取所有子弹名称列表
func get_all_bullet_names() -> Array:
	return bullet.keys()

# 创建击中特效
func create_hit_effect(pos: Vector2):
	pass

#销毁子弹
func destroy_bullet():
	"""销毁子弹"""
	is_active = false
	remove_from_group("bullets")
	queue_free()

#初始化子弹
func setup(dir: Vector2, spd: float, dmg: float, owner: NewPetBase, bullet_type: String = ""):
	"""初始化子弹"""
	direction = dir.normalized()
	owner_pet = owner
	
	# 如果指定了子弹类型，使用对应的创建函数
	if bullet_type != "" and bullet.has(bullet_type):
		create_bullet_by_name(bullet_type)
	else:
		# 使用传入的参数作为默认值
		speed = spd
		damage = dmg
		# 简单的视觉效果
		sprite.modulate = Color.YELLOW
	
	# 设置子弹旋转
	rotation = direction.angle()

#碰撞检测
func _on_area_entered(area: Area2D):
	"""碰撞检测"""
	if not is_active:
		return
	
	# 检查是否是宠物
	if not area is NewPetBase:
		return
	
	var pet_target = area as NewPetBase
	
	# 检查是否是有效目标
	if not is_valid_target(pet_target):
		return
	
	# 造成伤害并延迟销毁子弹（避免在物理查询期间修改状态）
	hit_target(pet_target)
	call_deferred("destroy_bullet")

#检查是否是有效攻击目标
func is_valid_target(target: NewPetBase) -> bool:
	"""检查是否是有效攻击目标"""
	# 检查owner_pet是否有效
	if not is_instance_valid(owner_pet):
		owner_pet = null
	
	# 不能攻击自己的主人
	if target == owner_pet:
		return false
	
	# 不能攻击同队伍
	if owner_pet != null and target.pet_team == owner_pet.pet_team:
		return false
	
	# 不能攻击已死亡的宠物
	if not target.is_alive:
		return false
	
	return true

#击中目标
func hit_target(target: NewPetBase):
	"""击中目标"""
	# 检查owner_pet是否有效（防止已释放对象错误）
	if not is_instance_valid(owner_pet):
		owner_pet = null
	
	# 造成伤害
	target.take_damage(damage, owner_pet)
	
	# 发射信号
	bullet_hit.emit(self, target)
	
	# 创建击中特效
	create_hit_effect(target.global_position)

#=========================通用子弹函数==============================

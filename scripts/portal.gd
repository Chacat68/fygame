extends Area2D

# 传送门脚本
# 用于在关卡之间传送玩家

# 信号
signal body_entered(body)

# 传送门参数
var next_level = -1 # -1表示自动进入下一关
var is_active = true # 传送门是否激活

# 在准备好时调用
func _ready():
	# 将自己添加到传送门组
	add_to_group("portal")
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 60) # 传送门碰撞区域大小
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# 创建传送门视觉效果
	_create_portal_visuals()
	
	# 连接信号
	connect("body_entered", _on_body_entered)

# 创建传送门视觉效果
func _create_portal_visuals():
	# 创建精灵节点
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(2, 3) # 调整大小
	
	# 创建简单的矩形作为临时视觉效果
	var rect = ColorRect.new()
	rect.size = Vector2(20, 30)
	rect.position = Vector2(-10, -15)
	rect.color = Color(0.2, 0.8, 1.0, 0.7) # 蓝色半透明
	
	# 添加到精灵
	sprite.add_child(rect)
	
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(10, 15)
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 10
	particles.initial_velocity_max = 30
	particles.scale_amount_min = 1
	particles.scale_amount_max = 3
	particles.color = Color(0.2, 0.8, 1.0, 0.7)
	
	# 添加到精灵
	sprite.add_child(particles)
	
	# 添加到场景
	add_child(sprite)
	
	# 创建标签
	var label = Label.new()
	label.text = "传送门"
	label.position = Vector2(-20, -40)
	add_child(label)

# 当有物体进入传送门时调用
func _on_body_entered(body):
	# 检查是否为玩家
	if body.is_in_group("player") and is_active:
		# 发出信号
		emit_signal("body_entered", body)

# 设置下一关卡
func set_next_level(level):
	next_level = level

# 设置传送门激活状态
func set_active(active):
	is_active = active
	
	# 更新视觉效果
	for child in get_children():
		if child is Sprite2D:
			child.modulate = Color(1, 1, 1, 1) if active else Color(0.5, 0.5, 0.5, 0.5)
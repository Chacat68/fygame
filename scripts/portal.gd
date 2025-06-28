extends Area2D

# 传送门脚本
# 用于在关卡之间传送玩家

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
	
	# 启动持续闪烁动画
	_start_idle_animation()

# 创建传送门视觉效果
func _create_portal_visuals():
	# 创建主要的传送门矩形
	var portal_rect = ColorRect.new()
	portal_rect.size = Vector2(40, 60)
	portal_rect.position = Vector2(-20, -30)
	portal_rect.color = Color(0.1, 0.6, 1.0, 0.8) # 明亮的蓝色
	add_child(portal_rect)
	
	# 创建边框效果
	var border_rect = ColorRect.new()
	border_rect.size = Vector2(44, 64)
	border_rect.position = Vector2(-22, -32)
	border_rect.color = Color(1.0, 1.0, 1.0, 0.9) # 白色边框
	add_child(border_rect)
	# 将主矩形移到边框前面
	move_child(portal_rect, -1)
	
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.amount = 30
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(20, 30)
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 50
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	particles.color = Color(0.3, 0.9, 1.0, 0.8)
	particles.emitting = true
	add_child(particles)
	
	# 创建标签
	var label = Label.new()
	label.text = "传送门"
	label.position = Vector2(-25, -50)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)

# 启动空闲状态的闪烁动画
func _start_idle_animation():
	var tween = create_tween()
	tween.set_loops() # 无限循环
	
	# 对所有ColorRect子节点应用闪烁效果
	for child in get_children():
		if child is ColorRect:
			tween.parallel().tween_property(child, "modulate", Color(1.5, 1.5, 1.5, 0.9), 1.0)
			tween.parallel().tween_property(child, "modulate", Color(1, 1, 1, 1), 1.0)

# 当有物体进入传送门时调用
func _on_body_entered(body):
	# 检查是否为玩家
	if body.is_in_group("player") and is_active:
		# 发出信号
		body_entered.emit(body)
		
		# 防止玩家多次触发传送门
		is_active = false
		
		# 添加视觉反馈
		for child in get_children():
			if child is ColorRect:
				# 创建闪烁动画
				var tween = create_tween()
				tween.tween_property(child, "modulate", Color(2, 2, 2, 1), 0.2)
				tween.tween_property(child, "modulate", Color(1, 1, 1, 1), 0.3)

# 设置下一关卡
func set_next_level(level):
	next_level = level

# 设置传送门激活状态
func set_active(active):
	is_active = active
	
	# 更新视觉效果
	for child in get_children():
		if child is ColorRect:
			child.modulate = Color(1, 1, 1, 1) if active else Color(0.5, 0.5, 0.5, 0.5)
		elif child is CPUParticles2D:
			child.emitting = active

extends Area2D

# 传送门脚本
# 用于在关卡之间传送玩家

# 传送门参数
var next_level = -1 # -1表示自动进入下一关
var is_active = true # 传送门是否激活
var destination_scene: String = "" # 目标场景路径
var teleport_position: Vector2 = Vector2.ZERO # 传送到目标场景的位置

# 管理器引用
var teleport_manager: TeleportManager
var level_manager: LevelManager
var game_manager: Node

# 在准备好时调用
func _ready():
	# 将自己添加到传送门组
	add_to_group("portal")
	
	# 初始化管理器引用
	_initialize_managers()
	
	# 设置碰撞形状
	_setup_collision_shape()
	
	# 连接信号
	connect("body_entered", _on_body_entered)
	
	# 启动持续动画效果
	_start_idle_animation()
	
	# 设置粒子效果
	_setup_particle_effects()

# 设置碰撞形状
func _setup_collision_shape():
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(40, 60) # 传送门碰撞区域大小
		collision_shape.shape = shape

func _setup_particle_effects():
	# 获取粒子系统节点
	var particle_system = get_node_or_null("ParticleSystem")
	if not particle_system:
		return
	
	# 设置核心粒子效果
	var core_particles = particle_system.get_node_or_null("CoreParticles")
	if core_particles:
		# 添加颜色渐变效果
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.2, 0.8, 1.0, 1.0))
		gradient.add_point(0.5, Color(0.5, 0.9, 1.0, 0.8))
		gradient.add_point(1.0, Color(0.1, 0.6, 1.0, 0.0))
		core_particles.color_ramp = gradient
	
	# 设置能量粒子效果
	var energy_particles = particle_system.get_node_or_null("EnergyParticles")
	if energy_particles:
		# 添加闪烁效果
		var energy_gradient = Gradient.new()
		energy_gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 0.8))
		energy_gradient.add_point(0.3, Color(0.8, 0.9, 1.0, 1.0))
		energy_gradient.add_point(0.7, Color(0.6, 0.8, 1.0, 0.9))
		energy_gradient.add_point(1.0, Color(0.4, 0.7, 1.0, 0.0))
		energy_particles.color_ramp = energy_gradient
	
	# 设置光晕粒子效果
	var glow_particles = particle_system.get_node_or_null("GlowParticles")
	if glow_particles:
		# 添加柔和的光晕效果
		var glow_gradient = Gradient.new()
		glow_gradient.add_point(0.0, Color(0.1, 0.6, 1.0, 0.5))
		glow_gradient.add_point(0.5, Color(0.2, 0.7, 1.0, 0.3))
		glow_gradient.add_point(1.0, Color(0.1, 0.5, 0.8, 0.0))
		glow_particles.color_ramp = glow_gradient

# 启动空闲状态的动画效果
func _start_idle_animation():
	# 获取传送门精灵
	var portal_sprite = get_node_or_null("PortalSprite")
	if portal_sprite:
		# 创建呼吸效果动画
		var tween = create_tween()
		tween.set_loops() # 无限循环
		tween.tween_property(portal_sprite, "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.5)
		tween.tween_property(portal_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.5)
	
	# 添加旋转动画
	if portal_sprite:
		var rotation_tween = create_tween()
		rotation_tween.set_loops()
		rotation_tween.tween_property(portal_sprite, "rotation", TAU, 8.0) # 8秒完成一圈
	
	# 粒子强度变化动画
	var particle_system = get_node_or_null("ParticleSystem")
	if particle_system:
		_animate_particles(particle_system)

# 粒子动画效果
func _animate_particles(particle_system: Node2D):
	var core_particles = particle_system.get_node_or_null("CoreParticles")
	if core_particles:
		var particle_tween = create_tween()
		particle_tween.set_loops()
		particle_tween.tween_method(_update_particle_amount.bind(core_particles), 30, 60, 2.0)
		particle_tween.tween_method(_update_particle_amount.bind(core_particles), 60, 30, 2.0)

# 更新粒子数量的辅助函数
func _update_particle_amount(particles: CPUParticles2D, amount: int):
	if particles:
		particles.amount = amount

# 当有物体进入传送门时调用
func _on_body_entered(body):
	# 检查是否为玩家
	if body.is_in_group("player") and is_active:
		# 发出信号
		body_entered.emit(body)
		
		# 防止玩家多次触发传送门
		is_active = false
		
		# 添加视觉反馈
		_play_teleport_animation()
		
		# 执行传送逻辑
		_perform_teleport(body)

# 播放传送动画
func _play_teleport_animation():
	# 获取传送门精灵
	var portal_sprite = get_node_or_null("PortalSprite")
	if portal_sprite:
		# 创建强烈的闪烁动画
		var flash_tween = create_tween()
		flash_tween.tween_property(portal_sprite, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.1)
		flash_tween.tween_property(portal_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
		flash_tween.tween_property(portal_sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.1)
		flash_tween.tween_property(portal_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	# 增强粒子效果
	var particle_system = get_node_or_null("ParticleSystem")
	if particle_system:
		_enhance_particles_for_teleport(particle_system)

# 传送时增强粒子效果
func _enhance_particles_for_teleport(particle_system: Node2D):
	var core_particles = particle_system.get_node_or_null("CoreParticles")
	if core_particles:
		# 临时增加粒子数量和速度
		var original_amount = core_particles.amount
		var original_velocity_max = core_particles.initial_velocity_max
		
		core_particles.amount = original_amount * 2
		core_particles.initial_velocity_max = original_velocity_max * 1.5
		
		# 0.5秒后恢复原状
		await get_tree().create_timer(0.5).timeout
		if core_particles:
			core_particles.amount = original_amount
			core_particles.initial_velocity_max = original_velocity_max

# 执行传送逻辑
func _perform_teleport(body):
	# 获取管理器引用
	if not teleport_manager:
		_initialize_managers()
	
	# 如果指定了目标场景，直接传送到该场景
	if destination_scene != "":
		if teleport_manager:
			teleport_manager.teleport_to_scene(destination_scene, teleport_position)
		return
	
	# 否则使用关卡管理器进入下一关
	if level_manager:
		if next_level == -1:
			level_manager.next_level()
		else:
			level_manager.load_level(next_level)
	else:
		print("警告：无法找到关卡管理器")

# 初始化管理器引用
func _initialize_managers():
	# 查找管理器节点
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		teleport_manager = game_manager.get_node_or_null("TeleportManager")
		level_manager = game_manager.get_node_or_null("LevelManager")
	
	# 如果在游戏管理器中找不到，尝试在场景树中查找
	if not teleport_manager:
		teleport_manager = get_tree().get_first_node_in_group("teleport_manager")
	if not level_manager:
		level_manager = get_tree().get_first_node_in_group("level_manager")

# 设置目标场景
func set_destination_scene(scene_path: String, position: Vector2 = Vector2.ZERO):
	destination_scene = scene_path
	teleport_position = position

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

# 配置传送门为关卡传送模式
func configure_for_level_teleport(target_level: int):
	next_level = target_level
	destination_scene = ""
	print("传送门配置为关卡传送模式，目标关卡：", target_level)

# 配置传送门为场景传送模式
func configure_for_scene_teleport(scene_path: String, position: Vector2 = Vector2.ZERO):
	destination_scene = scene_path
	teleport_position = position
	next_level = -1
	print("传送门配置为场景传送模式，目标场景：", scene_path)

# 获取传送门状态信息
func get_portal_info() -> Dictionary:
	return {
		"is_active": is_active,
		"next_level": next_level,
		"destination_scene": destination_scene,
		"teleport_position": teleport_position,
		"has_teleport_manager": teleport_manager != null,
		"has_level_manager": level_manager != null
	}

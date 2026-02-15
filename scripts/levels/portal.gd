extends Area2D

# 传送门脚本
# 用于在关卡之间传送玩家

# 传送门参数
var next_level = -1 # -1表示自动进入下一关
var is_active = true # 传送门是否激活
var is_teleporting = false # 防止重复传送的标志
var destination_scene: String = "" # 目标场景路径
var teleport_position: Vector2 = Vector2.ZERO # 传送到目标场景的位置

# Tween引用，用于清理
var breathing_tween: Tween
# var rotation_tween: Tween  # 旋转动画已禁用
var particle_tween: Tween

# 是否启用明暗呼吸效果（根据时间自动切换明暗）
@export var enable_breathing_effect: bool = false

# 管理器引用
var teleport_manager: TeleportManager
var game_manager: Node

# 在准备好时调用
func _ready():
	# 将自己添加到传送门组
	add_to_group("portal")
	
	# 初始化管理器引用
	_initialize_managers()
	
	# 设置碰撞形状
	_setup_collision_shape()
	
	# 连接信号，检查是否已经连接以避免重复连接
	if not body_entered.is_connected(_on_body_entered):
		connect("body_entered", _on_body_entered)
	
	# 启动持续动画效果
	_start_idle_animation()
	
	# 设置粒子效果
	_setup_particle_effects()
	
	# 确保传送门正确显示
	set_active(is_active)

# 设置碰撞形状
func _setup_collision_shape():
	var collision_shape = get_node("PortalCollisionShape2D")
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

# 启动持续动画效果
func _start_idle_animation():
	# 清理现有的Tween
	_cleanup_tweens()
	
	# 获取传送门精灵
	var portal_sprite = get_node_or_null("PortalSprite")
	if portal_sprite:
		# 创建呼吸效果动画（可选）
		if enable_breathing_effect:
			breathing_tween = create_tween()
			breathing_tween.set_loops() # 无限循环
			breathing_tween.tween_property(portal_sprite, "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.5)
			breathing_tween.tween_property(portal_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.5)
		else:
			portal_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
		# 旋转动画已禁用 - 根据用户要求移除旋转效果
		# rotation_tween = create_tween()
		# rotation_tween.set_loops()
		# rotation_tween.tween_property(portal_sprite, "rotation", TAU, 8.0) # 8秒完成一圈
	
	# 粒子强度变化动画
	var particle_system = get_node_or_null("ParticleSystem")
	if particle_system:
		_animate_particles(particle_system)

# 粒子动画效果
func _animate_particles(particle_system: Node2D):
	var core_particles = particle_system.get_node_or_null("CoreParticles")
	if core_particles:
		particle_tween = create_tween()
		particle_tween.set_loops()
		particle_tween.tween_method(_update_particle_amount.bind(core_particles), 30, 60, 2.0)
		particle_tween.tween_method(_update_particle_amount.bind(core_particles), 60, 30, 2.0)

# 清理Tween资源
func _cleanup_tweens():
	if breathing_tween and breathing_tween.is_valid():
		breathing_tween.kill()
		breathing_tween = null
	
	# 旋转动画已禁用，无需清理
	# if rotation_tween and rotation_tween.is_valid():
	#	rotation_tween.kill()
	#	rotation_tween = null
	
	if particle_tween and particle_tween.is_valid():
		particle_tween.kill()
		particle_tween = null

# 节点退出场景树时清理资源
func _exit_tree():
	_cleanup_tweens()

# 更新粒子数量的辅助函数
func _update_particle_amount(amount: int, particles: CPUParticles2D):
	if particles:
		particles.amount = amount

# 当有物体进入传送门时调用
func _on_body_entered(body):
	# 检查是否为玩家，并且传送门激活且未在传送中
	if body.is_in_group("player") and is_active and not is_teleporting:
		print("[Portal] 玩家进入传送门! 目标: ", destination_scene if destination_scene != "" else "下一关")
		# 设置传送标志，防止重复触发
		is_teleporting = true
		is_active = false
		
		# 发出信号
		body_entered.emit(body)
		
		# 添加视觉反馈
		_play_teleport_animation()
		
		# 使用 call_deferred 延迟执行传送逻辑，避免在物理回调中直接操作
		call_deferred("_perform_teleport", body)

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
		var tree = get_tree()
		if tree:
			await tree.create_timer(0.5).timeout
		else:
			print("[Portal] 警告：场景树无效，跳过粒子效果恢复延迟")
		if core_particles:
			core_particles.amount = original_amount
			core_particles.initial_velocity_max = original_velocity_max

# 执行传送逻辑
func _perform_teleport(_body):
	# 获取管理器引用
	if not teleport_manager:
		_initialize_managers()
	
	# 传送前自动保存游戏进度
	if SaveManager:
		SaveManager.trigger_auto_save()
		print("[Portal] 传送前自动保存完成")
	
	# 如果指定了目标场景，直接传送到该场景
	if destination_scene != "":
		if teleport_manager:
			teleport_manager.teleport_to_scene(destination_scene, teleport_position)
		else:
			print("错误：无法找到传送管理器")
			_reset_teleport_state()
		return
	
	# 回退：直接使用场景树切换
	print("[Portal] 无目标场景且无传送管理器，重置状态")
	_reset_teleport_state()

# 重置传送状态的辅助函数
func _reset_teleport_state():
	is_teleporting = false
	is_active = true

# 初始化管理器引用
func _initialize_managers():
	# 检查场景树是否有效
	var tree = get_tree()
	if not tree:
		print("[Portal] 错误：场景树无效，无法初始化管理器")
		return
	
	# 优先从组中查找传送管理器（TeleportManager在UI系统中创建）
	teleport_manager = tree.get_first_node_in_group("teleport_manager")
	
	# 查找游戏管理器节点
	game_manager = tree.get_first_node_in_group("game_manager")
	
	# 如果在组中没找到，从GameManager子节点中查找
	if not teleport_manager and game_manager:
		teleport_manager = game_manager.get_node_or_null("TeleportManager")
	
	# 连接传送完成信号，以便重新激活传送门
	if teleport_manager and not teleport_manager.teleport_completed.is_connected(_on_teleport_completed):
		teleport_manager.teleport_completed.connect(_on_teleport_completed)

# 传送完成后重新激活传送门
func _on_teleport_completed(_player: Node2D, _destination: Vector2):
	# 检查节点是否仍在场景树中
	if not is_inside_tree():
		print("[Portal] 警告：节点不在场景树中，跳过处理")
		return
	
	# 安全获取场景树
	var tree = get_tree()
	if not tree:
		# 如果当前节点的场景树无效，尝试从引擎获取
		tree = Engine.get_main_loop() as SceneTree
	
	if tree:
		# 延迟重新激活，避免立即重复触发
		await tree.create_timer(1.0).timeout
	else:
		print("[Portal] 警告：无法获取有效的场景树，跳过延迟")
	
	# 重置传送标志和激活状态
	is_teleporting = false
	is_active = true
	

# 设置目标场景
func set_destination_scene(scene_path: String, spawn_position: Vector2 = Vector2.ZERO):
	destination_scene = scene_path
	teleport_position = spawn_position

# 设置下一关卡
func set_next_level(level):
	next_level = level

# 设置传送门激活状态
func set_active(active):
	is_active = active
	
	# 更新传送门精灵的视觉效果
	var portal_sprite = get_node_or_null("PortalSprite")
	if portal_sprite:
		portal_sprite.modulate = Color(1, 1, 1, 1) if active else Color(0.5, 0.5, 0.5, 0.5)
	
	# 更新粒子系统
	var particle_system = get_node_or_null("ParticleSystem")
	if particle_system:
		for child in particle_system.get_children():
			if child is CPUParticles2D:
				child.emitting = active
	
	# 更新其他视觉效果
	for child in get_children():
		if child is ColorRect:
			child.modulate = Color(1, 1, 1, 1) if active else Color(0.5, 0.5, 0.5, 0.5)

# 配置传送门为关卡传送模式
func configure_for_level_teleport(target_level: int):
	next_level = target_level
	destination_scene = ""
	print("传送门配置为关卡传送模式，目标关卡：", target_level)

# 配置传送门为场景传送模式
func configure_for_scene_teleport(scene_path: String, spawn_position: Vector2 = Vector2.ZERO):
	destination_scene = scene_path
	teleport_position = spawn_position
	next_level = -1
	print("传送门配置为场景传送模式，目标场景：", scene_path)

# 获取传送门状态信息
func get_portal_info() -> Dictionary:
	return {
		"is_active": is_active,
		"next_level": next_level,
		"destination_scene": destination_scene,
		"teleport_position": teleport_position,
		"has_teleport_manager": teleport_manager != null
	}

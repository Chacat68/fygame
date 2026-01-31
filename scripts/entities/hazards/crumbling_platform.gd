class_name CrumblingPlatform
extends AnimatableBody2D

## 破碎平台
## 死亡细胞风格的易碎平台，踩上后会开始崩塌

# 信号
signal platform_crumbling
signal platform_collapsed
signal platform_restored

@export_group("破碎设置")
@export var crumble_delay: float = 0.5  # 开始崩塌前的延迟
@export var fall_speed: float = 200.0  # 下落速度
@export var fall_distance: float = 100.0  # 下落距离后消失
@export var respawn_time: float = 3.0  # 重生时间（0=不重生）

@export_group("视觉效果")
@export var shake_before_fall: bool = true  # 下落前震动
@export var shake_intensity: float = 2.0  # 震动强度
@export var spawn_particles: bool = true  # 产生碎片粒子

# 状态
enum PlatformState {
	STABLE,
	CRUMBLING,
	FALLING,
	COLLAPSED
}
var current_state: PlatformState = PlatformState.STABLE
var _original_position: Vector2
var _fall_progress: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

# 组件引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var player_detector: Area2D = $PlayerDetector if has_node("PlayerDetector") else null

func _ready() -> void:
	add_to_group("crumbling_platform")
	
	_original_position = position
	
	# 设置玩家检测区域
	_setup_player_detector()

func _setup_player_detector() -> void:
	if not player_detector:
		player_detector = Area2D.new()
		player_detector.name = "PlayerDetector"
		add_child(player_detector)
		
		# 创建检测形状（比平台稍大一点）
		var shape = CollisionShape2D.new()
		if collision_shape and collision_shape.shape:
			shape.shape = collision_shape.shape.duplicate()
			# 稍微向上偏移以检测站在上面的玩家
			shape.position = Vector2(0, -5)
		else:
			var rect = RectangleShape2D.new()
			rect.size = Vector2(32, 10)
			shape.shape = rect
			shape.position = Vector2(0, -5)
		
		player_detector.add_child(shape)
	
	player_detector.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_state != PlatformState.STABLE:
		return
	
	# 开始崩塌倒计时
	start_crumbling()

func start_crumbling() -> void:
	if current_state != PlatformState.STABLE:
		return
	
	current_state = PlatformState.CRUMBLING
	platform_crumbling.emit()
	
	# 开始震动
	if shake_before_fall:
		_start_shaking()
	
	# 延迟后开始下落
	await get_tree().create_timer(crumble_delay).timeout
	_start_falling()

func _start_shaking() -> void:
	var tween = create_tween()
	tween.set_loops(int(crumble_delay / 0.05))
	tween.tween_callback(_random_shake)
	tween.tween_interval(0.05)

func _random_shake() -> void:
	_shake_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	position = _original_position + _shake_offset

func _start_falling() -> void:
	current_state = PlatformState.FALLING
	_fall_progress = 0.0
	
	# 产生碎片粒子
	if spawn_particles:
		_spawn_crumble_particles()

func _process(delta: float) -> void:
	if current_state == PlatformState.FALLING:
		_fall_progress += fall_speed * delta
		position.y = _original_position.y + _fall_progress
		
		# 逐渐透明
		if sprite:
			sprite.modulate.a = 1.0 - (_fall_progress / fall_distance)
		
		# 检查是否完全下落
		if _fall_progress >= fall_distance:
			_collapse()

func _collapse() -> void:
	current_state = PlatformState.COLLAPSED
	platform_collapsed.emit()
	
	# 禁用碰撞
	if collision_shape:
		collision_shape.disabled = true
	
	# 隐藏
	visible = false
	
	# 重生
	if respawn_time > 0:
		await get_tree().create_timer(respawn_time).timeout
		_restore()

func _restore() -> void:
	current_state = PlatformState.STABLE
	position = _original_position
	_fall_progress = 0.0
	_shake_offset = Vector2.ZERO
	
	# 启用碰撞
	if collision_shape:
		collision_shape.disabled = false
	
	# 显示
	visible = true
	if sprite:
		sprite.modulate.a = 1.0
	
	platform_restored.emit()
	
	# 淡入效果
	_play_restore_effect()

func _play_restore_effect() -> void:
	if sprite:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func _spawn_crumble_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.8
	particles.explosiveness = 0.8
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 30.0
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 50.0
	particle_material.gravity = Vector3(0, 300, 0)
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.5
	
	# 灰色碎片
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.6, 0.6, 0.6, 1.0))
	gradient.set_color(1, Color(0.4, 0.4, 0.4, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture
	
	particles.process_material = particle_material
	particles.position = Vector2.ZERO
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# 自动清理
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

## 立即崩塌（外部触发）
func force_collapse() -> void:
	if current_state == PlatformState.STABLE:
		_start_falling()
	elif current_state == PlatformState.CRUMBLING:
		_start_falling()

## 重置平台
func reset() -> void:
	_restore()

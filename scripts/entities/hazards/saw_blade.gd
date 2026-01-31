class_name SawBlade
extends "res://scripts/entities/hazards/hazard_base.gd"

## 旋转锯片陷阱
## 死亡细胞风格的旋转锯片，可沿路径移动或原地旋转

# 锯片类型
enum SawType {
	STATIONARY,   # 原地旋转
	LINEAR,       # 线性往返移动
	CIRCULAR,     # 圆形路径移动
	PATH          # 沿 Path2D 移动
}

@export_group("锯片设置")
@export var saw_type: SawType = SawType.STATIONARY
@export var rotation_speed: float = 360.0  # 旋转速度（度/秒）
@export var saw_radius: float = 16.0  # 锯片半径

@export_group("移动设置")
@export var move_speed: float = 100.0  # 移动速度
@export var move_distance: float = 100.0  # 移动距离（LINEAR模式）
@export var circular_radius: float = 50.0  # 圆形路径半径（CIRCULAR模式）
@export var path_node: NodePath  # Path2D节点路径（PATH模式）
@export var ping_pong: bool = true  # 是否往返移动

@export_group("视觉效果")
@export var trail_enabled: bool = true  # 显示拖尾效果
@export var spark_on_contact: bool = true  # 接触时产生火花

# 内部变量
var _start_position: Vector2
var _move_direction: int = 1
var _move_progress: float = 0.0
var _circular_angle: float = 0.0
var _path_follow: PathFollow2D = null

# 锯片精灵（单独旋转）- 可以是 Sprite2D、Polygon2D 或其他 CanvasItem
var _saw_sprite: CanvasItem = null

func _hazard_ready() -> void:
	_start_position = global_position
	
	# 锯片始终激活
	is_active = true
	can_kill_instantly = false
	damage = 1
	damage_cooldown = 0.3
	
	# 获取锯片精灵
	if has_node("SawSprite"):
		_saw_sprite = $SawSprite
	elif animated_sprite:
		_saw_sprite = animated_sprite
	
	# 设置路径模式
	if saw_type == SawType.PATH and path_node:
		_setup_path_follow()
	
	# 启用拖尾
	if trail_enabled:
		_setup_trail()

func _setup_path_follow() -> void:
	var path = get_node_or_null(path_node)
	if path and path is Path2D:
		_path_follow = PathFollow2D.new()
		_path_follow.loop = not ping_pong
		_path_follow.rotates = false
		path.add_child(_path_follow)

func _setup_trail() -> void:
	# 创建简单的拖尾效果
	var trail = Line2D.new()
	trail.name = "Trail"
	trail.width = saw_radius * 0.5
	trail.default_color = Color(1, 0.5, 0, 0.5)
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(trail)

func _process(delta: float) -> void:
	# 旋转锯片
	_rotate_saw(delta)
	
	# 移动锯片
	_move_saw(delta)
	
	# 更新拖尾
	if trail_enabled:
		_update_trail()

func _rotate_saw(delta: float) -> void:
	if _saw_sprite:
		_saw_sprite.rotation_degrees += rotation_speed * delta
	elif animated_sprite:
		animated_sprite.rotation_degrees += rotation_speed * delta

func _move_saw(delta: float) -> void:
	match saw_type:
		SawType.STATIONARY:
			pass  # 不移动
		SawType.LINEAR:
			_move_linear(delta)
		SawType.CIRCULAR:
			_move_circular(delta)
		SawType.PATH:
			_move_path(delta)

func _move_linear(delta: float) -> void:
	_move_progress += move_speed * delta * _move_direction
	
	# 检查边界
	if _move_progress >= move_distance:
		_move_progress = move_distance
		if ping_pong:
			_move_direction = -1
		else:
			_move_progress = 0
	elif _move_progress <= 0:
		_move_progress = 0
		_move_direction = 1
	
	# 更新位置（默认水平移动）
	global_position = _start_position + Vector2(_move_progress, 0)

func _move_circular(delta: float) -> void:
	_circular_angle += move_speed * delta * 0.01
	
	var offset = Vector2(
		cos(_circular_angle) * circular_radius,
		sin(_circular_angle) * circular_radius
	)
	
	global_position = _start_position + offset

func _move_path(delta: float) -> void:
	if not _path_follow:
		return
	
	_path_follow.progress += move_speed * delta * _move_direction
	
	# 检查往返
	if ping_pong:
		var path = _path_follow.get_parent() as Path2D
		if path:
			var max_progress = path.curve.get_baked_length()
			if _path_follow.progress >= max_progress:
				_path_follow.progress = max_progress
				_move_direction = -1
			elif _path_follow.progress <= 0:
				_path_follow.progress = 0
				_move_direction = 1
	
	global_position = _path_follow.global_position

func _update_trail() -> void:
	var trail = get_node_or_null("Trail") as Line2D
	if not trail:
		return
	
	# 添加当前位置
	trail.add_point(Vector2.ZERO)
	
	# 限制拖尾长度
	while trail.get_point_count() > 10:
		trail.remove_point(0)

## 重写伤害应用，添加火花效果
func _apply_damage(player: Node2D) -> void:
	super._apply_damage(player)
	
	if spark_on_contact:
		_spawn_sparks()

func _spawn_sparks() -> void:
	# 创建简单的火花粒子效果
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	
	# 简单的粒子材质
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 100.0
	particle_material.gravity = Vector3(0, 200, 0)
	particle_material.color = Color.ORANGE
	particles.process_material = particle_material
	
	add_child(particles)
	
	# 自动清理
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

func _on_reset() -> void:
	global_position = _start_position
	_move_direction = 1
	_move_progress = 0.0
	_circular_angle = 0.0

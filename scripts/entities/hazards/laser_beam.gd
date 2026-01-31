class_name LaserBeam
extends Node2D

## 激光束陷阱
## 死亡细胞风格的激光，可以是持续或脉冲式的

# 激光类型
enum LaserType {
	CONTINUOUS,    # 持续激光
	PULSING,       # 脉冲激光
	ROTATING,      # 旋转激光
	TRIGGERED      # 触发式激光
}

# 信号
signal laser_activated
signal laser_deactivated
signal player_hit

@export_group("激光设置")
@export var laser_type: LaserType = LaserType.CONTINUOUS
@export var laser_length: float = 200.0  # 激光长度
@export var laser_width: float = 4.0  # 激光宽度
@export var damage: int = 1  # 伤害
@export var damage_cooldown: float = 0.5  # 伤害间隔

@export_group("脉冲设置")
@export var on_duration: float = 2.0  # 激活持续时间
@export var off_duration: float = 1.0  # 关闭持续时间
@export var warning_time: float = 0.5  # 警告时间
@export var initial_delay: float = 0.0  # 初始延迟

@export_group("旋转设置")
@export var rotation_speed: float = 45.0  # 旋转速度（度/秒）
@export var rotation_range: float = 180.0  # 旋转范围
@export var ping_pong_rotation: bool = true  # 往返旋转

@export_group("视觉效果")
@export var laser_color: Color = Color.RED
@export var warning_color: Color = Color(1, 0.5, 0, 0.5)

# 状态
var is_active: bool = false
var _state_timer: float = 0.0
var _current_phase: String = "off"  # off, warning, on
var _rotation_direction: int = 1
var _current_rotation: float = 0.0
var _can_damage: bool = true

# 组件
var _laser_line: Line2D
var _raycast: RayCast2D
var _hit_area: Area2D

func _ready() -> void:
	add_to_group("laser")
	
	_create_laser_components()
	
	# 初始化状态
	match laser_type:
		LaserType.CONTINUOUS:
			_activate_laser()
		LaserType.PULSING:
			_state_timer = initial_delay if initial_delay > 0 else off_duration
			_current_phase = "off"
			_deactivate_laser()
		LaserType.ROTATING:
			_activate_laser()
		LaserType.TRIGGERED:
			_deactivate_laser()

func _create_laser_components() -> void:
	# 创建激光线
	_laser_line = Line2D.new()
	_laser_line.name = "LaserLine"
	_laser_line.width = laser_width
	_laser_line.default_color = laser_color
	_laser_line.add_point(Vector2.ZERO)
	_laser_line.add_point(Vector2(laser_length, 0))
	add_child(_laser_line)
	
	# 创建射线检测
	_raycast = RayCast2D.new()
	_raycast.name = "LaserRay"
	_raycast.target_position = Vector2(laser_length, 0)
	_raycast.collision_mask = 1 | 2  # 地形和玩家
	_raycast.enabled = true
	add_child(_raycast)
	
	# 创建伤害区域
	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_mask = 2  # 玩家层
	add_child(_hit_area)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(laser_length, laser_width * 2)
	shape.shape = rect
	shape.position = Vector2(laser_length / 2, 0)
	_hit_area.add_child(shape)
	
	_hit_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# 处理脉冲激光
	if laser_type == LaserType.PULSING:
		_process_pulsing(delta)
	
	# 处理旋转激光
	if laser_type == LaserType.ROTATING:
		_process_rotation(delta)
	
	# 更新激光终点（检测碰撞）
	if is_active:
		_update_laser_endpoint()

func _process_pulsing(delta: float) -> void:
	_state_timer -= delta
	
	if _state_timer <= 0:
		match _current_phase:
			"off":
				_current_phase = "warning"
				_state_timer = warning_time
				_show_warning()
			"warning":
				_current_phase = "on"
				_state_timer = on_duration
				_activate_laser()
			"on":
				_current_phase = "off"
				_state_timer = off_duration
				_deactivate_laser()

func _process_rotation(delta: float) -> void:
	_current_rotation += rotation_speed * delta * _rotation_direction
	
	if ping_pong_rotation:
		if _current_rotation >= rotation_range / 2:
			_current_rotation = rotation_range / 2
			_rotation_direction = -1
		elif _current_rotation <= -rotation_range / 2:
			_current_rotation = -rotation_range / 2
			_rotation_direction = 1
	
	rotation_degrees = _current_rotation

func _update_laser_endpoint() -> void:
	_raycast.force_raycast_update()
	
	var end_point = Vector2(laser_length, 0)
	
	if _raycast.is_colliding():
		var collision_point = _raycast.get_collision_point()
		end_point = to_local(collision_point)
	
	# 更新激光线
	_laser_line.set_point_position(1, end_point)
	
	# 更新碰撞区域
	var shape = _hit_area.get_child(0) as CollisionShape2D
	if shape:
		var rect = shape.shape as RectangleShape2D
		rect.size.x = end_point.x
		shape.position.x = end_point.x / 2

func _show_warning() -> void:
	# 显示警告（闪烁的虚线）
	_laser_line.visible = true
	_laser_line.default_color = warning_color
	_laser_line.width = laser_width * 0.5
	
	# 闪烁效果
	var tween = create_tween()
	tween.set_loops(int(warning_time / 0.1))
	tween.tween_property(_laser_line, "modulate:a", 0.3, 0.05)
	tween.tween_property(_laser_line, "modulate:a", 1.0, 0.05)

func _activate_laser() -> void:
	is_active = true
	laser_activated.emit()
	
	_laser_line.visible = true
	_laser_line.default_color = laser_color
	_laser_line.width = laser_width
	_laser_line.modulate.a = 1.0
	
	# 启用碰撞
	_hit_area.get_child(0).disabled = false

func _deactivate_laser() -> void:
	is_active = false
	laser_deactivated.emit()
	
	_laser_line.visible = false
	
	# 禁用碰撞
	_hit_area.get_child(0).disabled = true

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	
	if not body.is_in_group("player"):
		return
	
	if not _can_damage:
		return
	
	# 造成伤害
	if body.has_method("take_damage"):
		body.take_damage(damage)
		player_hit.emit()
		
		# 冷却
		_can_damage = false
		await get_tree().create_timer(damage_cooldown).timeout
		_can_damage = true

## 触发激光（用于 TRIGGERED 类型）
func trigger(duration: float = 1.0) -> void:
	if laser_type != LaserType.TRIGGERED:
		return
	
	_activate_laser()
	await get_tree().create_timer(duration).timeout
	_deactivate_laser()

## 重置激光
func reset() -> void:
	_state_timer = initial_delay if initial_delay > 0 else off_duration
	_current_phase = "off"
	_current_rotation = 0.0
	_rotation_direction = 1
	rotation_degrees = 0
	
	if laser_type == LaserType.CONTINUOUS or laser_type == LaserType.ROTATING:
		_activate_laser()
	else:
		_deactivate_laser()

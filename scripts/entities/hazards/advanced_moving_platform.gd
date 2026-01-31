class_name AdvancedMovingPlatform
extends AnimatableBody2D

## 高级移动平台
## 死亡细胞风格的移动平台，支持多种移动模式和特殊行为

# 移动模式
enum MoveMode {
	LINEAR,          # 线性往返
	CIRCULAR,        # 圆形运动
	PATH,            # 沿路径移动
	ELEVATOR,        # 电梯模式（需要触发）
	CONVEYOR         # 传送带（站上后推动玩家）
}

# 信号
signal platform_moved(new_position: Vector2)
signal player_mounted(player: Node2D)
signal player_dismounted(player: Node2D)

@export_group("移动设置")
@export var move_mode: MoveMode = MoveMode.LINEAR
@export var move_speed: float = 50.0  # 移动速度
@export var move_distance: float = 100.0  # 移动距离（LINEAR模式）
@export var move_direction: Vector2 = Vector2.RIGHT  # 移动方向

@export_group("圆形运动设置")
@export var circular_radius: float = 50.0  # 圆形半径
@export var clockwise: bool = true  # 是否顺时针

@export_group("路径设置")
@export var path_node: NodePath  # Path2D节点

@export_group("电梯设置")
@export var elevator_wait_time: float = 1.0  # 到达后等待时间
@export var auto_return: bool = true  # 是否自动返回
@export var require_player: bool = true  # 是否需要玩家在上面才移动

@export_group("传送带设置")
@export var conveyor_force: float = 100.0  # 传送带推力
@export var conveyor_direction: Vector2 = Vector2.RIGHT

@export_group("行为设置")
@export var ping_pong: bool = true  # 往返移动
@export var pause_at_ends: float = 0.5  # 端点暂停时间
@export var start_delay: float = 0.0  # 启动延迟
@export var sync_id: String = ""  # 同步ID（相同ID的平台同步移动）

# 状态
var _start_position: Vector2
var _move_progress: float = 0.0
var _move_direction_sign: int = 1
var _circular_angle: float = 0.0
var _path_follow: PathFollow2D = null
var _is_paused: bool = false
var _pause_timer: float = 0.0
var _player_on_platform: Node2D = null
var _is_at_start: bool = true  # 电梯模式用

# 组件引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var player_detector: Area2D = $PlayerDetector if has_node("PlayerDetector") else null

func _ready() -> void:
	add_to_group("moving_platform")
	
	_start_position = global_position
	
	# 设置玩家检测
	_setup_player_detector()
	
	# 设置路径跟随
	if move_mode == MoveMode.PATH:
		_setup_path_follow()
	
	# 启动延迟
	if start_delay > 0:
		_is_paused = true
		_pause_timer = start_delay

func _setup_player_detector() -> void:
	if not player_detector:
		player_detector = Area2D.new()
		player_detector.name = "PlayerDetector"
		add_child(player_detector)
		
		var shape = CollisionShape2D.new()
		if collision_shape and collision_shape.shape:
			shape.shape = collision_shape.shape.duplicate()
			shape.position = Vector2(0, -5)
		else:
			var rect = RectangleShape2D.new()
			rect.size = Vector2(32, 10)
			shape.shape = rect
			shape.position = Vector2(0, -5)
		
		player_detector.add_child(shape)
	
	player_detector.body_entered.connect(_on_player_entered)
	player_detector.body_exited.connect(_on_player_exited)

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_on_platform = body
		player_mounted.emit(body)

func _on_player_exited(body: Node2D) -> void:
	if body == _player_on_platform:
		player_dismounted.emit(body)
		_player_on_platform = null

func _setup_path_follow() -> void:
	var path = get_node_or_null(path_node)
	if path and path is Path2D:
		_path_follow = PathFollow2D.new()
		_path_follow.loop = not ping_pong
		_path_follow.rotates = false
		path.add_child(_path_follow)

func _physics_process(delta: float) -> void:
	# 处理暂停
	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0:
			_is_paused = false
		return
	
	# 电梯模式特殊处理
	if move_mode == MoveMode.ELEVATOR:
		if require_player and not _player_on_platform:
			return
	
	# 传送带效果
	if move_mode == MoveMode.CONVEYOR and _player_on_platform:
		_apply_conveyor_force()
	
	# 移动平台
	var old_position = global_position
	_move_platform(delta)
	
	# 发射移动信号
	if global_position != old_position:
		platform_moved.emit(global_position)

func _move_platform(delta: float) -> void:
	match move_mode:
		MoveMode.LINEAR:
			_move_linear(delta)
		MoveMode.CIRCULAR:
			_move_circular(delta)
		MoveMode.PATH:
			_move_path(delta)
		MoveMode.ELEVATOR:
			_move_elevator(delta)
		MoveMode.CONVEYOR:
			_move_linear(delta)  # 传送带也可以移动

func _move_linear(delta: float) -> void:
	_move_progress += move_speed * delta * _move_direction_sign
	
	# 检查边界
	if _move_progress >= move_distance:
		_move_progress = move_distance
		if ping_pong:
			_move_direction_sign = -1
			_start_pause()
		else:
			_move_progress = 0
	elif _move_progress <= 0:
		_move_progress = 0
		_move_direction_sign = 1
		_start_pause()
	
	global_position = _start_position + move_direction.normalized() * _move_progress

func _move_circular(delta: float) -> void:
	var direction = 1 if clockwise else -1
	_circular_angle += move_speed * delta * 0.02 * direction
	
	var offset = Vector2(
		cos(_circular_angle) * circular_radius,
		sin(_circular_angle) * circular_radius
	)
	
	global_position = _start_position + offset

func _move_path(delta: float) -> void:
	if not _path_follow:
		return
	
	_path_follow.progress += move_speed * delta * _move_direction_sign
	
	var path = _path_follow.get_parent() as Path2D
	if path and ping_pong:
		var max_progress = path.curve.get_baked_length()
		if _path_follow.progress >= max_progress:
			_path_follow.progress = max_progress
			_move_direction_sign = -1
			_start_pause()
		elif _path_follow.progress <= 0:
			_path_follow.progress = 0
			_move_direction_sign = 1
			_start_pause()
	
	global_position = _path_follow.global_position

func _move_elevator(delta: float) -> void:
	_move_progress += move_speed * delta * _move_direction_sign
	
	# 检查是否到达目的地
	if _move_progress >= move_distance:
		_move_progress = move_distance
		_is_at_start = false
		_start_pause()
		_pause_timer = elevator_wait_time
		
		if auto_return:
			_move_direction_sign = -1
	elif _move_progress <= 0:
		_move_progress = 0
		_is_at_start = true
		_start_pause()
		_pause_timer = elevator_wait_time
		
		_move_direction_sign = 1
	
	global_position = _start_position + move_direction.normalized() * _move_progress

func _start_pause() -> void:
	if pause_at_ends > 0:
		_is_paused = true
		_pause_timer = pause_at_ends

func _apply_conveyor_force() -> void:
	if _player_on_platform and _player_on_platform is CharacterBody2D:
		_player_on_platform.velocity += conveyor_direction.normalized() * conveyor_force * get_physics_process_delta_time()

## 电梯模式：呼叫电梯到当前位置
func call_elevator() -> void:
	if move_mode != MoveMode.ELEVATOR:
		return
	
	if _is_at_start:
		_move_direction_sign = 1
	else:
		_move_direction_sign = -1

## 重置平台
func reset() -> void:
	global_position = _start_position
	_move_progress = 0.0
	_move_direction_sign = 1
	_circular_angle = 0.0
	_is_paused = false
	_is_at_start = true

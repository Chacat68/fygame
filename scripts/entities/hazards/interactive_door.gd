class_name InteractiveDoor
extends Node2D

## 互动门/开关门系统
## 死亡细胞风格的门机关，支持多种触发方式

# 门类型
enum DoorType {
	ONE_WAY,       # 单向门（只能从一侧通过）
	SWITCH,        # 开关门（需要机关触发）
	KEY,           # 钥匙门（需要钥匙）
	TIMED,         # 限时门（开启后一段时间关闭）
	KILL_ALL       # 清怪门（杀死所有敌人后开启）
}

# 门状态
enum DoorState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING
}

# 信号
signal door_opened
signal door_closed
signal door_state_changed(new_state: DoorState)

@export_group("门设置")
@export var door_type: DoorType = DoorType.SWITCH
@export var door_id: String = ""  # 用于开关链接
@export var starts_open: bool = false

@export_group("单向门设置")
@export var one_way_direction: Vector2 = Vector2.RIGHT  # 允许通过的方向

@export_group("限时门设置")
@export var open_duration: float = 3.0  # 开启持续时间
@export var show_timer_warning: bool = true  # 显示关门警告

@export_group("钥匙门设置")
@export var required_key_id: String = ""  # 需要的钥匙ID

@export_group("动画设置")
@export var open_time: float = 0.3
@export var close_time: float = 0.3

# 状态
var current_state: DoorState = DoorState.CLOSED
var _timer: float = 0.0
var _linked_switches: Array[Node] = []

# 组件引用
@onready var door_body: StaticBody2D = $DoorBody if has_node("DoorBody") else null
@onready var collision_shape: CollisionShape2D = $DoorBody/CollisionShape2D if has_node("DoorBody/CollisionShape2D") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var one_way_detector: Area2D = $OneWayDetector if has_node("OneWayDetector") else null

func _ready() -> void:
	add_to_group("door")
	
	# 生成ID
	if door_id == "":
		door_id = "door_%d" % get_instance_id()
	
	# 设置初始状态
	if starts_open:
		_set_open_state(true)
	else:
		_set_open_state(false)
	
	# 设置单向门检测
	if door_type == DoorType.ONE_WAY:
		_setup_one_way_detector()
	
	# 设置清怪门
	if door_type == DoorType.KILL_ALL:
		_setup_kill_all_check()

func _process(delta: float) -> void:
	# 处理限时门
	if door_type == DoorType.TIMED and current_state == DoorState.OPEN:
		_timer -= delta
		
		if show_timer_warning and _timer <= 1.0 and _timer > 0:
			_play_warning_effect()
		
		if _timer <= 0:
			close_door()

## 开门
func open_door() -> void:
	if current_state == DoorState.OPEN or current_state == DoorState.OPENING:
		return
	
	current_state = DoorState.OPENING
	door_state_changed.emit(current_state)
	
	# 播放开门动画
	_play_open_animation()
	
	await get_tree().create_timer(open_time).timeout
	
	_set_open_state(true)
	current_state = DoorState.OPEN
	door_state_changed.emit(current_state)
	door_opened.emit()
	
	# 限时门开始计时
	if door_type == DoorType.TIMED:
		_timer = open_duration

## 关门
func close_door() -> void:
	if current_state == DoorState.CLOSED or current_state == DoorState.CLOSING:
		return
	
	current_state = DoorState.CLOSING
	door_state_changed.emit(current_state)
	
	# 播放关门动画
	_play_close_animation()
	
	await get_tree().create_timer(close_time).timeout
	
	_set_open_state(false)
	current_state = DoorState.CLOSED
	door_state_changed.emit(current_state)
	door_closed.emit()

## 切换门状态
func toggle_door() -> void:
	if current_state == DoorState.CLOSED:
		open_door()
	elif current_state == DoorState.OPEN:
		close_door()

## 尝试用钥匙开门
func try_open_with_key(key_id: String) -> bool:
	if door_type != DoorType.KEY:
		return false
	
	if key_id == required_key_id:
		open_door()
		return true
	
	return false

func _set_open_state(is_open: bool) -> void:
	if collision_shape:
		collision_shape.disabled = is_open
	
	# 更新视觉
	if animated_sprite:
		if is_open:
			animated_sprite.modulate.a = 0.3  # 半透明表示开启
		else:
			animated_sprite.modulate.a = 1.0

func _play_open_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("open"):
			animated_sprite.play("open")
			return
	
	# 默认动画：向上滑动
	var tween = create_tween()
	if door_body:
		var target_pos = door_body.position + Vector2(0, -32)
		tween.tween_property(door_body, "position", target_pos, open_time)

func _play_close_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("close"):
			animated_sprite.play("close")
			return
	
	# 默认动画：向下滑动
	var tween = create_tween()
	if door_body:
		var target_pos = door_body.position + Vector2(0, 32)
		tween.tween_property(door_body, "position", target_pos, close_time)

func _play_warning_effect() -> void:
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func _setup_one_way_detector() -> void:
	if not one_way_detector:
		# 创建单向检测区域
		one_way_detector = Area2D.new()
		one_way_detector.name = "OneWayDetector"
		add_child(one_way_detector)
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(16, 32)
		shape.shape = rect
		shape.position = one_way_direction * 20
		one_way_detector.add_child(shape)
	
	one_way_detector.body_entered.connect(_on_one_way_body_entered)

func _on_one_way_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if door_type != DoorType.ONE_WAY:
		return
	
	# 检查玩家是否从正确方向进入
	if body is CharacterBody2D:
		var player_direction = body.velocity.normalized()
		if player_direction.dot(one_way_direction) > 0.5:
			# 暂时开门让玩家通过
			open_door()
			await get_tree().create_timer(0.5).timeout
			close_door()

func _setup_kill_all_check() -> void:
	# 定期检查是否所有敌人都被消灭
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_check_enemies_cleared)
	add_child(timer)
	timer.start()

func _check_enemies_cleared() -> void:
	if door_type != DoorType.KILL_ALL:
		return
	
	if current_state != DoorState.CLOSED:
		return
	
	# 检查场景中是否还有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		open_door()

## 链接开关
func link_switch(switch_node: Node) -> void:
	if switch_node not in _linked_switches:
		_linked_switches.append(switch_node)
		if switch_node.has_signal("activated"):
			switch_node.activated.connect(_on_switch_activated)

func _on_switch_activated() -> void:
	toggle_door()

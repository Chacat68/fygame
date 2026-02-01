# 蝙蝠敌人
# 会飞行的敌人，可以在空中巡逻和追击玩家
class_name Bat
extends EnemyBase

@export_group("蝙蝠特性")
@export var fly_speed: float = 60.0
@export var hover_amplitude: float = 20.0  # 悬停振幅
@export var hover_frequency: float = 2.0   # 悬停频率
@export var dive_speed: float = 150.0      # 俯冲速度
@export var return_to_patrol_time: float = 3.0

# 蝙蝠特有变量
var patrol_center: Vector2
var hover_offset: float = 0.0
var dive_timer: float = 0.0
var is_diving: bool = false

func _ready() -> void:
	# 设置蝙蝠属性
	max_health = 10
	move_speed = fly_speed
	chase_speed = dive_speed
	damage = 8
	detection_range = 120.0
	can_chase = true
	can_jump = false
	
	coin_drop_min = 2
	coin_drop_max = 5
	
	super._ready()
	
	# 记录初始位置作为巡逻中心
	patrol_center = global_position
	
	# 蝙蝠不需要地面检测
	_disable_floor_checks()

func _disable_floor_checks() -> void:
	var floor_right = get_node_or_null("FloorCheckRight")
	var floor_left = get_node_or_null("FloorCheckLeft")
	if floor_right:
		floor_right.enabled = false
	if floor_left:
		floor_left.enabled = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 蝙蝠不受重力影响（除非死亡）
	# 不调用父类的 _physics_process，而是自己处理
	
	match current_state:
		EnemyState.IDLE:
			_process_idle_bat(delta)
		EnemyState.PATROL:
			_process_patrol_bat(delta)
		EnemyState.CHASE:
			_process_chase_bat(delta)
		EnemyState.ATTACK:
			_process_attack_bat(delta)
		EnemyState.HURT:
			_process_hurt_bat(delta)
		EnemyState.DEAD:
			_process_dead_bat(delta)
	
	move_and_slide()

func _process_idle_bat(delta: float) -> void:
	# 悬停动画
	hover_offset += delta * hover_frequency * TAU
	velocity.y = sin(hover_offset) * hover_amplitude
	velocity.x = 0
	
	# 检测玩家
	var player = _detect_player()
	if player:
		target = player
		_change_state(EnemyState.CHASE)

func _process_patrol_bat(delta: float) -> void:
	# 悬停效果
	hover_offset += delta * hover_frequency * TAU
	var hover_y = sin(hover_offset) * hover_amplitude
	
	# 水平巡逻
	velocity.x = direction * fly_speed
	velocity.y = hover_y
	
	# 限制巡逻范围
	if abs(global_position.x - patrol_center.x) > patrol_distance:
		direction *= -1
	
	# 更新朝向
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# 检测玩家
	var player = _detect_player()
	if player:
		target = player
		_change_state(EnemyState.CHASE)

func _process_chase_bat(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(EnemyState.PATROL)
		return
	
	# 计算到目标的方向
	var dir_to_target = (target.global_position - global_position).normalized()
	
	if not is_diving:
		# 接近玩家
		velocity = dir_to_target * chase_speed
		
		# 如果足够近，开始俯冲攻击
		var distance = global_position.distance_to(target.global_position)
		if distance < attack_range * 2:
			is_diving = true
			dive_timer = 0.0
	else:
		# 俯冲攻击
		velocity = dir_to_target * dive_speed
		dive_timer += delta
		
		if dive_timer > return_to_patrol_time:
			is_diving = false
			_change_state(EnemyState.PATROL)
	
	# 更新朝向
	if animated_sprite:
		animated_sprite.flip_h = velocity.x < 0

func _process_attack_bat(_delta: float) -> void:
	# 攻击动画播放中
	pass

func _process_hurt_bat(_delta: float) -> void:
	# 受伤反冲
	velocity *= 0.9
	
	# 短暂后恢复
	await get_tree().create_timer(0.3).timeout
	if not is_dead:
		_change_state(EnemyState.PATROL)

func _process_dead_bat(delta: float) -> void:
	# 死亡时应用重力
	velocity.y += gravity * delta
	velocity.x *= 0.95

## 蝙蝠死亡特效
func _play_death_effect() -> void:
	# 蝙蝠掉落效果
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "rotation", randf_range(-1, 1), 0.5)

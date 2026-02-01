# 骷髅战士敌人
# 近战敌人，会追击玩家并进行攻击
class_name SkeletonWarrior
extends EnemyBase

@export_group("骷髅特性")
@export var attack_cooldown: float = 1.5
@export var attack_damage: int = 15
@export var attack_range_extended: float = 40.0
@export var retreat_distance: float = 20.0

# 骷髅特有变量
var attack_timer: float = 0.0
var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	# 设置骷髅属性
	max_health = 40
	move_speed = 40.0
	chase_speed = 70.0
	damage = attack_damage
	detection_range = 180.0
	attack_range = attack_range_extended
	knockback_force = 250.0
	can_chase = true
	
	coin_drop_min = 3
	coin_drop_max = 8
	
	super._ready()

func _physics_process(delta: float) -> void:
	# 更新攻击冷却
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0
	
	super._physics_process(delta)

func _process_patrol(_delta: float) -> void:
	_check_direction()
	velocity.x = direction * move_speed
	
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# 检测玩家
	var player = _detect_player()
	if player:
		target = player
		_change_state(EnemyState.CHASE)

func _process_chase(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(EnemyState.PATROL)
		return
	
	var distance = global_position.distance_to(target.global_position)
	var dir_to_target = sign(target.global_position.x - global_position.x)
	
	# 如果在攻击范围内且可以攻击
	if distance < attack_range and can_attack:
		_change_state(EnemyState.ATTACK)
		return
	
	# 追击玩家
	if distance > attack_range:
		direction = dir_to_target
		velocity.x = direction * chase_speed
	else:
		velocity.x = 0
	
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# 如果玩家跑远了，回到巡逻
	if distance > detection_range * 1.5:
		target = null
		_change_state(EnemyState.PATROL)

func _process_attack(_delta: float) -> void:
	if is_attacking:
		return
	
	is_attacking = true
	velocity.x = 0
	
	# 面向目标
	if target and is_instance_valid(target):
		direction = sign(target.global_position.x - global_position.x)
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
	
	# 播放攻击动画
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	# 造成伤害
	_perform_attack()
	
	# 攻击后冷却
	can_attack = false
	is_attacking = false
	
	# 返回追击状态
	_change_state(EnemyState.CHASE)

## 执行攻击
func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		if target.has_method("take_damage"):
			target.take_damage(damage)
			
			# 播放攻击音效
			if AudioManager:
				AudioManager.play_sfx("hurt")

func _process_hurt(_delta: float) -> void:
	# 受伤后短暂停顿
	velocity.x *= 0.8
	
	await get_tree().create_timer(0.2).timeout
	if not is_dead:
		# 受伤后立即追击
		if target and is_instance_valid(target):
			_change_state(EnemyState.CHASE)
		else:
			_change_state(EnemyState.PATROL)

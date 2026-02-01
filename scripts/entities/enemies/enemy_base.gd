# 敌人基类
# 为所有敌人提供通用功能
class_name EnemyBase
extends CharacterBody2D

# 敌人状态枚举
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

# 信号
signal died(enemy: Node, killer: Node)
signal damaged(enemy: Node, damage: int, remaining_health: int)
signal state_changed(new_state: EnemyState)

# 导出变量 - 基础属性
@export_group("基础属性")
@export var max_health: int = 20
@export var move_speed: float = 50.0
@export var chase_speed: float = 80.0
@export var damage: int = 10
@export var knockback_force: float = 200.0

@export_group("行为配置")
@export var patrol_distance: float = 100.0
@export var attack_range: float = 30.0
@export var detection_range: float = 150.0
@export var can_chase: bool = true
@export var can_jump: bool = false

@export_group("战利品")
@export var coin_drop_min: int = 1
@export var coin_drop_max: int = 3
@export var drop_chance: float = 1.0

# 状态变量
var current_health: int
var current_state: EnemyState = EnemyState.IDLE
var is_dead: bool = false
var direction: int = 1
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var target: Node2D = null

# 组件引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	_setup_raycast()
	_change_state(EnemyState.PATROL)

## 设置射线检测
func _setup_raycast() -> void:
	# 创建墙壁检测射线
	if not has_node("RayCastRight"):
		var ray_right = RayCast2D.new()
		ray_right.name = "RayCastRight"
		ray_right.target_position = Vector2(15, 0)
		ray_right.collision_mask = 1
		ray_right.enabled = true
		add_child(ray_right)
	
	if not has_node("RayCastLeft"):
		var ray_left = RayCast2D.new()
		ray_left.name = "RayCastLeft"
		ray_left.target_position = Vector2(-15, 0)
		ray_left.collision_mask = 1
		ray_left.enabled = true
		add_child(ray_left)
	
	# 创建地面检测射线
	if not has_node("FloorCheckRight"):
		var floor_right = RayCast2D.new()
		floor_right.name = "FloorCheckRight"
		floor_right.position = Vector2(15, 6)
		floor_right.target_position = Vector2(0, 20)
		floor_right.collision_mask = 1
		floor_right.enabled = true
		add_child(floor_right)
	
	if not has_node("FloorCheckLeft"):
		var floor_left = RayCast2D.new()
		floor_left.name = "FloorCheckLeft"
		floor_left.position = Vector2(-15, 6)
		floor_left.target_position = Vector2(0, 20)
		floor_left.collision_mask = 1
		floor_left.enabled = true
		add_child(floor_left)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 根据状态执行行为
	match current_state:
		EnemyState.IDLE:
			_process_idle(delta)
		EnemyState.PATROL:
			_process_patrol(delta)
		EnemyState.CHASE:
			_process_chase(delta)
		EnemyState.ATTACK:
			_process_attack(delta)
		EnemyState.HURT:
			_process_hurt(delta)
		EnemyState.DEAD:
			_process_dead(delta)
	
	move_and_slide()

## 状态处理函数（子类可覆盖）
func _process_idle(_delta: float) -> void:
	velocity.x = 0
	
	# 检测玩家
	if can_chase:
		var player = _detect_player()
		if player:
			target = player
			_change_state(EnemyState.CHASE)

func _process_patrol(_delta: float) -> void:
	_check_direction()
	velocity.x = direction * move_speed
	
	# 更新动画朝向
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# 检测玩家
	if can_chase:
		var player = _detect_player()
		if player:
			target = player
			_change_state(EnemyState.CHASE)

func _process_chase(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(EnemyState.PATROL)
		return
	
	# 计算到目标的方向
	var dir_to_target = sign(target.global_position.x - global_position.x)
	direction = dir_to_target
	velocity.x = direction * chase_speed
	
	# 更新动画朝向
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# 检查是否在攻击范围内
	var distance = global_position.distance_to(target.global_position)
	if distance < attack_range:
		_change_state(EnemyState.ATTACK)
	elif distance > detection_range * 1.5:
		target = null
		_change_state(EnemyState.PATROL)

func _process_attack(_delta: float) -> void:
	velocity.x = 0
	# 子类实现具体攻击逻辑

func _process_hurt(_delta: float) -> void:
	# 受伤处理，可以添加击退效果
	pass

func _process_dead(_delta: float) -> void:
	velocity.x = 0

## 检查方向（墙壁和边缘检测）
func _check_direction() -> void:
	var ray_right = get_node_or_null("RayCastRight")
	var ray_left = get_node_or_null("RayCastLeft")
	var floor_right = get_node_or_null("FloorCheckRight")
	var floor_left = get_node_or_null("FloorCheckLeft")
	
	# 边缘检测
	if floor_right and floor_left:
		if direction == 1 and not floor_right.is_colliding():
			direction = -1
			return
		elif direction == -1 and not floor_left.is_colliding():
			direction = 1
			return
	
	# 墙壁检测
	if ray_right and ray_right.is_colliding():
		direction = -1
	elif ray_left and ray_left.is_colliding():
		direction = 1

## 检测玩家
func _detect_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var distance = global_position.distance_to(player.global_position)
		if distance <= detection_range:
			return player
	return null

## 受到伤害
func take_damage(amount: int, attacker: Node = null) -> void:
	if is_dead:
		return
	
	current_health -= amount
	damaged.emit(self, amount, current_health)
	
	# 显示伤害数字
	_show_damage_number(amount)
	
	# 播放受伤动画
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play("hurt")
	
	# 击退效果
	if attacker:
		var knockback_dir = sign(global_position.x - attacker.global_position.x)
		velocity.x = knockback_dir * knockback_force
		velocity.y = -100
	
	if current_health <= 0:
		_die(attacker)
	else:
		_change_state(EnemyState.HURT)

## 显示伤害数字
func _show_damage_number(damage_amount: int) -> void:
	if FloatingTextManager:
		FloatingTextManager.show_damage(global_position + Vector2(0, -20), damage_amount)

## 死亡
func _die(killer: Node = null) -> void:
	if is_dead:
		return
	
	is_dead = true
	_change_state(EnemyState.DEAD)
	
	# 发射死亡信号
	died.emit(self, killer)
	
	# 掉落金币
	_drop_loot()
	
	# 增加击杀计数
	_add_kill_score()
	
	# 播放死亡动画或直接销毁
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	# 播放死亡特效
	_play_death_effect()
	
	# 销毁
	queue_free()

## 掉落战利品
func _drop_loot() -> void:
	if randf() > drop_chance:
		return
	
	var coin_amount = randi_range(coin_drop_min, coin_drop_max)
	
	# 通过游戏状态添加金币
	if GameState:
		GameState.add_coins(coin_amount)
	
	# 显示金币获得
	if FloatingTextManager:
		FloatingTextManager.show_coin(global_position + Vector2(0, -30), coin_amount)

## 增加击杀分数
func _add_kill_score() -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("add_point"):
		game_manager.add_point()

## 播放死亡特效
func _play_death_effect() -> void:
	# 创建简单的消失动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

## 切换状态
func _change_state(new_state: EnemyState) -> void:
	if current_state == EnemyState.DEAD and new_state != EnemyState.DEAD:
		return
	
	current_state = new_state
	state_changed.emit(new_state)
	
	# 播放对应动画
	_play_state_animation()

## 播放状态动画
func _play_state_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var anim_name = ""
	match current_state:
		EnemyState.IDLE:
			anim_name = "idle"
		EnemyState.PATROL:
			anim_name = "walk"
		EnemyState.CHASE:
			anim_name = "run" if animated_sprite.sprite_frames.has_animation("run") else "walk"
		EnemyState.ATTACK:
			anim_name = "attack"
		EnemyState.HURT:
			anim_name = "hurt"
		EnemyState.DEAD:
			anim_name = "death"
	
	if anim_name and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")

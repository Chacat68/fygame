# 史莱姆王Boss
# 大型史莱姆，会分裂成小史莱姆
class_name SlimeKing
extends "res://scripts/entities/enemies/enemy_base.gd"

@export_group("史莱姆王特性")
@export var jump_force: float = -350.0
@export var jump_interval: float = 2.0
@export var slam_damage: int = 25
@export var spawn_count_on_death: int = 3
@export var mini_slime_scene: PackedScene

# 史莱姆王特有变量
var jump_timer: float = 0.0
var is_jumping: bool = false
var slam_area: Area2D

func _ready() -> void:
	# 设置史莱姆王属性
	max_health = 150
	move_speed = 30.0
	chase_speed = 50.0
	damage = slam_damage
	detection_range = 200.0
	attack_range = 60.0
	knockback_force = 350.0
	can_chase = true
	can_jump = true
	
	coin_drop_min = 20
	coin_drop_max = 50
	
	super._ready()
	
	# 创建落地震击区域
	_create_slam_area()

func _create_slam_area() -> void:
	slam_area = Area2D.new()
	slam_area.name = "SlamArea"
	slam_area.collision_layer = 0
	slam_area.collision_mask = 2  # 玩家层
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	collision.shape = shape
	collision.disabled = true
	
	slam_area.add_child(collision)
	add_child(slam_area)

func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return
	
	# 跳跃计时器
	jump_timer += delta
	
	# 检测玩家
	if current_state != EnemyState.ATTACK:
		var player = _detect_player()
		if player:
			target = player
	
	# 跳跃攻击
	if is_on_floor() and jump_timer >= jump_interval and target and is_instance_valid(target):
		_perform_jump_attack()
	
	# 落地震击
	if is_jumping and is_on_floor():
		_perform_slam()
		is_jumping = false
	
	super._physics_process(delta)

func _perform_jump_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	
	jump_timer = 0.0
	is_jumping = true
	
	# 跳向玩家
	var dir_to_player = sign(target.global_position.x - global_position.x)
	velocity.y = jump_force
	velocity.x = dir_to_player * chase_speed * 1.5
	
	# 播放跳跃动画
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("jump"):
		animated_sprite.play("jump")
	
	# 更新朝向
	if animated_sprite:
		animated_sprite.flip_h = dir_to_player < 0

func _perform_slam() -> void:
	# 启用震击区域检测
	var collision = slam_area.get_child(0) as CollisionShape2D
	if collision:
		collision.disabled = false
	
	# 检测区域内的玩家
	await get_tree().physics_frame
	
	var bodies = slam_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(slam_damage)
	
	# 禁用震击区域
	if collision:
		collision.disabled = true
	
	# 屏幕震动效果（如果有相机）
	_shake_camera()
	
	# 播放落地音效
	if AudioManager:
		AudioManager.play_sfx("explosion")

func _shake_camera() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		var tween = create_tween()
		tween.tween_property(camera, "offset", original_offset + Vector2(10, 10), 0.05)
		tween.tween_property(camera, "offset", original_offset + Vector2(-10, -5), 0.05)
		tween.tween_property(camera, "offset", original_offset + Vector2(5, -10), 0.05)
		tween.tween_property(camera, "offset", original_offset, 0.05)

func _die(killer: Node = null) -> void:
	# 分裂成小史莱姆
	_spawn_mini_slimes()
	
	# 调用父类死亡
	super._die(killer)

func _spawn_mini_slimes() -> void:
	for i in range(spawn_count_on_death):
		var mini_slime: Node2D
		
		# 如果有预制场景，使用预制场景
		if mini_slime_scene:
			mini_slime = mini_slime_scene.instantiate()
		else:
			# 创建简单的小史莱姆
			mini_slime = _create_simple_mini_slime()
		
		if mini_slime:
			# 设置位置（分散开）
			var offset = Vector2(randf_range(-30, 30), randf_range(-20, 0))
			mini_slime.global_position = global_position + offset
			
			# 给一个初始速度
			if mini_slime is CharacterBody2D:
				mini_slime.velocity = Vector2(randf_range(-100, 100), -150)
			
			# 添加到场景
			get_parent().add_child(mini_slime)

func _create_simple_mini_slime() -> Node2D:
	# 创建简单的小史莱姆节点
	var mini_slime_node = CharacterBody2D.new()
	mini_slime_node.add_to_group("enemy")
	
	# 添加碰撞体
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8
	shape.height = 16
	collision.shape = shape
	mini_slime_node.add_child(collision)
	
	# 添加精灵（如果有史莱姆精灵）
	var sprite = Sprite2D.new()
	var slime_texture = load("res://assets/sprites/slime_green.png") if ResourceLoader.exists("res://assets/sprites/slime_green.png") else null
	if slime_texture:
		sprite.texture = slime_texture
		sprite.scale = Vector2(0.5, 0.5)
	mini_slime_node.add_child(sprite)
	
	# 添加简单的AI脚本
	var script = load("res://scripts/entities/enemies/slime.gd") if ResourceLoader.exists("res://scripts/entities/enemies/slime.gd") else null
	if script:
		mini_slime_node.set_script(script)
	
	return mini_slime_node

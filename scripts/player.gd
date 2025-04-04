extends CharacterBody2D

# 角色属性常量
const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2  # 最大跳跃次数（包括第一次跳跃）
const MAX_HEALTH = 100  # 最大血量
const DAMAGE_AMOUNT = 10  # 受到伤害的数值
const INVINCIBILITY_TIME = 1.0  # 受伤后的无敌时间（秒）

# 状态变量
var jumps_made = 0   # 已经跳跃的次数
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health = MAX_HEALTH  # 当前血量
var is_invincible = false  # 是否处于无敌状态
var is_hurt = false  # 是否处于受伤状态
var is_falling_to_death = false  # 是否正在掉落死亡

# 组件引用
@onready var animated_sprite = $AnimatedSprite2D

# 预加载音效
var hurt_sound = preload("res://assets/sounds/hurt.wav")

# 信号
signal health_changed(new_health)

# 复活效果标志 - 使用AutoLoad模式在场景重载后保持
var should_apply_respawn_effect = false

# 初始化函数
func _ready():
	# 将玩家添加到player组，便于后续查找
	add_to_group("player")
	
	# 检查是否需要应用复活效果
	if Engine.has_singleton("GameState") and Engine.get_singleton("GameState").player_respawning:
		print("检测到玩家正在复活，应用复活效果")
		_apply_respawn_effect()
		# 重置复活标志
		Engine.get_singleton("GameState").set_player_respawning(false)

func _physics_process(delta):
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_update_animation()
	_handle_invincibility(delta)
	_check_fall_death()
	move_and_slide()

# 应用重力
func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 当角色着地时重置跳跃计数
		jumps_made = 0

# 处理跳跃逻辑
func _handle_jump():
	if Input.is_action_just_pressed("jump") and (is_on_floor() or jumps_made < MAX_JUMPS):
		velocity.y = JUMP_VELOCITY
		jumps_made += 1

# 处理水平移动
func _handle_movement():
	var direction = Input.get_axis("move_left", "move_right")
	
	# 翻转精灵
	if direction != 0:
		animated_sprite.flip_h = (direction < 0)
	
	# 应用移动
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

# 更新动画状态
func _update_animation():
	if is_hurt:
		animated_sprite.play("death")  # 使用死亡动画表示受伤状态
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
	
	# 如果处于无敌状态，让角色闪烁
	if is_invincible:
		animated_sprite.modulate.a = 0.5 if Engine.get_process_frames() % 10 < 5 else 1.0
	else:
		animated_sprite.modulate.a = 1.0

# 处理无敌状态计时
var invincibility_timer = 0.0
func _handle_invincibility(delta):
	if is_invincible:
		# 使用delta时间递减计时器
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			is_hurt = false
			invincibility_timer = 0.0

# 处理受到伤害
func take_damage(amount = DAMAGE_AMOUNT):
	# 如果处于无敌状态，不受伤害
	if is_invincible:
		return
	
	# 减少血量
	current_health -= amount
	
	# 发出血量变化信号
	emit_signal("health_changed", current_health)
	
	# 播放受伤音效
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = hurt_sound
	add_child(audio_player)
	audio_player.play()
	
	# 设置受伤和无敌状态
	is_hurt = true
	is_invincible = true
	invincibility_timer = INVINCIBILITY_TIME  # 初始化无敌时间计时器
	
	# 受伤后短暂击退
	velocity.y = JUMP_VELOCITY * 0.5
	
	# 检查是否死亡
	if current_health <= 0:
		_die()
		return

# 处理死亡
func _die():
	# 禁用碰撞 - 使用set_deferred避免在物理查询刷新时修改状态
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# 播放死亡动画
	animated_sprite.play("death")
	
	# 设置复活标志，以便在场景重新加载后应用复活效果
	if Engine.has_singleton("GameState"):
		Engine.get_singleton("GameState").set_player_respawning(true)
	
	# 延迟重新加载场景
	await get_tree().create_timer(1.0).timeout
	_respawn()

# 处理复活
func _respawn():
	# 重新加载当前场景
	get_tree().reload_current_scene()

# 应用复活效果
func _apply_respawn_effect():
	print("开始应用复活效果")
	
	# 初始设置为完全透明
	modulate.a = 0.0
	print("初始透明度设置为: " + str(modulate.a))
	
	# 设置无敌状态
	is_invincible = true
	invincibility_timer = INVINCIBILITY_TIME * 2  # 给予更长的无敌时间
	
	# 创建从透明到不透明的渐变效果
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 1.5)  # 1.5秒内从透明变为不透明
	
	# 添加完成回调
	tween.finished.connect(func():
		print("玩家复活完成，当前透明度: " + str(modulate.a))
		# 确保完全不透明
		modulate.a = 1.0
	)

# 检测角色是否掉落到悬崖下
func _check_fall_death():
	# 如果已经在掉落死亡过程中，不再重复处理
	if is_falling_to_death:
		return
	
	# 定义屏幕边界值，当角色Y坐标超过此值时视为掉落到悬崖下
	var fall_death_y_threshold = 1000  # 根据游戏实际情况调整此值
	
	# 检查角色是否掉落到悬崖下
	if global_position.y > fall_death_y_threshold:
		# 设置掉落死亡标志，防止重复触发
		is_falling_to_death = true
		# 直接调用_die()函数，不经过take_damage()函数
		print("Player fell off cliff - instant death!")
		# 直接调用死亡函数，碰撞形状的禁用会在_die()函数中处理
		_die()

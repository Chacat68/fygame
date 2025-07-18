extends CharacterBody2D

# 游戏配置
var config: GameConfig

# 技能管理器
var skill_manager: SkillManager

# 角色属性（从配置文件加载）
var SPEED: float
var JUMP_VELOCITY: float
var MAX_JUMPS: int
var MAX_HEALTH: int
var INVINCIBILITY_TIME: float
var gravity: float

# 状态变量
var jumps_made = 0   # 已经跳跃的次数
var current_health: int  # 当前血量
var is_invincible = false  # 是否处于无敌状态
var is_falling_to_death = false  # 是否正在掉落死亡
var wall_jump_count = 0  # 连续墙跳次数
var facing_direction = 1  # 玩家朝向 (1=右, -1=左)

# 状态管理
var current_state: PlayerState
var states = {}

# 组件引用
@onready var animated_sprite = $AnimatedSprite2D

# 音效引用 - 通过资源管理器获取
var hurt_sound = null
var jump_sound = null

# 音效资源现在通过ResourceManager AutoLoad获取，不需要预加载

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()
	
	# 设置角色属性
	SPEED = config.player_speed
	JUMP_VELOCITY = config.player_jump_velocity
	MAX_JUMPS = config.player_max_jumps
	MAX_HEALTH = config.player_max_health
	INVINCIBILITY_TIME = config.player_invincibility_time
	gravity = config.player_gravity
	
	# 初始化当前血量
	current_health = MAX_HEALTH
	
	# 初始化技能管理器
	skill_manager = SkillManager.new()
	skill_manager.init_skills()

# 信号
signal health_changed(new_health)

# 复活效果标志 - 使用AutoLoad模式在场景重载后保持
var should_apply_respawn_effect = false

# 初始化函数
func _ready():
	# 初始化配置
	_init_config()
	
	# 将玩家添加到player组，便于后续查找
	add_to_group("player")
	
	# 初始化状态
	_init_states()
	
	# 检查是否需要应用复活效果
	if Engine.has_singleton("GameState") and Engine.get_singleton("GameState").player_respawning:
		print("检测到玩家正在复活，应用复活效果")
		_apply_respawn_effect()
		# 重置复活标志
		Engine.get_singleton("GameState").set_player_respawning(false)

# 初始化状态机
func _init_states():
	# 创建各种状态
	states = {
		"Idle": IdleState.new(self),
		"Run": RunState.new(self),
		"Jump": JumpState.new(self),
		"Fall": FallState.new(self),
		"Hurt": HurtState.new(self),
		"Death": DeathState.new(self),
		"Dash": DashState.new(self),
		"WallSlide": WallSlideState.new(self),
		"WallJump": WallJumpState.new(self),
		"Slide": SlideState.new(self)
	}
	
	# 设置初始状态
	_change_state("Idle")

# 切换状态
func _change_state(new_state_name: String):
	if current_state:
		current_state.exit()
	
	current_state = states[new_state_name]
	current_state.enter()

# 物理处理
func _physics_process(delta):
	# 更新技能冷却
	skill_manager.update_cooldowns(delta)
	
	# 处理无敌状态
	_handle_invincibility(delta)
	
	# 检查掉落死亡
	_check_fall_death()
	
	# 检查踩踏击杀
	_check_stomp_kill()
	
	# 更新玩家朝向
	_update_facing_direction()
	
	# 使用当前状态处理物理更新
	var new_state_name = current_state.physics_process(delta)
	if new_state_name:
		_change_state(new_state_name)
	
	# 应用移动
	move_and_slide()

# 处理无敌状态计时
var invincibility_timer = 0.0
func _handle_invincibility(delta):
	if not animated_sprite:
		return
		
	if is_invincible:
		invincibility_timer += delta
		
		# 无敌状态闪烁效果
		animated_sprite.modulate.a = 0.5 if Engine.get_process_frames() % 10 < 5 else 1.0
		
		# 无敌时间结束
		if invincibility_timer >= INVINCIBILITY_TIME:
			is_invincible = false
			animated_sprite.modulate.a = 1.0
	else:
		animated_sprite.modulate.a = 1.0

# 检查是否掉落死亡
func _check_fall_death():
	# 获取死亡高度
	var death_height = config.death_height if config else 300.0 # 从配置获取，默认值300
	
	# 尝试从游戏管理器获取关卡特定的死亡高度（优先级更高）
	var game_manager = _get_game_manager()
	if game_manager and game_manager.has_method("get_death_height"):
		death_height = game_manager.get_death_height()
	
	# 如果玩家掉落到一定高度，直接死亡
	if position.y > death_height and not is_falling_to_death:
		is_falling_to_death = true
		_die()

# 受到伤害
func take_damage(amount: int = 10):
	# 如果处于无敌状态，不受伤害
	if is_invincible:
		return
	
	# 扣除血量
	current_health -= amount
	
	# 发出血量变化信号
	health_changed.emit(current_health)
	
	# 设置无敌状态
	is_invincible = true
	invincibility_timer = 0.0
	
	# 如果血量为0，死亡
	if current_health <= 0:
		_die()
	else:
		# 切换到受伤状态
		_change_state("Hurt")

# 死亡处理
func _die():
	# 切换到死亡状态
	_change_state("Death")

# 开始闪烁效果（受伤时使用）
func start_blink():
	if not animated_sprite:
		return
	
	# 创建闪烁动画
	var tween = create_tween()
	tween.set_loops(3) # 闪烁3次
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)

# 应用复活效果
func _apply_respawn_effect():
	# 设置无敌状态
	is_invincible = true
	invincibility_timer = 0.0
	
	# 重置血量
	current_health = MAX_HEALTH
	health_changed.emit(current_health)
	
	# 应用闪烁效果
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.2)



# 注释：原有的重复函数已被移除，使用上面的take_damage函数实现

# 注释：原有的重复_die函数已被移除，使用上面的_die函数实现

# 检查踩踏击杀怪物
func _check_stomp_kill():
	# 只有在下落状态且向下移动时才能踩踏击杀
	if velocity.y <= 0:
		return
	
	# 获取所有怪物
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		# 检查怪物是否还活着
		if not enemy.is_dead and enemy.current_state != enemy.EnemyState.DEAD:
			# 计算距离
			var distance = global_position.distance_to(enemy.global_position)
			
			# 如果距离足够近
			if distance < 25:
				# 检查玩家是否在怪物上方
				var player_bottom = global_position.y + 8 # 玩家底部大概位置
				var enemy_top = enemy.global_position.y - 8 # 怪物头顶大概位置
				
				# 如果玩家在怪物上方且正在下落
				if player_bottom >= enemy_top - 5 and player_bottom <= enemy_top + 10:
					# 执行踩踏击杀
					_perform_stomp_kill(enemy)
					break # 一次只击杀一个怪物

# 执行踩踏击杀
func _perform_stomp_kill(monster):
	# 给玩家一个向上的反弹力
	velocity.y = -250
	
	# 重置跳跃次数，允许玩家继续跳跃
	jumps_made = 1 # 设为1而不是0，因为踩踏算作一次跳跃
	
	# 击杀怪物
	monster._die(self)
	
	# 播放击杀音效（如果有的话）
	ResourceManager.play_sound("power_up", self)

# 注释：原有的重复_check_fall_death函数已被移除，使用上面的_check_fall_death函数实现

# 更新玩家朝向
func _update_facing_direction():
	if velocity.x > 0:
		facing_direction = 1
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		facing_direction = -1
		animated_sprite.flip_h = true

# 获取技能管理器
func get_skill_manager() -> SkillManager:
	return skill_manager

# 检查是否可以使用技能
func can_use_skill(skill_name: String) -> bool:
	return skill_manager.can_use_skill(skill_name)

# 使用技能
func use_skill(skill_name: String) -> bool:
	return skill_manager.use_skill(skill_name)

# 重置墙跳计数
func reset_wall_jump_count():
	wall_jump_count = 0

# 增加墙跳计数
func increment_wall_jump_count():
	wall_jump_count += 1

# 获取墙跳计数
func get_wall_jump_count() -> int:
	return wall_jump_count

# 获取玩家朝向
func get_facing_direction() -> int:
	return facing_direction

# 设置玩家朝向
func set_facing_direction(direction: int):
	facing_direction = direction
	if animated_sprite:
		animated_sprite.flip_h = (direction < 0)

# 安全获取GameManager节点
func _get_game_manager() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("GameManager")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("game_manager")

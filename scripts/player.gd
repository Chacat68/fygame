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
var is_falling_to_death = false  # 是否正在掉落死亡

# 状态管理
var current_state: PlayerState
var states = {}

# 组件引用
@onready var animated_sprite = $AnimatedSprite2D

# 音效引用 - 通过资源管理器获取
var hurt_sound = null
var jump_sound = null

# 预加载ResourceManager类
const ResourceManagerClass = preload("res://scripts/resource_manager.gd")

# 初始化音效资源
func _init_sounds():
	# 如果ResourceManager已注册为自动加载，直接使用
	if Engine.has_singleton("ResourceManager"):
		hurt_sound = Engine.get_singleton("ResourceManager").get_sound("hurt")
		jump_sound = Engine.get_singleton("ResourceManager").get_sound("jump")
	else:
		# 如果ResourceManager未注册为自动加载，使用单例模式
		hurt_sound = ResourceManagerClass.instance().get_sound("hurt")
		jump_sound = ResourceManagerClass.instance().get_sound("jump")

# 信号
signal health_changed(new_health)

# 复活效果标志 - 使用AutoLoad模式在场景重载后保持
var should_apply_respawn_effect = false

# 初始化函数
func _ready():
	# 将玩家添加到player组，便于后续查找
	add_to_group("player")
	
	# 初始化音效资源
	_init_sounds()
	
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
		"Death": DeathState.new(self)
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
	# 处理无敌状态
	_handle_invincibility(delta)
	
	# 检查掉落死亡
	_check_fall_death()
	
	# 使用当前状态处理物理更新
	var new_state_name = current_state.physics_process(delta)
	if new_state_name:
		_change_state(new_state_name)
	
	# 应用移动
	move_and_slide()

# 处理无敌状态计时
var invincibility_timer = 0.0
func _handle_invincibility(delta):
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
	# 如果玩家掉落到一定高度，直接死亡
	if position.y > 500 and not is_falling_to_death:
		is_falling_to_death = true
		_die()

# 受到伤害
func take_damage(amount = DAMAGE_AMOUNT):
	# 如果处于无敌状态，不受伤害
	if is_invincible:
		return
	
	# 扣除血量
	current_health -= amount
	
	# 发出血量变化信号
	emit_signal("health_changed", current_health)
	
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

# 应用复活效果
func _apply_respawn_effect():
	# 设置无敌状态
	is_invincible = true
	invincibility_timer = 0.0
	
	# 重置血量
	current_health = MAX_HEALTH
	emit_signal("health_changed", current_health)
	
	# 应用闪烁效果
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.2)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.2)

# 注释：原有的重复函数已被移除，使用上面的take_damage函数实现

# 注释：原有的重复_die函数已被移除，使用上面的_die函数实现

# 注释：原有的重复_check_fall_death函数已被移除，使用上面的_check_fall_death函数实现

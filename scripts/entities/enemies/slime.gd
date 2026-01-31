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

# 游戏配置
var config: GameConfig

# 移动属性（从配置文件加载）
var SPEED: float
var CHASE_SPEED: float
var PATROL_DISTANCE: float
var ATTACK_RANGE: float
var HEALTH: int

# 状态变量
var direction = 1
var current_state = EnemyState.PATROL
var is_dead = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health: int

# 组件引用
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

# 飘字效果现在由FloatingTextManager管理

# 在准备好时调用
func _ready():
	# 初始化配置
	_init_config()
	
	# 将怪物添加到enemy组，便于识别
	add_to_group("enemy")
	
	# 创建地面检测射线（如果不存在）
	_create_floor_checks()
	
	# 设置初始状态
	_change_state(EnemyState.PATROL)

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()
	
	# 设置史莱姆属性
	SPEED = config.slime_speed
	CHASE_SPEED = config.slime_chase_speed
	PATROL_DISTANCE = config.slime_patrol_distance
	ATTACK_RANGE = config.slime_attack_range
	HEALTH = config.slime_health
	current_health = HEALTH
	
	# 设置射线可见，便于调试
	# 注意：debug_shape_thickness在某些Godot版本中不可用
	# 如果需要调试可视化，可以考虑使用其他方法或检查Godot版本

# 创建地面检测射线
func _create_floor_checks():
	# 创建右侧地面检测射线
	if not has_node("FloorCheckRight"):
		var floor_check = RayCast2D.new()
		floor_check.name = "FloorCheckRight"
		add_child(floor_check)
		floor_check.position = Vector2(15, 6) # 右侧射线位置（更靠外侧）
		floor_check.target_position = Vector2(0, 20) # 向下检测（增加长度）
		floor_check.enabled = true
		# 确保射线只检测地形层
		floor_check.collision_mask = 1
	
	# 创建左侧地面检测射线
	if not has_node("FloorCheckLeft"):
		var floor_check = RayCast2D.new()
		floor_check.name = "FloorCheckLeft"
		add_child(floor_check)
		floor_check.position = Vector2(-15, 6) # 左侧射线位置（更靠外侧）
		floor_check.target_position = Vector2(0, 20) # 向下检测（增加长度）
		floor_check.enabled = true
		# 确保射线只检测地形层
		floor_check.collision_mask = 1

# 每一帧都会调用此函数。'delta' 是自上一帧以来的经过时间。
func _process(delta):
	# 根据当前状态执行不同的行为
	match current_state:
		EnemyState.IDLE:
			# 待机状态，可以添加计时器在一段时间后切换到巡逻状态
			pass
			
		EnemyState.PATROL:
			# 巡逻状态，检查方向并移动
			_check_direction()
			_move(delta)
			
		EnemyState.CHASE:
			# 追逐状态，可以实现追逐玩家的逻辑
			# 暂时使用巡逻逻辑
			_check_direction()
			_move(delta)
			
		EnemyState.ATTACK:
			# 攻击状态，可以实现攻击玩家的逻辑
			pass
			
		EnemyState.HURT:
			# 受伤状态，可以实现受伤动画和短暂无敌时间
			pass
			
		EnemyState.DEAD:
			# 死亡状态，不执行任何行为
			pass

# 检查并更新移动方向
func _check_direction():
	# 获取地面检测射线
	var floor_check_right = get_node_or_null("FloorCheckRight")
	var floor_check_left = get_node_or_null("FloorCheckLeft")
	
	# 确保地面检测射线存在并启用
	if floor_check_right and floor_check_left:
		# 优先检测平台边缘
		# 如果右侧没有地面，向左转
		if direction == 1 and not floor_check_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
			return # 已经改变方向，不需要继续检测
		# 如果左侧没有地面，向右转
		elif direction == -1 and not floor_check_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
			return # 已经改变方向，不需要继续检测
	
	# 检测是否碰到墙壁
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

# 根据当前方向移动
func _move(delta):
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 设置水平速度
	velocity.x = direction * SPEED
	
	# 移动并滑动
	move_and_slide()

# 注释：头部碰撞检测已移除，现在使用玩家端的踩踏检测

# 状态切换函数
func _change_state(new_state):
	# 退出当前状态
	match current_state:
		EnemyState.IDLE:
			pass
		EnemyState.PATROL:
			pass
		EnemyState.CHASE:
			pass
		EnemyState.ATTACK:
			pass
		EnemyState.HURT:
			pass
		EnemyState.DEAD:
			# 如果已经死亡，不允许切换到其他状态
			return
	
	# 更新当前状态
	current_state = new_state
	
	# 进入新状态
	match current_state:
		EnemyState.IDLE:
			velocity.x = 0
			# 可以在这里播放待机动画
		EnemyState.PATROL:
			# 可以在这里播放行走动画
			pass
		EnemyState.CHASE:
			# 追逐状态可以增加移动速度
			SPEED = CHASE_SPEED
			# 可以在这里播放追逐动画
		EnemyState.ATTACK:
			velocity.x = 0
			# 可以在这里播放攻击动画
		EnemyState.HURT:
			velocity.x = 0
			# 可以在这里播放受伤动画
		EnemyState.DEAD:
			velocity.x = 0
			# 可以在这里播放死亡动画

# 注释：旧的头部碰撞处理函数已移除，现在使用玩家端的踩踏检测

# 怪物死亡处理
func _die(player):
	# 切换到死亡状态
	current_state = EnemyState.DEAD
	# 标记为已死亡（保留兼容性）
	is_dead = true
	
	# 显示击杀得分文本
	_show_floating_text(player)
	
	# 播放死亡动画（如果有的话）
	# 这里可以添加死亡动画播放代码
	
	# 禁用碰撞区域 - 使用set_deferred避免在物理查询刷新时修改状态
	var killzone = get_node_or_null("Killzone")
	if killzone and killzone.has_node("CollisionShape2D"):
		killzone.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# 延迟移除怪物
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5) # 淡出效果
	tween.tween_callback(queue_free) # 完成后移除
	
	# 增加游戏分数和击杀计数
	var game_manager = _get_game_manager()
	if game_manager and game_manager.has_method("add_point"):
		game_manager.add_point()
	else:
		# 如果找不到 GameManager，直接更新 UI
		var ui = _get_ui_node()
		if ui:
			if ui.has_method("add_kill"):
				ui.add_kill()
			if ui.has_method("add_coin"):
				var coin_value = config.coin_value if config else 1
				ui.add_coin(coin_value)

# 显示飘字效果
func _show_floating_text(player):
	# 确保玩家仍然有效
	if not is_instance_valid(player):
		return
		
	# 获取场景根节点，避免Game节点的position偏移影响飘字位置
	var game_root = get_tree().current_scene
	if not game_root:
		game_root = get_tree().get_root()
	
	# 计算基础位置（在怪物头顶附近）
	var base_position = global_position + Vector2(0, -15)
	
	# 使用飘字管理器创建排列的飘字效果（直接使用 AutoLoad 单例）
	# 创建击杀飘字
	FloatingTextManager.create_arranged_floating_text(base_position, "击杀+1", game_root)
	
	# 创建金币飘字
	var coin_value = config.coin_value if config else 1
	FloatingTextManager.create_arranged_floating_text(base_position, "金币+" + str(coin_value), game_root)

# 安全获取UI节点
func _get_ui_node() -> Node:
	# 首先尝试在当前场景中查找 UI 节点
	var current_scene = get_tree().current_scene
	if current_scene:
		var ui = current_scene.get_node_or_null("UI")
		if ui:
			return ui
	
	# 尝试 /root/Game 路径（兼容旧结构）
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("UI")
	
	# 如果都找不到，尝试在 group 中查找
	return get_tree().get_first_node_in_group("ui")

# 安全获取GameManager节点
func _get_game_manager() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("GameManager")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("game_manager")

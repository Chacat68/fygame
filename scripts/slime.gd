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

# 移动属性
var SPEED = 45 # 改为变量，使其可以被修改

# 状态变量
var direction = 1
var current_state = EnemyState.PATROL
var is_dead = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 组件引用
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

# 预加载飘字场景
var floating_text_scene = preload("res://scenes/floating_text.tscn")

# 在准备好时调用
func _ready():
	# 创建地面检测射线（如果不存在）
	_create_floor_checks()
	
	# 创建头部碰撞检测区域（如果不存在）
	_create_head_hitbox()
	
	# 设置初始状态
	_change_state(EnemyState.PATROL)
	
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

# 创建头部碰撞检测区域
func _create_head_hitbox():
	if not has_node("HeadHitbox"):
		# 创建头部碰撞区域
		var head_hitbox = Area2D.new()
		head_hitbox.name = "HeadHitbox"
		add_child(head_hitbox)
		
		# 创建碰撞形状
		var collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		head_hitbox.add_child(collision_shape)
		
		# 创建矩形形状
		var shape = RectangleShape2D.new()
		shape.size = Vector2(16, 4) # 头部碰撞区域大小
		collision_shape.shape = shape
		
		# 设置碰撞区域位置（在怪物头顶）
		collision_shape.position = Vector2(0, -6)
		
		# 设置碰撞掩码，只检测玩家层（假设玩家在第2层，即掩码值为2）
		head_hitbox.collision_mask = 2
		
		# 连接信号
		head_hitbox.connect("body_entered", _on_head_hitbox_body_entered)

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
			SPEED = 65
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

# 当玩家踩到怪物头顶时调用
func _on_head_hitbox_body_entered(body):
	# 确保怪物还没有死亡
	if current_state == EnemyState.DEAD:
		return
		
	# 确保碰撞的是玩家
	if body.is_in_group("player"):
		# 更精确地检查玩家是否从上方踩踏
		# 比较玩家底部和怪物头部的相对位置
		var player_bottom = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var collision = body.get_node("CollisionShape2D")
			if collision.shape is CircleShape2D:
				player_bottom += collision.shape.radius
			elif collision.shape is RectangleShape2D:
				player_bottom += collision.shape.size.y / 2
		
		var slime_top = global_position.y - 6 # 头部位置
		
		if player_bottom < slime_top + 2 and body.velocity.y > 0:
			# 击杀怪物
			_die(body)
			
			# 让玩家弹跳
			body.velocity.y = -300 # 给玩家一个向上的反弹力

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
	
	# 增加游戏分数
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager and game_manager.has_method("add_point"):
		game_manager.add_point()

# 显示飘字效果
func _show_floating_text(player):
	# 确保玩家仍然有效
	if not is_instance_valid(player):
		return
		
	# 获取游戏场景根节点
	var game_root = get_tree().get_root().get_node("Game")
	if not game_root:
		game_root = get_tree().get_root()
	
	# 实例化击杀飘字场景
	var kill_text = floating_text_scene.instantiate()
	
	# 计算世界坐标中的位置（在怪物上方）
	var kill_position = global_position + Vector2(-20, -30)
	kill_text.global_position = kill_position
	
	# 设置击杀飘字文本
	kill_text.pending_text = "击杀+1"
	
	# 将击杀飘字添加到游戏根节点
	game_root.add_child(kill_text)
	
	# 添加到场景树后再设置文本
	kill_text.set_text("击杀+1")
	
	# 实例化金币飘字场景
	var coin_text = floating_text_scene.instantiate()
	
	# 计算世界坐标中的位置（在怪物上方，稍微偏右）
	var coin_position = global_position + Vector2(20, -30)
	coin_text.global_position = coin_position
	
	# 设置金币飘字文本
	coin_text.pending_text = "金币+1"
	
	# 将金币飘字添加到游戏根节点
	game_root.add_child(coin_text)
	
	# 添加到场景树后再设置文本
	coin_text.set_text("金币+1")

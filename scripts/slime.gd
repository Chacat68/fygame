extends Node2D

# 移动属性
const SPEED = 60

# 状态变量
var direction = 1
var is_dead = false

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
	# 如果怪物已死亡，不再处理移动逻辑
	if is_dead:
		return
		
	_check_direction()
	_move(delta)

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
	position.x += direction * SPEED * delta

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

# 当玩家踩到怪物头顶时调用
func _on_head_hitbox_body_entered(body):
	# 确保怪物还活着
	if is_dead:
		return
		
	# 确保碰撞的是玩家
	if body is CharacterBody2D:
		# 检查玩家是否从上方踩踏（通过比较y轴速度）
		if body.velocity.y > 0:
			# 击杀怪物
			_die(body)
			
			# 让玩家弹跳
			body.velocity.y = -300 # 给玩家一个向上的反弹力

# 怪物死亡处理
func _die(player):
	# 标记为已死亡
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

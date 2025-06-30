extends Area2D

# 游戏配置
var config: GameConfig

# 组件引用
@onready var coin_counter = _get_ui_node()
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $CoinSound

# 飘字效果现在由FloatingTextManager管理

# 状态变量
var popup_shown = false
var collected = false

# 初始化函数
func _ready():
	# 初始化配置
	_init_config()

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	if collected:
		return
		
	collected = true
	_collect_coin(_body)

# 处理金币收集逻辑
func _collect_coin(body = null):
	var error_messages = []
	
	# 增加金币计数
	if coin_counter:
		coin_counter.add_coin()
	else:
		error_messages.append("CoinCounter is null")
	
	# 播放收集动画
	if animation_player:
		animation_player.play("pickup")
	else:
		error_messages.append("AnimationPlayer is null")
	
	# 播放收集音效
	if sound_player:
		sound_player.play()
	
	# 显示飘字效果
	if body and body is CharacterBody2D:
		# 使用call_deferred确保在安全的时间添加子节点
		call_deferred("_show_floating_text", body)
	
	# 显示收集信息
	if not popup_shown:
		print("金币已收集！")
		popup_shown = true
	
	# 输出任何错误信息
	for message in error_messages:
		print(message)

# 显示飘字效果
func _show_floating_text(player):
	# 确保玩家仍然有效
	if not is_instance_valid(player):
		return
		
	# 获取游戏场景根节点
	# 获取场景根节点，避免Game节点的position偏移影响飘字位置
	var game_root = get_tree().current_scene
	if not game_root:
		game_root = get_tree().get_root()
	
	# 计算世界坐标中的位置（在玩家头顶附近）
	var world_position = player.global_position + Vector2(0, -15)
	
	# 设置飘字文本
	var coin_value = config.coin_value if config else 1
	var text = "金币+" + str(coin_value)
	
	# 使用飘字管理器创建排列的飘字效果
	var text_manager = FloatingTextManager.get_instance()
	text_manager.create_arranged_floating_text(world_position, text, game_root)

# 当动画播放完成后，移除金币
func _on_animation_player_animation_finished(_anim_name):
	queue_free()  # 从场景中移除金币

# 安全获取UI节点
func _get_ui_node() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("UI")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("ui")

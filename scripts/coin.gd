extends Area2D

# 组件引用
@onready var coin_counter = get_node_or_null("/root/Game/UI")
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $CoinSound

# 预加载飘字场景
var floating_text_scene = preload("res://scenes/floating_text.tscn")

# 状态变量
var popup_shown = false
var collected = false

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
	var game_root = get_tree().get_root().get_node("Game")
	if not game_root:
		game_root = get_tree().get_root()
	
	# 实例化飘字场景
	var floating_text = floating_text_scene.instantiate()
	
	# 计算世界坐标中的位置（在玩家上方）
	var world_position = player.global_position + Vector2(0, -30)
	floating_text.global_position = world_position
	
	# 设置飘字文本
	floating_text.pending_text = "金币+1"
	
	# 将飘字添加到游戏根节点，而不是玩家
	game_root.add_child(floating_text)
	
	# 添加到场景树后再设置文本
	floating_text.set_text("金币+1")

# 当动画播放完成后，移除金币
func _on_animation_player_animation_finished(_anim_name):
	queue_free()  # 从场景中移除金币

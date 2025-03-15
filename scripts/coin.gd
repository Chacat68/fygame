extends Area2D

# 组件引用
@onready var coin_counter = get_node_or_null("/root/Game/UI")
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $CoinSound

# 状态变量
var popup_shown = false
var collected = false

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	if collected:
		return
		
	collected = true
	_collect_coin()

# 处理金币收集逻辑
func _collect_coin():
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
	
	# 显示收集信息
	if not popup_shown:
		print("金币已收集！")
		popup_shown = true
	
	# 输出任何错误信息
	for message in error_messages:
		print(message)

# 当动画播放完成后，移除金币
func _on_animation_player_animation_finished(_anim_name):
	queue_free()  # 从场景中移除金币

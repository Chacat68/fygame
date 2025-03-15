extends Area2D

# 获取GameManager、AnimationPlayer和提示文本Label节点
@onready var coin_counter = get_node_or_null("/root/Game/UI")
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $CoinSound
# 创建一个变量来跟踪是否已经显示了弹出文本
var popup_shown = false
var collected = false

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	if collected:
		return
		
	var messages = []
	
	if coin_counter:
		coin_counter.add_coin()  # 调用金币计数器的add_coin方法
	else:
		messages.append("CoinCounter is null")
	
	if animation_player:
		animation_player.play("pickup")  # 播放"pickup"动画
	else:
		messages.append("AnimationPlayer is null")
	
	if sound_player:
		sound_player.play()  # 播放金币音效
	
	# 由于没有PopupLabel节点，我们改为在控制台输出信息
	if not popup_shown:
		print("金币已收集！")
		popup_shown = true
	
	collected = true
	
	for message in messages:
		print(message)

# 当动画播放完成后，移除金币
func _on_animation_player_animation_finished(_anim_name):
	queue_free()  # 从场景中移除金币

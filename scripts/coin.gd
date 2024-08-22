extends Area2D

# 获取GameManager、AnimationPlayer和提示文本Label节点
@onready var game_manager = get_node_or_null("../GameManager")
@onready var animation_player = $AnimationPlayer
@onready var popup_label = $PopupLabel

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	var messages = []
	
	if game_manager:
		game_manager.add_point()  # 在GameManager中增加分数
	else:
		messages.append("GameManager is null")
	
	if animation_player:
		animation_player.play("pickup")  # 播放"pickup"动画
	else:
		messages.append("AnimationPlayer is null")
	
	# 显示弹出文本提示
	if popup_label:
		popup_label.text = "金币已收集！"
		popup_label.visible = true
		# 设置一个定时器，3秒后隐藏提示
		$Timer.start(3)
	
	for message in messages:
		print(message)

# 定时器超时回调函数
func _on_Timer_timeout():
	popup_label.visible = false

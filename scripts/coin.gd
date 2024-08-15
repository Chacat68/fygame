extends Area2D

# 获取GameManager和AnimationPlayer节点
@onready var game_manager = $"../GameManager"
@onready var animation_player = $AnimationPlayer

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	print("GameManager: ", game_manager)
	print("AnimationPlayer: ", animation_player)
	
	if game_manager != null:
		game_manager.add_point()  # 在GameManager中增加分数
	else:
		print("GameManager is null")
	
	if animation_player != null:
		animation_player.play("pickup")  # 播放"pickup"动画
	else:
		print("AnimationPlayer is null")

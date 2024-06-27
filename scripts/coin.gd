extends Area2D

# 获取GameManager和AnimationPlayer节点
@onready var game_manager = $GameManager
@onready var animation_player = $AnimationPlayer

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(body_id, body, body_shape, local_shape):
	game_manager.add_point()  # 在GameManager中增加分数
	animation_player.play("pickup")  # 播放"pickup"动画


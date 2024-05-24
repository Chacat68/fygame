extends Area2D

# 获取Timer节点
@onready var timer = $Timer

# 当有物体进入Area2D时调用此函数
func _on_body_entered(body):
	print("You Died!")  # 打印"You Died!"
	Engine.time_scale = 0.5  # 将游戏速度减半
	body.get_node("CollisionShape2D").queue_free()  # 删除碰撞体
	timer.start()  # 开始计时器


# 当计时器超时时调用此函数
func _on_timer_timeout():
	Engine.time_scale = 1  # 恢复游戏速度
	get_tree().reload_current_scene()  # 重新加载当前场景

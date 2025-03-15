extends Area2D

# 组件引用
@onready var timer = $Timer

# 常量
const SLOW_MOTION_SCALE = 0.5
const NORMAL_TIME_SCALE = 1.0

# 当有物体进入Area2D时调用此函数
func _on_body_entered(body):
	print("You Died!")
	_handle_player_death(body)

# 处理玩家死亡逻辑
func _handle_player_death(player):
	# 启动慢动作效果
	Engine.time_scale = SLOW_MOTION_SCALE
	
	# 移除玩家碰撞体以防止多次触发
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").queue_free()
	
	# 开始重生计时器
	timer.start()

# 当计时器超时时调用此函数
func _on_timer_timeout():
	# 恢复正常游戏速度
	Engine.time_scale = NORMAL_TIME_SCALE
	
	# 重新加载当前场景
	get_tree().reload_current_scene()

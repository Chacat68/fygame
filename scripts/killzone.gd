extends Area2D

# 当有物体进入Area2D时调用此函数
func _on_body_entered(body):
	print("You Died!")
	_handle_player_death(body)

# 处理玩家死亡逻辑
func _handle_player_death(player):
	# 使用call_deferred延迟移除玩家碰撞体，避免在物理回调中直接移除
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").call_deferred("queue_free")
	
	# 使用call_deferred延迟重新加载场景，确保在物理处理完成后执行
	get_tree().call_deferred("reload_current_scene")

extends Area2D

# 当有物体进入Area2D时调用此函数
func _on_body_entered(body):
	# 检查碰撞的是否为玩家
	if body.is_in_group("player"):
		# 检查是否是掉落悬崖触发的killzone
		if global_position.y > 900: # 假设y坐标大于900的killzone是位于悬崖底部的
			print("Player fell off cliff!")
			# 直接调用玩家的死亡函数，绕过扣血逻辑
			if body.has_method("_die"):
				body._die()
			else:
				_handle_player_death(body)
			return
		# 如果不是掉落悬崖，而是其他类型的killzone（如尖刺等），则正常扣血
		elif body.has_method("take_damage"):
			print("Player took damage!")
			# 调用玩家的受伤函数
			body.take_damage()
			return
	
	# 如果没有血量系统或不是玩家，使用旧的死亡逻辑作为后备
	print("You Died!")
	_handle_player_death(body)

# 处理玩家死亡逻辑（作为后备机制）
func _handle_player_death(player):
	# 使用call_deferred延迟移除玩家碰撞体，避免在物理回调中直接移除
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").call_deferred("queue_free")
	
	# 使用call_deferred延迟重新加载场景，确保在物理处理完成后执行
	get_tree().call_deferred("reload_current_scene")

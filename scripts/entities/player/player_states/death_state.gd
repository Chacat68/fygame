class_name DeathState
extends PlayerState

# 死亡状态计时器
var death_timer = 0.0
var respawn_triggered = false

func enter():
	player.animated_sprite.play("death")
	death_timer = 0.0
	respawn_triggered = false
	
	# 禁用碰撞体，防止与其他物体交互
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# 更新死亡统计
	if GameState:
		GameState.add_death()

func physics_process(delta: float):
	# 应用重力（如果需要的话）
	player.velocity.y += player.gravity * delta
	
	# 停止水平移动
	player.velocity.x = 0
	
	# 更新死亡计时器
	death_timer += delta
	
	# 死亡动画播放一段时间后进行重生
	if death_timer >= 1.5 and not respawn_triggered:  # 死亡动画持续1.5秒
		respawn_triggered = true
		_handle_respawn()
	
	return null

## 处理玩家重生逻辑
func _handle_respawn():
	# 设置GameState中的复活标志
	if GameState:
		GameState.set_player_respawning(true)
	
	# 触发自动保存（保存死亡前的进度）
	if SaveManager:
		SaveManager.trigger_auto_save()
	
	# 尝试使用检查点系统重生
	var checkpoint_manager = player.get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_checkpoint():
		# 有激活的检查点，使用检查点重生
		_respawn_at_checkpoint(checkpoint_manager)
	else:
		# 没有检查点，重新加载整个场景
		player.get_tree().call_deferred("reload_current_scene")

## 在检查点位置重生
func _respawn_at_checkpoint(checkpoint_manager) -> void:
	var respawn_pos = checkpoint_manager.get_respawn_position()
	
	# 重新启用碰撞体
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").set_deferred("disabled", false)
	
	# 重置玩家位置
	player.global_position = respawn_pos
	
	# 重置玩家状态
	player.velocity = Vector2.ZERO
	player.current_health = player.MAX_HEALTH
	
	# 发出玩家重生信号
	if player.has_signal("respawned"):
		player.respawned.emit()
	
	# 触发重生视觉效果
	_play_respawn_effect()
	
	# 转换到Idle状态（通过 player 的方法）
	player._change_state("Idle")
	
	# 重置GameState中的复活标志
	if GameState:
		GameState.set_player_respawning(false)

## 播放重生视觉效果
func _play_respawn_effect():
	# 闪烁效果
	var tween = player.create_tween()
	for i in range(5):
		tween.tween_property(player.animated_sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(player.animated_sprite, "modulate:a", 1.0, 0.1)
	
	# 短暂无敌时间
	if player.has_method("start_invincibility"):
		player.start_invincibility(2.0)
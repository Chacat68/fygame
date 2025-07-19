class_name HurtState
extends PlayerState

var hurt_timer: float = 0.0

func enter():
	# 播放闪烁效果
	player.start_blink()
	
	hurt_timer = 0.0
	
	# 播放受伤音效
	# 使用AutoLoad的ResourceManager播放音效
	AudioManager.play_sfx("hurt")

func physics_process(delta: float):
	# 应用重力
	player.velocity.y += player.gravity * delta
	
	# 减缓水平移动
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 2 * delta)
	
	# 更新受伤计时器
	hurt_timer += delta
	
	# 受伤状态持续一段时间后恢复
	var hurt_duration = player.config.hurt_duration if player.config else 1.0
	if hurt_timer >= hurt_duration:
		# 检查是否应该死亡
		if player.current_health <= 0:
			return "Death"
		
		# 根据玩家状态返回到适当的状态
		if player.is_on_floor():
			if abs(player.velocity.x) > 0.1:
				return "Run"
			else:
				return "Idle"
		else:
			return "Fall"
	
	return null

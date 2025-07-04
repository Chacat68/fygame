class_name JumpState
extends PlayerState

func enter():
	if player.animated_sprite:
		player.animated_sprite.play("jump")
	# 播放跳跃音效
	# 使用AutoLoad的ResourceManager播放音效
	ResourceManager.play_sound("jump", player)

func physics_process(delta: float):
	# 应用重力
	player.velocity.y += player.gravity * delta
	
	# 检查是否开始下落
	if player.velocity.y > 0:
		return "Fall"
	
	# 处理移动
	var direction = Input.get_axis("move_left", "move_right")
	
	# 翻转精灵
	if direction != 0 and player.animated_sprite:
		player.animated_sprite.flip_h = (direction < 0)
	
	# 应用移动
	if direction:
		player.velocity.x = direction * player.SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	
	# 处理二段跳
	if Input.is_action_just_pressed("jump") and player.jumps_made < player.MAX_JUMPS:
		player.velocity.y = player.JUMP_VELOCITY
		player.jumps_made += 1
	
	return null

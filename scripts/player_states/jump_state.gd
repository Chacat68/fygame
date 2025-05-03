class_name JumpState
extends PlayerState

# 预加载ResourceManager类
const ResourceManagerClass = preload("res://scripts/resource_manager.gd")

func enter():
	player.animated_sprite.play("jump")
	# 播放跳跃音效
	# 使用资源管理器播放音效
	if Engine.has_singleton("ResourceManager"):
		Engine.get_singleton("ResourceManager").play_sound("jump", player)
	else:
		# 兼容旧代码
		if player.jump_sound:
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = player.jump_sound
			audio_player.volume_db = -10.0  # 降低音量
			player.add_child(audio_player)
			audio_player.play()
			# 设置音频播放完成后自动清理
			audio_player.finished.connect(func(): audio_player.queue_free())

func physics_process(delta: float):
	# 应用重力
	player.velocity.y += player.gravity * delta
	
	# 检查是否开始下落
	if player.velocity.y > 0:
		return "Fall"
	
	# 处理移动
	var direction = Input.get_axis("move_left", "move_right")
	
	# 翻转精灵
	if direction != 0:
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

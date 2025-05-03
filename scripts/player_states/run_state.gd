class_name RunState
extends PlayerState

func enter():
    player.animated_sprite.play("run")

func physics_process(delta: float):
    # 应用重力
    if not player.is_on_floor():
        player.velocity.y += player.gravity * delta
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
        return "Idle"
    
    # 处理跳跃
    if Input.is_action_just_pressed("jump"):
        player.velocity.y = player.JUMP_VELOCITY
        player.jumps_made = 1
        return "Jump"
    
    return null
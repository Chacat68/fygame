class_name IdleState
extends PlayerState

func enter():
    player.animated_sprite.play("idle")

func physics_process(delta: float):
    # 应用重力
    if not player.is_on_floor():
        player.velocity.y += player.gravity * delta
        return "Fall"
    
    # 检查状态转换
    var direction = Input.get_axis("move_left", "move_right")
    if direction != 0:
        return "Run"
    
    # 处理跳跃
    if Input.is_action_just_pressed("jump"):
        player.velocity.y = player.JUMP_VELOCITY
        player.jumps_made = 1
        return "Jump"
    
    # 保持静止
    player.velocity.x = 0
    
    return null
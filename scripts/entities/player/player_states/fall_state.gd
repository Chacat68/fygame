class_name FallState
extends PlayerState

func enter():
    if player.animated_sprite:
        player.animated_sprite.play("jump")  # 使用跳跃动画表示下落

func physics_process(delta: float):
    # 应用重力
    player.velocity.y += player.gravity * delta
    
    # 检查是否着陆
    if player.is_on_floor():
        # 重置墙跳计数
        player.reset_wall_jump_count()
        
        # 根据水平速度决定返回到哪个状态
        if abs(player.velocity.x) > 0.1:
            return "Run"
        else:
            return "Idle"
    
    # 检查墙滑
    if player.can_use_skill("wall_jump"):
        var wall_slide_state = player.states["WallSlide"]
        if wall_slide_state.can_wall_slide():
            return "WallSlide"
    
    # 检查冲刺技能
    if Input.is_action_just_pressed("dash") and player.can_use_skill("dash"):
        return "Dash"
    
    # 处理移动
    var direction = Input.get_axis("move_left", "move_right")
    
    # 翻转精灵
    if direction != 0 and player.animated_sprite:
        player.animated_sprite.flip_h = (direction < 0)
    
    # 应用移动
    if direction:
        player.velocity.x = direction * player.SPEED
    else:
        player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 0.5)  # 空中减速较慢
    
    # 处理二段跳
    if Input.is_action_just_pressed("jump") and player.jumps_made < player.MAX_JUMPS:
        player.velocity.y = player.JUMP_VELOCITY
        player.jumps_made += 1
        return "Jump"
    
    return null
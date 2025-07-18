# 墙跳状态
# 玩家从墙壁跳跃的状态
class_name WallJumpState
extends PlayerState

# 墙跳相关变量
var wall_jump_timer: float = 0.0
var wall_jump_duration: float = 0.3  # 墙跳状态持续时间
var wall_jump_force: float
var wall_jump_horizontal: float
var wall_normal: Vector2
var wall_slide_state: WallSlideState

func enter():
    """进入墙跳状态"""
    # 获取墙滑状态的引用
    wall_slide_state = player.state_machine.get_state("WallSlide") as WallSlideState
    
    if wall_slide_state:
        wall_normal = wall_slide_state.get_wall_normal()
        wall_slide_state.increment_wall_jump_count()
    
    # 获取技能参数
    wall_jump_force = player.skill_manager.get_wall_jump_force()
    wall_jump_horizontal = player.skill_manager.get_wall_jump_horizontal()
    
    # 重置计时器
    wall_jump_timer = 0.0
    
    # 设置墙跳速度
    _perform_wall_jump()
    
    # 播放墙跳动画
    player.animated_sprite.play("wall_jump")
    
    # 播放墙跳音效
    if ResourceManager.has_sound("wall_jump"):
        AudioManager.play_sound("wall_jump")
    
    # 发射技能使用信号
    player.skill_manager.skill_used.emit("wall_jump")
    
    print("执行墙跳，法向量: ", wall_normal, " 力度: ", wall_jump_force)

func exit():
    """退出墙跳状态"""
    wall_jump_timer = 0.0
    print("墙跳结束")

func physics_process(delta):
    """墙跳状态的物理处理"""
    wall_jump_timer += delta
    
    # 应用重力
    player.velocity.y += player.gravity * delta
    
    # 墙跳初期保持水平速度，后期允许玩家控制
    if wall_jump_timer < wall_jump_duration * 0.5:
        # 前半段保持墙跳的水平推力
        pass  # 保持enter()中设置的水平速度
    else:
        # 后半段允许玩家输入控制
        var horizontal_input = Input.get_axis("move_left", "move_right")
        if horizontal_input != 0:
            # 混合墙跳推力和玩家输入
            var input_force = horizontal_input * player.speed * 0.5
            player.velocity.x = lerp(player.velocity.x, input_force, delta * 3.0)
    
    # 移动玩家
    player.move_and_slide()
    
    # 检查状态转换
    if wall_jump_timer >= wall_jump_duration:
        # 墙跳时间结束，检查当前状态
        if player.is_on_floor():
            return "Idle"
        elif _can_wall_slide():
            return "WallSlide"
        else:
            return "Fall"
    
    # 检查是否可以再次墙跳
    if Input.is_action_just_pressed("jump") and _can_wall_slide():
        if wall_slide_state and wall_slide_state.can_wall_jump():
            return "WallJump"  # 连续墙跳
    
    return null

func handle_input(event):
    """处理墙跳状态下的输入"""
    # 检测连续墙跳
    if Input.is_action_just_pressed("jump") and _can_wall_slide():
        if wall_slide_state and wall_slide_state.can_wall_jump():
            return "WallJump"
    
    return null

func _perform_wall_jump():
    """执行墙跳动作"""
    # 向上的跳跃力
    player.velocity.y = -wall_jump_force
    
    # 远离墙壁的水平推力
    if wall_normal != Vector2.ZERO:
        player.velocity.x = wall_normal.x * wall_jump_horizontal
    else:
        # 如果没有墙壁法向量，使用玩家当前朝向的反方向
        var direction = 1 if player.animated_sprite.flip_h else -1
        player.velocity.x = direction * wall_jump_horizontal
    
    # 更新玩家朝向
    if player.velocity.x > 0:
        player.animated_sprite.flip_h = false
    elif player.velocity.x < 0:
        player.animated_sprite.flip_h = true
    
    # 3级墙跳技能：恢复空中跳跃次数
    var skill_level = player.skill_manager.get_skill_level("wall_jump")
    if skill_level >= 3:
        player.jump_count = 0  # 重置跳跃计数，允许再次空中跳跃

func _can_wall_slide() -> bool:
    """检查是否可以进入墙滑状态"""
    if not wall_slide_state:
        return false
    
    # 检查是否还在接触墙壁且在下落
    return wall_slide_state._is_touching_wall() and player.velocity.y > 0

func get_state_name() -> String:
    return "WallJump"

func can_transition_to(new_state: String) -> bool:
    """检查是否可以转换到新状态"""
    match new_state:
        "WallSlide":
            return _can_wall_slide()
        "Fall":
            return wall_jump_timer >= wall_jump_duration * 0.5
        "Idle", "Run":
            return player.is_on_floor()
        "Jump":
            # 允许在墙跳后进行普通跳跃（如果还有跳跃次数）
            return player.jump_count < player.max_jumps
        "WallJump":
            return _can_wall_slide() and wall_slide_state and wall_slide_state.can_wall_jump()
        "Hurt", "Death":
            return true
        _:
            return false

# 墙跳状态的特殊效果
func _on_wall_jump_land():
    """墙跳着地时的处理"""
    # 重置墙跳计数
    if wall_slide_state:
        wall_slide_state.wall_jump_count = 0
    
    # 播放着地音效
    if ResourceManager.has_sound("land"):
        AudioManager.play_sound("land")
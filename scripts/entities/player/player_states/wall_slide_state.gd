# 贴墙滑行状态
# 玩家贴在墙壁上滑行的状态
class_name WallSlideState
extends PlayerState

# 墙跳相关变量
var wall_normal: Vector2
var wall_cling_timer: float = 0.0
var wall_jump_count: int = 0
var max_wall_jumps: int
var wall_slide_speed: float
var wall_cling_time: float

# 墙壁检测射线
var wall_ray_right: RayCast2D
var wall_ray_left: RayCast2D

func _ready():
    """初始化墙壁检测射线"""
    _setup_wall_rays()

func _setup_wall_rays():
    """设置墙壁检测射线"""
    # 右侧墙壁检测
    wall_ray_right = RayCast2D.new()
    wall_ray_right.position = Vector2.ZERO
    wall_ray_right.target_position = Vector2(20, 0)  # 向右检测20像素
    wall_ray_right.enabled = true
    wall_ray_right.collision_mask = 1  # 只检测地形层
    player.add_child(wall_ray_right)
    
    # 左侧墙壁检测
    wall_ray_left = RayCast2D.new()
    wall_ray_left.position = Vector2.ZERO
    wall_ray_left.target_position = Vector2(-20, 0)  # 向左检测20像素
    wall_ray_left.enabled = true
    wall_ray_left.collision_mask = 1  # 只检测地形层
    player.add_child(wall_ray_left)

func enter():
    """进入贴墙滑行状态"""
    # 获取技能参数
    max_wall_jumps = player.skill_manager.get_max_wall_jumps()
    wall_slide_speed = player.skill_manager.get_wall_slide_speed()
    wall_cling_time = player.config.wall_cling_time
    
    # 重置计时器和跳跃计数
    wall_cling_timer = 0.0
    wall_jump_count = 0
    
    # 检测墙壁方向
    _detect_wall()
    
    # 播放贴墙动画
    player.animated_sprite.play("wall_slide")
    
    print("开始贴墙滑行，墙壁法向量: ", wall_normal)

func exit():
    """退出贴墙滑行状态"""
    wall_cling_timer = 0.0
    print("结束贴墙滑行")

func physics_process(delta):
    """贴墙滑行状态的物理处理"""
    wall_cling_timer += delta
    
    # 检查是否还在贴墙
    if not _is_touching_wall():
        return "Fall"  # 离开墙壁后进入下落状态
    
    # 检查是否着地
    if player.is_on_floor():
        return "Idle"  # 着地后进入空闲状态
    
    # 处理贴墙滑行
    if player.velocity.y > 0:  # 只在下落时减速
        player.velocity.y = min(player.velocity.y, wall_slide_speed)
    
    # 保持贴墙（轻微向墙壁方向的力）
    player.velocity.x = -wall_normal.x * 10
    
    # 移动玩家
    player.move_and_slide()
    
    return null

func handle_input(event):
    """处理贴墙滑行状态下的输入"""
    # 检测跳跃输入
    if Input.is_action_just_pressed("jump"):
        if wall_jump_count < max_wall_jumps:
            return "WallJump"
    
    # 检测离开墙壁的输入
    var horizontal_input = Input.get_axis("move_left", "move_right")
    if horizontal_input != 0:
        # 如果输入方向远离墙壁，离开贴墙状态
        if (wall_normal.x > 0 and horizontal_input < 0) or (wall_normal.x < 0 and horizontal_input > 0):
            return "Fall"
    
    return null

func _detect_wall():
    """检测墙壁方向"""
    if wall_ray_right.is_colliding():
        wall_normal = wall_ray_right.get_collision_normal()
    elif wall_ray_left.is_colliding():
        wall_normal = wall_ray_left.get_collision_normal()
    else:
        wall_normal = Vector2.ZERO

func _is_touching_wall() -> bool:
    """检查是否还在接触墙壁"""
    return wall_ray_right.is_colliding() or wall_ray_left.is_colliding()

func get_wall_normal() -> Vector2:
    """获取墙壁法向量"""
    return wall_normal

func increment_wall_jump_count():
    """增加墙跳计数"""
    wall_jump_count += 1

func get_wall_jump_count() -> int:
    """获取当前墙跳次数"""
    return wall_jump_count

func can_wall_jump() -> bool:
    """检查是否可以墙跳"""
    return wall_jump_count < max_wall_jumps and _is_touching_wall()

func get_state_name() -> String:
    return "WallSlide"

func can_transition_to(new_state: String) -> bool:
    """检查是否可以转换到新状态"""
    match new_state:
        "WallJump":
            return can_wall_jump()
        "Fall":
            return not _is_touching_wall()
        "Idle", "Run":
            return player.is_on_floor()
        "Hurt", "Death":
            return true
        _:
            return false
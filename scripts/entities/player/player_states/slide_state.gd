# 滑铲状态
# 玩家进行滑铲攻击的状态
class_name SlideState
extends PlayerState

# 滑铲相关变量
var slide_timer: float = 0.0
var slide_duration: float
var slide_speed: float
var slide_damage: int
var slide_friction: float
var slide_direction: int

# 碰撞体积相关
var original_collision_shape: Shape2D
var slide_collision_shape: RectangleShape2D
var collision_shape_node: CollisionShape2D

# 攻击检测区域
var slide_attack_area: Area2D
var slide_attack_collision: CollisionShape2D
var attacked_enemies: Array = []  # 记录已攻击的敌人，避免重复伤害

func _ready():
    """初始化滑铲攻击区域"""
    _setup_slide_attack_area()

func _setup_slide_attack_area():
    """设置滑铲攻击检测区域"""
    # 创建攻击检测区域
    slide_attack_area = Area2D.new()
    slide_attack_area.name = "SlideAttackArea"
    slide_attack_area.collision_layer = 0  # 不参与物理碰撞
    slide_attack_area.collision_mask = 4   # 只检测敌人层（假设敌人在第3层）
    
    # 创建攻击区域的碰撞形状
    slide_attack_collision = CollisionShape2D.new()
    var attack_shape = RectangleShape2D.new()
    attack_shape.size = Vector2(40, 20)  # 攻击范围
    slide_attack_collision.shape = attack_shape
    slide_attack_collision.position = Vector2(0, 5)  # 稍微向下偏移
    
    slide_attack_area.add_child(slide_attack_collision)
    player.add_child(slide_attack_area)
    
    # 连接信号
    slide_attack_area.body_entered.connect(_on_slide_attack_hit)
    slide_attack_area.area_entered.connect(_on_slide_attack_hit_area)

func enter():
    """进入滑铲状态"""
    # 获取技能参数
    slide_duration = player.skill_manager.get_slide_duration()
    slide_speed = player.skill_manager.get_slide_speed()
    slide_damage = player.skill_manager.get_slide_damage()
    slide_friction = player.config.slide_friction
    
    # 确定滑铲方向
    var horizontal_input = Input.get_axis("move_left", "move_right")
    if horizontal_input != 0:
        slide_direction = 1 if horizontal_input > 0 else -1
    else:
        slide_direction = 1 if not player.animated_sprite.flip_h else -1
    
    # 重置计时器和攻击记录
    slide_timer = 0.0
    attacked_enemies.clear()
    
    # 修改碰撞体积
    _change_collision_shape()
    
    # 设置滑铲速度
    player.velocity.x = slide_direction * slide_speed
    player.velocity.y = 0  # 滑铲时贴地
    
    # 更新玩家朝向
    player.animated_sprite.flip_h = slide_direction < 0
    
    # 播放滑铲动画
    player.animated_sprite.play("slide")
    
    # 播放滑铲音效
    AudioManager.play_sfx("slide")
    
    # 启用攻击区域
    slide_attack_area.monitoring = true
    
    # 发射技能使用信号
    player.skill_manager.skill_used.emit("slide")
    
    print("开始滑铲，方向: ", slide_direction, " 速度: ", slide_speed)

func exit():
    """退出滑铲状态"""
    # 恢复原始碰撞体积
    _restore_collision_shape()
    
    # 禁用攻击区域
    slide_attack_area.monitoring = false
    
    # 清空攻击记录
    attacked_enemies.clear()
    
    print("滑铲结束")

func physics_process(delta):
    """滑铲状态的物理处理"""
    slide_timer += delta
    
    # 检查滑铲是否结束
    if slide_timer >= slide_duration:
        return _get_exit_state()
    
    # 应用摩擦力减速
    player.velocity.x *= slide_friction
    
    # 保持贴地（轻微向下的力）
    if not player.is_on_floor():
        player.velocity.y += player.gravity * delta
    else:
        player.velocity.y = 0
    
    # 检查是否撞墙
    if player.is_on_wall():
        player.velocity.x = 0
        return _get_exit_state()
    
    # 移动玩家
    player.move_and_slide()
    
    return null

func handle_input():
    """处理滑铲状态下的输入"""
    # 3级滑铲技能：滑铲结束时可以直接跳跃
    var skill_level = player.skill_manager.get_skill_level("slide")
    if skill_level >= 3 and Input.is_action_just_pressed("jump"):
        if slide_timer > slide_duration * 0.7:  # 滑铲进行70%后可以跳跃
            return "Jump"
    
    return null

func _change_collision_shape():
    """修改碰撞体积为滑铲形状"""
    collision_shape_node = player.get_node("CollisionShape2D")
    if collision_shape_node:
        # 保存原始形状
        original_collision_shape = collision_shape_node.shape
        
        # 创建滑铲碰撞形状（更矮更宽）
        slide_collision_shape = RectangleShape2D.new()
        var original_size = original_collision_shape.size
        slide_collision_shape.size = Vector2(original_size.x * 1.2, original_size.y * 0.5)
        
        # 应用新形状
        collision_shape_node.shape = slide_collision_shape
        
        # 调整位置（向下偏移）
        collision_shape_node.position.y += original_size.y * 0.25

func _restore_collision_shape():
    """恢复原始碰撞体积"""
    if collision_shape_node and original_collision_shape:
        collision_shape_node.shape = original_collision_shape
        collision_shape_node.position.y = 0  # 重置位置

func _get_exit_state() -> String:
    """确定滑铲结束后的状态"""
    if player.is_on_floor():
        var horizontal_input = Input.get_axis("move_left", "move_right")
        if horizontal_input != 0:
            return "Run"
        else:
            return "Idle"
    else:
        return "Fall"

func _on_slide_attack_hit(body):
    """滑铲攻击命中敌人"""
    if body.is_in_group("enemy") and body not in attacked_enemies:
        _deal_slide_damage(body)

func _on_slide_attack_hit_area(area):
    """滑铲攻击命中敌人区域"""
    var body = area.get_parent()
    if body and body.is_in_group("enemy") and body not in attacked_enemies:
        _deal_slide_damage(body)

func _deal_slide_damage(enemy):
    """对敌人造成滑铲伤害"""
    # 记录已攻击的敌人
    attacked_enemies.append(enemy)
    
    # 造成伤害
    if enemy.has_method("take_damage"):
        enemy.take_damage(slide_damage)
    elif enemy.has_method("die"):
        enemy.die()  # 直接击杀
    
    # 播放攻击音效
    if ResourceManager.has_sound("slide_hit"):
        AudioManager.play_sfx("slide_hit")
    
    # 创建伤害飘字
    FloatingTextManager.create_floating_text(
        str(slide_damage),
        enemy.global_position,
        Color.ORANGE
    )
    
    print("滑铲命中敌人: ", enemy.name, " 伤害: ", slide_damage)

func get_state_name() -> String:
    return "Slide"

func can_transition_to(new_state: String) -> bool:
    """检查是否可以转换到新状态"""
    match new_state:
        "Jump":
            # 3级技能允许滑铲后直接跳跃
            var skill_level = player.skill_manager.get_skill_level("slide")
            return skill_level >= 3 and slide_timer > slide_duration * 0.7
        "Idle", "Run":
            return slide_timer >= slide_duration and player.is_on_floor()
        "Fall":
            return slide_timer >= slide_duration and not player.is_on_floor()
        "Hurt", "Death":
            return true
        _:
            return false

# 滑铲状态的特殊效果
func _create_slide_dust_effect():
    """创建滑铲尘土特效"""
    # 这里可以添加粒子效果或其他视觉特效
    pass

func get_slide_progress() -> float:
    """获取滑铲进度（0-1）"""
    return slide_timer / slide_duration

func is_slide_ending() -> bool:
    """检查滑铲是否即将结束"""
    return slide_timer > slide_duration * 0.8
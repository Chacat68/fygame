# 冲刺状态
# 玩家进行快速冲刺移动的状态
class_name DashState
extends PlayerState

# 冲刺相关变量
var dash_timer: float = 0.0
var dash_direction: Vector2
var dash_speed: float
var dash_duration: float
var original_collision_layer: int

func enter():
    """进入冲刺状态"""
    # 获取冲刺方向
    dash_direction = Vector2(Input.get_axis("move_left", "move_right"), 0)
    
    # 如果没有输入方向，使用玩家当前朝向
    if dash_direction.x == 0:
        dash_direction.x = 1 if not player.animated_sprite.flip_h else -1
    
    # 标准化方向向量
    dash_direction = dash_direction.normalized()
    
    # 获取技能参数
    dash_speed = player.skill_manager.get_dash_speed()
    dash_duration = player.skill_manager.get_dash_duration()
    
    # 设置冲刺速度
    player.velocity = dash_direction * dash_speed
    
    # 重置计时器
    dash_timer = 0.0
    
    # 设置无敌状态
    if player.skill_manager.is_dash_invincible():
        player.set_temporary_invincible(dash_duration)
    
    # 保存原始碰撞层并设置冲刺碰撞层
    original_collision_layer = player.collision_layer
    # 可以设置特殊的冲刺碰撞层，允许穿过某些物体
    # player.collision_layer = 2  # 假设2是冲刺专用层
    
    # 播放冲刺动画
    player.animated_sprite.play("dash")
    
    # 播放冲刺音效
    if ResourceManager.has_sound("dash"):
        AudioManager.play_sound("dash")
    
    # 发射技能使用信号
    player.skill_manager.skill_used.emit("dash")
    
    print("开始冲刺，方向: ", dash_direction, " 速度: ", dash_speed)

func exit():
    """退出冲刺状态"""
    # 恢复原始碰撞层
    player.collision_layer = original_collision_layer
    
    # 重置速度（保持一些水平动量）
    player.velocity.x *= 0.3
    
    print("冲刺结束")

func physics_process(delta):
    """冲刺状态的物理处理"""
    dash_timer += delta
    
    # 检查冲刺是否结束
    if dash_timer >= dash_duration:
        return "Fall"  # 冲刺结束后进入下落状态
    
    # 应用重力（减少重力影响）
    player.velocity.y += player.gravity * delta * 0.3  # 冲刺时重力减少70%
    
    # 保持冲刺速度
    player.velocity.x = dash_direction.x * dash_speed
    
    # 移动玩家
    player.move_and_slide()
    
    # 检查是否撞墙或着地
    if player.is_on_wall():
        return "Fall"  # 撞墙后结束冲刺
    
    if player.is_on_floor() and dash_timer > dash_duration * 0.5:
        # 冲刺进行一半后如果着地，可以提前结束
        return "Idle"
    
    return null

func handle_input(event):
    """处理冲刺状态下的输入"""
    # 冲刺期间不处理其他输入
    return null

func get_state_name() -> String:
    return "Dash"

# 冲刺状态下的特殊效果
func _on_dash_hit_enemy(enemy):
    """冲刺撞击敌人时的处理"""
    var skill_level = player.skill_manager.get_skill_level("dash")
    
    # 3级冲刺可以造成伤害
    if skill_level >= 3 and enemy.has_method("take_damage"):
        enemy.take_damage(15)  # 冲刺伤害
        
        # 播放撞击特效
        if ResourceManager.has_sound("dash_hit"):
            AudioManager.play_sound("dash_hit")

func can_transition_to(new_state: String) -> bool:
    """检查是否可以转换到新状态"""
    # 冲刺期间只能转换到特定状态
    match new_state:
        "Fall", "Hurt", "Death":
            return true
        "Idle", "Run":
            # 只有在冲刺快结束时才能转换到地面状态
            return dash_timer > dash_duration * 0.7 and player.is_on_floor()
        _:
            return false
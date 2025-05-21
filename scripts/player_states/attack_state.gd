class_name AttackState
extends PlayerState

# 攻击状态计时器
var attack_timer = 0.0
const ATTACK_DURATION = 0.3  # 攻击动作持续时间

func enter():
    player.animated_sprite.play("attack")
    attack_timer = 0.0
    
    # 创建攻击判定区域
    _create_attack_hitbox()

func physics_process(delta: float):
    # 应用重力
    if not player.is_on_floor():
        player.velocity.y += player.gravity * delta
        return "Fall"
    
    # 更新攻击计时器
    attack_timer += delta
    
    # 攻击动作结束后返回之前的状态
    if attack_timer >= ATTACK_DURATION:
        if abs(player.velocity.x) > 0.1:
            return "Run"
        else:
            return "Idle"
    
    # 保持水平移动
    var direction = Input.get_axis("move_left", "move_right")
    if direction != 0:
        player.velocity.x = direction * player.SPEED
        player.animated_sprite.flip_h = (direction < 0)
    else:
        player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
    
    return null

# 创建攻击判定区域
func _create_attack_hitbox():
    if not player.has_node("AttackHitbox"):
        # 创建攻击判定区域
        var hitbox = Area2D.new()
        hitbox.name = "AttackHitbox"
        player.add_child(hitbox)
        
        # 创建碰撞形状
        var collision_shape = CollisionShape2D.new()
        collision_shape.name = "CollisionShape2D"
        hitbox.add_child(collision_shape)
        
        # 创建矩形形状
        var shape = RectangleShape2D.new()
        shape.size = Vector2(40, 20)  # 攻击判定区域大小
        collision_shape.shape = shape
        
        # 设置碰撞区域位置（在玩家前方）
        collision_shape.position = Vector2(20, -10)
        
        # 设置碰撞掩码，只检测可破坏物体层
        hitbox.collision_mask = 4  # 假设可破坏物体在第3层
        
        # 连接信号
        hitbox.connect("area_entered", _on_attack_hitbox_area_entered)

# 当攻击判定区域碰到可破坏物体时
func _on_attack_hitbox_area_entered(area):
    if area.get_parent() is StaticBody2D:  # 检查是否是平台
        var platform = area.get_parent()
        if platform.has_method("take_damage"):
            platform.take_damage(20)  # 造成20点伤害 
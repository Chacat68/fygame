# 敌人AI与战斗系统

## 概述

本文档详细描述了游戏中的敌人AI行为模式和战斗系统，包括敌人类型、行为逻辑、战斗机制和伤害计算等方面。

## 敌人类型

### 史莱姆

史莱姆是游戏中的基础敌人，分为两种类型：

#### 1. 绿色史莱姆

**属性**：
- 移动速度：45
- 生命值：20
- 伤害值：10
- 击退力度：中等

**行为特点**：
- 基础巡逻行为
- 平台边缘检测
- 简单的碰撞反应

#### 2. 紫色史莱姆

**属性**：
- 移动速度：60（比绿色史莱姆更快）
- 生命值：40（比绿色史莱姆更高）
- 伤害值：15
- 击退力度：较大

**行为特点**：
- 更积极的巡逻行为
- 平台边缘检测
- 可能的跳跃能力
- 更强的碰撞反应

## 敌人AI系统

### 移动逻辑

```gdscript
# 每一帧都会调用此函数。'delta' 是自上一帧以来的经过时间。
func _process(delta):
    # 如果怪物已死亡，不再处理移动逻辑
    if is_dead:
        return
        
    _check_direction()
    _move(delta)
```

### 方向检测

敌人使用射线检测来避免掉落平台边缘和检测墙壁：

```gdscript
# 检查并更新移动方向
func _check_direction():
    # 获取地面检测射线
    var floor_check_right = get_node_or_null("FloorCheckRight")
    var floor_check_left = get_node_or_null("FloorCheckLeft")
    
    # 确保地面检测射线存在并启用
    if floor_check_right and floor_check_left:
        # 优先检测平台边缘
        # 如果右侧没有地面，向左转
        if direction == 1 and not floor_check_right.is_colliding():
            direction = -1
            animated_sprite.flip_h = true
            return # 已经改变方向，不需要继续检测
        # 如果左侧没有地面，向右转
        elif direction == -1 and not floor_check_left.is_colliding():
            direction = 1
            animated_sprite.flip_h = false
            return # 已经改变方向，不需要继续检测
    
    # 检测是否碰到墙壁
    if ray_cast_right.is_colliding():
        direction = -1
        animated_sprite.flip_h = true
    elif ray_cast_left.is_colliding():
        direction = 1
        animated_sprite.flip_h = false
```

### 移动实现

```gdscript
# 根据当前方向移动
func _move(delta):
    # 应用重力
    if not is_on_floor():
        velocity.y += gravity * delta
    
    # 设置水平速度
    velocity.x = direction * SPEED
    
    # 移动角色
    move_and_slide()
```

### 射线检测设置

敌人使用多个射线进行环境检测：

```gdscript
# 创建地面检测射线
func _create_floor_checks():
    # 创建右侧地面检测射线
    if not has_node("FloorCheckRight"):
        var floor_check = RayCast2D.new()
        floor_check.name = "FloorCheckRight"
        add_child(floor_check)
        floor_check.position = Vector2(15, 6) # 右侧射线位置
        floor_check.target_position = Vector2(0, 20) # 向下检测
        floor_check.enabled = true
        # 确保射线只检测地形层
        floor_check.collision_mask = 1
    
    # 创建左侧地面检测射线
    if not has_node("FloorCheckLeft"):
        var floor_check = RayCast2D.new()
        floor_check.name = "FloorCheckLeft"
        add_child(floor_check)
        floor_check.position = Vector2(-15, 6) # 左侧射线位置
        floor_check.target_position = Vector2(0, 20) # 向下检测
        floor_check.enabled = true
        # 确保射线只检测地形层
        floor_check.collision_mask = 1
```

## 战斗系统

### 碰撞检测

#### 敌人头部碰撞区域

```gdscript
# 创建头部碰撞检测区域
func _create_head_hitbox():
    if not has_node("HeadHitbox"):
        var area = Area2D.new()
        area.name = "HeadHitbox"
        add_child(area)
        
        var collision = CollisionShape2D.new()
        var shape = RectangleShape2D.new()
        shape.size = Vector2(20, 5) # 头部碰撞区域大小
        collision.shape = shape
        collision.position = Vector2(0, -10) # 头部位置
        area.add_child(collision)
        
        # 连接信号
        area.connect("body_entered", _on_head_hitbox_body_entered)
```

#### 玩家与敌人碰撞处理

当玩家从上方踩踏敌人时：

```gdscript
# 当玩家踩到敌人头部时调用
func _on_head_hitbox_body_entered(body):
    # 检查碰撞体是否为玩家
    if body.is_in_group("player"):
        # 检查玩家是否从上方踩踏（垂直速度为正）
        if body.velocity.y > 0:
            # 敌人受到伤害
            take_damage(body)
            
            # 玩家反弹
            body.velocity.y = -200 # 给玩家一个向上的反弹力
```

当敌人碰到玩家时：

```gdscript
# 当敌人碰到玩家时调用
func _on_body_entered(body):
    # 检查碰撞体是否为玩家
    if body.is_in_group("player"):
        # 检查是否不是头部碰撞
        if not is_head_collision(body):
            # 玩家受到伤害
            body.take_damage(10, global_position)
```

### 伤害系统

#### 敌人受伤逻辑

```gdscript
# 敌人受到伤害
func take_damage(attacker):
    # 如果已经死亡，不再处理
    if is_dead:
        return
    
    # 减少生命值
    health -= 10
    
    # 显示伤害数字
    _show_damage_number(10)
    
    # 检查是否死亡
    if health <= 0:
        _die()
    else:
        # 受伤效果
        _hurt_effect()
        
        # 击退效果
        _apply_knockback(attacker)
```

#### 敌人死亡逻辑

```gdscript
# 敌人死亡
func _die():
    # 设置死亡标志
    is_dead = true
    
    # 播放死亡动画
    animated_sprite.play("death")
    
    # 禁用碰撞
    $CollisionShape2D.disabled = true
    
    # 增加玩家分数
    if Engine.has_singleton("GameManager"):
        Engine.get_singleton("GameManager").add_point()
    
    # 生成金币奖励
    _spawn_coin_reward()
    
    # 延迟后移除
    await get_tree().create_timer(1.0).timeout
    queue_free()
```

#### 击退效果

```gdscript
# 应用击退效果
func _apply_knockback(attacker):
    # 计算击退方向
    var knockback_direction = global_position - attacker.global_position
    knockback_direction = knockback_direction.normalized()
    
    # 应用击退力
    velocity = knockback_direction * 200
```

### 视觉反馈

#### 伤害数字显示

```gdscript
# 显示伤害数字
func _show_damage_number(damage_amount):
    # 创建浮动文本实例
    var floating_text = floating_text_scene.instantiate()
    get_parent().add_child(floating_text)
    
    # 设置文本位置和内容
    floating_text.global_position = global_position + Vector2(0, -20)
    floating_text.set_text(str(damage_amount))
    floating_text.set_color(Color(1, 0.3, 0.3)) # 红色
```

#### 受伤效果

```gdscript
# 受伤视觉效果
func _hurt_effect():
    # 闪烁效果
    modulate = Color(1, 0.5, 0.5) # 变红
    await get_tree().create_timer(0.2).timeout
    modulate = Color(1, 1, 1) # 恢复正常颜色
```

## 敌人生成系统

### 敌人实例化

```gdscript
# 实例化敌人
func _instantiate_enemy(enemy_data):
    var enemy = slime_scene.instantiate()
    enemy.position = enemy_data.position
    
    # 根据敌人类型设置属性
    if enemy_data.type == "purple_slime":
        # 设置为紫色史莱姆
        enemy.get_node("AnimatedSprite2D").modulate = Color(0.8, 0.3, 0.8) # 紫色
        enemy.SPEED = 60 # 更快的速度
        enemy.health = 40 # 更高的生命值
    
    # 添加到场景
    $Enemies.add_child(enemy)
```

### 敌人难度调整

```gdscript
# 根据关卡难度调整敌人属性
func _adjust_enemy_difficulty(enemy, difficulty_level):
    # 基础难度倍数
    var difficulty_multiplier = 1.0 + (difficulty_level * 0.1) # 每级增加10%
    
    # 调整敌人属性
    enemy.SPEED *= difficulty_multiplier # 增加速度
    enemy.health *= difficulty_multiplier # 增加生命值
```

## 战斗平衡性

### 难度曲线

游戏的难度曲线通过以下方式实现：

1. **敌人数量**：随关卡增加而增加
2. **敌人类型**：高级关卡中紫色史莱姆比例增加
3. **敌人属性**：随关卡增加而提升
4. **平台布局**：更复杂的跳跃挑战

### 奖励系统

击败敌人的奖励：

1. **分数增加**：每击败一个敌人增加1分
2. **金币奖励**：敌人死亡时有几率掉落金币
3. **特殊道具**：高级敌人有几率掉落特殊道具

## 战斗策略

### 玩家策略

1. **跳跃攻击**：从上方踩踏敌人是主要攻击方式
2. **躲避**：避开敌人的正面接触
3. **时机把握**：在合适的时机进行攻击，避免被多个敌人包围

### 敌人行为模式

1. **巡逻**：在平台上左右移动
2. **边缘检测**：避免掉落平台
3. **碰撞反应**：碰到墙壁或其他障碍物时改变方向

## 实现注意事项

1. **性能优化**：
   - 使用对象池减少实例化开销
   - 只处理屏幕附近的敌人AI
   - 优化碰撞检测

2. **可扩展性**：
   - 设计允许轻松添加新的敌人类型
   - 支持自定义敌人行为
   - 允许添加新的攻击模式

3. **平衡性**：
   - 确保敌人难度与关卡进度匹配
   - 平衡敌人数量和分布
   - 提供足够的挑战但不过于困难

---

本文档详细描述了游戏中的敌人AI与战斗系统。开发人员应参考此文档进行敌人行为和战斗机制的实现和扩展。如有任何更新或修改，请及时更新本文档。
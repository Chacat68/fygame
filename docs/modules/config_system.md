# 游戏配置系统设计文档

## 概述

游戏配置系统（GameConfig）是项目中的核心配置管理组件，用于统一管理游戏中的各种数值参数，避免硬编码，提高游戏的可配置性和可维护性。

## 系统架构

### 配置资源类

`GameConfig`继承自Godot的`Resource`类，位于`/scripts/systems/game_config.gd`，作为游戏配置的核心数据结构。

### 配置分组

配置参数按功能模块进行分组，便于在编辑器中管理：

#### 玩家移动配置
- `player_speed: float = 180.0` - 玩家水平移动速度（像素/秒）
- `player_gravity: float = 800.0` - 玩家重力加速度（像素/秒²）

#### 玩家跳跃配置
- `player_jump_velocity: float = -280.0` - 玩家跳跃初始速度（像素/秒）
- `player_max_jumps: int = 2` - 玩家最大跳跃次数

#### 玩家生命配置
- `player_max_health: int = 100` - 玩家最大生命值
- `player_damage_amount: int = 10` - 玩家受到的伤害量
- `player_invincibility_time: float = 1.0` - 玩家无敌时间（秒）

#### 敌人配置
- `slime_speed: float = 50.0` - 史莱姆巡逻速度
- `slime_patrol_distance: float = 100.0` - 史莱姆巡逻距离
- `slime_chase_speed: float = 80.0` - 史莱姆追击速度
- `slime_attack_range: float = 30.0` - 史莱姆攻击范围
- `slime_health: int = 1` - 史莱姆生命值

#### 其他配置
- `death_height: float = 300.0` - 关卡死亡高度
- `hurt_duration: float = 1.0` - 受伤状态持续时间
- `coin_value: int = 1` - 金币价值
- `floating_text_speed: float = 50.0` - 浮动文本速度
- `floating_text_fade_duration: float = 2.0` - 浮动文本淡出时间

## 高级特性

### 范围限制参数

为了在编辑器中提供更好的用户体验，配置系统支持带范围限制的参数：

```gdscript
# 带范围限制的玩家移动速度（50-500像素/秒，步长10）
@export_range(50.0, 500.0, 10.0) var player_speed_ranged: float = 250.0

# 带范围限制的玩家跳跃速度（-800到-100像素/秒，步长50）
@export_range(-800.0, -100.0, 50.0) var player_jump_velocity_ranged: float = -400.0
```

### 配置验证系统

配置系统包含内置的验证机制，确保参数的合理性：

```gdscript
func validate_config() -> bool:
    var warnings = []
    
    # 检查物理参数的合理性
    if player_jump_velocity >= 0:
        warnings.append("警告：跳跃速度应为负值")
    
    if player_gravity <= 0:
        warnings.append("警告：重力应为正值")
    
    if player_speed <= 0:
        warnings.append("警告：移动速度应为正值")
    
    # 输出警告信息
    for warning in warnings:
        print(warning)
    
    return warnings.is_empty()
```

## 使用方式

### 静态访问方法

配置系统提供静态方法用于获取配置实例：

```gdscript
static func get_config() -> GameConfig:
    var config = load("res://resources/game_config.tres") as GameConfig
    if config:
        config.validate_config()  # 验证配置
        return config
    else:
        print("警告：无法加载游戏配置文件，使用默认配置")
        var default_config = GameConfig.new()
        default_config.validate_config()
        return default_config
```

### 在游戏实体中使用

各个游戏实体通过配置系统获取参数：

```gdscript
# 在玩家脚本中
func _init_config():
    config = GameConfig.get_config()
    
    # 设置角色属性
    SPEED = config.player_speed
    JUMP_VELOCITY = config.player_jump_velocity
    MAX_JUMPS = config.player_max_jumps
    # ...

# 在敌人脚本中
func _init_config():
    config = GameConfig.get_config()
    
    # 设置史莱姆属性
    SPEED = config.slime_speed
    CHASE_SPEED = config.slime_chase_speed
    PATROL_DISTANCE = config.slime_patrol_distance
    # ...
```

## 配置文件

配置数据存储在`/resources/game_config.tres`文件中，这是一个Godot资源文件，可以在编辑器中直接编辑。

## 优势

1. **统一管理**：所有游戏参数集中在一个地方管理
2. **避免硬编码**：参数不再分散在各个脚本中
3. **易于调试**：可以快速调整参数进行游戏平衡
4. **编辑器友好**：支持在Godot编辑器中可视化编辑
5. **类型安全**：利用GDScript的类型系统确保参数类型正确
6. **验证机制**：内置验证确保参数的合理性
7. **热重载**：配置更改可以在运行时生效

## 扩展指南

### 添加新配置参数

1. 在`GameConfig`类中添加新的`@export`变量
2. 在`validate_config()`方法中添加相应的验证逻辑
3. 在需要使用该参数的脚本中通过`config.parameter_name`访问
4. 更新相关文档

### 添加新的配置分组

使用`@export_group("分组名称")`来创建新的参数分组：

```gdscript
@export_group("新功能配置")
@export var new_feature_enabled: bool = true
@export var new_feature_value: float = 1.0
```

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本文档描述了游戏配置系统的设计和使用方法。该系统是项目架构的重要组成部分，为游戏的可配置性和可维护性提供了强有力的支持。
# 传送系统设计文档

## 概述

传送系统是游戏中的高级功能模块，提供玩家快速移动和场景传送的能力。系统基于配置驱动的设计，支持多种传送模式和安全检查机制。

## 系统架构

### 核心组件

#### TeleportManager
位于`/scripts/systems/teleport_manager.gd`，作为传送系统的核心管理器：

```gdscript
class_name TeleportManager

# 传送相关信号
signal teleport_started(player, destination)
signal teleport_completed(player, destination)
signal teleport_failed(reason)
signal teleport_cooldown_finished()
```

#### TeleportConfig
位于`/scripts/systems/teleport_config.gd`，定义传送系统的配置参数：

- 传送距离限制
- 冷却时间设置
- 传送预设模式
- 安全检查参数

### 信号系统

传送系统使用信号机制来通知其他系统传送状态的变化：

- `teleport_started`：传送开始时触发
- `teleport_completed`：传送完成时触发
- `teleport_failed`：传送失败时触发，包含失败原因
- `teleport_cooldown_finished`：冷却时间结束时触发

## 功能特性

### 冷却时间机制

```gdscript
# 检查是否可以传送（冷却时间检查）
func can_teleport() -> bool:
    if is_teleporting:
        return false
    
    var current_time = Time.get_time_dict_from_system()
    var time_since_last = current_time.hour * 3600 + current_time.minute * 60 + current_time.second - last_teleport_time
    
    return time_since_last >= config.cooldown_time
```

### 距离限制检查

系统会检查传送距离是否超过配置的最大传送距离：

```gdscript
# 检查传送距离
var distance = player_node.global_position.distance_to(portal.global_position)
if distance > config.max_teleport_distance:
    teleport_failed.emit("传送距离过远")
    return false
```

### 安全位置检测

传送系统包含安全位置检测机制，确保玩家不会传送到危险位置：

```gdscript
# 检查传送位置是否安全
if not _is_position_safe(destination):
    # 尝试寻找附近的安全位置
    destination = _find_safe_position_nearby(destination)
```

### 传送动画效果

系统支持传送过程中的视觉效果，使用Godot 4的Tween系统：

```gdscript
# 传送特效节点
var tween: Tween

# 在需要时通过 create_tween() 创建
# 注意：每次使用时需要重新创建 Tween
```

## 集成方式

### 在UI系统中的集成

传送系统已集成到UI系统中，通过`CoinCounter`脚本管理：

```gdscript
# 引入传送管理器
const TeleportManagerClass = preload("res://scripts/systems/teleport_manager.gd")

# 传送管理器实例
var teleport_manager: TeleportManagerClass

func _ready():
    # 初始化传送管理器
    teleport_manager = TeleportManagerClass.new()
    add_child(teleport_manager)
    
    # 加载传送配置
    var config = load("res://resources/default_teleport_config.tres") as TeleportConfig
    if config:
        teleport_manager.set_config(config)
    
    # 连接传送管理器信号
    teleport_manager.teleport_started.connect(_on_teleport_started)
    teleport_manager.teleport_completed.connect(_on_teleport_completed)
    teleport_manager.teleport_failed.connect(_on_teleport_failed)
    teleport_manager.teleport_cooldown_finished.connect(_on_teleport_cooldown_finished)
```

### 配置文件

传送配置存储在`/resources/default_teleport_config.tres`中，包含：

- 传送距离限制
- 冷却时间设置
- 传送模式预设
- 安全检查参数

## 使用场景

### Portal传送

主要的传送功能是通过Portal（传送门）实现：

```gdscript
# 传送到指定的Portal
func teleport_to_portal(player_node: Node2D = null) -> bool:
    # 检查是否可以传送
    if not can_teleport():
        teleport_failed.emit("传送冷却中，请稍后再试")
        return false
    
    # 查找Portal节点
    var portal = _find_portal()
    if not portal:
        teleport_failed.emit("未找到传送门节点")
        return false
    
    # 执行传送逻辑
    # ...
```

### 调试和测试

系统提供了测试界面，便于开发过程中的调试：

- 测试按钮：触发传送功能测试
- 测试面板：显示传送状态和参数
- 传送按钮：手动触发传送操作

## 错误处理

传送系统包含完善的错误处理机制：

1. **玩家节点检查**：确保玩家节点存在
2. **传送门检查**：确保目标传送门存在
3. **距离检查**：验证传送距离是否合理
4. **冷却时间检查**：防止频繁传送
5. **安全位置检查**：确保传送目标位置安全

所有错误都会通过`teleport_failed`信号通知，并包含详细的错误信息。

## 扩展性

### 添加新的传送模式

可以通过扩展`TeleportConfig`来添加新的传送模式：

```gdscript
enum TeleportMode {
    INSTANT,    # 瞬间传送
    SMOOTH,     # 平滑传送
    FADE,       # 淡入淡出传送
    CUSTOM      # 自定义传送
}
```

### 添加传送限制条件

可以在传送检查中添加更多限制条件：

```gdscript
# 检查玩家状态
if player.is_in_combat():
    emit_signal("teleport_failed", "战斗中无法传送")
    return false

# 检查区域限制
if not _is_teleport_allowed_in_area(player.global_position):
    emit_signal("teleport_failed", "此区域禁止传送")
    return false
```

## 性能考虑

1. **资源管理**：Tween对象按需创建，避免内存泄漏
2. **信号连接**：合理管理信号连接，避免重复连接
3. **配置缓存**：配置文件加载后缓存，避免重复加载
4. **位置检查优化**：使用高效的碰撞检测算法

## 调试工具

系统提供了多种调试工具：

1. **控制台输出**：详细的日志信息
2. **测试界面**：可视化的测试工具
3. **配置验证**：配置参数的合理性检查
4. **状态监控**：实时监控传送系统状态

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本文档详细描述了传送系统的设计和实现。该系统为游戏提供了灵活、安全、可扩展的传送功能，是游戏高级功能的重要组成部分。

---

本文档详细描述了传送系统的设计和实现。该系统为游戏提供了灵活、安全、可扩展的传送功能，是游戏高级功能的重要组成部分。
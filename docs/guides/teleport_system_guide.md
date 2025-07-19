# 传送系统使用指南

## 概述

新的传送系统提供了一个灵活、可配置的传送功能，支持多种传送模式和丰富的配置选项。

## 核心组件

### 1. TeleportManager (传送管理器)
- **位置**: `scripts/systems/teleport_manager.gd`
- **功能**: 处理所有传送逻辑，包括安全检查、动画效果、冷却管理
- **主要方法**:
  - `teleport_to_portal()`: 传送到Portal位置
  - `teleport_to_position()`: 传送到指定位置
  - `set_config()`: 设置传送配置
  - `can_teleport()`: 检查是否可以传送

### 2. TeleportConfig (传送配置)
- **位置**: `scripts/systems/teleport_config.gd`
- **功能**: 定义传送系统的所有配置参数
- **配置文件**: `resources/default_teleport_config.tres`

## 配置参数说明

### 基础设置
- `portal_offset`: Portal传送偏移量 (默认: Vector2(-20, 0))
- `safety_distance`: 安全检查距离 (默认: 32.0)
- `max_teleport_distance`: 最大传送距离 (默认: 500.0)

### 特效设置
- `enable_teleport_effects`: 启用传送特效 (默认: true)
- `teleport_duration`: 传送动画时长 (默认: 0.0 = 瞬间传送)
- `fade_out_duration`: 淡出时长 (默认: 0.2)
- `fade_in_duration`: 淡入时长 (默认: 0.2)

### 限制设置
- `cooldown_time`: 传送冷却时间 (默认: 1.0秒)
- `max_teleports_per_minute`: 每分钟最大传送次数 (默认: 10)

### 调试设置
- `log_teleport_events`: 记录传送事件 (默认: true)

## 预设配置

系统提供了4种预设配置：

1. **INSTANT** (瞬间传送)
   - 无动画，立即传送
   - 适合快节奏游戏

2. **SMOOTH** (平滑传送)
   - 带淡入淡出效果
   - 适合一般游戏体验

3. **CINEMATIC** (电影式传送)
   - 较长的动画时间
   - 适合剧情重要场景

4. **DEBUG** (调试模式)
   - 启用所有日志
   - 适合开发调试

## 使用示例

### 基本使用

```gdscript
# 创建传送管理器
var teleport_manager = TeleportManager.new()
add_child(teleport_manager)

# 加载配置
var config = load("res://resources/default_teleport_config.tres")
teleport_manager.set_config(config)

# 连接信号
teleport_manager.teleport_started.connect(_on_teleport_started)
teleport_manager.teleport_completed.connect(_on_teleport_completed)
teleport_manager.teleport_failed.connect(_on_teleport_failed)

# 执行传送
teleport_manager.teleport_to_portal()
```

### 自定义配置

```gdscript
# 创建自定义配置
var custom_config = TeleportConfig.new()
custom_config.portal_offset = Vector2(-30, 0)
custom_config.cooldown_time = 2.0
custom_config.enable_teleport_effects = false

# 应用配置
teleport_manager.set_config(custom_config)
```

### 使用预设

```gdscript
# 应用电影式传送预设
var config = TeleportConfig.new()
config.apply_preset(TeleportConfig.TeleportPreset.CINEMATIC)
teleport_manager.set_config(config)
```

## 信号事件

传送管理器提供以下信号：

- `teleport_started(player, destination)`: 传送开始
- `teleport_completed(player, destination)`: 传送完成
- `teleport_failed(reason)`: 传送失败
- `teleport_cooldown_finished()`: 冷却完成

## 最佳实践

1. **配置管理**: 使用资源文件管理配置，便于在编辑器中调整
2. **错误处理**: 始终连接 `teleport_failed` 信号，提供用户反馈
3. **性能优化**: 合理设置冷却时间，避免频繁传送
4. **用户体验**: 根据游戏类型选择合适的预设配置
5. **调试**: 开发时启用日志，发布时关闭以提高性能

## 扩展功能

### 添加音效

在 `_play_teleport_effect()` 函数中添加音效播放：

```gdscript
func _play_teleport_effect(from_position: Vector2, to_position: Vector2):
    # 播放传送音效
    AudioManager.play_sfx("teleport_sound")
    
    # 创建粒子效果
    var particles = preload("res://effects/TeleportParticles.tscn").instantiate()
    get_tree().current_scene.add_child(particles)
    particles.global_position = from_position
    particles.emitting = true
```

### 添加传送限制

可以在配置中添加更多限制条件：

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

## 故障排除

### 常见问题

1. **传送失败**: 检查Portal节点是否存在且在"portal"组中
2. **配置无效**: 确保配置文件路径正确且格式有效
3. **动画不工作**: 检查Tween节点是否正确创建
4. **冷却不生效**: 确保连接了 `teleport_cooldown_finished` 信号

### 调试技巧

1. 启用 `log_teleport_events` 查看详细日志
2. 使用DEBUG预设进行问题诊断
3. 检查信号连接是否正确
4. 验证节点路径和组设置
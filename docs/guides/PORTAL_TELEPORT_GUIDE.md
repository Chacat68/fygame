# 传送门传送功能使用指南

## 概述

传送门Portal现在支持两种传送模式：
1. **关卡传送模式** - 传送到指定关卡或下一关
2. **场景传送模式** - 传送到指定场景的特定位置

## 功能特性

- ✅ 支持关卡间传送
- ✅ 支持场景间传送
- ✅ 集成传送管理器的特效系统
- ✅ 支持传送位置配置
- ✅ 防止重复触发机制
- ✅ 完整的错误处理
- ✅ 调试信息输出

## 使用方法

### 1. 关卡传送模式

```gdscript
# 在脚本中配置传送门
func _ready():
    var portal = $Portal
    
    # 配置传送到指定关卡
    portal.configure_for_level_teleport(2)  # 传送到关卡2
    
    # 或者配置为自动进入下一关
    portal.configure_for_level_teleport(-1)  # -1表示下一关
```

### 2. 场景传送模式

```gdscript
# 在脚本中配置传送门
func _ready():
    var portal = $Portal
    
    # 配置传送到指定场景
    portal.configure_for_scene_teleport(
        "res://scenes/levels/lv2.tscn",
        Vector2(100, 200)  # 传送到的位置
    )
    
    # 如果不指定位置，玩家将出现在场景的原点
    portal.configure_for_scene_teleport("res://scenes/levels/boss_level.tscn")
```

### 3. 直接设置属性

```gdscript
# 直接设置传送门属性
var portal = $Portal

# 关卡传送
portal.next_level = 3
portal.destination_scene = ""

# 场景传送
portal.destination_scene = "res://scenes/levels/secret_area.tscn"
portal.teleport_position = Vector2(50, 100)
portal.next_level = -1
```

### 4. 控制传送门状态

```gdscript
var portal = $Portal

# 激活/禁用传送门
portal.set_active(true)   # 激活
portal.set_active(false)  # 禁用

# 获取传送门状态信息
var info = portal.get_portal_info()
print("传送门状态：", info)
```

## 在场景编辑器中使用

1. 将Portal场景实例化到你的关卡中
2. 选中Portal节点
3. 在脚本中添加配置代码
4. 或者通过代码动态配置

## 系统要求

传送门功能需要以下管理器支持：

- **TeleportManager** - 处理传送特效和场景切换
- **LevelManager** - 处理关卡切换逻辑
- **GameManager** - 协调各个管理器

### 管理器查找顺序

1. 首先在GameManager中查找子节点
2. 然后在场景树中查找对应的组

确保管理器节点被正确添加到对应的组：
```gdscript
# 在管理器的_ready()函数中
add_to_group("teleport_manager")
add_to_group("level_manager")
add_to_group("game_manager")
```

## 调试和故障排除

### 常见问题

1. **传送门无响应**
   - 检查`is_active`状态
   - 确认玩家在"player"组中
   - 检查碰撞形状是否正确

2. **找不到管理器**
   - 确认管理器节点存在
   - 检查节点是否在正确的组中
   - 查看控制台的警告信息

3. **场景切换失败**
   - 检查场景路径是否正确
   - 确认场景文件存在
   - 查看TeleportManager的错误信息

### 调试信息

传送门会输出详细的调试信息：
```
传送门配置为关卡传送模式，目标关卡：2
传送门配置为场景传送模式，目标场景：res://scenes/levels/lv2.tscn
[TeleportManager] 场景传送完成：res://scenes/levels/lv2.tscn 位置：(100, 200)
```

## 示例场景

```gdscript
# 完整的传送门配置示例
extends Node2D

func _ready():
    # 配置第一个传送门 - 关卡传送
    var portal1 = $Portal1
    portal1.configure_for_level_teleport(2)
    
    # 配置第二个传送门 - 场景传送
    var portal2 = $Portal2
    portal2.configure_for_scene_teleport(
        "res://scenes/levels/bonus_stage.tscn",
        Vector2(200, 300)
    )
    
    # 配置第三个传送门 - 下一关
    var portal3 = $Portal3
    portal3.configure_for_level_teleport(-1)  # 自动下一关
    
    # 监听传送事件
    portal1.body_entered.connect(_on_portal_used)
    portal2.body_entered.connect(_on_portal_used)
    portal3.body_entered.connect(_on_portal_used)

func _on_portal_used(body):
    if body.is_in_group("player"):
        print("玩家使用了传送门")
```

## 性能优化建议

1. 避免在同一帧内多次调用传送功能
2. 合理设置传送冷却时间
3. 在不需要时禁用传送门以节省性能
4. 使用对象池管理传送特效

## 扩展功能

传送门系统支持进一步扩展：

- 添加传送条件检查
- 实现传送门动画
- 支持双向传送
- 添加传送音效
- 实现传送门网络

通过继承Portal类或修改脚本可以实现这些高级功能。
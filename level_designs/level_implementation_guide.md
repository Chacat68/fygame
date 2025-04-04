# 关卡实现指南

本文档提供了在Godot引擎中实现新关卡的具体指南，包括TileMap设置、场景组织和游戏对象放置。

## TileMap设置

### 1. 地形图层设置

在game.tscn中，TileMap节点包含两个主要图层：
- **Background**：用于装饰性背景元素
- **Mid**：用于主要地形和碰撞元素

### 2. 地形块类型

根据world_tileset.png中的图块：

- **实心地形块**：用于主要平台和地面（0,0到8,2的图块）
- **单向平台**：允许玩家从下方跳跃穿过（9,0到11,2的图块）
- **装饰性图块**：用于背景和视觉丰富度

## 场景组织

新关卡应按照以下结构组织：

```
Game (Node2D)
|-- GameManager
|-- UI
|-- Player
|   |-- Camera2D
|-- Killzone
|-- TileMap
|   |-- Background
|   |-- Mid
|-- Coins
|   |-- Coin1, Coin2, ...
|-- Platforms
|   |-- Platform1, Platform2, ...
|-- Monster
|   |-- Slime1, Slime2, ...
```

## 具体实现步骤

### 1. 基础地形创建

1. 使用TileMap的Mid图层创建主要地形
   - 入口区域：创建平坦的地面和简单的平台
   - 中间区域：添加更多变化的地形和高度差
   - 挑战区域：创建复杂的地形结构
   - 宝藏区域：设计明显的终点区域

2. 使用Background图层添加装饰性元素
   - 根据区域主题添加适当的背景元素
   - 使用不同的图块创造深度感

### 2. 平台放置

1. **静态平台**：
   ```gdscript
   # 示例代码：放置静态平台
   var platform = preload("res://scenes/platform.tscn").instantiate()
   platform.position = Vector2(x, y)
   $Platforms.add_child(platform)
   ```

2. **移动平台**：
   ```gdscript
   # 示例代码：设置水平移动平台
   var platform = preload("res://scenes/platform.tscn").instantiate()
   platform.position = Vector2(x, y)
   $Platforms.add_child(platform)
   
   # 添加动画播放器
   var anim_player = AnimationPlayer.new()
   platform.add_child(anim_player)
   
   # 创建移动动画
   var animation = Animation.new()
   var track_index = animation.add_track(Animation.TYPE_VALUE)
   animation.track_set_path(track_index, ":position")
   animation.track_insert_key(track_index, 0.0, Vector2(x, y))
   animation.track_insert_key(track_index, 1.3, Vector2(x + 40, y)) # 移动距离
   animation.set_length(1.3)
   animation.set_loop_mode(Animation.LOOP_PINGPONG)
   
   # 将动画添加到播放器
   anim_player.add_animation("move", animation)
   anim_player.play("move")
   ```

### 3. 敌人放置

1. **绿色史莱姆**：
   ```gdscript
   # 示例代码：放置史莱姆敌人
   var slime = preload("res://scenes/slime.tscn").instantiate()
   slime.position = Vector2(x, y)
   $Monster.add_child(slime)
   ```

2. **紫色史莱姆**（如果支持）：
   ```gdscript
   # 需要创建紫色史莱姆变种
   var purple_slime = preload("res://scenes/slime.tscn").instantiate()
   purple_slime.position = Vector2(x, y)
   # 修改精灵图像为紫色版本
   purple_slime.get_node("AnimatedSprite2D").texture = preload("res://assets/sprites/slime_purple.png")
   # 可以增加移动速度或其他属性
   purple_slime.SPEED = 60 # 比普通史莱姆快
   $Monster.add_child(purple_slime)
   ```

### 4. 金币放置

```gdscript
# 示例代码：放置金币
var coin = preload("res://scenes/coin.tscn").instantiate()
coin.position = Vector2(x, y)
$Coins.add_child(coin)
```

### 5. 死亡区域设置

```gdscript
# 示例代码：设置底部死亡区域
var killzone = preload("res://scenes/killzone.tscn").instantiate()
# 添加碰撞形状
var collision_shape = CollisionShape2D.new()
var shape = WorldBoundaryShape2D.new()
collision_shape.shape = shape
killzone.add_child(collision_shape)
# 设置位置在关卡底部
killzone.position = Vector2(0, 120) # 根据关卡大小调整
```

## 关卡平衡调整

### 1. 难度调整

- **平台间距**：入口区域30-40像素，中间区域50-60像素，挑战区域70-80像素
- **敌人密度**：入口区域低，中间区域中，挑战区域高
- **移动平台速度**：入口区域慢(1.5-2秒/循环)，中间区域中(1-1.5秒/循环)，挑战区域快(0.8-1秒/循环)

### 2. 奖励分布

- 容易获取的金币：放置在主路径上
- 中等难度金币：需要简单跳跃才能获取
- 高难度金币：需要精确跳跃或冒险才能获取
- 隐藏金币：放置在隐藏区域或需要特殊技巧才能到达的地方

## 相机设置

```gdscript
# 示例代码：设置相机限制
$Player/Camera2D.limit_left = -200
$Player/Camera2D.limit_right = 1000 # 根据关卡宽度调整
$Player/Camera2D.limit_top = -300 # 根据关卡高度调整
$Player/Camera2D.limit_bottom = 120
```

## 测试与优化

1. **玩家路径测试**：确保玩家可以顺利通过所有区域
2. **难度曲线测试**：确保难度逐渐增加而不是突然变难
3. **金币收集测试**：确保所有金币都可以被收集
4. **性能优化**：确保关卡在目标平台上运行流畅

## 扩展建议

1. **检查点系统**：在关键位置添加检查点，让玩家死亡后从最近的检查点重生
2. **特殊能力道具**：添加临时能力提升，如双跳、速度提升等
3. **环境危害**：添加尖刺、熔岩等环境危害增加挑战性
4. **秘密区域**：创建需要特殊技巧才能到达的隐藏区域，包含额外奖励

## 结论

通过遵循这些指南，你可以在Godot中创建一个平衡、有趣且具有挑战性的平台游戏关卡。记得不断测试和调整，以确保最佳的游戏体验。
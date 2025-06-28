# 关卡设计完整指南

本文档整合了项目中所有关卡设计相关的文档，为开发者提供完整的关卡设计和实现指南。

## 目录

1. [关卡设计概述](#关卡设计概述)
2. [基础关卡：新关卡场景](#基础关卡新关卡场景)
3. [主题关卡：山洞探险](#主题关卡山洞探险)
4. [高级关卡：悬崖探险](#高级关卡悬崖探险)
5. [技术实现指南](#技术实现指南)
6. [视觉设计规范](#视觉设计规范)
7. [测试与优化](#测试与优化)

---

## 关卡设计概述

### 设计原则

1. **渐进式难度**：从简单的教学区域逐渐过渡到具有挑战性的区域
2. **清晰的视觉引导**：使用金币、平台布局和视觉元素引导玩家
3. **平衡的风险与奖励**：高难度区域提供更丰厚的奖励
4. **多样化的游戏元素**：结合静态平台、移动平台、敌人和收集品
5. **主题一致性**：每个关卡都有明确的主题和视觉风格

### 关卡类型

- **教学关卡**：介绍基本游戏机制
- **主题关卡**：具有特定主题和挑战的完整关卡
- **高级关卡**：测试玩家技巧的复杂关卡

---

## 基础关卡：新关卡场景

### 概述

`new_level.tscn` 是基于原始 `game.tscn` 场景创建的新关卡，包含了相似的游戏元素但具有不同的布局和特性。

### 场景结构

```
NewLevel (Node2D)
├── GameManager
├── UI
├── Player
├── LevelCamera
├── Killzone
├── TileMap
├── Coins (5个)
├── Platforms (3个，包含1个移动平台)
├── Enemies (2个史莱姆)
└── Labels
```

### 新特性

1. **改进的摄像机系统**
   - 使用 `LevelCamera` 替代 `GameCamera`
   - 更好的缩放比例 (3x)
   - 扩展的边界限制
   - 平滑的玩家跟随

2. **动态平台**
   - 包含一个移动平台 `MovingPlatform`
   - 使用 AnimationPlayer 实现水平移动动画
   - 2秒循环周期

3. **优化的布局**
   - 重新设计的金币分布
   - 对称的平台布局
   - 战略性的敌人位置

### 游戏元素位置

**金币 (5个)**
- Coin1: (-150, -80)
- Coin2: (-100, -80)
- Coin3: (100, -80)
- Coin4: (150, -80)
- Coin5: (0, -150) - 挑战位置

**平台 (3个)**
- Platform1: (-120, -50) - 静态
- Platform2: (120, -50) - 静态
- MovingPlatform: (-50, -120) 到 (50, -120) - 动态

**敌人 (2个)**
- Slime1: (-200, -20)
- Slime2: (200, -20)

---

## 主题关卡：山洞探险

### 关卡概述

山洞探险是一个具有挑战性的平台跳跃关卡，玩家需要通过跳跃在不同高度和类型的平台上，收集金币并击败史莱姆敌人来完成关卡。

### 关卡布局

```
                                    [宝藏区域]
                                    C C C C C
                                        P
                                    C     C
                                P           P
                                        S
                            ==================
                           /
      [挑战区域]         /
      C           C     /
          P   P       /
              S      /
          P     P   /
      C           C/
  P               P
          S S    /
      P P   P P /
  C           C/
================/
 /
/  [中间区域]
   C     C     C
       P     P
                     C C
                  P     P
          S             S
       P       P
   C                       C
===================================

[入口区域]
    C   C
        P       P
C               C
P                   P
           S
===========================
```

### 区域设计

#### 1. 入口区域（教学区）
- **目的**：让玩家熟悉基本移动和跳跃
- **元素**：5个金币，1个史莱姆，2-3个静态平台
- **特点**：平台间距较小，容易跳跃

#### 2. 中间区域（逐渐增加难度）
- **目的**：引入更多游戏机制
- **元素**：8个金币，2个史莱姆，混合静态和移动平台
- **特点**：平台间距增加，需要更精确的跳跃

#### 3. 挑战区域（高难度）
- **目的**：测试玩家的技巧和反应能力
- **元素**：7个金币，3个史莱姆，复杂的平台布局
- **特点**：包括移动平台和单向平台，多个敌人同时出现

#### 4. 宝藏区域（终点）
- **目的**：提供最终奖励和挑战
- **元素**：5个金币，1个增强版史莱姆
- **特点**：丰富的金币奖励，最后的Boss战

---

## 高级关卡：悬崖探险

### 关卡概念

「悬崖探险」是一个垂直攀爬为主的关卡，与「山洞探险」形成对比。玩家需要在悬崖峭壁上攀爬，利用各种平台向上前进。

### 整体布局

```
[顶部区域]
    C C C
  P       P
    S   S
===========
     |
     |
[攀爬区域]
  C   P   C
P           P
    S   P
  P       P
C           C
     P S
   P     P
C           C
=============
     |
     |
[起始区域]
  C     C
P         P
    P S P
  C       C
=============
```

### 区域详细设计

#### 1. 起始区域
- **地形特点**：较宽的底部平台，基础跳跃平台
- **元素放置**：4个金币，1个绿色史莱姆，3-4个静态平台
- **游戏流程**：基础攀爬训练，处理第一个敌人

#### 2. 攀爬区域
- **地形特点**：垂直分布的平台，移动平台，窄小的立足点
- **元素放置**：8个金币，2个史莱姆，混合静态和移动平台
- **游戏流程**：精确跳跃，利用移动平台，处理平台上的敌人

#### 3. 顶部区域
- **地形特点**：开阔的顶部平台，装饰性小平台
- **元素放置**：5个金币（皇冠形状），2个史莱姆（1绿1紫）
- **游戏流程**：最终挑战，收集奖励金币

### 游戏机制强调

1. **垂直移动技巧**
   - 连续跳跃时机掌握
   - 墙跳技巧（如果支持）
   - 精确落地控制

2. **平台类型变化**
   - 静态平台：基础立足点
   - 水平移动平台：时机掌握
   - 垂直移动平台：上升通道
   - 单向平台：特殊路径设计

---

## 技术实现指南

### TileMap设置

#### 地形图层设置
- **Background**：装饰性背景元素
- **Mid**：主要地形和碰撞元素

#### 地形块类型
- **实心地形块**：主要平台和地面（0,0到8,2的图块）
- **单向平台**：允许从下方跳跃穿过（9,0到11,2的图块）
- **装饰性图块**：背景和视觉丰富度

### 场景组织结构

```
Game (Node2D)
├── GameManager
├── UI
├── Player
│   └── Camera2D
├── Killzone
├── TileMap
│   ├── Background
│   └── Mid
├── Coins
│   └── Coin1, Coin2, ...
├── Platforms
│   └── Platform1, Platform2, ...
└── Monster
    └── Slime1, Slime2, ...
```

### 具体实现代码

#### 1. 静态平台放置

```gdscript
# 放置静态平台
var platform = preload("res://scenes/entities/platform.tscn").instantiate()
platform.position = Vector2(x, y)
$Platforms.add_child(platform)
```

#### 2. 移动平台设置

```gdscript
# 设置水平移动平台
var platform = preload("res://scenes/entities/platform.tscn").instantiate()
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

#### 3. 垂直移动平台

```gdscript
# 垂直移动平台示例
var platform = preload("res://scenes/entities/platform.tscn").instantiate()
platform.position = Vector2(x, y)
$Platforms.add_child(platform)

# 添加动画播放器
var anim_player = AnimationPlayer.new()
platform.add_child(anim_player)

# 创建垂直移动动画
var animation = Animation.new()
var track_index = animation.add_track(Animation.TYPE_VALUE)
animation.track_set_path(track_index, ":position")
animation.track_insert_key(track_index, 0.0, Vector2(x, y))
animation.track_insert_key(track_index, 1.3, Vector2(x, y - 40)) # 向上移动
animation.set_length(1.3)
animation.set_loop_mode(Animation.LOOP_PINGPONG)

# 将动画添加到播放器
anim_player.add_animation("move", animation)
anim_player.play("move")
```

#### 4. 敌人放置

```gdscript
# 绿色史莱姆
var slime = preload("res://scenes/entities/slime.tscn").instantiate()
slime.position = Vector2(x, y)
$Monster.add_child(slime)

# 紫色史莱姆（增强版）
var purple_slime = preload("res://scenes/entities/slime.tscn").instantiate()
purple_slime.position = Vector2(x, y)
# 修改精灵图像为紫色版本
purple_slime.get_node("AnimatedSprite2D").texture = preload("res://assets/sprites/slime_purple.png")
# 增加移动速度
purple_slime.SPEED = 60 # 比普通史莱姆快
$Monster.add_child(purple_slime)
```

#### 5. 金币放置

```gdscript
# 放置金币
var coin = preload("res://scenes/entities/coin.tscn").instantiate()
coin.position = Vector2(x, y)
$Coins.add_child(coin)
```

#### 6. 死亡区域设置

```gdscript
# 设置底部死亡区域
var killzone = preload("res://scenes/entities/killzone.tscn").instantiate()
# 添加碰撞形状
var collision_shape = CollisionShape2D.new()
var shape = WorldBoundaryShape2D.new()
collision_shape.shape = shape
killzone.add_child(collision_shape)
# 设置位置在关卡底部
killzone.position = Vector2(0, 120) # 根据关卡大小调整
```

### 相机设置

```gdscript
# 设置相机限制
$Player/Camera2D.limit_left = -200
$Player/Camera2D.limit_right = 1000 # 根据关卡宽度调整
$Player/Camera2D.limit_top = -300 # 根据关卡高度调整
$Player/Camera2D.limit_bottom = 120
```

---

## 视觉设计规范

### 主题风格

#### 山洞探险主题
- **入口区域**：明亮的洞口光线，可见洞外景色
- **中间区域**：逐渐变暗，钟乳石和石笋装饰
- **挑战区域**：黑暗环境，发光水晶或蘑菇照明
- **宝藏区域**：金色光芒，宝箱或宝石装饰

#### 悬崖探险主题
- **起始区域**：悬崖底部，植被和岩石
- **攀爬区域**：陡峭岩壁，突出的岩石和植物
- **顶部区域**：悬崖顶部，远处风景

### 视觉引导原则

1. **金币引导**：使用金币排列引导玩家沿设计路径前进
2. **平台布局**：平台排列暗示跳跃方向和路径
3. **颜色对比**：重要元素使用对比色突出显示
4. **背景深度**：使用背景元素创造深度感

### 特殊元素设计

#### 移动平台视觉表示

```
时间 t=0       时间 t=0.5     时间 t=1.0     时间 t=1.5
    P               P               P               P
    |               |               |               |
    |               |               |               |
    V               V               V               V
位置 x            位置 x+20        位置 x+40        位置 x+20
```

#### 敌人巡逻路径

```
绿色史莱姆：
    <------- 巡逻范围 ------->
    S →→→→→→→→→→→→→→→→→→→→→→→→→→
    ←←←←←←←←←←←←←←←←←←←←←←←←←←←

紫色史莱姆（更快）：
    <------- 巡逻范围 ------->
    S →→→→→→→→→→→→→→→→→→→→→→→→→→→→→→
    ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

---

## 关卡平衡调整

### 难度调整参数

#### 平台间距
- **入口区域**：30-40像素
- **中间区域**：50-60像素
- **挑战区域**：70-80像素

#### 敌人密度
- **入口区域**：低密度（1个敌人）
- **中间区域**：中密度（2个敌人）
- **挑战区域**：高密度（3-4个敌人）

#### 移动平台速度
- **入口区域**：慢速（1.5-2秒/循环）
- **中间区域**：中速（1-1.5秒/循环）
- **挑战区域**：快速（0.8-1秒/循环）

### 奖励分布策略

1. **容易获取的金币**：放置在主路径上
2. **中等难度金币**：需要简单跳跃才能获取
3. **高难度金币**：需要精确跳跃或冒险才能获取
4. **隐藏金币**：放置在隐藏区域或需要特殊技巧的地方

### 金币分布建议

- **入口区域**：5个（容易获取）
- **中间区域**：8个（中等难度）
- **挑战区域**：7个（高难度）
- **宝藏区域**：5个（奖励）
- **总计**：25个金币

---

## 测试与优化

### 测试要点

1. **玩家路径测试**
   - 确保玩家可以顺利通过所有区域
   - 验证跳跃距离的可行性
   - 检查是否存在卡住的可能性

2. **难度曲线测试**
   - 确保难度逐渐增加而不是突然变难
   - 验证每个区域的挑战性适中
   - 检查是否有过于困难的部分

3. **金币收集测试**
   - 确保所有金币都可以被收集
   - 验证隐藏金币的可发现性
   - 检查金币位置的合理性

4. **敌人互动测试**
   - 验证敌人的巡逻路径
   - 检查敌人与平台的互动
   - 确保敌人不会卡在地形中

5. **性能优化测试**
   - 确保关卡在目标平台上运行流畅
   - 检查移动平台的性能影响
   - 优化不必要的碰撞检测

### 调试工具

1. **关卡管理脚本功能**
   - `setup_level()` - 初始化关卡设置
   - `connect_signals()` - 连接游戏事件信号
   - `show_welcome_message()` - 显示欢迎信息
   - `_on_coin_collected()` - 处理金币收集
   - `_on_enemy_defeated()` - 处理敌人击败
   - `restart_level()` - 重启关卡
   - `get_level_progress()` - 获取进度信息

2. **状态跟踪变量**
   - `coins_collected` - 已收集金币数
   - `total_coins` - 总金币数
   - `enemies_defeated` - 已击败敌人数
   - `level_completed` - 关卡完成状态

---

## 扩展建议

### 基础扩展

1. **检查点系统**
   - 在关键位置添加检查点
   - 让玩家死亡后从最近的检查点重生
   - 保存关卡进度状态

2. **特殊能力道具**
   - 双跳能力
   - 速度提升
   - 临时无敌
   - 磁性收集（自动吸引金币）

3. **环境危害**
   - 尖刺陷阱
   - 熔岩区域
   - 毒气区域
   - 坍塌的平台

### 高级扩展

1. **动态关卡元素**
   - 可破坏的墙壁
   - 可激活的机关
   - 时间限制挑战
   - 天气效果

2. **多路径设计**
   - 主路径：安全但奖励较少
   - 挑战路径：危险但奖励丰厚
   - 隐藏路径：需要特殊技巧发现

3. **关卡评分系统**
   - 完成时间评分
   - 金币收集率评分
   - 死亡次数评分
   - 综合评级（S、A、B、C）

4. **关卡间连接**
   - 传送门系统
   - 世界地图
   - 关卡解锁机制
   - 剧情连接

---

## 结论

通过遵循这个完整的关卡设计指南，开发者可以创建出平衡、有趣且具有挑战性的平台游戏关卡。关键要点包括：

1. **渐进式难度设计**：确保玩家能够逐步适应游戏机制
2. **清晰的视觉引导**：帮助玩家理解游戏目标和路径
3. **平衡的挑战与奖励**：让玩家感到成就感
4. **技术实现的规范性**：确保代码的可维护性和扩展性
5. **充分的测试验证**：保证游戏体验的质量

记住，关卡设计是一个迭代的过程，需要不断测试、调整和优化，以达到最佳的游戏体验。
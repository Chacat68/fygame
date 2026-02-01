# 关卡设计完整指南

本文档整合了项目中所有关卡设计相关的文档，为开发者提供完整的关卡设计和实现指南。

## 目录

1. [关卡设计概述](#关卡设计概述)
2. [关卡1](#关卡1)
3. [技术实现指南](#技术实现指南)
4. [视觉设计规范](#视觉设计规范)
5. [测试与优化](#测试与优化)

---

## 关卡设计概述

### 设计原则

1. **渐进式难度**：从简单的教学区域逐渐过渡到具有挑战性的区域
2. **清晰的视觉引导**：使用金币、平台布局和视觉元素引导玩家
3. **平衡的风险与奖励**：高难度区域提供更丰厚的奖励
4. **多样化的游戏元素**：结合静态平台、移动平台、敌人和收集品
5. **主题一致性**：每个关卡都有明确的主题和视觉风格

### 实体放置规则

以下规则确保关卡的一致性和可玩性：

1. **传送门 (Portal)**
   - ⚠️ **必须放置在地面平台上**
   - 传送门底部应与地面对齐
   - 确保玩家可以正常进入传送门触发传送
   - 建议Y坐标与地面其他实体（如敌人）保持一致

2. **玩家出生点 (Player)**
   - 必须在安全区域，远离即时伤害机关
   - 建议在关卡起始区域的平台上

3. **金币 (Coin)**
   - 可放置在空中引导玩家路线
   - 高风险位置的金币作为奖励

4. **敌人 (Enemy)**
   - 必须放置在可行走的平台上
   - 给玩家足够的反应时间

5. **机关 (Hazards)**
   - 尖刺：放置在地面或平台边缘
   - 锯片：可悬空巡逻
   - 弹簧板：放置在地面上
   - 压力开关：放置在地面上

### 关卡类型

- **教学关卡**：介绍基本游戏机制
- **主题关卡**：具有特定主题和挑战的完整关卡
- **高级关卡**：测试玩家技巧的复杂关卡

---

## 关卡1

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

## 技术实现指南

### 关卡管理系统

项目采用统一的关卡管理系统，包含以下核心组件：

1. **LevelConfig资源**
   - 统一管理所有关卡配置信息
   - 包含关卡ID、名称、场景路径、难度等
   - 支持关卡解锁条件和目标设置

2. **LevelManager管理器**
   - 负责关卡的加载、切换和状态管理
   - 提供关卡完成、失败、重新开始等功能
   - 管理关卡进度和分数系统

3. **关卡命名规范**
   - 场景文件：`lv{数字}.tscn`（如：`lv1.tscn`, `lv2.tscn`, `lv3.tscn`）
   - 脚本文件：`level{数字}.gd`（如：`level2.gd`, `level3.gd`）
   - 统一的数字编号便于管理和扩展

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

### 关卡配置管理

**使用LevelManager加载关卡：**
```gdscript
# 在主游戏场景中
func _ready():
    # 获取关卡管理器
    var level_manager = get_node("/root/LevelManager")
    
    # 连接信号
    level_manager.level_completed.connect(_on_level_completed)
    level_manager.level_failed.connect(_on_level_failed)
    
    # 加载第一关
    level_manager.load_level(1)

func _on_level_completed(level_id: int, score: int):
    print("关卡完成！分数：", score)
    # 加载下一关
    level_manager.load_next_level()

func _on_level_failed(level_id: int):
    print("关卡失败！")
    # 重新开始关卡
    level_manager.restart_level()
```

**关卡脚本模板：**
```gdscript
# level1.gd
extends Node2D

@onready var level_manager = get_node("/root/LevelManager")
@onready var player = $Player

func _ready():
    setup_level()
    connect_signals()

func setup_level():
    setup_platforms()
    setup_collectibles()
    setup_enemies()

func connect_signals():
    # 连接玩家信号
    if player:
        player.died.connect(_on_player_died)
        player.reached_goal.connect(_on_player_reached_goal)
    
    # 连接金币收集信号
    for coin in $Collectibles.get_children():
        coin.collected.connect(_on_coin_collected)

func _on_player_died():
    level_manager.fail_level()

func _on_player_reached_goal():
    var score = level_manager.get_current_score()
    level_manager.complete_level(score)

func _on_coin_collected(points: int):
    level_manager.add_score(points)
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

#### 基础关卡主题
- **入口区域**：明亮清晰的环境，便于玩家理解游戏机制
- **中间区域**：逐渐增加视觉复杂度，引入更多元素
- **挑战区域**：视觉上突出危险和挑战性

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

- **教学区域**：3-5个（容易获取）
- **进阶区域**：5-8个（中等难度）
- **挑战区域**：5-7个（高难度）
- **总计**：根据关卡规模调整

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

### 模块化设计

1. **关卡组件系统**
   - 创建可重用的关卡组件（平台、机关、敌人）
   - 使用组合模式构建复杂关卡
   - 支持组件的参数化配置

2. **主题系统**
   - 分离视觉主题和关卡逻辑
   - 支持主题的热切换
   - 统一的资源管理

### 数据驱动开发

1. **配置文件驱动**
   - 使用JSON/YAML配置关卡数据
   - 支持外部工具编辑
   - 版本控制友好的格式

2. **关卡编辑器**
   - 开发可视化关卡编辑工具
   - 支持拖拽放置游戏元素
   - 实时预览和测试功能
   - 导出标准化关卡数据

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

1. **动态难度调整**
   - 根据玩家表现调整难度
   - 自适应敌人数量和速度
   - 智能提示系统

2. **关卡生成系统**
   - 程序化生成关卡布局
   - 基于规则的随机生成
   - 保证可玩性的验证算法

3. **性能优化**
   - 关卡流式加载
   - 对象池管理
   - LOD系统实现

4. **动态关卡元素**
   - 可破坏的墙壁
   - 可激活的机关
   - 时间限制挑战
   - 天气效果

5. **多路径设计**
   - 主路径：安全但奖励较少
   - 挑战路径：危险但奖励丰厚
   - 隐藏路径：需要特殊技巧发现

6. **关卡评分系统**
   - 完成时间评分
   - 金币收集率评分
   - 死亡次数评分
   - 综合评级（S、A、B、C）

7. **关卡间连接**
   - 传送门系统
   - 世界地图
   - 关卡解锁机制
   - 剧情连接

8. **多样化机制**
   - 添加新的平台类型
   - 引入环境交互元素
   - 实现特殊能力系统
   - 支持多人合作模式

---

## 结论

通过遵循这个完整的关卡设计指南，开发者可以创建出平衡、有趣且具有挑战性的平台游戏关卡。关键要点包括：

1. **渐进式难度设计**：确保玩家能够逐步适应游戏机制
2. **清晰的视觉引导**：帮助玩家理解游戏目标和路径
3. **平衡的挑战与奖励**：让玩家感到成就感
4. **技术实现的规范性**：确保代码的可维护性和扩展性
5. **充分的测试验证**：保证游戏体验的质量

记住，关卡设计是一个迭代的过程，需要不断测试、调整和优化，以达到最佳的游戏体验。

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队
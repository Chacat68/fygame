# 玩家状态机系统设计

## 概述

本文档详细描述了游戏中玩家角色的状态机系统，包括各状态的行为、转换条件以及实现细节。状态机模式使玩家的行为逻辑更加清晰和可维护。

## 状态机架构

### 基础状态类

所有玩家状态都继承自`PlayerState`基类，该基类定义了状态机的基础接口。实际实现位于`/scripts/entities/player/player_states/player_state.gd`：

```gdscript
class_name PlayerState
extends Node

# 状态拥有者引用
var player: CharacterBody2D

# 构造函数
func _init(player_ref: CharacterBody2D):
    self.player = player_ref

# 进入状态时调用
func enter():
    pass

# 退出状态时调用
func exit():
    pass

# 处理物理更新
func physics_process(_delta: float):
    pass

# 处理输入
func handle_input():
    pass

# 更新动画
func update_animation():
    pass
```

### 状态机管理

玩家主脚本（`player.gd`）中实现了状态机的核心管理逻辑：

```gdscript
# 状态管理
var current_state: PlayerState
var states = {}

# 初始化状态机
func _init_states():
    # 创建各种状态
    states = {
        "Idle": IdleState.new(self),
        "Run": RunState.new(self),
        "Jump": JumpState.new(self),
        "Fall": FallState.new(self),
        "Hurt": HurtState.new(self),
        "Death": DeathState.new(self)
    }
    
    # 设置初始状态
    _change_state("Idle")

# 切换状态
func _change_state(new_state_name: String):
    if current_state:
        current_state.exit()
    
    current_state = states[new_state_name]
    current_state.enter()
```

### 状态初始化

在玩家脚本中，状态机通过以下方式初始化：

```gdscript
# 初始化状态机
func _init_states():
    # 创建各种状态
    states = {
        "Idle": IdleState.new(self),
        "Run": RunState.new(self),
        "Jump": JumpState.new(self),
        "Fall": FallState.new(self),
        "Hurt": HurtState.new(self),
        "Death": DeathState.new(self)
    }
    
    # 设置初始状态
    _change_state("Idle")
```

## 状态详解

### 1. 闲置状态 (Idle)

**描述**：玩家静止不动的状态。

**进入条件**：
- 游戏开始时的初始状态
- 从奔跑状态停止移动
- 从跳跃或下落状态落地且没有水平移动

**行为**：
- 播放闲置动画
- 检测输入以转换到其他状态
- 保持玩家静止

**退出转换**：
- 按下左右方向键 → 转换到奔跑状态
- 按下跳跃键 → 转换到跳跃状态
- 走出平台 → 转换到下落状态
- 受到伤害 → 转换到受伤状态
- 生命值为0 → 转换到死亡状态

### 2. 奔跑状态 (Run)

**描述**：玩家水平移动的状态。

**进入条件**：
- 在闲置状态按下左右方向键
- 从跳跃或下落状态落地且有水平移动输入

**行为**：
- 播放奔跑动画
- 根据输入方向移动玩家
- 根据移动方向翻转精灵

**退出转换**：
- 松开方向键 → 转换到闲置状态
- 按下跳跃键 → 转换到跳跃状态
- 走出平台 → 转换到下落状态
- 受到伤害 → 转换到受伤状态
- 生命值为0 → 转换到死亡状态

### 3. 跳跃状态 (Jump)

**描述**：玩家跳跃上升的状态。

**进入条件**：
- 在闲置或奔跑状态按下跳跃键
- 在下落状态中按下跳跃键（二段跳）

**行为**：
- 播放跳跃动画
- 应用向上的初始速度
- 增加已跳跃次数计数
- 播放跳跃音效

**退出转换**：
- 垂直速度变为正值 → 转换到下落状态
- 受到伤害 → 转换到受伤状态
- 生命值为0 → 转换到死亡状态

### 4. 下落状态 (Fall)

**描述**：玩家下落的状态。

**进入条件**：
- 从跳跃状态开始下落
- 走出平台边缘

**行为**：
- 播放下落动画
- 应用重力
- 允许水平移动控制

**退出转换**：
- 接触地面 → 根据水平输入转换到闲置或奔跑状态
- 按下跳跃键且未达到最大跳跃次数 → 转换到跳跃状态（二段跳）
- 受到伤害 → 转换到受伤状态
- 生命值为0或掉落超过死亡高度 → 转换到死亡状态

### 5. 受伤状态 (Hurt)

**描述**：玩家受到伤害的状态。

**进入条件**：
- 与敌人碰撞
- 接触伤害区域

**行为**：
- 播放受伤动画
- 减少生命值
- 应用短暂的击退效果
- 播放受伤音效
- 触发无敌时间
- 发送生命值变化信号

**退出转换**：
- 受伤动画结束且生命值大于0 → 转换到闲置状态
- 生命值为0 → 转换到死亡状态

### 6. 死亡状态 (Death)

**描述**：玩家死亡的状态。

**进入条件**：
- 生命值降至0
- 掉落超过死亡高度

**行为**：
- 播放死亡动画
- 禁用玩家输入
- 设置玩家复活标志
- 延迟后重新加载当前场景

**退出转换**：
- 无（死亡后重新加载场景）

## 状态转换逻辑

状态转换通过`_change_state`方法实现：

```gdscript
# 切换状态
func _change_state(new_state_name: String):
    if current_state:
        current_state.exit()
    
    current_state = states[new_state_name]
    current_state.enter()
```

每个状态的`physics_process`方法返回新状态的名称（如果需要转换）或`null`（如果保持当前状态）：

```gdscript
# 物理处理
func _physics_process(delta):
    # 使用当前状态处理物理更新
    var new_state_name = current_state.physics_process(delta)
    if new_state_name:
        _change_state(new_state_name)
```

## 实现注意事项

1. **状态独立性**：每个状态应该是自包含的，只负责自己的行为逻辑。

2. **状态转换条件**：转换条件应该明确，避免状态之间的循环转换。

3. **动画同步**：状态变化应该与动画同步，确保视觉反馈与游戏逻辑一致。

4. **输入处理**：每个状态应该只处理与该状态相关的输入。

5. **扩展性**：状态机设计应该允许轻松添加新状态，如滑行、攀爬等。

## 状态机扩展

未来可以考虑添加以下状态：

- **滑行状态**：允许玩家在地面上滑行，可以通过小缝隙。
- **攀爬状态**：允许玩家攀爬特定的墙壁或梯子。
- **冲刺状态**：允许玩家短时间内快速移动。
- **蹲伏状态**：允许玩家蹲下，减小碰撞体积。

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本文档详细描述了玩家状态机系统的设计和实现。开发人员应参考此文档进行玩家控制系统的实现和扩展。
# 技能系统扩展指南

本指南将帮助你为游戏添加新的技能，扩展现有的技能系统。

## 目录

1. [准备工作](#准备工作)
2. [创建技能状态类](#创建技能状态类)
3. [更新技能管理器](#更新技能管理器)
4. [更新玩家状态机](#更新玩家状态机)
5. [更新技能升级UI](#更新技能升级UI)
6. [添加输入映射](#添加输入映射)
7. [添加动画和音效](#添加动画和音效)
8. [测试新技能](#测试新技能)
9. [示例：双跳技能](#示例双跳技能)

## 准备工作

在开始扩展技能系统之前，请确保你已经了解以下内容：

1. 技能系统的基本结构和工作原理
2. 玩家状态机的工作方式
3. 技能管理器的API和数据结构
4. 技能升级UI的结构和工作方式

## 创建技能状态类

每个技能都需要一个对应的状态类，继承自`PlayerState`。

1. 在`scripts/entities/player/player_states`目录下创建新的技能状态类文件，例如`double_jump_state.gd`

2. 实现技能状态类的基本结构：

```gdscript
class_name DoubleJumpState
extends PlayerState

func enter() -> void:
    # 进入状态时的处理
    player.velocity.y = -player.skill_manager.get_double_jump_force()
    player.skill_manager.use_skill("double_jump")
    # 播放动画
    player.animation_player.play("double_jump")
    # 播放音效
    player.sound_player.play("double_jump")

func exit() -> void:
    # 退出状态时的处理
    pass

func physics_process(delta: float) -> String:
    # 物理处理
    player.apply_gravity(delta)
    player.move_and_slide()
    
    # 状态转换
    if player.is_on_floor():
        return "Idle"
    elif player.velocity.y > 0:
        return "Fall"
    
    return ""

func input_process(event: InputEvent) -> String:
    # 输入处理
    if event.is_action_pressed("dash") and player.can_use_skill("dash"):
        return "Dash"
    
    return ""
```

## 更新技能管理器

在`SkillManager`中添加新技能的配置和参数。

1. 在`skill_manager.gd`文件中添加新技能的初始化数据：

```gdscript
func _init() -> void:
    # 现有技能初始化...
    
    # 添加新技能
    _skill_data["double_jump"] = {
        "name": "双跳",
        "description": "在空中再次跳跃",
        "max_level": 3,
        "level": 0,
        "unlocked": false,
        "unlock_cost": 150,
        "upgrade_cost": 100,
        "cooldown": 1.0,
        "cooldown_remaining": 0.0
    }
```

2. 添加新技能的参数获取方法：

```gdscript
func get_double_jump_force() -> float:
    var level = get_skill_level("double_jump")
    return 300.0 + (level - 1) * 50.0

func get_double_jump_cooldown() -> float:
    var level = get_skill_level("double_jump")
    return 1.0 - (level - 1) * 0.2
```

## 更新玩家状态机

在玩家状态机中注册新技能状态。

1. 在玩家状态机初始化中添加新状态：

```gdscript
func _init_states() -> void:
    # 现有状态初始化...
    
    # 添加新技能状态
    _states["DoubleJump"] = DoubleJumpState.new(self)
```

2. 在相关状态中添加技能输入检测：

```gdscript
# 在JumpState和FallState中添加
func input_process(event: InputEvent) -> String:
    # 现有输入处理...
    
    # 添加双跳输入检测
    if event.is_action_pressed("jump") and player.can_use_skill("double_jump"):
        return "DoubleJump"
    
    return ""
```

## 更新技能升级UI

在技能升级UI中添加新技能的面板。

1. 在`skill_upgrade_ui.tscn`中添加新技能面板，可以复制现有技能面板并修改。

2. 在`skill_upgrade_ui.gd`中添加新技能面板的引用和初始化：

```gdscript
# 添加面板引用
@onready var double_jump_panel = $SkillsContainer/DoubleJumpPanel
@onready var double_jump_unlock_button = $SkillsContainer/DoubleJumpPanel/UnlockButton
@onready var double_jump_upgrade_button = $SkillsContainer/DoubleJumpPanel/UpgradeButton
@onready var double_jump_level_label = $SkillsContainer/DoubleJumpPanel/LevelLabel
@onready var double_jump_description_label = $SkillsContainer/DoubleJumpPanel/DescriptionLabel
@onready var double_jump_cost_label = $SkillsContainer/DoubleJumpPanel/CostLabel

func _ready() -> void:
    # 现有初始化...
    
    # 连接新技能按钮信号
    double_jump_unlock_button.pressed.connect(_on_double_jump_unlock_button_pressed)
    double_jump_upgrade_button.pressed.connect(_on_double_jump_upgrade_button_pressed)
```

3. 添加新技能的按钮回调方法：

```gdscript
func _on_double_jump_unlock_button_pressed() -> void:
    if _skill_manager.unlock_skill("double_jump"):
        update_ui()

func _on_double_jump_upgrade_button_pressed() -> void:
    if _skill_manager.upgrade_skill("double_jump"):
        update_ui()
```

4. 更新UI更新方法：

```gdscript
func update_ui() -> void:
    # 现有UI更新...
    
    # 更新双跳技能UI
    var double_jump_data = _skill_manager.get_skill_data("double_jump")
    double_jump_level_label.text = "等级: %d/%d" % [double_jump_data.level, double_jump_data.max_level]
    double_jump_description_label.text = double_jump_data.description
    
    if double_jump_data.unlocked:
        double_jump_unlock_button.visible = false
        double_jump_upgrade_button.visible = true
        
        if double_jump_data.level < double_jump_data.max_level:
            double_jump_cost_label.text = "升级费用: %d" % double_jump_data.upgrade_cost
            double_jump_upgrade_button.disabled = _skill_manager.get_coins() < double_jump_data.upgrade_cost
        else:
            double_jump_cost_label.text = "已达最高等级"
            double_jump_upgrade_button.disabled = true
    else:
        double_jump_unlock_button.visible = true
        double_jump_upgrade_button.visible = false
        double_jump_cost_label.text = "解锁费用: %d" % double_jump_data.unlock_cost
        double_jump_unlock_button.disabled = _skill_manager.get_coins() < double_jump_data.unlock_cost
```

## 添加输入映射

如果新技能需要新的输入映射，需要在项目设置中添加。

1. 打开项目设置（Project > Project Settings）
2. 选择Input Map选项卡
3. 添加新的输入映射，例如"double_jump"
4. 为新的输入映射添加按键或按钮

## 添加动画和音效

为新技能添加动画和音效。

1. 在玩家的动画播放器中添加新技能的动画
2. 在技能状态类的`enter`方法中播放动画和音效

```gdscript
func enter() -> void:
    # 播放动画
    player.animation_player.play("double_jump")
    # 播放音效
    player.sound_player.play("double_jump")
```

## 测试新技能

使用测试场景测试新技能。

1. 打开测试场景：`scenes/test/skill_test_scene.tscn`
2. 运行场景，使用调试面板查看技能状态
3. 测试新技能的解锁、升级和使用
4. 调整技能参数以获得最佳游戏体验

## 示例：双跳技能

以下是一个完整的双跳技能实现示例。

### 1. 双跳状态类（double_jump_state.gd）

```gdscript
class_name DoubleJumpState
extends PlayerState

func enter() -> void:
    # 设置垂直速度为双跳力度
    player.velocity.y = -player.skill_manager.get_double_jump_force()
    # 使用技能，开始冷却
    player.skill_manager.use_skill("double_jump")
    # 播放动画
    player.animation_player.play("double_jump")
    # 播放音效
    player.sound_effects.play("double_jump")

func exit() -> void:
    # 退出状态时的处理
    pass

func physics_process(delta: float) -> String:
    # 应用重力
    player.apply_gravity(delta)
    
    # 允许水平移动控制
    var input_dir = Input.get_axis("move_left", "move_right")
    player.velocity.x = input_dir * player.speed
    
    # 移动玩家
    player.move_and_slide()
    
    # 状态转换
    if player.is_on_floor():
        return "Idle"
    elif player.velocity.y > 0:
        return "Fall"
    elif Input.is_action_just_pressed("dash") and player.can_use_skill("dash"):
        return "Dash"
    
    return ""
```

### 2. 技能管理器更新（skill_manager.gd）

```gdscript
func _init() -> void:
    # 现有技能初始化...
    
    # 添加双跳技能
    _skill_data["double_jump"] = {
        "name": "双跳",
        "description": "在空中再次跳跃，可以到达更高的地方",
        "max_level": 3,
        "level": 0,
        "unlocked": false,
        "unlock_cost": 150,
        "upgrade_cost": 100,
        "cooldown": 1.0,
        "cooldown_remaining": 0.0
    }

# 双跳参数获取方法
func get_double_jump_force() -> float:
    var level = get_skill_level("double_jump")
    return 300.0 + (level - 1) * 50.0

func get_double_jump_cooldown() -> float:
    var level = get_skill_level("double_jump")
    return 1.0 - (level - 1) * 0.2
```

### 3. 玩家状态机更新

```gdscript
func _init_states() -> void:
    # 现有状态初始化...
    _states["DoubleJump"] = DoubleJumpState.new(self)

# 在JumpState和FallState中添加
func input_process(event: InputEvent) -> String:
    if event.is_action_pressed("jump") and player.can_use_skill("double_jump"):
        return "DoubleJump"
    
    return ""
```

### 4. 技能升级UI更新

在`skill_upgrade_ui.tscn`中添加双跳技能面板，并在`skill_upgrade_ui.gd`中添加相应的代码。

### 5. 测试

在测试场景中测试双跳技能，确保它能正常工作并提供良好的游戏体验。

## 总结

通过本指南，你应该能够为游戏添加新的技能，扩展现有的技能系统。记住以下关键点：

1. 每个技能都需要一个状态类
2. 在技能管理器中添加技能数据和参数
3. 在玩家状态机中注册技能状态
4. 在技能升级UI中添加技能面板
5. 添加必要的输入映射、动画和音效
6. 充分测试新技能

通过这种模块化的方法，你可以轻松地为游戏添加各种技能，丰富游戏玩法。
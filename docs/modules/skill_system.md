# 技能系统设计文档

## 概述

技能系统为游戏增加了更丰富的玩法机制，包括冲刺、墙跳、滑铲等技能，以及基于金币的技能升级树。系统采用模块化设计，易于扩展和维护。

## 实现状态

技能系统已完成实现，包括以下功能：

- ✅ 技能管理器（SkillManager）
- ✅ 技能状态（DashState, WallSlideState, WallJumpState, SlideState）
- ✅ 技能升级UI
- ✅ 技能解锁和升级系统
- ✅ 技能冷却管理
- ✅ 玩家状态机集成
- ✅ 测试场景

## 系统架构

### 核心组件

#### SkillManager
位于`/scripts/systems/skill_manager.gd`，作为技能系统的核心管理器：

```gdscript
class_name SkillManager
extends Node

# 技能相关信号
signal skill_unlocked(skill_name: String)
signal skill_upgraded(skill_name: String, level: int)
signal skill_used(skill_name: String)
signal skill_cooldown_finished(skill_name: String)
```

#### SkillConfig
位于`/scripts/systems/skill_config.gd`，定义技能系统的配置参数：

- 技能解锁条件
- 技能冷却时间
- 技能升级成本
- 技能效果参数

### 技能数据结构

```gdscript
# 技能数据类
class_name SkillData
extends Resource

@export var skill_id: String
@export var skill_name: String
@export var description: String
@export var icon: Texture2D
@export var max_level: int = 3
@export var unlock_cost: int = 0
@export var upgrade_costs: Array[int] = []
@export var cooldown_time: float = 0.0
@export var is_unlocked: bool = false
@export var current_level: int = 0
```

## 技能详细设计

### 1. 冲刺技能 (Dash)

#### 功能描述
- 玩家可以进行短距离快速冲刺
- 冲刺期间无敌或减少受到的伤害
- 可以穿过某些敌人或障碍物

#### 技能参数
```gdscript
# 冲刺技能配置
@export_group("冲刺技能")
@export var dash_distance: float = 120.0        # 冲刺距离
@export var dash_speed: float = 600.0           # 冲刺速度
@export var dash_duration: float = 0.2          # 冲刺持续时间
@export var dash_cooldown: float = 2.0          # 冲刺冷却时间
@export var dash_invincible: bool = true        # 冲刺时是否无敌
@export var dash_can_pass_enemies: bool = true  # 是否可以穿过敌人
```

#### 升级效果
- **等级1**: 基础冲刺能力
- **等级2**: 减少冷却时间20%，增加冲刺距离
- **等级3**: 冲刺结束时造成小范围伤害

#### 实现要点
```gdscript
# 冲刺状态类
class_name DashState
extends PlayerState

var dash_timer: float = 0.0
var dash_direction: Vector2

func enter():
    # 设置冲刺方向和参数
    dash_direction = Vector2(Input.get_axis("move_left", "move_right"), 0)
    if dash_direction.x == 0:
        dash_direction.x = 1 if not player.animated_sprite.flip_h else -1
    
    # 设置冲刺速度
    player.velocity = dash_direction * player.skill_manager.get_dash_speed()
    
    # 设置无敌状态
    if player.skill_manager.is_dash_invincible():
        player.set_temporary_invincible(player.skill_manager.get_dash_duration())
```

### 2. 墙跳技能 (Wall Jump)

#### 功能描述
- 玩家可以在墙壁上进行跳跃
- 支持连续墙跳
- 扩展关卡设计的垂直空间利用

#### 技能参数
```gdscript
# 墙跳技能配置
@export_group("墙跳技能")
@export var wall_jump_force: float = 300.0       # 墙跳力度
@export var wall_slide_speed: float = 100.0     # 贴墙滑行速度
@export var wall_jump_horizontal: float = 200.0 # 墙跳水平推力
@export var wall_cling_time: float = 0.3        # 贴墙时间
@export var max_wall_jumps: int = 3             # 最大连续墙跳次数
```

#### 升级效果
- **等级1**: 基础墙跳能力
- **等级2**: 增加墙跳次数，减少贴墙滑行速度
- **等级3**: 墙跳时恢复空中跳跃次数

#### 实现要点
```gdscript
# 墙跳状态类
class_name WallSlideState
extends PlayerState

var wall_normal: Vector2
var wall_cling_timer: float = 0.0

func physics_process(delta):
    # 检测墙壁
    var wall_ray = player.get_wall_ray()
    if wall_ray.is_colliding():
        wall_normal = wall_ray.get_collision_normal()
        
        # 贴墙滑行
        if player.velocity.y > 0:
            player.velocity.y = min(player.velocity.y, player.skill_manager.get_wall_slide_speed())
        
        # 检测墙跳输入
        if Input.is_action_just_pressed("jump"):
            return "WallJump"
```

### 3. 滑铲技能 (Slide)

#### 功能描述
- 玩家可以滑过低矮障碍物
- 滑铲时可以攻击敌人
- 改变玩家碰撞体积

#### 技能参数
```gdscript
# 滑铲技能配置
@export_group("滑铲技能")
@export var slide_speed: float = 250.0          # 滑铲速度
@export var slide_duration: float = 0.8         # 滑铲持续时间
@export var slide_damage: int = 15              # 滑铲伤害
@export var slide_cooldown: float = 3.0         # 滑铲冷却时间
@export var slide_friction: float = 0.9         # 滑铲摩擦力
```

#### 升级效果
- **等级1**: 基础滑铲能力
- **等级2**: 增加滑铲伤害，减少冷却时间
- **等级3**: 滑铲结束时可以直接跳跃

#### 实现要点
```gdscript
# 滑铲状态类
class_name SlideState
extends PlayerState

var slide_timer: float = 0.0
var original_collision_shape: Shape2D

func enter():
    # 改变碰撞体积
    var collision = player.get_node("CollisionShape2D")
    original_collision_shape = collision.shape
    
    # 创建滑铲碰撞形状（更矮更宽）
    var slide_shape = RectangleShape2D.new()
    slide_shape.size = Vector2(original_collision_shape.size.x * 1.2, original_collision_shape.size.y * 0.5)
    collision.shape = slide_shape
```

## 技能升级树系统

### 升级树结构

```gdscript
# 技能树数据
class_name SkillTree
extends Resource

@export var skills: Dictionary = {}
@export var skill_dependencies: Dictionary = {}

# 技能解锁条件
enum UnlockCondition {
    COINS,          # 金币数量
    LEVEL,          # 关卡进度
    SKILL,          # 前置技能
    ACHIEVEMENT     # 成就解锁
}
```

### 技能商店界面

#### UI组件
- **技能图标**: 显示技能状态（未解锁/已解锁/已升级）
- **技能描述**: 详细说明技能效果
- **升级成本**: 显示所需金币数量
- **升级按钮**: 执行技能升级

#### 界面布局
```
技能树界面
├── 移动技能分支
│   ├── 冲刺技能 (100金币)
│   ├── 墙跳技能 (150金币)
│   └── 滑铲技能 (200金币)
├── 战斗技能分支
│   ├── 连击技能 (120金币)
│   ├── 反击技能 (180金币)
│   └── 终结技能 (300金币)
└── 被动技能分支
    ├── 生命提升 (80金币)
    ├── 速度提升 (100金币)
    └── 跳跃提升 (120金币)
```

### 技能持久化

```gdscript
# 技能进度保存
func save_skill_progress():
    var skill_data = {
        "unlocked_skills": [],
        "skill_levels": {},
        "total_coins_spent": 0
    }
    
    for skill_id in skills.keys():
        var skill = skills[skill_id]
        if skill.is_unlocked:
            skill_data.unlocked_skills.append(skill_id)
            skill_data.skill_levels[skill_id] = skill.current_level
    
    # 保存到游戏进度文件
    GameState.save_skill_data(skill_data)
```

## 配置系统集成

### GameConfig扩展

在现有的GameConfig中添加技能相关配置：

```gdscript
# 在GameConfig类中添加技能配置
@export_group("技能系统")
# 冲刺技能
@export var dash_distance: float = 120.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0
@export var dash_unlock_cost: int = 100

# 墙跳技能
@export var wall_jump_force: float = 300.0
@export var wall_slide_speed: float = 100.0
@export var wall_jump_horizontal: float = 200.0
@export var wall_jump_unlock_cost: int = 150

# 滑铲技能
@export var slide_speed: float = 250.0
@export var slide_duration: float = 0.8
@export var slide_damage: int = 15
@export var slide_cooldown: float = 3.0
@export var slide_unlock_cost: int = 200

# 技能升级成本倍数
@export var skill_upgrade_cost_multiplier: float = 1.5
```

## 输入系统扩展

### 新增输入映射

在项目设置中添加新的输入动作：
- `dash`: 冲刺技能（默认：Shift键）
- `slide`: 滑铲技能（默认：Ctrl键）
- `skill_menu`: 技能菜单（默认：Tab键）

### 输入处理

```gdscript
# 在玩家状态中处理技能输入
func handle_skill_input():
    # 冲刺技能
    if Input.is_action_just_pressed("dash") and player.skill_manager.can_use_skill("dash"):
        return "Dash"
    
    # 滑铲技能
    if Input.is_action_just_pressed("slide") and player.skill_manager.can_use_skill("slide"):
        return "Slide"
    
    # 技能菜单
    if Input.is_action_just_pressed("skill_menu"):
        player.skill_manager.toggle_skill_menu()
```

## 动画系统集成

### 新增动画

为玩家角色添加技能相关动画：
- `dash`: 冲刺动画
- `wall_slide`: 贴墙滑行动画
- `wall_jump`: 墙跳动画
- `slide`: 滑铲动画

### 动画状态机

```gdscript
# 在各个技能状态中更新动画
func update_animation():
    match state_name:
        "Dash":
            player.animated_sprite.play("dash")
        "WallSlide":
            player.animated_sprite.play("wall_slide")
        "Slide":
            player.animated_sprite.play("slide")
```

## 音效系统集成

### 新增音效

在ResourceManager中添加技能相关音效：
- `dash.wav`: 冲刺音效
- `wall_jump.wav`: 墙跳音效
- `slide.wav`: 滑铲音效
- `skill_unlock.wav`: 技能解锁音效
- `skill_upgrade.wav`: 技能升级音效

## 性能优化

### 技能冷却管理

```gdscript
# 高效的冷却时间管理
class_name SkillCooldownManager
extends Node

var active_cooldowns: Dictionary = {}

func start_cooldown(skill_name: String, duration: float):
    active_cooldowns[skill_name] = Time.get_time_dict_from_system()["unix"] + duration

func is_skill_ready(skill_name: String) -> bool:
    if not active_cooldowns.has(skill_name):
        return true
    
    var current_time = Time.get_time_dict_from_system()["unix"]
    return current_time >= active_cooldowns[skill_name]
```

### 状态缓存

```gdscript
# 缓存技能状态以避免重复计算
var skill_cache: Dictionary = {}
var cache_dirty: bool = true

func get_skill_level(skill_name: String) -> int:
    if cache_dirty:
        _rebuild_cache()
    
    return skill_cache.get(skill_name, 0)
```

## 测试与调试

### 调试命令

```gdscript
# 调试控制台命令
func _ready():
    # 注册调试命令
    if OS.is_debug_build():
        Console.register_command("unlock_skill", _debug_unlock_skill)
        Console.register_command("reset_skills", _debug_reset_skills)
        Console.register_command("add_coins", _debug_add_coins)

func _debug_unlock_skill(skill_name: String):
    skill_manager.unlock_skill(skill_name)
    print("已解锁技能: ", skill_name)
```

### 单元测试

```gdscript
# 技能系统测试
class_name TestSkillSystem
extends GutTest

func test_skill_unlock():
    var skill_manager = SkillManager.new()
    var initial_coins = 100
    
    # 测试技能解锁
    skill_manager.set_coins(initial_coins)
    var result = skill_manager.unlock_skill("dash")
    
    assert_true(result, "技能解锁应该成功")
    assert_true(skill_manager.is_skill_unlocked("dash"), "技能应该被标记为已解锁")
```

## 扩展性设计

### 插件化技能

```gdscript
# 技能插件接口
class_name SkillPlugin
extends Resource

@export var plugin_name: String
@export var skill_script: GDScript

# 动态加载技能
func load_skill_plugin(plugin_path: String):
    var plugin = load(plugin_path) as SkillPlugin
    if plugin:
        var skill_instance = plugin.skill_script.new()
        register_skill(plugin.plugin_name, skill_instance)
```

### 自定义技能编辑器

```gdscript
# 技能编辑器工具
@tool
class_name SkillEditor
extends EditorPlugin

func _enter_tree():
    add_custom_type(
        "SkillData",
        "Resource",
        preload("skill_data.gd"),
        preload("skill_icon.svg")
    )
```

---

## 使用指南

### 如何测试技能系统

1. 打开测试场景：`scenes/test/skill_test_scene.tscn`
2. 运行场景，使用以下控制：
   - WASD：移动
   - 空格：跳跃
   - X/Shift：冲刺
   - S/Down：滑铲
   - 靠近墙壁时按空格：墙跳
   - 回车键：打开技能升级界面
   - 空格键：添加测试金币

### 如何集成到现有场景

1. 确保玩家对象已经引用了技能管理器：
   ```gdscript
   var skill_manager = SkillManager.new()
   ```

2. 在玩家状态机中添加技能状态：
   ```gdscript
   _states["Dash"] = DashState.new(self)
   _states["WallSlide"] = WallSlideState.new(self)
   _states["WallJump"] = WallJumpState.new(self)
   _states["Slide"] = SlideState.new(self)
   ```

3. 在玩家状态中添加技能输入检测：
   ```gdscript
   if Input.is_action_just_pressed("dash") and player.can_use_skill("dash"):
       return "Dash"
   ```

4. 添加技能升级UI：
   ```gdscript
   var skill_ui = preload("res://scenes/ui/skill_upgrade_ui.tscn").instantiate()
   skill_ui.set_skill_manager(player.get_skill_manager())
   ```

### 扩展新技能

1. 创建新的技能状态类，继承自PlayerState
2. 在SkillManager中添加新技能的配置和参数
3. 在玩家状态机中注册新技能状态
4. 在相关状态中添加技能输入检测
5. 在技能升级UI中添加新技能的面板

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本文档详细描述了技能系统的设计和实现方案。该系统采用模块化设计，易于扩展和维护，为游戏提供了丰富的玩法机制。开发人员应参考此文档进行技能系统的实现和扩展。
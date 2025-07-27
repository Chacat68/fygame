# 技能系统使用指南

## 概述

技能系统为游戏增加了更丰富的玩法机制，包括冲刺、墙跳、滑铲等技能，以及基于金币的技能升级树。系统采用模块化设计，易于扩展和维护。

## 已实现功能

- ✅ **技能管理器**：管理技能解锁、升级、冷却和使用
- ✅ **技能状态**：
  - 冲刺（Dash）：快速向前冲刺，冲刺期间无敌
  - 墙跳（Wall Jump）：在墙壁上跳跃，支持连续墙跳
  - 墙滑（Wall Slide）：贴墙滑行，减缓下落速度
  - 滑铲（Slide）：滑过低矮障碍物并攻击敌人
- ✅ **技能升级UI**：解锁和升级技能的界面
- ✅ **技能解锁和升级系统**：使用金币解锁和升级技能
- ✅ **技能冷却管理**：管理技能的冷却时间
- ✅ **玩家状态机集成**：将技能状态集成到玩家状态机中
- ✅ **测试场景**：用于测试技能系统的场景

## 如何测试

1. 打开测试场景：`scenes/test/skill_test_scene.tscn`
2. 运行场景，使用以下控制：
   - WASD：移动
   - 空格：跳跃
   - X/Shift：冲刺
   - S/Down：滑铲
   - 靠近墙壁时按空格：墙跳
   - 回车键：打开技能升级界面
   - 空格键：添加测试金币

## 如何集成到现有场景

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

## 文件结构

- **技能管理器**：`/scripts/systems/skill_manager.gd`
- **技能状态**：
  - `/scripts/entities/player/player_states/dash_state.gd`
  - `/scripts/entities/player/player_states/wall_slide_state.gd`
  - `/scripts/entities/player/player_states/wall_jump_state.gd`
  - `/scripts/entities/player/player_states/slide_state.gd`
- **技能升级UI**：
  - `/scripts/ui/skill_upgrade_ui.gd`
  - `/scenes/ui/skill_upgrade_ui.tscn`
- **测试场景**：
  - `/scripts/test/skill_test_scene.gd`
  - `/scenes/test/skill_test_scene.tscn`

## 扩展新技能

1. 创建新的技能状态类，继承自PlayerState
2. 在SkillManager中添加新技能的配置和参数
3. 在玩家状态机中注册新技能状态
4. 在相关状态中添加技能输入检测
5. 在技能升级UI中添加新技能的面板

## 技能参数配置

技能参数可以在GameConfig中配置，例如：

```gdscript
# 冲刺技能
@export var dash_distance: float = 120.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0
@export var dash_unlock_cost: int = 100
```

## 注意事项

- 技能状态需要正确处理进入和退出逻辑
- 技能冷却时间需要在SkillManager中管理
- 技能升级效果需要在SkillManager中实现
- 技能解锁和升级需要消耗金币

## 详细文档

更详细的技能系统设计文档请参考：`/docs/modules/skill_system.md`
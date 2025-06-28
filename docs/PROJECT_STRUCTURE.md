# 项目结构说明

## 概述

本项目已经重新组织，采用更清晰的文件夹结构，便于开发和维护。

## 文件夹结构

### 根目录
- `project.godot` - Godot项目配置文件
- `icon.svg` - 项目图标
- `README.md` - 项目说明文档
- `export_presets.cfg` - 导出预设配置
- `default_bus_layout.tres` - 音频总线布局

### 主要文件夹

#### `/addons/`
存放Godot插件
- `teleport_system/` - 传送系统插件

#### `/assets/`
游戏资源文件
- `fonts/` - 字体文件
- `images/` - 图片资源
- `music/` - 音乐文件
- `sounds/` - 音效文件
- `sprites/` - 精灵图片

#### `/docs/`
项目文档
- `design/` - 设计文档
  - `game_mechanics.md` - 游戏机制设计（已更新，包含完整系统描述）
  - `player_state_machine.md` - 玩家状态机设计（已更新，包含实际实现）
  - `game_config_system.md` - 游戏配置系统设计（新增）
  - `teleport_system_design.md` - 传送系统设计文档（新增）
  - `ui_design.md` - UI设计文档
  - `level_design.md` - 关卡设计文档
- `guides/` - 使用指南
  - 浮动文本优化指南
  - 传送系统变更日志
  - 传送测试指南
- `system/` - 系统文档
  - 传送系统指南
- `api/` - API文档
  - `resource_manager_api.md` - 资源管理器API
- `PROJECT_STRUCTURE.md` - 项目结构说明（本文档）
- `README.md` - 项目说明文档

#### `/scenes/`
场景文件，按功能分类
- `entities/` - 实体场景
  - `coin.tscn` - 金币
  - `player.tscn` - 玩家
  - `slime.tscn` - 史莱姆敌人
  - `platform.tscn` - 平台
  - `portal.tscn` - 传送门
  - `killzone.tscn` - 死亡区域
- `levels/` - 关卡场景
  - `level2.tscn` - 第二关
  - `mountain_cave_level.tscn` - 山洞关卡
- `managers/` - 管理器场景
  - `game_manager.tscn` - 游戏管理器
  - `game_state.tscn` - 游戏状态
  - `floating_text.tscn` - 浮动文本
  - `music.tscn` - 音乐管理器
- `ui/` - 用户界面场景
  - `main_menu.tscn` - 主菜单
  - `game_start_screen.tscn` - 游戏开始界面
  - `ui.tscn` - 游戏内UI
- `game.tscn` - 主游戏场景

#### `/scripts/`
脚本文件，按功能模块分类
- `autoload/` - 自动加载脚本
  - `resource_manager_autoload.gd` - 资源管理器自动加载（AutoLoad单例）
- `entities/` - 实体脚本
  - `player/` - 玩家相关脚本
    - `player.gd` - 玩家主脚本（集成GameConfig配置系统）
    - `player_states/` - 玩家状态机系统
      - `player_state.gd` - 状态机基类
      - `idle_state.gd` - 闲置状态
      - `run_state.gd` - 奔跑状态
      - `jump_state.gd` - 跳跃状态
      - `fall_state.gd` - 下落状态
      - `hurt_state.gd` - 受伤状态
      - `death_state.gd` - 死亡状态
  - `enemies/` - 敌人脚本
    - `slime.gd` - 史莱姆脚本（包含完整状态机和AI系统）
  - `items/` - 道具脚本
    - `coin.gd` - 金币脚本（集成FloatingTextManager）
    - `coin_counter.gd` - 金币计数器（集成传送系统）
- `managers/` - 管理器脚本
  - `game_manager.gd` - 游戏管理器
  - `game_state.gd` - 游戏状态管理
  - `floating_text_manager.gd` - 浮动文本管理器
  - `resource_manager.gd` - 资源管理器（预加载所有游戏资源）
- `ui/` - UI脚本
  - `main_menu.gd` - 主菜单脚本
  - `game_start_screen.gd` - 游戏开始界面脚本
- `levels/` - 关卡脚本
  - `level2.gd` - 第二关脚本
  - `mountain_cave_level.gd` - 山洞关卡脚本
  - `killzone.gd` - 死亡区域脚本
  - `portal.gd` - 传送门脚本
- `systems/` - 系统脚本
  - `game_config.gd` - 游戏配置系统（核心配置管理）
  - `teleport_config.gd` - 传送配置
  - `teleport_manager.gd` - 传送管理器（完整传送系统）
  - `floating_text.gd` - 浮动文本系统（支持动画和配置）
- `utils/` - 工具脚本
  - `config_hot_reload.gd` - 配置热重载
  - `config_sync_tool.gd` - 配置同步工具
  - `debug_config_overlay.gd` - 调试配置覆盖
  - `room_config.gd` - 房间配置

#### `/resources/`
资源配置文件
- `default_teleport_config.tres` - 默认传送配置
- `game_config.tres` - 游戏配置

#### `/shaders/`
着色器文件
- `pixelate.gdshader` - 像素化着色器

#### `/tests/`
测试相关文件
- `unit/` - 单元测试
  - 各种测试脚本
- `integration/` - 集成测试
  - `teleport_test_scene.tscn` - 传送测试场景
- `examples/` - 示例代码
  - `floating_text_usage_example.gd` - 浮动文本使用示例
  - `teleport_example.gd` - 传送系统示例

#### `/tools/`
开发工具
- `scripts/` - 工具脚本
  - `quick_test.sh` - 快速测试脚本

## 优势

1. **清晰的分类**: 文件按功能和类型分类，便于查找和维护
2. **模块化**: 相关功能的文件放在一起，便于模块化开发
3. **可扩展性**: 新功能可以轻松添加到相应的文件夹中
4. **测试友好**: 测试文件单独组织，便于自动化测试
5. **文档完整**: 所有文档集中管理，便于查阅

## 注意事项

- 添加新功能时，请将文件放在相应的文件夹中
- 保持文件命名的一致性
- 更新文档时，请同时更新相关的设计文档
- 测试文件应该与被测试的功能模块对应
# 小王子历险记 (FyGame)

基于Brackeys教程制作的2D平台跳跃游戏demo

**教程地址：** https://youtu.be/LOhfqjmasi0?si=qng6rKh2-j9MwLgN

## 项目简介

这是一个基于Brackeys教程制作的游戏demo项目，使用Godot 4引擎开发。通过该项目，你可以学习如何创建一个完整的2D平台跳跃游戏，包括角色控制、敌人AI、收集系统、关卡管理等核心功能。

## 技术栈

- **游戏引擎：** Godot 4.x
- **编程语言：** GDScript
- **项目类型：** 2D平台跳跃游戏
- **目标平台：** PC (Windows/Mac/Linux)


## 项目结构

本项目遵循标准化的目录结构和文件命名规范：

```
fygame/
├── docs/                          # 项目文档目录
│   ├── modules/                   # 模块设计文档
│   ├── guides/                    # 使用指南
│   ├── development/               # 开发文档
│   └── testing/                   # 测试文档
├── scenes/                        # Godot场景文件
│   ├── levels/                    # 关卡场景 (lv1.tscn, lv2.tscn, lv3.tscn)
│   ├── entities/                  # 游戏实体场景 (player, coin, slime等)
│   ├── managers/                  # 管理器场景
│   ├── ui/                        # 用户界面场景
│   ├── debug/                     # 调试场景
│   └── test/                      # 测试场景
├── scripts/                       # GDScript脚本文件
│   ├── autoload/                  # 自动加载脚本
│   ├── entities/                  # 实体脚本 (player, enemies, items)
│   ├── managers/                  # 管理器脚本
│   ├── systems/                   # 系统脚本
│   ├── levels/                    # 关卡脚本
│   ├── ui/                        # UI脚本
│   ├── utils/                     # 工具脚本
│   └── debug/                     # 调试脚本
├── resources/                     # Godot资源文件
├── assets/                        # 原始资源文件
│   ├── sprites/                   # 精灵图片
│   ├── sounds/                    # 音效文件
│   ├── music/                     # 背景音乐
│   ├── fonts/                     # 字体文件
│   ├── images/                    # 图片资源
│   └── ui/                        # UI资源
├── addons/                        # Godot插件
│   ├── gut/                       # GUT测试框架
│   └── teleport_system/           # 传送系统插件
├── tests/                         # 测试文件目录
├── tools/                         # 开发工具目录
├── shaders/                       # 着色器文件
└── project.godot                  # Godot项目配置文件
```

详细的项目结构说明请参考：[PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)

## 游戏截图

![游戏截图1](https://blog-1259751088.cos.ap-shanghai.myqcloud.com/20260201034300170.webp?imageSlim)

![游戏截图2](https://blog-1259751088.cos.ap-shanghai.myqcloud.com/20260201034328059.webp?imageSlim)

![游戏截图3](https://blog-1259751088.cos.ap-shanghai.myqcloud.com/20260201034409861.webp?imageSlim)



## 快速开始

### 环境要求
- Godot 4.x 引擎
- 支持的操作系统：Windows、macOS、Linux

### 运行游戏
1. 克隆或下载项目到本地
2. 使用Godot 4.x打开项目文件 `project.godot`
3. 点击运行按钮或按F5开始游戏

### 控制方式
- **移动：** A/D键 或 方向键左右
- **跳跃：** 空格键
- **双段跳：** 在空中再次按空格键

## 游戏玩法

### 基本玩法
- 这是一款2D平台跳跃游戏，玩家控制一个骑士角色在平台间移动和跳跃
- 游戏目标是收集尽可能多的金币，击杀敌人获取分数，同时避免掉落或受到伤害
- 通过传送门可以进入下一关卡

## 角色能力
- **双段跳**：玩家可以在空中再次按下跳跃键执行第二段跳跃，最多可跳跃2次
- **动态动画**：角色根据移动状态自动切换闲置、奔跑、跳跃和受伤动画
- **血量系统**：玩家拥有100点血量，每次受到伤害会减少10点血量
- **无敌时间**：受伤后有1秒无敌时间，角色会闪烁表示无敌状态
- **受伤反馈**：受伤时会播放受伤音效并短暂向上弹起

## 敌人系统
- **史莱姆敌人**：沿着平台自动移动，移动速度为45像素/秒
- **智能巡逻**：使用两组射线检测技术（墙壁检测和地面边缘检测）避免掉落平台
- **敌人类型**：普通史莱姆敌人，可通过调整移动速度参数创建不同难度的敌人
- **踩踏击杀**：玩家可以通过踩踏敌人头部区域来击杀它们并获得反弹力
- **危险接触**：玩家碰到敌人会受到10点伤害并短暂无敌，血量为零时死亡
- **击杀奖励**：击杀敌人会增加分数并显示飘字效果

## 收集系统
- **金币收集**：玩家可以收集场景中的金币增加分数，每个金币增加1分
- **击杀计数**：击杀敌人会同时增加击杀计数和金币数
- **视觉反馈**：收集金币时会播放收集动画和音效，并显示"+1"飘字效果
- **计分板**：UI界面实时显示已收集的金币数量和击杀敌人数量
- **信号系统**：使用Godot信号系统在UI和游戏管理器之间传递分数变化

## 传送门系统
- **关卡传送**：传送门可以配置为传送到指定关卡或自动进入下一关
- **场景传送**：支持传送到任意场景的指定位置
- **视觉效果**：传送门具有蓝色发光效果、粒子特效和闪烁动画
- **防重复触发**：传送门被触发后会自动禁用，防止重复传送
- **管理器集成**：与TeleportManager和LevelManager深度集成，支持传送特效和关卡管理
- **配置灵活**：支持代码配置和运行时动态修改传送目标
- **错误处理**：完整的错误检查和调试信息输出

## 死亡机制
- **掉落死亡**：角色掉落超过Y坐标1000或进入死亡区域时立即死亡
- **血量耗尽**：血量降至零时角色死亡，播放死亡动画
- **复活效果**：死亡后会自动重新加载当前场景，角色会有1.5秒的淡入效果并获得额外的无敌时间
- **状态保持**：使用GameState单例在场景重载后保持玩家复活状态
- **延迟重载**：死亡后有1秒延迟再重新加载场景，给予玩家视觉反馈时间

## 核心系统架构

### 关卡管理系统
项目采用统一的关卡管理系统，提供模块化和数据驱动的开发方式：

**核心组件：**
- **LevelConfig资源** (`scripts/systems/level_config.gd`) - 统一管理关卡配置信息
- **LevelManager管理器** (`scripts/managers/level_manager.gd`) - 负责关卡加载、切换和状态管理
- **关卡场景** (`scenes/levels/lv*.tscn`) - 遵循标准命名规范

**关卡命名规范：**
- 场景文件：`lv{数字}.tscn`（如：`lv2.tscn`, `lv3.tscn`）
- 脚本文件：`level{数字}.gd`（如：`level2.gd`, `level3.gd`）
- 统一的数字编号便于管理和扩展

> 备注：当前项目场景从 `lv2.tscn` 开始，`lv1.tscn` 预留未使用。

详细设计文档：[关卡设计指南](docs/design/integrated_level_design_guide.md)

### 模块设计

项目采用模块化设计，各功能模块独立开发和维护：

| 模块 | 脚本路径 | 主要功能 |
|------|----------|----------|
| **角色控制** | `scripts/entities/player/player.gd` | 动画状态机、物理运动、信号通信 |
| **玩家状态机** | `scripts/entities/player/player_states/` | 状态管理（idle, run, jump, dash等） |
| **敌人AI** | `scripts/entities/enemies/slime.gd` | 自动转向、射线检测、移动控制 |
| **游戏管理** | `scripts/managers/game_manager.gd` | 场景切换、分数统计、状态管理 |
| **收集系统** | `scripts/entities/items/coin.gd`<br>`scripts/entities/items/coin_counter.gd` | 金币收集、分数显示、音效反馈 |
| **死亡区域** | `scripts/levels/killzone.gd` | 碰撞检测、死亡处理 |
| **反馈系统** | `scripts/systems/floating_text.gd`<br>`scripts/managers/floating_text_manager.gd` | 动态文本、动画效果、视觉反馈 |
| **传送系统** | `scripts/systems/teleport_manager.gd`<br>`scripts/systems/teleport_config.gd` | 传送门管理、场景切换、特效 |
| **音频系统** | `scripts/managers/audio_manager.gd` | 音效播放、背景音乐、音量控制 |
| **存档系统** | `scripts/managers/save_manager.gd`<br>`scripts/systems/save_data.gd` | 游戏存档、进度保存、存档槽位 |
| **技能系统** | `scripts/systems/skill_manager.gd` | 技能管理、技能升级 |

**设计原则：**
- 按功能模块分类组织
- 管理器类统一放在 `managers/` 目录
- 系统级脚本放在 `systems/` 目录
- 工具类脚本放在 `utils/` 目录

## 技术实现细节

### 角色控制
- 使用Godot的CharacterBody2D实现物理移动
- 通过跟踪跳跃次数实现双段跳
- 使用动画状态机管理不同状态下的角色动画

### 敌人AI
- 使用射线检测实现边缘识别和自动转向
- 通过调整移动速度控制难度
- 简单但有效的巡逻行为模式

### 游戏管理
- 集中管理游戏状态和分数
- 使用信号系统实现模块间通信
- 提供游戏重置功能

### 用户界面
- 使用CanvasLayer实现固定位置UI
- 动态更新分数显示
- 提供即时视觉反馈

## 开发指南

### 添加新关卡
1. 在 `scenes/levels/` 创建 `lv{数字}.tscn`
2. 在 `scripts/levels/` 创建对应脚本（如需要）
3. 更新 `resources/level_config.tres`
4. 更新 `docs/design/level_index.md`

### 添加新功能模块
1. 在对应目录创建场景和脚本文件
2. 遵循现有的命名规范
3. 更新相关文档
4. 考虑与现有系统的集成

### 代码规范
- 遵循 [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) 中的文件组织规范
- 使用中文注释
- 保持代码的模块化和可维护性
- 及时更新相关文档

## 文档链接

### 设计文档
- [项目结构说明](docs/PROJECT_STRUCTURE.md)
- [项目总设计文档](docs/PROJECT_DESIGN.md)
- [关卡设计指南](docs/modules/level_design.md)
- [关卡索引](docs/modules/level_index.md)
- [传送系统设计](docs/modules/teleport_system.md)
- [敌人AI和战斗系统](docs/modules/enemy_ai_combat.md)
- [技能系统设计](docs/modules/skill_system.md)
- [玩家状态机设计](docs/modules/player_state_machine.md)

### 使用指南
- [传送门使用指南](docs/guides/PORTAL_TELEPORT_GUIDE.md)
- [传送系统测试指南](docs/guides/TELEPORT_TEST_GUIDE.md)
- [浮动文本优化指南](docs/guides/FLOATING_TEXT_OPTIMIZATION.md)
- [技能系统使用指南](docs/guides/SKILL_SYSTEM_USAGE_GUIDE.md)
- [技能系统扩展指南](docs/guides/SKILL_SYSTEM_EXTENSION_GUIDE.md)
- [技能系统演示指南](docs/guides/SKILL_SYSTEM_DEMO_GUIDE.md)
- [技能系统FAQ](docs/guides/SKILL_SYSTEM_FAQ.md)

### 系统文档
- [传送系统更新日志](docs/guides/TELEPORT_SYSTEM_CHANGELOG.md)
- [音频系统模块](docs/modules/audio_system.md)
- [配置系统模块](docs/modules/config_system.md)
- [UI系统模块](docs/modules/ui_system.md)
- [游戏机制模块](docs/modules/game_mechanics.md)

### 开发文档
- [技能系统代码审查清单](docs/development/SKILL_SYSTEM_CODE_REVIEW_CHECKLIST.md)
- [技能系统性能优化](docs/development/SKILL_SYSTEM_PERFORMANCE_OPTIMIZATION.md)

### 测试文档
- [技能系统测试计划](docs/testing/SKILL_SYSTEM_TEST_PLAN.md)

## 扩展规划

### 短期目标
- 完善关卡编辑器功能
- 优化敌人AI系统
- 增加更多关卡内容
- 完善音效和视觉效果

### 长期目标
- 程序化关卡生成
- 多人合作模式
- 技能树和升级系统
- 移动平台支持

---

**注意事项：**
- 本项目基于Brackeys教程制作，适合学习Godot游戏开发
- 如有问题或建议，请通过项目Issues提出
- 欢迎贡献代码和文档改进
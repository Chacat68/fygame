# 项目结构说明

本文档详细说明了FyGame项目的目录结构和文件组织方式。

## 总体结构

```
fygame/
├── .vscode/                       # VS Code配置目录
├── docs/                          # 项目文档目录
├── scenes/                        # Godot场景文件
├── scripts/                       # GDScript脚本文件
├── resources/                     # Godot资源文件
├── assets/                        # 原始资源文件
├── addons/                        # Godot插件目录
├── shaders/                       # 着色器文件
├── tests/                         # 测试文件目录
├── tools/                         # 开发工具目录
├── project.godot                  # Godot项目配置文件
├── export_presets.cfg             # 导出预设配置
├── default_bus_layout.tres        # 默认音频总线布局
├── icon.svg                       # 项目图标文件
├── PROJECT_RESTRUCTURE_PLAN.md    # 项目重构计划
└── README.md                      # 项目说明文档
```

## 详细目录说明

### docs/ - 文档目录

```
docs/
├── PROJECT_DESIGN.md             # 项目总设计文档
├── PROJECT_STRUCTURE.md          # 项目结构说明（本文档）
├── modules/                      # 模块设计文档
│   ├── README.md                 # 模块文档说明
│   ├── audio_system.md           # 音频系统模块设计
│   ├── config_system.md          # 配置系统模块设计
│   ├── enemy_ai_combat.md        # 敌人AI与战斗模块设计
│   ├── game_mechanics.md         # 游戏机制模块设计
│   ├── level_design.md           # 关卡设计模块设计
│   ├── level_index.md            # 关卡索引
│   ├── player_state_machine.md   # 玩家状态机模块设计
│   ├── skill_system.md           # 技能系统模块设计
│   ├── stomp_kill_feature.md     # 踩踏击杀功能设计
│   ├── teleport_system.md        # 传送系统模块设计
│   └── ui_system.md              # UI系统模块设计
├── guides/                       # 使用指南
│   ├── README.md                 # 指南文档说明
│   ├── FLOATING_TEXT_OPTIMIZATION.md # 飘字优化指南
│   ├── PORTAL_TELEPORT_GUIDE.md  # 传送门指南
│   ├── PORTAL_VISUAL_EFFECTS_GUIDE.md # 传送门视觉效果指南
│   ├── SKILL_SYSTEM_DEMO_GUIDE.md # 技能系统演示指南
│   ├── SKILL_SYSTEM_EXTENSION_GUIDE.md # 技能系统扩展指南
│   ├── SKILL_SYSTEM_FAQ.md       # 技能系统FAQ
│   ├── TELEPORT_SYSTEM_CHANGELOG.md # 传送系统变更日志
│   ├── TELEPORT_TEST_GUIDE.md    # 传送测试指南
│   └── teleport_system_guide.md  # 传送系统使用指南
├── development/                  # 开发文档
│   ├── README.md                 # 开发文档说明
│   ├── SKILL_SYSTEM_CODE_REVIEW_CHECKLIST.md # 技能系统代码审查清单
│   └── SKILL_SYSTEM_PERFORMANCE_OPTIMIZATION.md # 技能系统性能优化
└── testing/                      # 测试文档
    ├── README.md                 # 测试文档说明
    └── SKILL_SYSTEM_TEST_PLAN.md # 技能系统测试计划
```

**文档组织：**
- `PROJECT_DESIGN.md` - 项目总设计文档，包含所有模块的概览
- `PROJECT_STRUCTURE.md` - 项目结构说明文档
- `modules/` - 各个功能模块的详细设计文档
- `guides/` - 使用指南、教程和操作手册
- `development/` - 开发相关文档、规范和检查清单
- `testing/` - 测试计划、测试策略和测试文档
- 所有文档使用Markdown格式
- 每个目录都有README.md说明文档内容
- 保持文档与代码的同步更新

### scenes/ - 场景目录

```
scenes/
├── debug/                         # 调试场景
│   └── portal_test.tscn          # 传送门测试场景
├── entities/                      # 游戏实体场景
│   ├── coin.tscn                 # 金币场景
│   ├── killzone.tscn             # 死亡区域场景
│   ├── platform.tscn             # 平台场景
│   ├── player.tscn               # 玩家角色场景
│   ├── portal.tscn               # 传送门场景
│   └── slime.tscn                # 史莱姆敌人场景
├── levels/                        # 关卡场景
│   ├── lv2.tscn                  # 关卡2场景文件
│   └── lv3.tscn                  # 关卡3场景文件
├── managers/                      # 管理器场景
│   ├── floating_text.tscn        # 飘字管理器场景
│   ├── game_manager.tscn         # 游戏管理器场景
│   ├── game_state.tscn           # 游戏状态场景
│   └── music.tscn                # 音乐管理器场景
├── ui/                           # 用户界面场景
│   ├── game_start_screen.tscn    # 游戏开始界面
│   ├── main_menu.tscn            # 主菜单界面
│   └── ui.tscn                   # 游戏内UI
├── game.tscn                     # 主游戏场景
└── test_portal.tscn              # 传送门测试场景
```

**命名规范：**
- 关卡场景：`level{数字}.tscn`
- 功能场景：使用描述性名称，小写字母+下划线
- 组件场景：按功能分类存放

### scripts/ - 脚本目录

```
scripts/
├── autoload/                      # 自动加载脚本
│   └── resource_manager_autoload.gd  # 资源管理器自动加载
├── debug/                         # 调试脚本
│   └── portal_debug.gd           # 传送门调试脚本
├── entities/                      # 实体脚本
│   ├── enemies/                   # 敌人脚本
│   │   └── slime.gd              # 史莱姆敌人脚本
│   ├── items/                     # 物品脚本
│   │   ├── coin.gd               # 金币脚本
│   │   └── coin_counter.gd       # 金币计数器脚本
│   └── player/                    # 玩家相关脚本
│       ├── player.gd             # 玩家控制脚本
│       └── player_states/        # 玩家状态脚本目录
├── levels/                        # 关卡脚本
│   ├── killzone.gd               # 死亡区域脚本
│   ├── level2.gd                 # 关卡2脚本
│   ├── level3.gd                 # 关卡3脚本
│   ├── mountain_cave_level.gd    # 山洞关卡脚本
│   └── portal.gd                 # 传送门脚本
├── managers/                      # 管理器脚本
│   ├── floating_text_manager.gd  # 飘字管理器
│   ├── game_manager.gd           # 游戏管理器
│   ├── game_state.gd             # 游戏状态管理器
│   ├── level_manager.gd          # 关卡管理器
│   └── resource_manager.gd       # 资源管理器
├── systems/                       # 系统脚本
│   ├── floating_text.gd          # 飘字系统
│   ├── game_config.gd            # 游戏配置系统
│   ├── level_config.gd           # 关卡配置系统
│   ├── teleport_config.gd        # 传送配置系统
│   └── teleport_manager.gd       # 传送管理器
├── ui/                           # UI脚本
│   ├── game_start_screen.gd      # 游戏开始界面脚本
│   └── main_menu.gd              # 主菜单脚本
└── utils/                        # 工具脚本
    ├── config_hot_reload.gd      # 配置热重载工具
    ├── config_sync_tool.gd       # 配置同步工具
    ├── debug_config_overlay.gd   # 调试配置覆盖工具
    └── room_config.gd            # 房间配置工具
```

**脚本组织原则：**
- 按功能模块分类
- 管理器类脚本放在 `managers/` 目录
- 系统级脚本放在 `systems/` 目录
- 游戏对象脚本按类型分类
- 工具类脚本放在 `utils/` 目录

### resources/ - 资源目录

```
resources/
├── default_teleport_config.tres  # 默认传送配置资源
├── game_config.tres              # 游戏配置资源
└── level_config.tres             # 关卡配置资源
```

**资源管理原则：**
- 按类型和用途分类存放
- 使用Godot原生资源格式（.tres, .res）
- 保持资源文件的相对路径一致性

### assets/ - 原始资源目录

```
assets/
├── fonts/                        # 字体文件
│   ├── PixelOperator8-Bold.ttf  # 像素字体（粗体）
│   └── PixelOperator8.ttf        # 像素字体（常规）
├── images/                       # 图片资源
│   ├── beijing.png               # 北京背景图
│   ├── beijing.tres              # 北京纹理资源
│   ├── home1.png                 # 家园图片1
│   └── home2.png                 # 家园图片2
├── music/                        # 音乐文件
│   └── time_for_adventure.mp3    # 冒险时光背景音乐
├── sounds/                       # 音效文件
│   ├── coin.wav                  # 金币音效
│   ├── explosion.wav             # 爆炸音效
│   ├── hurt.wav                  # 受伤音效
│   ├── jump.wav                  # 跳跃音效
│   ├── power_up.wav              # 强化音效
│   └── tap.wav                   # 点击音效
├── sprites/                      # 精灵图片
│   ├── coin.png                  # 金币精灵
│   ├── coin_icon.png             # 金币图标
│   ├── coin_icon_enhanced.svg    # 增强金币图标（SVG）
│   ├── fruit.png                 # 水果精灵
│   ├── heart_icon.svg            # 心形图标（SVG）
│   ├── knight.png                # 骑士精灵
│   ├── platforms.png             # 平台精灵
│   ├── portal_icon.svg           # 传送门图标（SVG）
│   ├── slime_green.png           # 绿色史莱姆精灵
│   ├── slime_purple.png          # 紫色史莱姆精灵
│   ├── sword_icon.svg            # 剑图标（SVG）
│   └── world_tileset.png         # 世界瓦片集
└── ui/                           # UI资源
    ├── Large tiles/              # 大型瓦片
    ├── Small tiles/              # 小型瓦片
    └── Tilesheets/               # 瓦片表
```

**原始资源管理：**
- 存放未经Godot处理的原始文件
- 保持源文件的完整性
- 便于资源的更新和维护

### addons/ - 插件目录

```
addons/
├── gut/                          # GUT测试框架插件
│   ├── 各种测试相关脚本和资源
│   └── plugin.cfg               # 插件配置文件
└── teleport_system/              # 传送系统插件
    ├── icons/                    # 插件图标
    ├── plugin.cfg                # 插件配置文件
    ├── teleport_config_editor.gd # 传送配置编辑器
    └── teleport_config_inspector.gd # 传送配置检查器
```

**插件管理：**
- `gut/` - 用于单元测试和集成测试的GUT框架
- `teleport_system/` - 自定义传送系统插件
- 所有插件都包含plugin.cfg配置文件

### tests/ - 测试目录

```
tests/
├── examples/                     # 测试示例
│   ├── floating_text_usage_example.gd  # 飘字使用示例
│   ├── portal_teleport_test.gd   # 传送门测试
│   ├── portal_teleport_test.tscn # 传送门测试场景
│   └── teleport_example.gd       # 传送示例
├── integration/                  # 集成测试
│   └── teleport_test_scene.tscn  # 传送测试场景
├── unit/                         # 单元测试
│   ├── run_teleport_test.gd      # 传送测试运行器
│   ├── test_floating_text_optimization.gd # 飘字优化测试
│   ├── test_teleport.gd          # 传送功能测试
│   └── test_tween_fix.gd         # 补间修复测试
├── README.md                     # 测试说明文档
├── test_gut_installation.gd      # GUT安装测试
├── test_level_manager.gd         # 关卡管理器测试
└── test_resource_manager.gd      # 资源管理器测试
```

**测试组织：**
- `examples/` - 功能使用示例和演示
- `integration/` - 集成测试场景
- `unit/` - 单元测试脚本
- 使用GUT框架进行自动化测试

### tools/ - 开发工具目录

```
tools/
├── scripts/                      # 工具脚本
│   └── quick_test.sh            # 快速测试脚本
└── project_optimizer.gd          # 项目优化工具
```

**开发工具：**
- `project_optimizer.gd` - 项目优化和清理工具
- `scripts/` - 各种开发辅助脚本
- 提高开发效率的自动化工具

### shaders/ - 着色器目录

```
shaders/
└── pixelate.gdshader            # 像素化着色器
```

**着色器管理：**
- 存放自定义着色器文件
- 按功能和效果分类组织
- 便于着色器的复用和维护
- 当前包含像素化效果着色器

## 文件命名规范

### 场景文件命名
- 关卡场景：`lv{数字}.tscn`（如：lv2.tscn, lv3.tscn）
- 功能场景：`功能名称.tscn`（小写字母+下划线）
- 组件场景：`组件名称.tscn`
- 测试场景：`test_功能名称.tscn`

### 脚本文件命名
- 类脚本：`类名.gd`（小写字母+下划线）
- 管理器：`功能_manager.gd`
- 系统脚本：`功能名称.gd`（如：teleport_config.gd）
- 自动加载脚本：`功能_autoload.gd`

### 资源文件命名
- 配置资源：`配置名称.tres`（如：game_config.tres）
- 纹理资源：`描述性名称.png/svg`
- 音频资源：`描述性名称.wav/mp3`
- 字体资源：`字体名称.ttf`

## 路径引用规范

### 绝对路径
```gdscript
# 推荐使用绝对路径引用资源
var level_config = load("res://resources/level_config.tres")
var player_scene = load("res://scenes/player/player.tscn")
```

### 相对路径
```gdscript
# 在同一目录下可使用相对路径
var coin_scene = load("coin.tscn")  # 在同一目录下
```

### 节点路径
```gdscript
# 使用标准的节点路径
@onready var level_manager = get_node("/root/LevelManager")
@onready var player = $Player
```

## 版本控制

### 忽略文件
建议在 `.gitignore` 中添加：
```
# Godot 4+ specific ignores
.godot/

# Godot-specific ignores
*.tmp
*.import

# 临时文件
*.swp
*.swo
*~

# 系统文件
.DS_Store
Thumbs.db
```

### 提交规范
- 场景文件和脚本文件一起提交
- 资源文件变更需要说明
- 配置文件变更需要详细说明

## 扩展指南

### 添加新关卡
1. 在 `scenes/levels/` 创建 `lv{数字}.tscn`
2. 在 `scripts/levels/` 创建对应脚本（如需要）
3. 更新 `resources/level_config.tres`
4. 更新 `docs/design/level_index.md`
5. 如需要，在 `tests/` 目录添加相应测试

### 添加新功能模块
1. 在对应目录创建场景和脚本文件
2. 遵循现有的命名规范
3. 更新相关文档
4. 考虑与现有系统的集成
5. 编写相应的测试用例
6. 如果是系统级功能，考虑添加到 `systems/` 目录

### 添加新插件
1. 在 `addons/` 目录创建插件文件夹
2. 创建 `plugin.cfg` 配置文件
3. 实现插件功能脚本
4. 更新项目文档
5. 在 `tests/` 目录添加插件测试

### 重构建议
- 保持目录结构的一致性
- 及时更新文档
- 考虑向后兼容性
- 进行充分的测试

## 项目优化

### 已实现的优化

#### 1. 关卡管理器优化 (LevelManager)

**新增功能：**
- **错误处理系统**: 添加了`LoadError`枚举和详细的错误分类
- **性能监控**: 实时跟踪加载时间、成功率和失败次数
- **配置验证**: 在加载前验证关卡配置的完整性
- **信号系统**: 新增`level_load_error`信号用于错误通知

**改进的加载流程：**
1. **前置验证**: 检查配置、关卡存在性和解锁状态
2. **资源验证**: 验证场景文件存在性
3. **分步加载**: 将加载过程分解为独立的验证和加载步骤
4. **性能记录**: 记录每次加载的时间和结果
5. **错误处理**: 统一的错误处理和信号发射

#### 2. 资源管理器优化 (ResourceManager)

**新增功能：**
- **动态缓存系统**: 支持运行时资源缓存
- **异步加载**: 支持后台异步加载资源
- **内存管理**: 自动清理和内存使用监控
- **性能统计**: 缓存命中率和加载统计

**改进的资源管理：**
1. **统一接口**: 所有资源获取通过`_get_resource()`统一处理
2. **缓存策略**: LRU缓存清理和内存阈值管理
3. **异步加载**: 支持后台加载大型资源
4. **错误恢复**: 完善的错误处理和重试机制
5. **性能监控**: 实时统计缓存效率和内存使用

#### 3. 单元测试系统

**新增测试文件：**
- `tests/test_level_manager.gd`: 关卡管理器测试
- `tests/test_resource_manager.gd`: 资源管理器测试

**测试覆盖范围：**
- **功能测试**: 验证核心功能正确性
- **错误处理测试**: 验证异常情况处理
- **性能测试**: 验证性能监控功能
- **信号测试**: 验证信号发射和连接

#### 4. 项目优化工具

**工具功能：**
- **项目结构检查**: 验证目录结构和文件组织
- **资源路径验证**: 检查所有资源文件是否存在
- **脚本依赖分析**: 检查关键脚本和依赖关系
- **性能瓶颈分析**: 识别大型文件和复杂场景
- **优化建议生成**: 提供具体的优化建议

### 性能改进

#### 加载性能
- **加载时间监控**: 实时跟踪每次加载的耗时
- **缓存命中率**: 提高资源访问效率
- **异步加载**: 避免主线程阻塞

#### 内存管理
- **自动清理**: 定期清理不需要的缓存
- **内存阈值**: 防止内存使用过量
- **资源复用**: 减少重复加载

#### 错误处理
- **详细错误分类**: 便于问题定位
- **错误统计**: 跟踪错误频率和类型
- **优雅降级**: 错误时的备用方案

### 使用指南

#### 运行项目优化工具
1. 在Godot编辑器中打开项目
2. 选择 `工具 > 执行脚本`
3. 选择 `tools/project_optimizer.gd`
4. 查看生成的 `optimization_report.txt`

#### 运行单元测试
```bash
# 如果安装了GUT测试框架
godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/
```

#### 监控性能数据
```gdscript
# 获取关卡管理器性能数据
var level_stats = LevelManager.performance_data
print("平均加载时间: %.3f秒" % level_stats["average_load_time"])

# 获取资源管理器性能数据
var resource_stats = ResourceManager.get_performance_stats()
print("缓存命中率: %.1f%%" % (resource_stats["cache_hits"] * 100.0 / (resource_stats["cache_hits"] + resource_stats["cache_misses"])))
```

## 项目重构历史

### 重构前的问题分析

1. **根目录混乱**: 测试文件直接放在根目录
2. **scripts分类不清**: 所有脚本混在一起，缺乏逻辑分组
3. **文档分散**: 设计文档和系统文档分开存放
4. **测试文件无组织**: 测试相关文件散落各处

### 重构步骤

1. 创建新的文件夹结构
2. 移动文档文件到docs文件夹
3. 重新组织scripts文件夹
4. 重新组织scenes文件夹
5. 移动测试文件到tests文件夹
6. 创建工具文件夹

### 重构后的改进

- **清晰的目录结构**: 按功能模块组织文件
- **统一的文档管理**: 所有文档集中在docs目录
- **完善的测试体系**: 单元测试、集成测试和示例分离
- **开发工具支持**: 专门的tools目录存放开发辅助工具

---

**注意事项：**
- 本文档需要随项目结构变化及时更新
- 新加入的开发者应首先阅读本文档
- 如有结构调整建议，请通过项目Issues提出
- 详细的优化指南请参考 `docs/OPTIMIZATION_GUIDE.md`
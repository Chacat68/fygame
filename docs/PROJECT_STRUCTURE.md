# 项目结构说明

本文档详细说明了FyGame项目的目录结构和文件组织方式。

## 总体结构

```
fygame/
├── docs/                          # 项目文档目录
├── scenes/                        # Godot场景文件
├── scripts/                       # GDScript脚本文件
├── resources/                     # Godot资源文件
├── assets/                        # 原始资源文件
├── project.godot                  # Godot项目配置文件
└── README.md                      # 项目说明文档
```

## 详细目录说明

### docs/ - 文档目录

```
docs/
├── design/                        # 设计文档
│   ├── integrated_level_design_guide.md  # 关卡设计指南
│   └── level_index.md             # 关卡索引文档
├── project_structure.md           # 项目结构说明（本文档）
└── README.md                      # 文档目录说明
```

**用途说明：**
- `design/` - 存放游戏设计相关文档
- `integrated_level_design_guide.md` - 完整的关卡设计指南
- `level_index.md` - 关卡列表和管理信息

### scenes/ - 场景目录

```
scenes/
├── levels/                        # 关卡场景
│   ├── level1.tscn               # 关卡1场景文件
│   ├── level2.tscn               # 关卡2场景文件
│   └── level3.tscn               # 关卡3场景文件
├── player/                        # 玩家相关场景
│   └── player.tscn               # 玩家角色场景
├── enemies/                       # 敌人场景
│   └── slime.tscn                # 史莱姆敌人场景
├── ui/                           # 用户界面场景
│   ├── main_menu.tscn            # 主菜单界面
│   └── game_ui.tscn              # 游戏内UI
├── collectibles/                  # 收集品场景
│   └── coin.tscn                 # 金币场景
├── environment/                   # 环境元素场景
│   ├── platform.tscn             # 平台场景
│   └── killzone.tscn             # 死亡区域场景
└── main.tscn                     # 主场景文件
```

**命名规范：**
- 关卡场景：`level{数字}.tscn`
- 功能场景：使用描述性名称，小写字母+下划线
- 组件场景：按功能分类存放

### scripts/ - 脚本目录

```
scripts/
├── managers/                      # 管理器脚本
│   ├── level_manager.gd          # 关卡管理器
│   ├── game_manager.gd           # 游戏管理器
│   └── audio_manager.gd          # 音频管理器
├── systems/                       # 系统脚本
│   ├── level_config.gd           # 关卡配置系统
│   ├── save_system.gd            # 存档系统
│   └── input_system.gd           # 输入系统
├── player/                        # 玩家相关脚本
│   ├── player.gd                 # 玩家控制脚本
│   └── player_state.gd           # 玩家状态管理
├── enemies/                       # 敌人脚本
│   ├── slime.gd                  # 史莱姆敌人脚本
│   └── enemy_base.gd             # 敌人基类
├── ui/                           # UI脚本
│   ├── main_menu.gd              # 主菜单脚本
│   ├── game_ui.gd                # 游戏UI脚本
│   └── coin_counter.gd           # 金币计数器脚本
├── collectibles/                  # 收集品脚本
│   └── coin.gd                   # 金币脚本
├── environment/                   # 环境脚本
│   ├── platform.gd               # 平台脚本
│   ├── moving_platform.gd        # 移动平台脚本
│   └── killzone.gd               # 死亡区域脚本
├── utils/                        # 工具脚本
│   ├── floating_text.gd          # 飘字效果脚本
│   └── game_state.gd             # 游戏状态单例
└── autoload/                     # 自动加载脚本
    ├── global.gd                 # 全局脚本
    └── scene_manager.gd          # 场景管理器
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
├── level_config.tres             # 关卡配置资源
├── game_settings.tres            # 游戏设置资源
├── textures/                     # 纹理资源
│   ├── player/                   # 玩家纹理
│   ├── enemies/                  # 敌人纹理
│   ├── environment/              # 环境纹理
│   └── ui/                       # UI纹理
├── audio/                        # 音频资源
│   ├── sfx/                      # 音效文件
│   └── music/                    # 背景音乐
├── fonts/                        # 字体资源
├── materials/                    # 材质资源
└── themes/                       # UI主题资源
```

**资源管理原则：**
- 按类型和用途分类存放
- 使用Godot原生资源格式（.tres, .res）
- 保持资源文件的相对路径一致性

### assets/ - 原始资源目录

```
assets/
├── sprites/                      # 原始精灵图片
│   ├── player/                   # 玩家精灵
│   ├── enemies/                  # 敌人精灵
│   ├── environment/              # 环境精灵
│   └── ui/                       # UI精灵
├── sounds/                       # 原始音效文件
├── music/                        # 原始音乐文件
├── fonts/                        # 原始字体文件
└── source/                       # 源文件（PSD, AI等）
```

**原始资源管理：**
- 存放未经Godot处理的原始文件
- 保持源文件的完整性
- 便于资源的更新和维护

## 文件命名规范

### 场景文件命名
- 关卡场景：`level{数字}.tscn`
- 功能场景：`功能名称.tscn`（小写字母+下划线）
- 组件场景：`组件名称.tscn`

### 脚本文件命名
- 类脚本：`类名.gd`（小写字母+下划线）
- 管理器：`功能_manager.gd`
- 系统脚本：`功能_system.gd`

### 资源文件命名
- 配置资源：`配置名称.tres`
- 纹理资源：`描述性名称.png/jpg`
- 音频资源：`描述性名称.ogg/wav`

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
1. 在 `scenes/levels/` 创建 `level{数字}.tscn`
2. 在 `scripts/levels/` 创建对应脚本（如需要）
3. 更新 `resources/level_config.tres`
4. 更新 `docs/design/level_index.md`

### 添加新功能模块
1. 在对应目录创建场景和脚本文件
2. 遵循现有的命名规范
3. 更新相关文档
4. 考虑与现有系统的集成

### 重构建议
- 保持目录结构的一致性
- 及时更新文档
- 考虑向后兼容性
- 进行充分的测试

---

**注意事项：**
- 本文档需要随项目结构变化及时更新
- 新加入的开发者应首先阅读本文档
- 如有结构调整建议，请通过项目Issues提出
# 存档系统设计文档

## 概述

存档系统为游戏提供完整的进度保存和加载功能，支持多存档槽位、自动保存、手动保存等特性。

## 系统架构

### 核心组件

```
存档系统
├── SaveData (存档数据类)
│   ├── 玩家进度数据
│   ├── 技能数据
│   ├── 游戏设置
│   └── 统计数据
├── SaveManager (存档管理器)
│   ├── 保存/加载逻辑
│   ├── 自动保存系统
│   └── 存档槽位管理
└── UI组件
    ├── SaveScreen (存档界面)
    ├── SaveSlot (存档槽位组件)
    └── PauseMenu (暂停菜单)
```

## 存档数据结构 (SaveData)

### 元数据
```gdscript
save_slot: int          # 存档槽位 (0-2)
save_name: String       # 存档名称
save_timestamp: int     # 存档时间戳
play_time: float        # 游戏时长（秒）
save_version: String    # 存档版本
```

### 玩家进度
```gdscript
current_level: int          # 当前关卡
max_unlocked_level: int     # 最大已解锁关卡
completed_levels: Dictionary # 已完成关卡
```

### 玩家资源
```gdscript
total_coins: int        # 总金币数
current_health: int     # 当前血量
```

### 技能数据
```gdscript
unlocked_skills: Array[String]  # 已解锁技能列表
skill_levels: Dictionary        # 技能等级
```

### 游戏设置
```gdscript
music_volume: float     # 音乐音量
sfx_volume: float       # 音效音量
```

### 统计数据
```gdscript
total_deaths: int           # 总死亡次数
total_kills: int            # 总击杀次数
total_coins_collected: int  # 总收集金币数
```

## SaveManager API

### 核心方法

```gdscript
# 保存游戏到指定槽位
func save_game(slot: int = -1) -> bool

# 加载指定槽位的存档
func load_game(slot: int) -> bool

# 删除指定槽位的存档
func delete_save(slot: int) -> bool

# 创建新存档
func create_new_save(slot: int) -> bool
```

### 查询方法

```gdscript
# 检查指定槽位是否有存档
func has_save(slot: int) -> bool

# 获取指定槽位的存档信息
func get_save_info(slot: int) -> SaveData

# 获取所有存档槽位信息
func get_all_save_info() -> Array[SaveData]

# 获取当前存档
func get_current_save() -> SaveData

# 获取当前槽位
func get_current_slot() -> int
```

### 自动保存

```gdscript
# 启用/禁用自动保存
func set_auto_save_enabled(enabled: bool) -> void

# 手动触发自动保存
func trigger_auto_save() -> void
```

### 信号

```gdscript
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)
signal auto_save_triggered()
```

## 存档文件格式

存档文件使用 JSON 格式存储在 `user://saves/` 目录下：

```
user://saves/
├── save_slot_0.json
├── save_slot_1.json
└── save_slot_2.json
```

### JSON 结构示例

```json
{
    "save_slot": 0,
    "save_name": "存档 1",
    "save_timestamp": 1701234567,
    "play_time": 3600.5,
    "save_version": "1.0",
    "current_level": 3,
    "max_unlocked_level": 4,
    "completed_levels": {"1": true, "2": true},
    "total_coins": 150,
    "current_health": 80,
    "unlocked_skills": ["dash", "wall_jump"],
    "skill_levels": {"dash": 2, "wall_jump": 1},
    "music_volume": 0.8,
    "sfx_volume": 1.0,
    "total_deaths": 5,
    "total_kills": 42,
    "total_coins_collected": 200
}
```

## 使用指南

### 保存游戏

```gdscript
# 手动保存到当前槽位
SaveManager.save_game()

# 保存到指定槽位
SaveManager.save_game(0)  # 保存到槽位0
```

### 加载游戏

```gdscript
# 加载指定槽位的存档
if SaveManager.load_game(0):
    print("存档加载成功")
else:
    print("存档加载失败")
```

### 检查存档

```gdscript
# 检查是否有存档
if SaveManager.has_save(0):
    var save_info = SaveManager.get_save_info(0)
    print("关卡: %d, 金币: %d" % [save_info.current_level, save_info.total_coins])
```

### 监听存档事件

```gdscript
func _ready():
    SaveManager.save_completed.connect(_on_save_completed)
    SaveManager.load_completed.connect(_on_load_completed)

func _on_save_completed(slot: int, success: bool):
    if success:
        print("存档 %d 保存成功" % slot)

func _on_load_completed(slot: int, success: bool):
    if success:
        print("存档 %d 加载成功" % slot)
```

## 自动保存触发点

系统在以下位置自动触发保存：

1. **定时自动保存** - 每60秒自动保存一次
2. **通过传送门** - 进入传送门前保存
3. **玩家死亡** - 死亡时保存（保留死亡前的进度）
4. **退出游戏** - 退出前自动保存

## UI 组件

### 存档界面 (SaveScreen)

- 位置：`scenes/ui/save_screen.tscn`
- 功能：显示所有存档槽位，提供加载、删除、新建存档功能

### 存档槽位组件 (SaveSlot)

- 位置：`scenes/ui/save_slot.tscn`
- 功能：显示单个存档的信息和操作按钮

### 暂停菜单 (PauseMenu)

- 位置：`scenes/ui/pause_menu.tscn`
- 功能：游戏暂停时显示，提供保存、返回主菜单等功能
- 触发：按 ESC 键

## 集成方式

### 在关卡中添加暂停菜单

```gdscript
# 在关卡场景中添加暂停菜单
var pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
add_child(pause_menu)
```

### 在主菜单中打开存档界面

```gdscript
# 切换到存档界面
get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")
```

## 注意事项

1. **存档版本兼容** - 加载存档时会检查版本，确保兼容性
2. **数据验证** - 加载存档前会验证数据完整性
3. **错误处理** - 所有操作都有完善的错误处理和日志输出
4. **自动保存间隔** - 默认60秒，可通过 `AUTO_SAVE_INTERVAL` 常量调整

## 文件列表

| 文件 | 描述 |
|------|------|
| `scripts/systems/save_data.gd` | 存档数据类 |
| `scripts/managers/save_manager.gd` | 存档管理器 |
| `scripts/ui/save_screen.gd` | 存档界面脚本 |
| `scripts/ui/save_slot_ui.gd` | 存档槽位组件脚本 |
| `scripts/ui/pause_menu.gd` | 暂停菜单脚本 |
| `scenes/ui/save_screen.tscn` | 存档界面场景 |
| `scenes/ui/save_slot.tscn` | 存档槽位场景 |
| `scenes/ui/pause_menu.tscn` | 暂停菜单场景 |

---

**文档版本**: v1.0  
**最后更新**: 2024年12月  
**维护者**: FyGame 开发团队

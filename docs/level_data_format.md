# 关卡数据格式文档

本文档描述了数据驱动关卡生成系统的 JSON 配置文件格式规范。

## 概述

关卡数据文件使用 JSON 格式存储关卡中所有实体的位置、属性和配置。这些数据由 `LevelGenerator` 系统读取并动态生成关卡场景。

## 文件位置

所有关卡数据文件存储在：`res://resources/level_data/`

命名约定：`lv{level_id}_data.json`（例如：`lv1_data.json`、`lv2_data.json`）

## JSON 格式规范

### 顶层字段

| 字段 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `level_id` | Integer | 是 | 关卡ID，用于关卡识别 |
| `level_name` | String | 是 | 关卡名称（中文） |
| `theme` | String | 否 | 关卡主题（如"新手教程"、"进阶挑战"） |
| `difficulty` | String | 否 | 难度等级（如"简单"、"中等"、"困难"） |
| `player` | Object | 是 | 玩家配置 |
| `camera` | Object | 是 | 相机配置 |
| `killzone` | Object | 是 | 死亡区域配置 |
| `coins` | Array | 否 | 金币数组 |
| `platforms` | Array | 否 | 平台数组 |
| `enemies` | Array | 否 | 敌人数组 |
| `portal` | Object | 否 | 传送门配置 |
| `tilemap_scene` | String | 否 | TileMap场景路径（引用） |

### player 对象

玩家初始配置。

```json
{
  "position": [x, y]  // 玩家初始位置（Vector2）
}
```

**示例：**
```json
"player": {
  "position": [0, 0]
}
```

### camera 对象

相机配置，包括位置、缩放和边界限制。

```json
{
  "position": [x, y],      // 相机位置（Vector2）
  "zoom": [x, y],          // 相机缩放（Vector2）
  "limit_left": number,    // 左边界限制
  "limit_bottom": number,  // 下边界限制
  "smooth": boolean        // 是否启用平滑移动
}
```

**示例：**
```json
"camera": {
  "position": [0, -6],
  "zoom": [4, 4],
  "limit_left": -200,
  "limit_bottom": 120,
  "smooth": true
}
```

### killzone 对象

死亡区域配置（玩家掉落后会死亡的高度）。

```json
{
  "y_position": number  // Y轴位置（高度）
}
```

**示例：**
```json
"killzone": {
  "y_position": 600
}
```

### coins 数组

金币列表，每个金币只需要指定位置。

```json
[
  { "position": [x, y] },
  { "position": [x, y] }
]
```

**示例：**
```json
"coins": [
  { "position": [223, -28] },
  { "position": [301, -30] },
  { "position": [217, -109] }
]
```

### platforms 数组

平台列表，支持静态平台和移动平台。

#### 静态平台

```json
{
  "position": [x, y],
  "is_moving": false
}
```

#### 移动平台

```json
{
  "position": [x, y],           // 平台起始位置
  "is_moving": true,            // 标记为移动平台
  "move_target": [x, y],        // 移动目标位置（绝对坐标）
  "move_duration": number,      // 移动持续时间（秒）
  "loop_mode": "pingpong"       // 循环模式："pingpong" 或 "linear"
}
```

**示例：**
```json
"platforms": [
  { "position": [-137, -90], "is_moving": false },
  {
    "position": [-28, -90],
    "is_moving": true,
    "move_target": [12, -90],
    "move_duration": 1.3,
    "loop_mode": "pingpong"
  }
]
```

### enemies 数组

敌人列表，每个敌人需要指定类型和位置。

```json
[
  {
    "type": "slime",        // 敌人类型（对应场景缓存中的key）
    "position": [x, y]      // 敌人位置
  }
]
```

**当前支持的敌人类型：**
- `slime` - 史莱姆敌人

**示例：**
```json
"enemies": [
  { "type": "slime", "position": [168, -12] },
  { "type": "slime", "position": [520, -91] },
  { "type": "slime", "position": [664, -75] }
]
```

### portal 对象

传送门配置，用于场景切换。

```json
{
  "position": [x, y],                          // 传送门位置
  "destination_scene": "res://path/to/scene"   // 目标场景路径
}
```

**示例：**
```json
"portal": {
  "position": [1513, -87],
  "destination_scene": "res://scenes/levels/lv3.tscn"
}
```

### tilemap_scene 字段

TileMap 场景路径引用。由于 TileMap 的 tile 数据是二进制编码的 `PackedByteArray`，无法用 JSON 表达，因此通过引用现有场景文件的方式处理。

```json
"tilemap_scene": "res://scenes/levels/lv2.tscn"
```

系统会从该场景中提取 TileMap 节点并添加到生成的关卡中。

## 完整示例

```json
{
  "level_id": 2,
  "level_name": "关卡2",
  "theme": "进阶挑战",
  "difficulty": "中等",
  "player": {
    "position": [0, 0]
  },
  "camera": {
    "position": [0, -6],
    "zoom": [4, 4],
    "limit_left": -200,
    "limit_bottom": 120,
    "smooth": true
  },
  "killzone": {
    "y_position": 600
  },
  "coins": [
    { "position": [223, -28] },
    { "position": [301, -30] },
    { "position": [217, -109] }
  ],
  "platforms": [
    { "position": [-137, -90], "is_moving": false },
    {
      "position": [-28, -90],
      "is_moving": true,
      "move_target": [12, -90],
      "move_duration": 1.3,
      "loop_mode": "pingpong"
    }
  ],
  "enemies": [
    { "type": "slime", "position": [168, -12] },
    { "type": "slime", "position": [520, -91] }
  ],
  "portal": {
    "position": [1513, -87],
    "destination_scene": "res://scenes/levels/lv3.tscn"
  },
  "tilemap_scene": "res://scenes/levels/lv2.tscn"
}
```

## 如何创建新关卡

### 方法1：从头创建

1. 在 `res://resources/level_data/` 目录下创建新文件，如 `lv5_data.json`
2. 复制上述完整示例作为模板
3. 修改 `level_id`、`level_name` 等基础信息
4. 根据关卡设计调整各实体的位置
5. 使用 `LevelLoader` 加载：

```gdscript
var loader = LevelLoader.new()
var level = loader.load_level_from_data(5)
```

### 方法2：从现有场景提取

如果已经在 Godot 编辑器中设计了关卡：

1. 打开 `.tscn` 文件
2. 查看各节点的 `position` 属性
3. 将这些位置数据转换为 JSON 格式
4. 保存为新的 JSON 数据文件

### 方法3：程序化生成

可以编写脚本动态生成 JSON 数据：

```gdscript
var level_data = {
    "level_id": 10,
    "level_name": "程序化关卡",
    "player": {"position": [0, 0]},
    "coins": []
}

# 程序化添加金币
for i in range(10):
    level_data["coins"].append({
        "position": [i * 100, -50]
    })

# 生成关卡
var generator = LevelGenerator.new()
var level = generator.generate_level(level_data)
```

## TileMap 数据处理说明

### 为什么 TileMap 不能完全用 JSON 表示？

Godot 的 TileMap 使用 `PackedByteArray` 存储 tile 数据，这是一个高效的二进制格式。将其转换为 JSON 会：
- 显著增加文件大小
- 降低加载性能
- 失去编辑器的可视化编辑能力

### 当前方案

通过 `tilemap_scene` 字段引用包含 TileMap 的 `.tscn` 场景文件：

1. 在 Godot 编辑器中创建和编辑 TileMap
2. 保存为独立场景（如 `lv2_tilemap.tscn`）或作为完整关卡的一部分
3. 在 JSON 中引用该场景路径
4. `LevelGenerator` 会从场景中提取 TileMap 节点

### 未来改进

可能的优化方向：
- 支持更细粒度的 TileMap 数据导出（如果需要）
- 创建独立的 TileMap 场景文件供复用
- 支持程序化生成的 TileMap 模式

## 最佳实践

1. **保持一致性**：所有关卡使用相同的结构和命名约定
2. **版本控制友好**：JSON 格式便于查看 diff 和进行版本控制
3. **渐进式迁移**：现有 `.tscn` 关卡可以保持不变，新关卡使用 JSON
4. **测试驱动**：创建关卡后立即测试以验证数据正确性
5. **文档更新**：如果添加新的实体类型，及时更新本文档

## 工具和工作流

### 使用 LevelGenerator

```gdscript
# 直接从文件加载
var generator = LevelGenerator.new()
var level = generator.generate_level_from_file("res://resources/level_data/lv2_data.json")
get_tree().root.add_child(level)
```

### 使用 LevelLoader

```gdscript
# 通过关卡ID加载
var loader = LevelLoader.new()
var level = loader.load_level_from_data(2)
get_tree().root.add_child(level)

# 从自定义路径加载
var custom_level = loader.load_level_from_path("res://custom_levels/special.json")
```

## 故障排查

### JSON 解析失败

- 检查 JSON 语法（逗号、括号、引号）
- 使用 JSON 验证器（如 jsonlint.com）
- 查看控制台错误消息，会显示行号

### 实体未生成

- 确认场景缓存中存在对应的实体类型
- 检查 position 数组格式 `[x, y]`
- 确认场景路径正确且文件存在

### 移动平台不工作

- 确认 `is_moving: true`
- 检查 `move_target` 是绝对坐标而非相对偏移
- 验证 `move_duration` 大于 0

### TileMap 未加载

- 确认 `tilemap_scene` 路径存在
- 确认目标场景中包含 TileMap 节点
- 检查控制台警告信息

## 扩展性

系统设计支持以下扩展：

1. **新实体类型**：在 `_preload_scenes()` 中添加新场景缓存
2. **自定义属性**：在对应的 `_create_*()` 方法中处理新字段
3. **复杂动画**：扩展 `_setup_moving_platform()` 支持更多动画类型
4. **关卡事件**：添加 `events` 数组支持脚本触发的事件

## 相关文件

- 生成器脚本：`scripts/systems/level_generator.gd`
- 加载器脚本：`scripts/systems/level_loader.gd`
- 示例数据：`resources/level_data/lv1_data.json`、`lv2_data.json`
- 关卡配置：`scripts/systems/level_config.gd`、`resources/level_config.tres`

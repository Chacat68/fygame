# 检查点系统 (Checkpoint System)

**版本**: v1.1  
**最后更新**: 2026年2月

## 概述

检查点系统为玩家提供了在关卡中保存进度的方式。当玩家激活检查点后死亡，会在最近激活的检查点位置重生，而不是重新开始整个关卡。

## 核心组件

### 1. CheckpointManager (单例)

**路径**: `scripts/managers/checkpoint_manager.gd`

检查点管理器是一个 AutoLoad 单例，负责管理所有检查点的注册、激活状态和重生逻辑。

#### 主要属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `checkpoints` | Dictionary | 存储所有已注册的检查点 |
| `active_checkpoint_id` | String | 当前激活的检查点ID |
| `initial_spawn_position` | Vector2 | 关卡初始出生点位置 |
| `current_level` | String | 当前关卡标识 |

#### 主要方法

```gdscript
# 注册检查点
func register_checkpoint(checkpoint: Node) -> void

# 激活检查点
func activate_checkpoint(checkpoint_id: String) -> void

# 获取重生位置
func get_respawn_position() -> Vector2

# 检查是否有激活的检查点
func has_checkpoint() -> bool

# 重生玩家
func respawn_player(player: Node) -> void

# 设置初始出生点
func set_initial_spawn_position(pos: Vector2) -> void

# 重置所有检查点
func reset_all_checkpoints() -> void
```

#### 信号

```gdscript
signal checkpoint_activated(checkpoint_id: String)  # 检查点被激活时
signal player_respawned(position: Vector2)          # 玩家重生时
```

### 2. Checkpoint (实体)

**路径**: `scripts/entities/checkpoint.gd`  
**场景**: `scenes/entities/checkpoint.tscn`

检查点实体是放置在关卡中的可交互对象，玩家碰触后可以激活。

#### 导出属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `checkpoint_id` | String | "" | 检查点唯一标识（自动生成） |
| `checkpoint_order` | int | 0 | 检查点顺序（用于排序） |
| `spawn_offset` | Vector2 | (0, -16) | 重生位置偏移 |
| `auto_activate` | bool | false | 是否自动激活（用于关卡起点） |

#### 主要方法

```gdscript
# 激活检查点
func activate() -> void

# 获取重生位置
func get_spawn_position() -> Vector2

# 重置检查点状态
func reset() -> void
```

#### 信号

```gdscript
signal activated(checkpoint: Node)  # 检查点被激活时
```

## 使用方法

### 1. 在关卡中放置检查点

1. 将 `checkpoint.tscn` 场景实例化到关卡中
2. 设置检查点的位置
3. 配置 `checkpoint_order` 属性（可选，用于排序显示）
4. 设置 `spawn_offset` 调整重生位置偏移

### 2. 关卡起点设置

对于关卡起点的检查点，可以设置 `auto_activate = true`，玩家进入关卡时会自动激活。

### 3. 自定义检查点外观

检查点场景包含以下节点，可以自定义：

- `AnimatedSprite2D`: 检查点动画
  - `inactive`: 未激活状态动画
  - `active`: 激活状态动画
- `FlagSprite`: 旗帜精灵
- `ActivationParticles`: 激活粒子效果
- `Label`: 显示标签（可选）

### 4. 与存档系统集成

检查点数据会自动与 SaveManager 集成：

```gdscript
# 保存检查点数据
func get_save_data() -> Dictionary:
    return {
        "active_checkpoint_id": active_checkpoint_id,
        "current_level": current_level
    }

# 加载检查点数据
func load_save_data(data: Dictionary) -> void:
    if data.has("active_checkpoint_id"):
        active_checkpoint_id = data["active_checkpoint_id"]
    if data.has("current_level"):
        current_level = data["current_level"]
```

## 重生流程

1. 玩家死亡 → `DeathState` 处理
2. 死亡动画播放完毕（1.5秒）
3. 检查 `CheckpointManager.has_checkpoint()`
4. **有检查点**: 在检查点位置重生
   - 获取重生位置
   - 重置玩家状态
   - 播放重生效果
   - 切换到 Idle 状态
5. **无检查点**: 重新加载整个场景

## 代码示例

### 创建自定义检查点

```gdscript
extends Checkpoint

# 特殊检查点：恢复玩家生命值
func activate() -> void:
    super.activate()
    
    # 获取玩家并恢复生命
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.current_health = player.MAX_HEALTH
        player.health_changed.emit(player.current_health)
```

### 监听检查点事件

```gdscript
func _ready():
    CheckpointManager.checkpoint_activated.connect(_on_checkpoint_activated)
    CheckpointManager.player_respawned.connect(_on_player_respawned)

func _on_checkpoint_activated(checkpoint_id: String):
    print("检查点激活: ", checkpoint_id)
    # 显示提示UI等

func _on_player_respawned(position: Vector2):
    print("玩家重生在: ", position)
    # 播放重生音效等
```

## 最佳实践

1. **合理间距**: 检查点之间保持适当距离，避免过于密集或稀疏
2. **安全位置**: 确保检查点位置是安全的，玩家重生后不会立即死亡
3. **视觉反馈**: 使用粒子效果和动画让玩家清楚知道检查点已激活
4. **顺序设置**: 使用 `checkpoint_order` 确保检查点按正确顺序排列
5. **存档集成**: 重要关卡点建议触发自动保存

## 相关文件

- [checkpoint_manager.gd](scripts/managers/checkpoint_manager.gd) - 检查点管理器
- [checkpoint.gd](scripts/entities/checkpoint.gd) - 检查点实体脚本
- [checkpoint.tscn](scenes/entities/checkpoint.tscn) - 检查点场景
- [death_state.gd](scripts/entities/player/player_states/death_state.gd) - 死亡状态（处理重生）
- [player.gd](scripts/entities/player/player.gd) - 玩家脚本（记录初始位置）

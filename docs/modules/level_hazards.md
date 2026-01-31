# 关卡机关系统设计文档

## 概述

本模块实现了一套参考《死亡细胞》(Dead Cells) 风格的关卡机关系统，为游戏增添了丰富的交互元素和挑战性。

## 系统架构

```
关卡机关系统
├── HazardBase (机关基类)
│   ├── Spikes (尖刺陷阱)
│   ├── SawBlade (旋转锯片)
│   ├── LaserBeam (激光束)
│   └── ...
├── Springboard (弹簧跳板)
├── CrumblingPlatform (破碎平台)
├── AdvancedMovingPlatform (高级移动平台)
├── InteractiveDoor (互动门)
└── PressureSwitch (压力开关)
```

## 机关类型详解

### 1. 尖刺陷阱 (Spikes)

**文件位置**: `scripts/entities/hazards/spikes.gd`

**类型**:
| 类型 | 说明 |
|------|------|
| `STATIC` | 静态尖刺，始终存在 |
| `PERIODIC` | 周期性弹出，带警告 |
| `TRIGGERED` | 触发式，由外部事件激活 |

**方向**: 支持上、下、左、右四个方向

**关键属性**:
```gdscript
@export var spike_type: SpikeType = SpikeType.STATIC
@export var spike_direction: SpikeDirection = SpikeDirection.UP
@export var extend_time: float = 1.0      # 伸出持续时间
@export var retract_time: float = 1.0     # 收回持续时间
@export var warning_time: float = 0.3     # 警告时间
```

**使用示例**:
```gdscript
# 创建周期性尖刺
var spikes = preload("res://scenes/entities/hazards/spikes.tscn").instantiate()
spikes.spike_type = Spikes.SpikeType.PERIODIC
spikes.extend_time = 2.0
spikes.retract_time = 1.0
add_child(spikes)
```

---

### 2. 旋转锯片 (SawBlade)

**文件位置**: `scripts/entities/hazards/saw_blade.gd`

**类型**:
| 类型 | 说明 |
|------|------|
| `STATIONARY` | 原地旋转 |
| `LINEAR` | 线性往返移动 |
| `CIRCULAR` | 圆形路径移动 |
| `PATH` | 沿 Path2D 移动 |

**关键属性**:
```gdscript
@export var saw_type: SawType = SawType.STATIONARY
@export var rotation_speed: float = 360.0     # 旋转速度
@export var move_speed: float = 100.0         # 移动速度
@export var move_distance: float = 100.0      # 移动距离
@export var path_node: NodePath               # Path2D 路径
```

**特效**:
- 旋转动画
- 接触时产生火花粒子
- 可选拖尾效果

---

### 3. 激光束 (LaserBeam)

**文件位置**: `scripts/entities/hazards/laser_beam.gd`

**类型**:
| 类型 | 说明 |
|------|------|
| `CONTINUOUS` | 持续激光 |
| `PULSING` | 脉冲激光（开关周期）|
| `ROTATING` | 旋转激光 |
| `TRIGGERED` | 触发式激光 |

**关键属性**:
```gdscript
@export var laser_type: LaserType = LaserType.CONTINUOUS
@export var laser_length: float = 200.0
@export var on_duration: float = 2.0          # 激活时间
@export var off_duration: float = 1.0         # 关闭时间
@export var rotation_speed: float = 45.0      # 旋转速度
@export var rotation_range: float = 180.0     # 旋转范围
```

**特效**:
- 脉冲模式下的警告闪烁
- 激光遇到障碍物自动截断
- 可自定义颜色

---

### 4. 弹簧跳板 (Springboard)

**文件位置**: `scripts/entities/hazards/springboard.gd`

**方向**: 支持上、下、左、右和自定义角度

**关键属性**:
```gdscript
@export var spring_direction: SpringDirection = SpringDirection.UP
@export var bounce_force: float = 600.0       # 弹跳力度
@export var custom_angle: float = 0.0         # 自定义角度
@export var override_player_velocity: bool = true
```

**特效**:
- 压缩-弹起动画
- 音效反馈
- 重置玩家跳跃次数

---

### 5. 破碎平台 (CrumblingPlatform)

**文件位置**: `scripts/entities/hazards/crumbling_platform.gd`

**状态流程**:
```
STABLE → CRUMBLING → FALLING → COLLAPSED → (重生) → STABLE
```

**关键属性**:
```gdscript
@export var crumble_delay: float = 0.5        # 崩塌延迟
@export var fall_speed: float = 200.0         # 下落速度
@export var respawn_time: float = 3.0         # 重生时间（0=不重生）
@export var shake_before_fall: bool = true    # 下落前震动
```

**特效**:
- 踩上后震动警告
- 下落时产生碎片粒子
- 重生时淡入效果

---

### 6. 高级移动平台 (AdvancedMovingPlatform)

**文件位置**: `scripts/entities/hazards/advanced_moving_platform.gd`

**移动模式**:
| 模式 | 说明 |
|------|------|
| `LINEAR` | 线性往返 |
| `CIRCULAR` | 圆形运动 |
| `PATH` | 沿路径移动 |
| `ELEVATOR` | 电梯模式（需触发）|
| `CONVEYOR` | 传送带（推动玩家）|

**关键属性**:
```gdscript
@export var move_mode: MoveMode = MoveMode.LINEAR
@export var move_speed: float = 50.0
@export var move_distance: float = 100.0
@export var conveyor_force: float = 100.0     # 传送带推力
@export var require_player: bool = true       # 电梯需要玩家
```

---

### 7. 互动门 (InteractiveDoor)

**文件位置**: `scripts/entities/hazards/interactive_door.gd`

**门类型**:
| 类型 | 说明 |
|------|------|
| `ONE_WAY` | 单向门 |
| `SWITCH` | 开关门 |
| `KEY` | 钥匙门 |
| `TIMED` | 限时门 |
| `KILL_ALL` | 清怪门 |

**关键属性**:
```gdscript
@export var door_type: DoorType = DoorType.SWITCH
@export var door_id: String = ""              # 用于开关链接
@export var open_duration: float = 3.0        # 限时门开启时间
@export var required_key_id: String = ""      # 钥匙门所需钥匙
```

---

### 8. 压力开关 (PressureSwitch)

**文件位置**: `scripts/entities/hazards/pressure_switch.gd`

**关键属性**:
```gdscript
@export var switch_id: String = ""
@export var stay_activated: bool = false      # 保持激活
@export var require_weight: bool = false      # 需要重物
@export var linked_door_ids: Array[String]    # 链接的门
```

**使用方式**:
1. 在场景中放置开关
2. 设置 `linked_door_ids` 为目标门的 `door_id`
3. 玩家踩上开关时，链接的门会切换状态

---

## 组合使用示例

### 示例 1：开关控制门
```
PressureSwitch (switch_id: "sw1", linked_door_ids: ["door1"])
    ↓ 踩下
InteractiveDoor (door_id: "door1", door_type: SWITCH)
    ↓ 打开
玩家通过
```

### 示例 2：清怪房间
```
InteractiveDoor (door_type: KILL_ALL) ← 入口关闭
    ↓
敌人 x N
    ↓ 全部消灭
InteractiveDoor 自动打开
```

### 示例 3：计时挑战
```
Springboard → 玩家弹起
    ↓
CrumblingPlatform x 3 → 连续跳跃
    ↓
InteractiveDoor (door_type: TIMED, open_duration: 5.0)
    ↓ 必须在5秒内到达
终点
```

---

## 信号参考

### HazardBase
```gdscript
signal player_damaged(damage: int)
signal hazard_triggered
```

### Springboard
```gdscript
signal player_bounced(player: Node2D)
```

### CrumblingPlatform
```gdscript
signal platform_crumbling
signal platform_collapsed
signal platform_restored
```

### InteractiveDoor
```gdscript
signal door_opened
signal door_closed
signal door_state_changed(new_state: DoorState)
```

### PressureSwitch
```gdscript
signal activated
signal deactivated
signal toggled(is_on: bool)
```

---

## 测试场景

测试场景位于: `scenes/test/hazard_test_level.tscn`

包含所有机关类型的展示和测试。

---

## 扩展指南

### 创建新机关

1. 继承 `HazardBase` 类：
```gdscript
class_name MyCustomHazard
extends HazardBase

func _hazard_ready() -> void:
    # 初始化代码
    pass

func _on_activated() -> void:
    # 激活时的行为
    pass
```

2. 创建对应的场景文件 (.tscn)
3. 添加必要的碰撞形状和视觉组件

### 最佳实践

1. **性能优化**: 使用对象池管理频繁创建/销毁的机关
2. **视觉反馈**: 所有危险机关都应有明显的视觉警告
3. **音效配合**: 为关键动作添加音效增强反馈
4. **难度平衡**: 通过调整参数控制难度，而非修改核心逻辑

---

## 文件清单

```
scripts/entities/hazards/
├── hazard_base.gd              # 机关基类
├── spikes.gd                   # 尖刺陷阱
├── saw_blade.gd                # 旋转锯片
├── laser_beam.gd               # 激光束
├── springboard.gd              # 弹簧跳板
├── crumbling_platform.gd       # 破碎平台
├── advanced_moving_platform.gd # 高级移动平台
├── interactive_door.gd         # 互动门
└── pressure_switch.gd          # 压力开关

scenes/test/
└── hazard_test_level.tscn      # 测试场景
```

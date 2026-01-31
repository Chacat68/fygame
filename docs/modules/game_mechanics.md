# 游戏机制文档

本文档详细描述了游戏中的所有核心机制和系统，为开发和设计提供参考。

## 目录

1. [玩家系统](#玩家系统)
2. [敌人系统](#敌人系统)
3. [关卡系统](#关卡系统)
4. [游戏状态管理](#游戏状态管理)
5. [资源管理系统](#资源管理系统)
6. [UI系统](#ui系统)
7. [物理与碰撞系统](#物理与碰撞系统)

## 玩家系统

### 基本属性

基于GameConfig配置系统，所有数值可通过配置文件调整：

- **移动速度**：180.0（可配置：player_speed）
- **跳跃速度**：-280.0（可配置：player_jump_velocity）
- **重力加速度**：800.0（可配置：player_gravity）
- **最大跳跃次数**：2（可配置：player_max_jumps，支持双跳能力）
- **最大生命值**：100（可配置：player_max_health）
- **受伤伤害值**：10（可配置：player_damage_amount）
- **无敌时间**：1.0秒（可配置：player_invincibility_time）

### 状态机系统

玩家使用状态机模式管理不同状态下的行为。所有状态继承自基础`PlayerState`类，实现以下方法：

- `enter()`：进入状态时调用
- `exit()`：退出状态时调用
- `physics_process(delta)`：处理物理更新
- `handle_input()`：处理输入
- `update_animation()`：更新动画

#### 玩家状态

1. **Idle状态**：玩家静止不动时的状态
2. **Run状态**：玩家水平移动时的状态
3. **Jump状态**：玩家跳跃上升时的状态
4. **Fall状态**：玩家下落时的状态
5. **Hurt状态**：玩家受伤时的状态
6. **Death状态**：玩家死亡时的状态

### 玩家输入处理

- 左右方向键：水平移动
- 空格键/上方向键：跳跃
- 双击跳跃键：二段跳

### 玩家复活机制

当玩家死亡后，游戏状态会设置`player_respawning`标志，在玩家重新生成时应用复活效果。

## 敌人系统

### 史莱姆敌人

#### 基本属性

基于GameConfig配置系统，支持以下可配置属性：

- **巡逻速度**：50.0（可配置：slime_speed）
- **追击速度**：80.0（可配置：slime_chase_speed）
- **巡逻距离**：100.0（可配置：slime_patrol_distance）
- **攻击范围**：30.0（可配置：slime_attack_range）
- **生命值**：1（可配置：slime_health）
- **伤害值**：碰撞时对玩家造成伤害

#### 状态系统

史莱姆敌人实现了完整的状态机系统：
- **IDLE**：待机状态
- **PATROL**：巡逻状态，在指定范围内来回移动
- **CHASE**：追击状态，发现玩家后进行追击
- **ATTACK**：攻击状态
- **HURT**：受伤状态
- **DEAD**：死亡状态

#### 行为模式

1. **巡逻行为**：
   - 在平台上左右移动
   - 使用射线检测避免掉落平台边缘
   - 碰到墙壁时改变方向

2. **碰撞检测**：
   - 使用`RayCast`检测前方障碍物和平台边缘
   - 使用`FloorCheck`射线检测平台边缘

#### 史莱姆类型

项目支持多种史莱姆类型的精灵资源：
- **绿色史莱姆**：基础敌人类型（slime_green.png）
- **紫色史莱姆**：高级敌人类型（slime_purple.png）

所有史莱姆共享相同的AI逻辑和配置参数，可通过不同的精灵资源实现视觉差异化。

## 关卡系统

### 关卡结构

每个关卡分为四个主要区域：

1. **入口区域**：简单的平台和少量敌人，作为教学区域
2. **中间区域**：增加难度，更多的跳跃挑战和敌人
3. **挑战区域**：高难度区域，复杂的平台布局和更多敌人
4. **宝藏区域**：关卡终点，包含大量奖励



## 游戏状态管理

### 全局游戏状态

- **player_respawning**：玩家是否正在复活
- **current_level**：当前关卡编号
- **max_unlocked_level**：最大已解锁关卡
- **total_coins**：玩家收集的总金币数
- **completed_levels**：已完成的关卡记录

### 游戏进度保存

游戏进度保存在`user://game_progress.json`文件中，包含以下信息：

- 当前关卡
- 最大已解锁关卡
- 总金币数
- 已完成关卡记录



## 资源管理系统
### 资源类型

`ResourceManager`作为AutoLoad单例，集中管理游戏中的所有资源预加载，避免在各个脚本中分散加载资源：

1. **音效资源**（sounds字典）：
   - `jump`：跳跃音效（jump.wav）
   - `hurt`：受伤音效（hurt.wav）
   - `coin`：金币音效（coin.wav）
   - `power_up`：能量提升音效（power_up.wav）
   - `explosion`：爆炸音效（explosion.wav）
   - `tap`：点击音效（tap.wav）

2. **音乐资源**（music字典）：
   - `adventure`：冒险背景音乐（time_for_adventure.mp3）

3. **精灵资源**（sprites字典）：
   - `knight`：骑士精灵（knight.png）
   - `coin`：金币精灵（coin.png）
   - `slime_green`：绿色史莱姆精灵（slime_green.png）
   - `slime_purple`：紫色史莱姆精灵（slime_purple.png）
   - `platforms`：平台精灵（platforms.png）
   - `world_tileset`：世界瓦片集（world_tileset.png）
   - `fruit`：水果精灵（fruit.png）
   - `coin_icon`：金币图标（coin_icon.png）

4. **场景资源**（scenes字典）：
   - `coin`：金币场景（coin.tscn）
   - `slime`：史莱姆场景（slime.tscn）
   - `platform`：平台场景（platform.tscn）
   - `floating_text`：浮动文本场景（floating_text.tscn）

### 资源访问方法

提供了便捷的资源获取方法：
- `get_sound(sound_name: String) -> AudioStream`
- `get_music(music_name: String) -> AudioStream`
- `get_sprite(sprite_name: String) -> Texture2D`
- `get_scene(scene_name: String) -> PackedScene`

**注意**：音频播放功能已迁移到专门的`AudioManager`系统，请使用以下方法：
- `AudioManager.play_sfx(sound_name: String, volume_db: float, pitch: float, priority: int) -> AudioStreamPlayer`
- `AudioManager.play_music(music_name: String, volume_db: float, loop: bool) -> AudioStreamPlayer`
- `AudioManager.play_music_with_fade_in(music_name: String, fade_duration: float) -> AudioStreamPlayer`

### 单例模式

资源管理器使用单例模式，确保全局只有一个实例：

- 通过`get_instance()`获取单例实例
- 通过`get_sound()`, `get_sprite()`, `get_scene()`等方法获取资源

## UI系统
### 游戏UI组件

基于实际实现的UI系统包含：

- **金币计数器**：显示收集的金币数量，包含金币图标和数量标签
- **击杀计数器**：显示击败的敌人数量
- **顶部状态栏**：包含金币和击杀计数器的容器
- **传送测试面板**：开发调试用的传送功能测试界面

### UI管理

`CoinCounter`脚本负责管理UI显示和状态更新：
- 集成了传送管理器功能
- 支持金币和击杀数量的实时更新
- 提供信号系统用于状态变化通知

### 浮动文本系统

基于GameConfig配置的浮动文本系统，用于显示动态信息：

**功能特性**：
- 伤害数值显示
- 得分提示（如"金币+1"）
- 状态变化提示
- 支持文本错开显示，避免重叠
- 可配置的动画参数

**配置参数**：
- `floating_text_speed`：浮动速度（默认50.0）
- `floating_text_fade_duration`：淡出持续时间（默认2.0秒）

**动画效果**：
- 向上浮动动画
- 渐变透明效果
- 水平偏移避免重叠
- 延迟显示支持

**使用方式**：
通过`FloatingTextManager`统一管理，场景资源通过`ResourceManager`获取。

### 菜单系统

- **主菜单**：游戏开始界面
- **关卡选择菜单**：多关卡模式下选择关卡
- **游戏开始界面**：单关卡模式的开始界面

## 物理与碰撞系统

### 重力系统

- 使用Godot的默认重力设置
- 在跳跃和下落状态中应用重力

### 碰撞检测

- **平台碰撞**：玩家与平台的碰撞
- **敌人碰撞**：玩家与敌人的碰撞
- **金币碰撞**：玩家与金币的碰撞
- **死亡区域**：超出地图边界的死亡区域

### 射线检测

- 用于敌人的边缘检测
- 用于玩家的地面检测

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本文档详细描述了游戏中的所有核心机制和系统。开发人员应参考此文档进行游戏功能的实现和扩展。如有任何更新或修改，请及时更新本文档。
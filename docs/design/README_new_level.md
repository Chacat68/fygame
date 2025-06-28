# 新关卡场景说明

## 概述

`new_level.tscn` 是基于原始 `game.tscn` 场景创建的新关卡，包含了相似的游戏元素但具有不同的布局和特性。

## 场景结构

### 主要节点

- **NewLevel** (Node2D) - 根节点，附加了 `new_level.gd` 脚本
- **GameManager** - 游戏管理器实例
- **UI** - 用户界面层
- **Player** - 玩家角色
- **LevelCamera** - 关卡摄像机
- **Killzone** - 死亡区域
- **TileMap** - 地形瓦片地图
- **Coins** - 金币容器节点
- **Platforms** - 平台容器节点
- **Enemies** - 敌人容器节点
- **Labels** - 标签容器节点

## 新特性

### 1. 改进的摄像机系统
- 使用 `LevelCamera` 替代 `GameCamera`
- 更好的缩放比例 (3x)
- 扩展的边界限制
- 平滑的玩家跟随

### 2. 动态平台
- 包含一个移动平台 `MovingPlatform`
- 使用 AnimationPlayer 实现水平移动动画
- 2秒循环周期

### 3. 优化的布局
- 重新设计的金币分布
- 对称的平台布局
- 战略性的敌人位置

### 4. 关卡管理脚本
- 自动跟踪金币收集进度
- 敌人击败计数
- 关卡完成检测
- 欢迎和完成消息显示

## 游戏元素位置

### 金币 (5个)
- Coin1: (-150, -80)
- Coin2: (-100, -80)
- Coin3: (100, -80)
- Coin4: (150, -80)
- Coin5: (0, -150) - 挑战位置

### 平台 (3个)
- Platform1: (-120, -50) - 静态
- Platform2: (120, -50) - 静态
- MovingPlatform: (-50, -120) 到 (50, -120) - 动态

### 敌人 (2个)
- Slime1: (-200, -20)
- Slime2: (200, -20)

## 脚本功能

### 主要方法

- `setup_level()` - 初始化关卡设置
- `connect_signals()` - 连接游戏事件信号
- `show_welcome_message()` - 显示欢迎信息
- `_on_coin_collected()` - 处理金币收集
- `_on_enemy_defeated()` - 处理敌人击败
- `restart_level()` - 重启关卡
- `get_level_progress()` - 获取进度信息

### 状态跟踪

- `coins_collected` - 已收集金币数
- `total_coins` - 总金币数
- `enemies_defeated` - 已击败敌人数
- `level_completed` - 关卡完成状态

## 使用方法

1. 在 Godot 编辑器中打开 `new_level.tscn`
2. 运行场景进行测试
3. 可以通过修改节点位置来调整关卡布局
4. 通过脚本可以添加更多自定义逻辑

## 扩展建议

- 添加更多动态平台
- 实现关卡间的传送门
- 增加收集品种类
- 添加背景音乐和音效
- 实现关卡评分系统
- 添加隐藏区域和秘密通道

## 技术细节

- 基于 Godot 4.x 格式
- 使用相同的资源引用确保兼容性
- 保持与原始游戏系统的一致性
- 模块化设计便于维护和扩展
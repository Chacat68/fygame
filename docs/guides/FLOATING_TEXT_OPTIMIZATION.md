# 金币飘字动画优化说明

## 优化概述

本次优化改进了游戏中金币收集时的文字弹出动画效果，实现了**一排往上飘**的视觉效果，提升了游戏的视觉体验。

## 主要改进

### 1. 新增飘字管理器 (FloatingTextManager)

- **文件位置**: `scripts/managers/floating_text_manager.gd`
- **功能**: 统一管理所有飘字的创建、排列和动画
- **特性**:
  - 单例模式，确保全局唯一管理器
  - 自动排列多个飘字成一排
  - 支持错开延迟动画效果
  - 自动清理已完成的飘字

### 2. 飘字排列算法

#### 水平排列
- **间距**: 40像素
- **居中对齐**: 自动计算起始位置使飘字居中排列
- **多排支持**: 超过5个飘字时自动换行

#### 时间错开
- **延迟间隔**: 0.1秒
- **效果**: 飘字依次出现，形成波浪式动画

### 3. 增强的飘字组件

#### 新增参数
- `horizontal_offset`: 水平偏移量
- `stagger_delay`: 错开延迟时间
- `is_delayed`: 延迟状态标记

#### 新增方法
- `set_arrangement(h_offset, delay)`: 设置排列参数
- `_start_animation()`: 延迟结束后开始动画

## 使用方式

### 创建排列飘字

```gdscript
# 获取飘字管理器实例
var text_manager = FloatingTextManager.get_instance()

# 创建排列的飘字效果
text_manager.create_arranged_floating_text(world_position, "金币+10", game_root)
```

### 配置参数

可以通过修改 `FloatingTextManager` 中的参数来调整效果：

```gdscript
# 排列参数
var horizontal_spacing = 40.0           # 水平间距
var stagger_delay_interval = 0.1        # 错开延迟间隔
var max_texts_per_row = 5               # 每排最大文字数量
```

## 更新的文件

1. **新增文件**:
   - `scripts/managers/floating_text_manager.gd` - 飘字管理器
   - `test_floating_text_optimization.gd` - 测试脚本

2. **修改文件**:
   - `scripts/systems/floating_text.gd` - 增加排列支持
- `scripts/entities/items/coin.gd` - 使用新管理器
- `scripts/entities/enemies/slime.gd` - 使用新管理器

## 视觉效果

### 优化前
- 每个金币独立创建飘字
- 飘字位置重叠或随机
- 同时出现，缺乏层次感

### 优化后
- 飘字自动排列成一排
- 依次出现，形成波浪效果
- 视觉层次丰富，更具吸引力

## 性能优化

- **自动清理**: 管理器自动清理已完成的飘字，避免内存泄漏
- **单例模式**: 减少重复创建管理器实例
- **延迟加载**: 只在需要时创建飘字实例

## 测试方法

1. 运行游戏
2. 收集多个金币
3. 观察飘字是否按一排往上飘的效果显示
4. 击杀史莱姆时观察击杀和金币飘字的排列效果

## 扩展性

该系统设计具有良好的扩展性，可以轻松添加：
- 不同类型的飘字效果
- 更复杂的排列模式
- 自定义动画曲线
- 音效同步
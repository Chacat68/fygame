# 音频系统使用指南

## 概述

游戏的音频系统已经从 `ResourceManager` 中分离出来，现在由专门的 `AudioManager` 负责管理。新的音频系统提供了更好的性能、更丰富的功能和更灵活的配置选项。

## 核心组件

### AudioManager
- **位置**: `scripts/managers/audio_manager.gd`
- **类型**: AutoLoad 单例
- **功能**: 统一管理游戏中的所有音频播放

## 主要特性

### 1. 对象池管理
- **音效播放器池**: 复用 AudioStreamPlayer 实例，减少内存分配
- **音乐播放器池**: 专门的音乐播放器管理
- **自动回收**: 播放完成后自动回收播放器到对象池

### 2. 性能优化
- **最大播放器限制**: 防止同时播放过多音频
- **优先级系统**: 高优先级音效可以替换低优先级音效
- **定期清理**: 自动清理不活跃的播放器

### 3. 音量控制
- **分离的音频总线**: SFX、Music、Master 独立控制
- **实时音量调节**: 支持运行时动态调整音量
- **淡入淡出**: 音乐支持平滑的淡入效果

### 4. 性能监控
- **实时统计**: 活跃播放器数量、对象池大小等
- **播放计数**: 总音效和音乐播放次数统计

## API 参考

### 音效播放

```gdscript
# 基本音效播放
var player = AudioManager.play_sfx("jump")

# 带参数的音效播放
var player = AudioManager.play_sfx("explosion", -5.0, 1.2, 5)
# 参数: 音效名称, 音量(dB), 音调, 优先级
```

### 音乐播放

```gdscript
# 播放背景音乐
var player = AudioManager.play_music("adventure")

# 带淡入效果的音乐播放
var player = AudioManager.play_music_with_fade_in("adventure", 2.0)
# 参数: 音乐名称, 淡入时长(秒)

# 检查音乐播放状态
if AudioManager.is_music_playing():
    print("音乐正在播放")
```

### 音频控制

```gdscript
# 停止所有音效
AudioManager.stop_all_sfx()

# 停止所有音乐
AudioManager.stop_all_music()

# 停止所有音频
AudioManager.stop_all_audio()
```

### 音量控制

```gdscript
# 设置音效音量
AudioManager.set_bus_volume(AudioManager.AudioBus.SFX, -10.0)

# 设置音乐音量
AudioManager.set_bus_volume(AudioManager.AudioBus.MUSIC, -15.0)

# 设置主音量
AudioManager.set_bus_volume(AudioManager.AudioBus.MASTER, -5.0)

# 获取当前音量
var sfx_volume = AudioManager.get_bus_volume(AudioManager.AudioBus.SFX)
```

### 性能监控

```gdscript
# 获取性能统计
var stats = AudioManager.get_performance_stats()
print("活跃音效播放器: ", stats.active_sfx_players)
print("音效池大小: ", stats.sfx_pool_size)
print("总音效播放次数: ", stats.total_sfx_played)
```

## 信号系统

AudioManager 提供以下信号用于监听音频事件：

```gdscript
# 连接音频事件信号
AudioManager.sfx_started.connect(_on_sfx_started)
AudioManager.sfx_finished.connect(_on_sfx_finished)
AudioManager.music_started.connect(_on_music_started)
AudioManager.music_finished.connect(_on_music_finished)

func _on_sfx_started(sound_name: String):
    print("音效开始播放: ", sound_name)

func _on_sfx_finished(sound_name: String):
    print("音效播放完成: ", sound_name)
```

## 配置参数

### 对象池设置
- `_max_sfx_players`: 最大音效播放器数量 (默认: 15)
- `_max_music_players`: 最大音乐播放器数量 (默认: 3)

### 清理设置
- `_cleanup_interval`: 清理间隔时间 (默认: 30秒)
- `_low_priority_threshold`: 低优先级阈值 (默认: 2)

## 迁移指南

### 从 ResourceManager 迁移

**旧代码**:
```gdscript
# 旧的音频播放方式
ResourceManager.play_sound("jump")
```

**新代码**:
```gdscript
# 新的音频播放方式
AudioManager.play_sfx("jump")
```

### 常见替换模式

| 旧方法 | 新方法 |
|--------|--------|
| `ResourceManager.play_sound(name)` | `AudioManager.play_sfx(name)` |
| `ResourceManager.play_sound(name, parent, volume)` | `AudioManager.play_sfx(name, volume)` |
| 手动音乐播放 | `AudioManager.play_music(name)` |

## 最佳实践

### 1. 音效使用
- 为重要音效设置较高优先级
- 避免同时播放过多相同音效
- 使用合适的音量级别

### 2. 音乐使用
- 使用淡入效果提升用户体验
- 在场景切换时停止当前音乐
- 合理设置音乐循环

### 3. 性能优化
- 定期检查性能统计
- 避免在短时间内播放大量音效
- 使用优先级系统管理音效播放

### 4. 调试技巧
- 使用性能统计监控音频系统状态
- 连接信号事件进行调试
- 检查对象池使用情况

## 示例代码

完整的使用示例请参考 `scripts/examples/audio_manager_example.gd` 文件。

## 故障排除

### 常见问题

1. **音效不播放**
   - 检查音效资源是否在 ResourceManager 中正确配置
   - 确认音效名称拼写正确
   - 检查音量设置是否过低

2. **音乐播放异常**
   - 确认音乐资源路径正确
   - 检查是否有其他音乐正在播放
   - 验证音频总线配置

3. **性能问题**
   - 检查活跃播放器数量是否过多
   - 调整最大播放器限制
   - 使用优先级系统优化播放

### 调试工具

```gdscript
# 打印当前音频系统状态
func debug_audio_system():
    var stats = AudioManager.get_performance_stats()
    print("=== 音频系统状态 ===")
    print("活跃音效播放器: ", stats.active_sfx_players)
    print("活跃音乐播放器: ", stats.active_music_players)
    print("音效池大小: ", stats.sfx_pool_size)
    print("音乐池大小: ", stats.music_pool_size)
    print("总音效播放: ", stats.total_sfx_played)
    print("总音乐播放: ", stats.total_music_played)
```

---

**文档版本**: v1.1  
**最后更新**: 2026年2月  
**维护者**: FyGame 开发团队

> 本指南涵盖了新音频系统的所有主要功能和使用方法。如有疑问或需要更多功能，请参考源代码或联系开发团队。
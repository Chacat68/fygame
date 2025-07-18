# 技能系统性能优化指南

## 概述

本文档提供了技能系统性能优化的指南和最佳实践，帮助开发者提高技能系统的性能和效率。虽然当前的技能系统已经相对高效，但随着游戏规模的增长和技能数量的增加，性能优化将变得越来越重要。

## 性能分析

在进行任何优化之前，首先需要进行性能分析，找出瓶颈所在。

### 使用Godot的性能监视器

1. 在游戏运行时按下F1键打开性能监视器
2. 观察CPU和GPU使用情况
3. 查看内存使用情况
4. 注意帧率下降的时刻

### 使用Godot的分析器

1. 在项目设置中启用分析器
2. 运行游戏并使用技能
3. 分析结果，找出耗时最长的函数

### 常见的性能瓶颈

- 技能状态的物理处理
- 技能冷却时间的更新
- 技能效果的渲染
- 技能UI的更新
- 技能数据的持久化

## 代码优化

### 技能状态优化

#### 状态缓存

```gdscript
# 优化前
func _init_states() -> void:
    _states["Dash"] = DashState.new(self)
    _states["WallSlide"] = WallSlideState.new(self)
    _states["WallJump"] = WallJumpState.new(self)
    _states["Slide"] = SlideState.new(self)

# 优化后
func _init_states() -> void:
    # 预先创建并缓存所有状态
    var dash_state = DashState.new(self)
    var wall_slide_state = WallSlideState.new(self)
    var wall_jump_state = WallJumpState.new(self)
    var slide_state = SlideState.new(self)
    
    _states["Dash"] = dash_state
    _states["WallSlide"] = wall_slide_state
    _states["WallJump"] = wall_jump_state
    _states["Slide"] = slide_state
```

#### 减少物理计算

```gdscript
# 优化前
func physics_process(delta: float) -> String:
    # 每帧都进行复杂的物理计算
    var complex_result = complex_physics_calculation()
    
    # 使用结果
    player.velocity = complex_result
    player.move_and_slide()
    
    return ""

# 优化后
var _physics_timer: float = 0.0
var _cached_result = null

func physics_process(delta: float) -> String:
    _physics_timer += delta
    
    # 只在必要时进行复杂计算
    if _physics_timer >= 0.05 or _cached_result == null:
        _cached_result = complex_physics_calculation()
        _physics_timer = 0.0
    
    # 使用缓存的结果
    player.velocity = _cached_result
    player.move_and_slide()
    
    return ""
```

### 技能管理器优化

#### 冷却时间更新优化

```gdscript
# 优化前
func _process(delta: float) -> void:
    # 每帧更新所有技能的冷却时间
    for skill_name in _skill_data.keys():
        if _skill_data[skill_name].cooldown_remaining > 0:
            _skill_data[skill_name].cooldown_remaining -= delta
            if _skill_data[skill_name].cooldown_remaining < 0:
                _skill_data[skill_name].cooldown_remaining = 0

# 优化后
func _process(delta: float) -> void:
    # 只更新正在冷却的技能
    var active_cooldowns = []
    for skill_name in _skill_data.keys():
        if _skill_data[skill_name].cooldown_remaining > 0:
            active_cooldowns.append(skill_name)
    
    for skill_name in active_cooldowns:
        _skill_data[skill_name].cooldown_remaining -= delta
        if _skill_data[skill_name].cooldown_remaining < 0:
            _skill_data[skill_name].cooldown_remaining = 0
            # 发出冷却完成信号
            cooldown_finished.emit(skill_name)
```

#### 参数计算优化

```gdscript
# 优化前
func get_dash_distance() -> float:
    var level = get_skill_level("dash")
    return dash_distance + (level - 1) * 20.0

# 优化后
var _cached_dash_distance: float = 0.0
var _cached_dash_level: int = -1

func get_dash_distance() -> float:
    var level = get_skill_level("dash")
    
    # 只在等级变化时重新计算
    if level != _cached_dash_level:
        _cached_dash_distance = dash_distance + (level - 1) * 20.0
        _cached_dash_level = level
    
    return _cached_dash_distance
```

### 技能UI优化

#### 减少UI更新

```gdscript
# 优化前
func _process(delta: float) -> void:
    # 每帧更新UI
    update_ui()

# 优化后
func _ready() -> void:
    # 只在需要时更新UI
    _skill_manager.skill_unlocked.connect(_on_skill_changed)
    _skill_manager.skill_upgraded.connect(_on_skill_changed)
    _skill_manager.coins_changed.connect(_on_coins_changed)

func _on_skill_changed(skill_name: String) -> void:
    update_skill_ui(skill_name)

func _on_coins_changed(amount: int) -> void:
    update_coins_ui()
```

#### 优化UI元素

```gdscript
# 优化前
func update_ui() -> void:
    # 更新所有UI元素
    for skill_name in _skill_manager.get_all_skills():
        var panel = get_node("SkillsContainer/%sPanel" % skill_name.capitalize())
        var level_label = panel.get_node("LevelLabel")
        var description_label = panel.get_node("DescriptionLabel")
        var cost_label = panel.get_node("CostLabel")
        var unlock_button = panel.get_node("UnlockButton")
        var upgrade_button = panel.get_node("UpgradeButton")
        
        # 更新UI元素
        # ...

# 优化后
func _ready() -> void:
    # 预先缓存UI元素引用
    _ui_elements = {}
    for skill_name in _skill_manager.get_all_skills():
        var panel = get_node("SkillsContainer/%sPanel" % skill_name.capitalize())
        _ui_elements[skill_name] = {
            "panel": panel,
            "level_label": panel.get_node("LevelLabel"),
            "description_label": panel.get_node("DescriptionLabel"),
            "cost_label": panel.get_node("CostLabel"),
            "unlock_button": panel.get_node("UnlockButton"),
            "upgrade_button": panel.get_node("UpgradeButton")
        }

func update_skill_ui(skill_name: String) -> void:
    # 使用缓存的UI元素引用
    var elements = _ui_elements[skill_name]
    var skill_data = _skill_manager.get_skill_data(skill_name)
    
    # 更新UI元素
    # ...
```

## 渲染优化

### 技能效果优化

#### 粒子系统优化

```gdscript
# 优化前
func enter() -> void:
    # 创建新的粒子效果
    var particles = ParticleEffect.new()
    particles.emitting = true
    player.add_child(particles)

# 优化后
func _ready() -> void:
    # 预先创建粒子效果并禁用
    _particles = ParticleEffect.new()
    _particles.emitting = false
    player.add_child(_particles)

func enter() -> void:
    # 启用已创建的粒子效果
    _particles.emitting = true

func exit() -> void:
    # 禁用粒子效果
    _particles.emitting = false
```

#### 使用对象池

```gdscript
class ParticlePool:
    var _available_particles = []
    var _in_use_particles = []
    var _particle_scene
    
    func _init(particle_scene, pool_size: int):
        _particle_scene = particle_scene
        for i in range(pool_size):
            var particle = particle_scene.instantiate()
            particle.emitting = false
            _available_particles.append(particle)
    
    func get_particle():
        if _available_particles.size() > 0:
            var particle = _available_particles.pop_back()
            _in_use_particles.append(particle)
            return particle
        else:
            print("Warning: Particle pool exhausted")
            var particle = _particle_scene.instantiate()
            _in_use_particles.append(particle)
            return particle
    
    func return_particle(particle):
        particle.emitting = false
        _in_use_particles.erase(particle)
        _available_particles.append(particle)
```

### 减少绘制调用

- 使用精灵表（Sprite Sheets）而不是单独的精灵
- 合并相似的材质
- 使用遮挡剔除（Occlusion Culling）

## 内存优化

### 资源加载优化

```gdscript
# 优化前
func _ready() -> void:
    # 每次都加载资源
    var dash_effect = load("res://effects/dash_effect.tscn")
    var dash_sound = load("res://sounds/dash_sound.wav")

# 优化后
# 预加载资源
const DASH_EFFECT = preload("res://effects/dash_effect.tscn")
const DASH_SOUND = preload("res://sounds/dash_sound.wav")

func _ready() -> void:
    # 使用预加载的资源
    var effect = DASH_EFFECT.instantiate()
    var sound = DASH_SOUND.duplicate()
```

### 减少内存分配

```gdscript
# 优化前
func physics_process(delta: float) -> String:
    # 每帧创建新的数组
    var nearby_enemies = []
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if player.global_position.distance_to(enemy.global_position) < 100:
            nearby_enemies.append(enemy)
    
    return ""

# 优化后
var _nearby_enemies = []

func physics_process(delta: float) -> String:
    # 重用现有数组
    _nearby_enemies.clear()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if player.global_position.distance_to(enemy.global_position) < 100:
            _nearby_enemies.append(enemy)
    
    return ""
```

## 网络优化

如果游戏支持多人模式，还需要考虑网络优化。

### 减少网络同步

```gdscript
# 优化前
func _process(delta: float) -> void:
    # 每帧同步技能状态
    if is_network_master():
        rpc("sync_skill_data", _skill_data)

# 优化后
var _sync_timer: float = 0.0
var _last_synced_data = null

func _process(delta: float) -> void:
    # 只在必要时同步技能状态
    if is_network_master():
        _sync_timer += delta
        if _sync_timer >= 0.1:  # 每0.1秒同步一次
            _sync_timer = 0.0
            var current_data = _skill_data.duplicate(true)
            if _last_synced_data != current_data:
                rpc("sync_skill_data", current_data)
                _last_synced_data = current_data
```

### 使用预测和插值

```gdscript
# 客户端预测
func use_dash() -> void:
    if is_network_master():
        # 服务器处理
        _perform_dash()
        rpc("remote_dash")
    else:
        # 客户端预测
        _perform_dash()

# 服务器确认
remote func remote_dash() -> void:
    if not is_network_master():
        _perform_dash()
```

## 输入优化

### 减少输入检查

```gdscript
# 优化前
func _process(delta: float) -> void:
    # 每帧检查所有输入
    if Input.is_action_just_pressed("dash"):
        use_dash()
    if Input.is_action_just_pressed("wall_jump"):
        use_wall_jump()
    if Input.is_action_just_pressed("slide"):
        use_slide()

# 优化后
func _input(event: InputEvent) -> void:
    # 只在输入事件发生时检查
    if event.is_action_pressed("dash"):
        use_dash()
    elif event.is_action_pressed("wall_jump"):
        use_wall_jump()
    elif event.is_action_pressed("slide"):
        use_slide()
```

### 使用输入缓冲

```gdscript
var _input_buffer = {}
var _buffer_timeout: float = 0.1

func _input(event: InputEvent) -> void:
    # 将输入存入缓冲区
    if event.is_action_pressed("dash"):
        _input_buffer["dash"] = _buffer_timeout
    elif event.is_action_pressed("wall_jump"):
        _input_buffer["wall_jump"] = _buffer_timeout
    elif event.is_action_pressed("slide"):
        _input_buffer["slide"] = _buffer_timeout

func _process(delta: float) -> void:
    # 处理缓冲区中的输入
    for action in _input_buffer.keys():
        _input_buffer[action] -= delta
        if _input_buffer[action] <= 0:
            _input_buffer.erase(action)
        elif can_use_skill(action):
            use_skill(action)
            _input_buffer.erase(action)
```

## 数据持久化优化

### 减少保存频率

```gdscript
# 优化前
func upgrade_skill(skill_name: String) -> bool:
    # 每次升级都保存
    if _skill_data.has(skill_name) and _skill_data[skill_name].unlocked:
        if _skill_data[skill_name].level < _skill_data[skill_name].max_level:
            if _coins >= _skill_data[skill_name].upgrade_cost:
                _coins -= _skill_data[skill_name].upgrade_cost
                _skill_data[skill_name].level += 1
                save_skill_data()
                return true
    return false

# 优化后
var _save_pending: bool = false
var _save_timer: float = 0.0

func upgrade_skill(skill_name: String) -> bool:
    # 标记需要保存，但不立即保存
    if _skill_data.has(skill_name) and _skill_data[skill_name].unlocked:
        if _skill_data[skill_name].level < _skill_data[skill_name].max_level:
            if _coins >= _skill_data[skill_name].upgrade_cost:
                _coins -= _skill_data[skill_name].upgrade_cost
                _skill_data[skill_name].level += 1
                _save_pending = true
                return true
    return false

func _process(delta: float) -> void:
    # 定期保存
    if _save_pending:
        _save_timer += delta
        if _save_timer >= 5.0:  # 每5秒最多保存一次
            _save_timer = 0.0
            _save_pending = false
            save_skill_data()
```

### 优化保存格式

```gdscript
# 优化前
func save_skill_data() -> void:
    var config = ConfigFile.new()
    for skill_name in _skill_data.keys():
        config.set_value("skills", skill_name + "_unlocked", _skill_data[skill_name].unlocked)
        config.set_value("skills", skill_name + "_level", _skill_data[skill_name].level)
    config.set_value("player", "coins", _coins)
    config.save("user://skill_data.cfg")

# 优化后
func save_skill_data() -> void:
    var save_data = {
        "skills": {},
        "player": {
            "coins": _coins
        }
    }
    
    for skill_name in _skill_data.keys():
        save_data.skills[skill_name] = {
            "unlocked": _skill_data[skill_name].unlocked,
            "level": _skill_data[skill_name].level
        }
    
    var file = FileAccess.open("user://skill_data.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
    file.close()
```

## 调试和分析工具

### 添加性能监控

```gdscript
class PerformanceMonitor:
    var _frame_times = []
    var _max_samples = 60
    var _total_time: float = 0.0
    
    func add_sample(delta: float) -> void:
        _frame_times.append(delta)
        _total_time += delta
        
        if _frame_times.size() > _max_samples:
            _total_time -= _frame_times[0]
            _frame_times.remove_at(0)
    
    func get_average_fps() -> float:
        if _frame_times.size() == 0:
            return 0.0
        return _frame_times.size() / _total_time
    
    func get_min_fps() -> float:
        if _frame_times.size() == 0:
            return 0.0
        var max_delta = _frame_times.max()
        return 1.0 / max_delta
```

### 添加调试开关

```gdscript
var DEBUG_MODE = OS.is_debug_build()

func _process(delta: float) -> void:
    if DEBUG_MODE:
        # 执行调试代码
        update_debug_display()
```

## 最佳实践总结

1. **分析先行**：在优化之前，先进行性能分析，找出瓶颈
2. **缓存引用**：缓存节点引用和计算结果，避免重复获取和计算
3. **减少更新**：只在必要时更新，使用信号而不是轮询
4. **对象池**：对于频繁创建和销毁的对象，使用对象池
5. **预加载资源**：使用`preload`而不是`load`加载经常使用的资源
6. **减少内存分配**：重用现有对象，避免频繁创建新对象
7. **批处理操作**：将多个小操作合并为一个大操作
8. **异步处理**：将耗时操作移到后台线程或分散到多个帧中
9. **减少绘制调用**：合并材质，使用精灵表
10. **优化输入处理**：使用`_input`而不是在`_process`中检查输入

## 结论

通过应用本文档中的优化技术，可以显著提高技能系统的性能和效率。记住，优化是一个持续的过程，应该根据游戏的具体需求和性能分析结果进行有针对性的优化。

在优化过程中，始终保持代码的可读性和可维护性，避免过度优化导致代码难以理解和维护。最后，定期进行性能测试，确保优化措施确实带来了性能提升。
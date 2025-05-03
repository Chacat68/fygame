# 随机关卡生成系统

## 概述

本文档详细描述了游戏中的随机关卡生成系统，包括生物群系、房间系统、难度调整和程序化地形生成等方面。该系统参考了《缺氧》游戏风格，实现了丰富多样的游戏体验。

## 系统架构

随机关卡生成系统主要由以下组件构成：

1. **关卡数据结构**：存储生成的关卡信息
2. **生物群系系统**：定义不同环境特性
3. **房间系统**：管理不同功能的区域
4. **难度调整系统**：根据关卡编号调整难度
5. **种子系统**：确保可重现性

## 关卡数据结构

```gdscript
class LevelData:
    var platforms = [] # 平台数据
    var coins = [] # 金币数据
    var monsters = [] # 怪物数据
    var biome = "" # 生物群系类型
```

## 生物群系系统

### 生物群系定义

```gdscript
const BIOMES = {
    "FOREST": {
        "name": "森林",
        "platform_color": Color(0.2, 0.8, 0.2),  # 绿色平台
        "enemy_types": ["green_slime", "purple_slime"],
        "resource_types": ["coin", "fruit"],
        "oxygen_level": 1.2,  # 氧气充足
        "background_color": Color(0.1, 0.5, 0.1)  # 深绿色背景
    },
    "CAVE": {
        "name": "洞穴",
        "platform_color": Color(0.6, 0.6, 0.6),  # 灰色平台
        "enemy_types": ["green_slime", "purple_slime"],
        "resource_types": ["coin"],
        "oxygen_level": 0.8,  # 氧气较少
        "background_color": Color(0.2, 0.2, 0.3)  # 深灰色背景
    },
    "SWAMP": {
        "name": "沼泽",
        "platform_color": Color(0.5, 0.4, 0.1),  # 棕色平台
        "enemy_types": ["purple_slime"],
        "resource_types": ["coin"],
        "oxygen_level": 0.6,  # 氧气稀少
        "background_color": Color(0.3, 0.3, 0.1)  # 棕色背景
    }
}
```

### 生物群系特性

每个生物群系具有以下特性：

1. **视觉风格**：平台颜色和背景颜色
2. **敌人类型**：可出现的敌人种类
3. **资源类型**：可出现的资源种类
4. **氧气水平**：影响玩家在该区域的氧气消耗

### 生物群系选择

关卡生成时，根据关卡编号和随机种子选择生物群系：

```gdscript
# 根据关卡编号选择生物群系
func _select_biome_for_level(level_number):
    var rng = RandomNumberGenerator.new()
    rng.seed = level_seeds[level_number]
    
    # 低级关卡更可能出现森林
    if level_number <= 10:
        if rng.randf() < 0.7:
            return "FOREST"
        elif rng.randf() < 0.5:
            return "CAVE"
        else:
            return "SWAMP"
    # 中级关卡更可能出现洞穴
    elif level_number <= 50:
        if rng.randf() < 0.6:
            return "CAVE"
        elif rng.randf() < 0.3:
            return "FOREST"
        else:
            return "SWAMP"
    # 高级关卡更可能出现沼泽
    else:
        if rng.randf() < 0.5:
            return "SWAMP"
        elif rng.randf() < 0.3:
            return "CAVE"
        else:
            return "FOREST"
```

## 关卡区域划分

每个关卡被划分为四个主要区域：

### 1. 入口区域

```gdscript
const ENTRANCE_AREA_START = Vector2(100, 250)
```

**特点**：
- 简单的平台布局
- 较少的敌人（主要是绿色史莱姆）
- 较多的金币作为引导
- 移动平台概率低（10%）

### 2. 中间区域

```gdscript
const MIDDLE_AREA_START = Vector2(400, 230)
```

**特点**：
- 平台间距增加
- 更多的敌人（包括少量紫色史莱姆）
- 移动平台概率中等（30%）

### 3. 挑战区域

```gdscript
const CHALLENGE_AREA_START = Vector2(800, 220)
```

**特点**：
- 复杂的平台布局
- 大量敌人（包括更多紫色史莱姆）
- 移动平台概率高（50%）

### 4. 宝藏区域

```gdscript
const TREASURE_AREA_START = Vector2(1200, 200)
```

**特点**：
- 大量金币和奖励
- 传送门通往下一关
- 较少的敌人

## 平台生成算法

### 平台参数

```gdscript
const MIN_PLATFORM_SPACING = 80   # 平台之间的最小间距
const MAX_PLATFORM_SPACING = 150  # 平台之间的最大间距
const MIN_PLATFORM_HEIGHT = -30   # 高度变化范围
const MAX_PLATFORM_HEIGHT = 30    # 高度变化范围
```

### 平台生成逻辑

1. **起始位置确定**：根据区域起始位置确定第一个平台位置
2. **平台间距计算**：使用随机数在最小和最大间距之间选择
3. **平台高度变化**：使用随机数在最小和最大高度变化范围内选择
4. **平台类型选择**：根据区域和随机数决定是静态平台还是移动平台

```gdscript
# 生成平台
func _generate_platforms(area_start, area_width, moving_platform_chance):
    var platforms = []
    var current_x = area_start.x
    var current_y = area_start.y
    
    while current_x < area_start.x + area_width:
        # 创建平台数据
        var platform_data = {
            "position": Vector2(current_x, current_y),
            "is_moving": randf() < moving_platform_chance,
            "move_distance": 0,
            "move_speed": 0
        }
        
        # 如果是移动平台，设置移动参数
        if platform_data.is_moving:
            platform_data.move_distance = randi_range(30, 80)
            platform_data.move_speed = randi_range(30, 60)
        
        platforms.append(platform_data)
        
        # 计算下一个平台位置
        var spacing = randi_range(MIN_PLATFORM_SPACING, MAX_PLATFORM_SPACING)
        current_x += spacing
        
        # 随机调整高度
        var height_change = randi_range(MIN_PLATFORM_HEIGHT, MAX_PLATFORM_HEIGHT)
        current_y += height_change
        
        # 确保高度不会太高或太低
        current_y = clamp(current_y, 150, 350)
    
    return platforms
```

## 敌人和金币生成

### 敌人生成逻辑

1. **位置确定**：在平台上方生成
2. **类型选择**：根据生物群系和区域难度选择敌人类型
3. **概率控制**：根据区域调整敌人出现概率

```gdscript
# 在平台上生成敌人
func _generate_enemies_on_platforms(platforms, area_type, biome):
    var enemies = []
    
    for platform in platforms:
        # 根据区域类型确定敌人生成概率和类型
        var spawn_chance = 0.3  # 默认概率
        var purple_slime_chance = 0.0  # 默认紫色史莱姆概率
        
        match area_type:
            "entrance":
                spawn_chance = 0.2
                purple_slime_chance = ENTRANCE_PURPLE_SLIME_CHANCE
            "middle":
                spawn_chance = 0.3
                purple_slime_chance = MIDDLE_PURPLE_SLIME_CHANCE
            "challenge":
                spawn_chance = 0.4
                purple_slime_chance = CHALLENGE_PURPLE_SLIME_CHANCE
            "treasure":
                spawn_chance = 0.1
                purple_slime_chance = 0.0
        
        # 决定是否生成敌人
        if randf() < spawn_chance:
            # 确定敌人类型
            var enemy_type = "green_slime"
            if randf() < purple_slime_chance:
                enemy_type = "purple_slime"
            
            # 确保该生物群系支持这种敌人类型
            if enemy_type in BIOMES[biome].enemy_types:
                var enemy_data = {
                    "position": Vector2(platform.position.x, platform.position.y - SLIME_HEIGHT_ABOVE_PLATFORM),
                    "type": enemy_type
                }
                enemies.append(enemy_data)
    
    return enemies
```

### 金币生成逻辑

1. **位置确定**：在平台上方或特定位置生成
2. **概率控制**：根据区域调整金币出现概率
3. **模式选择**：单个金币或金币组合（如金币线、金币圈等）

```gdscript
# 在平台上生成金币
func _generate_coins_on_platforms(platforms, area_type):
    var coins = []
    
    for platform in platforms:
        # 根据区域类型确定金币生成概率和模式
        var spawn_chance = 0.4  # 默认概率
        var pattern_chance = 0.2  # 金币图案概率
        
        match area_type:
            "entrance":
                spawn_chance = 0.5
                pattern_chance = 0.1
            "middle":
                spawn_chance = 0.4
                pattern_chance = 0.2
            "challenge":
                spawn_chance = 0.3
                pattern_chance = 0.3
            "treasure":
                spawn_chance = 0.8
                pattern_chance = 0.5
        
        # 决定是否生成金币
        if randf() < spawn_chance:
            # 决定金币模式
            if randf() < pattern_chance:
                # 生成金币图案（线、圈等）
                var pattern_coins = _generate_coin_pattern(platform.position)
                coins.append_array(pattern_coins)
            else:
                # 生成单个金币
                var coin_data = {
                    "position": Vector2(platform.position.x, platform.position.y - COIN_HEIGHT_ABOVE_PLATFORM)
                }
                coins.append(coin_data)
    
    return coins
```

## 房间系统

### 房间类型

```gdscript
enum RoomType {
    ENTRANCE = 0,  # 入口房间
    CORRIDOR = 1,  # 走廊房间
    STORAGE = 2,   # 储藏室
    OXYGEN = 3,    # 氧气房间
    CHALLENGE = 4, # 挑战房间
    TREASURE = 5   # 宝藏房间
}
```

### 房间生成逻辑

1. **房间布局**：根据房间类型生成不同的布局
2. **房间连接**：确保房间之间有合理的连接
3. **房间内容**：根据房间类型放置不同的游戏元素

```gdscript
# 生成房间
func _generate_room(room_type, position, size):
    var room_data = {
        "type": room_type,
        "position": position,
        "size": size,
        "platforms": [],
        "coins": [],
        "enemies": [],
        "special_objects": []
    }
    
    # 根据房间类型生成内容
    match room_type:
        RoomType.ENTRANCE:
            # 生成入口房间内容
            room_data.platforms = _generate_entrance_platforms(position, size)
            room_data.coins = _generate_coins_on_platforms(room_data.platforms, "entrance")
        RoomType.CORRIDOR:
            # 生成走廊房间内容
            room_data.platforms = _generate_corridor_platforms(position, size)
            room_data.enemies = _generate_enemies_on_platforms(room_data.platforms, "middle", current_biome)
        RoomType.STORAGE:
            # 生成储藏室内容
            room_data.platforms = _generate_storage_platforms(position, size)
            room_data.coins = _generate_coins_on_platforms(room_data.platforms, "treasure")
        RoomType.OXYGEN:
            # 生成氧气房间内容
            room_data.platforms = _generate_oxygen_platforms(position, size)
            room_data.special_objects = _generate_oxygen_generators(position, size)
        RoomType.CHALLENGE:
            # 生成挑战房间内容
            room_data.platforms = _generate_challenge_platforms(position, size)
            room_data.enemies = _generate_enemies_on_platforms(room_data.platforms, "challenge", current_biome)
            room_data.coins = _generate_coins_on_platforms(room_data.platforms, "challenge")
        RoomType.TREASURE:
            # 生成宝藏房间内容
            room_data.platforms = _generate_treasure_platforms(position, size)
            room_data.coins = _generate_treasure_coins(position, size)
            room_data.special_objects = _generate_portal(position, size)
    
    return room_data
```

## 难度调整系统

### 难度参数

```gdscript
# 入口区域参数
const ENTRANCE_MOVING_PLATFORM_CHANCE = 0.1  # 移动平台概率
const ENTRANCE_PURPLE_SLIME_CHANCE = 0.0    # 紫色史莱姆概率

# 中间区域参数
const MIDDLE_MOVING_PLATFORM_CHANCE = 0.3    # 移动平台概率
const MIDDLE_PURPLE_SLIME_CHANCE = 0.2      # 紫色史莱姆概率

# 挑战区域参数
const CHALLENGE_MOVING_PLATFORM_CHANCE = 0.5  # 移动平台概率
const CHALLENGE_PURPLE_SLIME_CHANCE = 0.4    # 紫色史莱姆概率
```

### 难度调整逻辑

根据关卡编号调整难度参数：

```gdscript
# 根据关卡编号调整难度
func _adjust_difficulty_for_level(level_number):
    # 基础难度参数
    var base_moving_platform_chance = 0.1
    var base_purple_slime_chance = 0.0
    var base_platform_spacing = 80
    
    # 根据关卡编号增加难度
    var difficulty_factor = min(level_number / 20.0, 1.0)  # 最大难度因子为1.0
    
    # 调整移动平台概率
    ENTRANCE_MOVING_PLATFORM_CHANCE = base_moving_platform_chance + (0.2 * difficulty_factor)
    MIDDLE_MOVING_PLATFORM_CHANCE = 0.3 + (0.2 * difficulty_factor)
    CHALLENGE_MOVING_PLATFORM_CHANCE = 0.5 + (0.2 * difficulty_factor)
    
    # 调整紫色史莱姆概率
    ENTRANCE_PURPLE_SLIME_CHANCE = base_purple_slime_chance + (0.2 * difficulty_factor)
    MIDDLE_PURPLE_SLIME_CHANCE = 0.2 + (0.3 * difficulty_factor)
    CHALLENGE_PURPLE_SLIME_CHANCE = 0.4 + (0.3 * difficulty_factor)
    
    # 调整平台间距
    MIN_PLATFORM_SPACING = base_platform_spacing + int(20 * difficulty_factor)
    MAX_PLATFORM_SPACING = 150 + int(30 * difficulty_factor)
```

## 种子系统

### 种子管理

```gdscript
# 关卡种子管理
var level_seeds = {}  # 存储所有关卡的随机种子
var save_file_path = "user://level_seeds.json"  # 关卡种子保存文件路径

# 生成关卡种子
func _generate_level_seeds():
    # 如果已有种子，不重新生成
    if not level_seeds.empty():
        return
    
    # 为每个关卡生成唯一的种子
    for i in range(1, TOTAL_LEVELS + 1):
        level_seeds[i] = randi()
    
    # 保存种子
    save_level_seeds()

# 保存关卡种子
func save_level_seeds():
    var file = FileAccess.open(save_file_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(level_seeds))
        file.close()

# 加载关卡种子
func load_level_seeds():
    if FileAccess.file_exists(save_file_path):
        var file = FileAccess.open(save_file_path, FileAccess.READ)
        if file:
            var json_string = file.get_as_text()
            file.close()
            
            var json = JSON.parse_string(json_string)
            if json:
                level_seeds = json
```

### 种子应用

使用种子确保关卡生成的可重现性：

```gdscript
# 根据关卡编号生成关卡
func generate_level_by_number(level_number):
    # 确保有关卡种子
    if level_seeds.empty():
        _generate_level_seeds()
    
    # 设置随机数生成器种子
    var rng = RandomNumberGenerator.new()
    rng.seed = level_seeds[level_number]
    
    # 调整难度
    _adjust_difficulty_for_level(level_number)
    
    # 选择生物群系
    var biome = _select_biome_for_level(level_number)
    
    # 生成关卡
    var level_data = _generate_level(rng, biome)
    
    # 实例化关卡
    _instantiate_level(level_data)
```

## 实现注意事项

1. **性能优化**：
   - 只生成玩家可见区域的内容
   - 使用对象池减少实例化开销
   - 优化碰撞检测

2. **可扩展性**：
   - 设计允许轻松添加新的生物群系
   - 支持添加新的敌人和资源类型
   - 允许自定义房间模板

3. **平衡性**：
   - 确保关卡难度曲线合理
   - 平衡资源和敌人的分布
   - 提供足够的挑战但不过于困难

4. **随机性与可控性**：
   - 使用种子系统确保可重现性
   - 在随机性和设计意图之间取得平衡
   - 允许开发者微调生成参数

---

本文档详细描述了游戏中的随机关卡生成系统。开发人员应参考此文档进行关卡生成系统的实现和扩展。如有任何更新或修改，请及时更新本文档。
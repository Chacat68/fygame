# 技能系统管理器
# 负责管理所有技能的解锁、升级、冷却和使用
class_name SkillManager
extends Node

# 技能相关信号
signal skill_unlocked(skill_name: String)
signal skill_upgraded(skill_name: String, level: int)
signal skill_used(skill_name: String)
signal skill_cooldown_finished(skill_name: String)

# 技能数据存储
var skills: Dictionary = {}
var skill_cooldowns: Dictionary = {}
var player_coins: int = 0

# 技能配置引用
var config: GameConfig

func _ready():
    config = GameConfig.get_config()
    _initialize_skills()
    
    # 连接游戏状态信号
    if GameState:
        GameState.coins_changed.connect(_on_coins_changed)

func _initialize_skills():
    """初始化所有技能数据"""
    # 冲刺技能
    skills["dash"] = {
        "name": "冲刺",
        "description": "快速向前冲刺，冲刺期间无敌",
        "max_level": 3,
        "current_level": 0,
        "is_unlocked": false,
        "unlock_cost": config.dash_unlock_cost if config else 100,
        "upgrade_costs": [150, 200],
        "cooldown_time": config.dash_cooldown if config else 2.0
    }
    
    # 墙跳技能
    skills["wall_jump"] = {
        "name": "墙跳",
        "description": "在墙壁上跳跃，支持连续墙跳",
        "max_level": 3,
        "current_level": 0,
        "is_unlocked": false,
        "unlock_cost": config.wall_jump_unlock_cost if config else 150,
        "upgrade_costs": [200, 300],
        "cooldown_time": 0.0
    }
    
    # 滑铲技能
    skills["slide"] = {
        "name": "滑铲",
        "description": "滑过低矮障碍物并攻击敌人",
        "max_level": 3,
        "current_level": 0,
        "is_unlocked": false,
        "unlock_cost": config.slide_unlock_cost if config else 200,
        "upgrade_costs": [250, 350],
        "cooldown_time": config.slide_cooldown if config else 3.0
    }

func _process(delta):
    """更新技能冷却时间"""
    _update_cooldowns(delta)

func _update_cooldowns(delta: float):
    """更新所有技能的冷却时间"""
    for skill_name in skill_cooldowns.keys():
        skill_cooldowns[skill_name] -= delta
        if skill_cooldowns[skill_name] <= 0:
            skill_cooldowns.erase(skill_name)
            skill_cooldown_finished.emit(skill_name)

# 技能解锁和升级
func unlock_skill(skill_name: String) -> bool:
    """解锁技能"""
    if not skills.has(skill_name):
        print("技能不存在: ", skill_name)
        return false
    
    var skill = skills[skill_name]
    if skill.is_unlocked:
        print("技能已解锁: ", skill_name)
        return false
    
    if player_coins < skill.unlock_cost:
        print("金币不足，需要: ", skill.unlock_cost, " 当前: ", player_coins)
        return false
    
    # 扣除金币并解锁技能
    _spend_coins(skill.unlock_cost)
    skill.is_unlocked = true
    skill.current_level = 1
    
    skill_unlocked.emit(skill_name)
    print("技能已解锁: ", skill.name)
    return true

func upgrade_skill(skill_name: String) -> bool:
    """升级技能"""
    if not skills.has(skill_name):
        return false
    
    var skill = skills[skill_name]
    if not skill.is_unlocked:
        print("技能未解锁: ", skill_name)
        return false
    
    if skill.current_level >= skill.max_level:
        print("技能已达到最高等级: ", skill_name)
        return false
    
    var upgrade_cost = skill.upgrade_costs[skill.current_level - 1]
    if player_coins < upgrade_cost:
        print("金币不足，需要: ", upgrade_cost, " 当前: ", player_coins)
        return false
    
    # 扣除金币并升级技能
    _spend_coins(upgrade_cost)
    skill.current_level += 1
    
    skill_upgraded.emit(skill_name, skill.current_level)
    print("技能已升级: ", skill.name, " 等级: ", skill.current_level)
    return true

# 技能使用检查
func can_use_skill(skill_name: String) -> bool:
    """检查是否可以使用技能"""
    if not skills.has(skill_name):
        return false
    
    var skill = skills[skill_name]
    if not skill.is_unlocked or skill.current_level == 0:
        return false
    
    # 检查冷却时间
    if skill_cooldowns.has(skill_name):
        return false
    
    return true

func use_skill(skill_name: String) -> bool:
    """使用技能"""
    if not can_use_skill(skill_name):
        return false
    
    var skill = skills[skill_name]
    
    # 开始冷却
    if skill.cooldown_time > 0:
        skill_cooldowns[skill_name] = skill.cooldown_time
    
    skill_used.emit(skill_name)
    return true

# 技能参数获取
func get_skill_level(skill_name: String) -> int:
    """获取技能等级"""
    if not skills.has(skill_name):
        return 0
    return skills[skill_name].current_level

func is_skill_unlocked(skill_name: String) -> bool:
    """检查技能是否已解锁"""
    if not skills.has(skill_name):
        return false
    return skills[skill_name].is_unlocked

func get_skill_cooldown_remaining(skill_name: String) -> float:
    """获取技能剩余冷却时间"""
    if skill_cooldowns.has(skill_name):
        return skill_cooldowns[skill_name]
    return 0.0

# 冲刺技能参数
func get_dash_distance() -> float:
    var level = get_skill_level("dash")
    var base_distance = config.dash_distance if config else 120.0
    return base_distance * (1.0 + (level - 1) * 0.3)  # 每级增加30%距离

func get_dash_speed() -> float:
    var level = get_skill_level("dash")
    var base_speed = config.dash_speed if config else 600.0
    return base_speed * (1.0 + (level - 1) * 0.2)  # 每级增加20%速度

func get_dash_duration() -> float:
    return config.dash_duration if config else 0.2

func is_dash_invincible() -> bool:
    return config.dash_invincible if config else true

func get_dash_cooldown() -> float:
    var level = get_skill_level("dash")
    var base_cooldown = config.dash_cooldown if config else 2.0
    return base_cooldown * (1.0 - (level - 1) * 0.2)  # 每级减少20%冷却

# 墙跳技能参数
func get_wall_jump_force() -> float:
    var level = get_skill_level("wall_jump")
    var base_force = config.wall_jump_force if config else 300.0
    return base_force * (1.0 + (level - 1) * 0.15)  # 每级增加15%力度

func get_wall_slide_speed() -> float:
    var level = get_skill_level("wall_jump")
    var base_speed = config.wall_slide_speed if config else 100.0
    return base_speed * (1.0 - (level - 1) * 0.2)  # 每级减少20%滑行速度

func get_wall_jump_horizontal() -> float:
    return config.wall_jump_horizontal if config else 200.0

func get_max_wall_jumps() -> int:
    var level = get_skill_level("wall_jump")
    return 2 + level  # 基础2次，每级+1次

# 滑铲技能参数
func get_slide_speed() -> float:
    var level = get_skill_level("slide")
    var base_speed = config.slide_speed if config else 250.0
    return base_speed * (1.0 + (level - 1) * 0.1)  # 每级增加10%速度

func get_slide_duration() -> float:
    var level = get_skill_level("slide")
    var base_duration = config.slide_duration if config else 0.8
    return base_duration * (1.0 + (level - 1) * 0.2)  # 每级增加20%持续时间

func get_slide_damage() -> int:
    var level = get_skill_level("slide")
    var base_damage = config.slide_damage if config else 15
    return base_damage + (level - 1) * 5  # 每级增加5点伤害

func get_slide_cooldown() -> float:
    var level = get_skill_level("slide")
    var base_cooldown = config.slide_cooldown if config else 3.0
    return base_cooldown * (1.0 - (level - 1) * 0.25)  # 每级减少25%冷却

# 金币管理
func _spend_coins(amount: int):
    """消费金币"""
    player_coins -= amount
    if GameState:
        GameState.remove_coins(amount)

func _on_coins_changed(new_amount: int):
    """响应金币变化"""
    player_coins = new_amount

# 数据持久化
func save_skill_data() -> Dictionary:
    """保存技能数据"""
    var skill_data = {
        "unlocked_skills": [],
        "skill_levels": {},
        "total_coins_spent": 0
    }
    
    for skill_id in skills.keys():
        var skill = skills[skill_id]
        if skill.is_unlocked:
            skill_data.unlocked_skills.append(skill_id)
            skill_data.skill_levels[skill_id] = skill.current_level
    
    return skill_data

func load_skill_data(data: Dictionary):
    """加载技能数据"""
    if data.has("unlocked_skills"):
        for skill_id in data.unlocked_skills:
            if skills.has(skill_id):
                skills[skill_id].is_unlocked = true
    
    if data.has("skill_levels"):
        for skill_id in data.skill_levels.keys():
            if skills.has(skill_id):
                skills[skill_id].current_level = data.skill_levels[skill_id]

# 调试功能
func _debug_unlock_all_skills():
    """调试：解锁所有技能"""
    if not OS.is_debug_build():
        return
    
    for skill_name in skills.keys():
        var skill = skills[skill_name]
        skill.is_unlocked = true
        skill.current_level = skill.max_level
        skill_unlocked.emit(skill_name)

func _debug_add_coins(amount: int):
    """调试：添加金币"""
    if not OS.is_debug_build():
        return
    
    player_coins += amount
    if GameState:
        GameState.add_coins(amount)

func get_all_skills() -> Dictionary:
    """获取所有技能信息"""
    return skills.duplicate(true)
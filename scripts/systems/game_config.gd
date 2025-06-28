class_name GameConfig
extends Resource

# 游戏配置资源类
# 用于统一管理游戏中的各种数值参数，避免硬编码

# 玩家相关配置
# 使用分组来组织参数
@export_group("玩家移动")
# 玩家水平移动速度（像素/秒）
# 控制玩家左右移动的快慢，数值越大移动越快
@export var player_speed: float = 180.0

# 玩家重力加速度（像素/秒²）
# 控制玩家下落的速度，数值越大下落越快
@export var player_gravity: float = 800.0

@export_group("玩家跳跃")
# 玩家跳跃初始速度（像素/秒）
# 负值表示向上的速度，绝对值越大跳得越高
@export var player_jump_velocity: float = -250.0

# 玩家最大跳跃次数
# 允许玩家连续跳跃的次数（包括二段跳等）
@export var player_max_jumps: int = 2

@export_group("玩家生命")
# 玩家最大生命值
# 玩家可承受的最大伤害次数
@export var player_max_health: int = 3

# 玩家受到的伤害量
# 每次受伤时减少的生命值
@export var player_damage_amount: int = 10

# 玩家无敌时间（秒）
# 受伤后的无敌保护时间，期间不会再次受伤
@export var player_invincibility_time: float = 1.0

# 添加参数范围限制
# 带范围限制的玩家移动速度（50-500像素/秒，步长10）
# 用于编辑器中的滑块控制，提供更直观的参数调整
@export_range(50.0, 500.0, 10.0) var player_speed_ranged: float = 250.0

# 带范围限制的玩家跳跃速度（-800到-100像素/秒，步长50）
# 用于编辑器中的滑块控制，限制跳跃力度的合理范围
@export_range(-800.0, -100.0, 50.0) var player_jump_velocity_ranged: float = -400.0

# 关卡相关配置
@export var death_height: float = 300.0

# 受伤状态配置
@export var hurt_duration: float = 1.0

# 史莱姆敌人配置
@export var slime_speed: float = 50.0
@export var slime_patrol_distance: float = 100.0
@export var slime_chase_speed: float = 80.0
@export var slime_attack_range: float = 30.0
@export var slime_health: int = 1

# 金币配置
@export var coin_value: int = 10

# 浮动文本配置
@export var floating_text_speed: float = 50.0
@export var floating_text_fade_duration: float = 2.0

# 获取配置实例的静态方法
# 在GameConfig类中添加验证方法
func validate_config() -> bool:
    var warnings = []
    
    # 检查物理参数的合理性
    if player_jump_velocity >= 0:
        warnings.append("警告：跳跃速度应为负值")
    
    if player_gravity <= 0:
        warnings.append("警告：重力应为正值")
    
    if player_speed <= 0:
        warnings.append("警告：移动速度应为正值")
    
    # 输出警告信息
    for warning in warnings:
        print(warning)
    
    return warnings.is_empty()

# 在get_config()方法中调用验证
static func get_config() -> GameConfig:
    var config = load("res://resources/game_config.tres") as GameConfig
    if config:
        config.validate_config()  # 验证配置
        return config
    else:
        print("警告：无法加载游戏配置文件，使用默认配置")
        var default_config = GameConfig.new()
        default_config.validate_config()
        return default_config
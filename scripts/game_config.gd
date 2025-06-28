class_name GameConfig
extends Resource

# 游戏配置资源类
# 用于统一管理游戏中的各种数值参数，避免硬编码

# 玩家相关配置
@export var player_speed: float = 300.0
@export var player_jump_velocity: float = -400.0
@export var player_gravity: float = 980.0
@export var player_max_jumps: int = 2
@export var player_max_health: int = 3
@export var player_damage_amount: int = 10
@export var player_invincibility_time: float = 1.0

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
static func get_config() -> GameConfig:
	# 尝试加载配置文件
	var config = load("res://resources/game_config.tres") as GameConfig
	if config:
		return config
	else:
		# 如果加载失败，返回默认配置
		print("警告：无法加载游戏配置文件，使用默认配置")
		return GameConfig.new()
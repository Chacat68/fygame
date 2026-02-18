extends Resource
# 传送配置资源
# 用于配置传送系统的各种参数

class_name TeleportConfig

# 传送偏移配置
@export var portal_offset: Vector2 = Vector2(-20, 0)  # 传送到Portal前方的偏移
@export var spawn_offset: Vector2 = Vector2(0, -10)   # 生成点偏移

# 安全检查配置
@export var safety_distance: float = 30.0            # 安全传送距离
@export var enable_collision_check: bool = true      # 是否启用碰撞检查
@export var enable_killzone_check: bool = true       # 是否检查危险区域

# 特效配置
@export var enable_teleport_effects: bool = true     # 是否启用传送特效
@export var teleport_sound_enabled: bool = true      # 是否播放传送音效
@export var screen_flash_enabled: bool = false       # 是否启用屏幕闪烁效果

# 动画配置
@export var teleport_duration: float = 0.3           # 传送动画持续时间
@export var fade_in_duration: float = 0.15           # 淡入时间
@export var fade_out_duration: float = 0.15          # 淡出时间

# 调试配置
@export var debug_mode: bool = false                 # 调试模式
@export var show_teleport_markers: bool = false      # 显示传送标记
@export var log_teleport_events: bool = true         # 记录传送事件

# 限制配置
@export var cooldown_time: float = 1.0               # 传送冷却时间
@export var max_teleport_distance: float = 1000.0    # 最大传送距离
@export var require_line_of_sight: bool = false      # 是否需要视线

# 预设配置
enum TeleportPreset {
	INSTANT,      # 瞬间传送
	SMOOTH,       # 平滑传送
	CINEMATIC,    # 电影式传送
	DEBUG         # 调试模式传送
}

# 应用预设配置
func apply_preset(preset: TeleportPreset):
	match preset:
		TeleportPreset.INSTANT:
			_apply_instant_preset()
		TeleportPreset.SMOOTH:
			_apply_smooth_preset()
		TeleportPreset.CINEMATIC:
			_apply_cinematic_preset()
		TeleportPreset.DEBUG:
			_apply_debug_preset()

# 瞬间传送预设
func _apply_instant_preset():
	teleport_duration = 0.0
	fade_in_duration = 0.0
	fade_out_duration = 0.0
	enable_teleport_effects = false
	teleport_sound_enabled = false
	screen_flash_enabled = false

# 平滑传送预设
func _apply_smooth_preset():
	teleport_duration = 0.5
	fade_in_duration = 0.25
	fade_out_duration = 0.25
	enable_teleport_effects = true
	teleport_sound_enabled = true
	screen_flash_enabled = false

# 电影式传送预设
func _apply_cinematic_preset():
	teleport_duration = 1.0
	fade_in_duration = 0.4
	fade_out_duration = 0.4
	enable_teleport_effects = true
	teleport_sound_enabled = true
	screen_flash_enabled = true

# 调试模式预设
func _apply_debug_preset():
	teleport_duration = 0.1
	fade_in_duration = 0.05
	fade_out_duration = 0.05
	enable_teleport_effects = false
	teleport_sound_enabled = false
	screen_flash_enabled = false
	debug_mode = true
	show_teleport_markers = true
	log_teleport_events = true
	cooldown_time = 0.0

# 验证配置有效性
func validate_config() -> bool:
	if teleport_duration < 0:
		Logger.warn("TeleportConfig", 警告：传送持续时间不能为负数")
		return false
	
	if safety_distance < 0:
		Logger.warn("TeleportConfig", 警告：安全距离不能为负数")
		return false
	
	if max_teleport_distance <= 0:
		Logger.warn("TeleportConfig", 警告：最大传送距离必须大于0")
		return false
	
	return true

# 重置为默认配置
func reset_to_default():
	apply_preset(TeleportPreset.SMOOTH)
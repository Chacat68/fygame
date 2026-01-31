class_name Springboard
extends Area2D

## 弹簧跳板
## 死亡细胞风格的弹跳装置，可以将玩家弹射到特定方向

# 弹跳方向
enum SpringDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	CUSTOM  # 自定义角度
}

# 信号
signal player_bounced(player: Node2D)

@export_group("弹跳设置")
@export var spring_direction: SpringDirection = SpringDirection.UP
@export var bounce_force: float = 600.0  # 弹跳力度
@export var custom_angle: float = 0.0  # 自定义角度（度，0=上，90=右）
@export var override_player_velocity: bool = true  # 是否覆盖玩家速度

@export_group("动画设置")
@export var spring_animation_time: float = 0.3  # 弹簧压缩动画时间
@export var play_sound: bool = true

@export_group("视觉效果")
@export var squash_amount: float = 0.3  # 压缩量

# 组件引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# 状态
var _is_bouncing: bool = false
var _original_scale: Vector2

func _ready() -> void:
	add_to_group("springboard")
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	
	# 保存原始缩放
	_original_scale = scale
	
	# 设置旋转
	_set_rotation()

func _set_rotation() -> void:
	match spring_direction:
		SpringDirection.UP:
			rotation_degrees = 0
		SpringDirection.DOWN:
			rotation_degrees = 180
		SpringDirection.LEFT:
			rotation_degrees = -90
		SpringDirection.RIGHT:
			rotation_degrees = 90
		SpringDirection.CUSTOM:
			rotation_degrees = custom_angle

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if _is_bouncing:
		return
	
	_bounce_player(body)

func _bounce_player(player: Node2D) -> void:
	_is_bouncing = true
	
	# 计算弹跳方向
	var direction = _get_bounce_direction()
	
	# 应用弹跳力
	if player is CharacterBody2D:
		if override_player_velocity:
			player.velocity = direction * bounce_force
		else:
			player.velocity += direction * bounce_force
		
		# 重置跳跃次数（允许空中再次跳跃）
		if player.has_method("reset_jumps"):
			player.reset_jumps()
		elif "jumps_made" in player:
			player.jumps_made = 0
	
	# 发射信号
	player_bounced.emit(player)
	
	# 播放弹簧动画
	_play_bounce_animation()
	
	# 播放音效
	if play_sound:
		_play_bounce_sound()
	
	# 重置状态
	await get_tree().create_timer(0.1).timeout
	_is_bouncing = false

func _get_bounce_direction() -> Vector2:
	match spring_direction:
		SpringDirection.UP:
			return Vector2.UP
		SpringDirection.DOWN:
			return Vector2.DOWN
		SpringDirection.LEFT:
			return Vector2.LEFT
		SpringDirection.RIGHT:
			return Vector2.RIGHT
		SpringDirection.CUSTOM:
			var angle_rad = deg_to_rad(custom_angle - 90)  # -90 使0度朝上
			return Vector2(cos(angle_rad), sin(angle_rad))
	
	return Vector2.UP

func _play_bounce_animation() -> void:
	# 压缩然后弹回
	var tween = create_tween()
	
	# 压缩
	var squash_scale = Vector2(_original_scale.x * (1 + squash_amount), _original_scale.y * (1 - squash_amount))
	tween.tween_property(self, "scale", squash_scale, spring_animation_time * 0.3)
	
	# 拉伸
	var stretch_scale = Vector2(_original_scale.x * (1 - squash_amount * 0.5), _original_scale.y * (1 + squash_amount * 0.5))
	tween.tween_property(self, "scale", stretch_scale, spring_animation_time * 0.3)
	
	# 恢复
	tween.tween_property(self, "scale", _original_scale, spring_animation_time * 0.4)
	
	# 播放精灵动画
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("bounce"):
			animated_sprite.play("bounce")

func _play_bounce_sound() -> void:
	# 尝试通过 AudioManager 播放音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("spring")

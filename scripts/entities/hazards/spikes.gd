class_name Spikes
extends "res://scripts/entities/hazards/hazard_base.gd"

## 尖刺陷阱
## 死亡细胞风格的地刺/墙刺，可以是静态或周期性弹出

# 尖刺类型
enum SpikeType {
	STATIC,      # 静态尖刺，一直存在
	PERIODIC,    # 周期性弹出
	TRIGGERED    # 触发式（踩到触发板后弹出）
}

# 尖刺方向
enum SpikeDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export_group("尖刺设置")
@export var spike_type: SpikeType = SpikeType.STATIC
@export var spike_direction: SpikeDirection = SpikeDirection.UP
@export var spike_length: float = 16.0  # 尖刺长度

@export_group("周期设置")
@export var extend_time: float = 1.0  # 伸出持续时间
@export var retract_time: float = 1.0  # 收回持续时间
@export var warning_time: float = 0.3  # 警告时间
@export var initial_delay: float = 0.0  # 初始延迟

@export_group("视觉效果")
@export var show_warning: bool = true  # 显示警告

# 状态
var _is_extended: bool = false
var _state_timer: float = 0.0
var _current_phase: String = "retracted"  # retracted, warning, extending, extended

# 尖刺位置
var _base_position: Vector2
var _extended_position: Vector2

func _hazard_ready() -> void:
	# 保存基础位置
	_base_position = position
	
	# 计算伸出位置
	_calculate_extended_position()
	
	# 根据类型设置初始状态
	match spike_type:
		SpikeType.STATIC:
			_set_extended(true)
			is_active = true
		SpikeType.PERIODIC:
			_set_extended(false)
			_state_timer = initial_delay
			_current_phase = "retracted"
		SpikeType.TRIGGERED:
			_set_extended(false)
			is_active = false
	
	# 设置旋转
	_set_rotation()

func _calculate_extended_position() -> void:
	var offset = Vector2.ZERO
	match spike_direction:
		SpikeDirection.UP:
			offset = Vector2(0, -spike_length)
		SpikeDirection.DOWN:
			offset = Vector2(0, spike_length)
		SpikeDirection.LEFT:
			offset = Vector2(-spike_length, 0)
		SpikeDirection.RIGHT:
			offset = Vector2(spike_length, 0)
	
	_extended_position = _base_position + offset

func _set_rotation() -> void:
	match spike_direction:
		SpikeDirection.UP:
			rotation_degrees = 0
		SpikeDirection.DOWN:
			rotation_degrees = 180
		SpikeDirection.LEFT:
			rotation_degrees = -90
		SpikeDirection.RIGHT:
			rotation_degrees = 90

func _process(delta: float) -> void:
	if spike_type != SpikeType.PERIODIC:
		return
	
	_state_timer -= delta
	
	if _state_timer <= 0:
		_advance_phase()

func _advance_phase() -> void:
	match _current_phase:
		"retracted":
			# 进入警告阶段
			_current_phase = "warning"
			_state_timer = warning_time
			_play_warning()
		"warning":
			# 开始伸出
			_current_phase = "extending"
			_extend_spikes()
		"extending":
			# 伸出完成，保持伸出状态
			_current_phase = "extended"
			_state_timer = extend_time
		"extended":
			# 开始收回
			_current_phase = "retracting"
			_retract_spikes()
		"retracting":
			# 收回完成
			_current_phase = "retracted"
			_state_timer = retract_time

func _play_warning() -> void:
	if not show_warning:
		return
	
	# 闪烁警告效果
	if animated_sprite:
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(animated_sprite, "modulate", Color.RED, 0.05)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)

func _extend_spikes() -> void:
	_is_extended = true
	is_active = true
	
	# 动画伸出
	var tween = create_tween()
	tween.tween_property(self, "position", _extended_position, 0.1)
	tween.tween_callback(func(): _current_phase = "extending"; _state_timer = 0.01)
	
	# 播放伸出动画
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("extend"):
			animated_sprite.play("extend")

func _retract_spikes() -> void:
	_is_extended = false
	is_active = false
	
	# 动画收回
	var tween = create_tween()
	tween.tween_property(self, "position", _base_position, 0.15)
	tween.tween_callback(func(): _current_phase = "retracting"; _state_timer = 0.01)
	
	# 播放收回动画
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("retract"):
			animated_sprite.play("retract")

func _set_extended(extended: bool) -> void:
	_is_extended = extended
	is_active = extended
	
	if extended:
		position = _extended_position if _extended_position else _base_position
		if animated_sprite and animated_sprite.sprite_frames:
			if animated_sprite.sprite_frames.has_animation("extended"):
				animated_sprite.play("extended")
	else:
		position = _base_position
		if animated_sprite and animated_sprite.sprite_frames:
			if animated_sprite.sprite_frames.has_animation("retracted"):
				animated_sprite.play("retracted")

## 外部触发（用于 TRIGGERED 类型）
func trigger() -> void:
	if spike_type != SpikeType.TRIGGERED:
		return
	
	if _is_extended:
		return
	
	_extend_spikes()
	
	# 一段时间后收回
	await get_tree().create_timer(extend_time).timeout
	_retract_spikes()

func _on_reset() -> void:
	_state_timer = initial_delay
	_current_phase = "retracted"
	_set_extended(spike_type == SpikeType.STATIC)

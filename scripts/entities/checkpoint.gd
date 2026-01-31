class_name Checkpoint
extends Area2D

## 检查点系统
## 玩家触碰后激活，死亡时从最近的激活检查点重生

# 信号
signal activated(checkpoint: Node)

# 导出变量
@export var checkpoint_id: String = ""  # 检查点ID，用于识别（留空则自动生成）
@export var checkpoint_order: int = 0  # 检查点顺序，用于排序
@export var spawn_offset: Vector2 = Vector2(0, -16)  # 重生位置偏移
@export var auto_activate: bool = false  # 是否自动激活（如关卡起点）
@export var one_time_only: bool = false  # 是否只能激活一次

# 状态
var is_active: bool = false

# 组件引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var particles: GPUParticles2D = $ActivationParticles if has_node("ActivationParticles") else null

func _ready() -> void:
	# 如果没有设置ID，自动生成
	if checkpoint_id == "":
		checkpoint_id = "checkpoint_%d" % get_instance_id()
	
	# 添加到检查点组
	add_to_group("checkpoint")
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	
	# 延迟注册到检查点管理器（等待 AutoLoad 初始化完成）
	call_deferred("_register_to_manager")
	
	# 如果是自动激活的检查点（如关卡起点）
	if auto_activate:
		_activate_checkpoint(true)
	else:
		_set_inactive_visual()

## 注册到检查点管理器
func _register_to_manager() -> void:
	var manager = get_node_or_null("/root/CheckpointManager")
	if manager:
		manager.register_checkpoint(self)

## 获取重生位置
func get_spawn_position() -> Vector2:
	return global_position + spawn_offset

## 激活检查点
func activate() -> void:
	if is_active and one_time_only:
		return
	_activate_checkpoint(false)

## 内部激活逻辑
func _activate_checkpoint(silent: bool = false) -> void:
	if is_active:
		return
	
	is_active = true
	
	# 更新视觉效果
	_set_active_visual()
	
	# 播放激活特效
	if not silent:
		_play_activation_effect()
	
	# 发射信号（CheckpointManager 会通过信号连接接收）
	activated.emit(self)
	
	print("[Checkpoint] 检查点 %s 已激活，位置: %s" % [checkpoint_id, global_position])

## 设置激活状态的视觉效果
func _set_active_visual() -> void:
	if animated_sprite:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("active"):
			animated_sprite.play("active")
		else:
			# 如果没有动画，使用颜色变化
			animated_sprite.modulate = Color(0.5, 1.0, 0.5)  # 绿色表示激活

## 设置未激活状态的视觉效果
func _set_inactive_visual() -> void:
	if animated_sprite:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("inactive"):
			animated_sprite.play("inactive")
		else:
			# 如果没有动画，使用颜色变化
			animated_sprite.modulate = Color(0.5, 0.5, 0.5)  # 灰色表示未激活

## 播放激活特效
func _play_activation_effect() -> void:
	# 播放粒子效果
	if particles:
		particles.emitting = true
	
	# 播放音效
	if AudioManager:
		AudioManager.play_sfx("power_up")
	
	# 播放缩放动画
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "scale", Vector2(1.3, 1.3), 0.15)
		tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.15)

## 当物体进入检查点区域
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		activate()

## 重置检查点状态（用于关卡重置）
func reset() -> void:
	is_active = false
	_set_inactive_visual()

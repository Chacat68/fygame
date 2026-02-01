# 收集品基类
# 提供所有收集品的通用功能
class_name CollectibleBase
extends Area2D

# 信号
signal collected(collectible: Node, player: Node)

# 导出变量
@export_group("收集品属性")
@export var collectible_id: String = ""  # 收集品ID
@export var value: int = 1  # 收集品价值
@export var auto_collect: bool = true  # 是否自动收集
@export var one_time_only: bool = true  # 是否只能收集一次
@export var respawn_time: float = 0.0  # 重生时间（0表示不重生）

@export_group("视觉效果")
@export var bob_enabled: bool = true  # 是否启用上下浮动
@export var bob_amplitude: float = 4.0  # 浮动幅度
@export var bob_speed: float = 2.0  # 浮动速度
@export var rotate_enabled: bool = false  # 是否旋转
@export var rotate_speed: float = 2.0  # 旋转速度
@export var particle_enabled: bool = true  # 是否启用粒子效果

# 状态
var is_collected: bool = false
var original_position: Vector2
var bob_offset: float = 0.0

# 组件引用
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var particles: GPUParticles2D = $Particles if has_node("Particles") else null

func _ready() -> void:
	# 生成ID
	if collectible_id == "":
		collectible_id = "collectible_%d" % get_instance_id()
	
	original_position = global_position
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	
	# 注册到收集品管理器
	_register_to_manager()

## 注册到管理器（子类可覆盖）
func _register_to_manager() -> void:
	pass  # 子类实现

func _process(delta: float) -> void:
	if is_collected:
		return
	
	# 浮动效果
	if bob_enabled:
		bob_offset += delta * bob_speed
		var bob_y = sin(bob_offset * TAU) * bob_amplitude
		global_position.y = original_position.y + bob_y
	
	# 旋转效果
	if rotate_enabled:
		if sprite:
			sprite.rotation += delta * rotate_speed
		elif animated_sprite:
			animated_sprite.rotation += delta * rotate_speed

## 当玩家进入区域
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and auto_collect:
		collect(body)

## 收集
func collect(player: Node) -> void:
	if is_collected and one_time_only:
		return
	
	is_collected = true
	
	# 应用收集效果
	_apply_collection_effect(player)
	
	# 播放收集动画
	_play_collect_animation()
	
	# 播放音效
	_play_collect_sound()
	
	# 显示收集文本
	_show_collect_text()
	
	# 发射信号
	collected.emit(self, player)
	
	# 处理重生或销毁
	if respawn_time > 0:
		_start_respawn_timer()
	else:
		await _play_collect_animation()
		queue_free()

## 应用收集效果（子类覆盖）
func _apply_collection_effect(_player: Node) -> void:
	pass

## 播放收集动画
func _play_collect_animation() -> void:
	# 禁用碰撞
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# 播放粒子效果
	if particles and particle_enabled:
		particles.emitting = true
	
	# 收集动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished

## 播放收集音效（子类可覆盖）
func _play_collect_sound() -> void:
	if AudioManager:
		AudioManager.play_sfx("coin")

## 显示收集文本（子类可覆盖）
func _show_collect_text() -> void:
	pass

## 开始重生计时
func _start_respawn_timer() -> void:
	# 隐藏
	visible = false
	
	await get_tree().create_timer(respawn_time).timeout
	
	# 重生
	_respawn()

## 重生
func _respawn() -> void:
	is_collected = false
	visible = true
	scale = Vector2.ONE
	modulate.a = 1.0
	global_position = original_position
	
	if collision_shape:
		collision_shape.disabled = false

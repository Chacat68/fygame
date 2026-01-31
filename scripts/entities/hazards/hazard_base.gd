class_name HazardBase
extends Area2D

## 机关/陷阱基类
## 所有机关陷阱的父类，提供通用功能

# 信号
signal player_damaged(damage: int)
signal hazard_triggered

# 导出变量
@export_group("伤害设置")
@export var damage: int = 1  # 造成的伤害
@export var can_kill_instantly: bool = false  # 是否可以秒杀
@export var damage_cooldown: float = 0.5  # 伤害冷却时间

@export_group("状态设置")
@export var is_active: bool = true  # 机关是否激活
@export var one_shot: bool = false  # 是否只触发一次
@export var destroy_on_trigger: bool = false  # 触发后是否销毁

@export_group("视觉效果")
@export var flash_on_damage: bool = true  # 造成伤害时闪烁
@export var shake_screen: bool = false  # 是否震动屏幕

# 内部变量
var _can_damage: bool = true
var _has_triggered: bool = false
var _bodies_in_area: Array[Node2D] = []

# 组件引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var damage_timer: Timer = null

func _ready() -> void:
	# 添加到机关组
	add_to_group("hazard")
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 创建伤害冷却计时器
	_create_damage_timer()
	
	# 子类初始化
	_hazard_ready()

## 子类重写此方法进行初始化
func _hazard_ready() -> void:
	pass

## 创建伤害冷却计时器
func _create_damage_timer() -> void:
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_cooldown_finished)
	add_child(damage_timer)

## 物体进入区域
func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	
	if body.is_in_group("player"):
		_bodies_in_area.append(body)
		_try_damage_player(body)

## 物体离开区域
func _on_body_exited(body: Node2D) -> void:
	if body in _bodies_in_area:
		_bodies_in_area.erase(body)

## 尝试对玩家造成伤害
func _try_damage_player(player: Node2D) -> void:
	if not _can_damage or not is_active:
		return
	
	if one_shot and _has_triggered:
		return
	
	# 造成伤害
	_apply_damage(player)
	
	# 标记已触发
	_has_triggered = true
	hazard_triggered.emit()
	
	# 开始冷却
	_can_damage = false
	damage_timer.start()
	
	# 销毁检查
	if destroy_on_trigger:
		queue_free()

## 应用伤害
func _apply_damage(player: Node2D) -> void:
	if can_kill_instantly:
		if player.has_method("_die"):
			player._die()
		return
	
	if player.has_method("take_damage"):
		player.take_damage(damage)
		player_damaged.emit(damage)
		
		# 视觉效果
		if flash_on_damage:
			_play_damage_flash()
		
		if shake_screen:
			_shake_camera()

## 伤害冷却完成
func _on_damage_cooldown_finished() -> void:
	_can_damage = true
	
	# 检查是否有玩家仍在区域内
	for body in _bodies_in_area:
		if body.is_in_group("player"):
			_try_damage_player(body)
			break

## 播放伤害闪烁效果
func _play_damage_flash() -> void:
	if animated_sprite:
		# 简单的闪烁效果
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

## 震动摄像机
func _shake_camera() -> void:
	# 尝试找到摄像机并震动
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(0.2, 5)

## 激活机关
func activate() -> void:
	is_active = true
	_has_triggered = false
	_on_activated()

## 停用机关
func deactivate() -> void:
	is_active = false
	_on_deactivated()

## 子类重写 - 激活时调用
func _on_activated() -> void:
	pass

## 子类重写 - 停用时调用
func _on_deactivated() -> void:
	pass

## 重置机关状态
func reset() -> void:
	_has_triggered = false
	_can_damage = true
	is_active = true
	_on_reset()

## 子类重写 - 重置时调用
func _on_reset() -> void:
	pass

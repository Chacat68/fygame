class_name PressureSwitch
extends Area2D

## 压力开关
## 死亡细胞风格的地面开关，用于触发门和其他机关

# 信号
signal activated
signal deactivated
signal toggled(is_on: bool)

@export_group("开关设置")
@export var switch_id: String = ""  # 开关ID
@export var stay_activated: bool = false  # 是否保持激活状态
@export var require_weight: bool = false  # 是否需要重物（敌人尸体等）

@export_group("链接设置")
@export var linked_door_ids: Array[String] = []  # 链接的门ID

@export_group("视觉设置")
@export var pressed_color: Color = Color.GREEN
@export var unpressed_color: Color = Color.RED

# 状态
var is_on: bool = false
var _bodies_on_switch: Array[Node2D] = []

# 组件引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready() -> void:
	add_to_group("switch")
	
	if switch_id == "":
		switch_id = "switch_%d" % get_instance_id()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_update_visual()

func _on_body_entered(body: Node2D) -> void:
	if require_weight and not _is_valid_weight(body):
		return
	
	if body not in _bodies_on_switch:
		_bodies_on_switch.append(body)
	
	if not is_on:
		_activate()

func _on_body_exited(body: Node2D) -> void:
	if body in _bodies_on_switch:
		_bodies_on_switch.erase(body)
	
	if not stay_activated and _bodies_on_switch.is_empty():
		_deactivate()

func _is_valid_weight(body: Node2D) -> bool:
	# 玩家、敌人、可推动物体都算有效重量
	return body.is_in_group("player") or body.is_in_group("enemy") or body.is_in_group("pushable")

func _activate() -> void:
	is_on = true
	activated.emit()
	toggled.emit(true)
	
	# 触发链接的门
	_trigger_linked_doors()
	
	_update_visual()
	_play_activate_effect()

func _deactivate() -> void:
	is_on = false
	deactivated.emit()
	toggled.emit(false)
	
	# 触发链接的门
	_trigger_linked_doors()
	
	_update_visual()

func _trigger_linked_doors() -> void:
	for door_id in linked_door_ids:
		var doors = get_tree().get_nodes_in_group("door")
		for door in doors:
			if door.has_method("toggle_door") and door.door_id == door_id:
				door.toggle_door()

func _update_visual() -> void:
	if animated_sprite:
		animated_sprite.modulate = pressed_color if is_on else unpressed_color
		
		if animated_sprite.sprite_frames:
			if is_on and animated_sprite.sprite_frames.has_animation("pressed"):
				animated_sprite.play("pressed")
			elif not is_on and animated_sprite.sprite_frames.has_animation("unpressed"):
				animated_sprite.play("unpressed")

func _play_activate_effect() -> void:
	# 压下动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

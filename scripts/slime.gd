extends Node2D

# 移动属性
const SPEED = 60

# 状态变量
var direction = 1

# 组件引用
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

# 每一帧都会调用此函数。'delta' 是自上一帧以来的经过时间。
func _process(delta):
	_check_direction()
	_move(delta)

# 检查并更新移动方向
func _check_direction():
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

# 根据当前方向移动
func _move(delta):
	position.x += direction * SPEED * delta

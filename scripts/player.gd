extends CharacterBody2D

# 角色属性常量
const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS = 2  # 最大跳跃次数（包括第一次跳跃）

# 状态变量
var jumps_made = 0   # 已经跳跃的次数
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 组件引用
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_update_animation()
	move_and_slide()

# 应用重力
func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 当角色着地时重置跳跃计数
		jumps_made = 0

# 处理跳跃逻辑
func _handle_jump():
	if Input.is_action_just_pressed("jump") and (is_on_floor() or jumps_made < MAX_JUMPS):
		velocity.y = JUMP_VELOCITY
		jumps_made += 1

# 处理水平移动
func _handle_movement():
	var direction = Input.get_axis("move_left", "move_right")
	
	# 翻转精灵
	if direction != 0:
		animated_sprite.flip_h = (direction < 0)
	
	# 应用移动
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

# 更新动画状态
func _update_animation():
	if not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")

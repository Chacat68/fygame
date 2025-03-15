extends CharacterBody2D

# 定义角色的移动速度和跳跃速度
const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# 连跳相关变量
const MAX_JUMPS = 2  # 最大跳跃次数（包括第一次跳跃）
var jumps_made = 0   # 已经跳跃的次数

# 从项目设置中获取重力值，以与RigidBody节点同步。
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 获取AnimatedSprite2D节点
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# 如果角色不在地面上，添加重力。
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 当角色着地时重置跳跃计数
		jumps_made = 0

	# 处理跳跃。
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jumps_made < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jumps_made += 1
 
	# 获取输入方向： -1,0,1
	var direction = Input.get_axis("move_left", "move_right") 
	
	# 翻转精灵
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# 播放动画
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# 应用移动
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 执行移动和滑动
	move_and_slide()

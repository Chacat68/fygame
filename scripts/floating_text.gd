extends Node2D

# 文本标签引用
@onready var label = $Label

# 游戏配置
var config: GameConfig

# 动画参数（从配置文件加载）
var initial_velocity: Vector2
var max_velocity: Vector2
var fade_duration: float
var elapsed_time = 0.0
var pending_text = "金币+1"              # 默认文本
var acceleration = 1.2                  # 加速系数
var max_distance = 80.0                 # 最大上升距离（像素）
var total_distance = 0.0                # 已上升的总距离

# 初始化函数
func _ready():
	# 初始化配置
	_init_config()
	
	# 设置初始透明度
	modulate.a = 1.0
	
	# 如果有待设置的文本，现在设置它
	if label and pending_text:
		label.text = pending_text

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()
	
	# 设置动画参数
	initial_velocity = Vector2(0, -config.floating_text_speed * 0.3)
	max_velocity = Vector2(0, -config.floating_text_speed)
	fade_duration = config.floating_text_fade_duration

# 设置显示的文本
func set_text(text):
	pending_text = text
	# 如果Label已经准备好，立即设置文本
	if label:
		label.text = text

# 每帧更新
func _process(delta):
	# 计算当前进度（0.0到1.0之间）
	var progress = elapsed_time / fade_duration
	
	# 如果已经达到最大距离，则不再上升
	if total_distance < max_distance:
		# 计算当前速度（开始慢，然后加速）
		var current_velocity = initial_velocity.lerp(max_velocity, min(1.0, progress * acceleration))
		
		# 计算本帧移动的距离
		var frame_distance = -current_velocity.y * delta  # 取负值因为向上是负Y
		
		# 确保不超过最大距离
		var remaining_distance = max_distance - total_distance
		if frame_distance > remaining_distance:
			frame_distance = remaining_distance
			
		# 更新位置
		position.y -= frame_distance
		
		# 累计已移动的距离
		total_distance += frame_distance
	else:
		# 已达到最大距离，加快淡出速度
		progress = min(1.0, progress * 1.8)
	
	# 更新计时器
	elapsed_time += delta
	
	# 计算淡出效果（开始缓慢淡出，后期快速淡出）
	var alpha = 1.0 - pow(progress, 2)  # 使用平方函数使后期淡出更快
	modulate.a = alpha
	
	# 当完全淡出后，移除节点
	if elapsed_time >= fade_duration or alpha <= 0.05:
		queue_free()

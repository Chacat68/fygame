extends Node2D

# 文本标签引用
@onready var label = $Label

# 游戏配置（缓存以避免重复访问）
static var cached_config: GameConfig

# 动画参数（预计算以提高性能）
var initial_velocity: Vector2
var max_velocity: Vector2
var fade_duration: float
var elapsed_time = 0.0
var pending_text = "金币+1"              # 默认文本
var acceleration = 1.2                  # 加速系数
var max_distance = 80.0                 # 最大上升距离（像素）
var total_distance = 0.0                # 已上升的总距离

# 排列相关参数
var horizontal_offset = 0.0             # 水平偏移量
var stagger_delay = 0.0                 # 错开延迟时间
var is_delayed = false                  # 是否处于延迟状态

# 性能优化变量
var last_position: Vector2              # 缓存上一帧位置
var animation_finished = false          # 动画完成标志
var delay_timer: Timer                  # 复用计时器对象

# 初始化函数（优化版）
func _ready():
	# 初始化配置（使用缓存）
	_init_config_cached()
	
	# 设置初始状态
	modulate.a = 1.0
	last_position = position
	
	# 应用水平偏移
	position.x += horizontal_offset
	
	# 处理延迟显示
	if stagger_delay > 0.0:
		_setup_delayed_animation()
	else:
		# 立即开始动画
		_start_animation()
	
	# 设置文本
	if label and pending_text:
		label.text = pending_text

# 初始化配置（缓存优化）
func _init_config_cached():
	# 使用静态缓存避免重复加载配置
	if not cached_config:
		cached_config = GameConfig.get_config()
	
	# 预计算动画参数
	var base_speed = cached_config.floating_text_speed
	initial_velocity = Vector2(0, -base_speed * 0.3)
	max_velocity = Vector2(0, -base_speed)
	fade_duration = cached_config.floating_text_fade_duration

# 设置延迟动画
func _setup_delayed_animation():
	is_delayed = true
	modulate.a = 0.0
	
	# 复用计时器对象
	if not delay_timer:
		delay_timer = Timer.new()
		delay_timer.one_shot = true
		delay_timer.timeout.connect(_start_animation)
		add_child(delay_timer)
	
	delay_timer.wait_time = stagger_delay
	delay_timer.start()

# 设置显示的文本
func set_text(text):
	pending_text = text
	# 如果Label已经准备好，立即设置文本
	if label:
		label.text = text

# 设置排列参数
func set_arrangement(h_offset: float, delay: float):
	horizontal_offset = h_offset
	stagger_delay = delay

# 开始动画（延迟结束后调用）
func _start_animation():
	is_delayed = false
	modulate.a = 1.0
	elapsed_time = 0.0
	animation_finished = false

# 每帧更新（优化版）
func _process(delta):
	# 早期退出条件
	if is_delayed or animation_finished:
		return
	
	# 更新计时器
	elapsed_time += delta
	
	# 计算当前进度（0.0到1.0之间）
	var progress = elapsed_time / fade_duration
	
	# 位置更新（仅在未达到最大距离时）
	if total_distance < max_distance:
		_update_position(delta, progress)
	else:
		# 已达到最大距离，加快淡出速度
		progress = min(1.0, progress * 1.8)
	
	# 透明度更新
	_update_alpha(progress)
	
	# 检查动画完成
	if elapsed_time >= fade_duration or modulate.a <= 0.05:
		_finish_animation()

# 更新位置（分离逻辑以提高可读性和性能）
func _update_position(delta: float, progress: float):
	# 计算当前速度（开始慢，然后加速）
	var velocity_progress = min(1.0, progress * acceleration)
	var current_velocity = initial_velocity.lerp(max_velocity, velocity_progress)
	
	# 计算本帧移动的距离
	var frame_distance = -current_velocity.y * delta  # 取负值因为向上是负Y
	
	# 确保不超过最大距离
	var remaining_distance = max_distance - total_distance
	frame_distance = min(frame_distance, remaining_distance)
	
	# 更新位置（仅在有移动时进行像素对齐）
	if frame_distance > 0.0:
		position.y -= frame_distance
		# 像素对齐以避免字体模糊（仅在位置变化时）
		var new_position = Vector2(round(position.x), round(position.y))
		if new_position != last_position:
			position = new_position
			last_position = new_position
		
		# 累计已移动的距离
		total_distance += frame_distance

# 更新透明度
func _update_alpha(progress: float):
	# 使用平方函数使后期淡出更快
	var alpha = 1.0 - (progress * progress)
	modulate.a = alpha

# 完成动画
func _finish_animation():
	animation_finished = true
	queue_free()

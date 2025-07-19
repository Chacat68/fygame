extends Node

# 飘字管理器 - 负责协调多个飘字的排列和动画（性能优化版）
class_name FloatingTextManager

# 预加载飘字场景
var floating_text_scene = preload("res://scenes/managers/floating_text.tscn")

# 排列参数
var horizontal_spacing = 40.0           # 水平间距
var stagger_delay_interval = 0.1        # 错开延迟间隔
var max_texts_per_row = 5               # 每排最大文字数量

# 当前活跃的飘字队列
var active_floating_texts = []

# 对象池优化
var floating_text_pool = []             # 可复用的飘字对象池
var max_pool_size = 20                  # 对象池最大大小
var cleanup_timer: Timer                # 定期清理计时器
var last_cleanup_time = 0.0             # 上次清理时间
var cleanup_interval = 2.0              # 清理间隔（秒）

# 单例实例
static var instance: FloatingTextManager

# 获取单例实例（优化版）
static func get_instance() -> FloatingTextManager:
	if not instance:
		instance = FloatingTextManager.new()
		# 将管理器添加到场景树中
		var game_root = Engine.get_main_loop().get_root().get_node_or_null("Game")
		if game_root:
			game_root.add_child(instance)
		else:
			Engine.get_main_loop().get_root().add_child(instance)
		
		# 初始化定期清理
		instance._setup_cleanup_timer()
	return instance

# 设置定期清理计时器
func _setup_cleanup_timer():
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = cleanup_interval
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_periodic_cleanup)
	add_child(cleanup_timer)

# 定期清理
func _periodic_cleanup():
	_cleanup_finished_texts()
	_cleanup_object_pool()

# 创建排列的飘字效果（对象池优化版）
func create_arranged_floating_text(base_position: Vector2, text: String, game_root: Node) -> void:
	# 获取或创建飘字实例
	var floating_text = _get_floating_text_from_pool()
	
	# 重置和配置飘字
	_configure_floating_text(floating_text, base_position, text)
	
	# 添加到游戏场景
	game_root.add_child(floating_text)
	
	# 添加到活跃列表
	active_floating_texts.append(floating_text)

# 从对象池获取飘字实例
func _get_floating_text_from_pool() -> Node2D:
	var floating_text: Node2D
	
	# 尝试从对象池获取
	if floating_text_pool.size() > 0:
		floating_text = floating_text_pool.pop_back()
		# 重置状态
		_reset_floating_text(floating_text)
	else:
		# 对象池为空，创建新实例
		floating_text = floating_text_scene.instantiate()
	
	return floating_text

# 配置飘字属性
func _configure_floating_text(floating_text: Node2D, base_position: Vector2, text: String):
	# 设置位置
	floating_text.global_position = base_position
	
	# 设置排列参数（直接显示，无偏移）
	floating_text.set_arrangement(0.0, 0.0)
	
	# 设置文本
	floating_text.pending_text = text
	floating_text.set_text(text)

# 重置飘字状态
func _reset_floating_text(floating_text: Node2D):
	# 重置基本属性
	floating_text.modulate.a = 1.0
	floating_text.elapsed_time = 0.0
	floating_text.total_distance = 0.0
	floating_text.is_delayed = false
	floating_text.animation_finished = false
	
	# 停止可能存在的计时器
	if floating_text.delay_timer and floating_text.delay_timer.is_inside_tree():
		floating_text.delay_timer.stop()

# 清理已完成的飘字（对象池优化版）
func _cleanup_finished_texts():
	for i in range(active_floating_texts.size() - 1, -1, -1):
		var text_node = active_floating_texts[i]
		if not is_instance_valid(text_node) or text_node.is_queued_for_deletion() or text_node.animation_finished:
			# 回收到对象池
			_recycle_floating_text(text_node)
			active_floating_texts.remove_at(i)

# 回收飘字到对象池
func _recycle_floating_text(floating_text: Node2D):
	if not is_instance_valid(floating_text):
		return
	
	# 从场景树中移除
	if floating_text.is_inside_tree():
		floating_text.get_parent().remove_child(floating_text)
	
	# 如果对象池未满，回收对象
	if floating_text_pool.size() < max_pool_size:
		floating_text_pool.append(floating_text)
	else:
		# 对象池已满，直接释放
		floating_text.queue_free()

# 清理对象池
func _cleanup_object_pool():
	# 移除无效的对象
	for i in range(floating_text_pool.size() - 1, -1, -1):
		var text_node = floating_text_pool[i]
		if not is_instance_valid(text_node):
			floating_text_pool.remove_at(i)
	
	# 如果对象池过大，释放一些对象
	while floating_text_pool.size() > max_pool_size:
		var text_node = floating_text_pool.pop_back()
		if is_instance_valid(text_node):
			text_node.queue_free()

# 清空所有飘字（优化版）
func clear_all_texts():
	# 回收活跃的飘字
	for text_node in active_floating_texts:
		if is_instance_valid(text_node):
			_recycle_floating_text(text_node)
	active_floating_texts.clear()
	
	# 清理对象池
	for text_node in floating_text_pool:
		if is_instance_valid(text_node):
			text_node.queue_free()
	floating_text_pool.clear()

# 关卡管理器
# 负责关卡的加载、切换和状态管理
class_name LevelManager
extends Node

# 信号定义
signal level_loaded(level_id: int)
signal level_completed(level_id: int, score: int)
signal level_failed(level_id: int)
signal level_changed(from_level: int, to_level: int)
signal level_load_error(level_id: int, error_message: String)

# 错误类型枚举
enum LoadError {
	NONE,
	CONFIG_NOT_FOUND,
	LEVEL_NOT_FOUND,
	LEVEL_LOCKED,
	SCENE_PATH_EMPTY,
	SCENE_LOAD_FAILED,
	SCENE_INSTANTIATE_FAILED
}

# 关卡配置
@export var level_config: LevelConfig

# 当前关卡信息
var current_level_id: int = 0
var current_level_scene: Node = null
var current_level_data: Dictionary = {}

# 关卡状态
var level_start_time: float = 0.0
var level_score: int = 0
var is_level_completed: bool = false
var is_loading_level: bool = false  # 防止重复加载关卡

# 性能监控
var performance_data: Dictionary = {}
var load_times: Array[float] = []

# 性能优化缓存
static var _config_cache: LevelConfig = null
static var _level_data_cache: Dictionary = {}
var _scene_cache: Dictionary = {}  # 场景预加载缓存
var _max_cached_scenes: int = 3  # 最大缓存场景数
var _preload_queue: Array[int] = []  # 预加载队列
var _last_validation_time: float = 0.0
var _validation_interval: float = 5.0  # 配置验证间隔（秒）

# 错误统计
var error_count: int = 0
var last_error: LoadError = LoadError.NONE

# 初始化
func _ready() -> void:
	# 将自己添加到关卡管理器组，方便其他脚本查找
	add_to_group("level_manager")
	
	_initialize_performance_monitoring()
	_load_and_validate_config_cached()
	_setup_preload_system()

# 初始化性能监控
func _initialize_performance_monitoring() -> void:
	performance_data = {
		"total_loads": 0,
		"successful_loads": 0,
		"failed_loads": 0,
		"average_load_time": 0.0,
		"last_load_time": 0.0
	}

# 加载和验证配置（使用缓存）
func _load_and_validate_config_cached() -> void:
	# 使用静态缓存避免重复加载
	if _config_cache and not level_config:
		level_config = _config_cache
		print("使用缓存的关卡配置")
		return
	
	# 如果没有配置，尝试加载默认配置
	if not level_config:
		if ResourceLoader.exists("res://resources/level_config.tres"):
			var config = load("res://resources/level_config.tres")
			level_config = config as LevelConfig
			if not level_config:
				push_error("关卡配置文件格式错误")
				return
			# 缓存配置
			_config_cache = level_config
		else:
			push_error("关卡配置文件不存在: res://resources/level_config.tres")
			return
	
	# 智能验证配置（避免频繁验证）
	if level_config and _should_validate_config():
		if level_config.has_method("validate_config"):
			if not level_config.validate_config():
				push_error("关卡配置验证失败")
				return
		else:
			print("警告：关卡配置缺少验证方法")
		
		_last_validation_time = Time.get_unix_time_from_system()
		print("关卡管理器初始化成功，共加载 %d 个关卡" % level_config.get_level_count())
	elif not level_config:
		push_error("关卡配置初始化失败")

# 设置预加载系统
func _setup_preload_system() -> void:
	if level_config and level_config.get_level_count() > 0:
		# 预加载前几个关卡
		for i in range(min(3, level_config.get_level_count())):
			_preload_queue.append(i + 1)
		_process_preload_queue()

# 检查是否需要验证配置
func _should_validate_config() -> bool:
	var current_time = Time.get_unix_time_from_system()
	return current_time - _last_validation_time > _validation_interval

# 处理预加载队列
func _process_preload_queue() -> void:
	if _preload_queue.is_empty():
		return
	
	var level_id = _preload_queue.pop_front()
	_preload_level_scene(level_id)
	
	# 继续处理队列（异步）
	if not _preload_queue.is_empty():
		get_tree().process_frame.connect(_process_preload_queue, CONNECT_ONE_SHOT)

# 预加载关卡场景
func _preload_level_scene(level_id: int) -> void:
	if _scene_cache.has(level_id) or _scene_cache.size() >= _max_cached_scenes:
		return
	
	var level_data = _get_level_data_cached(level_id)
	if level_data.is_empty():
		return
	
	var scene_path = level_data.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	
	# 异步加载场景
	var scene_resource = load(scene_path)
	if scene_resource:
		_scene_cache[level_id] = scene_resource
		print("预加载关卡场景: %s" % level_data.get("name", "未知关卡"))

# 获取缓存的关卡数据
func _get_level_data_cached(level_id: int) -> Dictionary:
	if _level_data_cache.has(level_id):
		return _level_data_cache[level_id]
	
	if not level_config:
		return {}
	
	var level_data = level_config.get_level_by_id(level_id)
	if not level_data.is_empty():
		_level_data_cache[level_id] = level_data
	
	return level_data

# 加载指定关卡
func load_level(level_id: int) -> bool:
	# 防止重复加载
	if is_loading_level:
		return false
	
	is_loading_level = true
	var start_time = Time.get_unix_time_from_system()
	performance_data["total_loads"] += 1
	
	# 验证配置
	var error_result = _validate_level_load_preconditions_cached(level_id)
	if error_result != LoadError.NONE:
		_handle_load_error(level_id, error_result)
		is_loading_level = false
		return false
	
	# 获取缓存的关卡数据
	var level_data = _get_level_data_cached(level_id)
	
	# 卸载当前关卡
	unload_current_level()
	
	# 优先使用缓存的场景
	var load_result = _load_level_scene_optimized(level_id, level_data)
	if not load_result.success:
		_handle_load_error(level_id, load_result.error)
		is_loading_level = false
		return false
	
	# 设置关卡
	_setup_level(level_id, level_data, load_result.scene)
	
	# 预加载下一关卡
	_queue_next_level_preload(level_id)
	
	# 记录性能数据
	var load_time = Time.get_unix_time_from_system() - start_time
	_record_load_performance(load_time, true)
	
	print("关卡加载成功: %s (耗时: %.3f秒)" % [level_data.get("name", "未知关卡"), load_time])
	is_loading_level = false
	return true

# 验证关卡加载前置条件（使用缓存）
func _validate_level_load_preconditions_cached(level_id: int) -> LoadError:
	if not level_config:
		return LoadError.CONFIG_NOT_FOUND
	
	# 检查关卡是否存在（使用缓存）
	var level_data = _get_level_data_cached(level_id)
	if level_data.is_empty():
		return LoadError.LEVEL_NOT_FOUND
	
	# 检查关卡是否解锁
	if not level_config.is_level_unlocked(level_id):
		return LoadError.LEVEL_LOCKED
	
	return LoadError.NONE

# 优化的关卡场景加载
func _load_level_scene_optimized(level_id: int, level_data: Dictionary) -> Dictionary:
	# 优先使用缓存的场景
	if _scene_cache.has(level_id):
		var cached_scene = _scene_cache[level_id]
		var scene_instance = cached_scene.instantiate()
		if scene_instance:
			print("使用缓存场景: %s" % level_data.get("name", "未知关卡"))
			return {"success": true, "scene": scene_instance}
	
	# 回退到常规加载
	return _load_level_scene_fallback(level_data)

# 回退场景加载方法
func _load_level_scene_fallback(level_data: Dictionary) -> Dictionary:
	var scene_path = level_data.get("scene_path", "")
	if scene_path.is_empty():
		return {"success": false, "error": LoadError.SCENE_PATH_EMPTY}
	
	# 验证场景文件是否存在
	if not ResourceLoader.exists(scene_path):
		return {"success": false, "error": LoadError.SCENE_LOAD_FAILED}
	
	# 加载场景资源
	var level_scene = load(scene_path)
	if not level_scene:
		return {"success": false, "error": LoadError.SCENE_LOAD_FAILED}
	
	# 实例化场景
	var scene_instance = level_scene.instantiate()
	if not scene_instance:
		return {"success": false, "error": LoadError.SCENE_INSTANTIATE_FAILED}
	
	return {"success": true, "scene": scene_instance}

# 设置关卡
func _setup_level(level_id: int, level_data: Dictionary, scene_instance: Node) -> void:
	# 检查场景树是否有效
	var tree = get_tree()
	if not tree or not tree.current_scene:
		print("[LevelManager] 错误：场景树或当前场景无效，无法设置关卡")
		return
	
	# 添加到场景树
	tree.current_scene.add_child(scene_instance)
	current_level_scene = scene_instance
	
	# 更新关卡信息
	var old_level_id = current_level_id
	current_level_id = level_id
	current_level_data = level_data
	level_start_time = Time.get_unix_time_from_system()
	level_score = 0
	is_level_completed = false
	
	# 发送信号
	level_loaded.emit(level_id)
	if old_level_id != 0:
		level_changed.emit(old_level_id, level_id)

# 处理加载错误
func _handle_load_error(level_id: int, error: LoadError) -> void:
	last_error = error
	error_count += 1
	performance_data["failed_loads"] += 1
	
	var error_message = _get_error_message(error)
	push_error("关卡加载失败 (ID: %d): %s" % [level_id, error_message])
	level_load_error.emit(level_id, error_message)

# 获取错误信息
func _get_error_message(error: LoadError) -> String:
	match error:
		LoadError.CONFIG_NOT_FOUND:
			return "关卡配置未初始化"
		LoadError.LEVEL_NOT_FOUND:
			return "关卡不存在"
		LoadError.LEVEL_LOCKED:
			return "关卡未解锁"
		LoadError.SCENE_PATH_EMPTY:
			return "关卡场景路径为空"
		LoadError.SCENE_LOAD_FAILED:
			return "无法加载关卡场景文件"
		LoadError.SCENE_INSTANTIATE_FAILED:
			return "无法实例化关卡场景"
		_:
			return "未知错误"

# 记录加载性能
func _record_load_performance(load_time: float, success: bool) -> void:
	load_times.append(load_time)
	performance_data["last_load_time"] = load_time
	
	if success:
		performance_data["successful_loads"] += 1
	
	# 计算平均加载时间
	if load_times.size() > 0:
		var total_time = 0.0
		for time in load_times:
			total_time += time
		performance_data["average_load_time"] = total_time / load_times.size()
	
	# 保持最近10次的加载时间记录
	if load_times.size() > 10:
		load_times = load_times.slice(-10)

# 预加载下一关卡队列
func _queue_next_level_preload(current_level_id: int) -> void:
	var next_level_id = current_level_id + 1
	if level_config and next_level_id <= level_config.get_level_count():
		if not _scene_cache.has(next_level_id) and not _preload_queue.has(next_level_id):
			_preload_queue.append(next_level_id)
			# 异步处理预加载
			get_tree().process_frame.connect(_process_preload_queue, CONNECT_ONE_SHOT)

# 优化的缓存清理
func _cleanup_scene_cache() -> void:
	if _scene_cache.size() <= _max_cached_scenes:
		return
	
	# 移除最旧的缓存（简单LRU策略）
	var keys_to_remove = []
	var current_keys = _scene_cache.keys()
	var remove_count = _scene_cache.size() - _max_cached_scenes
	
	for i in range(remove_count):
		if i < current_keys.size():
			keys_to_remove.append(current_keys[i])
	
	for key in keys_to_remove:
		_scene_cache.erase(key)
		print("清理缓存场景: %d" % key)

# 卸载当前关卡
func unload_current_level() -> void:
	if current_level_scene:
		current_level_scene.queue_free()
		current_level_scene = null
	
	current_level_id = 0
	current_level_data = {}
	level_start_time = 0.0
	level_score = 0
	is_level_completed = false
	
	# 清理过多的缓存
	_cleanup_scene_cache()

# 完成当前关卡
func complete_level(score: int = 0) -> void:
	if current_level_id == 0:
		print("警告：没有活动关卡可以完成")
		return
	
	if is_level_completed:
		print("警告：关卡已经完成")
		return

	is_level_completed = true
	level_score = score
	
	# 更新关卡进度
	if current_level_id >= level_config.current_level:
		level_config.current_level = current_level_id + 1
	
	# 发送完成信号
	level_completed.emit(current_level_id, score)
	
	print("关卡完成: ", current_level_data.get("name", "未知关卡"), " 分数: ", score)

# 关卡失败
func fail_level() -> void:
	if current_level_id == 0:
		print("警告：没有活动关卡可以失败")
		return
	
	# 发送失败信号
	level_failed.emit(current_level_id)
	
	print("关卡失败: ", current_level_data.get("name", "未知关卡"))

# 重新开始当前关卡
func restart_level() -> bool:
	if current_level_id == 0:
		print("警告：没有活动关卡可以重新开始")
		return false
	
	var level_id = current_level_id
	return load_level(level_id)

# 加载下一关卡
func load_next_level() -> bool:
	if current_level_id == 0:
		print("警告：没有当前关卡")
		return false
	
	var next_level_id = current_level_id + 1
	return load_level(next_level_id)

# 加载上一关卡
func load_previous_level() -> bool:
	if current_level_id <= 1:
		print("警告：已经是第一关")
		return false
	
	var prev_level_id = current_level_id - 1
	return load_level(prev_level_id)

# 获取当前关卡信息
func get_current_level_info() -> Dictionary:
	return current_level_data.duplicate()

# 获取当前关卡ID
func get_current_level_id() -> int:
	return current_level_id

# 获取当前关卡名称
func get_current_level_name() -> String:
	return current_level_data.get("name", "未知关卡")

# 获取关卡游戏时间
func get_level_play_time() -> float:
	if level_start_time == 0.0:
		return 0.0
	return Time.get_unix_time_from_system() - level_start_time

# 获取关卡列表
func get_level_list() -> Array[Dictionary]:
	if not level_config:
		return []
	return level_config.levels.duplicate()

# 检查关卡是否解锁
func is_level_unlocked(level_id: int) -> bool:
	if not level_config:
		return false
	return level_config.is_level_unlocked(level_id)

# 获取可用关卡数量
func get_available_level_count() -> int:
	if not level_config:
		return 0
	return level_config.get_level_count()

# 添加分数
func add_score(points: int) -> void:
	level_score += points

# 获取当前分数
func get_current_score() -> int:
	return level_score

# 检查是否达到目标分数
func is_target_score_reached() -> bool:
	var target = current_level_data.get("target_score", 0)
	if target == 0:
		return true  # 没有目标分数要求
	return level_score >= target

# 检查是否超时
func is_time_limit_exceeded() -> bool:
	var time_limit = current_level_data.get("time_limit", 0)
	if time_limit == 0:
		return false  # 没有时间限制
	return get_level_play_time() > time_limit

# 进入下一关
func next_level() -> bool:
	var next_level_id = current_level_id + 1
	
	# 检查下一关是否存在
	if not level_config or next_level_id >= level_config.get_level_count():
		print("[LevelManager] 已经是最后一关")
		level_load_error.emit(next_level_id, "没有更多关卡")
		return false
	
	# 检查下一关是否解锁
	if not is_level_unlocked(next_level_id):
		print("[LevelManager] 下一关尚未解锁：", next_level_id)
		level_load_error.emit(next_level_id, "关卡尚未解锁")
		return false
	
	# 加载下一关
	return load_level(next_level_id)

extends Node

# 资源管理器类
# 注意：此类不应使用class_name，因为它被用作AutoLoad单例
# 用于集中管理游戏中的所有资源预加载
# 避免在各个脚本中分散加载资源

# 信号
signal resource_loaded(resource_name: String, resource_type: String)
signal resource_load_failed(resource_name: String, error_message: String)
signal cache_cleared()

# 资源类型枚举
enum ResourceType {
	SOUND,
	MUSIC,
	SPRITE,
	SCENE,
	OTHER
}

# 资源优先级枚举
enum ResourcePriority {
	CRITICAL,  # 游戏启动必需的资源
	HIGH,      # 游戏核心功能资源
	MEDIUM,    # 常用资源
	LOW        # 可延迟加载的资源
}

# 只预加载关键资源，其他资源按需加载
var critical_sounds = {
	"jump": preload("res://assets/sounds/jump.wav"),
	"hurt": preload("res://assets/sounds/hurt.wav")
}

var critical_sprites = {
	"knight": preload("res://assets/sprites/knight.png")
}

# 资源路径配置（按需加载）
var resource_paths = {
	# 音效资源路径
	"sounds": {
		"coin": "res://assets/sounds/coin.wav",
		"power_up": "res://assets/sounds/power_up.wav",
		"explosion": "res://assets/sounds/explosion.wav",
		"tap": "res://assets/sounds/tap.wav"
	},
	# 音乐资源路径
	"music": {
		"adventure": "res://assets/music/time_for_adventure.mp3"
	},
	# 精灵资源路径
	"sprites": {
		"coin": "res://assets/sprites/coin.png",
		"slime_green": "res://assets/sprites/slime_green.png",
		"slime_purple": "res://assets/sprites/slime_purple.png",
		"platforms": "res://assets/sprites/platforms.png",
		"world_tileset": "res://assets/sprites/world_tileset.png",
		"fruit": "res://assets/sprites/fruit.png",
		"coin_icon": "res://assets/sprites/coin_icon.png"
	},
	# 场景资源路径
	"scenes": {
		"coin": "res://scenes/entities/coin.tscn",
		"slime": "res://scenes/entities/slime.tscn",
		"platform": "res://scenes/entities/platform.tscn",
		"floating_text": "res://scenes/managers/floating_text.tscn"
	}
}

# 资源优先级配置
var resource_priorities = {
	"jump": ResourcePriority.CRITICAL,
	"hurt": ResourcePriority.CRITICAL,
	"knight": ResourcePriority.CRITICAL,
	"coin": ResourcePriority.HIGH,
	"slime_green": ResourcePriority.HIGH,
	"platforms": ResourcePriority.MEDIUM,
	"adventure": ResourcePriority.LOW
}

# 保留原有变量以兼容现有代码
var sounds = {}
var music = {}
var sprites = {}
var scenes = {}

# 动态资源缓存
var resource_cache: Dictionary = {}
var loading_queue: Array[Dictionary] = []
var is_loading: bool = false

# 性能监控
var performance_stats = {
	"total_loads": 0,
	"cache_hits": 0,
	"cache_misses": 0,
	"failed_loads": 0,
	"memory_usage": 0,
	"last_cleanup_time": 0
}

# 缓存配置
var max_cache_size: int = 100
var cache_cleanup_interval: float = 300.0  # 5分钟
var memory_threshold_mb: float = 512.0

func _ready():
	_initialize_performance_monitoring()
	_start_cache_cleanup_timer()
	_initialize_critical_resources()
	_preload_high_priority_resources()

# 按名称加载资源（用于预加载）
func _load_resource_by_name(resource_name: String) -> void:
	# 确定资源类型和路径
	for type_key in resource_paths:
		if resource_paths[type_key].has(resource_name):
			var resource_path = resource_paths[type_key][resource_name]
			var resource_type = _get_resource_type_from_key(type_key)
			load_resource_async(resource_path, resource_name, resource_type)
			break

func _initialize_performance_monitoring():
	performance_stats["last_cleanup_time"] = Time.get_unix_time_from_system()

func _start_cache_cleanup_timer():
	var timer = Timer.new()
	timer.wait_time = cache_cleanup_interval
	timer.timeout.connect(_cleanup_cache)
	timer.autostart = true
	add_child(timer)

# 获取音效资源
func get_sound(sound_name: String) -> AudioStream:
	return _get_resource(sound_name, ResourceType.SOUND, sounds)

# 获取音乐资源
func get_music(music_name: String) -> AudioStream:
	return _get_resource(music_name, ResourceType.MUSIC, music)

# 获取精灵资源
func get_sprite(sprite_name: String) -> Texture2D:
	return _get_resource(sprite_name, ResourceType.SPRITE, sprites)

# 获取场景资源
func get_scene(scene_name: String) -> PackedScene:
	return _get_resource(scene_name, ResourceType.SCENE, scenes)

# 通用资源获取方法（优化版）
func _get_resource(resource_name: String, resource_type: ResourceType, resource_dict: Dictionary) -> Resource:
	# 首先检查预加载资源
	if resource_dict.has(resource_name):
		performance_stats["cache_hits"] += 1
		return resource_dict[resource_name]
	
	# 检查动态缓存
	var cache_key = "%s_%s" % [ResourceType.keys()[resource_type], resource_name]
	if resource_cache.has(cache_key):
		var cache_entry = resource_cache[cache_key]
		# 更新访问统计
		cache_entry["access_count"] += 1
		cache_entry["timestamp"] = Time.get_unix_time_from_system()
		performance_stats["cache_hits"] += 1
		return cache_entry["resource"]
	
	# 尝试按需加载资源
	var loaded_resource = _load_resource_on_demand(resource_name, resource_type)
	if loaded_resource:
		performance_stats["cache_misses"] += 1
		# 将资源添加到对应的字典中
		resource_dict[resource_name] = loaded_resource
		return loaded_resource
	
	# 资源加载失败
	performance_stats["cache_misses"] += 1
	performance_stats["failed_loads"] += 1
	
	var error_msg = "Resource not found: %s (type: %s)" % [resource_name, ResourceType.keys()[resource_type]]
	push_error(error_msg)
	resource_load_failed.emit(resource_name, error_msg)
	return null

# 按需加载资源
func _load_resource_on_demand(resource_name: String, resource_type: ResourceType) -> Resource:
	var type_key = ResourceType.keys()[resource_type].to_lower() + "s"
	
	# 检查资源路径配置
	if not resource_paths.has(type_key):
		var error_msg = "Resource type not configured: %s" % type_key
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		return null
	
	if not resource_paths[type_key].has(resource_name):
		var error_msg = "Resource name not found in configuration: %s" % resource_name
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		return null
	
	var resource_path = resource_paths[type_key][resource_name]
	
	# 检查文件是否存在
	if not ResourceLoader.exists(resource_path):
		var error_msg = "Resource file does not exist: %s" % resource_path
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		return null
	
	# 尝试加载资源
	var resource = load(resource_path)
	if not resource:
		var error_msg = "Failed to load resource from path: %s" % resource_path
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		return null
	
	performance_stats["total_loads"] += 1
	print("按需加载资源成功: %s" % resource_name)
	return resource



# 从类型键获取资源类型枚举
func _get_resource_type_from_key(type_key: String) -> ResourceType:
	match type_key:
		"sounds":
			return ResourceType.SOUND
		"music":
			return ResourceType.MUSIC
		"sprites":
			return ResourceType.SPRITE
		"scenes":
			return ResourceType.SCENE
		_:
			return ResourceType.OTHER

# 异步加载资源
func load_resource_async(resource_path: String, resource_name: String, resource_type: ResourceType, options: Dictionary = {}) -> void:
	# 增强的参数验证
	if typeof(resource_path) != TYPE_STRING or resource_path.is_empty():
		var error_msg = "无效的资源路径: %s" % str(resource_path)
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		_send_user_notification("资源加载错误", "资源路径无效", "error")
		return
	
	if typeof(resource_name) != TYPE_STRING or resource_name.is_empty():
		var error_msg = "无效的资源名称: %s (路径: %s)" % [str(resource_name), resource_path]
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		_send_user_notification("资源加载错误", "资源名称无效", "error")
		return
	
	# 检查文件是否存在
	if not ResourceLoader.exists(resource_path):
		var error_msg = "资源文件不存在: %s" % resource_path
		push_error(error_msg)
		resource_load_failed.emit(resource_name, error_msg)
		_send_user_notification("资源加载错误", "找不到资源文件: %s" % resource_path.get_file(), "error")
		return
	
	# 检查资源是否已在缓存中
	var cache_key = "%s_%s" % [ResourceType.keys()[resource_type], resource_name]
	if resource_cache.has(cache_key):
		print("资源已在缓存中: %s" % resource_name)
		_send_user_notification("资源加载", "资源 %s 已缓存" % resource_name, "info")
		return
	
	# 检查资源是否已在加载队列中
	for request in loading_queue:
		if request.name == resource_name and request.type == resource_type:
			print("资源已在加载队列中: %s" % resource_name)
			return
	
	var load_request = {
		"path": resource_path,
		"name": resource_name,
		"type": resource_type,
		"timestamp": Time.get_unix_time_from_system(),
		"retry_count": 0,
		"max_retries": options.get("max_retries", 3),
		"priority": options.get("priority", ResourcePriority.MEDIUM)
	}
	
	loading_queue.append(load_request)
	print("添加资源到加载队列: %s (类型: %s)" % [resource_name, ResourceType.keys()[resource_type]])
	_process_loading_queue()

# 处理加载队列
func _process_loading_queue() -> void:
	if is_loading or loading_queue.is_empty():
		return
	
	is_loading = true
	var request = loading_queue.pop_front()
	
	# 检查资源是否存在
	if not ResourceLoader.exists(request.path):
		var error_msg = "Resource file not found: %s" % request.path
		push_error(error_msg)
		resource_load_failed.emit(request.name, error_msg)
		performance_stats["failed_loads"] += 1
		is_loading = false
		_process_loading_queue()  # 继续处理队列
		return
	
	# 异步加载资源
	ResourceLoader.load_threaded_request(request.path)
	_wait_for_resource_load(request)

# 等待资源加载完成
func _wait_for_resource_load(request: Dictionary) -> void:
	# 记录加载开始时间
	request["load_start_time"] = Time.get_unix_time_from_system()
	
	var load_timer = Timer.new()
	load_timer.wait_time = 0.1
	load_timer.timeout.connect(_check_load_progress.bind(request, load_timer))
	add_child(load_timer)
	load_timer.start()

# 处理加载失败
func _handle_load_failure(request: Dictionary, error_reason: String) -> void:
	var retry_count = request.get("retry_count", 0)
	var max_retries = request.get("max_retries", 3)
	
	# 检查是否可以重试
	if retry_count < max_retries:
		request["retry_count"] = retry_count + 1
		var delay_time = pow(2, retry_count) * 0.5  # 指数退避：0.5s, 1s, 2s
		
		print("资源加载失败，%d秒后重试 (%d/%d): %s - %s" % [delay_time, retry_count + 1, max_retries, request.name, error_reason])
		
		# 延迟重试
		var retry_timer = Timer.new()
		retry_timer.wait_time = delay_time
		retry_timer.one_shot = true
		retry_timer.timeout.connect(_retry_load_resource.bind(request, retry_timer))
		add_child(retry_timer)
		retry_timer.start()
	else:
		# 重试次数用尽，最终失败
		var final_error_msg = "资源加载最终失败 (重试%d次): %s - %s" % [max_retries, request.name, error_reason]
		push_error(final_error_msg)
		resource_load_failed.emit(request.name, final_error_msg)
		performance_stats["failed_loads"] += 1
		
		# 发送用户友好的错误通知
		_send_user_notification("资源加载失败", "无法加载 %s，请检查文件是否存在" % request.name, "error")

# 重试加载资源
func _retry_load_resource(request: Dictionary, timer: Timer) -> void:
	timer.queue_free()
	
	# 重新检查文件是否存在
	if not ResourceLoader.exists(request.path):
		_handle_load_failure(request, "文件不存在")
		return
	
	# 重新开始异步加载
	ResourceLoader.load_threaded_request(request.path)
	_wait_for_resource_load(request)

# 发送用户通知
func _send_user_notification(title: String, message: String, type: String = "info") -> void:
	# 这里可以连接到UI系统显示通知
	# 目前只在控制台输出
	match type:
		"error":
			print("[错误] %s: %s" % [title, message])
		"warning":
			print("[警告] %s: %s" % [title, message])
		"success":
			print("[成功] %s: %s" % [title, message])
		_:
			print("[信息] %s: %s" % [title, message])
	
	# 如果有UI管理器，可以发送信号
	# if UIManager:
	#     UIManager.show_notification(title, message, type)

# 检查加载进度
func _check_load_progress(request: Dictionary, timer: Timer) -> void:
	var status = ResourceLoader.load_threaded_get_status(request.path)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(request.path)
			if resource:
				_cache_resource(request.name, request.type, resource)
				resource_loaded.emit(request.name, ResourceType.keys()[request.type])
				performance_stats["total_loads"] += 1
				print("资源加载成功: %s (类型: %s)" % [request.name, ResourceType.keys()[request.type]])
			else:
				_handle_load_failure(request, "资源加载返回空值")
			
			timer.queue_free()
			is_loading = false
			_process_loading_queue()
		
		ResourceLoader.THREAD_LOAD_FAILED:
			_handle_load_failure(request, "资源加载失败")
			timer.queue_free()
			is_loading = false
			_process_loading_queue()
		
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# 继续等待，但检查超时
			var current_time = Time.get_unix_time_from_system()
			var load_time = current_time - request.get("load_start_time", current_time)
			if load_time > 30.0:  # 30秒超时
				_handle_load_failure(request, "资源加载超时")
				timer.queue_free()
				is_loading = false
				_process_loading_queue()

# 缓存资源（优化版）
func _cache_resource(resource_name: String, resource_type: ResourceType, resource: Resource) -> void:
	var cache_key = "%s_%s" % [ResourceType.keys()[resource_type], resource_name]
	
	# 检查缓存大小限制
	if resource_cache.size() >= max_cache_size:
		_cleanup_old_cache_entries()
	
	# 添加时间戳和优先级信息
	var cache_entry = {
		"resource": resource,
		"timestamp": Time.get_unix_time_from_system(),
		"access_count": 1,
		"priority": resource_priorities.get(resource_name, ResourcePriority.MEDIUM)
	}
	
	resource_cache[cache_key] = cache_entry
	_update_memory_usage()
	
	# 同时添加到对应的主字典中以提高访问速度
	match resource_type:
		ResourceType.SOUND:
			sounds[resource_name] = resource
		ResourceType.MUSIC:
			music[resource_name] = resource
		ResourceType.SPRITE:
			sprites[resource_name] = resource
		ResourceType.SCENE:
			scenes[resource_name] = resource

# 清理旧的缓存条目（智能清理）
func _cleanup_old_cache_entries() -> void:
	var current_time = Time.get_unix_time_from_system()
	var entries_to_remove = []
	
	# 收集需要清理的条目（基于优先级和访问频率）
	for cache_key in resource_cache:
		var entry = resource_cache[cache_key]
		var age = current_time - entry.timestamp
		var priority = entry.priority
		var access_count = entry.access_count
		
		# 清理策略：低优先级且长时间未访问的资源
		var should_remove = false
		if priority == ResourcePriority.LOW and age > 600:  # 10分钟
			should_remove = true
		elif priority == ResourcePriority.MEDIUM and age > 1800 and access_count < 3:  # 30分钟且访问次数少
			should_remove = true
		elif age > 3600:  # 1小时以上的资源（除了关键资源）
			if priority != ResourcePriority.CRITICAL:
				should_remove = true
		
		if should_remove:
			entries_to_remove.append(cache_key)
	
	# 如果智能清理不够，强制清理一些条目
	if entries_to_remove.size() < resource_cache.size() / 4:
		# 按访问次数和时间排序，移除最少使用的
		var sorted_entries = []
		for cache_key in resource_cache:
			var entry = resource_cache[cache_key]
			if entry.priority != ResourcePriority.CRITICAL:
				sorted_entries.append({"key": cache_key, "score": entry.access_count * 1000 - (current_time - entry.timestamp)})
		
		sorted_entries.sort_custom(func(a, b): return a.score < b.score)
		
		# 移除评分最低的条目
		var additional_removals = min(10, sorted_entries.size())
		for i in range(additional_removals):
			entries_to_remove.append(sorted_entries[i].key)
	
	# 执行清理
	for key in entries_to_remove:
		resource_cache.erase(key)
	
	if entries_to_remove.size() > 0:
		print("缓存清理完成，移除了 %d 个条目" % entries_to_remove.size())

# 更新内存使用统计（增强版）
func _update_memory_usage() -> void:
	# 更精确的内存使用估算
	var total_memory = 0
	for cache_key in resource_cache:
		var entry = resource_cache[cache_key]
		var resource = entry.resource
		
		# 根据资源类型估算内存使用
		if resource is Texture2D:
			var texture = resource as Texture2D
			total_memory += texture.get_width() * texture.get_height() * 4  # RGBA
		elif resource is AudioStream:
			total_memory += 1024 * 1024  # 假设1MB音频
		elif resource is PackedScene:
			total_memory += 512 * 1024  # 假设512KB场景
		else:
			total_memory += 1024  # 默认1KB
	
	performance_stats["memory_usage"] = total_memory
	
	# 动态内存阈值管理
	var memory_threshold = 64 * 1024 * 1024  # 64MB基础阈值
	if OS.get_static_memory_usage_by_type().size() > 0:
		# 根据系统内存动态调整
		memory_threshold = min(memory_threshold * 2, 128 * 1024 * 1024)
	
	# 如果内存使用过高，触发清理
	if performance_stats["memory_usage"] > memory_threshold:
		print("内存使用过高 (%d MB)，触发缓存清理" % (performance_stats["memory_usage"] / 1024 / 1024))
		_cleanup_cache()

# 定期清理缓存
func _cleanup_cache() -> void:
	var current_time = Time.get_unix_time_from_system()
	var memory_mb = performance_stats["memory_usage"] / (1024.0 * 1024.0)
	
	# 如果内存使用超过阈值，清理缓存
	if memory_mb > memory_threshold_mb:
		resource_cache.clear()
		performance_stats["memory_usage"] = 0
		cache_cleared.emit()
		print("资源缓存已清理，释放内存: %.2f MB" % memory_mb)
	
	performance_stats["last_cleanup_time"] = current_time

# 初始化关键资源
func _initialize_critical_resources() -> void:
	print("开始初始化关键资源...")
	
	# 预加载关键音效
	for sound_name in critical_sounds:
		if critical_sounds[sound_name]:
			sounds[sound_name] = critical_sounds[sound_name]
	
	# 预加载关键精灵
	for sprite_name in critical_sprites:
		if critical_sprites[sprite_name]:
			sprites[sprite_name] = critical_sprites[sprite_name]
	
	print("关键资源初始化完成")

# 异步预加载高优先级资源
func _preload_high_priority_resources() -> void:
	print("开始异步预加载高优先级资源...")
	
	for resource_name in resource_priorities:
		var priority = resource_priorities[resource_name]
		if priority == ResourcePriority.HIGH:
			# 异步加载高优先级资源
			_load_resource_by_name(resource_name)
	
	print("高优先级资源预加载队列已启动")

# 获取资源类型从缓存键
func _get_resource_type_from_key(cache_key: String) -> ResourceType:
	if cache_key.begins_with("SOUND_"):
		return ResourceType.SOUND
	elif cache_key.begins_with("MUSIC_"):
		return ResourceType.MUSIC
	elif cache_key.begins_with("SPRITE_"):
		return ResourceType.SPRITE
	elif cache_key.begins_with("SCENE_"):
		return ResourceType.SCENE
	else:
		return ResourceType.SOUND  # 默认值

# 获取性能统计
func get_performance_stats() -> Dictionary:
	return performance_stats.duplicate()

# 预加载资源列表
func preload_resources(resource_list: Array[Dictionary]) -> void:
	if resource_list.is_empty():
		print("[警告] 预加载资源列表为空")
		return
	
	var valid_resources = []
	var invalid_resources = []
	
	# 验证所有资源信息
	for resource_info in resource_list:
		if not resource_info.has("path") or not resource_info.has("name") or not resource_info.has("type"):
			invalid_resources.append("缺少必要字段: %s" % str(resource_info))
			continue
			
		if resource_info.path.is_empty():
			invalid_resources.append("空路径: %s" % resource_info.name)
			continue
			
		if resource_info.name.is_empty():
			invalid_resources.append("空名称: %s" % resource_info.path)
			continue
			
		if not ResourceLoader.exists(resource_info.path):
			invalid_resources.append("文件不存在: %s" % resource_info.path)
			continue
			
		valid_resources.append(resource_info)
	
	# 报告验证结果
	if not invalid_resources.is_empty():
		var error_msg = "预加载验证发现 %d 个无效资源:\n%s" % [invalid_resources.size(), "\n".join(invalid_resources)]
		push_warning(error_msg)
		_send_user_notification("资源预加载警告", "发现 %d 个无效资源" % invalid_resources.size(), "warning")
	
	if valid_resources.is_empty():
		_send_user_notification("资源预加载失败", "没有有效的资源可以加载", "error")
		return
	
	# 开始预加载有效资源
	print("开始预加载 %d 个资源..." % valid_resources.size())
	_send_user_notification("资源预加载", "正在预加载 %d 个资源" % valid_resources.size(), "info")
	
	for resource_info in valid_resources:
		load_resource_async(resource_info.path, resource_info.name, resource_info.type)

# 清理指定类型的缓存
func clear_cache_by_type(resource_type: ResourceType) -> void:
	var type_prefix = ResourceType.keys()[resource_type] + "_"
	var keys_to_remove = []
	
	for key in resource_cache.keys():
		if key.begins_with(type_prefix):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		resource_cache.erase(key)
	
	_update_memory_usage()

# 注意：音频播放功能已迁移到AudioManager
# 请使用 AudioManager.play_sfx() 和 AudioManager.play_music() 来播放音频
# 此处保留音频资源获取功能以供AudioManager使用

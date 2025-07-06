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

# 预加载的核心资源
var sounds = {
	"jump": preload("res://assets/sounds/jump.wav"),
	"hurt": preload("res://assets/sounds/hurt.wav"),
	"coin": preload("res://assets/sounds/coin.wav"),
	"power_up": preload("res://assets/sounds/power_up.wav"),
	"explosion": preload("res://assets/sounds/explosion.wav"),
	"tap": preload("res://assets/sounds/tap.wav")
}

var music = {
	"adventure": preload("res://assets/music/time_for_adventure.mp3")
}

var sprites = {
	"knight": preload("res://assets/sprites/knight.png"),
	"coin": preload("res://assets/sprites/coin.png"),
	"slime_green": preload("res://assets/sprites/slime_green.png"),
	"slime_purple": preload("res://assets/sprites/slime_purple.png"),
	"platforms": preload("res://assets/sprites/platforms.png"),
	"world_tileset": preload("res://assets/sprites/world_tileset.png"),
	"fruit": preload("res://assets/sprites/fruit.png"),
	"coin_icon": preload("res://assets/sprites/coin_icon.png")
}

var scenes = {
	"coin": preload("res://scenes/entities/coin.tscn"),
	"slime": preload("res://scenes/entities/slime.tscn"),
	"platform": preload("res://scenes/entities/platform.tscn"),
	"floating_text": preload("res://scenes/managers/floating_text.tscn")
}

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

# 通用资源获取方法
func _get_resource(resource_name: String, resource_type: ResourceType, resource_dict: Dictionary) -> Resource:
	# 首先检查预加载资源
	if resource_dict.has(resource_name):
		performance_stats["cache_hits"] += 1
		return resource_dict[resource_name]
	
	# 检查动态缓存
	var cache_key = "%s_%s" % [ResourceType.keys()[resource_type], resource_name]
	if resource_cache.has(cache_key):
		performance_stats["cache_hits"] += 1
		return resource_cache[cache_key]
	
	# 缓存未命中
	performance_stats["cache_misses"] += 1
	performance_stats["failed_loads"] += 1
	
	var error_msg = "Resource not found: %s (type: %s)" % [resource_name, ResourceType.keys()[resource_type]]
	push_error(error_msg)
	resource_load_failed.emit(resource_name, error_msg)
	return null

# 异步加载资源
func load_resource_async(resource_path: String, resource_name: String, resource_type: ResourceType) -> void:
	var load_request = {
		"path": resource_path,
		"name": resource_name,
		"type": resource_type,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	loading_queue.append(load_request)
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
	var load_timer = Timer.new()
	load_timer.wait_time = 0.1
	load_timer.timeout.connect(_check_load_progress.bind(request, load_timer))
	add_child(load_timer)
	load_timer.start()

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
			else:
				var error_msg = "Failed to load resource: %s" % request.path
				push_error(error_msg)
				resource_load_failed.emit(request.name, error_msg)
				performance_stats["failed_loads"] += 1
			
			timer.queue_free()
			is_loading = false
			_process_loading_queue()
		
		ResourceLoader.THREAD_LOAD_FAILED:
			var error_msg = "Resource loading failed: %s" % request.path
			push_error(error_msg)
			resource_load_failed.emit(request.name, error_msg)
			performance_stats["failed_loads"] += 1
			
			timer.queue_free()
			is_loading = false
			_process_loading_queue()
		
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# 继续等待
			pass

# 缓存资源
func _cache_resource(resource_name: String, resource_type: ResourceType, resource: Resource) -> void:
	var cache_key = "%s_%s" % [ResourceType.keys()[resource_type], resource_name]
	
	# 检查缓存大小限制
	if resource_cache.size() >= max_cache_size:
		_cleanup_old_cache_entries()
	
	resource_cache[cache_key] = resource
	_update_memory_usage()

# 清理旧的缓存条目
func _cleanup_old_cache_entries() -> void:
	# 简单的LRU实现：移除一半的缓存
	# 使用显式整数转换避免类型转换警告
	var half_size = int(resource_cache.size() / 2.0)
	var keys_to_remove = resource_cache.keys().slice(0, half_size)
	for key in keys_to_remove:
		resource_cache.erase(key)

# 更新内存使用统计
func _update_memory_usage() -> void:
	# 简化的内存使用计算
	performance_stats["memory_usage"] = resource_cache.size() * 1024  # 假设每个资源1KB

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

# 获取性能统计
func get_performance_stats() -> Dictionary:
	return performance_stats.duplicate()

# 预加载资源列表
func preload_resources(resource_list: Array[Dictionary]) -> void:
	for resource_info in resource_list:
		if resource_info.has("path") and resource_info.has("name") and resource_info.has("type"):
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

# 播放音效的便捷方法
func play_sound(sound_name: String, parent_node: Node = null, volume_db: float = -10.0) -> AudioStreamPlayer:
	var sound = get_sound(sound_name)
	if sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = sound
		audio_player.volume_db = volume_db
		
		# 如果提供了父节点，添加到父节点
		if parent_node:
			parent_node.add_child(audio_player)
		else:
			# 否则添加到场景树的根节点
			var scene_tree = Engine.get_main_loop() as SceneTree
			if scene_tree:
				scene_tree.current_scene.add_child(audio_player)
		
		# 播放音效
		audio_player.play()
		
		# 设置音频播放完成后自动清理
		audio_player.finished.connect(func(): audio_player.queue_free())
		
		return audio_player
	return null

extends GutTest

# 资源管理器单元测试
# 测试优化后的资源缓存、异步加载和性能监控功能

# 预加载ResourceManager脚本
const ResourceManagerScript = preload("res://scripts/managers/resource_manager.gd")
var resource_manager: Node

func before_each():
	# 创建测试实例
	resource_manager = ResourceManagerScript.new()
	resource_manager._ready()  # 手动调用初始化

func after_each():
	if resource_manager:
		resource_manager.queue_free()
	resource_manager = null

func test_get_preloaded_sound():
	# 测试获取预加载的音效
	var sound = resource_manager.get_sound("jump")
	assert_not_null(sound, "应该能获取到jump音效")
	assert_true(sound is AudioStream, "返回的应该是AudioStream类型")
	
	# 验证缓存命中统计
	assert_eq(resource_manager.performance_stats["cache_hits"], 1, "缓存命中次数应该为1")

func test_get_nonexistent_sound():
	# 测试获取不存在的音效
	var sound = resource_manager.get_sound("nonexistent")
	assert_null(sound, "不存在的音效应该返回null")
	
	# 验证缓存未命中和失败统计
	assert_eq(resource_manager.performance_stats["cache_misses"], 1, "缓存未命中次数应该为1")
	assert_eq(resource_manager.performance_stats["failed_loads"], 1, "失败加载次数应该为1")

func test_get_preloaded_sprite():
	# 测试获取预加载的精灵
	var sprite = resource_manager.get_sprite("knight")
	assert_not_null(sprite, "应该能获取到knight精灵")
	assert_true(sprite is Texture2D, "返回的应该是Texture2D类型")

func test_get_preloaded_scene():
	# 测试获取预加载的场景
	var scene = resource_manager.get_scene("coin")
	assert_not_null(scene, "应该能获取到coin场景")
	assert_true(scene is PackedScene, "返回的应该是PackedScene类型")

func test_get_preloaded_music():
	# 测试获取预加载的音乐
	var music = resource_manager.get_music("adventure")
	assert_not_null(music, "应该能获取到adventure音乐")
	assert_true(music is AudioStream, "返回的应该是AudioStream类型")

func test_cache_key_generation():
	# 测试缓存键生成
	var sound1 = resource_manager.get_sound("jump")
	var sound2 = resource_manager.get_sound("jump")
	
	# 两次获取同一资源应该都成功
	assert_not_null(sound1, "第一次获取应该成功")
	assert_not_null(sound2, "第二次获取应该成功")
	assert_eq(sound1, sound2, "两次获取应该返回同一资源")
	
	# 验证缓存命中次数
	assert_eq(resource_manager.performance_stats["cache_hits"], 2, "应该有2次缓存命中")

func test_resource_type_differentiation():
	# 测试不同类型资源的区分
	var sound = resource_manager.get_sound("jump")
	var sprite = resource_manager.get_sprite("knight")
	var scene = resource_manager.get_scene("coin")
	var music = resource_manager.get_music("adventure")
	
	assert_not_null(sound, "音效应该存在")
	assert_not_null(sprite, "精灵应该存在")
	assert_not_null(scene, "场景应该存在")
	assert_not_null(music, "音乐应该存在")
	
	# 验证类型正确性
	assert_true(sound is AudioStream, "音效类型正确")
	assert_true(sprite is Texture2D, "精灵类型正确")
	assert_true(scene is PackedScene, "场景类型正确")
	assert_true(music is AudioStream, "音乐类型正确")

func test_performance_stats_initialization():
	# 测试性能统计初始化
	var stats = resource_manager.get_performance_stats()
	
	assert_true(stats.has("total_loads"), "应该有total_loads统计")
	assert_true(stats.has("cache_hits"), "应该有cache_hits统计")
	assert_true(stats.has("cache_misses"), "应该有cache_misses统计")
	assert_true(stats.has("failed_loads"), "应该有failed_loads统计")
	assert_true(stats.has("memory_usage"), "应该有memory_usage统计")
	assert_true(stats.has("last_cleanup_time"), "应该有last_cleanup_time统计")

func test_cache_management():
	# 测试缓存管理
	var initial_cache_size = resource_manager.resource_cache.size()
	
	# 模拟添加缓存项
	resource_manager._cache_resource("test_sound", resource_manager.ResourceType.SOUND, preload("res://assets/sounds/jump.wav"))
	
	assert_gt(resource_manager.resource_cache.size(), initial_cache_size, "缓存大小应该增加")
	
	# 验证缓存键格式
	var cache_key = "SOUND_test_sound"
	assert_true(resource_manager.resource_cache.has(cache_key), "应该存在正确的缓存键")

func test_memory_usage_tracking():
	# 测试内存使用跟踪
	var initial_memory = resource_manager.performance_stats["memory_usage"]
	
	# 添加一些缓存项
	resource_manager._cache_resource("test1", resource_manager.ResourceType.SOUND, preload("res://assets/sounds/jump.wav"))
	resource_manager._cache_resource("test2", resource_manager.ResourceType.SPRITE, preload("res://assets/sprites/knight.png"))
	
	assert_gt(resource_manager.performance_stats["memory_usage"], initial_memory, "内存使用应该增加")

func test_cache_cleanup_by_type():
	# 测试按类型清理缓存
	# 添加不同类型的缓存项
	resource_manager._cache_resource("test_sound", resource_manager.ResourceType.SOUND, preload("res://assets/sounds/jump.wav"))
	resource_manager._cache_resource("test_sprite", resource_manager.ResourceType.SPRITE, preload("res://assets/sprites/knight.png"))
	
	var initial_cache_size = resource_manager.resource_cache.size()
	assert_gt(initial_cache_size, 0, "缓存应该有内容")
	
	# 清理音效类型的缓存
	resource_manager.clear_cache_by_type(resource_manager.ResourceType.SOUND)
	
	# 验证只有音效缓存被清理
	assert_false(resource_manager.resource_cache.has("SOUND_test_sound"), "音效缓存应该被清理")
	assert_true(resource_manager.resource_cache.has("SPRITE_test_sprite"), "精灵缓存应该保留")

func test_async_loading_queue():
	# 测试异步加载队列
	var initial_queue_size = resource_manager.loading_queue.size()
	
	# 添加异步加载请求（使用不存在的路径进行测试）
	resource_manager.load_resource_async("res://test/nonexistent.wav", "test_async", resource_manager.ResourceType.SOUND)
	
	assert_gt(resource_manager.loading_queue.size(), initial_queue_size, "加载队列应该增加")

func test_signal_connections():
	# 测试信号连接
	var resource_loaded_fired = false
	var resource_load_failed_fired = false
	
	resource_manager.resource_loaded.connect(func(name, type):
		resource_loaded_fired = true
	)
	
	resource_manager.resource_load_failed.connect(func(name, error):
		resource_load_failed_fired = true
	)
	
	# 尝试加载不存在的资源
	resource_manager.load_resource_async("res://nonexistent.wav", "test", resource_manager.ResourceType.SOUND)
	
	# 等待一小段时间让异步处理完成
	await get_tree().create_timer(0.2).timeout
	
	assert_true(resource_load_failed_fired, "应该触发resource_load_failed信号")

func test_play_sound_convenience_method():
	# 测试播放音效的便捷方法
	var audio_player = resource_manager.play_sound("jump")
	
	assert_not_null(audio_player, "应该返回AudioStreamPlayer")
	assert_true(audio_player is AudioStreamPlayer, "返回的应该是AudioStreamPlayer类型")
	assert_not_null(audio_player.stream, "AudioStreamPlayer应该有音频流")
	
	# 清理
	if audio_player:
		audio_player.queue_free()

func test_play_nonexistent_sound():
	# 测试播放不存在的音效
	var audio_player = resource_manager.play_sound("nonexistent")
	
	assert_null(audio_player, "不存在的音效应该返回null")

func test_preload_resources_batch():
	# 测试批量预加载资源
	var resource_list = [
		{"path": "res://test1.wav", "name": "test1", "type": resource_manager.ResourceType.SOUND},
		{"path": "res://test2.png", "name": "test2", "type": resource_manager.ResourceType.SPRITE}
	]
	
	var initial_queue_size = resource_manager.loading_queue.size()
	resource_manager.preload_resources(resource_list)
	
	assert_eq(resource_manager.loading_queue.size(), initial_queue_size + 2, "加载队列应该增加2个项目")
extends GutTest

# 关卡管理器单元测试
# 测试优化后的关卡加载、错误处理和性能监控功能

var level_manager: LevelManager
var mock_level_config: LevelConfig

func before_each():
	# 创建测试实例
	level_manager = LevelManager.new()
	mock_level_config = LevelConfig.new()
	
	# 设置模拟数据
	_setup_mock_level_config()
	level_manager.level_config = mock_level_config

func after_each():
	if level_manager:
		level_manager.queue_free()
	level_manager = null
	mock_level_config = null

func _setup_mock_level_config():
	# 设置测试关卡数据
	mock_level_config.levels = [
		{
			"id": 1,
			"name": "测试关卡1",
			"scene_path": "res://scenes/levels/level_1.tscn",
			"unlocked": true,
			"completed": false
		},
		{
			"id": 2,
			"name": "测试关卡2",
			"scene_path": "res://scenes/levels/level_2.tscn",
			"unlocked": false,
			"completed": false
		}
	]
	mock_level_config.max_levels = 2

func test_load_level_success():
	# 测试成功加载关卡
	var result = level_manager.load_level(1)
	assert_true(result, "关卡应该成功加载")
	assert_eq(level_manager.current_level_id, 1, "当前关卡ID应该为1")
	assert_eq(level_manager.performance_data["total_loads"], 1, "总加载次数应该为1")

func test_load_nonexistent_level():
	# 测试加载不存在的关卡
	var result = level_manager.load_level(999)
	assert_false(result, "不存在的关卡应该加载失败")
	assert_eq(level_manager.last_error, LevelManager.LoadError.LEVEL_NOT_FOUND, "错误类型应该为LEVEL_NOT_FOUND")
	assert_eq(level_manager.error_count, 1, "错误计数应该为1")

func test_load_locked_level():
	# 测试加载锁定的关卡
	var result = level_manager.load_level(2)
	assert_false(result, "锁定的关卡应该加载失败")
	assert_eq(level_manager.last_error, LevelManager.LoadError.LEVEL_LOCKED, "错误类型应该为LEVEL_LOCKED")

func test_load_level_without_config():
	# 测试没有配置时加载关卡
	level_manager.level_config = null
	var result = level_manager.load_level(1)
	assert_false(result, "没有配置时应该加载失败")
	assert_eq(level_manager.last_error, LevelManager.LoadError.CONFIG_NOT_FOUND, "错误类型应该为CONFIG_NOT_FOUND")

func test_performance_monitoring():
	# 测试性能监控
	var initial_stats = level_manager.performance_data.duplicate()
	
	# 执行一些操作
	level_manager.load_level(1)
	level_manager.load_level(999)  # 失败的加载
	
	# 验证统计数据
	assert_gt(level_manager.performance_data["total_loads"], initial_stats["total_loads"], "总加载次数应该增加")
	assert_gt(level_manager.performance_data["failed_loads"], initial_stats["failed_loads"], "失败加载次数应该增加")
	assert_gt(level_manager.performance_data["successful_loads"], initial_stats["successful_loads"], "成功加载次数应该增加")

func test_error_message_generation():
	# 测试错误信息生成
	var error_msg = level_manager._get_error_message(LevelManager.LoadError.LEVEL_NOT_FOUND)
	assert_eq(error_msg, "关卡不存在", "错误信息应该正确")
	
	error_msg = level_manager._get_error_message(LevelManager.LoadError.LEVEL_LOCKED)
	assert_eq(error_msg, "关卡未解锁", "错误信息应该正确")

func test_level_validation():
	# 测试关卡验证
	var validation_result = level_manager._validate_level_load_preconditions(1)
	assert_eq(validation_result, LevelManager.LoadError.NONE, "有效关卡应该通过验证")
	
	validation_result = level_manager._validate_level_load_preconditions(999)
	assert_eq(validation_result, LevelManager.LoadError.LEVEL_NOT_FOUND, "无效关卡应该验证失败")

func test_load_time_recording():
	# 测试加载时间记录
	var initial_load_times_count = level_manager.load_times.size()
	level_manager.load_level(1)
	
	assert_gt(level_manager.load_times.size(), initial_load_times_count, "加载时间记录应该增加")
	assert_gt(level_manager.performance_data["last_load_time"], 0, "最后加载时间应该大于0")

func test_signal_emission():
	# 测试信号发射
	var signal_received = false
	var received_level_id = 0
	
	level_manager.level_loaded.connect(func(level_id): 
		signal_received = true
		received_level_id = level_id
	)
	
	level_manager.load_level(1)
	
	assert_true(signal_received, "应该发射level_loaded信号")
	assert_eq(received_level_id, 1, "信号应该包含正确的关卡ID")

func test_error_signal_emission():
	# 测试错误信号发射
	var error_signal_received = false
	var error_level_id = 0
	var error_message = ""
	
	level_manager.level_load_error.connect(func(level_id, msg):
		error_signal_received = true
		error_level_id = level_id
		error_message = msg
	)
	
	level_manager.load_level(999)
	
	assert_true(error_signal_received, "应该发射level_load_error信号")
	assert_eq(error_level_id, 999, "错误信号应该包含正确的关卡ID")
	assert_ne(error_message, "", "错误信号应该包含错误信息")
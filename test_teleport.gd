extends Node

# 传送功能测试脚本
# 用于验证新的传送系统是否正常工作

class_name TeleportTest

var teleport_manager: TeleportManager
var test_results: Array[String] = []

func _ready():
	print("=== 开始传送功能测试 ===")
	print("💡 按空格键执行传送测试，R键重新运行所有测试，ESC键退出")
	_run_all_tests()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("\n🚀 执行传送测试...")
				test_actual_teleport()
			KEY_R:
				print("\n🔄 重新运行所有测试...")
				test_results.clear()
				_run_all_tests()
			KEY_ESCAPE:
				print("\n👋 退出测试")
				get_tree().quit()

func _run_all_tests():
	# 测试1: 传送管理器初始化
	_test_teleport_manager_initialization()
	
	# 测试2: 配置加载
	_test_config_loading()
	
	# 测试3: Portal节点查找
	_test_portal_finding()
	
	# 测试4: 传送冷却功能
	_test_cooldown_system()
	
	# 测试5: 配置预设
	_test_config_presets()
	
	# 输出测试结果
	_print_test_results()

func _test_teleport_manager_initialization():
	print("\n测试1: 传送管理器初始化")
	try:
		teleport_manager = TeleportManager.new()
		add_child(teleport_manager)
		
		if teleport_manager:
			_add_test_result("✅ 传送管理器创建成功")
		else:
			_add_test_result("❌ 传送管理器创建失败")
	except:
		_add_test_result("❌ 传送管理器初始化异常")

func _test_config_loading():
	print("\n测试2: 配置加载")
	try:
		var config = load("res://resources/default_teleport_config.tres") as TeleportConfig
		if config:
			teleport_manager.set_config(config)
			_add_test_result("✅ 默认配置加载成功")
			
			# 验证配置参数
			if config.portal_offset == Vector2(-20, 0):
				_add_test_result("✅ Portal偏移配置正确")
			else:
				_add_test_result("❌ Portal偏移配置错误")
			
			if config.cooldown_time == 1.0:
				_add_test_result("✅ 冷却时间配置正确")
			else:
				_add_test_result("❌ 冷却时间配置错误")
		else:
			_add_test_result("❌ 配置文件加载失败")
	except:
		_add_test_result("❌ 配置加载异常")

func _test_portal_finding():
	print("\n测试3: Portal节点查找")
	try:
		# 测试组查找
		var portal_by_group = get_tree().get_first_node_in_group("portal")
		if portal_by_group:
			_add_test_result("✅ 通过组查找Portal成功")
		else:
			_add_test_result("⚠️ 通过组查找Portal失败（可能Portal未添加到场景）")
		
		# 测试节点名称查找
		var portal_by_name = get_tree().current_scene.get_node_or_null("Portal")
		if portal_by_name:
			_add_test_result("✅ 通过名称查找Portal成功")
		else:
			_add_test_result("⚠️ 通过名称查找Portal失败（可能Portal节点不存在）")
	except:
		_add_test_result("❌ Portal查找异常")

func _test_cooldown_system():
	print("\n测试4: 传送冷却功能")
	try:
		# 测试初始状态
		if teleport_manager.can_teleport():
			_add_test_result("✅ 初始状态可以传送")
		else:
			_add_test_result("❌ 初始状态无法传送")
		
		# 连接信号进行测试
		teleport_manager.teleport_started.connect(_on_test_teleport_started)
		teleport_manager.teleport_failed.connect(_on_test_teleport_failed)
		teleport_manager.teleport_completed.connect(_on_test_teleport_completed)
		
		_add_test_result("✅ 传送事件信号连接成功")
	except:
		_add_test_result("❌ 冷却系统测试异常")

func _test_config_presets():
	print("\n测试5: 配置预设")
	try:
		var test_config = TeleportConfig.new()
		
		# 测试瞬间传送预设
		test_config.apply_preset(TeleportConfig.Preset.INSTANT)
		if test_config.teleport_duration == 0.0:
			_add_test_result("✅ INSTANT预设配置正确")
		else:
			_add_test_result("❌ INSTANT预设配置错误")
		
		# 测试平滑传送预设
		test_config.apply_preset(TeleportConfig.Preset.SMOOTH)
		if test_config.teleport_duration > 0.0:
			_add_test_result("✅ SMOOTH预设配置正确")
		else:
			_add_test_result("❌ SMOOTH预设配置错误")
		
		# 测试配置验证
		if test_config.validate():
			_add_test_result("✅ 配置验证通过")
		else:
			_add_test_result("❌ 配置验证失败")
	except:
		_add_test_result("❌ 配置预设测试异常")

# 测试传送功能（如果有Portal的话）
func test_actual_teleport():
	print("\n执行实际传送测试...")
	if teleport_manager:
		teleport_manager.teleport_to_portal()

func _on_test_teleport_started(player: Node2D, destination: Vector2):
	_add_test_result("✅ 传送开始事件触发")

func _on_test_teleport_completed(player: Node2D, destination: Vector2):
	_add_test_result("✅ 传送完成事件触发")

func _on_test_teleport_failed(reason: String):
	_add_test_result("⚠️ 传送失败: " + reason)

func _add_test_result(result: String):
	test_results.append(result)
	print(result)

func _print_test_results():
	print("\n=== 测试结果汇总 ===")
	var success_count = 0
	var warning_count = 0
	var error_count = 0
	
	for result in test_results:
		if result.begins_with("✅"):
			success_count += 1
		elif result.begins_with("⚠️"):
			warning_count += 1
		elif result.begins_with("❌"):
			error_count += 1
	
	print("成功: %d, 警告: %d, 错误: %d" % [success_count, warning_count, error_count])
	
	if error_count == 0:
		print("🎉 传送系统基础功能测试通过！")
	else:
		print("⚠️ 传送系统存在问题，请检查错误信息")
	
	print("\n💡 提示: 要测试完整的传送功能，请确保场景中有Portal节点")
	print("💡 提示: 可以运行 test_actual_teleport() 来测试实际传送")

func try(callable: Callable):
	callable.call()

func except():
	pass
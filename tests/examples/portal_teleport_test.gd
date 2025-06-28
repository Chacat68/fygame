extends Node2D

# 传送门传送功能测试脚本
# 用于验证传送门的各种传送模式

class_name PortalTeleportTest

# 测试用的传送门引用
@onready var level_portal = $LevelPortal
@onready var scene_portal = $ScenePortal
@onready var next_level_portal = $NextLevelPortal

# 测试状态
var test_results: Dictionary = {}
var current_test: String = ""

func _ready():
	print("[PortalTeleportTest] 开始传送门功能测试")
	
	# 配置测试传送门
	_setup_test_portals()
	
	# 连接信号
	_connect_portal_signals()
	
	# 运行测试
	_run_tests()

# 配置测试传送门
func _setup_test_portals():
	print("[PortalTeleportTest] 配置测试传送门...")
	
	# 配置关卡传送门
	if level_portal:
		level_portal.configure_for_level_teleport(2)
		level_portal.position = Vector2(100, 100)
		print("✓ 关卡传送门配置完成")
	
	# 配置场景传送门
	if scene_portal:
		scene_portal.configure_for_scene_teleport(
			"res://scenes/levels/level1.tscn",
			Vector2(200, 150)
		)
		scene_portal.position = Vector2(300, 100)
		print("✓ 场景传送门配置完成")
	
	# 配置下一关传送门
	if next_level_portal:
		next_level_portal.configure_for_level_teleport(-1)
		next_level_portal.position = Vector2(500, 100)
		print("✓ 下一关传送门配置完成")

# 连接传送门信号
func _connect_portal_signals():
	if level_portal:
		level_portal.body_entered.connect(_on_level_portal_used)
	
	if scene_portal:
		scene_portal.body_entered.connect(_on_scene_portal_used)
	
	if next_level_portal:
		next_level_portal.body_entered.connect(_on_next_level_portal_used)

# 运行测试
func _run_tests():
	print("[PortalTeleportTest] 开始运行测试...")
	
	# 测试1：检查传送门配置
	_test_portal_configuration()
	
	# 测试2：检查管理器连接
	_test_manager_connections()
	
	# 测试3：检查传送门状态
	_test_portal_states()
	
	# 输出测试结果
	_print_test_results()

# 测试传送门配置
func _test_portal_configuration():
	current_test = "portal_configuration"
	print("\n[测试] 传送门配置检查")
	
	var passed = true
	
	# 检查关卡传送门
	if level_portal:
		var info = level_portal.get_portal_info()
		if info.next_level == 2 and info.destination_scene == "":
			print("✓ 关卡传送门配置正确")
		else:
			print("✗ 关卡传送门配置错误")
			passed = false
	else:
		print("✗ 关卡传送门不存在")
		passed = false
	
	# 检查场景传送门
	if scene_portal:
		var info = scene_portal.get_portal_info()
		if info.destination_scene != "" and info.next_level == -1:
			print("✓ 场景传送门配置正确")
		else:
			print("✗ 场景传送门配置错误")
			passed = false
	else:
		print("✗ 场景传送门不存在")
		passed = false
	
	test_results[current_test] = passed

# 测试管理器连接
func _test_manager_connections():
	current_test = "manager_connections"
	print("\n[测试] 管理器连接检查")
	
	var passed = true
	
	# 检查传送管理器
	var teleport_manager = get_tree().get_first_node_in_group("teleport_manager")
	if teleport_manager:
		print("✓ 传送管理器连接正常")
	else:
		print("⚠ 传送管理器未找到（可能影响场景传送功能）")
	
	# 检查关卡管理器
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		print("✓ 关卡管理器连接正常")
	else:
		print("⚠ 关卡管理器未找到（可能影响关卡传送功能）")
	
	# 检查游戏管理器
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		print("✓ 游戏管理器连接正常")
	else:
		print("⚠ 游戏管理器未找到")
	
	test_results[current_test] = passed

# 测试传送门状态
func _test_portal_states():
	current_test = "portal_states"
	print("\n[测试] 传送门状态检查")
	
	var passed = true
	
	# 检查所有传送门是否激活
	var portals = [level_portal, scene_portal, next_level_portal]
	var portal_names = ["关卡传送门", "场景传送门", "下一关传送门"]
	
	for i in range(portals.size()):
		var portal = portals[i]
		var name = portal_names[i]
		
		if portal:
			var info = portal.get_portal_info()
			if info.is_active:
				print("✓ %s 状态正常" % name)
			else:
				print("✗ %s 未激活" % name)
				passed = false
		else:
			print("✗ %s 不存在" % name)
			passed = false
	
	test_results[current_test] = passed

# 输出测试结果
func _print_test_results():
	print("\n" + "=".repeat(50))
	print("传送门功能测试结果")
	print("=".repeat(50))
	
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for test_name in test_results.keys():
		var result = test_results[test_name]
		var status = "✓ 通过" if result else "✗ 失败"
		print("%s: %s" % [test_name, status])
		if result:
			passed_tests += 1
	
	print("\n总计：%d/%d 测试通过" % [passed_tests, total_tests])
	
	if passed_tests == total_tests:
		print("🎉 所有测试通过！传送门功能正常")
	else:
		print("⚠ 部分测试失败，请检查配置")

# 传送门使用事件处理
func _on_level_portal_used(body):
	if body.is_in_group("player"):
		print("[测试] 玩家使用了关卡传送门")

func _on_scene_portal_used(body):
	if body.is_in_group("player"):
		print("[测试] 玩家使用了场景传送门")

func _on_next_level_portal_used(body):
	if body.is_in_group("player"):
		print("[测试] 玩家使用了下一关传送门")

# 手动测试传送门功能
func test_portal_manually(portal_type: String):
	print("\n[手动测试] 测试 %s" % portal_type)
	
	match portal_type:
		"level":
			if level_portal:
				var info = level_portal.get_portal_info()
				print("关卡传送门信息：", info)
		"scene":
			if scene_portal:
				var info = scene_portal.get_portal_info()
				print("场景传送门信息：", info)
		"next":
			if next_level_portal:
				var info = next_level_portal.get_portal_info()
				print("下一关传送门信息：", info)
		_:
			print("未知的传送门类型：", portal_type)

# 重置所有传送门状态
func reset_all_portals():
	print("[测试] 重置所有传送门状态")
	
	var portals = [level_portal, scene_portal, next_level_portal]
	for portal in portals:
		if portal:
			portal.set_active(true)
	
	print("✓ 所有传送门已重置")
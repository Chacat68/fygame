extends Node

# 测试 Tween 修复的简单脚本
# 验证传送管理器是否能正常创建和使用

func _ready():
	print("🔧 测试 Tween 修复...")
	
	# 测试1: 创建传送管理器
	var teleport_manager = preload("res://scripts/systems/teleport_manager.gd").new()
	if teleport_manager:
		print("✅ 传送管理器创建成功")
		add_child(teleport_manager)
		
		# 测试2: 验证 _ready 函数执行
		await get_tree().process_frame
		print("✅ 传送管理器初始化完成")
		
		# 测试3: 测试 Tween 创建
		var test_tween = teleport_manager.create_tween()
		if test_tween:
			print("✅ Tween 创建成功")
			test_tween.kill()  # 清理测试用的 Tween
		else:
			print("❌ Tween 创建失败")
		
		print("🎉 Tween 修复测试完成！")
	else:
		print("❌ 传送管理器创建失败")
	
	# 退出测试
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
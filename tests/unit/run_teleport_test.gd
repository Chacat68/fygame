extends SceneTree

# 传送功能测试启动脚本
# 直接运行传送测试场景

func _init():
	print("🚀 启动传送功能测试...")
	
	# 加载测试场景
	var test_scene = load("res://tests/integration/teleport_test_scene.tscn")
	if test_scene:
		current_scene = test_scene.instantiate()
		root.add_child(current_scene)
		print("✅ 测试场景加载成功")
	else:
		print("❌ 无法加载测试场景")
		quit(1)
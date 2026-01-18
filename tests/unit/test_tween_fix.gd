extends GutTest

# 测试 Tween 修复的简单脚本
# 验证传送管理器是否能正常创建和使用

func test_teleport_manager_tween_creation():
	var teleport_manager = preload("res://scripts/systems/teleport_manager.gd").new()
	assert_not_null(teleport_manager, "传送管理器应该创建成功")
	if teleport_manager == null:
		return

	add_child_autofree(teleport_manager)
	await wait_process_frames(1)

	var test_tween = teleport_manager.create_tween()
	assert_not_null(test_tween, "Tween 应该创建成功")
	if test_tween:
		test_tween.kill()
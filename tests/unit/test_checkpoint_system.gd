extends GutTest
## 检查点系统单元测试
##
## 测试检查点管理器和检查点实体的核心功能

# 测试用的模拟检查点
class MockCheckpoint extends Node2D:
	var checkpoint_id: String = ""
	var checkpoint_order: int = 0
	var spawn_offset: Vector2 = Vector2(0, -16)
	var is_active: bool = false
	
	signal activated(checkpoint)
	
	func _init(id: String = "", order: int = 0):
		checkpoint_id = id if id != "" else str(get_instance_id())
		checkpoint_order = order
	
	func activate():
		is_active = true
		activated.emit(self)
	
	func get_spawn_position() -> Vector2:
		return global_position + spawn_offset
	
	func reset():
		is_active = false

# 测试用的检查点管理器实例
var manager: Node

func before_each():
	# 创建新的管理器实例用于测试
	manager = load("res://scripts/managers/checkpoint_manager.gd").new()
	add_child(manager)

func after_each():
	if manager:
		manager.queue_free()

# ============================================
# 检查点注册测试
# ============================================

func test_register_checkpoint():
	var checkpoint = MockCheckpoint.new("test_cp_1", 1)
	checkpoint.global_position = Vector2(100, 200)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	
	assert_true(manager.checkpoints.has("test_cp_1"), "检查点应该被注册")
	
	checkpoint.queue_free()

func test_register_multiple_checkpoints():
	var cp1 = MockCheckpoint.new("cp_1", 1)
	var cp2 = MockCheckpoint.new("cp_2", 2)
	var cp3 = MockCheckpoint.new("cp_3", 3)
	
	add_child(cp1)
	add_child(cp2)
	add_child(cp3)
	
	manager.register_checkpoint(cp1)
	manager.register_checkpoint(cp2)
	manager.register_checkpoint(cp3)
	
	assert_eq(manager.checkpoints.size(), 3, "应该注册3个检查点")
	
	cp1.queue_free()
	cp2.queue_free()
	cp3.queue_free()

func test_register_duplicate_checkpoint():
	var checkpoint = MockCheckpoint.new("duplicate_cp", 1)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.register_checkpoint(checkpoint)  # 重复注册
	
	assert_eq(manager.checkpoints.size(), 1, "重复注册不应该增加检查点数量")
	
	checkpoint.queue_free()

# ============================================
# 检查点激活测试
# ============================================

func test_activate_checkpoint():
	var checkpoint = MockCheckpoint.new("active_cp", 1)
	checkpoint.global_position = Vector2(100, 200)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("active_cp")
	
	assert_eq(manager.active_checkpoint_id, "active_cp", "活动检查点ID应该正确设置")
	assert_true(manager.has_checkpoint(), "应该有活动的检查点")
	
	checkpoint.queue_free()

func test_activate_nonexistent_checkpoint():
	manager.activate_checkpoint("nonexistent")
	
	assert_eq(manager.active_checkpoint_id, "", "不存在的检查点不应该被激活")
	assert_false(manager.has_checkpoint(), "不应该有活动的检查点")

func test_activate_checkpoint_emits_signal():
	var checkpoint = MockCheckpoint.new("signal_cp", 1)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	
	watch_signals(manager)
	manager.activate_checkpoint("signal_cp")
	
	assert_signal_emitted(manager, "checkpoint_activated", "应该发出checkpoint_activated信号")
	
	checkpoint.queue_free()

# ============================================
# 重生位置测试
# ============================================

func test_get_respawn_position_with_checkpoint():
	var checkpoint = MockCheckpoint.new("respawn_cp", 1)
	checkpoint.global_position = Vector2(500, 300)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("respawn_cp")
	
	var respawn_pos = manager.get_respawn_position()
	var expected_pos = checkpoint.get_spawn_position()
	
	assert_eq(respawn_pos, expected_pos, "重生位置应该是检查点的出生位置")
	
	checkpoint.queue_free()

func test_get_respawn_position_without_checkpoint():
	var initial_pos = Vector2(50, 100)
	manager.set_initial_spawn_position(initial_pos)
	
	var respawn_pos = manager.get_respawn_position()
	
	assert_eq(respawn_pos, initial_pos, "没有检查点时应该返回初始出生位置")

func test_initial_spawn_position():
	var initial_pos = Vector2(100, 200)
	manager.set_initial_spawn_position(initial_pos)
	
	assert_eq(manager.initial_spawn_position, initial_pos, "初始出生位置应该正确设置")

# ============================================
# 检查点重置测试
# ============================================

func test_reset_all_checkpoints():
	var cp1 = MockCheckpoint.new("reset_cp_1", 1)
	var cp2 = MockCheckpoint.new("reset_cp_2", 2)
	
	add_child(cp1)
	add_child(cp2)
	
	manager.register_checkpoint(cp1)
	manager.register_checkpoint(cp2)
	manager.activate_checkpoint("reset_cp_1")
	
	manager.reset_all_checkpoints()
	
	assert_eq(manager.active_checkpoint_id, "", "重置后活动检查点ID应该为空")
	assert_false(manager.has_checkpoint(), "重置后不应该有活动检查点")
	
	cp1.queue_free()
	cp2.queue_free()

func test_clear_checkpoints():
	var checkpoint = MockCheckpoint.new("clear_cp", 1)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.clear_checkpoints()
	
	assert_eq(manager.checkpoints.size(), 0, "清除后检查点字典应该为空")
	
	checkpoint.queue_free()

# ============================================
# 关卡管理测试
# ============================================

func test_set_current_level():
	manager.set_current_level("level_1")
	
	assert_eq(manager.current_level, "level_1", "当前关卡应该正确设置")

func test_level_change_clears_checkpoints():
	var checkpoint = MockCheckpoint.new("level_cp", 1)
	add_child(checkpoint)
	
	manager.set_current_level("level_1")
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("level_cp")
	
	# 切换到新关卡
	manager.set_current_level("level_2")
	
	assert_eq(manager.checkpoints.size(), 0, "切换关卡后检查点应该被清除")
	assert_false(manager.has_checkpoint(), "切换关卡后不应该有活动检查点")
	
	checkpoint.queue_free()

# ============================================
# 存档数据测试
# ============================================

func test_get_save_data():
	var checkpoint = MockCheckpoint.new("save_cp", 1)
	add_child(checkpoint)
	
	manager.set_current_level("test_level")
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("save_cp")
	
	var save_data = manager.get_save_data()
	
	assert_true(save_data.has("active_checkpoint_id"), "存档数据应该包含活动检查点ID")
	assert_true(save_data.has("current_level"), "存档数据应该包含当前关卡")
	assert_eq(save_data["active_checkpoint_id"], "save_cp", "存档的检查点ID应该正确")
	assert_eq(save_data["current_level"], "test_level", "存档的关卡应该正确")
	
	checkpoint.queue_free()

func test_load_save_data():
	var save_data = {
		"active_checkpoint_id": "loaded_cp",
		"current_level": "loaded_level"
	}
	
	manager.load_save_data(save_data)
	
	assert_eq(manager.active_checkpoint_id, "loaded_cp", "加载后检查点ID应该正确")
	assert_eq(manager.current_level, "loaded_level", "加载后关卡应该正确")

# ============================================
# has_checkpoint 测试
# ============================================

func test_has_checkpoint_false_initially():
	assert_false(manager.has_checkpoint(), "初始状态不应该有检查点")

func test_has_checkpoint_true_after_activation():
	var checkpoint = MockCheckpoint.new("has_cp", 1)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("has_cp")
	
	assert_true(manager.has_checkpoint(), "激活后应该有检查点")
	
	checkpoint.queue_free()

# ============================================
# 边界情况测试
# ============================================

func test_activate_checkpoint_updates_previous():
	var cp1 = MockCheckpoint.new("first_cp", 1)
	var cp2 = MockCheckpoint.new("second_cp", 2)
	
	add_child(cp1)
	add_child(cp2)
	
	manager.register_checkpoint(cp1)
	manager.register_checkpoint(cp2)
	
	manager.activate_checkpoint("first_cp")
	assert_eq(manager.active_checkpoint_id, "first_cp")
	
	manager.activate_checkpoint("second_cp")
	assert_eq(manager.active_checkpoint_id, "second_cp", "应该更新为最新激活的检查点")
	
	cp1.queue_free()
	cp2.queue_free()

func test_respawn_position_with_offset():
	var checkpoint = MockCheckpoint.new("offset_cp", 1)
	checkpoint.global_position = Vector2(100, 100)
	checkpoint.spawn_offset = Vector2(10, -20)
	add_child(checkpoint)
	
	manager.register_checkpoint(checkpoint)
	manager.activate_checkpoint("offset_cp")
	
	var expected_pos = Vector2(110, 80)  # 100+10, 100-20
	var respawn_pos = manager.get_respawn_position()
	
	assert_eq(respawn_pos, expected_pos, "重生位置应该考虑偏移量")
	
	checkpoint.queue_free()

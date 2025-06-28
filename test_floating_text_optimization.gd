# 测试脚本 - 验证飘字优化功能
# 这个脚本用于测试新的飘字排列系统

extends Node

# 测试飘字管理器功能
func test_floating_text_manager():
	print("开始测试飘字管理器...")
	
	# 测试管理器单例
	var manager1 = FloatingTextManager.get_instance()
	var manager2 = FloatingTextManager.get_instance()
	
	if manager1 == manager2:
		print("✓ 单例模式工作正常")
	else:
		print("✗ 单例模式失败")
	
	# 测试排列参数
	print("✓ 水平间距: ", manager1.horizontal_spacing)
	print("✓ 延迟间隔: ", manager1.stagger_delay_interval)
	print("✓ 每排最大数量: ", manager1.max_texts_per_row)
	
	print("飘字管理器测试完成")

# 测试飘字排列逻辑
func test_arrangement_logic():
	print("开始测试排列逻辑...")
	
	var manager = FloatingTextManager.get_instance()
	
	# 模拟多个飘字的排列
	for i in range(8):  # 测试8个飘字
		var current_index = i
		var row = current_index / manager.max_texts_per_row
		var col = current_index % manager.max_texts_per_row
		
		var total_width = (manager.max_texts_per_row - 1) * manager.horizontal_spacing
		var start_x = -total_width / 2.0
		var horizontal_offset = start_x + col * manager.horizontal_spacing
		var vertical_offset = -row * 25.0
		var delay = col * manager.stagger_delay_interval
		
		print("飘字 ", i, ": 排(", row, ") 列(", col, ") 水平偏移(", horizontal_offset, ") 垂直偏移(", vertical_offset, ") 延迟(", delay, ")")
	
	print("排列逻辑测试完成")

# 主测试函数
func _ready():
	print("=== 飘字优化测试开始 ===")
	test_floating_text_manager()
	test_arrangement_logic()
	print("=== 飘字优化测试结束 ===")
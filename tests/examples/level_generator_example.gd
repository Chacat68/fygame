extends Node2D

# 关卡生成器使用示例
# 演示如何使用LevelLoader和LevelGenerator加载数据驱动的关卡
# 注：根据项目规范，代码注释使用中文

var level_loader: LevelLoader
var current_level: Node2D

func _ready():
	print("=== 关卡生成器示例 ===")
	print("📝 按数字键加载不同关卡：")
	print("  1 - 加载关卡1 (lv1_data.json)")
	print("  2 - 加载关卡2 (lv2_data.json)")
	print("  C - 清除当前关卡")
	print("  ESC - 退出")
	print("")
	
	# 创建LevelLoader
	level_loader = LevelLoader.new()
	add_child(level_loader)
	
	print("✅ LevelLoader已准备就绪")
	print("💡 提示：现在可以按数字键加载关卡了")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_load_level(1)
			KEY_2:
				_load_level(2)
			KEY_C:
				_clear_level()
			KEY_ESCAPE:
				print("\n👋 退出示例")
				get_tree().quit()

# 加载指定关卡
func _load_level(level_id: int):
	print("\n" + "=".repeat(50))
	print("🔄 开始加载关卡 %d..." % level_id)
	
	# 清除旧关卡
	if current_level:
		_clear_level()
	
	# 加载新关卡
	current_level = level_loader.load_level_from_data(level_id)
	
	if current_level:
		add_child(current_level)
		print("✅ 关卡 %d 加载成功！" % level_id)
		_print_level_info(current_level)
	else:
		print("❌ 加载关卡 %d 失败" % level_id)
	
	print("=".repeat(50) + "\n")

# 清除当前关卡
func _clear_level():
	if current_level:
		print("🗑️  清除当前关卡...")
		current_level.queue_free()
		current_level = null
		print("✅ 关卡已清除")

# 打印关卡信息
func _print_level_info(level: Node2D):
	print("\n📊 关卡信息：")
	print("  名称: %s" % level.name)
	print("  子节点数: %d" % level.get_child_count())
	
	# 统计各类实体
	var stats = {
		"玩家": 0,
		"金币": 0,
		"平台": 0,
		"敌人": 0,
		"传送门": 0,
		"UI": 0,
		"管理器": 0
	}
	
	for child in level.get_children():
		match child.name:
			"Player":
				stats["玩家"] += 1
			"Coins":
				stats["金币"] = child.get_child_count()
			"Platforms":
				stats["平台"] = child.get_child_count()
			"Monster":
				stats["敌人"] = child.get_child_count()
			"Portal":
				stats["传送门"] += 1
			"UI":
				stats["UI"] += 1
			"GameManager":
				stats["管理器"] += 1
	
	print("\n  实体统计：")
	for key in stats:
		if stats[key] > 0:
			print("    %s: %d" % [key, stats[key]])

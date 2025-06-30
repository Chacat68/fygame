extends Node

# 飘字管理器 - 负责协调多个飘字的排列和动画
class_name FloatingTextManager

# 预加载飘字场景
var floating_text_scene = preload("res://scenes/managers/floating_text.tscn")

# 排列参数
var horizontal_spacing = 40.0           # 水平间距
var stagger_delay_interval = 0.1        # 错开延迟间隔
var max_texts_per_row = 5               # 每排最大文字数量

# 当前活跃的飘字队列
var active_floating_texts = []

# 单例实例
static var instance: FloatingTextManager

# 获取单例实例
static func get_instance() -> FloatingTextManager:
	if not instance:
		instance = FloatingTextManager.new()
		# 将管理器添加到场景树中
		var game_root = Engine.get_main_loop().get_root().get_node_or_null("Game")
		if game_root:
			game_root.add_child(instance)
		else:
			Engine.get_main_loop().get_root().add_child(instance)
	return instance

# 创建排列的飘字效果
func create_arranged_floating_text(base_position: Vector2, text: String, game_root: Node) -> void:
	# 清理已经完成的飘字
	_cleanup_finished_texts()
	
	# 创建飘字实例
	var floating_text = floating_text_scene.instantiate()
	
	# 设置位置（直接使用基础位置，不添加任何偏移）
	floating_text.global_position = base_position
	
	# 不设置任何排列参数，飘字将直接在角色头顶显示
	floating_text.set_arrangement(0.0, 0.0)
	
	# 设置文本
	floating_text.pending_text = text
	
	# 添加到游戏场景
	game_root.add_child(floating_text)
	
	# 设置文本（在添加到场景树后）
	floating_text.set_text(text)
	
	# 添加到活跃列表
	active_floating_texts.append(floating_text)

# 清理已完成的飘字
func _cleanup_finished_texts():
	for i in range(active_floating_texts.size() - 1, -1, -1):
		var text_node = active_floating_texts[i]
		if not is_instance_valid(text_node) or text_node.is_queued_for_deletion():
			active_floating_texts.remove_at(i)

# 清空所有飘字
func clear_all_texts():
	for text_node in active_floating_texts:
		if is_instance_valid(text_node):
			text_node.queue_free()
	active_floating_texts.clear()

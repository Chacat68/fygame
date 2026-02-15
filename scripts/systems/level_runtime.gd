# 运行时关卡加载器
# 挂在生成的 .tscn 场景根节点上
# _ready() 时从 JSON 文件动态构建整个关卡
extends Node2D

## JSON 数据文件路径（在编辑器生成时设定）
@export_file("*.json") var json_data_path: String = ""

var _generator: LevelGenerator

func _ready():
	if json_data_path.is_empty():
		push_error("[LevelRuntime] 未设置 json_data_path")
		return

	if not ResourceLoader.exists(json_data_path):
		push_error("[LevelRuntime] JSON 文件不存在: " + json_data_path)
		return

	# 加载 JSON
	var file = FileAccess.open(json_data_path, FileAccess.READ)
	if not file:
		push_error("[LevelRuntime] 无法打开: " + json_data_path)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[LevelRuntime] JSON 解析失败: " + json.get_error_message())
		return

	var data = json.data as Dictionary
	if data.is_empty():
		push_error("[LevelRuntime] JSON 数据为空")
		return

	# 用 LevelGenerator 构建关卡
	_generator = LevelGenerator.new()
	add_child(_generator)

	# 等一帧让 preload 完成
	await get_tree().process_frame

	var level_root = _generator.generate_level(data)
	if level_root:
		# 先收集所有子节点（避免边遍历边移除导致跳过节点）
		var children = level_root.get_children().duplicate()
		for child in children:
			level_root.remove_child(child)
			add_child(child)
		level_root.queue_free()
	else:
		push_error("[LevelRuntime] 关卡生成失败")

	_generator.queue_free()
	_generator = null

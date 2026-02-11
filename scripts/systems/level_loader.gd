# 数据驱动关卡加载器
# 集成 LevelGenerator，提供简单的关卡加载接口
class_name LevelLoader
extends Node

var level_generator: LevelGenerator

func _ready():
	level_generator = LevelGenerator.new()
	add_child(level_generator)

## 从 JSON 数据文件加载关卡
func load_level_from_data(level_id: int) -> Node2D:
	var json_path = "res://resources/level_data/lv%d_data.json" % level_id
	return level_generator.generate_level_from_file(json_path)

## 从自定义路径加载关卡
func load_level_from_path(json_path: String) -> Node2D:
	return level_generator.generate_level_from_file(json_path)

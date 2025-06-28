# 关卡配置系统
# 用于管理游戏中所有关卡的配置信息
class_name LevelConfig
extends Resource

# 关卡数据数组
@export var levels: Array[Dictionary] = []

# 最大关卡数量
@export var max_levels: int = 10

# 当前关卡
@export var current_level: int = 1

# 获取指定ID的关卡信息
func get_level_by_id(level_id: int) -> Dictionary:
	for level in levels:
		if level.get("id", 0) == level_id:
			return level
	return {}

# 获取关卡总数
func get_level_count() -> int:
	return levels.size()

# 检查关卡是否解锁
func is_level_unlocked(level_id: int) -> bool:
	var level = get_level_by_id(level_id)
	if level.is_empty():
		return false
	
	# 第一关总是解锁的
	if level_id == 1:
		return true
	
	# 检查解锁条件
	var unlock_condition = level.get("unlock_condition", "")
	if unlock_condition.is_empty():
		return true
	
	# 简单的解锁逻辑：前一关完成
	if unlock_condition.begins_with("完成关卡"):
		var required_level = unlock_condition.get_slice("关卡", 1).to_int()
		return is_level_completed(required_level)
	
	return false

# 检查关卡是否完成
func is_level_completed(level_id: int) -> bool:
	# 这里应该从游戏存档中读取完成状态
	# 暂时返回简单逻辑
	return level_id < current_level

# 获取关卡场景路径
func get_level_scene_path(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("scene_path", "")

# 获取关卡脚本路径
func get_level_script_path(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("script_path", "")

# 获取关卡名称
func get_level_name(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("name", "未知关卡")

# 获取关卡主题
func get_level_theme(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("theme", "")

# 获取关卡难度
func get_level_difficulty(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("difficulty", "")

# 获取关卡描述
func get_level_description(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("description", "")

# 获取关卡目标分数
func get_level_target_score(level_id: int) -> int:
	var level = get_level_by_id(level_id)
	return level.get("target_score", 0)

# 获取关卡时间限制
func get_level_time_limit(level_id: int) -> int:
	var level = get_level_by_id(level_id)
	return level.get("time_limit", 0)

# 添加新关卡
func add_level(level_data: Dictionary) -> void:
	levels.append(level_data)

# 更新关卡信息
func update_level(level_id: int, level_data: Dictionary) -> void:
	for i in range(levels.size()):
		if levels[i].get("id", 0) == level_id:
			levels[i] = level_data
			break

# 删除关卡
func remove_level(level_id: int) -> void:
	for i in range(levels.size()):
		if levels[i].get("id", 0) == level_id:
			levels.remove_at(i)
			break

# 获取下一个可用的关卡ID
func get_next_level_id() -> int:
	var max_id = 0
	for level in levels:
		var id = level.get("id", 0)
		if id > max_id:
			max_id = id
	return max_id + 1

# 验证关卡配置
func validate_config() -> bool:
	if levels.is_empty():
		print("警告：没有配置任何关卡")
		return false
	
	# 检查关卡ID是否唯一
	var ids = []
	for level in levels:
		var id = level.get("id", 0)
		if id in ids:
			print("错误：关卡ID重复: ", id)
			return false
		ids.append(id)
	
	# 检查必要字段
	for level in levels:
		var required_fields = ["id", "name", "scene_path"]
		for field in required_fields:
			if not level.has(field) or level[field] == "":
				print("错误：关卡缺少必要字段: ", field, " 在关卡ID: ", level.get("id", "未知"))
				return false
	
	return true
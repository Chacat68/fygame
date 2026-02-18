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
	if not levels:
		return 0
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

# 获取关卡数据路径（JSON）
func get_level_data_path(level_id: int) -> String:
	var level = get_level_by_id(level_id)
	return level.get("data_path", "")

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
	# 检查输入参数
	if level_data.is_empty():
		push_error("关卡数据不能为空")
		return
	
	# 检查必要字段
	var required_fields = ["id", "name", "scene_path"]
	for field in required_fields:
		if not level_data.has(field) or level_data[field] == "":
			push_error("关卡数据缺少必要字段: %s" % field)
			return
	
	# 检查ID是否已存在
	var new_id = level_data.get("id", 0)
	for level in levels:
		if level.get("id", 0) == new_id:
			push_error("关卡ID已存在: %d" % new_id)
			return
	
	# 初始化数组（如果需要）
	if not levels:
		levels = []
	
	levels.append(level_data)
	Logger.info("LevelConfig", "关卡添加成功: ID %d, 名称: %s" % [new_id, level_data.get("name", "未知")])

# 更新关卡信息
func update_level(level_id: int, level_data: Dictionary) -> void:
	# 检查输入参数
	if level_id <= 0:
		push_error("无效的关卡ID: %d" % level_id)
		return
	
	if level_data.is_empty():
		push_error("关卡数据不能为空")
		return
	
	# 检查数组是否为空
	if not levels or levels.is_empty():
		push_error("关卡数组为空，无法更新关卡")
		return
	
	# 安全地遍历数组
	for i in range(levels.size()):
		if i < levels.size() and levels[i].get("id", 0) == level_id:
			levels[i] = level_data
			Logger.info("LevelConfig", "关卡更新成功: ID %d" % level_id)
			return
	
	push_error("未找到要更新的关卡: ID %d" % level_id)

# 删除关卡
func remove_level(level_id: int) -> void:
	# 检查输入参数
	if level_id <= 0:
		push_error("无效的关卡ID: %d" % level_id)
		return
	
	# 检查数组是否为空
	if not levels or levels.is_empty():
		push_error("关卡数组为空，无法删除关卡")
		return
	
	# 安全地遍历数组（从后往前遍历以避免索引问题）
	for i in range(levels.size() - 1, -1, -1):
		if i >= 0 and i < levels.size() and levels[i].get("id", 0) == level_id:
			levels.remove_at(i)
			Logger.info("LevelConfig", "关卡删除成功: ID %d" % level_id)
			return
	
	push_error("未找到要删除的关卡: ID %d" % level_id)

# 获取下一个可用的关卡ID
func get_next_level_id() -> int:
	# 检查数组是否为空
	if not levels or levels.is_empty():
		return 1 # 如果没有关卡，返回第一个ID
	
	var max_id = 0
	for level in levels:
		# 确保level不为空且包含id字段
		if level and level.has("id"):
			var id = level.get("id", 0)
			if id > max_id:
				max_id = id
	return max_id + 1

# 验证关卡配置
func validate_config() -> bool:
	if levels.is_empty():
		Logger.warn("LevelConfig", "没有配置任何关卡")
		return false
	
	# 检查关卡ID是否唯一
	var ids = []
	for level in levels:
		var id = level.get("id", 0)
		if id in ids:
			Logger.error("LevelConfig", "关卡ID重复: ", id)
			return false
		ids.append(id)
	
	# 检查必要字段
	for level in levels:
		var required_fields = ["id", "name", "scene_path"]
		for field in required_fields:
			if not level.has(field) or level[field] == "":
				Logger.error("LevelConfig", "关卡缺少必要字段: ", field, " 在关卡ID: ", level.get("id", "未知"))
				return false
	
	return true
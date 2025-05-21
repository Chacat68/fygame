extends Node

# 全局游戏状态变量
var player_respawning = false  # 玩家是否正在复活
var current_level = 1         # 当前关卡编号
var max_unlocked_level = 1    # 最大已解锁关卡
var total_coins = 0           # 玩家收集的总金币数
var completed_levels = {}     # 已完成的关卡记录 {关卡编号: 是否完成}

# 游戏存档文件路径
const SAVE_FILE_PATH = "user://game_progress.json"

# 初始化函数
func _ready():
	# 确保单例被正确注册
	if not Engine.has_singleton("GameState"):
		Engine.register_singleton("GameState", self)
		print("GameState 单例已注册")

# 设置玩家复活状态
func set_player_respawning(value):
	player_respawning = value
	# 打印调试信息
	print("设置玩家复活状态: " + str(value))

# 设置当前关卡
func set_current_level(level_number):
	current_level = level_number
	# 如果当前关卡大于最大已解锁关卡，更新最大已解锁关卡
	if current_level > max_unlocked_level:
		max_unlocked_level = current_level
	# 保存游戏进度
	save_game_progress()

# 完成当前关卡
func complete_current_level(coins_collected = 0):
	# 标记当前关卡为已完成
	completed_levels[str(current_level)] = true
	# 增加总金币数
	total_coins += coins_collected
	# 解锁下一关
	if current_level < 100:  # 假设总共有100关
		max_unlocked_level = max(max_unlocked_level, current_level + 1)
	# 保存游戏进度
	save_game_progress()
	# 返回下一关的编号
	return current_level + 1

# 保存游戏进度
func save_game_progress():
	# 创建游戏进度数据
	var game_data = {
		"current_level": current_level,
		"max_unlocked_level": max_unlocked_level,
		"total_coins": total_coins,
		"completed_levels": completed_levels
	}
	
	# 将游戏进度数据转换为JSON
	var json_data = JSON.stringify(game_data)
	
	# 保存到文件
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		print("游戏进度已保存")
	else:
		print("保存游戏进度失败")

# 加载游戏进度
func load_game_progress():
	# 检查存档文件是否存在
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("没有找到存档文件")
		return
	
	# 读取存档文件
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_data)
		
		if error == OK:
			var game_data = json.get_data()
			current_level = game_data.get("current_level", 1)
			max_unlocked_level = game_data.get("max_unlocked_level", 1)
			total_coins = game_data.get("total_coins", 0)
			completed_levels = game_data.get("completed_levels", {})
			print("游戏进度已加载")
		else:
			print("解析存档文件失败")
	else:
		print("读取存档文件失败")

# 重置游戏进度
func reset_game_progress():
	current_level = 1
	max_unlocked_level = 1
	total_coins = 0
	completed_levels = {}
	save_game_progress()
	print("游戏进度已重置")

# 获取下一个关卡编号
func get_next_level():
	# 如果当前关卡是最后一关，返回第一关
	if current_level >= 100:
		return 1
	# 否则返回下一关
	return current_level + 1

# 检查关卡是否已解锁
func is_level_unlocked(level_number):
	return level_number <= max_unlocked_level
extends Node

const TAG = "GameState"

# 信号定义
signal coins_changed(new_amount: int)
signal level_changed(new_level: int)
signal health_changed(new_health: int)
signal debug_mode_changed(enabled: bool)

# 全局游戏状态变量
var player_respawning: bool = false # 玩家是否正在复活
var current_level: int = 1 # 当前关卡编号
var max_unlocked_level: int = 1 # 最大已解锁关卡
var total_coins: int = 0 # 玩家收集的总金币数
var completed_levels: Dictionary = {} # 已完成的关卡记录 {关卡编号: 是否完成}

# 调试模式
var debug_mode: bool = false # 调试模式开关

# 统计数据
var total_deaths: int = 0 # 总死亡次数
var total_kills: int = 0 # 总击杀次数

# 设置玩家复活状态
func set_player_respawning(value: bool) -> void:
	player_respawning = value
	Logger.debug(TAG, "设置玩家复活状态: " + str(value))

# 切换调试模式
func toggle_debug_mode() -> void:
	debug_mode = not debug_mode
	debug_mode_changed.emit(debug_mode)
	Logger.info(TAG, "调试模式: %s" % ("ON" if debug_mode else "OFF"))

# 设置调试模式
func set_debug_mode(enabled: bool) -> void:
	if debug_mode != enabled:
		debug_mode = enabled
		debug_mode_changed.emit(debug_mode)
		Logger.info(TAG, "调试模式: %s" % ("ON" if debug_mode else "OFF"))

# 设置当前关卡
func set_current_level(level_number: int) -> void:
	var old_level = current_level
	current_level = level_number
	# 如果当前关卡大于最大已解锁关卡，更新最大已解锁关卡
	if current_level > max_unlocked_level:
		max_unlocked_level = current_level
	# 发射关卡变化信号
	if old_level != current_level:
		level_changed.emit(current_level)
	# 触发自动存档（由 SaveManager 统一管理）
	if SaveManager:
		SaveManager.trigger_auto_save()

# 完成当前关卡
func complete_current_level(coins_collected: int = 0) -> int:
	# 标记当前关卡为已完成
	completed_levels[str(current_level)] = true
	# 增加总金币数
	total_coins += coins_collected
	# 解锁下一关
	if current_level < 100:
		max_unlocked_level = max(max_unlocked_level, current_level + 1)
	# 触发自动存档（由 SaveManager 统一管理）
	if SaveManager:
		SaveManager.trigger_auto_save()
	# 返回下一关的编号
	return current_level + 1

# 重置游戏进度
func reset_game_progress() -> void:
	current_level = 1
	max_unlocked_level = 1
	total_coins = 0
	completed_levels = {}
	Logger.info(TAG, "游戏进度已重置")

# 获取下一个关卡编号
func get_next_level() -> int:
	# 如果当前关卡是最后一关，返回第一关
	if current_level >= 100:
		return 1
	# 否则返回下一关
	return current_level + 1

# 检查关卡是否已解锁
func is_level_unlocked(level_number: int) -> bool:
	return level_number <= max_unlocked_level

# ==================== 金币管理 ====================

# 添加金币
func add_coins(amount: int) -> void:
	total_coins += amount
	coins_changed.emit(total_coins)
	Logger.debug(TAG, "金币增加: %d, 当前总数: %d" % [amount, total_coins])

# 移除金币
func remove_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		coins_changed.emit(total_coins)
		Logger.debug(TAG, "金币减少: %d, 当前总数: %d" % [amount, total_coins])
		return true
	return false

# 获取当前金币数
func get_coins() -> int:
	return total_coins

# ==================== 统计数据 ====================

# 增加死亡次数
func add_death() -> void:
	total_deaths += 1
	Logger.debug(TAG, "死亡次数: %d" % total_deaths)

# 增加击杀次数
func add_kill() -> void:
	total_kills += 1
	Logger.debug(TAG, "击杀次数: %d" % total_kills)

# 获取死亡次数
func get_total_deaths() -> int:
	return total_deaths

# 获取击杀次数
func get_total_kills() -> int:
	return total_kills

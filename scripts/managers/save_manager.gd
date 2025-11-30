# 存档管理器
# 负责游戏存档的保存、加载、删除和管理
# 使用方式: 作为 AutoLoad 单例，通过 SaveManager.xxx() 调用
class_name SaveManagerClass
extends Node

# 信号
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)
signal auto_save_triggered()

# 常量
const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_slot_"
const SAVE_FILE_EXTENSION = ".json"
const MAX_SAVE_SLOTS = 3
const AUTO_SAVE_SLOT = 0
const AUTO_SAVE_INTERVAL = 60.0  # 自动保存间隔（秒）

# 当前存档数据
var current_save: SaveData = null
var current_slot: int = -1

# 自动保存计时器
var auto_save_timer: float = 0.0
var auto_save_enabled: bool = true
var session_start_time: float = 0.0

# 初始化
func _ready() -> void:
	# 确保存档目录存在
	_ensure_save_directory()
	session_start_time = Time.get_unix_time_from_system()
	print("[SaveManager] 存档管理器初始化完成")

func _process(delta: float) -> void:
	# 自动保存逻辑
	if auto_save_enabled and current_save != null:
		auto_save_timer += delta
		if auto_save_timer >= AUTO_SAVE_INTERVAL:
			auto_save_timer = 0.0
			_perform_auto_save()

# ==================== 核心存档功能 ====================

# 保存游戏到指定槽位
func save_game(slot: int = -1) -> bool:
	# 如果没有指定槽位，使用当前槽位
	if slot < 0:
		slot = current_slot if current_slot >= 0 else AUTO_SAVE_SLOT
	
	# 验证槽位
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		save_completed.emit(slot, false)
		return false
	
	# 收集当前游戏状态
	var save_data = _collect_game_state(slot)
	if not save_data:
		push_error("[SaveManager] 无法收集游戏状态")
		save_completed.emit(slot, false)
		return false
	
	# 写入文件
	var success = _write_save_file(slot, save_data)
	
	if success:
		current_save = save_data
		current_slot = slot
		print("[SaveManager] 游戏已保存到槽位 %d" % slot)
	else:
		push_error("[SaveManager] 保存失败，槽位: %d" % slot)
	
	save_completed.emit(slot, success)
	return success

# 加载指定槽位的存档
func load_game(slot: int) -> bool:
	# 验证槽位
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		load_completed.emit(slot, false)
		return false
	
	# 检查存档是否存在
	if not has_save(slot):
		print("[SaveManager] 槽位 %d 没有存档" % slot)
		load_completed.emit(slot, false)
		return false
	
	# 读取存档文件
	var save_data = _read_save_file(slot)
	if not save_data:
		push_error("[SaveManager] 无法读取存档，槽位: %d" % slot)
		load_completed.emit(slot, false)
		return false
	
	# 验证存档数据
	if not save_data.validate():
		push_error("[SaveManager] 存档数据无效，槽位: %d" % slot)
		load_completed.emit(slot, false)
		return false
	
	# 应用存档数据
	var success = _apply_game_state(save_data)
	
	if success:
		current_save = save_data
		current_slot = slot
		session_start_time = Time.get_unix_time_from_system()
		print("[SaveManager] 存档已加载，槽位: %d" % slot)
	else:
		push_error("[SaveManager] 应用存档数据失败，槽位: %d" % slot)
	
	load_completed.emit(slot, success)
	return success

# 删除指定槽位的存档
func delete_save(slot: int) -> bool:
	# 验证槽位
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		return false
	
	var file_path = _get_save_path(slot)
	
	if FileAccess.file_exists(file_path):
		var error = DirAccess.remove_absolute(file_path)
		if error != OK:
			push_error("[SaveManager] 删除存档失败: %s" % error_string(error))
			return false
	
	# 如果删除的是当前存档，清空当前状态
	if slot == current_slot:
		current_save = null
		current_slot = -1
	
	print("[SaveManager] 存档已删除，槽位: %d" % slot)
	save_deleted.emit(slot)
	return true

# 创建新存档
func create_new_save(slot: int) -> bool:
	# 验证槽位
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % slot)
		return false
	
	# 创建新的存档数据
	var save_data = SaveData.create_new(slot)
	
	# 保存到文件
	var success = _write_save_file(slot, save_data)
	
	if success:
		current_save = save_data
		current_slot = slot
		session_start_time = Time.get_unix_time_from_system()
		# 应用新存档的初始状态
		_apply_game_state(save_data)
		print("[SaveManager] 新存档已创建，槽位: %d" % slot)
	
	return success

# ==================== 查询功能 ====================

# 检查指定槽位是否有存档
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	var file_path = _get_save_path(slot)
	return FileAccess.file_exists(file_path)

# 获取指定槽位的存档信息
func get_save_info(slot: int) -> SaveData:
	if not has_save(slot):
		return null
	return _read_save_file(slot)

# 获取所有存档槽位信息
func get_all_save_info() -> Array[SaveData]:
	var saves: Array[SaveData] = []
	for i in range(MAX_SAVE_SLOTS):
		if has_save(i):
			var save_data = _read_save_file(i)
			if save_data:
				saves.append(save_data)
		else:
			saves.append(null)
	return saves

# 获取当前存档
func get_current_save() -> SaveData:
	return current_save

# 获取当前槽位
func get_current_slot() -> int:
	return current_slot

# ==================== 自动保存 ====================

# 执行自动保存
func _perform_auto_save() -> void:
	if current_save == null:
		return
	
	auto_save_triggered.emit()
	save_game(current_slot)
	print("[SaveManager] 自动保存完成")

# 启用/禁用自动保存
func set_auto_save_enabled(enabled: bool) -> void:
	auto_save_enabled = enabled
	print("[SaveManager] 自动保存: %s" % ("启用" if enabled else "禁用"))

# 手动触发自动保存
func trigger_auto_save() -> void:
	if auto_save_enabled and current_save != null:
		_perform_auto_save()

# ==================== 私有方法 ====================

# 确保存档目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("[SaveManager] 创建存档目录: %s" % SAVE_DIR)

# 获取存档文件路径
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXTENSION

# 收集当前游戏状态
func _collect_game_state(slot: int) -> SaveData:
	var save_data = SaveData.new()
	
	# 设置元数据
	save_data.save_slot = slot
	save_data.save_name = "存档 %d" % (slot + 1)
	save_data.save_timestamp = int(Time.get_unix_time_from_system())
	save_data.save_version = "1.0"
	
	# 计算游戏时长
	var current_session_time = Time.get_unix_time_from_system() - session_start_time
	if current_save:
		save_data.play_time = current_save.play_time + current_session_time
	else:
		save_data.play_time = current_session_time
	
	# 从 GameState 收集数据
	if GameState:
		save_data.current_level = GameState.current_level
		save_data.max_unlocked_level = GameState.max_unlocked_level
		save_data.total_coins = GameState.total_coins
		save_data.completed_levels = GameState.completed_levels.duplicate()
	
	# 从玩家收集数据
	var player = _get_player()
	if player:
		save_data.current_health = player.current_health
		
		# 收集技能数据
		if player.skill_manager:
			var skill_data = player.skill_manager.save_skill_data()
			for skill in skill_data.get("unlocked_skills", []):
				save_data.unlocked_skills.append(skill)
			save_data.skill_levels = skill_data.get("skill_levels", {})
	
	# 从 AudioManager 收集音量设置
	if AudioManager:
		save_data.music_volume = AudioManager.get_music_volume() if AudioManager.has_method("get_music_volume") else 1.0
		save_data.sfx_volume = AudioManager.get_sfx_volume() if AudioManager.has_method("get_sfx_volume") else 1.0
	
	return save_data

# 应用存档数据到游戏状态
func _apply_game_state(save_data: SaveData) -> bool:
	if not save_data:
		return false
	
	# 应用到 GameState
	if GameState:
		GameState.current_level = save_data.current_level
		GameState.max_unlocked_level = save_data.max_unlocked_level
		GameState.total_coins = save_data.total_coins
		GameState.completed_levels = save_data.completed_levels.duplicate()
	
	# 应用音量设置
	if AudioManager:
		if AudioManager.has_method("set_music_volume"):
			AudioManager.set_music_volume(save_data.music_volume)
		if AudioManager.has_method("set_sfx_volume"):
			AudioManager.set_sfx_volume(save_data.sfx_volume)
	
	# 技能数据会在玩家初始化时从存档中加载
	# 这里暂存技能数据，等玩家初始化后再应用
	
	return true

# 写入存档文件
func _write_save_file(slot: int, save_data: SaveData) -> bool:
	var file_path = _get_save_path(slot)
	var json_data = JSON.stringify(save_data.to_dictionary(), "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] 无法打开文件: %s, 错误: %s" % [file_path, FileAccess.get_open_error()])
		return false
	
	file.store_string(json_data)
	file.close()
	return true

# 读取存档文件
func _read_save_file(slot: int) -> SaveData:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] 无法打开文件: %s" % file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] JSON解析错误: %s" % json.get_error_message())
		return null
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("[SaveManager] 存档数据格式错误")
		return null
	
	return SaveData.from_dictionary(data)

# 获取玩家节点
func _get_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

# ==================== 调试功能 ====================

# 打印所有存档信息
func debug_print_all_saves() -> void:
	if not OS.is_debug_build():
		return
	
	print("========== 存档信息 ==========")
	for i in range(MAX_SAVE_SLOTS):
		if has_save(i):
			var save = get_save_info(i)
			if save:
				print("槽位 %d: %s" % [i, save.get_summary()])
				print("  - 保存时间: %s" % save.get_formatted_save_time())
		else:
			print("槽位 %d: 空" % i)
	print("==============================")

# 重置所有存档（危险操作）
func debug_reset_all_saves() -> void:
	if not OS.is_debug_build():
		return
	
	for i in range(MAX_SAVE_SLOTS):
		delete_save(i)
	
	current_save = null
	current_slot = -1
	print("[SaveManager] 所有存档已重置")

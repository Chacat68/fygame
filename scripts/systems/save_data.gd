# 存档数据类
# 定义游戏存档的数据结构
class_name SaveData
extends Resource

# 存档元数据
@export var save_slot: int = 0                    # 存档槽位 (0-2)
@export var save_name: String = "存档"            # 存档名称
@export var save_timestamp: int = 0               # 存档时间戳
@export var play_time: float = 0.0                # 游戏时长（秒）
@export var save_version: String = "1.0"          # 存档版本

# 玩家进度数据
@export var current_level: int = 1                # 当前关卡
@export var max_unlocked_level: int = 1           # 最大已解锁关卡
@export var completed_levels: Dictionary = {}     # 已完成关卡 {关卡ID: 完成数据}

# 玩家资源数据
@export var total_coins: int = 0                  # 总金币数
@export var current_health: int = 100             # 当前血量

# 技能数据
@export var unlocked_skills: Array[String] = []   # 已解锁技能列表
@export var skill_levels: Dictionary = {}         # 技能等级 {技能名: 等级}

# 游戏设置
@export var music_volume: float = 1.0             # 音乐音量
@export var sfx_volume: float = 1.0               # 音效音量

# 统计数据
@export var total_deaths: int = 0                 # 总死亡次数
@export var total_kills: int = 0                  # 总击杀次数
@export var total_coins_collected: int = 0        # 总收集金币数

# 创建新存档
static func create_new(slot: int = 0) -> SaveData:
	var save = SaveData.new()
	save.save_slot = slot
	save.save_name = "存档 %d" % (slot + 1)
	save.save_timestamp = int(Time.get_unix_time_from_system())
	save.save_version = "1.0"
	save.current_level = 1
	save.max_unlocked_level = 1
	save.completed_levels = {}
	save.total_coins = 0
	save.current_health = 100
	save.unlocked_skills = [] as Array[String]
	save.skill_levels = {}
	save.music_volume = 1.0
	save.sfx_volume = 1.0
	save.total_deaths = 0
	save.total_kills = 0
	save.total_coins_collected = 0
	save.play_time = 0.0
	return save

# 从字典创建存档
static func from_dictionary(data: Dictionary) -> SaveData:
	var save = SaveData.new()
	
	# 元数据
	save.save_slot = data.get("save_slot", 0)
	save.save_name = data.get("save_name", "存档")
	save.save_timestamp = data.get("save_timestamp", 0)
	save.play_time = data.get("play_time", 0.0)
	save.save_version = data.get("save_version", "1.0")
	
	# 玩家进度
	save.current_level = data.get("current_level", 1)
	save.max_unlocked_level = data.get("max_unlocked_level", 1)
	save.completed_levels = data.get("completed_levels", {})
	
	# 玩家资源
	save.total_coins = data.get("total_coins", 0)
	save.current_health = data.get("current_health", 100)
	
	# 技能数据
	var skills_array = data.get("unlocked_skills", [])
	save.unlocked_skills = [] as Array[String]
	for skill in skills_array:
		save.unlocked_skills.append(str(skill))
	save.skill_levels = data.get("skill_levels", {})
	
	# 游戏设置
	save.music_volume = data.get("music_volume", 1.0)
	save.sfx_volume = data.get("sfx_volume", 1.0)
	
	# 统计数据
	save.total_deaths = data.get("total_deaths", 0)
	save.total_kills = data.get("total_kills", 0)
	save.total_coins_collected = data.get("total_coins_collected", 0)
	
	return save

# 转换为字典（用于JSON序列化）
func to_dictionary() -> Dictionary:
	return {
		# 元数据
		"save_slot": save_slot,
		"save_name": save_name,
		"save_timestamp": save_timestamp,
		"play_time": play_time,
		"save_version": save_version,
		
		# 玩家进度
		"current_level": current_level,
		"max_unlocked_level": max_unlocked_level,
		"completed_levels": completed_levels,
		
		# 玩家资源
		"total_coins": total_coins,
		"current_health": current_health,
		
		# 技能数据
		"unlocked_skills": unlocked_skills,
		"skill_levels": skill_levels,
		
		# 游戏设置
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		
		# 统计数据
		"total_deaths": total_deaths,
		"total_kills": total_kills,
		"total_coins_collected": total_coins_collected
	}

# 获取格式化的存档时间
func get_formatted_save_time() -> String:
	if save_timestamp == 0:
		return "未知时间"
	
	var datetime = Time.get_datetime_dict_from_unix_time(save_timestamp)
	return "%d年%02d月%02d日 %02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute
	]

# 获取格式化的游戏时长
func get_formatted_play_time() -> String:
	var hours = int(play_time / 3600)
	var minutes = int(fmod(play_time, 3600) / 60)
	var seconds = int(fmod(play_time, 60))
	
	if hours > 0:
		return "%d小时%02d分%02d秒" % [hours, minutes, seconds]
	elif minutes > 0:
		return "%d分%02d秒" % [minutes, seconds]
	else:
		return "%d秒" % seconds

# 获取存档摘要信息
func get_summary() -> String:
	return "关卡: %d | 金币: %d | 时长: %s" % [
		current_level, total_coins, get_formatted_play_time()
	]

# 验证存档数据
func validate() -> bool:
	print("[SaveData] 验证存档: slot=%d, current_level=%d, max_unlocked_level=%d, total_coins=%d" % [save_slot, current_level, max_unlocked_level, total_coins])
	
	# 检查基础数据有效性
	if save_slot < 0 or save_slot > 2:
		print("[SaveData] 验证失败: 无效槽位 %d" % save_slot)
		return false
	if current_level < 1:
		print("[SaveData] 自动修复: current_level 从 %d 改为 1" % current_level)
		current_level = 1
	
	# 自动修复：确保 max_unlocked_level >= current_level
	if max_unlocked_level < current_level:
		print("[SaveData] 自动修复: max_unlocked_level 从 %d 更新为 %d" % [max_unlocked_level, current_level])
		max_unlocked_level = current_level
	
	if total_coins < 0:
		print("[SaveData] 自动修复: total_coins 从 %d 改为 0" % total_coins)
		total_coins = 0
	
	print("[SaveData] 验证通过")
	return true

# 复制存档数据
func duplicate_save() -> SaveData:
	var copy = SaveData.new()
	
	copy.save_slot = save_slot
	copy.save_name = save_name
	copy.save_timestamp = save_timestamp
	copy.play_time = play_time
	copy.save_version = save_version
	
	copy.current_level = current_level
	copy.max_unlocked_level = max_unlocked_level
	copy.completed_levels = completed_levels.duplicate()
	
	copy.total_coins = total_coins
	copy.current_health = current_health
	
	copy.unlocked_skills = [] as Array[String]
	for skill in unlocked_skills:
		copy.unlocked_skills.append(skill)
	copy.skill_levels = skill_levels.duplicate()
	
	copy.music_volume = music_volume
	copy.sfx_volume = sfx_volume
	
	copy.total_deaths = total_deaths
	copy.total_kills = total_kills
	copy.total_coins_collected = total_coins_collected
	
	return copy

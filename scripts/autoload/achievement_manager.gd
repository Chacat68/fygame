# 成就管理器 (AutoLoad)
# 负责管理游戏成就的解锁、进度追踪和通知
class_name AchievementManager
extends Node

# 信号
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress(achievement_id: String, current: int, target: int)
signal all_achievements_unlocked()

# 成就定义
var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []
var achievement_progress_data: Dictionary = {}

# 成就通知队列
var notification_queue: Array[Dictionary] = []
var is_showing_notification: bool = false

func _ready() -> void:
	_initialize_achievements()
	print("[AchievementManager] 成就管理器已初始化，共 %d 个成就" % achievements.size())

## 初始化成就定义
func _initialize_achievements() -> void:
	# 收集类成就
	_register_achievement("first_coin", {
		"name": "初次收获",
		"description": "收集第一枚金币",
		"icon": "coin",
		"target": 1,
		"type": "collect_coins",
		"reward_coins": 10,
		"hidden": false
	})
	
	_register_achievement("coin_collector", {
		"name": "金币收藏家",
		"description": "收集100枚金币",
		"icon": "coin",
		"target": 100,
		"type": "collect_coins",
		"reward_coins": 50,
		"hidden": false
	})
	
	_register_achievement("coin_master", {
		"name": "金币大师",
		"description": "收集1000枚金币",
		"icon": "coin",
		"target": 1000,
		"type": "collect_coins",
		"reward_coins": 200,
		"hidden": false
	})
	
	# 击杀类成就
	_register_achievement("first_blood", {
		"name": "初战告捷",
		"description": "击杀第一个敌人",
		"icon": "sword",
		"target": 1,
		"type": "kill_enemies",
		"reward_coins": 10,
		"hidden": false
	})
	
	_register_achievement("slime_hunter", {
		"name": "史莱姆猎手",
		"description": "击杀50个史莱姆",
		"icon": "sword",
		"target": 50,
		"type": "kill_slimes",
		"reward_coins": 100,
		"hidden": false
	})
	
	_register_achievement("monster_slayer", {
		"name": "怪物杀手",
		"description": "击杀100个敌人",
		"icon": "sword",
		"target": 100,
		"type": "kill_enemies",
		"reward_coins": 150,
		"hidden": false
	})
	
	# 关卡类成就
	_register_achievement("level_complete_1", {
		"name": "冒险开始",
		"description": "完成第一关",
		"icon": "flag",
		"target": 1,
		"type": "complete_level",
		"level_id": 1,
		"reward_coins": 50,
		"hidden": false
	})
	
	_register_achievement("speedrunner", {
		"name": "速通达人",
		"description": "在60秒内完成任意关卡",
		"icon": "clock",
		"target": 60,
		"type": "speedrun",
		"reward_coins": 100,
		"hidden": false
	})
	
	_register_achievement("perfectionist", {
		"name": "完美主义者",
		"description": "在一关中收集所有金币",
		"icon": "star",
		"target": 1,
		"type": "perfect_level",
		"reward_coins": 150,
		"hidden": false
	})
	
	# 技能类成就
	_register_achievement("skill_learner", {
		"name": "技能学徒",
		"description": "解锁第一个技能",
		"icon": "skill",
		"target": 1,
		"type": "unlock_skill",
		"reward_coins": 30,
		"hidden": false
	})
	
	_register_achievement("skill_master", {
		"name": "技能大师",
		"description": "解锁所有技能",
		"icon": "skill",
		"target": 3,
		"type": "unlock_all_skills",
		"reward_coins": 200,
		"hidden": false
	})
	
	# 探索类成就
	_register_achievement("explorer", {
		"name": "探索者",
		"description": "发现一个隐藏区域",
		"icon": "compass",
		"target": 1,
		"type": "find_secret",
		"reward_coins": 50,
		"hidden": true
	})
	
	_register_achievement("death_defier", {
		"name": "死亡挑战者",
		"description": "死亡10次后继续游戏",
		"icon": "skull",
		"target": 10,
		"type": "deaths",
		"reward_coins": 25,
		"hidden": true
	})
	
	# 挑战类成就
	_register_achievement("no_damage", {
		"name": "无伤通关",
		"description": "不受伤完成一个关卡",
		"icon": "shield",
		"target": 1,
		"type": "no_damage_level",
		"reward_coins": 200,
		"hidden": false
	})
	
	_register_achievement("stomp_master", {
		"name": "踩踏大师",
		"description": "踩踏击杀20个敌人",
		"icon": "boot",
		"target": 20,
		"type": "stomp_kills",
		"reward_coins": 100,
		"hidden": false
	})

## 注册成就
func _register_achievement(achievement_id: String, data: Dictionary) -> void:
	data["id"] = achievement_id
	data["unlocked"] = false
	achievements[achievement_id] = data
	achievement_progress_data[achievement_id] = 0

## 更新成就进度
func update_progress(achievement_type: String, amount: int = 1, extra_data: Dictionary = {}) -> void:
	for achievement_id in achievements.keys():
		var achievement = achievements[achievement_id]
		
		if achievement["unlocked"]:
			continue
		
		if achievement["type"] != achievement_type:
			continue
		
		# 检查额外条件
		if not _check_extra_conditions(achievement, extra_data):
			continue
		
		# 更新进度
		achievement_progress_data[achievement_id] += amount
		var current = achievement_progress_data[achievement_id]
		var target = achievement["target"]
		
		achievement_progress.emit(achievement_id, current, target)
		
		# 检查是否解锁
		if current >= target:
			_unlock_achievement(achievement_id)

## 检查额外条件
func _check_extra_conditions(achievement: Dictionary, extra_data: Dictionary) -> bool:
	# 检查关卡ID
	if achievement.has("level_id") and extra_data.has("level_id"):
		if achievement["level_id"] != extra_data["level_id"]:
			return false
	
	return true

## 解锁成就
func _unlock_achievement(achievement_id: String) -> void:
	if achievement_id not in achievements:
		return
	
	if achievement_id in unlocked_achievements:
		return
	
	var achievement = achievements[achievement_id]
	achievement["unlocked"] = true
	unlocked_achievements.append(achievement_id)
	
	# 发放奖励
	if achievement.has("reward_coins") and GameState:
		GameState.add_coins(achievement["reward_coins"])
	
	# 发射信号
	achievement_unlocked.emit(achievement_id, achievement)
	
	# 添加到通知队列
	_queue_notification(achievement)
	
	# 检查是否全部解锁
	if unlocked_achievements.size() >= achievements.size():
		all_achievements_unlocked.emit()
	
	print("[AchievementManager] 成就解锁: %s - %s" % [achievement["name"], achievement["description"]])

## 添加到通知队列
func _queue_notification(achievement: Dictionary) -> void:
	notification_queue.append(achievement)
	
	if not is_showing_notification:
		_show_next_notification()

## 显示下一个通知
func _show_next_notification() -> void:
	if notification_queue.is_empty():
		is_showing_notification = false
		return
	
	is_showing_notification = true
	var achievement = notification_queue.pop_front()
	
	# 显示成就解锁UI（通过信号让UI处理）
	# 这里可以创建一个简单的通知
	print("🏆 成就解锁: %s" % achievement["name"])
	
	# 延迟显示下一个
	await get_tree().create_timer(3.0).timeout
	_show_next_notification()

## 手动解锁成就（用于特殊条件）
func unlock(achievement_id: String) -> void:
	if achievement_id in achievements and achievement_id not in unlocked_achievements:
		achievement_progress_data[achievement_id] = achievements[achievement_id]["target"]
		_unlock_achievement(achievement_id)

## 获取成就信息
func get_achievement(achievement_id: String) -> Dictionary:
	if achievements.has(achievement_id):
		var data = achievements[achievement_id].duplicate()
		data["progress"] = achievement_progress_data.get(achievement_id, 0)
		return data
	return {}

## 获取所有成就
func get_all_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for achievement_id in achievements.keys():
		var achievement = get_achievement(achievement_id)
		# 不返回隐藏的未解锁成就
		if achievement["hidden"] and not achievement["unlocked"]:
			continue
		result.append(achievement)
	return result

## 获取解锁进度
func get_unlock_progress() -> Dictionary:
	return {
		"unlocked": unlocked_achievements.size(),
		"total": achievements.size(),
		"percentage": float(unlocked_achievements.size()) / float(achievements.size()) * 100.0
	}

## 是否已解锁
func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

## 保存数据
func save_data() -> Dictionary:
	return {
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"achievement_progress": achievement_progress_data.duplicate()
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.has("unlocked_achievements"):
		unlocked_achievements = data["unlocked_achievements"].duplicate()
		for achievement_id in unlocked_achievements:
			if achievements.has(achievement_id):
				achievements[achievement_id]["unlocked"] = true
	
	if data.has("achievement_progress"):
		for key in data["achievement_progress"].keys():
			achievement_progress_data[key] = data["achievement_progress"][key]

## 重置所有成就（调试用）
func reset_all() -> void:
	unlocked_achievements.clear()
	for achievement_id in achievements.keys():
		achievements[achievement_id]["unlocked"] = false
		achievement_progress_data[achievement_id] = 0

# 游戏统计管理器 (AutoLoad)
# 负责追踪和管理所有游戏统计数据
class_name GameStatsManagerClass
extends Node

# 信号
signal stats_updated(stat_name: String, value: Variant)
signal milestone_reached(milestone_name: String, value: int)

# 会话统计（本次游戏会话）
var session_stats: Dictionary = {
	"play_time": 0.0,
	"coins_collected": 0,
	"enemies_killed": 0,
	"deaths": 0,
	"jumps": 0,
	"dashes_used": 0,
	"wall_jumps": 0,
	"levels_completed": 0,
	"secrets_found": 0,
	"damage_taken": 0,
	"damage_dealt": 0,
	"distance_traveled": 0.0,
	"highest_combo": 0,
	"stomp_kills": 0
}

# 总计统计（所有游戏会话）
var total_stats: Dictionary = {
	"total_play_time": 0.0,
	"total_coins_collected": 0,
	"total_enemies_killed": 0,
	"total_deaths": 0,
	"total_jumps": 0,
	"total_dashes_used": 0,
	"total_wall_jumps": 0,
	"total_levels_completed": 0,
	"total_secrets_found": 0,
	"total_damage_taken": 0,
	"total_damage_dealt": 0,
	"total_distance_traveled": 0.0,
	"best_combo": 0,
	"total_stomp_kills": 0,
	"games_played": 0,
	"fastest_level_time": {},  # 按关卡ID存储最快时间
	"perfect_levels": []  # 无伤通关的关卡
}

# 里程碑定义
var milestones: Dictionary = {
	"coins_100": {"stat": "total_coins_collected", "value": 100, "name": "收集100枚金币"},
	"coins_1000": {"stat": "total_coins_collected", "value": 1000, "name": "收集1000枚金币"},
	"kills_50": {"stat": "total_enemies_killed", "value": 50, "name": "击杀50个敌人"},
	"kills_100": {"stat": "total_enemies_killed", "value": 100, "name": "击杀100个敌人"},
	"deaths_10": {"stat": "total_deaths", "value": 10, "name": "死亡10次"},
	"play_1hour": {"stat": "total_play_time", "value": 3600, "name": "游戏1小时"},
	"jumps_1000": {"stat": "total_jumps", "value": 1000, "name": "跳跃1000次"},
	"stomp_20": {"stat": "total_stomp_kills", "value": 20, "name": "踩踏击杀20个敌人"}
}

var reached_milestones: Array[String] = []

# 玩家位置追踪
var last_player_position: Vector2 = Vector2.ZERO
var is_tracking: bool = false

func _ready() -> void:
	print("[GameStatsManager] 游戏统计管理器已初始化")

func _process(delta: float) -> void:
	if is_tracking:
		session_stats["play_time"] += delta
		_track_player_distance()

## 开始追踪统计
func start_tracking() -> void:
	is_tracking = true
	total_stats["games_played"] += 1
	print("[GameStatsManager] 开始追踪统计")

## 停止追踪统计
func stop_tracking() -> void:
	is_tracking = false
	_merge_session_to_total()
	print("[GameStatsManager] 停止追踪统计")

## 追踪玩家移动距离
func _track_player_distance() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if last_player_position != Vector2.ZERO:
			var distance = player.global_position.distance_to(last_player_position)
			if distance < 100:  # 忽略传送等大距离移动
				session_stats["distance_traveled"] += distance
		last_player_position = player.global_position

## 合并会话统计到总计
func _merge_session_to_total() -> void:
	total_stats["total_play_time"] += session_stats["play_time"]
	total_stats["total_coins_collected"] += session_stats["coins_collected"]
	total_stats["total_enemies_killed"] += session_stats["enemies_killed"]
	total_stats["total_deaths"] += session_stats["deaths"]
	total_stats["total_jumps"] += session_stats["jumps"]
	total_stats["total_dashes_used"] += session_stats["dashes_used"]
	total_stats["total_wall_jumps"] += session_stats["wall_jumps"]
	total_stats["total_levels_completed"] += session_stats["levels_completed"]
	total_stats["total_secrets_found"] += session_stats["secrets_found"]
	total_stats["total_damage_taken"] += session_stats["damage_taken"]
	total_stats["total_damage_dealt"] += session_stats["damage_dealt"]
	total_stats["total_distance_traveled"] += session_stats["distance_traveled"]
	total_stats["total_stomp_kills"] += session_stats["stomp_kills"]
	
	if session_stats["highest_combo"] > total_stats["best_combo"]:
		total_stats["best_combo"] = session_stats["highest_combo"]
	
	_check_milestones()

## 检查里程碑
func _check_milestones() -> void:
	for milestone_id in milestones.keys():
		if milestone_id in reached_milestones:
			continue
		
		var milestone = milestones[milestone_id]
		var current_value = total_stats.get(milestone["stat"], 0)
		
		if current_value >= milestone["value"]:
			reached_milestones.append(milestone_id)
			milestone_reached.emit(milestone["name"], milestone["value"])
			
			# 触发成就
			if AchievementManager:
				AchievementManager.update_progress(milestone["stat"], 0)

## 增加统计
func add_stat(stat_name: String, amount: int = 1) -> void:
	if session_stats.has(stat_name):
		session_stats[stat_name] += amount
		stats_updated.emit(stat_name, session_stats[stat_name])
		
		# 同步更新成就进度
		_sync_achievement_progress(stat_name, amount)

## 设置统计
func set_stat(stat_name: String, value: Variant) -> void:
	if session_stats.has(stat_name):
		session_stats[stat_name] = value
		stats_updated.emit(stat_name, value)

## 获取会话统计
func get_session_stat(stat_name: String) -> Variant:
	return session_stats.get(stat_name, 0)

## 获取总计统计
func get_total_stat(stat_name: String) -> Variant:
	return total_stats.get(stat_name, 0)

## 同步成就进度
func _sync_achievement_progress(stat_name: String, amount: int) -> void:
	if not AchievementManager:
		return
	
	match stat_name:
		"coins_collected":
			AchievementManager.update_progress("collect_coins", amount)
		"enemies_killed":
			AchievementManager.update_progress("kill_enemies", amount)
		"deaths":
			AchievementManager.update_progress("deaths", amount)
		"stomp_kills":
			AchievementManager.update_progress("stomp_kills", amount)
		"secrets_found":
			AchievementManager.update_progress("find_secret", amount)

## 记录关卡完成
func record_level_completion(level_id: int, time: float, stars: int, no_damage: bool) -> void:
	session_stats["levels_completed"] += 1
	
	# 记录最快时间
	var level_key = str(level_id)
	if not total_stats["fastest_level_time"].has(level_key) or time < total_stats["fastest_level_time"][level_key]:
		total_stats["fastest_level_time"][level_key] = time
	
	# 记录无伤通关
	if no_damage and level_key not in total_stats["perfect_levels"]:
		total_stats["perfect_levels"].append(level_key)
		if AchievementManager:
			AchievementManager.update_progress("no_damage_level", 1)
	
	# 速通成就
	if time <= 60.0:
		if AchievementManager:
			AchievementManager.update_progress("speedrun", 1)
	
	# 关卡完成成就
	if AchievementManager:
		AchievementManager.update_progress("complete_level", 1, {"level_id": level_id})

## 重置会话统计
func reset_session_stats() -> void:
	for key in session_stats.keys():
		if session_stats[key] is float:
			session_stats[key] = 0.0
		else:
			session_stats[key] = 0
	
	last_player_position = Vector2.ZERO

## 获取格式化的游戏时间
func get_formatted_play_time() -> String:
	var total_seconds = int(total_stats["total_play_time"])
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%d小时 %d分 %d秒" % [hours, minutes, seconds]

## 获取统计摘要
func get_stats_summary() -> Dictionary:
	return {
		"play_time": get_formatted_play_time(),
		"total_coins": total_stats["total_coins_collected"],
		"total_kills": total_stats["total_enemies_killed"],
		"total_deaths": total_stats["total_deaths"],
		"levels_completed": total_stats["total_levels_completed"],
		"best_combo": total_stats["best_combo"],
		"distance_km": "%.2f km" % (total_stats["total_distance_traveled"] / 1000.0),
		"games_played": total_stats["games_played"],
		"perfect_levels": total_stats["perfect_levels"].size()
	}

## 保存数据
func save_data() -> Dictionary:
	_merge_session_to_total()
	return {
		"total_stats": total_stats.duplicate(true),
		"reached_milestones": reached_milestones.duplicate()
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.has("total_stats"):
		for key in data["total_stats"].keys():
			if total_stats.has(key):
				total_stats[key] = data["total_stats"][key]
	
	if data.has("reached_milestones"):
		reached_milestones = data["reached_milestones"].duplicate()

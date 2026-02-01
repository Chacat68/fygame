# 关卡计时和评分系统
# 负责追踪关卡完成时间、计算评分和显示结果
class_name LevelTimer
extends Node

# 信号
signal timer_started()
signal timer_stopped(time: float)
signal time_updated(time: float)
signal score_calculated(score_data: Dictionary)

# 计时状态
var is_running: bool = false
var elapsed_time: float = 0.0
var pause_time: float = 0.0

# 关卡数据
var level_id: int = 0
var level_start_coins: int = 0
var level_start_health: int = 0
var damage_taken: int = 0
var enemies_killed: int = 0
var coins_collected: int = 0
var secrets_found: int = 0

# 评分标准（从配置加载）
var time_thresholds: Dictionary = {
	"three_star": 60.0,   # 3星时间阈值
	"two_star": 90.0,     # 2星时间阈值
	"one_star": 120.0     # 1星时间阈值
}

# 分数权重
var score_weights: Dictionary = {
	"time_bonus": 1000,      # 时间奖励基础分
	"kill_bonus": 50,        # 每个击杀奖励
	"coin_bonus": 10,        # 每个金币奖励
	"no_damage_bonus": 500,  # 无伤奖励
	"secret_bonus": 200      # 每个秘密奖励
}

func _ready() -> void:
	print("[LevelTimer] 关卡计时器已初始化")

func _process(delta: float) -> void:
	if is_running:
		elapsed_time += delta
		time_updated.emit(elapsed_time)

## 开始计时
func start_timer(current_level_id: int = 0) -> void:
	level_id = current_level_id
	elapsed_time = 0.0
	damage_taken = 0
	enemies_killed = 0
	coins_collected = 0
	secrets_found = 0
	is_running = true
	
	# 记录初始状态
	var player = get_tree().get_first_node_in_group("player")
	if player:
		level_start_health = player.current_health if "current_health" in player else 100
	
	if GameState:
		level_start_coins = GameState.get_coins()
	
	timer_started.emit()
	print("[LevelTimer] 计时开始 - 关卡 %d" % level_id)

## 停止计时
func stop_timer() -> void:
	if not is_running:
		return
	
	is_running = false
	timer_stopped.emit(elapsed_time)
	
	# 计算收集的金币
	if GameState:
		coins_collected = GameState.get_coins() - level_start_coins
	
	print("[LevelTimer] 计时停止 - 用时: %.2f秒" % elapsed_time)

## 暂停计时
func pause_timer() -> void:
	if is_running:
		is_running = false
		pause_time = elapsed_time

## 恢复计时
func resume_timer() -> void:
	is_running = true

## 记录伤害
func record_damage(amount: int) -> void:
	damage_taken += amount

## 记录击杀
func record_kill() -> void:
	enemies_killed += 1

## 记录金币收集
func record_coin(amount: int = 1) -> void:
	coins_collected += amount

## 记录秘密发现
func record_secret() -> void:
	secrets_found += 1

## 计算星级评分
func calculate_stars() -> int:
	if elapsed_time <= time_thresholds["three_star"]:
		return 3
	elif elapsed_time <= time_thresholds["two_star"]:
		return 2
	elif elapsed_time <= time_thresholds["one_star"]:
		return 1
	return 0

## 计算总分
func calculate_score() -> Dictionary:
	stop_timer()
	
	var stars = calculate_stars()
	
	# 计算时间奖励（越快越高）
	var time_bonus = 0
	if elapsed_time > 0:
		var max_time = time_thresholds["one_star"]
		var time_factor = clamp((max_time - elapsed_time) / max_time, 0.0, 1.0)
		time_bonus = int(score_weights["time_bonus"] * time_factor)
	
	# 击杀奖励
	var kill_bonus = enemies_killed * score_weights["kill_bonus"]
	
	# 金币奖励
	var coin_bonus = coins_collected * score_weights["coin_bonus"]
	
	# 无伤奖励
	var no_damage_bonus = 0
	if damage_taken == 0:
		no_damage_bonus = score_weights["no_damage_bonus"]
	
	# 秘密奖励
	var secret_bonus = secrets_found * score_weights["secret_bonus"]
	
	# 计算总分
	var total_score = time_bonus + kill_bonus + coin_bonus + no_damage_bonus + secret_bonus
	
	var score_data = {
		"level_id": level_id,
		"elapsed_time": elapsed_time,
		"stars": stars,
		"total_score": total_score,
		"time_bonus": time_bonus,
		"kill_bonus": kill_bonus,
		"coin_bonus": coin_bonus,
		"no_damage_bonus": no_damage_bonus,
		"secret_bonus": secret_bonus,
		"enemies_killed": enemies_killed,
		"coins_collected": coins_collected,
		"secrets_found": secrets_found,
		"damage_taken": damage_taken,
		"is_no_damage": damage_taken == 0,
		"formatted_time": format_time(elapsed_time)
	}
	
	score_calculated.emit(score_data)
	
	# 记录到统计系统
	_record_to_stats(score_data)
	
	return score_data

## 记录到统计系统
func _record_to_stats(score_data: Dictionary) -> void:
	var stats_mgr = get_node_or_null("/root/GameStatsManager")
	if stats_mgr:
		stats_mgr.record_level_completion(
			score_data["level_id"],
			score_data["elapsed_time"],
			score_data["stars"],
			score_data["is_no_damage"]
		)

## 格式化时间
func format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	var ms = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, secs, ms]

## 获取当前时间
func get_elapsed_time() -> float:
	return elapsed_time

## 获取格式化的当前时间
func get_formatted_time() -> String:
	return format_time(elapsed_time)

## 设置时间阈值（用于不同关卡）
func set_time_thresholds(three_star: float, two_star: float, one_star: float) -> void:
	time_thresholds["three_star"] = three_star
	time_thresholds["two_star"] = two_star
	time_thresholds["one_star"] = one_star

## 重置计时器
func reset() -> void:
	is_running = false
	elapsed_time = 0.0
	pause_time = 0.0
	damage_taken = 0
	enemies_killed = 0
	coins_collected = 0
	secrets_found = 0

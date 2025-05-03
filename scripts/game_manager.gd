extends Node

# 游戏状态
var score = 0
var kill_count = 0

# 组件引用
@onready var ui = get_node_or_null("/root/Game/UI")

# 信号
signal score_changed(new_score)
signal kill_count_changed(new_count)

# 定义一个函数，用于增加分数并更新分数显示
func add_point():
	score += 1
	kill_count += 1
	emit_signal("score_changed", score)
	emit_signal("kill_count_changed", kill_count)
	
	# 更新UI
	if ui:
		ui.add_coin()
		ui.update_kill_count(kill_count)

# 重置游戏分数
func reset_score():
	score = 0
	kill_count = 0
	emit_signal("score_changed", score)
	emit_signal("kill_count_changed", kill_count)
	
	if ui:
		ui.update_coin_count(0)
		ui.update_kill_count(0)

# 获取当前关卡的死亡高度
func get_death_height():
	# 默认死亡高度
	var default_height = 500
	
	# 获取当前场景名称
	var current_scene = get_tree().get_current_scene().name
	
	# 根据不同关卡返回不同的死亡高度
	match current_scene:
		"Game":
			return 500
		"RandomLevel":
			return 600
		"MountainCaveLevel":
			return 800
		_:
			return default_height

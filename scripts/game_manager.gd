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

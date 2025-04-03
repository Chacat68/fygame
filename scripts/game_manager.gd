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
	emit_signal("score_changed", score)
	
	# 更新UI
	if ui:
		ui.add_coin()

# 重置游戏分数
func reset_score():
	score = 0
	emit_signal("score_changed", score)
	
	if ui:
		ui.update_coin_count(0)

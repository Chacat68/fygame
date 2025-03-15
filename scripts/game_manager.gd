extends Node

# 初始化分数为0
var score = 0

# 获取UI节点
@onready var ui = get_node_or_null("/root/Game/UI")

# 定义一个函数，用于增加分数并更新分数显示
func add_point():
	score += 1  # 分数增加1
	
	# 如果UI节点存在，调用其add_coin方法
	if ui:
		ui.add_coin()

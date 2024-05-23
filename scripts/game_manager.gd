extends Node

# 初始化分数为0
var score = 0

# 获取ScoreLabel节点
@onready var score_label = $ScoreLabel

# 定义一个函数，用于增加分数并更新分数显示
func add_point():
	score += 1  # 分数增加1
	score_label.text = "获得" + str(score) + "金币"  # 更新分数显示
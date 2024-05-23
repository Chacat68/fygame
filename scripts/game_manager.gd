extends Node

var score =0

@onready var score_label = $ScoreLabel

func add_point():
	score += 1
	score_label.text = "获得" + str(score) + "金币"

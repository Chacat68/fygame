extends Node

# 全局游戏状态变量
var player_respawning = false  # 玩家是否正在复活

# 设置玩家复活状态
func set_player_respawning(value):
	player_respawning = value
	# 打印调试信息
	print("设置玩家复活状态: " + str(value))
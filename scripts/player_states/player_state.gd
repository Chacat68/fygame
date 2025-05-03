# 玩家状态基类
class_name PlayerState
extends Node

# 状态拥有者引用
var player: CharacterBody2D

# 构造函数
func _init(player_ref: CharacterBody2D):
	self.player = player_ref

# 进入状态时调用
func enter():
	pass

# 退出状态时调用
func exit():
	pass

# 处理物理更新
func physics_process(_delta: float):
	pass

# 处理输入
func handle_input():
	pass

# 更新动画
func update_animation():
	pass

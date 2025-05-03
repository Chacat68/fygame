extends Control

# 多关卡菜单脚本
# 用于管理多关卡游戏的入口界面

# 在准备好时调用
func _ready():
	# 设置按钮焦点
	$StartButton.grab_focus()

# 当开始按钮被按下时调用
func _on_start_button_pressed():
	# 切换到多关卡游戏场景
	get_tree().change_scene_to_file("res://scenes/multi_level_game.tscn")

# 当返回按钮被按下时调用
func _on_back_button_pressed():
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
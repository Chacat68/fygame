extends Control

# 主菜单脚本
# 用于处理主菜单的按钮点击事件和场景切换

# 在准备好时调用
func _ready():
	# 设置按钮焦点
	$VBoxContainer/StartButton.grab_focus()

# 固定关卡按钮点击事件
func _on_fixed_level_button_pressed():
	# 切换到固定关卡场景（山洞探险）
	get_tree().change_scene_to_file("res://scenes/mountain_cave_level.tscn")

# 退出按钮点击事件
func _on_quit_button_pressed():
	# 退出游戏
	get_tree().quit()

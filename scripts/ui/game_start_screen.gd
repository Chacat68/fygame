extends Control

# 游戏开始画面脚本
# 用于处理游戏开始画面的按钮点击事件和场景切换

# 在准备好时调用
func _ready():
	# 延迟调用grab_focus，确保节点已完全准备好
	call_deferred("set_button_focus")
	
	# 检查是否有存档，更新"继续冒险"按钮状态
	_update_continue_button_state()

# 设置按钮焦点的辅助函数
func set_button_focus():
	if has_node("MenuPanel/VBoxContainer/StartButton"):
		$MenuPanel/VBoxContainer/StartButton.grab_focus()
	else:
		print("警告：无法找到开始按钮节点")

# 更新继续冒险按钮状态
func _update_continue_button_state():
	var continue_button = get_node_or_null("MenuPanel/VBoxContainer/ContinueButton")
	if continue_button and SaveManager:
		# 检查是否有任何存档
		var has_any_save = false
		for i in range(SaveManager.MAX_SAVE_SLOTS):
			if SaveManager.has_save(i):
				has_any_save = true
				break
		
		# 如果没有存档，禁用或隐藏继续按钮
		continue_button.disabled = not has_any_save
		if not has_any_save:
			continue_button.tooltip_text = "没有找到存档"

# 开始新游戏按钮点击事件
func _on_start_button_pressed():
	# 打开存档界面，选择存档槽位开始新游戏
	get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")

# 继续冒险按钮点击事件
func _on_continue_button_pressed():
	# 打开存档界面，选择存档继续游戏
	get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")

# 结束游戏按钮点击事件
func _on_quit_button_pressed():
	# 退出游戏前保存当前存档
	if SaveManager and SaveManager.get_current_save() != null:
		SaveManager.save_game()
	
	# 退出游戏
	get_tree().quit()

# 安全获取游戏状态节点的辅助方法
func _get_game_state():
	# 优先从自动加载中获取 GameState
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		return game_state
	
	# 如果自动加载不存在，尝试在场景中查找
	var game_states = get_tree().get_nodes_in_group("game_state")
	if game_states.size() > 0:
		return game_states[0]
	
	return null

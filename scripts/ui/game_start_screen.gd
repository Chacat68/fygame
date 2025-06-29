extends Control

# 游戏开始画面脚本
# 用于处理游戏开始画面的按钮点击事件和场景切换

# 在准备好时调用
func _ready():
	# 延迟调用grab_focus，确保节点已完全准备好
	call_deferred("set_button_focus")

# 设置按钮焦点的辅助函数
func set_button_focus():
	if has_node("VBoxContainer/StartButton"):
		$VBoxContainer/StartButton.grab_focus()
	else:
		print("警告：无法找到开始按钮节点")

# 开始新游戏按钮点击事件
func _on_start_button_pressed():
	# 重置游戏进度并开始新游戏
	
	# 如果存在游戏状态管理器，重置关卡进度
	var game_state = _get_game_state()
	if game_state != null:
		game_state.reset_game_progress()
	
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/game.tscn")

# 继续冒险按钮点击事件
func _on_continue_button_pressed():
	# 加载存档并继续游戏
	
	# 如果存在游戏状态管理器，加载存档
	var game_state = _get_game_state()
	if game_state != null:
		game_state.load_game_progress()
	
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/game.tscn")

# 结束游戏按钮点击事件
func _on_quit_button_pressed():
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

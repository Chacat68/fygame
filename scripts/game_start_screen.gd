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
	var game_state = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.reset_game_progress()
	
	# 切换到随机关卡场景，并确保从第1关开始
	var params = {
		"start_level": 1,  # 从第1关开始
		"new_game": true   # 标记为新游戏
	}
	
	# 使用SceneTree的change_scene_to_file方法切换场景
	get_tree().change_scene_to_file("res://scenes/random_level.tscn")
	
	# 在下一帧设置关卡参数
	call_deferred("_set_level_params", params)

# 继续冒险按钮点击事件
func _on_continue_button_pressed():
	# 加载存档并继续游戏
	
	# 如果存在游戏状态管理器，加载存档
	var game_state = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.load_game_progress()
	
	# 切换到随机关卡场景，并使用已保存的关卡进度
	var params = {
		"continue_game": true  # 标记为继续游戏
	}
	
	# 使用SceneTree的change_scene_to_file方法切换场景
	get_tree().change_scene_to_file("res://scenes/random_level.tscn")
	
	# 在下一帧设置关卡参数
	call_deferred("_set_level_params", params)

# 结束游戏按钮点击事件
func _on_quit_button_pressed():
	# 退出游戏
	get_tree().quit()

# 设置关卡参数的辅助函数
func _set_level_params(params):
	# 检查 SceneTree 是否可用
	if get_tree() == null:
		print("错误：无法获取场景树，可能是在场景切换过程中")
		return
	
	# 等待一帧确保场景已完全加载
	await get_tree().process_frame
	
	# 获取随机关卡生成器节点
	var level_generator = get_tree().current_scene
	if not level_generator or not level_generator.has_method("generate_level_by_number"):
		print("警告：当前场景不是随机关卡生成器")
		return
	
	# 如果找到了随机关卡生成器节点
	if level_generator != null:
		# 如果是新游戏，从第1关开始
		if params.has("start_level"):
			level_generator.current_level_number = params["start_level"]
			level_generator.generate_level_by_number(params["start_level"])
		# 如果是继续游戏，使用已保存的关卡进度
		elif params.has("continue_game") and params["continue_game"]:
			# 关卡生成器会自动加载已保存的关卡种子
			pass
	else:
		print("警告：无法找到随机关卡生成器节点")

extends Control

# 游戏开始画面脚本
# 用于处理游戏开始画面的按钮点击事件和场景切换

# 调试模式点击计数
var debug_click_count: int = 0
var debug_click_timer: float = 0.0
const DEBUG_CLICK_TIMEOUT: float = 2.0  # 2秒内完成点击
const DEBUG_CLICK_REQUIRED: int = 5     # 需要点击5次

# 在准备好时调用
func _ready():
	# 延迟调用grab_focus，确保节点已完全准备好
	call_deferred("set_button_focus")
	
	# 检查是否有存档，更新"继续冒险"按钮状态
	_update_continue_button_state()
	
	# 更新调试模式显示状态
	_update_debug_indicator()

# 设置按钮焦点的辅助函数
func set_button_focus():
	var start_btn = get_node_or_null("VBoxContainer/ButtonContainer/StartButton")
	if start_btn:
		start_btn.grab_focus()
	else:
		Logger.warn("GameStartScreen", "无法找到开始按钮节点")

# 更新继续冒险按钮状态
func _update_continue_button_state():
	var continue_button = get_node_or_null("ButtonContainer/ContinueButton")
	if not continue_button:
		Logger.debug("GameStartScreen", 找不到继续冒险按钮")
		return
	
	if not SaveManager:
		Logger.debug("GameStartScreen", SaveManager不可用")
		continue_button.disabled = true
		continue_button.tooltip_text = "存档系统不可用"
		return
	
	# 检查是否有任何存档
	var has_any_save = false
	for i in range(SaveManager.MAX_SAVE_SLOTS):
		if SaveManager.has_save(i):
			has_any_save = true
			Logger.debug("GameStartScreen", 找到存档，槽位: %d" % i)
			break
	
	# 如果没有存档，禁用继续按钮
	continue_button.disabled = not has_any_save
	if not has_any_save:
		continue_button.tooltip_text = "没有找到存档"
		Logger.debug("GameStartScreen", 没有找到任何存档，禁用继续按钮")
	else:
		continue_button.tooltip_text = ""
		Logger.debug("GameStartScreen", 存档可用，启用继续按钮")

# 头杆帧处理（用于调试点击超时）
func _process(delta: float) -> void:
	if debug_click_count > 0:
		debug_click_timer += delta
		if debug_click_timer > DEBUG_CLICK_TIMEOUT:
			# 超时重置
			debug_click_count = 0
			debug_click_timer = 0.0

# 隐藏的调试按钮点击事件
func _on_debug_button_pressed() -> void:
	debug_click_count += 1
	debug_click_timer = 0.0
	
	if debug_click_count >= DEBUG_CLICK_REQUIRED:
		# 达到点击次数，切换调试模式
		debug_click_count = 0
		if GameState:
			GameState.toggle_debug_mode()
			# 更新调试模式指示器
			_update_debug_indicator()

# 更新调试模式指示器显示
func _update_debug_indicator() -> void:
	var debug_indicator = get_node_or_null("DebugIndicator")
	var hint_label = get_node_or_null("DebugIndicator/DebugHintLabel")
	
	if GameState and GameState.debug_mode:
		# 显示调试模式指示器
		if debug_indicator:
			debug_indicator.visible = true
		if hint_label:
			hint_label.text = "✓ 调试模式已开启"
	else:
		# 隐藏调试模式指示器
		if debug_indicator:
			debug_indicator.visible = false

# 开始新游戏按钮点击事件
func _on_start_button_pressed():
	# 打开存档界面，选择存档槽位开始新游戏
	get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")

# 继续冒险按钮点击事件
func _on_continue_button_pressed():
	if not SaveManager:
		Logger.debug("GameStartScreen", SaveManager不可用")
		get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")
		return
	
	# 再次检查是否有存档
	var has_any_save = false
	for i in range(SaveManager.MAX_SAVE_SLOTS):
		if SaveManager.has_save(i):
			has_any_save = true
			break
	
	if not has_any_save:
		Logger.debug("GameStartScreen", 没有找到存档，打开存档界面")
		get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")
		return
	
	# 统计有多少个存档以及找到的存档槽位
	var save_count = 0
	var save_slot = -1
	for i in range(SaveManager.MAX_SAVE_SLOTS):
		if SaveManager.has_save(i):
			save_count += 1
			save_slot = i
	
	# 如果只有一个存档，直接加载
	if save_count == 1 and save_slot >= 0:
		if SaveManager.load_game(save_slot):
			Logger.debug("GameStartScreen", 自动加载唯一存档，槽位: %d" % save_slot)
			# 获取当前关卡并切换场景
			var level = GameState.current_level
			var level_scene_path = _resolve_level_scene_path(level)
			get_tree().change_scene_to_file(level_scene_path)
			return
	
	# 多个存档或加载失败，打开存档界面选择
	get_tree().change_scene_to_file("res://scenes/ui/save_screen.tscn")

# 解析关卡场景路径
func _resolve_level_scene_path(level) -> String:
	# 尝试加载关卡配置
	var level_config = load("res://resources/level_config.tres")
	if level_config and level_config.has_method("get_level_scene_path"):
		return level_config.get_level_scene_path(level)
	
	# 回退：根据关卡编号构建路径
	if level is int:
		return "res://scenes/levels/lv%d.tscn" % level
	elif level is String:
		if level.begins_with("res://"):
			return level
		return "res://scenes/levels/%s.tscn" % level
	
	# 默认返回第一关
	return "res://scenes/levels/lv1.tscn"

# 结束游戏按钮点击事件
func _on_quit_button_pressed():
	# 退出游戏前保存当前存档
	if SaveManager and SaveManager.get_current_save() != null:
		SaveManager.save_game()
	
	# 退出游戏
	get_tree().quit()

# 设置按钮点击事件
func _on_settings_button_pressed():
	# 打开设置界面
	get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn")

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

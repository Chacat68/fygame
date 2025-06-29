extends Node

# 游戏状态
var score = 0
var kill_count = 0
var is_changing_scene = false  # 防止重复场景切换

# 组件引用
@onready var ui = _get_ui_node()
@onready var portal = _get_portal_node()

# 信号
signal score_changed(new_score)
signal kill_count_changed(new_count)

# 初始化
func _ready():
	# 将自己添加到游戏管理器组，方便其他脚本查找
	add_to_group("game_manager")
	
	# 注释掉重复的传送门信号连接，避免与 portal.gd 中的信号处理冲突
	# 传送门的 body_entered 信号现在由 portal.gd 统一处理
	# if portal:
	#	if not portal.body_entered.is_connected(_on_portal_entered):
	#		portal.connect("body_entered", _on_portal_entered)

# 传送门触发处理 - 已禁用，由 portal.gd 统一处理
# func _on_portal_entered(body):
#	if body.is_in_group("player") and not is_changing_scene:
#		# 使用 call_deferred 延迟切换场景，避免在物理回调中直接操作
#		call_deferred("_change_to_level2")

# 延迟执行的场景切换函数 - 已禁用，由传送系统统一处理
# func _change_to_level2():
#	# 防止重复调用
#	if is_changing_scene:
#		return
#	
#	is_changing_scene = true
#	# 检查树是否仍然有效
#	if get_tree():
#		get_tree().change_scene_to_file("res://scenes/levels/lv2.tscn")
#	else:
#		is_changing_scene = false  # 如果切换失败，重置标志

# 定义一个函数，用于增加分数并更新分数显示
func add_point():
	score += 1
	kill_count += 1
	score_changed.emit(score)
	kill_count_changed.emit(kill_count)
	
	# 更新UI
	if ui:
		ui.add_coin()
		ui.update_kill_count(kill_count)

# 重置游戏分数
func reset_score():
	score = 0
	kill_count = 0
	score_changed.emit(score)
	kill_count_changed.emit(kill_count)
	
	if ui:
		ui.update_coin_count(0)
		ui.update_kill_count(0)

# 获取当前关卡的死亡高度
func get_death_height():
	# 默认死亡高度
	var default_height = 300
	
	# 获取当前场景名称
	var tree = get_tree()
	if not tree or not tree.get_current_scene():
		print("[GameManager] 警告：无法获取当前场景，使用默认死亡高度")
		return default_height
	
	var current_scene = tree.get_current_scene().name
	
	# 根据不同关卡返回不同的死亡高度
	match current_scene:
		"Game":
			return 300
		"MountainCaveLevel":
			return 300
		_:
			return default_height

# 安全获取UI节点
func _get_ui_node() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("UI")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("ui")

# 安全获取Portal节点
func _get_portal_node() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("Portal")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("portal")

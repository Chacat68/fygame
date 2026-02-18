extends Node

const TAG = "GameManager"

# 游戏状态
var score = 0
var kill_count = 0
var is_changing_scene = false # 防止重复场景切换

# 组件引用
var ui: Node = null
var portal: Node = null

# 信号
signal score_changed(new_score)
signal kill_count_changed(new_count)

# 初始化
func _ready():
	# 将自己添加到游戏管理器组，方便其他脚本查找
	add_to_group("game_manager")
	# 延迟获取 UI 和 Portal 节点
	ui = _get_ui_node()
	portal = _get_portal_node()

# 定义一个函数，用于增加分数并更新分数显示
func add_point():
	score += 1
	kill_count += 1
	score_changed.emit(score)
	kill_count_changed.emit(kill_count)
	
	# 更新UI
	if ui:
		# 增加金币（根据配置的金币价值）
		var config = GameConfig.get_config()
		var coin_value = config.coin_value if config else 1
		ui.add_coin(coin_value)
		ui.add_kill()

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
		Logger.warn(TAG, "无法获取当前场景，使用默认死亡高度")
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
	# 首先尝试在当前场景中查找 UI 节点
	var current_scene = get_tree().current_scene
	if current_scene:
		var ui_node = current_scene.get_node_or_null("UI")
		if ui_node:
			return ui_node
	
	# 尝试 /root/Game 路径（兼容旧结构）
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("UI")
	
	# 如果都找不到，尝试在 group 中查找
	return get_tree().get_first_node_in_group("ui")

# 安全获取Portal节点
func _get_portal_node() -> Node:
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("Portal")
	else:
		# 如果Game节点不存在，尝试在当前场景中查找
		return get_tree().get_first_node_in_group("portal")

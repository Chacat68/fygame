extends Area2D

const TAG = "Coin"

# 游戏配置
var config: GameConfig

# 组件引用
var coin_counter: Node = null
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $CoinSound

# 飘字效果现在由FloatingTextManager管理

# 状态变量
var popup_shown = false
var collected = false

# 初始化函数
func _ready():
	# 初始化配置
	_init_config()
	# 获取 UI 节点（延迟获取以确保场景树已准备好）
	coin_counter = _get_ui_node()
	# 信号连接（从 .tscn 移到代码，避免多实例化时重复连接）
	if not body_shape_entered.is_connected(_on_body_shape_entered):
		body_shape_entered.connect(_on_body_shape_entered)
	if animation_player and not animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		animation_player.animation_finished.connect(_on_animation_player_animation_finished)

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()

# 当有物体进入Area2D时调用此函数
func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	if collected:
		return
		
	collected = true
	_collect_coin(_body)

# 处理金币收集逻辑
func _collect_coin(_body = null):
	var error_messages = []
	
	# 增加金币计数
	if coin_counter:
		coin_counter.add_coin()
	else:
		error_messages.append("CoinCounter is null")
	
	# 播放收集动画
	if animation_player:
		animation_player.play("pickup")
	else:
		error_messages.append("AnimationPlayer is null")
	
	# 播放收集音效
	if sound_player:
		sound_player.play()
	
	# 显示收集信息
	if not popup_shown:
		Logger.debug(TAG, "金币已收集！")
		popup_shown = true
	
	# 输出任何错误信息
	for message in error_messages:
		Logger.warn(TAG, message)

# 当动画播放完成后，移除金币
func _on_animation_player_animation_finished(_anim_name):
	queue_free() # 从场景中移除金币

# 安全获取UI节点
func _get_ui_node() -> Node:
	# 首先尝试在当前场景中查找 UI 节点
	var current_scene = get_tree().current_scene
	if current_scene:
		var ui = current_scene.get_node_or_null("UI")
		if ui:
			return ui
	
	# 尝试 /root/Game 路径（兼容旧结构）
	var game_root = get_node_or_null("/root/Game")
	if game_root:
		return game_root.get_node_or_null("UI")
	
	# 如果都找不到，尝试在 group 中查找
	return get_tree().get_first_node_in_group("ui")

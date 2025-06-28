extends CanvasLayer

# UI控制脚本，管理金币和击杀计数显示

# 引入传送管理器
const TeleportManagerClass = preload("res://scripts/teleport_manager.gd")

# 状态变量
var coin_count = 0
var kill_count = 0

# 传送管理器实例
var teleport_manager: TeleportManagerClass

# UI位置参数（可在Inspector中调整）
@export var margin_left: int = 10
@export var margin_top: int = 15

# 组件引用
@onready var coin_label = $TopBar/CoinCounter/CoinCount
@onready var coin_icon = $TopBar/CoinCounter/CoinIcon
@onready var coin_counter = $TopBar/CoinCounter
@onready var kill_counter = $TopBar/KillCounter
@onready var kill_label = $TopBar/KillCounter/KillCount
@onready var top_bar = $TopBar
@onready var test_button = $TestButton
@onready var test_panel = $TestPanel
@onready var teleport_button = $TestPanel/TestVBox/TeleportButton

# 信号
signal coins_changed(new_count)
signal kills_changed(new_count)

func _ready():
	# 初始化传送管理器
	teleport_manager = TeleportManagerClass.new()
	add_child(teleport_manager)
	
	# 加载传送配置
	var config = load("res://resources/default_teleport_config.tres") as TeleportConfig
	if config:
		teleport_manager.set_config(config)
	else:
		print("[CoinCounter] 警告：无法加载传送配置，使用默认设置")
	
	# 连接传送管理器信号
	teleport_manager.teleport_started.connect(_on_teleport_started)
	teleport_manager.teleport_completed.connect(_on_teleport_completed)
	teleport_manager.teleport_failed.connect(_on_teleport_failed)
	teleport_manager.teleport_cooldown_finished.connect(_on_teleport_cooldown_finished)
	
	# 初始化金币计数为0
	update_coin_count(0)
	
	# 初始化击杀计数为0
	update_kill_count(0)
	
	# 设置UI元素的位置
	update_position()
	
	# 连接测试按钮事件
	if test_button:
		test_button.pressed.connect(_on_test_button_pressed)
	if teleport_button:
		teleport_button.pressed.connect(_on_teleport_button_pressed)

# 更新金币计数并发出信号
func update_coin_count(value):
	var old_count = coin_count
	coin_count = value
	coin_label.text = str(coin_count)
	
	if old_count != coin_count:
		coins_changed.emit(coin_count)

# 增加金币计数
func add_coin(amount = 1):
	update_coin_count(coin_count + amount)

# 更新击杀计数并发出信号
func update_kill_count(value):
	var old_count = kill_count
	kill_count = value
	kill_label.text = str(kill_count)
	
	if old_count != kill_count:
		kills_changed.emit(kill_count)
	


# 增加击杀计数
func add_kill(amount = 1):
	update_kill_count(kill_count + amount)

# 更新UI元素的位置
func update_position():
	# 设置顶部栏的位置
	if top_bar:
		top_bar.offset_left = margin_left
		top_bar.offset_top = margin_top
	
# 当位置参数改变时调用此函数
func set_margins(left: int, top: int):
	margin_left = left
	margin_top = top
	update_position()

# 测试按钮点击事件
func _on_test_button_pressed():
	if test_panel:
		test_panel.visible = !test_panel.visible

# 传送到传送门按钮点击事件
func _on_teleport_button_pressed():
	if teleport_manager:
		# 使用传送管理器执行传送
		var success = teleport_manager.teleport_to_portal()
		if success:
			# 隐藏测试面板
			if test_panel:
				test_panel.visible = false
	else:
		print("[CoinCounter] 错误：传送管理器未初始化")

# 传送开始回调
func _on_teleport_started(player: Node2D, destination: Vector2):
	print("[CoinCounter] 传送开始：玩家从 ", player.global_position, " 传送到 ", destination)

# 传送完成回调
func _on_teleport_completed(_player: Node2D, destination: Vector2):
	print("[CoinCounter] 传送完成：玩家已到达 ", destination)
	# 这里可以添加传送完成后的UI反馈，比如显示提示信息

# 传送失败回调
func _on_teleport_failed(reason: String):
	print("[CoinCounter] 传送失败：", reason)
	# 这里可以添加错误提示UI，比如显示错误消息

# 传送冷却完成回调
func _on_teleport_cooldown_finished():
	print("[CoinCounter] 传送冷却完成，可以再次传送")
	# 这里可以添加UI反馈，比如重新启用传送按钮

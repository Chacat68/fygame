extends CanvasLayer

# UI控制脚本，管理金币和击杀计数显示

# 引入传送管理器
const TeleportManagerClass = preload("res://scripts/systems/teleport_manager.gd")

# 状态变量
var coin_count = 0
var kill_count = 0

# 滚动动画相关
var coin_display_value: float = 0.0
var kill_display_value: float = 0.0
var coin_tween: Tween = null
var kill_tween: Tween = null
const ROLL_DURATION: float = 0.3  # 滚动动画持续时间

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

# 更新金币计数并发出信号（带滚动动画）
func update_coin_count(value, animate: bool = true):
	var old_count = coin_count
	coin_count = value
	
	if animate and old_count != coin_count:
		_animate_coin_roll(old_count, coin_count)
		coins_changed.emit(coin_count)
	else:
		coin_display_value = float(coin_count)
		coin_label.text = str(coin_count)

# 金币数字滚动动画
func _animate_coin_roll(from_value: int, to_value: int):
	# 停止之前的动画
	if coin_tween and coin_tween.is_valid():
		coin_tween.kill()
	
	coin_display_value = float(from_value)
	coin_tween = create_tween()
	coin_tween.set_ease(Tween.EASE_OUT)
	coin_tween.set_trans(Tween.TRANS_CUBIC)
	coin_tween.tween_method(_update_coin_display, float(from_value), float(to_value), ROLL_DURATION)
	
	# 添加缩放弹跳效果
	if coin_label:
		var scale_tween = create_tween()
		scale_tween.tween_property(coin_label, "scale", Vector2(1.3, 1.3), 0.1)
		scale_tween.tween_property(coin_label, "scale", Vector2(1.0, 1.0), 0.2)

func _update_coin_display(value: float):
	coin_display_value = value
	if coin_label:
		coin_label.text = str(int(round(value)))

# 增加金币计数
func add_coin(amount = 1):
	update_coin_count(coin_count + amount, true)

# 更新击杀计数并发出信号（带滚动动画）
func update_kill_count(value, animate: bool = true):
	var old_count = kill_count
	kill_count = value
	
	if animate and old_count != kill_count:
		_animate_kill_roll(old_count, kill_count)
		kills_changed.emit(kill_count)
	else:
		kill_display_value = float(kill_count)
		kill_label.text = str(kill_count)

# 击杀数字滚动动画
func _animate_kill_roll(from_value: int, to_value: int):
	# 停止之前的动画
	if kill_tween and kill_tween.is_valid():
		kill_tween.kill()
	
	kill_display_value = float(from_value)
	kill_tween = create_tween()
	kill_tween.set_ease(Tween.EASE_OUT)
	kill_tween.set_trans(Tween.TRANS_CUBIC)
	kill_tween.tween_method(_update_kill_display, float(from_value), float(to_value), ROLL_DURATION)
	
	# 添加缩放弹跳效果
	if kill_label:
		var scale_tween = create_tween()
		scale_tween.tween_property(kill_label, "scale", Vector2(1.3, 1.3), 0.1)
		scale_tween.tween_property(kill_label, "scale", Vector2(1.0, 1.0), 0.2)

func _update_kill_display(value: float):
	kill_display_value = value
	if kill_label:
		kill_label.text = str(int(round(value)))

# 增加击杀计数
func add_kill(amount = 1):
	update_kill_count(kill_count + amount, true)

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

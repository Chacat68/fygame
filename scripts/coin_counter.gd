extends CanvasLayer

# 状态变量
var coin_count = 0
var kill_count = 0

# UI位置参数（可在Inspector中调整）
@export var margin_left: int = 80
@export var margin_top: int = 15

# 组件引用
@onready var coin_label = $CoinCounter/CoinCount
@onready var coin_icon = $CoinCounter/CoinIcon
@onready var coin_counter = $CoinCounter
@onready var kill_counter = $KillCounter
@onready var kill_label = $KillCounter/KillCount

# 信号
signal coins_changed(new_count)
signal kills_changed(new_count)

func _ready():
	# 初始化金币计数为0
	update_coin_count(0)
	
	# 初始化击杀计数为0
	update_kill_count(0)
	
	# 设置UI元素的位置
	update_position()

# 更新金币计数并发出信号
func update_coin_count(value):
	var old_count = coin_count
	coin_count = value
	coin_label.text = str(coin_count)
	
	if old_count != coin_count:
		emit_signal("coins_changed", coin_count)

# 增加金币计数
func add_coin(amount = 1):
	update_coin_count(coin_count + amount)

# 更新击杀计数并发出信号
func update_kill_count(value):
	var old_count = kill_count
	kill_count = value
	kill_label.text = str(kill_count)
	
	if old_count != kill_count:
		emit_signal("kills_changed", kill_count)

# 增加击杀计数
func add_kill(amount = 1):
	update_kill_count(kill_count + amount)

# 更新UI元素的位置
func update_position():
	coin_counter.position.x = margin_left
	coin_counter.position.y = margin_top
	
	# 设置击杀计数器位置在金币计数器下方
	if kill_counter:
		kill_counter.position.x = margin_left
		kill_counter.position.y = margin_top + 50
	
# 当位置参数改变时调用此函数
func set_margins(left: int, top: int):
	margin_left = left
	margin_top = top
	update_position()

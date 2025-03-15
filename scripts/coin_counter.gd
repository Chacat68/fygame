extends CanvasLayer

# 状态变量
var coin_count = 0

# 组件引用
@onready var coin_label = $CoinCounter/CoinCount
@onready var coin_icon = $CoinCounter/CoinIcon

# 信号
signal coins_changed(new_count)

func _ready():
	# 初始化金币计数为0
	update_coin_count(0)

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
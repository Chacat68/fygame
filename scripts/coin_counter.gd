extends CanvasLayer

# 金币计数
var coin_count = 0

# 获取UI元素
@onready var coin_label = $CoinCounter/CoinCount
@onready var coin_icon = $CoinCounter/CoinIcon

func _ready():
	# 初始化金币计数为0
	update_coin_count(0)

# 更新金币计数
func update_coin_count(value):
	coin_count = value
	coin_label.text = str(coin_count)

# 增加金币计数
func add_coin():
	coin_count += 1
	update_coin_count(coin_count) 
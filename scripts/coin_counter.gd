extends CanvasLayer

# 状态变量
var coin_count = 0
var kill_count = 0
var health = 100  # 玩家血量

# UI位置参数（可在Inspector中调整）
@export var margin_left: int = 10
@export var margin_top: int = 15

# 组件引用
@onready var coin_label = $CoinCounter/CoinCount
@onready var coin_icon = $CoinCounter/CoinIcon
@onready var coin_counter = $CoinCounter
@onready var kill_counter = $KillCounter
@onready var kill_label = $KillCounter/KillCount
@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthCount

# 信号
signal coins_changed(new_count)
signal kills_changed(new_count)
signal health_changed(new_health)

func _ready():
	# 初始化金币计数为0
	update_coin_count(0)
	
	# 初始化击杀计数为0
	update_kill_count(0)
	
	# 初始化血量显示
	update_health(100)
	
	# 设置UI元素的位置
	update_position()
	
	# 连接玩家的血量变化信号
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("health_changed"):
		player.connect("health_changed", update_health)

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
	
# 更新血量显示并发出信号
func update_health(value):
	var old_health = health
	health = value
	
	# 如果血量条存在，更新其值
	if health_label:
		health_label.text = str(health) + "/100"
	
	if old_health != health:
		emit_signal("health_changed", health)

# 增加击杀计数
func add_kill(amount = 1):
	update_kill_count(kill_count + amount)

# 更新UI元素的位置
func update_position():
	# 使用position.x和position.y可能会覆盖布局容器的对齐设置
	# 改为使用offset_left和offset_top属性
	coin_counter.offset_left = margin_left
	coin_counter.offset_top = margin_top
	
	# 设置击杀计数器位置在金币计数器下方
	if kill_counter:
		kill_counter.offset_left = margin_left
		kill_counter.offset_top = margin_top + 50
		
	# 设置血量条位置
	if health_bar:
		health_bar.offset_left = margin_left
		health_bar.offset_top = margin_top + 100
	
# 当位置参数改变时调用此函数
func set_margins(left: int, top: int):
	margin_left = left
	margin_top = top
	update_position()

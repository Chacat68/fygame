extends Node2D

# 新关卡脚本
# 管理关卡特定的逻辑和事件

@onready var player = $Player
@onready var game_manager = $GameManager
@onready var level_camera = $LevelCamera
@onready var coins = $Coins
@onready var enemies = $Enemies
@onready var welcome_label = $Labels/WelcomeLabel

# 关卡状态
var level_completed = false
var coins_collected = 0
var total_coins = 0
var enemies_defeated = 0

func _ready():
	# 初始化关卡
	setup_level()
	
	# 连接信号
	connect_signals()
	
	# 显示欢迎信息
	show_welcome_message()

func setup_level():
	"""设置关卡初始状态"""
	# 计算总金币数量
	total_coins = coins.get_child_count()
	
	# 设置摄像机跟随玩家
	if player and level_camera:
		level_camera.enabled = true
		# 可以添加平滑跟随逻辑
	
	print("新关卡已加载，总金币数: ", total_coins)

func connect_signals():
	"""连接游戏信号"""
	# 连接金币收集信号
	for coin in coins.get_children():
		if coin.has_signal("coin_collected"):
			coin.coin_collected.connect(_on_coin_collected)
	
	# 连接敌人击败信号
	for enemy in enemies.get_children():
		if enemy.has_signal("enemy_defeated"):
			enemy.enemy_defeated.connect(_on_enemy_defeated)

func show_welcome_message():
	"""显示欢迎信息"""
	if welcome_label:
		# 创建淡入动画
		var tween = create_tween()
		welcome_label.modulate.a = 0.0
		tween.tween_property(welcome_label, "modulate:a", 1.0, 1.0)
		tween.tween_delay(2.0)
		tween.tween_property(welcome_label, "modulate:a", 0.0, 1.0)

func _on_coin_collected():
	"""处理金币收集事件"""
	coins_collected += 1
	print("金币收集: ", coins_collected, "/", total_coins)
	
	# 检查是否收集完所有金币
	if coins_collected >= total_coins:
		_on_all_coins_collected()

func _on_enemy_defeated():
	"""处理敌人击败事件"""
	enemies_defeated += 1
	print("敌人击败数: ", enemies_defeated)

func _on_all_coins_collected():
	"""所有金币收集完成"""
	print("恭喜！收集完所有金币！")
	# 可以触发关卡完成逻辑
	level_completed = true
	
	# 显示完成信息
	show_completion_message()

func show_completion_message():
	"""显示关卡完成信息"""
	if welcome_label:
		welcome_label.text = "关卡完成！"
		welcome_label.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(welcome_label, "modulate:a", 1.0, 0.5)
		tween.tween_delay(3.0)
		tween.tween_property(welcome_label, "modulate:a", 0.0, 0.5)

func _process(delta):
	# 更新摄像机位置跟随玩家
	if player and level_camera and not level_completed:
		var target_position = player.global_position
		level_camera.global_position = level_camera.global_position.lerp(target_position, 2.0 * delta)

func restart_level():
	"""重启关卡"""
	# 重置状态
	coins_collected = 0
	enemies_defeated = 0
	level_completed = false
	
	# 重新加载场景
	get_tree().reload_current_scene()

func get_level_progress() -> Dictionary:
	"""获取关卡进度信息"""
	return {
		"coins_collected": coins_collected,
		"total_coins": total_coins,
		"enemies_defeated": enemies_defeated,
		"level_completed": level_completed
	}
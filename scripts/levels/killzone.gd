extends Area2D

# 游戏配置
var config: GameConfig

# 添加一个导出变量，可以在编辑器中设置killzone类型
@export var is_cliff_bottom: bool = false
@export var damage_amount: int = 10 # 可配置的伤害值（编辑器覆盖）

# 初始化函数
func _ready():
	# 初始化配置
	_init_config()
	# 信号连接（从 .tscn 移到代码，避免多实例化时重复连接）
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

# 初始化配置
func _init_config():
	# 加载游戏配置
	config = GameConfig.get_config()
	
	# 如果编辑器中没有特别设置伤害值，则使用配置中的值
	if damage_amount == 10: # 默认值
		damage_amount = config.player_damage_amount if config else 10

# 当有物体进入Area2D时调用此函数
func _on_body_entered(body):
	# 检查碰撞的是否为玩家
	if body.is_in_group("player"):
		# 使用标志而不是位置来判断类型
		if is_cliff_bottom:
			print("Player fell off cliff!")
			# 直接调用玩家的死亡函数，绕过扣血逻辑
			if body.has_method("_die"):
				body._die()
			else:
				_handle_player_death(body)
			return
		# 如果不是掉落悬崖，而是其他类型的killzone（如尖刺等），则正常扣血
		elif body.has_method("take_damage"):
			print("Player took damage!")
			# 调用玩家的受伤函数，使用配置的伤害值
			body.take_damage(damage_amount)
			return
	
	# 如果没有血量系统或不是玩家，使用旧的死亡逻辑作为后备
	print("You Died!")
	_handle_player_death(body)

# 处理玩家死亡逻辑（作为后备机制）
func _handle_player_death(player):
	# 使用call_deferred延迟移除玩家碰撞体，避免在物理回调中直接移除
	if player.has_node("CollisionShape2D"):
		player.get_node("CollisionShape2D").call_deferred("queue_free")
	
	# 使用call_deferred延迟重新加载场景，确保在物理处理完成后执行
	get_tree().call_deferred("reload_current_scene")

extends Node

## 检查点管理器 (AutoLoad 单例)
## 管理关卡中所有检查点，处理玩家重生逻辑
## 注意：作为 AutoLoad 使用时不要添加 class_name

# 信号
signal checkpoint_activated(checkpoint_id: String)
signal player_respawned(position: Vector2)

# 所有已注册的检查点（按ID索引）
var checkpoints: Dictionary = {}

# 当前激活的检查点ID
var active_checkpoint_id: String = ""

# 当前关卡标识
var current_level: String = ""

# 初始重生位置（如果没有检查点）
var initial_spawn_position: Vector2 = Vector2.ZERO

# 是否已记录初始位置
var has_initial_position: bool = false

func _ready() -> void:
	print("[CheckpointManager] 检查点管理器已初始化")

## 设置当前关卡（切换关卡时会清除检查点）
func set_current_level(level_name: String) -> void:
	if current_level != level_name:
		clear_checkpoints()
		current_level = level_name
		print("[CheckpointManager] 切换到关卡: %s" % level_name)

## 设置初始重生位置（通常是玩家的起始位置）
func set_initial_spawn_position(position: Vector2) -> void:
	initial_spawn_position = position
	has_initial_position = true
	print("[CheckpointManager] 设置初始重生位置: %s" % position)

## 注册检查点
func register_checkpoint(checkpoint: Node) -> void:
	var cp_id = _get_checkpoint_id(checkpoint)
	
	if checkpoints.has(cp_id):
		return  # 已注册，跳过
	
	checkpoints[cp_id] = checkpoint
	
	# 如果检查点有activated信号，连接它
	if checkpoint.has_signal("activated"):
		if not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)
	
	print("[CheckpointManager] 注册检查点: %s，当前检查点数: %d" % [cp_id, checkpoints.size()])

## 激活检查点（通过ID）
func activate_checkpoint(checkpoint_id: String) -> void:
	if not checkpoints.has(checkpoint_id):
		push_warning("[CheckpointManager] 尝试激活不存在的检查点: %s" % checkpoint_id)
		return
	
	active_checkpoint_id = checkpoint_id
	
	# 激活对应的检查点对象
	var checkpoint = checkpoints[checkpoint_id]
	if checkpoint and checkpoint.has_method("activate"):
		checkpoint.activate()
	
	checkpoint_activated.emit(checkpoint_id)
	print("[CheckpointManager] 激活检查点: %s" % checkpoint_id)

## 获取当前重生位置
func get_respawn_position() -> Vector2:
	if active_checkpoint_id != "" and checkpoints.has(active_checkpoint_id):
		var checkpoint = checkpoints[active_checkpoint_id]
		if checkpoint and checkpoint.has_method("get_spawn_position"):
			return checkpoint.get_spawn_position()
	
	if has_initial_position:
		return initial_spawn_position
	
	push_warning("[CheckpointManager] 没有可用的重生位置！")
	return Vector2.ZERO

## 检查是否有激活的检查点
func has_checkpoint() -> bool:
	return active_checkpoint_id != "" and checkpoints.has(active_checkpoint_id)

## 重生玩家到检查点
func respawn_player(player: Node2D) -> void:
	var respawn_pos = get_respawn_position()
	
	if player:
		player.global_position = respawn_pos
		print("[CheckpointManager] 玩家重生到位置: %s" % respawn_pos)
		
		# 发射重生信号
		player_respawned.emit(respawn_pos)

## 清除所有检查点记录（用于关卡切换）
func clear_checkpoints() -> void:
	checkpoints.clear()
	active_checkpoint_id = ""
	has_initial_position = false
	initial_spawn_position = Vector2.ZERO
	print("[CheckpointManager] 检查点记录已清除")

## 重置所有检查点状态（保留位置信息但重置激活状态）
func reset_all_checkpoints() -> void:
	# 获取所有检查点并重置
	for checkpoint in checkpoints.values():
		if checkpoint and checkpoint.has_method("reset"):
			checkpoint.reset()
	
	active_checkpoint_id = ""
	print("[CheckpointManager] 所有检查点已重置")

## 获取检查点数据（用于存档）
func get_save_data() -> Dictionary:
	return {
		"active_checkpoint_id": active_checkpoint_id,
		"current_level": current_level,
		"initial_spawn_position": {
			"x": initial_spawn_position.x,
			"y": initial_spawn_position.y
		},
		"has_initial_position": has_initial_position
	}

## 从存档数据恢复检查点状态
func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	# 恢复活动检查点ID
	if data.has("active_checkpoint_id"):
		active_checkpoint_id = data["active_checkpoint_id"]
	
	# 恢复当前关卡
	if data.has("current_level"):
		current_level = data["current_level"]
	
	# 恢复初始位置
	if data.has("initial_spawn_position"):
		var pos_data = data["initial_spawn_position"]
		initial_spawn_position = Vector2(pos_data["x"], pos_data["y"])
	
	has_initial_position = data.get("has_initial_position", false)
	
	print("[CheckpointManager] 检查点数据已从存档恢复")

## 内部方法：获取检查点ID
func _get_checkpoint_id(checkpoint: Node) -> String:
	if checkpoint.has_method("get") and checkpoint.get("checkpoint_id") != null:
		return str(checkpoint.checkpoint_id)
	return str(checkpoint.get_instance_id())

## 内部方法：处理检查点激活信号
func _on_checkpoint_activated(checkpoint: Node) -> void:
	var cp_id = _get_checkpoint_id(checkpoint)
	if cp_id != active_checkpoint_id:
		active_checkpoint_id = cp_id
		checkpoint_activated.emit(cp_id)
		print("[CheckpointManager] 检查点激活（通过信号）: %s" % cp_id)

# 检查点管理器 (AutoLoad)
# 负责管理所有检查点，处理玩家重生逻辑
class_name CheckpointManagerClass
extends Node

# 信号
signal checkpoint_registered(checkpoint: Node)
signal checkpoint_activated(checkpoint: Node)
signal player_respawned(position: Vector2)

# 检查点列表
var checkpoints: Array[Node] = []
var active_checkpoint: Node = null
var initial_spawn_position: Vector2 = Vector2.ZERO

# 重生状态
var respawn_count: int = 0
var last_respawn_time: float = 0.0

func _ready() -> void:
	Logger.debug("CheckpointManager", 检查点管理器已初始化")

## 注册检查点
func register_checkpoint(checkpoint: Node) -> void:
	if checkpoint and not checkpoints.has(checkpoint):
		checkpoints.append(checkpoint)
		
		# 按顺序排序检查点
		checkpoints.sort_custom(func(a, b):
			var order_a = a.checkpoint_order if "checkpoint_order" in a else 0
			var order_b = b.checkpoint_order if "checkpoint_order" in b else 0
			return order_a < order_b
		)
		
		# 连接检查点激活信号
		if checkpoint.has_signal("activated") and not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)
		
		checkpoint_registered.emit(checkpoint)
		Logger.debug("CheckpointManager", 检查点已注册: %s (总计: %d)" % [checkpoint.name, checkpoints.size()])

## 取消注册检查点
func unregister_checkpoint(checkpoint: Node) -> void:
	if checkpoint in checkpoints:
		checkpoints.erase(checkpoint)
		
		# 如果是当前激活的检查点，清除引用
		if active_checkpoint == checkpoint:
			active_checkpoint = null
		
		Logger.debug("CheckpointManager", 检查点已取消注册: %s" % checkpoint.name)

## 设置初始出生位置
func set_initial_spawn_position(position: Vector2) -> void:
	initial_spawn_position = position
	Logger.debug("CheckpointManager", 初始出生位置已设置: %s" % position)

## 检查点激活回调
func _on_checkpoint_activated(checkpoint: Node) -> void:
	active_checkpoint = checkpoint
	checkpoint_activated.emit(checkpoint)
	Logger.debug("CheckpointManager", 检查点已激活: %s" % checkpoint.name)

## 获取当前重生位置
func get_respawn_position() -> Vector2:
	if active_checkpoint and is_instance_valid(active_checkpoint):
		if active_checkpoint.has_method("get_spawn_position"):
			return active_checkpoint.get_spawn_position()
		return active_checkpoint.global_position
	return initial_spawn_position

## 重生玩家
func respawn_player() -> void:
	var spawn_pos = get_respawn_position()
	
	# 查找玩家
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_pos
		
		# 重置玩家状态
		if player.has_method("_apply_respawn_effect"):
			player._apply_respawn_effect()
		
		respawn_count += 1
		last_respawn_time = Time.get_unix_time_from_system()
		
		player_respawned.emit(spawn_pos)
		Logger.debug("CheckpointManager", 玩家已重生到位置: %s (重生次数: %d)" % [spawn_pos, respawn_count])
	else:
		push_error("[CheckpointManager] 找不到玩家节点，无法重生")

## 重置所有检查点（用于关卡重置）
func reset_all_checkpoints() -> void:
	for checkpoint in checkpoints:
		if checkpoint.has_method("reset"):
			checkpoint.reset()
	
	active_checkpoint = null
	Logger.debug("CheckpointManager", 所有检查点已重置")

## 清除所有检查点
func clear_all_checkpoints() -> void:
	checkpoints.clear()
	active_checkpoint = null
	initial_spawn_position = Vector2.ZERO
	Logger.debug("CheckpointManager", 所有检查点已清除")

## 获取检查点数量
func get_checkpoint_count() -> int:
	return checkpoints.size()

## 检查是否有活动的检查点
func has_checkpoint() -> bool:
	return active_checkpoint != null and is_instance_valid(active_checkpoint)

## 获取激活的检查点数量
func get_activated_checkpoint_count() -> int:
	var count = 0
	for checkpoint in checkpoints:
		if "is_active" in checkpoint and checkpoint.is_active:
			count += 1
	return count

## 获取重生统计
func get_respawn_stats() -> Dictionary:
	return {
		"respawn_count": respawn_count,
		"last_respawn_time": last_respawn_time,
		"checkpoint_count": checkpoints.size(),
		"activated_checkpoints": get_activated_checkpoint_count()
	}

# 收集品管理器 (AutoLoad)
# 负责管理所有收集品的注册、状态和统计
class_name CollectibleManagerClass
extends Node

# 信号
signal collectible_collected(collectible: Node, player: Node)
signal collection_completed(collection_type: String)
signal progress_updated(collection_type: String, current: int, total: int)

# 收集品类型枚举
enum CollectibleType {
	COIN,
	GEM,
	HEART,
	KEY,
	SECRET,
	POWERUP
}

# 收集品数据
var collectibles: Dictionary = {}  # 按类型存储收集品
var collected_items: Dictionary = {}  # 按关卡存储已收集的物品ID
var collection_stats: Dictionary = {}  # 收集统计

func _ready() -> void:
	_initialize_stats()
	print("[CollectibleManager] 收集品管理器已初始化")

## 初始化统计
func _initialize_stats() -> void:
	for type in CollectibleType.values():
		var type_name = CollectibleType.keys()[type]
		collection_stats[type_name] = {
			"total_collected": 0,
			"current_level_collected": 0,
			"current_level_total": 0
		}
		collectibles[type_name] = []

## 注册收集品
func register_collectible(collectible: Node, type: CollectibleType) -> void:
	var type_name = CollectibleType.keys()[type]
	
	if not collectibles.has(type_name):
		collectibles[type_name] = []
	
	if collectible not in collectibles[type_name]:
		collectibles[type_name].append(collectible)
		collection_stats[type_name]["current_level_total"] += 1
		
		# 连接收集信号
		if collectible.has_signal("collected") and not collectible.collected.is_connected(_on_collectible_collected):
			collectible.collected.connect(_on_collectible_collected.bind(type))

## 收集品被收集回调
func _on_collectible_collected(collectible: Node, player: Node, type: CollectibleType) -> void:
	var type_name = CollectibleType.keys()[type]
	
	collection_stats[type_name]["total_collected"] += 1
	collection_stats[type_name]["current_level_collected"] += 1
	
	# 记录已收集的物品
	var level_id = _get_current_level_id()
	if not collected_items.has(level_id):
		collected_items[level_id] = []
	
	var item_id = collectible.get_instance_id()
	if item_id not in collected_items[level_id]:
		collected_items[level_id].append(item_id)
	
	# 发射信号
	collectible_collected.emit(collectible, player)
	
	# 检查是否完成收集
	var current = collection_stats[type_name]["current_level_collected"]
	var total = collection_stats[type_name]["current_level_total"]
	
	progress_updated.emit(type_name, current, total)
	
	if current >= total and total > 0:
		collection_completed.emit(type_name)

## 获取当前关卡ID
func _get_current_level_id() -> String:
	var scene = get_tree().current_scene
	if scene:
		return scene.name
	return "unknown"

## 重置当前关卡收集状态
func reset_current_level() -> void:
	for type_name in collection_stats.keys():
		collection_stats[type_name]["current_level_collected"] = 0
		collection_stats[type_name]["current_level_total"] = 0
		collectibles[type_name].clear()

## 获取收集进度
func get_collection_progress(type: CollectibleType) -> Dictionary:
	var type_name = CollectibleType.keys()[type]
	if collection_stats.has(type_name):
		return collection_stats[type_name].duplicate()
	return {}

## 获取总收集统计
func get_total_stats() -> Dictionary:
	var total = {
		"total_collected": 0,
		"total_coins": collection_stats.get("COIN", {}).get("total_collected", 0),
		"total_gems": collection_stats.get("GEM", {}).get("total_collected", 0),
		"total_secrets": collection_stats.get("SECRET", {}).get("total_collected", 0)
	}
	
	for type_name in collection_stats.keys():
		total["total_collected"] += collection_stats[type_name]["total_collected"]
	
	return total

## 检查物品是否已收集
func is_collected(level_id: String, item_id: int) -> bool:
	if collected_items.has(level_id):
		return item_id in collected_items[level_id]
	return false

## 保存收集数据
func save_data() -> Dictionary:
	return {
		"collected_items": collected_items.duplicate(true),
		"collection_stats": collection_stats.duplicate(true)
	}

## 加载收集数据
func load_data(data: Dictionary) -> void:
	if data.has("collected_items"):
		collected_items = data["collected_items"].duplicate(true)
	if data.has("collection_stats"):
		for type_name in data["collection_stats"].keys():
			if collection_stats.has(type_name):
				collection_stats[type_name]["total_collected"] = data["collection_stats"][type_name].get("total_collected", 0)

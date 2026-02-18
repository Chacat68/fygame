# 道具管理器 (AutoLoad)
# 负责管理玩家的道具，包括使用道具、道具效果等
extends Node

# 信号
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_used(item_id: String)
signal effect_applied(effect_type: String, duration: float)
signal effect_expired(effect_type: String)

# 道具定义
var item_definitions: Dictionary = {}

# 玩家背包
var inventory: Dictionary = {}  # item_id -> count
var max_stack_size: int = 99
var max_inventory_slots: int = 20

# 激活的效果
var active_effects: Dictionary = {}  # effect_type -> {remaining_time, strength}

func _ready() -> void:
	_initialize_item_definitions()
	Logger.debug("ItemManager", 道具管理器已初始化，共 %d 种道具" % item_definitions.size())

func _process(delta: float) -> void:
	_update_active_effects(delta)

## 初始化道具定义
func _initialize_item_definitions() -> void:
	# 消耗品
	_register_item("health_potion", {
		"name": "生命药水",
		"description": "恢复25点生命值",
		"icon": "potion_red",
		"type": "consumable",
		"max_stack": 10,
		"effect": {"type": "heal", "value": 25},
		"buy_price": 50,
		"sell_price": 25
	})
	
	_register_item("health_potion_large", {
		"name": "大型生命药水",
		"description": "恢复50点生命值",
		"icon": "potion_red_large",
		"type": "consumable",
		"max_stack": 5,
		"effect": {"type": "heal", "value": 50},
		"buy_price": 100,
		"sell_price": 50
	})
	
	_register_item("speed_potion", {
		"name": "疾跑药水",
		"description": "10秒内移动速度提升50%",
		"icon": "potion_blue",
		"type": "consumable",
		"max_stack": 5,
		"effect": {"type": "speed_boost", "value": 1.5, "duration": 10.0},
		"buy_price": 80,
		"sell_price": 40
	})
	
	_register_item("invincibility_potion", {
		"name": "无敌药水",
		"description": "5秒内免疫所有伤害",
		"icon": "potion_gold",
		"type": "consumable",
		"max_stack": 3,
		"effect": {"type": "invincibility", "duration": 5.0},
		"buy_price": 200,
		"sell_price": 100
	})
	
	_register_item("jump_boost_potion", {
		"name": "弹跳药水",
		"description": "15秒内跳跃高度提升30%",
		"icon": "potion_green",
		"type": "consumable",
		"max_stack": 5,
		"effect": {"type": "jump_boost", "value": 1.3, "duration": 15.0},
		"buy_price": 60,
		"sell_price": 30
	})
	
	_register_item("double_coins", {
		"name": "双倍金币",
		"description": "30秒内获得的金币翻倍",
		"icon": "coin_double",
		"type": "consumable",
		"max_stack": 3,
		"effect": {"type": "double_coins", "value": 2.0, "duration": 30.0},
		"buy_price": 150,
		"sell_price": 75
	})
	
	# 永久道具
	_register_item("extra_life", {
		"name": "额外生命",
		"description": "死亡时自动复活一次",
		"icon": "heart_gold",
		"type": "permanent",
		"max_stack": 3,
		"effect": {"type": "extra_life"},
		"buy_price": 500,
		"sell_price": 250
	})
	
	_register_item("coin_magnet", {
		"name": "金币磁铁",
		"description": "自动吸引附近的金币",
		"icon": "magnet",
		"type": "permanent",
		"max_stack": 1,
		"effect": {"type": "coin_magnet", "range": 100.0},
		"buy_price": 300,
		"sell_price": 150
	})
	
	_register_item("lucky_charm", {
		"name": "幸运护符",
		"description": "敌人掉落金币增加20%",
		"icon": "clover",
		"type": "permanent",
		"max_stack": 1,
		"effect": {"type": "luck_boost", "value": 1.2},
		"buy_price": 400,
		"sell_price": 200
	})

## 注册道具
func _register_item(item_id: String, data: Dictionary) -> void:
	data["id"] = item_id
	item_definitions[item_id] = data

## 添加道具到背包
func add_item(item_id: String, count: int = 1) -> bool:
	if not item_definitions.has(item_id):
		push_error("[ItemManager] 未知道具: %s" % item_id)
		return false
	
	var item_def = item_definitions[item_id]
	var max_stack = item_def.get("max_stack", max_stack_size)
	
	# 检查是否已有该道具
	if inventory.has(item_id):
		var current = inventory[item_id]
		var new_count = min(current + count, max_stack)
		var added = new_count - current
		
		if added > 0:
			inventory[item_id] = new_count
			item_added.emit(item_id, added)
			return true
		return false
	else:
		# 检查背包是否已满
		if inventory.size() >= max_inventory_slots:
			push_error("[ItemManager] 背包已满")
			return false
		
		inventory[item_id] = min(count, max_stack)
		item_added.emit(item_id, inventory[item_id])
		return true

## 移除道具
func remove_item(item_id: String, count: int = 1) -> bool:
	if not inventory.has(item_id):
		return false
	
	var current = inventory[item_id]
	if current < count:
		return false
	
	inventory[item_id] -= count
	
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	
	item_removed.emit(item_id, count)
	return true

## 使用道具
func use_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	
	var item_def = item_definitions[item_id]
	var effect = item_def.get("effect", {})
	
	# 应用道具效果
	var success = _apply_item_effect(effect)
	
	if success:
		# 消耗品使用后减少数量
		if item_def.get("type") == "consumable":
			remove_item(item_id, 1)
		
		item_used.emit(item_id)
		
		# 播放使用音效
		if AudioManager:
			AudioManager.play_sfx("power_up")
	
	return success

## 应用道具效果
func _apply_item_effect(effect: Dictionary) -> bool:
	if effect.is_empty():
		return false
	
	var effect_type = effect.get("type", "")
	var player = get_tree().get_first_node_in_group("player")
	
	match effect_type:
		"heal":
			if player and "current_health" in player:
				var heal_amount = effect.get("value", 0)
				var max_health = player.MAX_HEALTH if "MAX_HEALTH" in player else 100
				player.current_health = min(player.current_health + heal_amount, max_health)
				if player.has_signal("health_changed"):
					player.health_changed.emit(player.current_health)
				
				if FloatingTextManager:
					FloatingTextManager.show_text(player.global_position + Vector2(0, -30), "+%d HP" % heal_amount, Color(0.2, 1.0, 0.2))
				return true
		
		"speed_boost":
			var duration = effect.get("duration", 10.0)
			var value = effect.get("value", 1.5)
			_add_timed_effect("speed_boost", duration, value)
			return true
		
		"invincibility":
			var duration = effect.get("duration", 5.0)
			_add_timed_effect("invincibility", duration, 1.0)
			if player and player.has_method("start_invincibility"):
				player.start_invincibility(duration)
			return true
		
		"jump_boost":
			var duration = effect.get("duration", 15.0)
			var value = effect.get("value", 1.3)
			_add_timed_effect("jump_boost", duration, value)
			return true
		
		"double_coins":
			var duration = effect.get("duration", 30.0)
			var value = effect.get("value", 2.0)
			_add_timed_effect("double_coins", duration, value)
			return true
		
		"extra_life":
			# 额外生命效果会在玩家死亡时自动触发
			return true
		
		"coin_magnet":
			# 金币磁铁是永久效果
			return true
		
		"luck_boost":
			# 幸运加成是永久效果
			return true
	
	return false

## 添加限时效果
func _add_timed_effect(effect_type: String, duration: float, strength: float = 1.0) -> void:
	active_effects[effect_type] = {
		"remaining_time": duration,
		"strength": strength
	}
	effect_applied.emit(effect_type, duration)
	Logger.debug("ItemManager", 效果已激活: %s (%.1f秒)" % [effect_type, duration])

## 更新激活的效果
func _update_active_effects(delta: float) -> void:
	var expired_effects: Array[String] = []
	
	for effect_type in active_effects.keys():
		active_effects[effect_type]["remaining_time"] -= delta
		
		if active_effects[effect_type]["remaining_time"] <= 0:
			expired_effects.append(effect_type)
	
	for effect_type in expired_effects:
		active_effects.erase(effect_type)
		effect_expired.emit(effect_type)
		Logger.debug("ItemManager", 效果已过期: %s" % effect_type)

## 检查效果是否激活
func is_effect_active(effect_type: String) -> bool:
	return active_effects.has(effect_type)

## 获取效果强度
func get_effect_strength(effect_type: String) -> float:
	if active_effects.has(effect_type):
		return active_effects[effect_type]["strength"]
	return 1.0

## 获取效果剩余时间
func get_effect_remaining_time(effect_type: String) -> float:
	if active_effects.has(effect_type):
		return active_effects[effect_type]["remaining_time"]
	return 0.0

## 检查是否拥有道具
func has_item(item_id: String) -> bool:
	return inventory.has(item_id) and inventory[item_id] > 0

## 获取道具数量
func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

## 获取道具信息
func get_item_info(item_id: String) -> Dictionary:
	if item_definitions.has(item_id):
		var info = item_definitions[item_id].duplicate()
		info["count"] = get_item_count(item_id)
		return info
	return {}

## 获取所有背包道具
func get_all_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item_id in inventory.keys():
		if inventory[item_id] > 0:
			var info = get_item_info(item_id)
			items.append(info)
	return items

## 检查是否拥有额外生命
func has_extra_life() -> bool:
	return has_item("extra_life")

## 使用额外生命
func use_extra_life() -> bool:
	if has_extra_life():
		remove_item("extra_life", 1)
		return true
	return false

## 获取金币倍率
func get_coin_multiplier() -> float:
	var multiplier = 1.0
	
	# 双倍金币效果
	if is_effect_active("double_coins"):
		multiplier *= get_effect_strength("double_coins")
	
	# 幸运护符（永久道具）
	if has_item("lucky_charm"):
		var charm = item_definitions.get("lucky_charm", {})
		var luck_value = charm.get("effect", {}).get("value", 1.0)
		multiplier *= luck_value
	
	return multiplier

## 获取金币磁铁范围
func get_coin_magnet_range() -> float:
	if has_item("coin_magnet"):
		var magnet = item_definitions.get("coin_magnet", {})
		return magnet.get("effect", {}).get("range", 0.0)
	return 0.0

## 保存数据
func save_data() -> Dictionary:
	return {
		"inventory": inventory.duplicate()
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.has("inventory"):
		inventory = data["inventory"].duplicate()

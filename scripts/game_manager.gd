extends Node

# 预加载所有系统
var resource_system = preload("res://scripts/resource_system.gd").new()
var environment_system = preload("res://scripts/environment_system.gd").new()
var production_manager = preload("res://scripts/production_manager.gd").new()

# 居民列表
var colonists = []

# 游戏状态
var game_time = 0.0
var is_paused = false

func _ready():
	# 添加所有系统到场景树
	add_child(resource_system)
	add_child(environment_system)
	add_child(production_manager)
	
	# 连接信号
	_connect_signals()

# 连接所有系统之间的信号
func _connect_signals():
	# 资源系统信号
	resource_system.connect("resource_critical", self, "_on_resource_critical")
	resource_system.connect("resource_normal", self, "_on_resource_normal")
	
	# 环境系统信号
	environment_system.connect("environment_critical", self, "_on_environment_critical")
	environment_system.connect("environment_normal", self, "_on_environment_normal")
	
	# 生产管理器信号
	production_manager.connect("facility_state_changed", self, "_on_facility_state_changed")
	production_manager.connect("production_changed", self, "_on_production_changed")
	production_manager.connect("consumption_changed", self, "_on_consumption_changed")
	production_manager.connect("maintenance_needed", self, "_on_maintenance_needed")

# 添加新居民
func add_colonist(colonist):
	colonists.append(colonist)
	add_child(colonist)
	
	# 连接居民信号
	colonist.connect("need_critical", self, "_on_colonist_need_critical", [colonist])
	colonist.connect("need_normal", self, "_on_colonist_need_normal")
	colonist.connect("state_changed", self, "_on_colonist_state_changed")

# 资源系统回调
func _on_resource_critical(resource_type):
	# 当资源达到临界值时，通知所有居民
	for colonist in colonists:
		match resource_type:
			resource_system.ResourceType.OXYGEN:
				colonist.needs[colonist.NeedType.OXYGEN].current = colonist.needs[colonist.NeedType.OXYGEN].critical_level
			resource_system.ResourceType.WATER:
				colonist.needs[colonist.NeedType.WATER].current = colonist.needs[colonist.NeedType.WATER].critical_level
			resource_system.ResourceType.FOOD:
				colonist.needs[colonist.NeedType.FOOD].current = colonist.needs[colonist.NeedType.FOOD].critical_level

func _on_resource_normal(resource_type):
	# 资源恢复正常时的处理
	pass

# 环境系统回调
func _on_environment_critical(parameter):
	match parameter:
		"temperature":
			# 温度过高或过低时，影响所有设施效率
			for facility_type in production_manager.facilities:
				var facility = production_manager.facilities[facility_type]
				if facility.is_running:
					production_manager._update_efficiency(facility)
		"oxygen":
			# 氧气不足时，影响居民健康
			for colonist in colonists:
				colonist.needs[colonist.NeedType.HEALTH].current -= 1.0
		"toxicity":
			# 毒性过高时，影响居民健康
			for colonist in colonists:
				colonist.needs[colonist.NeedType.HEALTH].current -= 2.0
		"radiation":
			# 辐射过高时，影响居民健康
			for colonist in colonists:
				colonist.needs[colonist.NeedType.HEALTH].current -= 3.0

func _on_environment_normal(parameter):
	# 环境恢复正常时的处理
	pass

# 生产管理器回调
func _on_facility_state_changed(facility_type, is_running):
	var facility = production_manager.facilities[facility_type]
	
	# 更新资源系统的生产和消耗速率
	for resource_type in facility.production:
		var amount = facility.production[resource_type]
		if is_running:
			resource_system.set_resource_production(resource_type, amount)
		else:
			resource_system.set_resource_production(resource_type, 0.0)
	
	for resource_type in facility.consumption:
		var amount = facility.consumption[resource_type]
		if is_running:
			resource_system.set_resource_consumption(resource_type, amount)
		else:
			resource_system.set_resource_consumption(resource_type, 0.0)

func _on_production_changed(facility_type, resource_type, amount):
	# 更新环境系统
	match resource_type:
		"heat":
			environment_system.add_heat(amount)
		"oxygen":
			environment_system.environment_data.oxygen_level = resource_system.get_resource(resource_system.ResourceType.OXYGEN) / resource_system.get_resource_max(resource_system.ResourceType.OXYGEN)

func _on_consumption_changed(facility_type, resource_type, amount):
	# 资源消耗时的处理
	pass

func _on_maintenance_needed(facility_type):
	# 设施需要维护时的处理
	var facility = production_manager.facilities[facility_type]
	print("设施 %s 需要维护！当前维护水平：%.2f" % [facility.name, facility.maintenance_level])

# 居民系统回调
func _on_colonist_need_critical(need_type, colonist):
	match need_type:
		colonist.NeedType.OXYGEN:
			# 寻找最近的制氧机
			var oxygen_generator = _find_nearest_facility(production_manager.FacilityType.OXYGEN_GENERATOR, colonist)
			if oxygen_generator:
				colonist.set_target_position(oxygen_generator.global_position)
		colonist.NeedType.WATER:
			# 寻找最近的水源
			var water_purifier = _find_nearest_facility(production_manager.FacilityType.WATER_PURIFIER, colonist)
			if water_purifier:
				colonist.set_target_position(water_purifier.global_position)
		colonist.NeedType.FOOD:
			# 寻找最近的食物
			var farm = _find_nearest_facility(production_manager.FacilityType.FARM, colonist)
			if farm:
				colonist.set_target_position(farm.global_position)
		colonist.NeedType.HEALTH:
			# 寻找最近的医疗舱
			var medical_bay = _find_nearest_facility(production_manager.FacilityType.MEDICAL_BAY, colonist)
			if medical_bay:
				colonist.set_target_position(medical_bay.global_position)

func _on_colonist_need_normal(need_type):
	# 需求恢复正常时的处理
	pass

func _on_colonist_state_changed(new_state):
	# 居民状态改变时的处理
	pass

# 辅助函数：查找最近的设施
func _find_nearest_facility(facility_type, colonist):
	var nearest_facility = null
	var min_distance = INF
	
	for facility in get_tree().get_nodes_in_group("facilities"):
		if facility.facility_type == facility_type:
			var distance = facility.global_position.distance_to(colonist.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_facility = facility
	
	return nearest_facility

# 游戏主循环
func _process(delta):
	if is_paused:
		return
		
	# 更新游戏时间
	game_time += delta
	
	# 更新所有系统
	resource_system._process(delta)
	environment_system._process(delta)
	production_manager._process(delta)
	
	# 更新所有居民
	for colonist in colonists:
		colonist._process(delta)

# 暂停游戏
func pause_game():
	is_paused = true

# 继续游戏
func resume_game():
	is_paused = false

# 获取游戏时间
func get_game_time():
	return game_time

# 获取游戏状态
func get_game_status():
	return {
		"time": game_time,
		"is_paused": is_paused,
		"colonist_count": colonists.size(),
		"resource_status": resource_system.get_all_resources_status(),
		"environment_status": environment_system.get_environment_status()
	}

extends Node

# 生产设施类型枚举
enum FacilityType {
	OXYGEN_GENERATOR = 0,  # 制氧机
	WATER_PURIFIER = 1,    # 净水器
	POWER_GENERATOR = 2,   # 发电机
	FARM = 3,             # 农场
	RESEARCH_LAB = 4,     # 研究实验室
	MEDICAL_BAY = 5,      # 医疗舱
	WORKSHOP = 6          # 工作坊
}

# 生产设施数据
var facilities = {
	FacilityType.OXYGEN_GENERATOR: {
		"name": "制氧机",
		"production": {
			"oxygen": 10.0,  # 每秒生产量
			"heat": 5.0      # 每秒产生热量
		},
		"consumption": {
			"power": 5.0,    # 每秒消耗电力
			"water": 2.0     # 每秒消耗水
		},
		"efficiency": 1.0,   # 效率系数
		"is_running": false,
		"maintenance_level": 1.0  # 维护水平（0-1）
	},
	FacilityType.WATER_PURIFIER: {
		"name": "净水器",
		"production": {
			"water": 8.0,    # 每秒生产量
			"heat": 3.0      # 每秒产生热量
		},
		"consumption": {
			"power": 4.0,    # 每秒消耗电力
			"dirt": 1.0      # 每秒消耗泥土
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	},
	FacilityType.POWER_GENERATOR: {
		"name": "发电机",
		"production": {
			"power": 15.0,   # 每秒生产量
			"heat": 10.0     # 每秒产生热量
		},
		"consumption": {
			"water": 3.0,    # 每秒消耗水
			"metal": 0.1     # 每秒消耗金属（维护）
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	},
	FacilityType.FARM: {
		"name": "农场",
		"production": {
			"food": 5.0,     # 每秒生产量
			"oxygen": 2.0    # 每秒产生氧气
		},
		"consumption": {
			"water": 4.0,    # 每秒消耗水
			"power": 2.0,    # 每秒消耗电力
			"dirt": 0.5      # 每秒消耗泥土
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	},
	FacilityType.RESEARCH_LAB: {
		"name": "研究实验室",
		"production": {
			"research": 3.0  # 每秒研究点数
		},
		"consumption": {
			"power": 6.0,    # 每秒消耗电力
			"water": 1.0     # 每秒消耗水
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	},
	FacilityType.MEDICAL_BAY: {
		"name": "医疗舱",
		"production": {
			"health": 5.0    # 每秒治疗量
		},
		"consumption": {
			"power": 4.0,    # 每秒消耗电力
			"water": 2.0     # 每秒消耗水
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	},
	FacilityType.WORKSHOP: {
		"name": "工作坊",
		"production": {
			"metal": 2.0,    # 每秒生产量
			"plastic": 1.0,  # 每秒生产量
			"glass": 1.0     # 每秒生产量
		},
		"consumption": {
			"power": 8.0,    # 每秒消耗电力
			"water": 2.0     # 每秒消耗水
		},
		"efficiency": 1.0,
		"is_running": false,
		"maintenance_level": 1.0
	}
}

# 信号
signal facility_state_changed(facility_type, is_running)
signal production_changed(facility_type, resource_type, amount)
signal consumption_changed(facility_type, resource_type, amount)
signal maintenance_needed(facility_type)

# 预加载系统
var resource_system = preload("res://scripts/resource_system.gd").new()
var environment_system = preload("res://scripts/environment_system.gd").new()

func _ready():
	# 初始化生产管理器
	pass

func _process(delta):
	_update_facilities(delta)

# 更新所有设施
func _update_facilities(delta):
	for facility_type in facilities:
		var facility = facilities[facility_type]
		if facility.is_running:
			_process_facility(facility_type, facility, delta)

# 处理单个设施
func _process_facility(facility_type, facility, delta):
	# 检查资源是否足够
	if _check_resources(facility):
		# 消耗资源
		_consume_resources(facility, delta)
		
		# 生产资源
		_produce_resources(facility_type, facility, delta)
		
		# 更新效率
		_update_efficiency(facility)
		
		# 更新维护水平
		_update_maintenance(facility, delta)
	else:
		# 资源不足，停止生产
		set_facility_running(facility_type, false)

# 检查资源是否足够
func _check_resources(facility):
	for resource_type in facility.consumption:
		var amount = facility.consumption[resource_type]
		if not resource_system.has_enough_resource(resource_type, amount):
			return false
	return true

# 消耗资源
func _consume_resources(facility, delta):
	for resource_type in facility.consumption:
		var amount = facility.consumption[resource_type] * delta
		resource_system.consume_resource(resource_type, amount)
		emit_signal("consumption_changed", facility_type, resource_type, amount)

# 生产资源
func _produce_resources(facility_type, facility, delta):
	for resource_type in facility.production:
		var amount = facility.production[resource_type] * facility.efficiency * delta
		resource_system.add_resource(resource_type, amount)
		emit_signal("production_changed", facility_type, resource_type, amount)

# 更新效率
func _update_efficiency(facility):
	# 获取环境效率修正
	var environment_modifier = environment_system.get_environment_efficiency_modifier()
	
	# 计算最终效率
	facility.efficiency = facility.maintenance_level * environment_modifier

# 更新维护水平
func _update_maintenance(facility, delta):
	# 维护水平随时间降低
	facility.maintenance_level = max(0.0, facility.maintenance_level - 0.001 * delta)
	
	# 如果维护水平过低，发出信号
	if facility.maintenance_level < 0.3:
		emit_signal("maintenance_needed", facility_type)

# 设置设施运行状态
func set_facility_running(facility_type, is_running):
	var facility = facilities[facility_type]
	if facility.is_running != is_running:
		facility.is_running = is_running
		emit_signal("facility_state_changed", facility_type, is_running)

# 获取设施运行状态
func is_facility_running(facility_type):
	return facilities[facility_type].is_running

# 获取设施效率
func get_facility_efficiency(facility_type):
	return facilities[facility_type].efficiency

# 获取设施生产速率
func get_facility_production(facility_type, resource_type):
	var facility = facilities[facility_type]
	if facility.production.has(resource_type):
		return facility.production[resource_type] * facility.efficiency
	return 0.0

# 获取设施消耗速率
func get_facility_consumption(facility_type, resource_type):
	var facility = facilities[facility_type]
	if facility.consumption.has(resource_type):
		return facility.consumption[resource_type]
	return 0.0

# 升级设施
func upgrade_facility(facility_type):
	var facility = facilities[facility_type]
	
	# 增加生产速率
	for resource_type in facility.production:
		facility.production[resource_type] *= 1.2
	
	# 增加消耗速率
	for resource_type in facility.consumption:
		facility.consumption[resource_type] *= 1.1
	
	# 提高基础效率
	facility.efficiency *= 1.1

# 维护设施
func maintain_facility(facility_type):
	var facility = facilities[facility_type]
	
	# 恢复维护水平
	facility.maintenance_level = 1.0
	
	# 消耗维护资源
	resource_system.consume_resource(resource_system.ResourceType.METAL, 10.0)
	resource_system.consume_resource(resource_system.ResourceType.PLASTIC, 5.0)

# 获取设施维护水平
func get_facility_maintenance_level(facility_type):
	return facilities[facility_type].maintenance_level

# 获取设施名称
func get_facility_name(facility_type):
	return facilities[facility_type].name 
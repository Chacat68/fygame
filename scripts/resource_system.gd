extends Node

# 资源类型枚举
enum ResourceType {
	OXYGEN = 0,    # 氧气
	WATER = 1,     # 水
	POWER = 2,     # 电力
	HEAT = 3,      # 热量
	METAL = 4,     # 金属
	PLASTIC = 5,   # 塑料
	GLASS = 6,     # 玻璃
	DIRT = 7,      # 泥土
	FOOD = 8       # 食物
}

# 资源数据
var resources = {
	ResourceType.OXYGEN: {
		"name": "氧气",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.WATER: {
		"name": "水",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.POWER: {
		"name": "电力",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.HEAT: {
		"name": "热量",
		"current": 20.0,  # 摄氏度
		"max": 50.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 40.0
	},
	ResourceType.METAL: {
		"name": "金属",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.PLASTIC: {
		"name": "塑料",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.GLASS: {
		"name": "玻璃",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.DIRT: {
		"name": "泥土",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	},
	ResourceType.FOOD: {
		"name": "食物",
		"current": 1000.0,
		"max": 2000.0,
		"production": 0.0,
		"consumption": 0.0,
		"critical_level": 200.0
	}
}

# 资源更新间隔（秒）
var update_interval = 1.0
var time_since_last_update = 0.0

# 信号
signal resource_changed(resource_type, current_value, max_value)
signal resource_critical(resource_type)
signal resource_normal(resource_type)

func _ready():
	# 初始化资源系统
	pass

func _process(delta):
	time_since_last_update += delta
	if time_since_last_update >= update_interval:
		_update_resources()
		time_since_last_update = 0.0

# 更新所有资源
func _update_resources():
	for resource_type in resources:
		var resource = resources[resource_type]
		
		# 更新资源值
		resource.current += (resource.production - resource.consumption) * update_interval
		
		# 确保资源在合理范围内
		resource.current = clamp(resource.current, 0.0, resource.max)
		
		# 检查资源状态
		if resource.current <= resource.critical_level:
			emit_signal("resource_critical", resource_type)
		else:
			emit_signal("resource_normal", resource_type)
		
		# 发出资源变化信号
		emit_signal("resource_changed", resource_type, resource.current, resource.max)

# 获取资源当前值
func get_resource(resource_type):
	return resources[resource_type].current

# 获取资源最大值
func get_resource_max(resource_type):
	return resources[resource_type].max

# 获取资源生产速率
func get_resource_production(resource_type):
	return resources[resource_type].production

# 获取资源消耗速率
func get_resource_consumption(resource_type):
	return resources[resource_type].consumption

# 设置资源生产速率
func set_resource_production(resource_type, value):
	resources[resource_type].production = value

# 设置资源消耗速率
func set_resource_consumption(resource_type, value):
	resources[resource_type].consumption = value

# 添加资源
func add_resource(resource_type, amount):
	var resource = resources[resource_type]
	resource.current = clamp(resource.current + amount, 0.0, resource.max)
	emit_signal("resource_changed", resource_type, resource.current, resource.max)

# 消耗资源
func consume_resource(resource_type, amount):
	var resource = resources[resource_type]
	resource.current = clamp(resource.current - amount, 0.0, resource.max)
	emit_signal("resource_changed", resource_type, resource.current, resource.max)

# 检查是否有足够的资源
func has_enough_resource(resource_type, amount):
	return resources[resource_type].current >= amount

# 获取资源状态（正常/警告/危险）
func get_resource_status(resource_type):
	var resource = resources[resource_type]
	var percentage = resource.current / resource.max
	
	if percentage <= 0.1:
		return "danger"
	elif percentage <= 0.3:
		return "warning"
	else:
		return "normal"

# 获取资源名称
func get_resource_name(resource_type):
	return resources[resource_type].name

# 获取所有资源状态
func get_all_resources_status():
	var status = {}
	for resource_type in resources:
		status[resource_type] = get_resource_status(resource_type)
	return status 
extends Node

# 房间配置系统
# 用于管理不同类型房间的配置参数，基于《缺氧》风格

# 房间类型枚举
enum RoomType {
	ENTRANCE = 0,    # 入口房间
	CORRIDOR = 1,    # 走廊
	LIVING = 2,      # 生活区
	FARM = 3,        # 农场
	POWER = 4,       # 发电站
	RESEARCH = 5,    # 研究站
	STORAGE = 6,     # 储藏室
	MEDICAL = 7,     # 医疗站
	INDUSTRIAL = 8,  # 工业区
	RECREATION = 9,  # 娱乐区
	WATER = 10,      # 水处理
	OXYGEN = 11      # 制氧站
}

# 房间配置数据
var room_configs = {
	RoomType.ENTRANCE: {
		"name": "入口",
		"color": Color(0.2, 0.6, 0.8, 0.5),  # 蓝色
		"size": Vector2(8, 4),  # 以格子为单位
		"required_resources": {
			"metal": 100,
			"plastic": 50
		},
		"power_consumption": 0,
		"oxygen_production": 0,
		"heat_production": 0,
		"water_consumption": 0,
		"priority": 1
	},
	RoomType.CORRIDOR: {
		"name": "走廊",
		"color": Color(0.4, 0.4, 0.4, 0.5),  # 灰色
		"size": Vector2(4, 2),
		"required_resources": {
			"metal": 20
		},
		"power_consumption": 0,
		"oxygen_production": 0,
		"heat_production": 0,
		"water_consumption": 0,
		"priority": 0
	},
	RoomType.LIVING: {
		"name": "生活区",
		"color": Color(0.8, 0.6, 0.4, 0.5),  # 橙色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 150,
			"plastic": 100
		},
		"power_consumption": 100,
		"oxygen_production": 0,
		"heat_production": 100,
		"water_consumption": 50,
		"priority": 2
	},
	RoomType.FARM: {
		"name": "农场",
		"color": Color(0.2, 0.8, 0.2, 0.5),  # 绿色
		"size": Vector2(8, 4),
		"required_resources": {
			"metal": 200,
			"plastic": 150,
			"dirt": 100
		},
		"power_consumption": 200,
		"oxygen_production": 50,
		"heat_production": 200,
		"water_consumption": 200,
		"priority": 3
	},
	RoomType.POWER: {
		"name": "发电站",
		"color": Color(0.8, 0.2, 0.2, 0.5),  # 红色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 300,
			"plastic": 200
		},
		"power_consumption": 0,
		"oxygen_production": 0,
		"heat_production": 500,
		"water_consumption": 100,
		"priority": 2
	},
	RoomType.RESEARCH: {
		"name": "研究站",
		"color": Color(0.6, 0.2, 0.8, 0.5),  # 紫色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 200,
			"plastic": 150,
			"glass": 100
		},
		"power_consumption": 150,
		"oxygen_production": 0,
		"heat_production": 150,
		"water_consumption": 50,
		"priority": 2
	},
	RoomType.STORAGE: {
		"name": "储藏室",
		"color": Color(0.5, 0.3, 0.0, 0.5),  # 棕色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 100,
			"plastic": 50
		},
		"power_consumption": 0,
		"oxygen_production": 0,
		"heat_production": 0,
		"water_consumption": 0,
		"priority": 1
	},
	RoomType.MEDICAL: {
		"name": "医疗站",
		"color": Color(1.0, 0.8, 0.8, 0.5),  # 粉色
		"size": Vector2(4, 4),
		"required_resources": {
			"metal": 150,
			"plastic": 200,
			"glass": 100
		},
		"power_consumption": 100,
		"oxygen_production": 0,
		"heat_production": 50,
		"water_consumption": 100,
		"priority": 2
	},
	RoomType.INDUSTRIAL: {
		"name": "工业区",
		"color": Color(0.4, 0.4, 0.4, 0.5),  # 深灰色
		"size": Vector2(8, 4),
		"required_resources": {
			"metal": 400,
			"plastic": 200
		},
		"power_consumption": 300,
		"oxygen_production": 0,
		"heat_production": 400,
		"water_consumption": 200,
		"priority": 2
	},
	RoomType.RECREATION: {
		"name": "娱乐区",
		"color": Color(0.8, 0.8, 0.2, 0.5),  # 黄色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 100,
			"plastic": 200
		},
		"power_consumption": 50,
		"oxygen_production": 0,
		"heat_production": 50,
		"water_consumption": 50,
		"priority": 1
	},
	RoomType.WATER: {
		"name": "水处理",
		"color": Color(0.2, 0.4, 0.8, 0.5),  # 蓝色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 250,
			"plastic": 150,
			"glass": 100
		},
		"power_consumption": 200,
		"oxygen_production": 0,
		"heat_production": 150,
		"water_consumption": 0,
		"priority": 2
	},
	RoomType.OXYGEN: {
		"name": "制氧站",
		"color": Color(0.2, 0.8, 0.8, 0.5),  # 青色
		"size": Vector2(6, 4),
		"required_resources": {
			"metal": 200,
			"plastic": 150,
			"glass": 100
		},
		"power_consumption": 150,
		"oxygen_production": 200,
		"heat_production": 100,
		"water_consumption": 150,
		"priority": 2
	}
}

# 生物群系修改器
var biome_modifiers = {
	"FOREST": {
		"color_modifier": Color(0.2, 0.8, 0.2, 0.0),  # 绿色调
		"resource_modifier": {
			"dirt": 1.5,    # 增加50%泥土
			"water": 1.2,   # 增加20%水
			"oxygen": 1.2   # 增加20%氧气
		},
		"heat_modifier": 0.8,  # 减少20%热量
		"power_modifier": 1.0  # 不变
	},
	"CAVE": {
		"color_modifier": Color(0.6, 0.6, 0.6, 0.0),  # 灰色调
		"resource_modifier": {
			"metal": 1.5,   # 增加50%金属
			"water": 0.8,   # 减少20%水
			"oxygen": 0.8   # 减少20%氧气
		},
		"heat_modifier": 1.2,  # 增加20%热量
		"power_modifier": 1.2  # 增加20%电力
	},
	"SWAMP": {
		"color_modifier": Color(0.5, 0.4, 0.1, 0.0),  # 棕色调
		"resource_modifier": {
			"water": 1.5,   # 增加50%水
			"dirt": 1.3,    # 增加30%泥土
			"oxygen": 0.6   # 减少40%氧气
		},
		"heat_modifier": 1.5,  # 增加50%热量
		"power_modifier": 0.8  # 减少20%电力
	}
}

# 获取房间配置
func get_room_config(room_type, biome_type = "FOREST"):
	var config = room_configs[room_type].duplicate()
	var modifier = biome_modifiers[biome_type]
	
	# 应用生物群系修改
	config.color = config.color + modifier.color_modifier
	
	# 修改资源需求
	for resource in config.required_resources:
		if modifier.resource_modifier.has(resource):
			config.required_resources[resource] = int(config.required_resources[resource] * modifier.resource_modifier[resource])
	
	# 修改其他参数
	config.heat_production = int(config.heat_production * modifier.heat_modifier)
	config.power_consumption = int(config.power_consumption * modifier.power_modifier)
	
	return config

# 获取房间大小
func get_room_size(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.size

# 获取资源需求
func get_required_resources(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.required_resources

# 获取电力消耗
func get_power_consumption(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.power_consumption

# 获取氧气产量
func get_oxygen_production(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.oxygen_production

# 获取热量产生
func get_heat_production(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.heat_production

# 获取水资源消耗
func get_water_consumption(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.water_consumption

# 获取房间优先级
func get_room_priority(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.priority
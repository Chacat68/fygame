extends Resource

# 房间配置资源
# 用于存储不同房间类型的配置数据

# 房间类型枚举
enum RoomType {
	ENTRANCE = 0, # 入口房间
	CORRIDOR = 1, # 走廊房间
	STORAGE = 2, # 储藏室
	OXYGEN = 3, # 氧气房间
	CHALLENGE = 4, # 挑战房间
	TREASURE = 5 # 宝藏房间
}

# 房间配置数据
var room_configs = {
	RoomType.ENTRANCE: {
		"name": "入口",
		"color": Color(0.2, 0.7, 0.3, 0.3), # 绿色半透明
		"platform_count": [3, 5], # 最小值和最大值
		"coin_chance": 0.3,
		"enemy_chance": 0.1,
		"moving_platform_chance": 0.1,
		"purple_slime_chance": 0.0
	},
	RoomType.CORRIDOR: {
		"name": "走廊",
		"color": Color(0.5, 0.5, 0.5, 0.3), # 灰色半透明
		"platform_count": [2, 3], # 最小值和最大值
		"coin_chance": 0.2,
		"enemy_chance": 0.1,
		"moving_platform_chance": 0.3,
		"purple_slime_chance": 0.2
	},
	RoomType.STORAGE: {
		"name": "储藏室",
		"color": Color(0.7, 0.7, 0.2, 0.3), # 黄色半透明
		"platform_count": [4, 6], # 最小值和最大值
		"coin_chance": 0.7,
		"enemy_chance": 0.2,
		"moving_platform_chance": 0.2,
		"purple_slime_chance": 0.3
	},
	RoomType.OXYGEN: {
		"name": "氧气室",
		"color": Color(0.2, 0.6, 0.8, 0.3), # 蓝色半透明
		"platform_count": [3, 5], # 最小值和最大值
		"coin_chance": 0.3,
		"enemy_chance": 0.1,
		"moving_platform_chance": 0.2,
		"purple_slime_chance": 0.1,
		"has_oxygen_generator": true
	},
	RoomType.CHALLENGE: {
		"name": "挑战室",
		"color": Color(0.8, 0.3, 0.3, 0.3), # 红色半透明
		"platform_count": [5, 7], # 最小值和最大值
		"coin_chance": 0.4,
		"enemy_chance": 0.6,
		"moving_platform_chance": 0.4,
		"purple_slime_chance": 0.6
	},
	RoomType.TREASURE: {
		"name": "宝藏室",
		"color": Color(0.8, 0.6, 0.2, 0.3), # 金色半透明
		"platform_count": [3, 4], # 最小值和最大值
		"coin_chance": 0.9,
		"enemy_chance": 0.3,
		"moving_platform_chance": 0.2,
		"purple_slime_chance": 0.5
	}
}

# 生物群系对房间的影响
var biome_modifiers = {
	"FOREST": {
		"color_modifier": null, # 不修改颜色
		"enemy_chance_modifier": 0.0,
		"purple_slime_chance_modifier": 0.0
	},
	"CAVE": {
		"color_modifier": "darken", # 使颜色变暗
		"darken_amount": 0.2,
		"enemy_chance_modifier": 0.1, # 增加敌人出现概率
		"purple_slime_chance_modifier": 0.1 # 增加紫色史莱姆概率
	},
	"SWAMP": {
		"color_modifier": "blend", # 混合颜色
		"blend_color": Color(0.3, 0.3, 0.1, 0.3),
		"enemy_chance_modifier": 0.2, # 大幅增加敌人出现概率
		"purple_slime_chance_modifier": 0.2 # 大幅增加紫色史莱姆概率
	}
}

# 获取房间配置
func get_room_config(room_type, biome_type = "FOREST"):
	# 获取基础配置
	var config = room_configs[room_type].duplicate(true)
	
	# 应用生物群系修改器
	var modifier = biome_modifiers[biome_type]
	
	# 修改敌人和紫色史莱姆概率
	config.enemy_chance += modifier.enemy_chance_modifier
	config.purple_slime_chance += modifier.purple_slime_chance_modifier
	
	# 修改颜色
	if modifier.color_modifier == "darken":
		config.color = config.color.darkened(modifier.darken_amount)
	elif modifier.color_modifier == "blend":
		config.color = config.color.blend(modifier.blend_color)
	
	return config

# 获取平台数量
func get_platform_count(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.platform_count[0] + randi() % (config.platform_count[1] - config.platform_count[0] + 1)

# 判断是否应该放置金币
func should_place_coin(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return randf() < config.coin_chance

# 判断是否应该放置敌人
func should_place_enemy(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return randf() < config.enemy_chance

# 判断是否应该使用移动平台
func should_use_moving_platform(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return randf() < config.moving_platform_chance

# 判断是否应该使用紫色史莱姆
func should_use_purple_slime(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return randf() < config.purple_slime_chance

# 判断是否应该放置氧气发生器
func should_place_oxygen_generator(room_type, biome_type = "FOREST"):
	var config = get_room_config(room_type, biome_type)
	return config.has("has_oxygen_generator") and config.has_oxygen_generator
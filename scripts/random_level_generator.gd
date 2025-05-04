extends Node

# 随机关卡生成器
# 用于生成随机的关卡布局、怪物和金币
# 参考《缺氧》游戏风格，添加生物群系系统、程序化地形生成和房间系统

# 预加载场景
var platform_scene = preload("res://scenes/platform.tscn")
var coin_scene = preload("res://scenes/coin.tscn")
var slime_scene = preload("res://scenes/slime.tscn")

# 生物群系定义
const BIOMES = {
	"FOREST": {
		"name": "森林",
		"platform_color": Color(0.2, 0.8, 0.2),  # 绿色平台
		"enemy_types": ["green_slime", "purple_slime"],
		"resource_types": ["coin", "fruit"],
		"oxygen_level": 1.2,  # 氧气充足
		"background_color": Color(0.1, 0.5, 0.1)  # 深绿色背景
	},
	"CAVE": {
		"name": "洞穴",
		"platform_color": Color(0.6, 0.6, 0.6),  # 灰色平台
		"enemy_types": ["green_slime", "purple_slime"],
		"resource_types": ["coin"],
		"oxygen_level": 0.8,  # 氧气较少
		"background_color": Color(0.2, 0.2, 0.3)  # 深灰色背景
	},
	"SWAMP": {
		"name": "沼泽",
		"platform_color": Color(0.5, 0.4, 0.1),  # 棕色平台
		"enemy_types": ["purple_slime"],
		"resource_types": ["coin"],
		"oxygen_level": 0.6,  # 氧气稀少
		"background_color": Color(0.3, 0.3, 0.1)  # 棕色背景
	}
}

# 关卡管理
const TOTAL_LEVELS = 100  # 游戏总关卡数
var current_level_number = 1  # 当前关卡编号
var level_seeds = {}  # 存储所有关卡的随机种子
var save_file_path = "user://level_seeds.json"  # 关卡种子保存文件路径

# 关卡区域定义
const ENTRANCE_AREA_START = Vector2(100, 250)  # 降低起始高度，使平台更靠近屏幕中央
const MIDDLE_AREA_START = Vector2(400, 230)    # 调整中间区域高度
const CHALLENGE_AREA_START = Vector2(800, 220)  # 调整挑战区域高度
const TREASURE_AREA_START = Vector2(1200, 200)  # 调整宝藏区域高度

# 关卡区域宽度
const AREA_WIDTH = 300

# 平台参数
const MIN_PLATFORM_SPACING = 80   # 增加平台之间的最小间距
const MAX_PLATFORM_SPACING = 150  # 增加平台之间的最大间距
const MIN_PLATFORM_HEIGHT = -30   # 减小高度变化范围
const MAX_PLATFORM_HEIGHT = 30    # 减小高度变化范围

# 金币和怪物参数
const COIN_HEIGHT_ABOVE_PLATFORM = 30  # 金币在平台上方的高度
const SLIME_HEIGHT_ABOVE_PLATFORM = 20  # 史莱姆在平台上方的高度

# 难度参数
const ENTRANCE_MOVING_PLATFORM_CHANCE = 0.1  # 入口区域移动平台概率
const MIDDLE_MOVING_PLATFORM_CHANCE = 0.3    # 中间区域移动平台概率
const CHALLENGE_MOVING_PLATFORM_CHANCE = 0.5  # 挑战区域移动平台概率

const ENTRANCE_PURPLE_SLIME_CHANCE = 0.0  # 入口区域紫色史莱姆概率
const MIDDLE_PURPLE_SLIME_CHANCE = 0.2    # 中间区域紫色史莱姆概率
const CHALLENGE_PURPLE_SLIME_CHANCE = 0.4  # 挑战区域紫色史莱姆概率

# 房间类型枚举
enum RoomType {
	ENTRANCE = 0,  # 入口房间
	CORRIDOR = 1,  # 走廊房间
	STORAGE = 2,   # 储藏室
	OXYGEN = 3,    # 氧气房间
	CHALLENGE = 4, # 挑战房间
	TREASURE = 5   # 宝藏房间
}

# 房间参数
var min_room_size = Vector2(150, 150)
var max_room_size = Vector2(300, 300)
var room_spacing = 50

# 房间布局参数
var level_width = 1500
var level_height = 600
var max_rooms = 8
var min_rooms = 5

# 在准备好时调用
func _ready():
	# 加载已保存的关卡种子
	load_level_seeds()
	
	# 初始化随机数生成器
	randomize()
	
	# 自动生成关卡
	generate_level_by_number(current_level_number)

# 关卡数据结构
class LevelData:
	var platforms = [] # 平台数据
	var coins = [] # 金币数据
	var monsters = [] # 怪物数据
	var biome = "" # 生物群系类型
	var oxygen_level = 1.0 # 氧气水平
	var oxygen_generators = [] # 氧气发生器数据
	var rooms = [] # 房间数据
	var corridors = [] # 走廊数据
	
	func _init(biome_type = "FOREST"):
		platforms = []
		coins = []
		monsters = []
		biome = biome_type # 默认为森林生物群系
		oxygen_level = 1.0
		oxygen_generators = []
		rooms = []
		corridors = []

# 关卡保存目录
const LEVELS_DIR = "user://levels"

# 根据关卡编号生成关卡
func generate_level_by_number(level_number):
	# 确保关卡编号在有效范围内
	level_number = clamp(level_number, 1, TOTAL_LEVELS)
	current_level_number = level_number
	
	# 检查是否已有该关卡的种子
	var seed_value = 0
	if level_seeds.has(str(level_number)):
		seed_value = level_seeds[str(level_number)]
	else:
		# 创建新的随机种子
		seed_value = randi()
		level_seeds[str(level_number)] = seed_value
		# 保存更新后的种子列表
		save_level_seeds()
	
	# 使用种子生成关卡
	generate_random_level_with_seed(seed_value)
	
	# 更新UI显示当前关卡
	update_level_ui()

# 使用特定种子生成随机关卡
func generate_random_level_with_seed(seed_value, level_number = 0):
	# 设置随机种子
	seed(seed_value)
	
	# 清除现有关卡元素
	_clear_level()
	
	# 选择生物群系
	var level_to_use = level_number if level_number > 0 else current_level_number
	var selected_biome = _select_biome_for_level(level_to_use)
	
	# 根据关卡编号决定使用新的房间系统还是旧的区域系统
	if level_number > 3 or (level_number == 0 and current_level_number > 3):
		# 使用新的房间和走廊系统
		_generate_room_based_level(selected_biome)
	else:
		# 创建关卡元素，应用生物群系特性
		_create_random_entrance_area(selected_biome)
		_create_random_middle_area(selected_biome)
		_create_random_challenge_area(selected_biome)
		_create_random_treasure_area(selected_biome)
	
	# 放置氧气发生器
	_place_oxygen_generators(selected_biome)
	
	# 设置背景颜色
	var background_color = BIOMES[selected_biome]["background_color"]
	if has_node("../Background"):
		$"../Background".color = background_color
	
	# 设置相机限制和缩放
	if has_node("Player") and $Player.has_node("Camera2D"):
		$Player/Camera2D.limit_left = 0
		$Player/Camera2D.limit_right = 1500
		$Player/Camera2D.limit_top = -300
		$Player/Camera2D.limit_bottom = 400
		
		# 设置相机缩放，使游戏内容在屏幕上显示得更合适
		$Player/Camera2D.zoom = Vector2(1.5, 1.5)  # 减小缩放值，使游戏元素在屏幕上显示得更大
	
	# 创建氧气UI
	_create_oxygen_ui(selected_biome)
	
	# 更新UI
	update_level_ui()
	
	# 保存生成的关卡
	save_current_level(selected_biome)

# 根据关卡编号选择生物群系
func _select_biome_for_level(level_number):
	# 根据关卡编号选择生物群系
	# 前10关为森林，11-20关为洞穴，21-30关为沼泽，之后循环
	var biome_cycle = (level_number - 1) / 10 % 3
	
	if biome_cycle == 0:
		return "FOREST"
	elif biome_cycle == 1:
		return "CAVE"
	else:
		return "SWAMP"

# 兼容旧代码的函数
func generate_random_level():
	# 生成新的随机关卡
	generate_level_by_number(current_level_number)

# 放置氧气发生器
func _place_oxygen_generators(biome_type):
	# 根据生物群系决定氧气发生器数量
	var generator_count = 0
	if biome_type == "FOREST":
		generator_count = 3  # 森林中氧气发生器较多
	elif biome_type == "CAVE":
		generator_count = 2  # 洞穴中氧气发生器适中
	elif biome_type == "SWAMP":
		generator_count = 1  # 沼泽中氧气发生器稀少
	
	# 在关卡中随机位置放置氧气发生器
	for i in range(generator_count):
		# 随机选择区域
		var area_start = ENTRANCE_AREA_START
		var random_area = randi() % 4
		if random_area == 1:
			area_start = MIDDLE_AREA_START
		elif random_area == 2:
			area_start = CHALLENGE_AREA_START
		elif random_area == 3:
			area_start = TREASURE_AREA_START
		
		# 随机位置
		var pos = Vector2(
			area_start.x + randf_range(50, 250),
			area_start.y + randf_range(-50, 50)
		)
		
		# 创建氧气发生器
		_create_oxygen_generator(pos, biome_type)

# 创建氧气发生器
func _create_oxygen_generator(pos, biome_type):
	# 创建氧气发生器节点
	var generator = Sprite2D.new()
	generator.position = pos
	generator.name = "OxygenGenerator"
	
	# 设置纹理（使用金币纹理作为临时替代）
	var texture = load("res://assets/sprites/coin.png")
	generator.texture = texture
	
	# 根据生物群系设置颜色
	if biome_type == "FOREST":
		generator.modulate = Color(0.3, 0.9, 1.0)  # 蓝色
	elif biome_type == "CAVE":
		generator.modulate = Color(0.5, 0.8, 1.0)  # 淡蓝色
	elif biome_type == "SWAMP":
		generator.modulate = Color(0.2, 0.6, 0.8)  # 深蓝色
	
	# 设置缩放
	generator.scale = Vector2(0.8, 0.8)
	
	# 添加到场景
	if not has_node("OxygenGenerators"):
		var generators = Node2D.new()
		generators.name = "OxygenGenerators"
		add_child(generators)
	
	$OxygenGenerators.add_child(generator)
	
	# 添加发光效果
	var light = PointLight2D.new()
	light.texture = texture
	light.color = Color(0.3, 0.7, 1.0, 0.5)  # 蓝色半透明
	light.energy = 0.8
	light.texture_scale = 3.0
	generator.add_child(light)
	
	# 添加动画
	var anim_player = AnimationPlayer.new()
	generator.add_child(anim_player)
	
	# 创建脉动动画
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, ":scale")
	animation.track_insert_key(track_index, 0.0, Vector2(0.8, 0.8))
	animation.track_insert_key(track_index, 1.0, Vector2(1.0, 1.0))
	animation.set_length(2.0)
	animation.set_loop_mode(Animation.LOOP_PINGPONG)
	
	# 将动画添加到播放器
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("pulse", animation)
	anim_player.add_animation_library("default", anim_lib)
	anim_player.play("default/pulse")
	
	return generator

# 创建氧气UI
func _create_oxygen_ui(biome_type):
	# 如果已有氧气UI，先移除
	if has_node("../UI/OxygenBar"):
		$"../UI/OxygenBar".queue_free()
	
	# 确保UI节点存在
	if not has_node("../UI"):
		var ui = CanvasLayer.new()
		ui.name = "UI"
		get_parent().add_child(ui)
	
	# 创建氧气条背景
	var oxygen_bg = ColorRect.new()
	oxygen_bg.name = "OxygenBarBG"
	oxygen_bg.color = Color(0.2, 0.2, 0.2, 0.7)
	oxygen_bg.size = Vector2(200, 20)
	oxygen_bg.position = Vector2(20, 50)
	$"../UI".add_child(oxygen_bg)
	
	# 创建氧气条
	var oxygen_bar = ColorRect.new()
	oxygen_bar.name = "OxygenBar"
	
	# 根据生物群系设置氧气条颜色
	if biome_type == "FOREST":
		oxygen_bar.color = Color(0.3, 0.9, 1.0)  # 蓝色
	elif biome_type == "CAVE":
		oxygen_bar.color = Color(0.5, 0.8, 1.0)  # 淡蓝色
	elif biome_type == "SWAMP":
		oxygen_bar.color = Color(0.2, 0.6, 0.8)  # 深蓝色
	
	# 设置氧气条大小，根据生物群系的氧气水平
	var oxygen_level = BIOMES[biome_type]["oxygen_level"]
	oxygen_bar.size = Vector2(200 * oxygen_level, 20)
	oxygen_bar.position = Vector2(20, 50)
	$"../UI".add_child(oxygen_bar)
	
	# 添加氧气标签
	var oxygen_label = Label.new()
	oxygen_label.name = "OxygenLabel"
	oxygen_label.text = "氧气: %d%%" % (oxygen_level * 100)
	oxygen_label.position = Vector2(25, 52)
	$"../UI".add_child(oxygen_label)

# 保存当前关卡
func save_current_level(biome_type = "FOREST"):
	# 创建关卡数据对象
	var level_data = LevelData.new()
	
	# 设置生物群系信息
	level_data.biome = biome_type
	level_data.oxygen_level = BIOMES[biome_type]["oxygen_level"]
	
	# 收集平台数据
	if has_node("Platforms"):
		for platform in $Platforms.get_children():
			var platform_data = {
				"position": { "x": platform.position.x, "y": platform.position.y },
				"is_moving": platform.has_node("AnimationPlayer"),
				"biome": biome_type
			}
			level_data.platforms.append(platform_data)
	
	# 收集金币数据
	if has_node("Coins"):
		for coin in $Coins.get_children():
			var coin_data = {
				"position": { "x": coin.position.x, "y": coin.position.y },
				"resource_type": "coin" # 默认为金币，未来可扩展为其他资源类型
			}
			level_data.coins.append(coin_data)
	
	# 收集怪物数据
	if has_node("Monsters"):
		for monster in $Monsters.get_children():
			var is_purple = false
			if monster.has_node("AnimatedSprite2D"):
				var sprite = monster.get_node("AnimatedSprite2D")
				if sprite.sprite_frames.get_animation_speed("default") > 5:
					is_purple = true
			
			var enemy_type = "green_slime"
			if is_purple:
				enemy_type = "purple_slime"
			
			var monster_data = {
				"position": { "x": monster.position.x, "y": monster.position.y },
				"enemy_type": enemy_type
			}
			level_data.monsters.append(monster_data)
	
	# 收集氧气发生器数据
	if has_node("OxygenGenerators"):
		for generator in $OxygenGenerators.get_children():
			var generator_data = {
				"position": { "x": generator.position.x, "y": generator.position.y },
				"biome": biome_type
			}
			level_data.oxygen_generators.append(generator_data)
	
	# 收集房间数据
	if has_node("Rooms"):
		for room in $Rooms.get_children():
			var room_data = {
				"position": { "x": room.position.x, "y": room.position.y },
				"size": { "width": room.scale.x * 100, "height": room.scale.y * 100 },
				"type": room.get_meta("room_type") if room.has_meta("room_type") else 0,
				"biome": biome_type
			}
			level_data.rooms.append(room_data)
	
	# 收集走廊数据
	if has_node("Corridors"):
		for corridor in $Corridors.get_children():
			var corridor_data = {
				"position": { "x": corridor.position.x, "y": corridor.position.y },
				"size": { "width": corridor.scale.x * 100, "height": corridor.scale.y * 100 },
				"start_room": corridor.get_meta("start_room") if corridor.has_meta("start_room") else 0,
				"end_room": corridor.get_meta("end_room") if corridor.has_meta("end_room") else 0,
				"biome": biome_type
			}
			level_data.corridors.append(corridor_data)
	
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(LEVELS_DIR):
		dir.make_dir(LEVELS_DIR)
	
	# 使用关卡编号作为文件名
	var level_file = "%s/level_%d.json" % [LEVELS_DIR, current_level_number]
	
	# 将关卡数据转换为JSON
	var json_data = JSON.stringify(level_data)
	
	# 保存到文件
	var file = FileAccess.open(level_file, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		print("关卡%d已保存到: %s，生物群系: %s" % [current_level_number, level_file, BIOMES[biome_type]["name"]])
	else:
		print("保存关卡失败")

# 保存所有关卡的种子
func save_level_seeds():
	# 将种子数据转换为JSON
	var json_data = JSON.stringify(level_seeds)
	
	# 保存到文件
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		print("关卡种子已保存")
	else:
		print("保存关卡种子失败")

# 加载所有关卡的种子
func load_level_seeds():
	# 检查文件是否存在
	if not FileAccess.file_exists(save_file_path):
		print("没有找到关卡种子文件，将创建新的种子")
		return
	
	# 打开文件
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		print("无法打开关卡种子文件")
		return
	
	# 读取JSON数据
	var json_data = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_data)
	
	if error != OK:
		print("解析JSON失败: %s" % json.get_error_message())
		return
	
	# 获取解析后的数据
	level_seeds = json.get_data()
	print("已加载%d个关卡的种子" % level_seeds.size())

# 更新UI显示当前关卡
func update_level_ui():
	# 如果有关卡UI，更新显示
	if has_node("../UI/LevelLabel"):
		var level_label = get_node("../UI/LevelLabel")
		level_label.text = "关卡: %d/%d" % [current_level_number, TOTAL_LEVELS]
	else:
		# 如果没有UI，创建一个临时的关卡显示
		if not has_node("LevelLabel"):
			var label = Label.new()
			label.name = "LevelLabel"
			label.text = "关卡: %d/%d" % [current_level_number, TOTAL_LEVELS]
			label.position = Vector2(20, 20)
			add_child(label)
		else:
			$LevelLabel.text = "关卡: %d/%d" % [current_level_number, TOTAL_LEVELS]

# 加载关卡
func load_level(level_file):
	# 清除现有关卡元素
	_clear_level()
	
	# 打开文件
	var file = FileAccess.open(level_file, FileAccess.READ)
	if not file:
		print("无法打开关卡文件: %s" % level_file)
		return
	
	# 读取JSON数据
	var json_data = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_data)
	
	if error != OK:
		print("解析JSON失败: %s" % json.get_error_message())
		return
	
	# 获取解析后的数据
	var level_data = json.get_data()
	
	# 获取生物群系信息
	var biome_type = level_data.biome if level_data.has("biome") else "FOREST"
	
	# 创建平台
	for platform_data in level_data.platforms:
		var position = Vector2(platform_data.position.x, platform_data.position.y)
		_create_platform(position, platform_data.is_moving, biome_type)
	
	# 创建金币
	for coin_data in level_data.coins:
		var position = Vector2(coin_data.position.x, coin_data.position.y)
		_create_coin(position, biome_type)
	
	# 创建怪物
	for monster_data in level_data.monsters:
		var position = Vector2(monster_data.position.x, monster_data.position.y)
		var enemy_type = monster_data.enemy_type if monster_data.has("enemy_type") else "green_slime"
		_create_slime(position, enemy_type == "purple_slime", biome_type)
	
	# 加载氧气发生器
	if level_data.has("oxygen_generators"):
		for generator_data in level_data.oxygen_generators:
			var position = Vector2(generator_data.position.x, generator_data.position.y)
			_create_oxygen_generator(position, biome_type)
	
	# 创建氧气UI
	_create_oxygen_ui(biome_type)
	
	print("关卡已加载: %s" % level_file)

# 清除现有关卡元素
func _clear_level():
	# 清除平台
	if has_node("Platforms"):
		for child in $Platforms.get_children():
			child.queue_free()
	
	# 清除金币
	if has_node("Coins"):
		for child in $Coins.get_children():
			child.queue_free()
	
	# 清除怪物
	if has_node("Monsters"):
		for child in $Monsters.get_children():
			child.queue_free()
	
	# 清除氧气发生器
	if has_node("OxygenGenerators"):
		for child in $OxygenGenerators.get_children():
			child.queue_free()
		
	# 清除房间
	if has_node("Rooms"):
		for child in $Rooms.get_children():
			child.queue_free()
		
	# 清除走廊
	if has_node("Corridors"):
		for child in $Corridors.get_children():
			child.queue_free()

# 创建随机入口区域
func _create_random_entrance_area(biome_type = "FOREST"):
	# 入口区域平台数量 (3-5个)
	var platform_count = randi_range(3, 5)
	
	# 创建平台
	var platforms = _generate_platforms(ENTRANCE_AREA_START, platform_count, ENTRANCE_MOVING_PLATFORM_CHANCE, biome_type)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.8)
	_place_coins_on_platforms(platforms, 0.8, biome_type)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.3)
	# 根据生物群系调整紫色史莱姆概率
	var purple_chance = ENTRANCE_PURPLE_SLIME_CHANCE
	if biome_type == "SWAMP":
		purple_chance += 0.2  # 沼泽地区紫色史莱姆更多
	_place_slimes_on_platforms(platforms, 0.3, purple_chance, biome_type)

# 创建随机中间区域
func _create_random_middle_area(biome_type = "FOREST"):
	# 中间区域平台数量 (4-6个)
	var platform_count = randi_range(4, 6)
	
	# 创建平台
	var platforms = _generate_platforms(MIDDLE_AREA_START, platform_count, MIDDLE_MOVING_PLATFORM_CHANCE, biome_type)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.7)
	_place_coins_on_platforms(platforms, 0.7, biome_type)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.4)
	# 根据生物群系调整紫色史莱姆概率
	var purple_chance = MIDDLE_PURPLE_SLIME_CHANCE
	if biome_type == "SWAMP":
		purple_chance += 0.2  # 沼泽地区紫色史莱姆更多
	_place_slimes_on_platforms(platforms, 0.4, purple_chance, biome_type)

# 创建随机挑战区域
func _create_random_challenge_area(biome_type = "FOREST"):
	# 挑战区域平台数量 (5-7个)
	var platform_count = randi_range(5, 7)
	
	# 创建平台
	var platforms = _generate_platforms(CHALLENGE_AREA_START, platform_count, CHALLENGE_MOVING_PLATFORM_CHANCE, biome_type)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.6)
	_place_coins_on_platforms(platforms, 0.6, biome_type)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.5)
	# 根据生物群系调整紫色史莱姆概率
	var purple_chance = CHALLENGE_PURPLE_SLIME_CHANCE
	if biome_type == "SWAMP":
		purple_chance += 0.2  # 沼泽地区紫色史莱姆更多
	_place_slimes_on_platforms(platforms, 0.5, purple_chance, biome_type)
	
	# 添加一些隐藏金币
	_add_hidden_coins(platforms, 2, biome_type)

# 创建随机宝藏区域
func _create_random_treasure_area(biome_type = "FOREST"):
	# 宝藏区域平台数量 (3个)
	var platform_count = 3
	
	# 创建平台
	var platforms = _generate_platforms(TREASURE_AREA_START, platform_count, 0.0, biome_type)  # 宝藏区域不使用移动平台
	
	# 在平台上放置金币 (每个平台上都有金币)
	_place_coins_on_platforms(platforms, 1.0, biome_type)
	
	# 额外添加金币，形成皇冠形状
	_create_crown_shaped_coins(TREASURE_AREA_START, biome_type)
	
	# 在中间平台上放置紫色史莱姆作为最终Boss
	if platforms.size() > 0:
		_create_slime(Vector2(platforms[platforms.size()/2].position.x, 
					 platforms[platforms.size()/2].position.y - SLIME_HEIGHT_ABOVE_PLATFORM), true, biome_type)

# 生成平台
func _generate_platforms(start_pos, count, moving_chance, biome_type = "FOREST"):
	var platforms = []
	var current_pos = start_pos
	
	# 根据生物群系调整移动平台概率
	if biome_type == "CAVE":
		# 洞穴中移动平台更少
		moving_chance *= 0.7
	elif biome_type == "SWAMP":
		# 沼泽中移动平台更多
		moving_chance *= 1.3
		# 确保概率不超过1.0
		moving_chance = min(moving_chance, 1.0)
	
	for i in range(count):
		# 随机决定平台位置
		var platform_pos = Vector2(
			current_pos.x + randf_range(MIN_PLATFORM_SPACING, MAX_PLATFORM_SPACING),
			current_pos.y + randf_range(MIN_PLATFORM_HEIGHT, MAX_PLATFORM_HEIGHT)
		)
		
		# 确保平台不会太高或太低
		platform_pos.y = clamp(platform_pos.y, 150, 280)  # 调整高度范围，使平台分布更合理
		
		# 随机决定是否为移动平台
		var is_moving = randf() < moving_chance
		
		# 创建平台
		var platform = _create_platform(platform_pos, is_moving, biome_type)
		platforms.append(platform)
		
		# 更新当前位置
		current_pos = platform_pos
	
	return platforms

# 在平台上放置金币
func _place_coins_on_platforms(platforms, coin_chance, biome_type = "FOREST"):
	# 根据生物群系调整金币概率
	if biome_type == "CAVE":
		# 洞穴中金币更少
		coin_chance *= 0.8
	elif biome_type == "SWAMP":
		# 沼泽中金币更多
		coin_chance *= 1.2
		# 确保概率不超过1.0
		coin_chance = min(coin_chance, 1.0)
	
	for platform in platforms:
		# 随机决定是否在此平台上放置金币
		if randf() < coin_chance:
			_create_coin(Vector2(
				platform.position.x,
				platform.position.y - COIN_HEIGHT_ABOVE_PLATFORM
			), biome_type)

# 创建金币
func _create_coin(pos, biome_type = "FOREST"):
	var coin = coin_scene.instantiate()
	coin.position = pos
	
	# 添加到场景
	if not has_node("Coins"):
		var coins = Node2D.new()
		coins.name = "Coins"
		add_child(coins)
	
	$Coins.add_child(coin)
	return coin

# 在平台上放置史莱姆
func _place_slimes_on_platforms(platforms, slime_chance, purple_chance, biome_type = "FOREST"):
	# 根据生物群系调整史莱姆概率
	if biome_type == "CAVE":
		# 洞穴中史莱姆更多
		slime_chance *= 1.3
		# 确保概率不超过1.0
		slime_chance = min(slime_chance, 1.0)
	elif biome_type == "SWAMP":
		# 沼泽中紫色史莱姆更多
		purple_chance *= 1.5
		# 确保概率不超过1.0
		purple_chance = min(purple_chance, 1.0)
	
	for platform in platforms:
		# 随机决定是否在此平台上放置史莱姆
		if randf() < slime_chance:
			# 随机决定是否为紫色史莱姆
			var is_purple = randf() < purple_chance
			
			_create_slime(Vector2(
				platform.position.x,
				platform.position.y - SLIME_HEIGHT_ABOVE_PLATFORM
			), is_purple, biome_type)

# 创建史莱姆敌人
func _create_slime(pos, is_purple = false, biome_type = "FOREST"):
	var slime = slime_scene.instantiate()
	slime.position = pos
	
	# 如果是紫色史莱姆，修改精灵图像和速度
	if is_purple:
		var animated_sprite = slime.get_node("AnimatedSprite2D")
		animated_sprite.sprite_frames.set_animation_speed("default", 10) # 增加动画速度
		
		# 加载紫色史莱姆纹理
		var texture = load("res://assets/sprites/slime_purple.png")
		for i in range(animated_sprite.sprite_frames.get_frame_count("default")):
			var atlas_texture = animated_sprite.sprite_frames.get_frame_texture("default", i)
			var new_atlas_texture = AtlasTexture.new()
			new_atlas_texture.atlas = texture
			new_atlas_texture.region = atlas_texture.region
			animated_sprite.sprite_frames.set_frame("default", i, new_atlas_texture)
		
		# 增加移动速度
		slime.SPEED = 60 # 比普通史莱姆快
	
	# 添加到场景
	if not has_node("Monsters"):
		var monsters = Node2D.new()
		monsters.name = "Monsters"
		add_child(monsters)
	
	$Monsters.add_child(slime)
	return slime

# 添加隐藏金币
func _add_hidden_coins(platforms, count, biome_type = "FOREST"):
	for i in range(count):
		# 随机选择一个平台
		if platforms.size() > 0:
			var platform = platforms[randi() % platforms.size()]
			
			# 在平台附近的随机位置创建金币
			_create_coin(Vector2(
				platform.position.x + randf_range(-30, 30),
				platform.position.y - randf_range(50, 80)
			), biome_type)

# 创建皇冠形状的金币
func _create_crown_shaped_coins(center_pos, biome_type = "FOREST"):
	# 创建皇冠顶部的金币
	_create_coin(Vector2(center_pos.x, center_pos.y - 60), biome_type)
	
	# 创建皇冠左侧的金币
	_create_coin(Vector2(center_pos.x - 20, center_pos.y - 50), biome_type)
	_create_coin(Vector2(center_pos.x - 40, center_pos.y - 40), biome_type)
	
	# 创建皇冠右侧的金币
	_create_coin(Vector2(center_pos.x + 20, center_pos.y - 50), biome_type)
	_create_coin(Vector2(center_pos.x + 40, center_pos.y - 40), biome_type)

# 走廊参数
var min_corridor_width = 80
var max_corridor_width = 120
var min_corridor_length = 100
var max_corridor_length = 250

# 生成基于房间的关卡
func _generate_room_based_level(biome_type):
	# 创建房间容器节点
	if not has_node("Rooms"):
		var rooms_node = Node2D.new()
		rooms_node.name = "Rooms"
		add_child(rooms_node)
	
	# 创建走廊容器节点
	if not has_node("Corridors"):
		var corridors_node = Node2D.new()
		corridors_node.name = "Corridors"
		add_child(corridors_node)
	
	# 确定房间数量（根据关卡难度调整）
	var room_count = min_rooms + randi() % (max_rooms - min_rooms + 1)
	
	# 生成房间
	var rooms = []
	var room_rects = []
	
	# 首先创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(100, 200, 200, 200),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(100, 200, 200, 200))
	
	# 最后创建宝藏房间（右侧）
	var treasure_room = _create_room(
		Rect2(level_width - 300, 200, 200, 200),
		RoomType.TREASURE,
		biome_type
	)
	rooms.append(treasure_room)
	room_rects.append(Rect2(level_width - 300, 200, 200, 200))
	
	# 创建中间房间
	for i in range(room_count - 2):
		# 尝试放置房间，确保不重叠
		var attempts = 0
		var room_placed = false
		
		while attempts < 20 and not room_placed:
			# 随机房间大小
			var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
			var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
			
			# 随机位置（确保在关卡范围内）
			var x = 300 + randi() % int(level_width - 600 - room_width)
			var y = 100 + randi() % int(level_height - 200 - room_height)
			
			# 创建房间矩形
			var new_rect = Rect2(x, y, room_width, room_height)
			
			# 检查是否与现有房间重叠
			var overlaps = false
			for existing_rect in room_rects:
				# 扩展现有矩形以考虑间距
				var expanded_rect = Rect2(
					existing_rect.position.x - room_spacing,
					existing_rect.position.y - room_spacing,
					existing_rect.size.x + room_spacing * 2,
					existing_rect.size.y + room_spacing * 2
				)
				
				if expanded_rect.intersects(new_rect):
					overlaps = true
					break
			
			if not overlaps:
				# 确定房间类型
				var room_type
				var type_roll = randi() % 10
				
				if type_roll < 3:
					room_type = RoomType.STORAGE
				elif type_roll < 6:
					room_type = RoomType.OXYGEN
				else:
					room_type = RoomType.CHALLENGE
				
				# 创建房间
				var room = _create_room(new_rect, room_type, biome_type)
				rooms.append(room)
				room_rects.append(new_rect)
				room_placed = true
			
			attempts += 1
	
	# 连接房间（创建走廊）
	_connect_rooms(rooms, room_rects, biome_type)

# 创建房间
func _create_room(rect, room_type, biome_type):
	# 创建房间节点
	var room = ColorRect.new()
	room.position = rect.position
	room.size = rect.size
	room.color = Color(0.2, 0.2, 0.2, 0.5)  # 半透明灰色
	room.set_meta("room_type", room_type)
	
	# 根据房间类型设置颜色
	if room_type == RoomType.ENTRANCE:
		room.color = Color(0.0, 0.5, 0.0, 0.5)  # 绿色（入口）
	elif room_type == RoomType.TREASURE:
		room.color = Color(0.8, 0.8, 0.0, 0.5)  # 金色（宝藏）
	elif room_type == RoomType.OXYGEN:
		room.color = Color(0.0, 0.5, 0.8, 0.5)  # 蓝色（氧气）
	elif room_type == RoomType.CHALLENGE:
		room.color = Color(0.8, 0.0, 0.0, 0.5)  # 红色（挑战）
	elif room_type == RoomType.STORAGE:
		room.color = Color(0.5, 0.3, 0.0, 0.5)  # 棕色（储藏室）
	
	# 添加到房间容器
	$Rooms.add_child(room)
	
	# 在房间内放置平台、金币和敌人
	_place_platforms_in_room(rect, room_type, biome_type)
	
	return room

# 连接房间（创建走廊）
func _connect_rooms(rooms, room_rects, biome_type):
	# 确保所有房间都连接到入口房间
	for i in range(1, rooms.size()):
		# 创建从入口房间到当前房间的走廊
		_create_corridor(room_rects[0], room_rects[i], biome_type)
		
	# 额外添加一些随机连接，增加关卡的复杂性
	var extra_connections = randi() % 3 + 1  # 1-3个额外连接
	for _i in range(extra_connections):
		var from_index = randi() % rooms.size()
		var to_index = randi() % rooms.size()
		
		# 确保不连接到自己
		if from_index != to_index:
			_create_corridor(room_rects[from_index], room_rects[to_index], biome_type)

# 这个函数已被移除，使用房间系统中的对应函数
# 保留此函数签名以兼容旧代码
func _create_corridor(from_rect, to_rect, biome_type):
	# 由于房间系统的函数签名不同，这里不能直接调用
	# 如果需要使用此函数，应该通过房间系统的其他接口实现
	pass

# 这个函数已被移除，使用房间系统中的对应函数
# 保留此函数签名以兼容旧代码
func _place_platforms_in_room(rect, room_type, biome_type):
	# 由于房间系统的实现方式不同，这里不能直接调用
	# 如果需要使用此函数，应该通过房间系统的其他接口实现
	pass

# 这个函数已被移除，使用房间系统中的对应函数
# 保留此函数签名以兼容旧代码
func _place_platforms_in_corridor(position, size, biome_type):
	# 由于房间系统的实现方式不同，这里不能直接调用
	# 如果需要使用此函数，应该通过房间系统的其他接口实现
	pass

# 创建平台
func _create_platform(pos, is_moving = false, biome_type = "FOREST"):
	var platform = platform_scene.instantiate()
	platform.position = pos
	
	# 根据生物群系设置平台颜色
	if biome_type in BIOMES:
		var sprite = platform.get_node("Sprite2D")
		if sprite:
			sprite.modulate = BIOMES[biome_type]["platform_color"]
	
	if is_moving:
		# 添加动画播放器
		var anim_player = AnimationPlayer.new()
		platform.add_child(anim_player)
		
		# 创建移动动画
		var animation = Animation.new()
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, ":position")
		
		# 随机决定移动方向（水平或垂直）
		var is_horizontal = randf() < 0.7  # 70%概率水平移动
		var move_distance = randf_range(40, 80)
		
		if is_horizontal:
			# 水平移动
			animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
			animation.track_insert_key(track_index, 1.3, Vector2(move_distance, 0))
		else:
			# 垂直移动
			animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
			animation.track_insert_key(track_index, 1.3, Vector2(0, move_distance))
		
		animation.set_length(2.6)
		animation.set_loop_mode(Animation.LOOP_PINGPONG)
		
		# 将动画添加到播放器
		var anim_lib = AnimationLibrary.new()
		anim_lib.add_animation("move", animation)
		anim_player.add_animation_library("default", anim_lib)
		anim_player.play("default/move")
	
	# 添加到场景
	if not has_node("Platforms"):
		var platforms = Node2D.new()
		platforms.name = "Platforms"
		add_child(platforms)
	
	$Platforms.add_child(platform)
	return platform

# 注意：这里原本有重复定义的_create_coin和_create_slime函数代码
# 已删除重复代码，请使用第718行和第757行定义的函数

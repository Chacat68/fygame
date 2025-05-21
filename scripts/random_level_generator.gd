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
const TOTAL_LEVELS = 1  # 游戏只有一个关卡
var current_level_number = 1  # 当前关卡编号

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
	# 初始化随机数生成器
	randomize()
	
	# 生成关卡
	generate_level()

# 生成关卡
func generate_level():
	# 清除现有关卡元素
	_clear_level()
	
	# 选择生物群系
	var selected_biome = "FOREST"  # 默认使用森林生物群系
	
	# 生成起始区域
	_generate_starting_area(selected_biome)
	
	# 生成主要关卡区域
	_generate_main_level_area(selected_biome)
	
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
		$Player/Camera2D.zoom = Vector2(1.5, 1.5)
	
	# 创建氧气UI
	_create_oxygen_ui(selected_biome)
	
	# 更新UI
	update_level_ui()

# 更新UI显示当前关卡
func update_level_ui():
	# 如果有关卡UI，更新显示
	if has_node("../UI/LevelLabel"):
		var level_label = get_node("../UI/LevelLabel")
		level_label.text = "探索模式"  # 改为探索模式显示
	else:
		# 如果没有UI，创建一个临时的关卡显示
		if not has_node("LevelLabel"):
			var label = Label.new()
			label.name = "LevelLabel"
			label.text = "探索模式"
			label.position = Vector2(20, 20)
			add_child(label)
		else:
			$LevelLabel.text = "探索模式"

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

# 生成起始区域
func _generate_starting_area(biome_type):
	# 起始区域的大小
	var start_area_width = 200
	var start_area_height = 300
	var start_area_x = 100
	var start_area_y = 200
	
	# 创建起始区域的平台
	# 底部平台
	_create_platform(Vector2(start_area_x, start_area_y + start_area_height), 
		Vector2(start_area_width, 20), biome_type)
	
	# 左侧平台
	_create_platform(Vector2(start_area_x - 20, start_area_y), 
		Vector2(20, start_area_height), biome_type)
	
	# 右侧平台
	_create_platform(Vector2(start_area_x + start_area_width, start_area_y), 
		Vector2(20, start_area_height), biome_type)
	
	# 顶部平台
	_create_platform(Vector2(start_area_x, start_area_y - 20), 
		Vector2(start_area_width, 20), biome_type)
	
	# 设置玩家出生点
	if has_node("Player"):
		$Player.position = Vector2(start_area_x + start_area_width/2, 
			start_area_y + start_area_height/2)

# 生成主要关卡区域
func _generate_main_level_area(biome_type):
	# 主要区域的大小和位置
	var main_area_width = 1200
	var main_area_height = 600
	var main_area_x = 400
	var main_area_y = 100
	
	# 存储所有水平平台，用于后续生成怪物
	var horizontal_platforms = []
	
	# 生成随机平台
	for i in range(20):  # 生成20个随机平台
		var platform_width = randf_range(100, 200)
		var platform_height = 20
		var platform_x = randf_range(main_area_x, main_area_x + main_area_width - platform_width)
		var platform_y = randf_range(main_area_y, main_area_y + main_area_height - platform_height)
		
		# 创建平台
		var platform = _create_platform(Vector2(platform_x, platform_y), 
			Vector2(platform_width, platform_height), biome_type)
		
		# 30%概率创建移动平台
		if randf() < 0.3:
			_make_platform_moving(platform)
		
		# 在平台上放置金币
		_place_coins_on_platform(platform, biome_type)
		
		# 将水平平台添加到列表中
		horizontal_platforms.append(platform)
	
	# 生成一些垂直平台
	for i in range(10):  # 生成10个垂直平台
		var platform_width = 20
		var platform_height = randf_range(100, 200)
		var platform_x = randf_range(main_area_x, main_area_x + main_area_width - platform_width)
		var platform_y = randf_range(main_area_y, main_area_y + main_area_height - platform_height)
		
		# 创建平台
		var platform = _create_platform(Vector2(platform_x, platform_y), 
			Vector2(platform_width, platform_height), biome_type)
		
		# 20%概率创建移动平台
		if randf() < 0.2:
			_make_platform_moving(platform)
	
	# 在水平平台上生成怪物
	_place_monsters_on_platforms(horizontal_platforms, biome_type)

# 使平台移动
func _make_platform_moving(platform):
	# 添加动画播放器
	var anim_player = AnimationPlayer.new()
	platform.add_child(anim_player)
	
	# 创建移动动画
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, ":position")
	
	# 随机决定移动方向（水平或垂直）
	var is_horizontal = randf() < 0.7  # 70%概率水平移动
	var move_distance = randf_range(100, 200)
	
	if is_horizontal:
		# 水平移动
		animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
		animation.track_insert_key(track_index, 2.0, Vector2(move_distance, 0))
	else:
		# 垂直移动
		animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
		animation.track_insert_key(track_index, 2.0, Vector2(0, move_distance))
	
	animation.set_length(4.0)
	animation.set_loop_mode(Animation.LOOP_PINGPONG)
	
	# 将动画添加到播放器
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("move", animation)
	anim_player.add_animation_library("default", anim_lib)
	anim_player.play("default/move")

# 在平台上放置金币
func _place_coins_on_platform(platform, biome_type):
	# 根据生物群系调整金币数量
	var coin_count = 0
	if biome_type == "FOREST":
		coin_count = randi_range(1, 3)  # 森林中金币较多
	elif biome_type == "CAVE":
		coin_count = randi_range(1, 2)  # 洞穴中金币适中
	elif biome_type == "SWAMP":
		coin_count = randi_range(0, 1)  # 沼泽中金币稀少
	
	# 创建金币
	for i in range(coin_count):
		var coin = coin_scene.instantiate()
		# 在平台上均匀分布金币
		var coin_x = platform.position.x + (i + 1) * (platform.get_node("CollisionShape2D").shape.size.x / (coin_count + 1))
		var coin_y = platform.position.y - 30  # 金币在平台上方30像素
		coin.position = Vector2(coin_x, coin_y)
		
		# 添加到场景
		if not has_node("Coins"):
			var coins = Node2D.new()
			coins.name = "Coins"
			add_child(coins)
		
		$Coins.add_child(coin)

# 创建平台
func _create_platform(position, size, biome_type):
	var platform = StaticBody2D.new()
	platform.position = position
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	
	# 添加精灵
	var sprite = Sprite2D.new()
	var texture = load("res://assets/tiles/platform.png")  # 确保这个路径正确
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	platform.add_child(sprite)
	
	# 添加血量系统
	platform.set_meta("health", 100)  # 设置初始血量
	platform.set_meta("max_health", 100)  # 设置最大血量
	
	# 添加半透明效果
	var tween = Tween.new()
	platform.add_child(tween)
	
	# 添加被攻击信号
	platform.connect("input_event", Callable(platform, "_on_input_event"))
	
	# 添加被攻击函数
	platform.set_script(load("res://scripts/destructible_platform.gd"))
	
	add_child(platform)
	return platform

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

# 在平台上放置怪物
func _place_monsters_on_platforms(platforms, biome_type):
	# 根据生物群系调整怪物数量和类型
	var monster_count = 0
	var purple_chance = 0.0
	
	if biome_type == "FOREST":
		monster_count = platforms.size() / 2  # 每两个平台一个怪物
		purple_chance = 0.2  # 20%概率生成紫色史莱姆
	elif biome_type == "CAVE":
		monster_count = platforms.size() / 1.5  # 每1.5个平台一个怪物
		purple_chance = 0.3  # 30%概率生成紫色史莱姆
	elif biome_type == "SWAMP":
		monster_count = platforms.size()  # 每个平台一个怪物
		purple_chance = 0.5  # 50%概率生成紫色史莱姆
	
	# 随机选择平台放置怪物
	var available_platforms = platforms.duplicate()
	for i in range(monster_count):
		if available_platforms.size() == 0:
			break
			
		# 随机选择一个平台
		var platform_index = randi() % available_platforms.size()
		var platform = available_platforms[platform_index]
		available_platforms.remove_at(platform_index)
		
		# 随机决定是否为紫色史莱姆
		var is_purple = randf() < purple_chance
		
		# 在平台上创建怪物
		_create_slime(Vector2(
			platform.position.x + platform.get_node("CollisionShape2D").shape.size.x / 2,
			platform.position.y - 30  # 怪物在平台上方30像素
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

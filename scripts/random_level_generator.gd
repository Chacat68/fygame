extends Node

# 随机关卡生成器
# 用于生成随机的关卡布局、怪物和金币

# 预加载场景
var platform_scene = preload("res://scenes/platform.tscn")
var coin_scene = preload("res://scenes/coin.tscn")
var slime_scene = preload("res://scenes/slime.tscn")

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
	
	func _init():
		platforms = []
		coins = []
		monsters = []

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
func generate_random_level_with_seed(seed_value):
	# 设置随机种子
	seed(seed_value)
	
	# 清除现有关卡元素
	_clear_level()
	
	# 创建关卡元素
	_create_random_entrance_area()
	_create_random_middle_area()
	_create_random_challenge_area()
	_create_random_treasure_area()
	
	# 设置相机限制和缩放
	if has_node("Player") and $Player.has_node("Camera2D"):
		$Player/Camera2D.limit_left = 0
		$Player/Camera2D.limit_right = 1500
		$Player/Camera2D.limit_top = -300
		$Player/Camera2D.limit_bottom = 400
		
		# 设置相机缩放，使游戏内容在屏幕上显示得更合适
		$Player/Camera2D.zoom = Vector2(1.5, 1.5)  # 减小缩放值，使游戏元素在屏幕上显示得更大
	
	# 保存生成的关卡
	save_current_level()

# 兼容旧代码的函数
func generate_random_level():
	# 生成新的随机关卡
	generate_level_by_number(current_level_number)

# 保存当前关卡
func save_current_level():
	# 创建关卡数据对象
	var level_data = LevelData.new()
	
	# 收集平台数据
	if has_node("Platforms"):
		for platform in $Platforms.get_children():
			var platform_data = {
				"position": { "x": platform.position.x, "y": platform.position.y },
				"is_moving": platform.has_node("AnimationPlayer")
			}
			level_data.platforms.append(platform_data)
	
	# 收集金币数据
	if has_node("Coins"):
		for coin in $Coins.get_children():
			var coin_data = {
				"position": { "x": coin.position.x, "y": coin.position.y }
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
			
			var monster_data = {
				"position": { "x": monster.position.x, "y": monster.position.y },
				"is_purple": is_purple
			}
			level_data.monsters.append(monster_data)
	
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
		print("关卡%d已保存到: %s" % [current_level_number, level_file])
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
	
	# 创建平台
	for platform_data in level_data.platforms:
		var position = Vector2(platform_data.position.x, platform_data.position.y)
		_create_platform(position, platform_data.is_moving)
	
	# 创建金币
	for coin_data in level_data.coins:
		var position = Vector2(coin_data.position.x, coin_data.position.y)
		_create_coin(position)
	
	# 创建怪物
	for monster_data in level_data.monsters:
		var position = Vector2(monster_data.position.x, monster_data.position.y)
		_create_slime(position, monster_data.is_purple)
	
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

# 创建随机入口区域
func _create_random_entrance_area():
	# 入口区域平台数量 (3-5个)
	var platform_count = randi_range(3, 5)
	
	# 创建平台
	var platforms = _generate_platforms(ENTRANCE_AREA_START, platform_count, ENTRANCE_MOVING_PLATFORM_CHANCE)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.8)
	_place_coins_on_platforms(platforms, 0.8)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.3)
	_place_slimes_on_platforms(platforms, 0.3, ENTRANCE_PURPLE_SLIME_CHANCE)

# 创建随机中间区域
func _create_random_middle_area():
	# 中间区域平台数量 (4-6个)
	var platform_count = randi_range(4, 6)
	
	# 创建平台
	var platforms = _generate_platforms(MIDDLE_AREA_START, platform_count, MIDDLE_MOVING_PLATFORM_CHANCE)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.7)
	_place_coins_on_platforms(platforms, 0.7)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.4)
	_place_slimes_on_platforms(platforms, 0.4, MIDDLE_PURPLE_SLIME_CHANCE)

# 创建随机挑战区域
func _create_random_challenge_area():
	# 挑战区域平台数量 (5-7个)
	var platform_count = randi_range(5, 7)
	
	# 创建平台
	var platforms = _generate_platforms(CHALLENGE_AREA_START, platform_count, CHALLENGE_MOVING_PLATFORM_CHANCE)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.6)
	_place_coins_on_platforms(platforms, 0.6)
	
	# 在平台上放置史莱姆 (每个平台1个史莱姆的概率为0.5)
	_place_slimes_on_platforms(platforms, 0.5, CHALLENGE_PURPLE_SLIME_CHANCE)
	
	# 添加一些隐藏金币
	_add_hidden_coins(platforms, 2)

# 创建随机宝藏区域
func _create_random_treasure_area():
	# 宝藏区域平台数量 (3个)
	var platform_count = 3
	
	# 创建平台
	var platforms = _generate_platforms(TREASURE_AREA_START, platform_count, 0.0)  # 宝藏区域不使用移动平台
	
	# 在平台上放置金币 (每个平台上都有金币)
	_place_coins_on_platforms(platforms, 1.0)
	
	# 额外添加金币，形成皇冠形状
	_create_crown_shaped_coins(TREASURE_AREA_START)
	
	# 在中间平台上放置紫色史莱姆作为最终Boss
	if platforms.size() > 0:
		_create_slime(Vector2(platforms[platforms.size()/2].position.x, 
					 platforms[platforms.size()/2].position.y - SLIME_HEIGHT_ABOVE_PLATFORM), true)

# 生成平台
func _generate_platforms(start_pos, count, moving_chance):
	var platforms = []
	var current_pos = start_pos
	
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
		var platform = _create_platform(platform_pos, is_moving)
		platforms.append(platform)
		
		# 更新当前位置
		current_pos = platform_pos
	
	return platforms

# 在平台上放置金币
func _place_coins_on_platforms(platforms, coin_chance):
	for platform in platforms:
		# 随机决定是否在此平台上放置金币
		if randf() < coin_chance:
			_create_coin(Vector2(
				platform.position.x,
				platform.position.y - COIN_HEIGHT_ABOVE_PLATFORM
			))

# 在平台上放置史莱姆
func _place_slimes_on_platforms(platforms, slime_chance, purple_chance):
	for platform in platforms:
		# 随机决定是否在此平台上放置史莱姆
		if randf() < slime_chance:
			# 随机决定是否为紫色史莱姆
			var is_purple = randf() < purple_chance
			
			_create_slime(Vector2(
				platform.position.x,
				platform.position.y - SLIME_HEIGHT_ABOVE_PLATFORM
			), is_purple)

# 添加隐藏金币
func _add_hidden_coins(platforms, count):
	for i in range(count):
		# 随机选择一个平台
		if platforms.size() > 0:
			var platform = platforms[randi() % platforms.size()]
			
			# 在平台附近的随机位置创建金币
			_create_coin(Vector2(
				platform.position.x + randf_range(-30, 30),
				platform.position.y - randf_range(50, 80)
			))

# 创建皇冠形状的金币
func _create_crown_shaped_coins(center_pos):
	# 创建皇冠顶部的金币
	_create_coin(Vector2(center_pos.x, center_pos.y - 60))
	
	# 创建皇冠左侧的金币
	_create_coin(Vector2(center_pos.x - 20, center_pos.y - 50))
	_create_coin(Vector2(center_pos.x - 40, center_pos.y - 40))
	
	# 创建皇冠右侧的金币
	_create_coin(Vector2(center_pos.x + 20, center_pos.y - 50))
	_create_coin(Vector2(center_pos.x + 40, center_pos.y - 40))

# 创建平台
func _create_platform(pos, is_moving = false):
	var platform = platform_scene.instantiate()
	platform.position = pos
	
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

# 创建金币
func _create_coin(pos):
	var coin = coin_scene.instantiate()
	coin.position = pos
	
	# 添加到场景
	if not has_node("Coins"):
		var coins = Node2D.new()
		coins.name = "Coins"
		add_child(coins)
	
	$Coins.add_child(coin)
	return coin

# 创建史莱姆敌人
func _create_slime(pos, is_purple = false):
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
